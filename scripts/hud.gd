class_name Hud
extends CanvasLayer
## In-level overlay: title, spring gauge, echo slots, hint and messages; the pause menu; and
## the delivery card with the letter.

var game: Game

var _title: Label
var _spring: Control
var _slots: HBoxContainer
var _hint: Label
var _msg: Label
var _msg_t := 0.0
var _keys: Label
var _overlay: Control  # pause menu or delivery card
var _spring_left := 1.0
var _chrome: Control  # everything but the overlay, hidden during an act's finale


func setup(g: Game) -> void:
	game = g
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS  # the pause menu works while the game is paused
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	add_child(root)
	_chrome = root
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 14
	top.add_theme_constant_override("separation", 22)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	_title = UI.label("", 26, UI.CREAM, 700, true)
	top.add_child(_title)
	_spring = Control.new()
	_spring.custom_minimum_size = Vector2(260, 34)
	_spring.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	_spring.draw.connect(_draw_spring)
	top.add_child(_spring)
	_slots = HBoxContainer.new()
	_slots.add_theme_constant_override("separation", 8)
	top.add_child(_slots)
	if Touch.active:
		top.offset_right = -24  # touch buttons sit below the bar
	_hint = UI.wrap(UI.label("", 19, Color(UI.CREAM, 0.85), 600), 0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_left = 360 if Touch.active else 120
	_hint.offset_right = -380 if Touch.active else -120
	_hint.offset_top = -92
	_hint.offset_bottom = -44
	root.add_child(_hint)
	_msg = UI.wrap(UI.label("", 22, Color(1, 0.88, 0.62), 700), 0)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_msg.offset_top = 70
	_msg.offset_left = 160
	_msg.offset_right = -160
	root.add_child(_msg)
	_keys = UI.label("←/→ move   Space jump   R unwind   Z undo echo   Backspace restart   Esc pause", 15, Color(UI.CREAM, 0.5), 600)
	_keys.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keys.offset_top = -32
	_keys.offset_bottom = -8
	_keys.visible = not Touch.active
	root.add_child(_keys)
	# A soft dark outline keeps the text readable over the bright daytime levels.
	for l in [_title, _hint, _msg, _keys]:
		l.add_theme_constant_override("outline_size", 7)
		l.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08, 0.55))
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.theme = UI.theme()
	_overlay.visible = false
	add_child(_overlay)


func refresh() -> void:
	_title.text = "%d · %s" % [game.index + 1, game.level.title]
	_hint.text = game.level.hint if Save.setting("hints") else ""
	if Touch.active:
		_hint.text = _hint.text.replace("Move with ←/→ (or A/D), jump with Space or ↑.", "Move with ◀ ▶ and jump with Jump.").replace("press R", "press Unwind").replace("Backspace", "Reset")
	for c in _slots.get_children():
		c.queue_free()
	var n := int(game.level.echoes)
	if n == 0:
		_slots.add_child(UI.label("no echoes", 17, UI.DIM, 600))
	for i in n:
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(30, 30)
		var used := i < game.echoes.size()
		dot.draw.connect(func():
			dot.draw_circle(Vector2(15, 15), 12, Color(UI.ECHO, 0.85) if used else Color(0, 0, 0, 0.3))
			dot.draw_arc(Vector2(15, 15), 12, 0, TAU, 32, UI.ECHO, 2.0, true))
		_slots.add_child(dot)
	var par := int(game.level.par)
	var seal := UI.label("  seal: %d" % par if n > 0 else "", 17, UI.DIM, 600)
	_slots.add_child(seal)
	for l in [seal] + _slots.get_children().filter(func(c): return c is Label):
		l.add_theme_constant_override("outline_size", 6)
		l.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08, 0.55))
	if _msg_t <= 0.0:
		_msg.text = ""


func update_live() -> void:
	if game.sim:
		_spring_left = clampf(1.0 - float(game.sim.frame) / game.sim.spring, 0.0, 1.0)
	_spring.queue_redraw()
	if _msg_t > 0.0:
		_msg_t -= get_process_delta_time()
		if _msg_t <= 0.0:
			_msg.text = ""


func flash_message(text: String, seconds: float) -> void:
	_msg.text = text
	_msg_t = seconds if seconds > 0.0 else 9999.0
	if seconds <= 0.0:
		_msg_t = 9999.0


