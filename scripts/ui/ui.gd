class_name UI
extends RefCounted
## Colors, fonts, the shared Theme and the small hand-drawn pieces every screen is built from:
## typeset menu items with a brass gear marker, brass plates and paper sheets with double rules
## and corner ornaments, ornamental rules, gears, wax seals, postmarks and keycaps. Everything
## is drawn with draw_* calls (or tiny textures painted in code); there are no image assets.

const INK := Color(0.07, 0.06, 0.08)
const PAPER := Color(0.93, 0.88, 0.78)
const CREAM := Color(1.0, 0.96, 0.88)
const BRASS := Color(0.86, 0.66, 0.32)
const DIM := Color(0.62, 0.57, 0.5)
const ECHO := Color(0.45, 0.85, 1.0)
const RED := Color(0.85, 0.32, 0.25)
const WAX := Color(0.6, 0.11, 0.1)
const GLOW := Color(1.0, 0.86, 0.6)  # focused text
const SHADE := Color(0.035, 0.03, 0.045)
const INK_BROWN := Color(0.2, 0.14, 0.1)  # writing on paper
const RULE_BROWN := Color(0.5, 0.36, 0.22)  # rules and ornaments on paper

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


static func empty(l := 0.0, t := 0.0, r := 0.0, b := 0.0) -> StyleBoxEmpty:
	var s := StyleBoxEmpty.new()
	s.content_margin_left = l
	s.content_margin_top = t
	s.content_margin_right = r
	s.content_margin_bottom = b
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(600)
	t.default_font_size = 22
	t.set_color("font_color", "Label", CREAM)
	# Buttons are typeset words; MenuItem draws the gear marker and rule for the focused one.
	t.set_font("font", "Button", serif(600))
	t.set_font_size("font_size", "Button", 31)
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(st, "Button", empty(34, 2, 34, 6))
	t.set_color("font_color", "Button", Color(CREAM, 0.86))
	t.set_color("font_hover_color", "Button", GLOW)
	t.set_color("font_pressed_color", "Button", BRASS)
	t.set_color("font_focus_color", "Button", GLOW)
	t.set_color("font_hover_pressed_color", "Button", BRASS)
	t.set_color("font_disabled_color", "Button", Color(DIM, 0.5))
	t.set_color("font_outline_color", "Button", Color(SHADE, 0.6))
	t.set_constant("outline_size", "Button", 6)
	t.set_stylebox("panel", "PanelContainer", empty(18, 18, 18, 18))
	# Sliders: a thin engraved track, brass where it's filled, and a brass knob.
	var track := box(Color(0, 0, 0, 0.45), 2, Color(BRASS, 0.3), 1, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(Color(BRASS, 0.85), 2, Color(0, 0, 0, 0), 0, 0)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("grabber_area", "HSlider", fill)
	var fill_hi := fill.duplicate()
	fill_hi.bg_color = GLOW
	t.set_stylebox("grabber_area_highlight", "HSlider", fill_hi)
	t.set_icon("grabber", "HSlider", _knob_tex(false))
	t.set_icon("grabber_highlight", "HSlider", _knob_tex(true))
	t.set_stylebox("focus", "HSlider", StyleBoxEmpty.new())
	# Check buttons: a small brass lever.
	for c in ["CheckButton"]:
		t.set_color("font_color", c, CREAM)
		t.set_color("font_hover_color", c, CREAM)
		t.set_color("font_pressed_color", c, CREAM)
		t.set_color("font_hover_pressed_color", c, CREAM)
		t.set_color("font_focus_color", c, CREAM)
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			t.set_stylebox(st, c, empty(0, 4, 0, 4))
	t.set_icon("checked", "CheckButton", _lever_tex(true, false))
	t.set_icon("unchecked", "CheckButton", _lever_tex(false, false))
	t.set_icon("checked_mirrored", "CheckButton", _lever_tex(true, false))
	t.set_icon("unchecked_mirrored", "CheckButton", _lever_tex(false, false))
	t.set_icon("checked_disabled", "CheckButton", _lever_tex(true, true))
	t.set_icon("unchecked_disabled", "CheckButton", _lever_tex(false, true))
	# Option buttons: the choice written on an engraved line, with a brass chevron.
	var opt := StyleBoxFlat.new()
	opt.bg_color = Color(0, 0, 0, 0)
	opt.border_color = Color(BRASS, 0.45)
	opt.border_width_bottom = 1
	opt.content_margin_left = 4
	opt.content_margin_right = 8
	opt.content_margin_top = 0
	opt.content_margin_bottom = 2
	var opt_hi := opt.duplicate()
	opt_hi.border_color = BRASS
	opt_hi.border_width_bottom = 2
	t.set_stylebox("normal", "OptionButton", opt)
	t.set_stylebox("hover", "OptionButton", opt_hi)
	t.set_stylebox("pressed", "OptionButton", opt_hi)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_font("font", "OptionButton", serif(600))
	t.set_font_size("font_size", "OptionButton", 25)
	t.set_color("font_color", "OptionButton", CREAM)
	t.set_color("font_hover_color", "OptionButton", GLOW)
	t.set_color("font_focus_color", "OptionButton", GLOW)
	t.set_color("font_pressed_color", "OptionButton", GLOW)
	t.set_icon("arrow", "OptionButton", _chevron_tex())
	t.set_stylebox("panel", "PopupMenu", box(Color(0.07, 0.06, 0.07, 0.97), 3, Color(BRASS, 0.7), 1, 6))
	t.set_font("font", "PopupMenu", serif(600))
	t.set_font_size("font_size", "PopupMenu", 24)
	t.set_color("font_color", "PopupMenu", CREAM)
	t.set_color("font_hover_color", "PopupMenu", GLOW)
	t.set_stylebox("hover", "PopupMenu", box(Color(BRASS, 0.18), 2, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	# A hairline scrollbar.
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color(RULE_BROWN, 0.18)
	bar.content_margin_left = 3
	bar.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", bar)
	t.set_stylebox("scroll_focus", "VScrollBar", bar)
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var g := StyleBoxFlat.new()
		g.bg_color = Color(RULE_BROWN, 0.55 if st == "grabber" else 0.85)
		g.set_corner_radius_all(3)
		t.set_stylebox(st, "VScrollBar", g)
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


## A soft dark outline, for text over the 3D world.
static func outline(l: Label, size := 7, alpha := 0.6) -> Label:
	l.label_settings.outline_size = size
	l.label_settings.outline_color = Color(SHADE, alpha)
	return l


static func wrap(l: Label, width := 0.0) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0.0:
		l.custom_minimum_size.x = width
	return l


static func center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## A menu item: a typeset word, marked with a turning brass gear and a rule when focused.
static func button(text: String, cb: Callable, width := 320.0, centered := true) -> MenuItem:
	var b := MenuItem.new()
	b.text = text
	b.centered = centered
	b.custom_minimum_size = Vector2(width, 50)
	if not centered:  # flush left: the gear hangs in the margin
		for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(st, empty(0, 2, 34, 6))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


## A full-screen dark backdrop (darker towards the edges) holding a centered column; returns
## the column.
static func page(parent: Control, dim := 0.6) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.025, 0.04, dim)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)
	parent.add_child(vignette(0.55))
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(col)
	return col


static func vignette(alpha: float) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(SHADE, 0.0), Color(SHADE, 0.0), Color(SHADE, alpha)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 128
	gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.08, 0.5)
	var r := TextureRect.new()
	r.texture = gt
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A serif heading with an ornamental rule under it.
static func heading(text: String, size := 44, color := CREAM, rule := BRASS) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var l := center(label(text, size, color, 700, true))
	v.add_child(l)
	var o := Ornament.new()
	o.color = rule
	o.custom_minimum_size = Vector2(maxf(260.0, size * 7.0), 14)
	o.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(o)
	return v


