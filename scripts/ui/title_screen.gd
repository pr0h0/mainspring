class_name TitleScreen
extends Control
## Main menu over a slowly drifting view of Brasswick, plus the level list and the letters book.

signal play(index: int)

var _view: WorldView
var _menu: Control
var _page: Control
var _t := 0.0
var _cam_base := Vector3.ZERO
var _look := Vector3.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	_view = WorldView.new()
	_view.follow = false
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
		# The stuck minute hand strains forward every few seconds and falls back.
		if _view.minute_hand:
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
	col.position = Vector2(110, 0)
	col.offset_top = -280
	col.offset_left = 110
	col.add_theme_constant_override("separation", 12)
	_menu.add_child(col)
	col.add_child(UI.label("Mainspring", 92, UI.CREAM, 700, true))
	col.add_child(UI.label("A wind-up courier. A frozen town. A few seconds at a time.", 21, Color(UI.CREAM, 0.7), 500, true))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	col.add_child(gap)
	var any: bool = not Save.data.best.is_empty()
	var first := UI.button("Continue" if any else "Begin", func():
		if not any:
			_story()
		else:
			play.emit(Save.next_unsolved()))
	col.add_child(first)
	col.add_child(UI.button("Deliveries", _show_levels))
	col.add_child(UI.button("Letters & journal", _show_book))
	col.add_child(UI.button("Settings", func():
		_menu.visible = false
		var p := SettingsPanel.new()
		p.closed.connect(func(): _menu.visible = true)
		add_child(p)))
	if not OS.has_feature("web"):
		col.add_child(UI.button("Quit", func(): get_tree().quit()))
	var done := 0
	for i in Levels.count():
		if Save.solved(i):
			done += 1
	var foot := UI.label("%d / %d delivered   ·   %d / %d journal pages" % [done, Levels.count(), Save.data.pages.size(), Levels.page_count()], 17, Color(UI.CREAM, 0.55), 600)
	col.add_child(foot)
	first.grab_focus.call_deferred()


func _story() -> void:
	_clear()
	_page = Control.new()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var col := UI.page(_page, 0.75)
	col.add_child(UI.label("Brasswick, one minute to midnight", 38, UI.CREAM, 700, true))
	col.add_child(UI.wrap(UI.label(Levels.INTRO, 23, Color(UI.CREAM, 0.88), 500, true), 680))
	var go := UI.button("Pick up the mail bag", func(): play.emit(0))
	col.add_child(go)
	go.grab_focus.call_deferred()


func _show_levels() -> void:
	_clear()
	_page = Control.new()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var col := UI.page(_page, 0.7)
	col.add_child(UI.label("Deliveries", 42, UI.CREAM, 700, true))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	var first: Button
	for i in Levels.count():
		var lv := Levels.get_level(i)
		var open := Save.is_open(i)
		var marks := ""
		if Save.solved(i):
			marks = "delivered"
			if Save.sealed(i):
				marks += " · sealed"
			if Levels.has_cog(i) and Save.has_page(i):
				marks += " · cog"
		elif open:
			marks = "waiting"
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 84)
		b.text = "%d  %s\n%s" % [i + 1, lv.title if open else "· · ·", marks]
		b.disabled = not open
		var idx := i
		b.pressed.connect(func():
			Sfx.play("click")
			play.emit(idx))
		grid.add_child(b)
		if open and first == null:
			first = b
	var back := UI.button("Back", _show_main)
	col.add_child(back)
	if first:
		first.grab_focus.call_deferred()


func _show_book() -> void:
	_clear()
	_page = Control.new()
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var col := UI.page(_page, 0.78)
	col.add_child(UI.label("Letters & journal", 42, UI.CREAM, 700, true))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	list.add_child(UI.label("Letters", 26, UI.BRASS, 700, true))
	for i in Levels.count() - 1:
		var lv := Levels.get_level(i)
		if Save.solved(i):
			list.add_child(UI.label("From %s, to %s" % [lv.from, lv.to], 16, UI.DIM, 700))
			list.add_child(UI.wrap(UI.label(lv.letter, 20, UI.PAPER, 500, true), 720))
		else:
			list.add_child(UI.label("A sealed letter (deliver %d · %s)" % [i + 1, lv.title if Save.is_open(i) else "· · ·"], 17, Color(UI.DIM, 0.7), 600))
	if Save.solved(Levels.count() - 1):
		list.add_child(UI.label("Midnight", 16, UI.DIM, 700))
		list.add_child(UI.wrap(UI.label(Levels.ENDING, 20, UI.PAPER, 500, true), 720))
	list.add_child(UI.label("Odile's journal", 26, UI.BRASS, 700, true))
	for p in Levels.count():
		if not Levels.has_cog(p):
			continue
		if Save.has_page(p):
			list.add_child(UI.wrap(UI.label(Levels.get_level(p).page, 20, UI.PAPER, 500, true), 720))
		else:
			list.add_child(UI.label("A missing page (a cog is hidden in one of the deliveries)", 17, Color(UI.DIM, 0.7), 600))
	var back := UI.button("Back", _show_main)
	col.add_child(back)
	back.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if _page and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_show_main()
