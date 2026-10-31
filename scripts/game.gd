class_name Game
extends Node
## Plays one level: steps the Sim at 60 Hz from the controls, records each loop, and handles
## unwinding (save the loop as an echo and start over), undo, restart, death and delivery.

signal finished(next: int)  # -1 back to the menu
signal quit_to_menu
signal act_begins(act: int)  # an act's ending was read: show the next act's opening

const UNWIND_TIME := 0.7

var index := 0
var level: Dictionary
var sim: Sim
var view: WorldView
var hud: Hud

var echoes: Array = []  # PackedByteArray per echo, oldest first
var trails: Array = []  # PackedVector2Array of where each echo walked when recorded
var _trail := PackedVector2Array()
var _history := []  # per frame: [actor positions, crate positions], for the unwind animation
var _state := "play"  # play | unwind | dead | won
var _state_t := 0.0
var _loops := 0
var _shown_spent := false
var _auto_inputs := PackedByteArray()  # debug: scripted input for the live player
var _fireworks := false  # midnight: keep them going behind the delivery card
var _fw_t := 0.0
var _fw_rng := RandomNumberGenerator.new()


func _init(i: int) -> void:
	index = i
	level = Levels.get_level(i)


func _ready() -> void:
	view = WorldView.new()
	view.thawed = Levels.act_of(index) >= 1
	Sfx.track("music2" if view.thawed else "music")
	view.light = float(level.get("light", 1.0 if view.thawed else 0.0))
	add_child(view)
	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	sim = Sim.new(level, echoes)
	view.build(sim)
	_begin_loop()
	Touch.in_game = true


func _exit_tree() -> void:
	Touch.in_game = false


func _begin_loop() -> void:
	sim = Sim.new(level, echoes)
	view.rebuild_dynamic(sim)
	view.set_trails(trails)
	_trail = PackedVector2Array()
	_history.clear()
	_state = "play"
	_shown_spent = false
	_loops += 1
	hud.refresh()


func _physics_process(_dt: float) -> void:
	if _state != "play" or get_tree().paused:
		return
	var bits := 0
	if _auto_inputs.size() > 0:
		bits = _auto_inputs[sim.frame] if sim.frame < _auto_inputs.size() else 0
	else:
		if Input.is_action_pressed("move_left"):
			bits |= Sim.IN_LEFT
		if Input.is_action_pressed("move_right"):
			bits |= Sim.IN_RIGHT
		if Input.is_action_pressed("jump"):
			bits |= Sim.IN_JUMP
		# With no echoes yet, the spring stays wound until the first key press, so you can look
		# around first. Once echoes exist the clock runs from spawn, because they move right away.
		if bits == 0 and sim.frame == 0 and echoes.is_empty():
			return
	var p := sim.player()
	if not sim.wound_down():
		_trail.append(p.pos)
	sim.step(bits)
	_history.append([sim.actors.map(func(a): return a.pos), sim.crates.map(func(c): return c.pos)])
	for e in sim.events:
		_event(e[0], e[1])
	if sim.won:
		_win()
	elif not sim.player().alive:
		_state = "dead"
		_state_t = 0.0
	elif sim.wound_down() and not _shown_spent:
		_shown_spent = true
		Sfx.play("wind_down")
		hud.flash_message(_spent_text(), 0.0)


func _spent_text() -> String:
	if int(level.echoes) == 0:
		return "Your spring ran down.  %s to try again" % _key("unwind")
	if echoes.size() < int(level.echoes):
		return "Spring spent.  %s to unwind and keep this as an echo" % _key("unwind")
	return "Spring spent.  %s to replay, %s to drop your last echo" % [_key("unwind"), _key("undo")]


func _key(action: String) -> String:
	if Touch.active:
		return {"unwind": "Unwind", "undo": "Undo", "restart": "Reset"}.get(action, action)
	return {"unwind": "R", "undo": "Z", "restart": "Backspace"}.get(action, action)


