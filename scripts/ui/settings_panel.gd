class_name SettingsPanel
extends Control
## Volume, fullscreen, touch buttons and hints. Used from the title screen and the pause menu.

signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	var col := UI.page(self, 0.7)
	col.add_child(UI.label("Settings", 42, UI.CREAM, 700, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	for row in [["Master volume", "master"], ["Music", "music"], ["Sound effects", "sfx"]]:
		grid.add_child(UI.label(row[0], 21))
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Save.setting(row[1]))
		s.custom_minimum_size = Vector2(260, 30)
		var key: String = row[1]
		s.value_changed.connect(func(v): Save.set_setting(key, v))
		s.drag_ended.connect(func(_c): Sfx.play("click"))
		grid.add_child(s)
	if not OS.has_feature("web_ios"):
		grid.add_child(UI.label("Fullscreen", 21))
		var fs := CheckButton.new()
		fs.button_pressed = bool(Save.setting("fullscreen"))
		fs.toggled.connect(func(on): Save.set_setting("fullscreen", on))
		grid.add_child(fs)
	grid.add_child(UI.label("Touch buttons", 21))
	var tb := OptionButton.new()
	for m in Save.TOUCH_MODES:
		tb.add_item(m)
	tb.selected = int(Save.setting("touch"))
	tb.item_selected.connect(func(i): Save.set_setting("touch", i))
	grid.add_child(tb)
	grid.add_child(UI.label("Level hints", 21))
	var hints := CheckButton.new()
	hints.button_pressed = bool(Save.setting("hints"))
	hints.toggled.connect(func(on): Save.set_setting("hints", on))
	grid.add_child(hints)
	var back := UI.button("Back", func():
		closed.emit()
		queue_free())
	col.add_child(back)
	back.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
