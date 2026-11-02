class_name TitleScreen
extends Control
## Main menu over a slowly drifting view of Brasswick, plus the level list and the letters book.

signal play(index: int)

var _view: WorldView
var _menu: Control
var _page: Control
var _t := 0.0
var _cam_base := Vector3.ZERO
var _thawed := false  # the first act is over: the clock runs and the snow falls
var _day := false  # the second act is over too
var _list_act := -1  # which act the Deliveries page shows
var _look := Vector3.ZERO
var _scroll: ScrollContainer  # the letters book's pages


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	_thawed = Save.solved(Levels.act_last(0))
	_day = Levels.ACTS.size() > 1 and Save.solved(Levels.act_last(1))
	_view = WorldView.new()
	_view.follow = false
	_view.thawed = _thawed
	Sfx.track("music2" if _thawed else "music")
	_view.light = 0.8 if _day else 0.0
	var vp := SubViewportContainer.new()  # keeps the 3D behind the menu
	vp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp.stretch = true
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sv := SubViewport.new()
	sv.msaa_3d = Viewport.MSAA_2X
	vp.add_child(sv)
	add_child(vp)
	sv.add_child(_view)
	# A long rooftop facing the tower: Seven, the mailbox, and Brasswick holding its breath.
	_view.build(Sim.new({"map": ["................S..........X............", "########################################"]}))
	_dress()
	_show_main()


func _process(dt: float) -> void:
	_t += dt
	if _view and _view.sim:
		var c := _view.camera
		c.position = _cam_base + Vector3(sin(_t * 0.05) * 1.2, sin(_t * 0.031) * 0.25, 0)
		c.look_at(_look + Vector3(sin(_t * 0.05) * 0.6, 0, 0))
		# The stuck minute hand strains forward every few seconds and falls back; once the clock
		# runs again it just keeps time.
		if _view.minute_hand and _thawed:
			_view.minute_hand.rotation.z = -TAU * (7.0 + _t / 60.0) / 60.0
		elif _view.minute_hand:
			var k := fmod(_t, 4.5)
			var strain := 0.0
			if k < 0.12:
				strain = k / 0.12
			elif k < 0.5:
				strain = 1.0 - ease((k - 0.12) / 0.38, 0.4)
			_view.minute_hand.rotation.z = -TAU / 60.0 + 0.045 * strain
		_view.sync(dt)


## Title-only scenery: framing, a moonlit sky full of stars, and the town's warm glow.
func _dress() -> void:
	var cx := _view.sim.w / 2.0
	var c := _view.camera
	c.fov = 54.0
	c.far = 400.0
	_cam_base = Vector3(cx - 8.0, 2.4, 14.0)
	_look = Vector3(cx - 15.4, 17.5, -30.0)
	c.position = _cam_base
	c.look_at(_look)
	# Seven looks up at the tower instead of along the roof.
	var seven: Node3D = _view.actor_node(0)
	seven.rotation.y = -1.5
	if _day:
		return  # a clear winter afternoon: no moon, no stars
	# Stars: a dome of tiny lights, thinning towards the glowing horizon.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1207
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var dot := SphereMesh.new()
	dot.radius = 0.5
	dot.height = 1.0
	dot.radial_segments = 4
	dot.rings = 2
	mm.mesh = dot
	mm.instance_count = 900
	for i in mm.instance_count:
		var up := pow(rng.randf(), 0.7)
		var dir := Vector3(rng.randf_range(-1.0, 1.0), 0.08 + up * 1.1, -1.0).normalized()
		var size := rng.randf_range(0.35, 1.0) * (1.6 if rng.randf() < 0.04 else 1.0)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * size), _cam_base + dir * 300.0))
		var warm := rng.randf()
		mm.set_instance_color(i, Color(0.8 + warm * 0.2, 0.85, 1.0 - warm * 0.15, rng.randf_range(0.35, 1.0) * clampf(up * 3.0, 0.15, 1.0)))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = mm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.vertex_color_use_as_albedo = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.disable_fog = true
	stars.material_override = sm
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_view.add_child(stars)
	# The moon, high on the right, with a soft halo.
	var moon_at := _cam_base + Vector3(12.0, 36.0, -48.0).normalized() * 280.0
	var moon := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 9.0
	ms.height = 18.0
	moon.mesh = ms
	var mmat := StandardMaterial3D.new()
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmat.albedo_color = Color(1.0, 0.96, 0.86)
	mmat.disable_fog = true
	moon.material_override = mmat
	moon.position = moon_at
	_view.add_child(moon)
	_view.add_child(_glow_quad(moon_at + Vector3(0, 0, -1), Vector2(110, 110), Color(0.75, 0.8, 1.0, 0.35)))


