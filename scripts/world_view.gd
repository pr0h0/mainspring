class_name WorldView
extends Node3D
## Draws a Sim in 3D: the map, its machines, the courier and its echoes, and frozen Brasswick
## behind it all. Gameplay lives on the z = 0 plane in tile units.

const FOV := 36.0

var sim: Sim
var camera: Camera3D
var follow := true  # gently lean the camera towards the player

var _static: Node3D
var _dynamic: Node3D
var _actors := []  # Courier nodes, same order as sim.actors
var _crates := []
var _doors := []
var _plates := []
var _lifts := []
var _cogs := []
var _steam := []  # [particles, glow, cell] per vent
var _trails: MultiMeshInstance3D
var _exit_flag: Node3D
var _time := 0.0
var _cam_target := Vector3.ZERO
var _fit_dist := 10.0
var _mats := {}


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.1
	camera.far = 200.0
	add_child(camera)
	camera.make_current()
	_environment()
	get_viewport().size_changed.connect(_fit_camera)


# ------------------------------------------------------------ build

## Builds the map for this sim (call once per level).
func build(s: Sim) -> void:
	sim = s
	if _static:
		_static.queue_free()
	_static = Node3D.new()
	add_child(_static)
	_build_walls()
	_build_backdrop()
	_build_machines()
	_fit_camera()
	camera.position = _cam_target
	rebuild_dynamic(s)


## Recreates everything that a new loop resets (actors, crates and machine state).
func rebuild_dynamic(s: Sim) -> void:
	sim = s
	if _dynamic:
		_dynamic.queue_free()
	_dynamic = Node3D.new()
	add_child(_dynamic)
	_actors.clear()
	for a in s.actors:
		var c := Courier.new()
		c.echo = a.echo
		_dynamic.add_child(c)
		_actors.append(c)
	_crates.clear()
	for c in s.crates:
		var n := _crate()
		_dynamic.add_child(n)
		_crates.append(n)
	_trails = MultiMeshInstance3D.new()
	_dynamic.add_child(_trails)
	sync(0.0)


func _mat(key: String, color: Color, rough := 0.8, metal := 0.0, emit := 0.0, alpha := 1.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alpha)
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


func _box(size: Vector3, mat: Material, pos := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	(parent if parent else _static).add_child(mi)
	return mi


func _build_walls() -> void:
	var cells := []
	for y in sim.h:
		for x in sim.w:
			if sim.walls[y * sim.w + x] == 1:
				cells.append(Vector2i(x, y))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 1.0, 1.4)
	mm.mesh = bm
	mm.instance_count = cells.size()
	var caps := []
	for i in cells.size():
		var c: Vector2i = cells[i]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(c.x + 0.5, c.y + 0.5, 0)))
		var n := _hash(c.x, c.y)
		var stone := Color(0.4, 0.36, 0.37).lerp(Color(0.48, 0.4, 0.36), n)
		if c.y == 0 or c.x == 0 or c.x == sim.w - 1 or c.y == sim.h - 1:
			stone = stone.darkened(0.3)
		mm.set_instance_color(i, stone)
		if c.y + 1 < sim.h and sim.walls[(c.y + 1) * sim.w + c.x] == 0 and c.y + 1 < sim.h - 1:
			caps.append(c)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	mi.material_override = m
	_static.add_child(mi)
	# A back wall behind the playfield, so the puzzle reads apart from the town behind it.
	var back := MultiMesh.new()
	back.transform_format = MultiMesh.TRANSFORM_3D
	back.use_colors = true
	var tile := BoxMesh.new()
	tile.size = Vector3(0.96, 0.96, 0.1)
	back.mesh = tile
	var inner := []
	for y in range(1, sim.h - 1):
		for x in range(1, sim.w - 1):
			if sim.walls[y * sim.w + x] == 0:
				inner.append(Vector2i(x, y))
	back.instance_count = inner.size()
	for i in inner.size():
		var c: Vector2i = inner[i]
		back.set_instance_transform(i, Transform3D(Basis(), Vector3(c.x + 0.5, c.y + 0.5, -0.72)))
		back.set_instance_color(i, Color(0.24, 0.18, 0.18).lerp(Color(0.3, 0.22, 0.2), _hash(c.y, c.x)))
	var back_mi := MultiMeshInstance3D.new()
	back_mi.multimesh = back
	back_mi.material_override = m
	_static.add_child(back_mi)
	_box(Vector3(sim.w - 2, sim.h - 2, 0.1), _mat("mortar", Color(0.1, 0.08, 0.08), 1.0), Vector3(sim.w / 2.0, sim.h / 2.0, -0.78))
	# Wooden caps on every walkable top, so floors read clearly.
	var cap_mat := _mat("cap", Color(0.55, 0.38, 0.22), 0.7)
	var trim := _mat("trim", UI.BRASS, 0.35, 0.8)
	for c in caps:
		_box(Vector3(1.0, 0.14, 1.46), cap_mat, Vector3(c.x + 0.5, c.y + 0.93, 0))
		_box(Vector3(1.0, 0.03, 0.04), trim, Vector3(c.x + 0.5, c.y + 0.86, 0.73))
	# One-way ledges: a thin plank on brackets.
	var plank := _mat("plank", Color(0.6, 0.42, 0.25), 0.75)
	for c in sim.ledges:
		_box(Vector3(1.0, 0.16, 1.1), plank, Vector3(c.x + 0.5, c.y + 0.9, 0))