func _process(dt: float) -> void:
	_state_t += dt
	match _state:
		"play":
			view.sync(dt, 1.0 - float(sim.frame) / sim.spring)
			if not get_tree().paused:
				if Input.is_action_just_pressed("unwind"):
					unwind()
				elif Input.is_action_just_pressed("undo"):
					undo()
				elif Input.is_action_just_pressed("restart"):
					restart()
				elif Input.is_action_just_pressed("pause"):
					hud.open_pause()
		"unwind":
			# Run the loop backwards on screen, then start the next one.
			var t := clampf(_state_t / UNWIND_TIME, 0.0, 1.0)
			var k := int(round((1.0 - ease(t, 0.6)) * (_history.size() - 1)))
			if _history.size() > 0:
				view.pose(_history[k][0], _history[k][1])
			view.sync(0.0)
			if t >= 1.0:
				_begin_loop()
		"dead":
			view.sync(dt, 0.0)
			if _state_t > 1.1:
				_begin_loop()
				hud.flash_message("Scalded! The loop starts over (your echoes are kept).", 3.0)
		"won":
			view.sync(dt, 0.0)
			if _fireworks:
				_fw_t -= dt
				if _fw_t <= 0.0:
					view.firework(_fw_rng)
					_fw_t = _fw_rng.randf_range(0.5, 1.4)
		"finale":
			pass  # driven by _finale()
	hud.update_live()


## Keeps this loop as a new echo (if there's room) and starts the next loop.
func unwind() -> void:
	if _state != "play":
		return
	var p := sim.player()
	if int(level.echoes) > 0 and echoes.size() < int(level.echoes) and p.inputs.size() > 10:
		echoes.append(p.inputs)
		trails.append(_trail)
		Sfx.play("unwind")
		hud.flash_message("Echo %d recorded. It will repeat that loop." % echoes.size(), 2.5)
	elif int(level.echoes) > 0 and echoes.size() >= int(level.echoes):
		Sfx.play("unwind", -4.0, 1.15)
		hud.flash_message("All echoes in use: replaying. %s drops the last one." % _key("undo"), 3.0)
	else:
		Sfx.play("unwind", -4.0, 1.15)
	_state = "unwind"
	_state_t = 0.0


func undo() -> void:
	if _state != "play" or echoes.is_empty():
		return
	echoes.pop_back()
	trails.pop_back()
	Sfx.play("undo")
	hud.flash_message("Last echo dropped.", 2.0)
	_state = "unwind"
	_state_t = 0.0


func restart() -> void:
	if _state != "play" and _state != "won":
		return
	echoes.clear()
	trails.clear()
	# Coming back from an act's ending: give the camera and the HUD back.
	_fireworks = false
	hud.set_chrome(true)
	view.reset_camera()
	Sfx.play("undo", 0.0, 0.85)
	_state = "unwind"
	_state_t = 0.0
	hud.flash_message("Level restarted.", 1.5)


func _event(name: String, at: Vector2) -> void:
	match name:
		"jump":
			Sfx.play("jump", -6.0)
		"land":
			Sfx.play("land", -8.0)
		"plate_on":
			Sfx.play("plate_on", -2.0)
		"plate_off":
			Sfx.play("plate_off", -4.0)
		"door_open":
			Sfx.play("door", -3.0, 1.1)
		"door_close":
			Sfx.play("door", -3.0, 0.85)
		"lift_stop":
			Sfx.play("thud", -6.0, 0.8)
		"thud":
			Sfx.play("thud", -4.0)
		"push":
			if sim.frame % 9 == 0:
				Sfx.play("push", -10.0)
		"die":
			Sfx.play("hiss")
			view.burst(at + Vector2(0.3, 0.5), Color(1, 0.6, 0.3), 18)
		"cog":
			Sfx.play("cog")
			view.burst(at, Color(1.0, 0.8, 0.3), 22)
			hud.flash_message("You found a cog: a page from Odile's journal (yours once you deliver).", 4.0)
		"chime":
			Sfx.play("chime", -2.0)
			view.ring(at)
		"release":
			Sfx.play("release", -6.0)
		"win":
			pass


