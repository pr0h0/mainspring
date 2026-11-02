class_name Hud
extends CanvasLayer
## In-level overlay: title, spring gauge, echo slots, hint and messages; the pause menu; and
## the delivery card with the letter.

const KEYS := [[["←", "→"], "move"], [["Space"], "jump"], [["R"], "unwind"], [["Z"], "undo echo"], [["Backspace"], "restart"], [["Esc"], "pause"]]

var game: Game

var _title: Label
var _badge: Control  # the level number, in a postmark
var _spring: Control
var _slots: HBoxContainer
var _hint: Label
var _msg: Label
var _msg_t := 0.0
var _keys: Control
var _overlay: Control  # pause menu or delivery card
var _spring_left := 1.0
var _chrome: Control  # everything but the overlay, hidden during an act's finale
var hint_shown := false  # the level's hint has been revealed (after a few tries, or from the pause menu)


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
	# Soft shade along the top and bottom edges keeps the text readable over the pale daytime
	# levels without boxing it in.
	root.add_child(_edge_shade(true))
	root.add_child(_edge_shade(false))
	# Top left: the level number in a postmark, and its name.
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = 22
	top.offset_top = 14
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	_badge = UI.Glyph.new(_draw_badge, Vector2(44, 44))
	top.add_child(_badge)
	_title = UI.outline(UI.label("", 28, UI.CREAM, 700, true), 7, 0.6)
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_title)
	# Top middle: the mainspring, a coil that unwinds as the loop runs.
	_spring = Control.new()
	_spring.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_spring.offset_left = -88
	_spring.offset_right = 88
	_spring.offset_top = 10
	_spring.offset_bottom = 66
	_spring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spring.draw.connect(_draw_spring)
	root.add_child(_spring)
	# Top right: a socket per echo, and the wax seal's echo count.
	var plate := UI.Plate.new()
	plate.style = "hud"
	plate.pad = 12.0
	plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	plate.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	plate.offset_right = -22
	plate.offset_top = 10
	plate.custom_minimum_size.y = 56
	root.add_child(plate)
	_slots = HBoxContainer.new()
	_slots.add_theme_constant_override("separation", 4)
	_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	plate.add_child(_slots)
	_hint = UI.wrap(UI.label("", 23, Color(UI.CREAM, 0.92), 600, true), 0)
	UI.outline(_hint, 8, 0.75)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_left = 360 if Touch.active else 120
	_hint.offset_right = -380 if Touch.active else -120
	_hint.offset_top = -112 if not Touch.active else -96
	_hint.offset_bottom = -52 if not Touch.active else -24
	root.add_child(_hint)
	_msg = UI.wrap(UI.label("", 25, UI.GLOW, 700, true), 0)
	UI.outline(_msg, 8, 0.75)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_msg.offset_top = 84
	_msg.offset_left = 160
	_msg.offset_right = -160
	root.add_child(_msg)
	# Bottom: the controls, as keycaps.
	_keys = Control.new()
	_keys.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_keys.offset_top = -40
	_keys.offset_bottom = -10
	_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keys.draw.connect(_draw_keys)
	_keys.visible = not Touch.active
	root.add_child(_keys)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.theme = UI.theme()
	_overlay.visible = false
	add_child(_overlay)