func _hash(x: int, y: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663)
	return float(absi(h) % 1000) / 1000.0


func _build_backdrop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.w * 31 + sim.h
	var cx := sim.w / 2.0
	# Rows of houses, nearer ones a little lighter.
	for row in 3:
		var z := -6.0 - row * 7.0
		var col := Color(0.12, 0.13, 0.2).lerp(Color(0.07, 0.08, 0.13), row / 2.0)
		var wall_m := _mat("house%d" % row, col, 0.95)
		var x := cx - 40.0
		while x < cx + 40.0:
			var wid := rng.randf_range(2.5, 5.0)
			var hgt := rng.randf_range(4.0, 9.0) + row * 2.5
			_box(Vector3(wid, hgt, 3.0), wall_m, Vector3(x + wid / 2.0, hgt / 2.0 - 1.0, z))
			var roof := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(wid + 0.4, rng.randf_range(1.2, 2.4), 3.2)
			roof.mesh = pm
			roof.material_override = _mat("roof%d" % row, col.darkened(0.3), 0.95)
			roof.position = Vector3(x + wid / 2.0, hgt - 1.0 + pm.size.y / 2.0, z)
			_static.add_child(roof)
			# Windows frozen mid-evening: some lit, some dark.
			for wy in range(1, int(hgt) - 1, 2):
				for wx in range(1, int(wid)):
					if rng.randf() < 0.35:
						var lit := rng.randf() < 0.55
						var wm := _mat("win_lit", Color(1.0, 0.72, 0.38), 1.0, 0.0, 2.2) if lit else _mat("win_dark", Color(0.05, 0.05, 0.08), 1.0)
						_box(Vector3(0.45, 0.6, 0.05), wm, Vector3(x + wx, wy - 0.4, z + 1.53))
			x += wid + rng.randf_range(0.0, 1.0)
	# The clock tower, stopped at one minute to midnight.
	var tz := -34.0
	var stone := _mat("tower", Color(0.1, 0.1, 0.16), 0.95)
	_box(Vector3(7, 40, 7), stone, Vector3(cx, 14, tz))
	var spire := MeshInstance3D.new()
	var sp := PrismMesh.new()
	sp.size = Vector3(8, 9, 8)
	spire.mesh = sp
	spire.material_override = _mat("spire", Color(0.07, 0.07, 0.11), 0.95)
	spire.position = Vector3(cx, 38.5, tz)
	_static.add_child(spire)
	var face := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.8
	cm.bottom_radius = 2.8
	cm.height = 0.2
	face.mesh = cm
	face.material_override = _mat("face", Color(0.98, 0.88, 0.62), 0.6, 0.0, 2.4)
	face.rotation.x = PI / 2.0
	face.position = Vector3(cx, 27, tz + 3.6)
	_static.add_child(face)
	var hand_m := _mat("hand", Color(0.08, 0.06, 0.05), 0.5, 0.5)
	for hand in [[2.3, -TAU / 60.0], [1.6, -TAU * 11.983 / 12.0]]:
		var pivot := Node3D.new()
		pivot.position = face.position + Vector3(0, 0, 0.15)
		pivot.rotation.z = hand[1]
		_static.add_child(pivot)
		_box(Vector3(0.16, hand[0], 0.06), hand_m, Vector3(0, hand[0] / 2.0 - 0.2, 0), pivot)
	# Snow, hanging in the air where it stopped.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var q := SphereMesh.new()
	q.radius = 0.04
	q.height = 0.08
	q.radial_segments = 6
	q.rings = 3
	mm.mesh = q
	mm.instance_count = 600
	for i in mm.instance_count:
		var p := Vector3(rng.randf_range(-12, sim.w + 12), rng.randf_range(-1, sim.h + 8), rng.randf_range(-14, 3))
		if p.x > -0.5 and p.x < sim.w + 0.5 and p.y < sim.h + 0.5 and p.z > -1.5:
			p.z -= 4.5  # none inside the playfield
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.6, 1.4)), p))
	var snow := MultiMeshInstance3D.new()
	snow.multimesh = mm
	snow.material_override = _mat("snow", Color(0.92, 0.95, 1.0), 1.0, 0.0, 0.6)
	_static.add_child(snow)
	# Ground beyond the play area.
	_box(Vector3(160, 1, 60), _mat("ground", Color(0.16, 0.17, 0.22), 1.0), Vector3(cx, -1.5, -25))


