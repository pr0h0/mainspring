class_name SettingsPanel
extends Control
## Volume, fullscreen, touch buttons and hints. Used from the title screen and the pause menu.

signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var col := UI.page(self, 0.7)
	var plate := UI.plated(col, "brass", 0.0, 40.0)
	plate.add_theme_constant_override("separation", 14)
	plate.add_child(UI.heading("Settings", 42))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 10)
	plate.add_child(grid)
	for row in [["Master volume", "master"], ["Music", "music"], ["Sound effects", "sfx"]]:
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Save.setting(row[1]))
		s.custom_minimum_size = Vector2(260, 34)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var key: String = row[1]
		s.value_changed.connect(func(v): Save.set_setting(key, v))
		s.drag_ended.connect(func(_c): Sfx.play("click"))
		_row(grid, row[0], s)
	if not OS.has_feature("web_ios"):
		var fs := CheckButton.new()
		fs.button_pressed = bool(Save.setting("fullscreen"))
		fs.toggled.connect(func(on): Save.set_setting("fullscreen", on))
		_row(grid, "Fullscreen", fs)
	var tb := OptionButton.new()
	for m in Save.TOUCH_MODES:
		tb.add_item(m)
	tb.selected = int(Save.setting("touch"))
	tb.item_selected.connect(func(i): Save.set_setting("touch", i))
	tb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tb.custom_minimum_size.x = 130
	_row(grid, "Touch buttons", tb)
	var hints := CheckButton.new()
	hints.button_pressed = bool(Save.setting("hints"))
	hints.toggled.connect(func(on): Save.set_setting("hints", on))
	_row(grid, "Hints after 3 tries", hints)
	var back := UI.button("Back", func():
		closed.emit()
		queue_free(), 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.add_child(back)
	back.grab_focus.call_deferred()


## A row: a gear marker and the name (both light up while the control is focused), then the control.
func _row(grid: GridContainer, text: String, ctl: Control) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var m := UI.Marker.new()
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(m)
	var l := UI.label(text, 25, Color(UI.CREAM, 0.85), 600, true)
	h.add_child(l)
	grid.add_child(h)
	if ctl is CheckButton:
		ctl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ctl.focus_entered.connect(func():
		m.on = true
		l.label_settings.font_color = UI.GLOW)
	ctl.focus_exited.connect(func():
		m.on = false
		l.label_settings.font_color = Color(UI.CREAM, 0.85))
	ctl.mouse_entered.connect(func(): ctl.grab_focus())
	grid.add_child(ctl)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