func _win() -> void:
	_state = "won"
	Sfx.play("win")
	view.burst(Vector2(sim.exit_cell) + Vector2(0.5, 1.0), Color(1.0, 0.85, 0.4), 30)
	var cog := sim.cogs.any(func(c): return c.taken)
	var news := Save.record(index, echoes.size(), cog)
	await get_tree().create_timer(1.0).timeout
	if Levels.ends_act(index):
		await _finale()
	hud.show_delivery(news, echoes.size(), cog)


## The end of an act: the camera rises to the tower. At midnight the stuck minute hand clicks
## over, the bells ring, the snow starts falling and fireworks go up; at the end of the second
## act the bells ring noon under a clear sky. Any key skips ahead.
func _finale() -> void:
	_state = "finale"
	hud.set_chrome(false)
	view.follow = false
	var act := Levels.act_of(index)
	var cam := view.camera
	var from := cam.global_transform
	var look_from := from.origin - from.basis.z * 30.0
	var to_pos := Vector3(view.clock_face.x - 3.0, sim.h + 1.5, from.origin.z + 9.0)
	var light0 := view.light
	_fw_rng.seed = 2026
	var t := 0.0
	var clunk := false
	var rang := false
	var next_fw := 5.4
	while t < 11.0:
		var dt := get_process_delta_time()
		t += dt
		var k := ease(clampf((t - 0.2) / 3.6, 0.0, 1.0), -2.2)
		cam.position = from.origin.lerp(to_pos, k)
		cam.look_at(look_from.lerp(view.clock_face, k))
		view.sync(dt, 0.0)
		if not clunk and t > 4.3:
			clunk = true
			Sfx.play("clunk")
			var tw := create_tween()
			if act == 0:
				tw.tween_property(view.minute_hand, "rotation:z", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				# The morning sweeps round to noon.
				tw.tween_property(view.minute_hand, "rotation:z", -TAU, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if not rang and t > 4.9:
			rang = true
			Sfx.play("bells")
			if act == 0:
				view.thaw()
		if act == 0 and t > next_fw:
			view.firework(_fw_rng)
			next_fw += _fw_rng.randf_range(0.25, 0.8)
		if act > 0 and t > 4.9:
			view.light = lerpf(light0, 1.0, clampf((t - 4.9) / 3.0, 0.0, 1.0))
			view.set_daylight(view.light)
		if t > 1.5 and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_accept")):
			if not rang:
				Sfx.play("bells")
				if act == 0:
					view.thaw()
				else:
					view.set_daylight(1.0)
			view.minute_hand.rotation.z = 0.0 if act == 0 else -TAU
			cam.position = to_pos
			cam.look_at(view.clock_face)
			break
		await get_tree().process_frame
	_state = "won"
	_fireworks = act == 0
	_fw_t = 0.3


func next_level() -> void:
	if Levels.ends_act(index) and index + 1 < Levels.count():
		act_begins.emit(Levels.act_of(index) + 1)
		return
	finished.emit(index + 1 if index + 1 < Levels.count() else -1)


func back_to_menu() -> void:
	quit_to_menu.emit()


## Debug: jump straight to this act's ending (nothing is saved).
func debug_finale() -> void:
	if not is_node_ready():
		await ready
	await get_tree().create_timer(0.3).timeout
	_state = "won"
	await _finale()
	hud.show_delivery({"first": false, "seal": false, "page": false}, 0, false)


## Debug: play a scripted solution live (loops split by "|").
func autoplay(solution: String) -> void:
	if not is_node_ready():
		await ready
	var loops := solution.split("|")
	for li in loops.size():
		_auto_inputs = Levels.inputs_for(loops[li])
		while _state != "play":
			await get_tree().process_frame
		while sim.frame < maxi(_auto_inputs.size() + 20, 60) and _state == "play" and not sim.won:
			await get_tree().physics_frame
		if li < loops.size() - 1:
			unwind()
	_auto_inputs = PackedByteArray()