func _build_machines() -> void:
	_plates.clear()
	_doors.clear()
	_lifts.clear()
	_cogs.clear()
	_steam.clear()
	var iron := _mat("iron", Color(0.2, 0.2, 0.22), 0.5, 0.7)
	for pl in sim.plates:
		var base := _box(Vector3(0.9, 0.08, 0.9), iron, Vector3(pl.cell.x + 0.5, pl.cell.y + 0.04, 0))
		var col: Color = UI.LINK[pl.id]
		var top := _box(Vector3(0.72, 0.08, 0.72), _mat("plate_%s_%d_%d" % [pl.id, pl.cell.x, pl.cell.y], col, 0.4, 0.3, 0.6), Vector3(pl.cell.x + 0.5, pl.cell.y + 0.12, 0))
		_plates.append({"top": top, "base_y": pl.cell.y + 0.12, "col": col, "on": 0.0})
		base.name = "plate"
	for d in sim.doors:
		var n := Node3D.new()
		n.position = Vector3(d.cell.x + 0.5, d.cell.y + 0.5, 0)
		_static.add_child(n)
		_box(Vector3(0.86, 1.0, 0.6), _mat("door", Color(0.26, 0.24, 0.26), 0.45, 0.8), Vector3.ZERO, n)
		var col: Color = UI.LINK[d.id]
		for k in 3:
			_box(Vector3(0.06, 0.92, 0.64), iron, Vector3(-0.25 + k * 0.25, 0, 0), n)
		_box(Vector3(0.86, 0.08, 0.66), _mat("link_" + d.id, col, 0.4, 0.2, 1.2), Vector3(0, -0.38, 0), n)
		_doors.append({"node": n, "y": d.cell.y + 0.5, "t": 0.0})
	for l in sim.lifts:
		var n := Node3D.new()
		_static.add_child(n)
		var col: Color = UI.LINK[l.id]
		_box(Vector3(l.size.x, 1.0, 1.2), _mat("lift", Color(0.5, 0.36, 0.22), 0.7), Vector3(l.size.x / 2.0, 0.5, 0), n)
		_box(Vector3(l.size.x + 0.02, 0.1, 1.24), _mat("link_" + l.id, col, 0.4, 0.2, 1.2), Vector3(l.size.x / 2.0, 0.9, 0), n)
		# Rails show how far it travels.
		for side in [0.0, l.size.x]:
			_box(Vector3(0.06, l.rise + 1.0, 0.06), _mat("rail_" + l.id, col.darkened(0.4), 0.6, 0.4, 0.3), Vector3(l.pos.x + side, l.base_y + (l.rise + 1.0) / 2.0, -0.62))
		_lifts.append(n)
	for v in sim.vents:
		_box(Vector3(0.9, 0.12, 0.9), _mat("grate", Color(0.15, 0.13, 0.12), 0.5, 0.6), Vector3(v.x + 0.5, v.y + 0.06, 0))
		var glow := _box(Vector3(0.7, 0.04, 0.7), _mat("vent_glow", Color(1.0, 0.45, 0.2), 0.5, 0.0, 2.0), Vector3(v.x + 0.5, v.y + 0.13, 0))
		var p := CPUParticles3D.new()
		p.amount = 18
		p.lifetime = 0.7
		p.position = Vector3(v.x + 0.5, v.y + 0.15, 0)
		p.direction = Vector3.UP
		p.spread = 12.0
		p.initial_velocity_min = 1.2
		p.initial_velocity_max = 2.0
		p.gravity = Vector3(0, 0.5, 0)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(0.3, 0.02, 0.3)
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.4
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		sm.radial_segments = 8
		sm.rings = 4
		p.mesh = sm
		p.material_override = _mat("steam", Color(0.95, 0.95, 1.0), 1.0, 0.0, 0.4, 0.35)
		var fade := Gradient.new()
		fade.set_color(0, Color(1, 1, 1, 0.8))
		fade.set_color(1, Color(1, 1, 1, 0))
		p.color_ramp = fade
		_static.add_child(p)
		_steam.append([p, glow, v])
	# The mailbox.
	var ex := Node3D.new()
	ex.position = Vector3(sim.exit_cell.x + 0.5, sim.exit_cell.y, 0)
	_static.add_child(ex)
	_box(Vector3(0.1, 0.6, 0.1), iron, Vector3(0, 0.3, 0), ex)
	_box(Vector3(0.5, 0.36, 0.42), _mat("mailbox", Color(0.62, 0.16, 0.13), 0.5, 0.3), Vector3(0, 0.75, 0), ex)
	_box(Vector3(0.52, 0.06, 0.44), _mat("trim", UI.BRASS, 0.35, 0.8), Vector3(0, 0.95, 0), ex)
	_exit_flag = Node3D.new()
	_exit_flag.position = Vector3(0.27, 0.7, 0)
	ex.add_child(_exit_flag)
	_box(Vector3(0.03, 0.3, 0.03), iron, Vector3(0, 0.15, 0), _exit_flag)
	_box(Vector3(0.03, 0.12, 0.16), _mat("flag", Color(0.95, 0.75, 0.2), 0.5, 0.0, 0.8), Vector3(0, 0.26, 0.08), _exit_flag)
	_exit_flag.rotation.x = -1.4
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.light_energy = 1.6
	lamp.omni_range = 4.5
	lamp.position = Vector3(0, 1.6, 1.0)
	ex.add_child(lamp)
	_box(Vector3(0.14, 0.14, 0.14), _mat("lamp", Color(1.0, 0.8, 0.5), 0.5, 0.0, 3.0), Vector3(0, 1.25, 0), ex)
	for cg in sim.cogs:
		var g := _gear(0.26, _mat("cog", Color(1.0, 0.78, 0.3), 0.3, 0.9, 0.9))
		g.position = Vector3(cg.cell.x + 0.5, cg.cell.y + 0.5, 0.1)
		_static.add_child(g)
		_cogs.append(g)