func _edge_shade(top: bool) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(UI.SHADE, 0.42))
	g.set_color(1, Color(UI.SHADE, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 4
	gt.height = 64
	gt.fill_from = Vector2(0, 0) if top else Vector2(0, 1)
	gt.fill_to = Vector2(0, 1) if top else Vector2(0, 0)
	var r := TextureRect.new()
	r.texture = gt
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
	if top:
		r.offset_bottom = 96
	else:
		r.offset_top = -130
	return r


func refresh() -> void:
	_title.text = String(game.level.title)
	_badge.queue_redraw()
	_hint.text = _hint_line()
	for c in _slots.get_children():
		c.queue_free()
	var n := int(game.level.echoes)
	if n == 0:
		_slots.add_child(UI.label("no echoes", 20, Color(UI.CREAM, 0.7), 600, true))
	for i in n:
		var used := i < game.echoes.size()
		_slots.add_child(UI.Glyph.new(func(ci: Control): _draw_socket(ci, used), Vector2(30, 32)))
	if n > 0:
		var par := int(game.level.par)
		var gap := UI.Glyph.new(func(ci: Control):
			UI.draw_fade_line(ci, Vector2(ci.size.x / 2.0, 2), Vector2(ci.size.x / 2.0, ci.size.y - 2), Color(UI.BRASS, 0.6)), Vector2(14, 32))
		_slots.add_child(gap)
		var seal := UI.label("seal", 15, Color(UI.CREAM, 0.7), 700)
		seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_slots.add_child(seal)
		_slots.add_child(UI.Glyph.new(func(ci: Control): UI.draw_seal(ci, ci.size / 2.0, 13.0, str(par)), Vector2(32, 32)))
	if _msg_t <= 0.0:
		_msg.text = ""


## The line under the level: its opening line, or the hint once revealed.
func _hint_line() -> String:
	var t: String = ("Hint: " + String(game.level.hint)) if hint_shown else String(game.level.get("intro", ""))
	return _touch_words(t)


static func _touch_words(t: String) -> String:
	if not Touch.active:
		return t
	return t.replace("Move with ←/→ (or A/D), jump with Space or ↑.", "Move with ◀ ▶ and jump with Jump.").replace("press R", "press Unwind").replace("Press R", "Press Unwind").replace("Backspace", "Reset").replace("press Z", "press Undo").replace("Press Z", "Press Undo")


## Reveals the hint (announce: say so, for when it appears by itself after a few tries).
func show_hint(announce := false) -> void:
	hint_shown = true
	_hint.text = _hint_line()
	if announce:
		flash_message("Stuck? Here's a hint, below.", 3.0)


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


## The level number, postmarked.
func _draw_badge(ci: Control) -> void:
	var c := ci.size / 2.0
	ci.draw_circle(c, 20.0, Color(UI.SHADE, 0.5))
	ci.draw_arc(c, 20.0, 0, TAU, 40, Color(UI.CREAM, 0.85), 1.5, true)
	ci.draw_arc(c, 16.5, 0, TAU, 40, Color(UI.CREAM, 0.45), 1.0, true)
	var f := UI.font(800)
	var t := str(game.index + 1) if game else ""
	var fs := 18 if t.length() < 2 else 16
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(f, c + Vector2(-w / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.CREAM)


## An echo socket: an empty keyhole while the echo is free, a little blue courier once used.
func _draw_socket(ci: Control, used: bool) -> void:
	var c := ci.size / 2.0
	if used:
		ci.draw_circle(c, 15.0, Color(UI.ECHO, 0.18))
		ci.draw_circle(c, 12.0, Color(UI.ECHO, 0.85))
		var ink := Color(1, 1, 1, 0.92)
		ci.draw_circle(c + Vector2(0, -4.5), 3.4, ink)
		var body := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			body.append(c + Vector2(0, 7.5) + Vector2(cos(a) * 6.5, sin(a) * 7.5))
		ci.draw_colored_polygon(body, ink)
	else:
		ci.draw_circle(c, 12.0, Color(UI.SHADE, 0.85))
		var k := Color(UI.BRASS, 0.6)
		ci.draw_circle(c + Vector2(0, -3), 3.3, k)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.6, -2), c + Vector2(1.6, -2), c + Vector2(2.8, 6), c + Vector2(-2.8, 6)]), k)
	ci.draw_arc(c, 12.0, 0, TAU, 32, Color(UI.BRASS, 0.9), 1.5, true)


## The mainspring: a coil inside a brass bezel that unwinds towards its arbor as the loop runs,
## with the seconds left beside it. While a bell holds the echoes, a pale arc runs round the
## bezel.
func _draw_spring() -> void:
	var s := _spring.size
	UI.draw_hud_plate(_spring, Rect2(Vector2.ZERO, s))
	var low := _spring_left <= 0.25
	var col := UI.RED if low else UI.BRASS
	var c := Vector2(31, s.y / 2.0)
	_spring.draw_circle(c, 20.0, Color(UI.SHADE, 0.9))
	for i in 12:
		var d := Vector2.from_angle(TAU * i / 12.0)
		_spring.draw_line(c + d * 17.5, c + d * 19.5, Color(UI.BRASS, 0.5), 1.0, true)
	var turns := 3.2
	var full := PackedVector2Array()
	var wound := PackedVector2Array()
	for i in 97:
		var u := i / 96.0
		var p := c + Vector2.from_angle(-PI / 2.0 + u * turns * TAU) * (2.5 + 13.0 * u)
		full.append(p)
		if u <= _spring_left + 0.001:
			wound.append(p)
	_spring.draw_polyline(full, Color(UI.BRASS, 0.2), 1.4, true)
	if wound.size() > 1:
		_spring.draw_polyline(wound, col, 2.0, true)
	_spring.draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), UI.GLOW)
	_spring.draw_arc(c, 20.0, 0, TAU, 40, col, 1.6, true)
	if game.sim and game.sim.hush > 0:
		var k := float(game.sim.hush) / Sim.HUSH
		_spring.draw_arc(c, 23.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color(0.8, 0.93, 1.0, 0.95), 2.5, true)
	var secs := maxf(0.0, (game.sim.spring - game.sim.frame) / 60.0) if game.sim else 0.0
	var f := UI.font(800)
	var txt := "%.1f" % secs
	var x := c.x + 32.0
	_spring.draw_string(f, Vector2(x, s.y / 2.0 + 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UI.RED.lightened(0.15) if low else UI.CREAM)
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	_spring.draw_string(UI.serif(600), Vector2(x + w + 4, s.y / 2.0 + 6), "sec", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UI.CREAM, 0.6))
	_spring.draw_string(UI.font(700), Vector2(x + 1, s.y / 2.0 + 21), "S P R I N G", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(UI.BRASS, 0.75))