## A plate (style "brass", "paper" or "hud") holding a column; returns the column.
static func plated(parent: Control, style := "brass", width := 0.0, pad := 34.0) -> VBoxContainer:
	var p := Plate.new()
	p.style = style
	p.pad = pad
	p.custom_minimum_size.x = width
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	return v


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# ------------------------------------------------------------ drawing

static func gear_points(c: Vector2, r: float, teeth: int, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ri := r * 0.76
	var s := TAU / teeth
	for i in teeth:
		var a := rot + s * i
		pts.append(c + Vector2.from_angle(a - s * 0.5) * ri)
		pts.append(c + Vector2.from_angle(a - s * 0.24) * ri)
		pts.append(c + Vector2.from_angle(a - s * 0.15) * r)
		pts.append(c + Vector2.from_angle(a + s * 0.15) * r)
		pts.append(c + Vector2.from_angle(a + s * 0.24) * ri)
	return pts


## A gear with a hole (the hole is painted in `hole`, or left as a ring if hole is clear).
static func draw_gear(ci: CanvasItem, c: Vector2, r: float, teeth: int, col: Color, rot := 0.0, hole := Color(0, 0, 0, 0)) -> void:
	ci.draw_colored_polygon(gear_points(c, r, teeth, rot), col)
	if hole.a > 0.0:
		ci.draw_circle(c, r * 0.32, hole)
	else:
		ci.draw_circle(c, r * 0.3, Color(SHADE, col.a * 0.85))


static func draw_gear_outline(ci: CanvasItem, c: Vector2, r: float, teeth: int, col: Color, w := 1.2) -> void:
	var p := gear_points(c, r, teeth)
	p.append(p[0])
	ci.draw_polyline(p, col, w, true)
	ci.draw_arc(c, r * 0.3, 0, TAU, 16, col, w, true)


## A blob of red sealing wax with a pressed ring, optionally stamped with a word or number.
static func draw_seal(ci: CanvasItem, c: Vector2, r: float, text := "", alpha := 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 22:
		var a := TAU * i / 22.0
		var k := 1.0 + 0.07 * sin(i * 2.7) + 0.05 * sin(i * 5.3 + 1.0)
		pts.append(c + Vector2.from_angle(a) * r * k)
	ci.draw_colored_polygon(pts, Color(WAX.darkened(0.35), alpha))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.9 + Vector2(-0.6, -0.8))
	ci.draw_colored_polygon(inner, Color(WAX, alpha))
	ci.draw_arc(c, r * 0.64, 0, TAU, 28, Color(WAX.darkened(0.45), alpha * 0.9), maxf(1.0, r * 0.09), true)
	ci.draw_arc(c + Vector2(-0.6, -0.8), r * 0.64, PI * 1.05, PI * 1.55, 10, Color(1, 0.6, 0.5, alpha * 0.35), maxf(1.0, r * 0.06), true)
	ci.draw_arc(c, r * 0.8, PI * 1.1, PI * 1.45, 10, Color(1, 0.75, 0.65, alpha * 0.3), maxf(1.0, r * 0.07), true)
	if text != "":
		var f := font(800) if text.is_valid_int() else serif(700)
		var fs := int(r * (0.95 if text.length() <= 2 else 0.55))
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(f, c + Vector2(-w / 2.0, fs * 0.34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.82, 0.72, alpha * 0.9))


## A round postmark: two rings, a word round the top and a number in the middle, with wavy
## cancellation lines trailing off to the right.
static func draw_postmark(ci: CanvasItem, c: Vector2, r: float, mid: String, col: Color, lines := 3, top := "") -> void:
	ci.draw_arc(c, r, 0, TAU, 40, col, 1.4, true)
	ci.draw_arc(c, r - 3.5, 0, TAU, 40, Color(col, col.a * 0.7), 1.0, true)
	var f := serif(700)
	if mid != "":
		var mf := font(800) if mid.is_valid_int() else f
		var fs := int(r * (0.8 if mid.length() < 3 else 0.6) * (0.62 if top != "" else 1.0))
		var w := mf.get_string_size(mid, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(mf, c + Vector2(-w / 2.0, fs * 0.36), mid, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if top != "":
		# Letters spaced around the upper arc.
		var fs2 := maxi(8, int(r * 0.31))
		var n := top.length()
		var span := minf(PI * 1.05, n * 0.24)
		for i in n:
			var a := -PI / 2.0 - span / 2.0 + span * (i + 0.5) / n
			var p := c + Vector2.from_angle(a) * (r - 9.0)
			var ch := top[i]
			var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
			ci.draw_set_transform(p, a + PI / 2.0, Vector2.ONE)
			ci.draw_string(f, Vector2(-w / 2.0, fs2 * 0.35), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, col)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in lines:
		var y := c.y - (lines - 1) * 4.0 + k * 8.0
		var pts := PackedVector2Array()
		for i in 15:
			var x := c.x + r + 3.0 + i * 3.4
			pts.append(Vector2(x, y + sin(i * 0.95 + k) * 2.0))
		ci.draw_polyline(pts, Color(col, col.a * 0.8), 1.2, true)


## A keycap with a key name on it.
static func draw_keycap(ci: CanvasItem, pos: Vector2, text: String, h := 24.0) -> float:
	var f := font(800)
	var fs := int(h * 0.56)
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := maxf(h, tw + h * 0.6)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.bg_color = Color(0.32, 0.27, 0.22, 0.95)
	ci.draw_style_box(sb, Rect2(pos + Vector2(0, 2), Vector2(w, h)))
	sb.bg_color = Color(0.92, 0.87, 0.77, 0.95)
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.border_width_top = 1
	ci.draw_style_box(sb, Rect2(pos, Vector2(w, h - 1)))
	ci.draw_string(f, pos + Vector2((w - tw) / 2.0, h * 0.5 + fs * 0.34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.16, 0.12, 0.1))
	return w


## The light backing plate behind the in-level gauges: clipped corners, a brass hairline and
## a fainter one inside it.
static func draw_hud_plate(ci: CanvasItem, r: Rect2) -> void:
	var pts := notch(r, 7.0)
	ci.draw_colored_polygon(pts, Color(SHADE, 0.62))
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(BRASS, 0.6), 1.0, true)
	var inner := notch(r.grow(-3.5), 5.0)
	inner.append(inner[0])
	ci.draw_polyline(inner, Color(BRASS, 0.2), 1.0, true)


static func notch(r: Rect2, n: float) -> PackedVector2Array:
	var a := r.position
	var b := r.end
	return PackedVector2Array([
		Vector2(a.x + n, a.y), Vector2(b.x - n, a.y), Vector2(b.x, a.y + n), Vector2(b.x, b.y - n),
		Vector2(b.x - n, b.y), Vector2(a.x + n, b.y), Vector2(a.x, b.y - n), Vector2(a.x, a.y + n)])


## Small diamond.
static func draw_diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


## A thin rule fading out at both ends, from a to b.
static func draw_fade_line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w := 1.0) -> void:
	var m := (a + b) / 2.0
	ci.draw_polyline_colors(PackedVector2Array([a, m, b]), PackedColorArray([Color(col, 0.0), col, Color(col, 0.0)]), w, true)


# ------------------------------------------------------------ painted textures

static func _paint(w: int, h: int, f: Callable) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			img.set_pixel(x, y, f.call(Vector2(x + 0.5, y + 0.5)))
	return ImageTexture.create_from_image(img)


static func _over(dst: Color, src: Color, cover: float) -> Color:
	var a := clampf(cover, 0.0, 1.0) * src.a
	var out_a := a + dst.a * (1.0 - a)
	if out_a <= 0.0:
		return Color(0, 0, 0, 0)
	var rgb := (Color(src.r, src.g, src.b) * a + Color(dst.r, dst.g, dst.b) * dst.a * (1.0 - a)) / out_a
	return Color(rgb.r, rgb.g, rgb.b, out_a)


static func _knob_tex(hi: bool) -> ImageTexture:
	return _paint(22, 22, func(p: Vector2) -> Color:
		var d := p.distance_to(Vector2(11, 11))
		var c := Color(0, 0, 0, 0)
		c = _over(c, Color(0, 0, 0, 0.4), 9.6 - d)
		c = _over(c, BRASS.darkened(0.35), 8.5 - d)
		c = _over(c, GLOW if hi else BRASS, 7.2 - d)
		c = _over(c, BRASS.darkened(0.3), 1.0 - absf(d - 3.2))
		c = _over(c, Color(1, 1, 1, 0.5), 1.6 - p.distance_to(Vector2(8.5, 8.0)))
		return c)


static func _lever_tex(on: bool, disabled: bool) -> ImageTexture:
	var a := 0.45 if disabled else 1.0
	return _paint(50, 28, func(p: Vector2) -> Color:
		var q := Vector2(clampf(p.x, 14.0, 36.0), 14.0)
		var d := p.distance_to(q) - 11.0
		var c := Color(0, 0, 0, 0)
		c = _over(c, Color(BRASS, 0.85 * a), 0.5 - d)
		c = _over(c, Color(0.36, 0.25, 0.12, 0.95 * a) if on else Color(0.06, 0.05, 0.06, 0.9 * a), -0.8 - d)
		var k := Vector2(36.0 if on else 14.0, 14.0)
		var dk := p.distance_to(k)
		c = _over(c, Color(0, 0, 0, 0.35 * a), 8.6 - dk)
		c = _over(c, Color(GLOW if on else DIM, a), 7.4 - dk)
		c = _over(c, Color(1, 1, 1, 0.45 * a), 1.4 - p.distance_to(k + Vector2(-2.5, -2.5)))
		return c)


static func _chevron_tex() -> ImageTexture:
	return _paint(16, 12, func(p: Vector2) -> Color:
		var x := absf(p.x - 8.0)
		var y := p.y - 3.0
		var d := absf(y - (6.0 - x * 0.75)) * 0.8
		var inside := 1.0 if x < 6.5 and y > -1.0 and y < 7.5 else 0.0
		return Color(BRASS, clampf(1.4 - d, 0.0, 1.0) * inside))


# ------------------------------------------------------------ widgets

## A typeset menu item. When focused (the mouse focuses what it points at, so there is only
## ever one), a small brass gear turns beside it and a rule draws itself under the word.
class MenuItem extends Button:
	var centered := true
	var _k := 0.0
	var _spin := 0.0

	func _ready() -> void:
		alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
		mouse_entered.connect(func():
			if not disabled and focus_mode != FOCUS_NONE:
				grab_focus())

	func _process(dt: float) -> void:
		var want := 1.0 if has_focus() and not disabled else 0.0
		if absf(_k - want) > 0.001 or want > 0.0:
			_k = move_toward(_k, want, dt * 6.0)
			_spin += dt * 0.9
			queue_redraw()

	func _draw() -> void:
		if _k <= 0.01:
			return
		var f := get_theme_font("font")
		var fs := get_theme_font_size("font_size")
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x0: float = (size.x - tw) / 2.0 if centered else get_theme_stylebox("normal").get_margin(SIDE_LEFT)
		var cy := size.y / 2.0 - 1.0
		var e := ease(_k, -2.0)
		var col := Color(UI.BRASS, e)
		var gr := clampf(fs * 0.27, 6.0, 9.0)
		var off := gr + 9.0 + (1.0 - e) * 8.0
		UI.draw_gear(self, Vector2(x0 - off, cy), gr, 8, col, _spin)
		if centered:
			UI.draw_gear(self, Vector2(x0 + tw + off, cy), gr, 8, col, -_spin)
		var y := cy + fs * 0.42
		var half := tw * 0.5 * e + 6.0
		var mid := x0 + tw / 2.0
		UI.draw_fade_line(self, Vector2(mid - half, y), Vector2(mid + half, y), Color(UI.BRASS, 0.9 * e), 1.2)


## A thin rule fading out to both sides with a diamond and two dots in the middle.
class Ornament extends Control:
	var color := UI.BRASS

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var w := size.x / 2.0
		UI.draw_diamond(self, c, 4.0, color)
		for s in [-1.0, 1.0]:
			draw_circle(c + Vector2(s * 11.0, 0), 1.6, color)
			draw_polyline_colors(PackedVector2Array([c + Vector2(s * 18.0, 0), c + Vector2(s * w, 0)]), PackedColorArray([color, Color(color, 0.0)]), 1.0, true)


## A panel drawn as a brass-ruled plate ("brass": dark, for menus), a sheet of paper ("paper":
## letters, the journal) or a light backing plate for the in-level bar ("hud"). Double rules
## with corner ornaments; corners are clipped like an engraved name plate.
class Plate extends PanelContainer:
	var style := "brass"
	var pad := 34.0
	var postmark := ""  # paper: a postmark over the top-right corner
	var sealed := false  # paper: a wax seal over the bottom-right corner

	func _ready() -> void:
		var p := pad
		add_theme_stylebox_override("panel", UI.empty(p, p * 0.8, p + (64.0 if postmark != "" else 0.0), p * 0.8))
		mouse_filter = MOUSE_FILTER_IGNORE if style == "hud" else MOUSE_FILTER_STOP

	func _notch(r: Rect2, n: float) -> PackedVector2Array:
		return UI.notch(r, n)

	func _outline(pts: PackedVector2Array, col: Color, w: float) -> void:
		var p := pts.duplicate()
		p.append(p[0])
		draw_polyline(p, col, w, true)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		match style:
			"paper":
				draw_rect(Rect2(r.position + Vector2(3, 7), r.size), Color(0, 0, 0, 0.32))
				draw_rect(r, UI.PAPER)
				# Foxed edges: a few nested, faint brown frames.
				for i in 6:
					draw_rect(r.grow(-i * 2.0 - 1.0), Color(0.55, 0.4, 0.22, 0.07 - i * 0.01), false, 2.0)
				var rule := Color(UI.RULE_BROWN, 0.75)
				var o := r.grow(-10)
				var i2 := r.grow(-14)
				draw_rect(o, rule, false, 1.2)
				draw_rect(i2, Color(rule, 0.45), false, 1.0)
				for c: Vector2 in [o.position, Vector2(o.end.x, o.position.y), o.end, Vector2(o.position.x, o.end.y)]:
					var into := (r.get_center() - c).sign()
					UI.draw_diamond(self, c, 4.5, rule)
					draw_circle(c + into * Vector2(10, 10), 1.6, rule)
				if postmark != "":
					var pc := Vector2(size.x - 62, 58)
					UI.draw_postmark(self, pc, 32.0, postmark, Color(0.2, 0.17, 0.3, 0.85), 0, "BRASSWICK")
				if sealed:
					UI.draw_seal(self, Vector2(size.x - 34, size.y - 30), 23.0, "M")
			"hud":
				UI.draw_hud_plate(self, r)
			_:
				var pts := _notch(r, 12.0)
				draw_colored_polygon(pts, Color(0.05, 0.042, 0.055, 0.93))
				if style == "wood":
					# Dark varnished wood: a warm fill with faint grain.
					draw_colored_polygon(pts, Color(0.16, 0.105, 0.07, 0.9))
					for i in int(size.y / 7.0):
						var y := 4.0 + i * 7.0 + sin(i * 1.7) * 2.0
						draw_line(Vector2(8, y), Vector2(size.x - 8, y + sin(i * 0.9) * 1.5), Color(0, 0, 0, 0.06 + 0.04 * sin(i * 2.3)), 1.0)
				_outline(pts, Color(UI.BRASS, 0.8), 1.5)
				_outline(_notch(r.grow(-6.0), 9.0), Color(UI.BRASS, 0.3), 1.0)
				var g := r.grow(-6.0)
				for c: Vector2 in [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)]:
					var into := (r.get_center() - c).sign()
					UI.draw_diamond(self, c + into * Vector2(13, 13), 3.0, Color(UI.BRASS, 0.7))
				# A small gear set into the middle of the top rule.
				UI.draw_gear(self, Vector2(size.x / 2.0, 0), 9.0, 10, UI.BRASS, 0.0, Color(0.05, 0.042, 0.055))


## A gear shown beside a settings row while one of its controls is focused.
class Marker extends Control:
	var on := false:
		set(v):
			on = v
			queue_redraw()
	var _spin := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(22, 22)
		mouse_filter = MOUSE_FILTER_IGNORE

	func _process(dt: float) -> void:
		if on:
			_spin += dt * 0.9
			queue_redraw()

	func _draw() -> void:
		if on:
			UI.draw_gear(self, size / 2.0, 8.0, 8, UI.BRASS, _spin)


## A small drawing control: calls `painter(self)` to draw.
class Glyph extends Control:
	var painter: Callable

	func _init(p: Callable, s: Vector2) -> void:
		painter = p
		custom_minimum_size = s
		mouse_filter = MOUSE_FILTER_IGNORE

	func _draw() -> void:
		painter.call(self)