func _gear(r: float, m: Material) -> Node3D:
	var g := Node3D.new()
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.08
	disc.mesh = cm
	disc.material_override = m
	disc.rotation.x = PI / 2.0
	g.add_child(disc)
	for k in 8:
		var a := TAU * k / 8.0
		var t := _box(Vector3(0.1, 0.12, 0.08), m, Vector3(cos(a), sin(a), 0) * (r + 0.04), g)
		t.rotation.z = a
	return g


func _crate() -> Node3D:
	var n := Node3D.new()
	var s := Sim.CRATE.x
	var wood := _mat("crate", Color(0.62, 0.43, 0.24), 0.8)
	var dark := _mat("crate_edge", Color(0.36, 0.24, 0.14), 0.8)
	_box(Vector3(s, s, s), wood, Vector3(0, s / 2.0, 0), n)
	for y in [0.06, s - 0.06]:
		_box(Vector3(s + 0.02, 0.1, s + 0.02), dark, Vector3(0, y, 0), n)
	var brace := _box(Vector3(0.1, s * 1.25, 0.04), dark, Vector3(0, s / 2.0, s / 2.0 + 0.01), n)
	brace.rotation.z = PI / 4.0
	_box(Vector3(0.36, 0.2, 0.02), _mat("label", UI.PAPER, 0.9), Vector3(0.18, s * 0.7, s / 2.0 + 0.03), n)
	return n