## The controls along the bottom, as keycaps.
func _draw_keys() -> void:
	var f := UI.font(700)
	var fs := 15
	var cap := 22.0
	var total := 0.0
	for k in KEYS:
		total += _key_group_width(k, f, fs, cap) + 22.0
	total -= 22.0
	var x := (_keys.size.x - total) / 2.0
	var y := (_keys.size.y - cap) / 2.0
	for k in KEYS:
		for name in k[0]:
			x += UI.draw_keycap(_keys, Vector2(x, y), name, cap) + 3.0
		x += 4.0
		var base := Vector2(x, y + cap * 0.5 + fs * 0.36)
		_keys.draw_string_outline(f, base, k[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(UI.SHADE, 0.6))
		_keys.draw_string(f, base, k[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(UI.CREAM, 0.82))
		x += f.get_string_size(k[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 22.0


func _key_group_width(k: Array, f: Font, fs: int, cap: float) -> float:
	var w := 0.0
	var kf := UI.font(800)
	for name in k[0]:
		w += maxf(cap, kf.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, int(cap * 0.56)).x + cap * 0.6) + 3.0
	return w + 4.0 + f.get_string_size(k[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## Shows or hides the in-level bar, hint and messages (the finale hides them).
func set_chrome(on: bool) -> void:
	_chrome.visible = on


# ------------------------------------------------------------ pause

func open_pause() -> void:
	if _overlay.visible:
		return
	get_tree().paused = true
	_clear_overlay()
	_bottom(false)
	var col := UI.plated(UI.page(_overlay), "brass", 560.0, 40.0)
	col.add_theme_constant_override("separation", 6)
	col.add_child(UI.heading("Paused", 46))
	var intro := String(game.level.get("intro", ""))
	if intro != "":
		col.add_child(UI.center(UI.wrap(UI.label(_touch_words(intro), 21, Color(UI.CREAM, 0.7), 500, true), 480)))
	if hint_shown:
		col.add_child(UI.center(UI.wrap(UI.label("Hint: " + _touch_words(game.level.hint), 21, UI.BRASS, 600, true), 480)))
	col.add_child(UI.spacer(8))
	var resume := UI.button("Resume", _close_pause)
	col.add_child(resume)
	if not hint_shown:
		col.add_child(UI.button("Show a hint", func():
			show_hint()
			_close_pause()))
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
	for b in col.get_children():
		if b is Button:
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_overlay.visible = true
	resume.grab_focus.call_deferred()


func _close_pause() -> void:
	_overlay.visible = false
	_bottom(true)
	_clear_overlay()
	get_tree().paused = false


## The hint and key row sit under the pause menu and the letter; hide them while one is up.
func _bottom(on: bool) -> void:
	_hint.visible = on
	_keys.visible = on and not Touch.active


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
	_bottom(false)
	var lv := game.level
	var last := Levels.ends_act(game.index)
	var act: Dictionary = Levels.ACTS[Levels.act_of(game.index)]
	var more := game.index + 1 < Levels.count()
	var col := UI.page(_overlay, 0.55)
	col.add_theme_constant_override("separation", 10)
	col.add_child(UI.heading("Delivered", 46))
	var stats := "Echoes used: %d" % used
	if used <= int(lv.par):
		stats += "   ·   Wax seal earned" if news.seal else "   ·   Sealed"
	else:
		stats += "   ·   The seal needs %d" % int(lv.par)
	col.add_child(UI.center(UI.outline(UI.label(stats, 19, UI.BRASS, 700), 6, 0.5)))
	col.add_child(UI.spacer(14))
	# The letter itself: postmarked with the delivery's number, wax-sealed when sealed.
	var card := UI.Plate.new()
	card.style = "paper"
	card.pad = 44.0
	card.postmark = "" if last else str(game.index + 1)
	card.sealed = used <= int(lv.par)
	card.custom_minimum_size.x = 640
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	if last:
		inner.add_child(UI.heading(act.ending_title, 30, UI.INK_BROWN, UI.RULE_BROWN))
		inner.add_child(UI.wrap(UI.label(act.ending, 21, UI.INK_BROWN, 500, true), 600))
	else:
		inner.add_child(UI.label("From %s, to %s" % [lv.from, lv.to], 19, UI.RULE_BROWN, 700, true))
		inner.add_child(UI.wrap(UI.label(lv.letter, 23, UI.INK_BROWN, 500, true), 560))
	col.add_child(UI.spacer(6))
	if news.page:
		col.add_child(UI.center(UI.outline(UI.label("A journal page was added to the Letters book.", 18, UI.BRASS, 700), 6, 0.5)))
	elif cog:
		pass
	elif Levels.has_cog(game.index) and not Save.has_page(game.index):
		col.add_child(UI.center(UI.outline(UI.label("A cog is still hidden somewhere in this level.", 17, Color(UI.CREAM, 0.6), 600), 6, 0.5)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
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
		_bottom(true)
		game.restart(), 200))
	row.add_child(next)
	_overlay.visible = true
	next.grab_focus.call_deferred()