func _draw_spring() -> void:
	var s := _spring.size
	var r := Rect2(Vector2(40, 8), Vector2(s.x - 40, 18))
	_spring.draw_rect(r, Color(0, 0, 0, 0.4))
	var col := UI.BRASS if _spring_left > 0.25 else UI.RED
	_spring.draw_rect(Rect2(r.position, Vector2(r.size.x * _spring_left, r.size.y)), col)
	_spring.draw_rect(r, Color(UI.CREAM, 0.5), false, 1.5)
	# A little key icon.
	var c := Vector2(18, 17)
	_spring.draw_circle(c + Vector2(-7, 0), 6, UI.BRASS)
	_spring.draw_circle(c + Vector2(7, 0), 6, UI.BRASS)
	_spring.draw_rect(Rect2(c + Vector2(-2, -2), Vector2(18, 4)), UI.BRASS)
	if game.sim:
		var secs := maxf(0.0, (game.sim.spring - game.sim.frame) / 60.0)
		var f := UI.font(700)
		_spring.draw_string(f, Vector2(r.position.x + 8, r.end.y - 3), "%.1f s" % secs, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.INK if _spring_left > 0.2 else UI.CREAM)
		# While a bell holds the echoes, a pale bar under the spring shows how long is left.
		if game.sim.hush > 0:
			var k := float(game.sim.hush) / Sim.HUSH
			_spring.draw_rect(Rect2(r.position + Vector2(0, r.size.y + 3), Vector2(r.size.x * k, 4)), Color(0.8, 0.93, 1.0, 0.9))


## Shows or hides the in-level bar, hint and messages (the finale hides them).
func set_chrome(on: bool) -> void:
	_chrome.visible = on


# ------------------------------------------------------------ pause

func open_pause() -> void:
	if _overlay.visible:
		return
	get_tree().paused = true
	_clear_overlay()
	var col := UI.page(_overlay)
	col.add_child(UI.label("Paused", 46, UI.CREAM, 700, true))
	col.add_child(UI.wrap(UI.label(game.level.hint, 18, UI.DIM, 600), 520))
	var resume := UI.button("Resume", _close_pause)
	col.add_child(resume)
	col.add_child(UI.button("Restart level", func():
		_close_pause()
		game.restart()))
	col.add_child(UI.button("Settings", func():
		_clear_overlay()
		var p := SettingsPanel.new()
		p.closed.connect(func():
			_overlay.visible = false
			open_pause())
		_overlay.add_child(p)
		_overlay.visible = true))
	col.add_child(UI.button("Main menu", func():
		get_tree().paused = false
		game.back_to_menu()))
	_overlay.visible = true
	resume.grab_focus.call_deferred()


func _close_pause() -> void:
	_overlay.visible = false
	_clear_overlay()
	get_tree().paused = false


func _clear_overlay() -> void:
	for c in _overlay.get_children():
		c.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _overlay.visible and get_tree().paused and event.is_action_pressed("pause"):
		_close_pause()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------ delivery

func show_delivery(news: Dictionary, used: int, cog: bool) -> void:
	_clear_overlay()
	var lv := game.level
	var last := Levels.ends_act(game.index)
	var act: Dictionary = Levels.ACTS[Levels.act_of(game.index)]
	var more := game.index + 1 < Levels.count()
	var col := UI.page(_overlay, 0.55)
	col.add_theme_constant_override("separation", 10)
	col.add_child(UI.label("Delivered", 44, UI.CREAM, 700, true))
	var stats := "Echoes used: %d" % used
	if used <= int(lv.par):
		stats += "   ·   Wax seal earned" if news.seal else "   ·   Sealed"
	else:
		stats += "   ·   The seal needs %d" % int(lv.par)
	col.add_child(UI.label(stats, 18, UI.BRASS, 700))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.box(UI.PAPER, 6, Color(0.55, 0.42, 0.28), 2, 22))
	card.custom_minimum_size.x = 640
	col.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	if last:
		inner.add_child(UI.label(act.ending_title, 26, UI.INK, 700, true))
		inner.add_child(UI.wrap(UI.label(act.ending, 19, Color(0.18, 0.13, 0.1), 500, true), 600))
	else:
		inner.add_child(UI.label("From %s, to %s" % [lv.from, lv.to], 16, Color(0.4, 0.3, 0.22), 700))
		inner.add_child(UI.wrap(UI.label(lv.letter, 22, Color(0.16, 0.12, 0.09), 500, true), 600))
	if news.page:
		col.add_child(UI.label("A journal page was added to the Letters book.", 17, UI.BRASS, 700))
	elif cog:
		pass
	elif Levels.has_cog(game.index) and not Save.has_page(game.index):
		col.add_child(UI.label("A cog is still hidden somewhere in this level.", 16, UI.DIM, 600))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var next: Button
	if last and more:
		next = UI.button("On to the new year", game.next_level, 260)
	elif last:
		next = UI.button("Main menu", game.back_to_menu, 240)
	else:
		next = UI.button("Next delivery", game.next_level, 240)
	row.add_child(UI.button("Play again", func():
		_overlay.visible = false
		game.restart(), 200))
	row.add_child(next)
	_overlay.visible = true
	next.grab_focus.call_deferred()