func _environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.03, 0.04, 0.1)
	sm.sky_horizon_color = Color(0.2, 0.16, 0.24)
	sm.ground_bottom_color = Color(0.05, 0.05, 0.08)
	sm.ground_horizon_color = Color(0.2, 0.16, 0.24)
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.52, 0.62)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.15, 0.24)
	env.fog_density = 0.012
	env.fog_sky_affect = 0.3
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.72, 0.78, 1.0)
	moon.light_energy = 0.55
	moon.rotation = Vector3(deg_to_rad(-48), deg_to_rad(28), 0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	var warm := DirectionalLight3D.new()
	warm.light_color = Color(1.0, 0.8, 0.6)
	warm.light_energy = 0.9
	warm.rotation = Vector3(deg_to_rad(-20), deg_to_rad(-35), 0)
	add_child(warm)


# ------------------------------------------------------------ camera

func _fit_camera() -> void:
	if sim == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	var half := tan(deg_to_rad(FOV / 2.0))
	var need_v := (sim.h / 2.0 + 0.9) / half
	var need_h := (sim.w / 2.0 + 0.4) / (half * aspect)
	_fit_dist = maxf(need_v, need_h)
	_cam_target = Vector3(sim.w / 2.0, sim.h / 2.0 + 0.35, _fit_dist)


# ------------------------------------------------------------ per frame

func sync(dt: float, spring_left := 1.0) -> void:
	_time += dt
	for i in _actors.size():
		var a: Dictionary = sim.actors[i]
		var c: Courier = _actors[i]
		c.position = Vector3(a.pos.x + Sim.ACTOR.x / 2.0, a.pos.y, 0.0 if not a.echo else -0.08 * (i + 1))
		c.animate(dt, a, spring_left if not a.echo else 1.0)
	for i in _crates.size():
		var c: Dictionary = sim.crates[i]
		_crates[i].position = Vector3(c.pos.x + Sim.CRATE.x / 2.0, c.pos.y, 0)
	for i in _plates.size():
		var p: Dictionary = _plates[i]
		var on := 1.0 if sim.plates[i].pressed else 0.0
		p.on = move_toward(p.on, on, dt * 10.0)
		p.top.position.y = p.base_y - 0.05 * p.on
		var m: StandardMaterial3D = p.top.material_override
		m.emission_energy_multiplier = 0.6 + 2.2 * p.on
	for i in _doors.size():
		var d: Dictionary = _doors[i]
		d.t = move_toward(d.t, 1.0 if sim.doors[i].open else 0.0, dt * 5.0)
		d.node.position.y = d.y + 0.92 * ease(d.t, -2.0)
	for st in _steam:
		var on := not sim.vent_blocked(st[2])
		st[0].emitting = on
		st[1].visible = on
	for i in _lifts.size():
		_lifts[i].position = Vector3(sim.lifts[i].pos.x, sim.lifts[i].pos.y, 0)
	for i in _cogs.size():
		var g: Node3D = _cogs[i]
		g.visible = not sim.cogs[i].taken
		g.rotation.z = _time * 1.5
		g.position.y = sim.cogs[i].cell.y + 0.5 + sin(_time * 2.0 + i) * 0.06
	if sim.won:
		_exit_flag.rotation.x = move_toward(_exit_flag.rotation.x, 0.0, dt * 6.0)
	if follow and sim.actors.size() > 0 and dt > 0.0:
		var p: Dictionary = sim.player()
		var lean := Vector3(p.pos.x - sim.w / 2.0, p.pos.y - sim.h / 2.0, 0) * 0.08
		camera.position = camera.position.lerp(_cam_target + lean, 1.0 - exp(-dt * 3.0))
		camera.look_at(camera.position + Vector3(0, -0.06, -1))


## Shows where each echo walked when it was recorded.
func set_trails(trails: Array) -> void:
	var pts := []
	for t in trails:
		for i in range(0, t.size(), 6):
			pts.append(t[i])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	s.radial_segments = 6
	s.rings = 3
	mm.mesh = s
	mm.instance_count = pts.size()
	for i in pts.size():
		var p: Vector2 = pts[i]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(p.x + Sim.ACTOR.x / 2.0, p.y + 0.45, -0.3)))
	_trails.multimesh = mm
	_trails.material_override = _mat("trail", UI.ECHO, 1.0, 0.0, 1.2, 0.45)


## Moves the actor and crate models to recorded positions (for the unwind animation).
func pose(actor_pos: Array, crate_pos: Array) -> void:
	for i in mini(actor_pos.size(), _actors.size()):
		_actors[i].position.x = actor_pos[i].x + Sim.ACTOR.x / 2.0
		_actors[i].position.y = actor_pos[i].y
	for i in mini(crate_pos.size(), _crates.size()):
		_crates[i].position.x = crate_pos[i].x + Sim.CRATE.x / 2.0
		_crates[i].position.y = crate_pos[i].y


func actor_node(i: int) -> Courier:
	return _actors[i]


func burst(at: Vector2, color: Color, amount := 14) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = 0.6
	p.explosiveness = 0.95
	p.position = Vector3(at.x, at.y, 0.3)
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -6, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.09
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.0
	p.material_override = m
	add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