## A camera-facing additive glow with a radial falloff.
func _glow_quad(at: Vector3, size: Vector2, color: Color) -> MeshInstance3D:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.disable_fog = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	q.material_override = m
	q.position = at
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return q


## Just the scenery, no menu (for store art: `--menu=clean`).
func hide_menu() -> void:
	_clear()


func _clear() -> void:
	for n in [_menu, _page]:
		if n:
			n.queue_free()
	_menu = null
	_page = null


func _show_main() -> void:
	_clear()
	_menu = Control.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_menu)
	# Darker on the left behind the menu, clear on the right where the tower stands.
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.02, 0.04, 0.85))
	g.set_color(1, Color(0.02, 0.02, 0.04, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0.75, 0)
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(shade)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	col.offset_left = 110
	col.offset_top = -270
	col.add_theme_constant_override("separation", 2)
	_menu.add_child(col)
	col.add_child(UI.outline(UI.label("Mainspring", 92, UI.CREAM, 700, true), 8, 0.4))
	# A rule under the name: a gear, then a line running off to the right.
	col.add_child(UI.Glyph.new(func(ci: Control):
		var y := ci.size.y / 2.0
		UI.draw_gear(ci, Vector2(10, y), 8.0, 10, UI.BRASS)
		ci.draw_circle(Vector2(26, y), 1.6, UI.BRASS)
		ci.draw_polyline_colors(PackedVector2Array([Vector2(34, y), Vector2(ci.size.x, y)]), PackedColorArray([UI.BRASS, Color(UI.BRASS, 0.0)]), 1.0, true), Vector2(440, 20)))
	col.add_child(UI.spacer(6))
	col.add_child(UI.label("A wind-up courier. A frozen town. A few seconds at a time.", 22, Color(UI.CREAM, 0.72), 500, true))
	col.add_child(UI.spacer(26))
	var any: bool = not Save.data.best.is_empty()
	var first := _menu_item(col, "Continue" if any else "Begin", func():
		var next := Save.next_unsolved()
		var act := Levels.act_of(next)
		if not any:
			show_story(0)
		elif next == int(Levels.ACTS[act].first) and act > 0:
			show_story(act)
		else:
			play.emit(next))
	_menu_item(col, "Deliveries", _show_levels)
	_menu_item(col, "Letters & journal", _show_book)
	_menu_item(col, "Settings", func():
		_menu.visible = false
		var p := SettingsPanel.new()
		p.closed.connect(func():
			_menu.visible = true
			first.grab_focus())
		add_child(p))
	if not OS.has_feature("web"):
		_menu_item(col, "Quit", func(): get_tree().quit())
	col.add_child(UI.spacer(26))
	var done := 0
	for i in Levels.count():
		if Save.solved(i):
			done += 1
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	var ink := Color(UI.CREAM, 0.6)
	foot.add_child(UI.Glyph.new(func(ci: Control): _draw_mini_envelope(ci, Rect2(2, 5, 22, 15), Color(UI.CREAM, 0.55)), Vector2(26, 24)))
	foot.add_child(UI.label("%d of %d delivered" % [done, Levels.count()], 17, ink, 600))
	foot.add_child(UI.spacer(0))
	foot.add_child(UI.Glyph.new(func(ci: Control): UI.draw_gear(ci, Vector2(12, 12), 8.0, 9, Color(UI.CREAM, 0.55)), Vector2(24, 24)))
	foot.add_child(UI.label("%d of %d journal pages" % [Save.data.pages.size(), Levels.page_count()], 17, ink, 600))
	first.grab_focus.call_deferred()


func _menu_item(col: Control, text: String, cb: Callable) -> UI.MenuItem:
	var b := UI.button(text, cb, 340, false)
	b.add_theme_font_size_override("font_size", 34)
	b.custom_minimum_size.y = 52
	col.add_child(b)
	return b


static func _draw_mini_envelope(ci: CanvasItem, r: Rect2, col: Color) -> void:
	ci.draw_rect(r, col, false, 1.2)
	ci.draw_polyline(PackedVector2Array([r.position, Vector2(r.get_center().x, r.position.y + r.size.y * 0.6), Vector2(r.end.x, r.position.y)]), col, 1.2, true)


## The opening of act `act`, leading into its first delivery: a letter on paper.
func show_story(act := 0) -> void:
	_clear()
	_page = Control.new()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var a: Dictionary = Levels.ACTS[act]
	var col := UI.page(_page, 0.75)
	col.add_theme_constant_override("separation", 22)
	var sheet := UI.plated(col, "paper", 0.0, 50.0)
	sheet.add_theme_constant_override("separation", 8)
	if act > 0:
		sheet.add_child(UI.center(UI.label("Act %s  ·  %s" % ["I" if act == 0 else "II", a.title], 18, UI.RULE_BROWN, 700, true)))
	sheet.add_child(UI.heading(a.intro_title, 36, UI.INK_BROWN, UI.RULE_BROWN))
	sheet.add_child(UI.spacer(4))
	sheet.add_child(UI.wrap(UI.label(a.intro, 23, UI.INK_BROWN, 500, true), minf(660.0, get_viewport_rect().size.x - 220.0)))
	var go := UI.button(a.start, func(): play.emit(int(a.first)), 360)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(go)
	go.grab_focus.call_deferred()


# ------------------------------------------------------------ deliveries

## The deliveries as a sorting rack: one pigeonhole per level with a brass number plate. Open
## levels hold an envelope (stamped and postmarked once delivered, wax-sealed when sealed, a
## brass cog when its journal page was found); locked ones are empty slots.
func _show_levels() -> void:
	_clear()
	_page = Control.new()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var vp := get_viewport_rect().size
	var col := UI.page(_page, 0.7)
	col.add_theme_constant_override("separation", 10)
	col.add_child(UI.heading("Deliveries", 42))
	if _list_act < 0:
		_list_act = Levels.act_of(Save.next_unsolved())
	var act_from := int(Levels.ACTS[_list_act].first)
	var act_to := Levels.act_last(_list_act)
	var tabs_h := 0.0
	if Save.is_open(int(Levels.ACTS[mini(1, Levels.ACTS.size() - 1)].first)) and Levels.ACTS.size() > 1:
		var tabs := HBoxContainer.new()
		tabs.alignment = BoxContainer.ALIGNMENT_CENTER
		tabs.add_theme_constant_override("separation", 18)
		col.add_child(tabs)
		for a in Levels.ACTS.size():
			var act_n := a
			var tb := UI.button("%s · %s" % [_roman(a + 1), Levels.ACTS[a].title], func():
				_list_act = act_n
				_show_levels(), 0)
			tb.add_theme_font_size_override("font_size", 25)
			if a != _list_act:
				tb.modulate = Color(1, 1, 1, 0.5)
			else:
				tb.add_theme_color_override("font_color", UI.BRASS)
			tabs.add_child(tb)
		tabs_h = 56.0
	# Size the rack to the act and the screen: up to six across, as few rows as that allows.
	var n := act_to - act_from + 1
	var cell := Vector2(150, 108)
	var gap := Vector2(12, 12)
	var max_cols := clampi(int((vp.x - 140.0 + gap.x) / (cell.x + gap.x)), 3, 6)
	var rows := ceili(float(n) / max_cols)
	var cols := ceili(float(n) / rows)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", int(gap.x))
	grid.add_theme_constant_override("v_separation", int(gap.y))
	col.add_child(UI.spacer(4))
	var rack := UI.plated(col, "wood", 0.0, 26.0)
	# Squeeze the slots a little on short screens before falling back to scrolling.
	var room := vp.y - 330.0 - tabs_h
	cell.y = clampf((room - (rows - 1) * gap.y) / rows, 92.0, cell.y)
	var grid_h := rows * (cell.y + gap.y) - gap.y
	if grid_h > room:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		scroll.custom_minimum_size = Vector2(cols * (cell.x + gap.x) - gap.x + 14, maxf(room, cell.y + 10))
		rack.add_child(scroll)
		scroll.add_child(grid)
	else:
		rack.add_child(grid)
	# What the focused envelope is: shown under the rack.
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.custom_minimum_size = Vector2(0, 62)
	col.add_child(info)
	var info_title := UI.center(UI.label("", 27, UI.CREAM, 700, true))
	var info_line := UI.center(UI.label("", 17, Color(UI.CREAM, 0.6), 600))
	info.add_child(info_title)
	info.add_child(info_line)
	var first: Control
	for i in range(act_from, act_to + 1):
		var lv := Levels.get_level(i)
		var e := Envelope.new()
		e.num = i + 1
		e.title = lv.title
		e.open = Save.is_open(i)
		e.done = Save.solved(i)
		e.sealed = Save.sealed(i)
		e.has_cog = Levels.has_cog(i)
		e.cog = Save.has_page(i)
		e.custom_minimum_size = cell
		var idx := i
		e.pressed.connect(func():
			Sfx.play("click")
			play.emit(idx))
		e.focus_entered.connect(func():
			info_title.text = "%d · %s" % [idx + 1, lv.title]
			info_line.text = _envelope_line(idx))
		grid.add_child(e)
		if e.open and (first == null or (not e.done and (first as Envelope).done)):
			first = e  # the first undelivered letter, else the first one
	# Right from the newest open letter stays put rather than jumping down to Back.
	var opened := grid.get_children().filter(func(c): return (c as Envelope).open)
	if not opened.is_empty():
		opened[-1].focus_neighbor_right = NodePath(".")
	var back := UI.button("Back", _show_main, 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.focus_entered.connect(func():
		info_title.text = ""
		info_line.text = "")
	col.add_child(back)
	if first:
		first.grab_focus.call_deferred()
	else:
		back.grab_focus.call_deferred()


static func _envelope_line(i: int) -> String:
	var lv := Levels.get_level(i)
	var bits: Array[String] = []
	if lv.get("from", "") != "":
		bits.append("From %s, to %s" % [lv.from, lv.to])
	if Save.solved(i):
		var b := Save.best(i)
		bits.append("delivered with %d echo%s" % [b, "" if b == 1 else "es"])
		bits.append("sealed" if Save.sealed(i) else "seal needs %d" % int(lv.par))
	else:
		bits.append("waiting to be delivered")
	if Levels.has_cog(i):
		bits.append("journal page found" if Save.has_page(i) else "a cog is hidden here" if Save.solved(i) else "")
	return "   ·   ".join(bits.filter(func(s): return s != ""))


static func _roman(n: int) -> String:
	return ["", "I", "II", "III", "IV", "V"][n] if n < 6 else str(n)


class Envelope extends Button:
	var num := 1
	var title := ""
	var open := false
	var done := false
	var sealed := false
	var has_cog := false
	var cog := false
	var _k := 0.0

	func _ready() -> void:
		text = ""
		disabled = not open
		focus_mode = FOCUS_ALL if open else FOCUS_NONE
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if open else CURSOR_ARROW
		for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		mouse_entered.connect(func():
			if open:
				grab_focus())

	func _process(dt: float) -> void:
		var want := 1.0 if has_focus() else 0.0
		if absf(_k - want) > 0.001:
			_k = move_toward(_k, want, dt * 7.0)
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var hole := Rect2(0, 0, w, h - 20)
		# The pigeonhole: a dark recess, shadowed under its top edge.
		draw_rect(hole, Color(0.02, 0.012, 0.01, 0.72))
		for i in 6:
			draw_rect(Rect2(hole.position + Vector2(0, i * 2), Vector2(w, 2)), Color(0, 0, 0, 0.3 - i * 0.05))
		draw_line(Vector2(0, hole.end.y), Vector2(w, hole.end.y), Color(UI.BRASS, 0.3), 2.0)
		var e := ease(_k, -2.0)
		draw_rect(hole, Color(UI.BRASS, 0.22 + 0.68 * e), false, 1.0 + e)
		# The brass number plate under it.
		var nf := UI.font(800)
		var label := str(num)
		var tw := nf.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var pw := maxf(34.0, tw + 20.0)
		var plate := Rect2(w / 2.0 - pw / 2.0, h - 17, pw, 16)
		draw_rect(plate, Color(UI.BRASS, 0.95) if open else Color(UI.BRASS.darkened(0.3), 0.5))
		draw_rect(plate, Color(UI.BRASS.darkened(0.5), 0.8 if open else 0.4), false, 1.0)
		draw_circle(plate.position + Vector2(4.5, 8), 1.3, Color(0, 0, 0, 0.45))
		draw_circle(plate.position + Vector2(pw - 4.5, 8), 1.3, Color(0, 0, 0, 0.45))
		draw_string(nf, Vector2(w / 2.0 - tw / 2.0, h - 4.5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.12, 0.08, 0.04, 1.0 if open else 0.75))
		var f := UI.serif(700)
		if not open:
			return
		# The envelope, sliding up out of its slot when focused.
		var lift := 7.0 * e
		var er := Rect2(9, 11 - lift, w - 18, hole.size.y - 17)
		draw_rect(Rect2(er.position + Vector2(2, 3 + lift * 0.5), er.size), Color(0, 0, 0, 0.45))
		var tint := 0.025 * sin(num * 2.3)
		var paper := Color(UI.PAPER.r + tint, UI.PAPER.g + tint * 0.6, UI.PAPER.b - tint, 1.0)
		if not done:
			paper = paper.lightened(0.04)
		draw_rect(er, paper)
		draw_rect(er, Color(UI.RULE_BROWN, 0.55), false, 1.0)
		var tip := Vector2(er.get_center().x, er.position.y + er.size.y * 0.44)
		draw_colored_polygon(PackedVector2Array([er.position, Vector2(er.end.x, er.position.y), tip]), paper.darkened(0.07))
		draw_polyline(PackedVector2Array([er.position, tip, Vector2(er.end.x, er.position.y)]), Color(UI.RULE_BROWN, 0.5), 1.0, true)
		# The address: the delivery's name, shrunk to fit.
		var fs := 17
		while fs > 11 and f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > er.size.x - 14:
			fs -= 1
		var ttw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(er.get_center().x - ttw / 2.0, er.end.y - 9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(UI.INK_BROWN, 0.95 if done else 0.8))
		# A stamp in the corner; postmarked once delivered.
		var st := Rect2(er.end.x - 21, er.position.y + 5, 15, 18)
		draw_rect(st, Color(1, 0.98, 0.92))
		draw_rect(st.grow(-2.0), Color(0.33, 0.42, 0.55) if (num % 2 == 0) else Color(0.62, 0.28, 0.24))
		draw_circle(st.grow(-2.0).get_center() + Vector2(0, -1), 2.6, Color(1, 0.95, 0.85, 0.5))
		if done:
			var pm := Vector2(st.position.x - 4, st.get_center().y + 3)
			draw_arc(pm, 10, 0, TAU, 24, Color(0.15, 0.13, 0.22, 0.6), 1.1, true)
			for k in 3:
				var pts := PackedVector2Array()
				for i in 7:
					pts.append(Vector2(pm.x + 7 + i * 3.0, pm.y - 5 + k * 5 + sin(i * 1.2 + k) * 1.3))
				draw_polyline(pts, Color(0.15, 0.13, 0.22, 0.5), 1.0, true)
		if sealed:
			UI.draw_seal(self, tip + Vector2(0, 1), 8.5)
		if has_cog and done:
			var gc := Vector2(er.position.x + 11, er.position.y + 11)
			if cog:
				UI.draw_gear(self, gc, 6.5, 8, UI.BRASS.darkened(0.1), 0.0, paper.darkened(0.07))
			else:
				UI.draw_gear_outline(self, gc, 6.5, 8, Color(UI.RULE_BROWN, 0.45), 1.0)


# ------------------------------------------------------------ letters & journal

func _show_book() -> void:
	_clear()
	_page = Control.new()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var vp := get_viewport_rect().size
	var col := UI.page(_page, 0.78)
	col.add_theme_constant_override("separation", 12)
	col.add_child(UI.heading("Letters & journal", 42))
	var sheet := UI.plated(col, "paper", 0.0, 34.0)
	var width := minf(720.0, vp.x - 200.0)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(width + 22, clampf(vp.y - 270.0, 260.0, 640.0))
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sheet.add_child(_scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(list)
	var faded := Color(UI.RULE_BROWN, 0.85)
	for a in Levels.ACTS.size():
		var act: Dictionary = Levels.ACTS[a]
		if a > 0 and not Save.is_open(int(act.first)):
			break
		if a > 0:
			list.add_child(UI.spacer(14))
		list.add_child(UI.heading("Letters · %s" % act.title, 30, UI.INK_BROWN, UI.RULE_BROWN))
		for i in range(int(act.first), Levels.act_last(a) + 1):
			var lv := Levels.get_level(i)
			if lv.letter == "":
				continue
			if Save.solved(i):
				list.add_child(UI.spacer(6))
				list.add_child(UI.label("%d.  From %s, to %s" % [i + 1, lv.from, lv.to], 18, UI.RULE_BROWN, 700, true))
				list.add_child(UI.wrap(UI.label(lv.letter, 21, UI.INK_BROWN, 500, true), width))
			else:
				list.add_child(_glyph_line(func(ci: Control): UI.draw_seal(ci, Vector2(11, 12), 8.0, "", 0.8),
					"%d.  A sealed letter%s" % [i + 1, ("  (deliver %s to read it)" % lv.title) if Save.is_open(i) else ""], faded))
		if Save.solved(Levels.act_last(a)):
			list.add_child(UI.spacer(8))
			list.add_child(UI.center(UI.label(act.ending_title, 20, UI.RULE_BROWN, 700, true)))
			list.add_child(UI.wrap(UI.label(act.ending, 21, UI.INK_BROWN, 500, true), width))
	list.add_child(UI.spacer(14))
	list.add_child(UI.heading("Odile's journal", 30, UI.INK_BROWN, UI.RULE_BROWN))
	for p in Levels.count():
		if not Levels.has_cog(p):
			continue
		list.add_child(UI.spacer(4))
		if Save.has_page(p):
			list.add_child(UI.wrap(UI.label(Levels.get_level(p).page, 21, UI.INK_BROWN, 500, true), width))
		else:
			list.add_child(_glyph_line(func(ci: Control): UI.draw_gear_outline(ci, Vector2(11, 12), 8.0, 9, faded, 1.2),
				"A missing page  (a cog is hidden in one of the deliveries)", faded))
	var back := UI.button("Back", _show_main, 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(back)
	back.grab_focus.call_deferred()


func _glyph_line(painter: Callable, text: String, color: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(UI.Glyph.new(painter, Vector2(24, 24)))
	h.add_child(UI.label(text, 19, color, 600, true))
	return h


func _input(event: InputEvent) -> void:
	# The book has one button; up/down (or the stick) scroll the pages instead.
	if not (_page and is_instance_valid(_scroll) and _scroll.is_inside_tree()):
		return
	var d := 0
	if event.is_action_pressed("ui_down", true):
		d = 1
	elif event.is_action_pressed("ui_up", true):
		d = -1
	if d != 0:
		_scroll.scroll_vertical += d * 60
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _page and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_show_main()
