class_name UI
extends RefCounted
## Colors, fonts, the shared Theme and small widget helpers.

const INK := Color(0.07, 0.06, 0.08)
const PAPER := Color(0.93, 0.88, 0.78)
const CREAM := Color(1.0, 0.96, 0.88)
const BRASS := Color(0.86, 0.66, 0.32)
const DIM := Color(0.62, 0.57, 0.5)
const ECHO := Color(0.45, 0.85, 1.0)
const RED := Color(0.85, 0.32, 0.25)

## Plate/door/lift colours by letter, so linked parts read at a glance.
const LINK := {"a": Color(0.98, 0.72, 0.22), "b": Color(0.3, 0.85, 0.78), "c": Color(0.95, 0.42, 0.55), "d": Color(0.62, 0.5, 0.98), "e": Color(0.55, 0.88, 0.35)}

static var _fonts := {}
static var _theme: Theme


static func font(weight := 600) -> FontVariation:
	if not _fonts.has(weight):
		var f := FontVariation.new()
		f.base_font = load("res://assets/fonts/Nunito.ttf")
		f.variation_opentype = {"wght": weight}
		_fonts[weight] = f
	return _fonts[weight]


static func serif(weight := 600) -> FontVariation:
	var key := -weight
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = load("res://assets/fonts/CormorantGaramond.ttf")
		f.variation_opentype = {"wght": weight}
		_fonts[key] = f
	return _fonts[key]


static func box(bg: Color, radius := 10, border := Color(0, 0, 0, 0), bw := 0, pad := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = pad + 6
	s.content_margin_right = pad + 6
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(600)
	t.default_font_size = 22
	t.set_color("font_color", "Label", CREAM)
	t.set_stylebox("normal", "Button", box(Color(0.12, 0.1, 0.11, 0.85), 10, Color(BRASS, 0.45), 2))
	t.set_stylebox("hover", "Button", box(Color(0.2, 0.16, 0.13, 0.95), 10, BRASS, 2))
	t.set_stylebox("pressed", "Button", box(Color(0.3, 0.22, 0.14), 10, BRASS, 2))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), 10, CREAM, 2))
	t.set_stylebox("disabled", "Button", box(Color(0.1, 0.09, 0.1, 0.6), 10, Color(DIM, 0.3), 2))
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color(1, 0.9, 0.7))
	t.set_color("font_pressed_color", "Button", CREAM)
	t.set_color("font_focus_color", "Button", CREAM)
	t.set_color("font_disabled_color", "Button", DIM)
	t.set_stylebox("panel", "PanelContainer", box(Color(0.08, 0.07, 0.08, 0.92), 14, Color(BRASS, 0.35), 2, 18))
	t.set_stylebox("grabber_area", "HSlider", box(BRASS, 4, Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(BRASS, 4, Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("slider", "HSlider", box(Color(0.25, 0.22, 0.2), 4, Color(0, 0, 0, 0), 0, 3))
	t.set_color("font_color", "CheckButton", CREAM)
	t.set_color("font_hover_color", "CheckButton", CREAM)
	t.set_color("font_pressed_color", "CheckButton", CREAM)
	t.set_color("font_hover_pressed_color", "CheckButton", CREAM)
	t.set_color("font_focus_color", "CheckButton", CREAM)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(st, "CheckButton", box(Color(0, 0, 0, 0), 6, Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("focus", "CheckButton", box(Color(0, 0, 0, 0), 6, Color(CREAM, 0.6), 1, 6))
	t.set_stylebox("normal", "OptionButton", box(Color(0.12, 0.1, 0.11, 0.85), 10, Color(BRASS, 0.45), 2, 8))
	t.set_stylebox("hover", "OptionButton", box(Color(0.2, 0.16, 0.13, 0.95), 10, BRASS, 2, 8))
	t.set_stylebox("pressed", "OptionButton", box(Color(0.3, 0.22, 0.14), 10, BRASS, 2, 8))
	t.set_stylebox("focus", "OptionButton", box(Color(0, 0, 0, 0), 10, CREAM, 2, 8))
	t.set_color("font_color", "OptionButton", CREAM)
	t.set_stylebox("panel", "PopupMenu", box(Color(0.1, 0.08, 0.09), 8, BRASS, 1, 6))
	t.set_color("font_color", "PopupMenu", CREAM)
	t.set_color("font_hover_color", "PopupMenu", Color(1, 0.9, 0.7))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.3, 0.22, 0.14), 6, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	_theme = t
	return t


static func label(text: String, size := 22, color := CREAM, weight := 600, serif_font := false) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = serif(weight) if serif_font else font(weight)
	ls.font_size = size
	ls.font_color = color
	l.label_settings = ls
	return l


static func wrap(l: Label, width := 0.0) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0.0:
		l.custom_minimum_size.x = width
	return l


static func button(text: String, cb: Callable, width := 320.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 54)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


## A full-screen dark backdrop holding a centered column; returns the column.
static func page(parent: Control, dim := 0.6) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.025, 0.04, dim)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	return col
