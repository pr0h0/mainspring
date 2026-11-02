extends CanvasLayer
## On-screen buttons for phones: ◀ ▶ on the left, Jump and Unwind on the right, Undo, Restart
## and Pause along the top. Each finger is tracked by its own index, so holding ▶ while
## tapping Jump works. Settings "touch": Auto (phones, or after the first touch), On, Off.

signal toggled(on: bool)

var active := false
var in_game := false  # the game shows the buttons only during play

var _root: Control
var _buttons := {}  # name -> {action, pos, r, label}
var _held := {}  # touch index -> button name
var _seen_touch := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw)
	add_child(_root)
	Save.changed.connect(_refresh)
	get_viewport().size_changed.connect(_layout)
	_refresh()


static func is_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")


func _refresh() -> void:
	var mode := int(Save.setting("touch"))
	var want := mode == 1 or (mode == 0 and (is_mobile() or _seen_touch))
	if want != active:
		active = want
		_release_all()
		toggled.emit(active)
	_layout()


func _layout() -> void:
	var s := _root.get_viewport_rect().size
	_buttons = {
		"left": {"action": "move_left", "pos": Vector2(95, s.y - 105), "r": 62.0, "label": ""},
		"right": {"action": "move_right", "pos": Vector2(250, s.y - 105), "r": 62.0, "label": ""},
		"jump": {"action": "jump", "pos": Vector2(s.x - 110, s.y - 110), "r": 68.0, "label": "Jump"},
		"unwind": {"action": "unwind", "pos": Vector2(s.x - 265, s.y - 80), "r": 52.0, "label": "Unwind"},
		"undo": {"action": "undo", "pos": Vector2(s.x - 205, 150), "r": 34.0, "label": "Undo"},
		"restart": {"action": "restart", "pos": Vector2(s.x - 125, 150), "r": 34.0, "label": "Reset"},
		"pause": {"action": "pause", "pos": Vector2(s.x - 45, 150), "r": 30.0, "label": ""},
	}
	_root.queue_redraw()


func _process(_dt: float) -> void:
	var show := active and in_game and not get_tree().paused
	if not show and not _held.is_empty():
		_release_all()
	_root.visible = show


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not _seen_touch:
		_seen_touch = true
		if int(Save.setting("touch")) == 0:
			_refresh()
	if not _root.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var b := _hit(event.position)
			if b != "":
				_press(event.index, b)
				get_viewport().set_input_as_handled()
		elif _held.has(event.index):
			_release(event.index)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _held.has(event.index):
		# A thumb sliding between ◀ and ▶ switches direction without lifting.
		var now: String = _held[event.index]
		if now == "left" or now == "right":
			var b := _hit(event.position, 1.5)
			if (b == "left" or b == "right") and b != now:
				_release(event.index)
				_press(event.index, b)
		get_viewport().set_input_as_handled()


func _hit(pos: Vector2, slack := 1.2) -> String:
	var best := ""
	var best_d := INF
	for name in _buttons:
		var b: Dictionary = _buttons[name]
		var d := pos.distance_to(b.pos)
		if d <= float(b.r) * slack and d < best_d:
			best = name
			best_d = d
	return best


func _press(index: int, name: String) -> void:
	_held[index] = name
	Input.action_press(_buttons[name].action)
	_root.queue_redraw()


func _release(index: int) -> void:
	var name: String = _held[index]
	_held.erase(index)
	if not name in _held.values():
		Input.action_release(_buttons[name].action)
	_root.queue_redraw()


func _release_all() -> void:
	for i in _held.keys():
		_release(i)


func _draw() -> void:
	var font := UI.font(700)
	var down := _held.values()
	for name in _buttons:
		var b: Dictionary = _buttons[name]
		var on: bool = name in down
		var r: float = b.r
		_root.draw_circle(b.pos, r, Color(0.05, 0.04, 0.06, 0.45 if on else 0.28))
		_root.draw_arc(b.pos, r, 0, TAU, 48, Color(UI.BRASS, 0.95 if on else 0.6), 2.5, true)
		_root.draw_arc(b.pos, r - 5.0, 0, TAU, 48, Color(UI.BRASS, 0.5 if on else 0.22), 1.0, true)
		var ink := Color(UI.CREAM, 0.95 if on else 0.75)
		match name:
			"left", "right":
				var sx := -1.0 if name == "left" else 1.0
				_root.draw_colored_polygon(PackedVector2Array([b.pos + Vector2(18 * sx, 0), b.pos + Vector2(-12 * sx, -20), b.pos + Vector2(-12 * sx, 20)]), ink)
				continue
			"pause":
				for dx in [-8.0, 3.0]:
					_root.draw_rect(Rect2(b.pos + Vector2(dx, -10), Vector2(5, 20)), ink)
				continue
		var fs := 19 if r > 45.0 else 15
		var text: String = b.label
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_root.draw_string(font, b.pos + Vector2(-w / 2.0, fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
