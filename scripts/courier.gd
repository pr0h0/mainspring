class_name Courier
extends Node3D
## Courier Seven, built from primitives: a brass body, a peaked cap, one glowing eye, a mail
## satchel and the wind-up key on its back. Echoes are the same shape in translucent blue.

var echo := false
var held := false  # an echo stilled by a bell

var _halo: MeshInstance3D
var _body: Node3D
var _key: Node3D
var _legs: Array[Node3D] = []
var _turn := 0.0
var _walk := 0.0
var _squash := 1.0
var _was_floor := true
var _dead_t := 0.0


## Back to a fresh start for a new loop (the same node is reused from loop to loop).
func reset() -> void:
	held = false
	_dead_t = 0.0
	_squash = 1.0
	_was_floor = true
	_walk = 0.0
	if _body:
		_body.rotation = Vector3.ZERO
		_body.position = Vector3.ZERO
		_body.scale = Vector3.ONE
		for l in _legs:
			l.rotation.x = 0.0
	if _halo:
		_halo.visible = false


## Shader warm-up only (see WorldView._prewarm).
func show_halo_for_warmup() -> void:
	if not is_node_ready():
		await ready
	if _halo:
		_halo.visible = true
		set_process(false)


func _ready() -> void:
	var brass := _m(Color(0.82, 0.62, 0.3), 0.35, 0.85)
	var dark := _m(Color(0.18, 0.15, 0.14), 0.6, 0.4)
	var cap := _m(Color(0.2, 0.28, 0.45), 0.7, 0.0)
	var leather := _m(Color(0.45, 0.27, 0.15), 0.8, 0.0)
	var eye := _m(Color(1.0, 0.8, 0.4), 0.3, 0.0, 3.0)
	if echo:
		brass = _m(UI.ECHO, 0.3, 0.0, 0.9, 0.42)
		dark = brass
		cap = brass
		leather = brass
		eye = _m(Color(0.8, 0.97, 1.0), 0.3, 0.0, 3.0, 0.8)
	_body = Node3D.new()
	add_child(_body)
	var torso := _mesh(_capsule(0.23, 0.6), brass, Vector3(0, 0.42, 0))
	torso.scale = Vector3(1.0, 1.0, 0.85)
	_mesh(_sphere(0.19), brass, Vector3(0, 0.74, 0))
	_mesh(_cyl(0.17, 0.2, 0.1), cap, Vector3(0, 0.9, 0))
	var brim := _mesh(_box(Vector3(0.26, 0.03, 0.3)), cap, Vector3(0, 0.85, 0.14))
	brim.rotation.x = 0.15
	_mesh(_sphere(0.055), eye, Vector3(0, 0.76, 0.17))
	_mesh(_box(Vector3(0.36, 0.05, 0.42)), dark, Vector3(0, 0.3, 0))  # belt
	_mesh(_box(Vector3(0.12, 0.22, 0.24)), leather, Vector3(0.24, 0.38, 0.02))  # satchel
	var strap := _mesh(_box(Vector3(0.04, 0.55, 0.42)), leather, Vector3(0.05, 0.5, 0))
	strap.rotation.z = 0.5
	for side in [-0.1, 0.1]:
		var hip := Node3D.new()
		hip.position = Vector3(side, 0.16, 0)
		_body.add_child(hip)
		var leg := MeshInstance3D.new()
		leg.mesh = _box(Vector3(0.09, 0.16, 0.12))
		leg.material_override = dark
		leg.position = Vector3(0, -0.08, 0)
		hip.add_child(leg)
		_legs.append(hip)
	if echo:
		# A pale ring of frost shows while a bell holds this echo still.
		_halo = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.42
		tm.outer_radius = 0.47
		tm.rings = 24
		_halo.mesh = tm
		_halo.material_override = _m(Color(0.85, 0.95, 1.0), 0.3, 0.0, 2.5, 0.7)
		_halo.position = Vector3(0, 0.45, 0)
		_halo.rotation.x = PI / 2.0
		_halo.visible = false
		add_child(_halo)
	# The key sticks out of the back and turns while there's spring left.
	_key = Node3D.new()
	_key.position = Vector3(0, 0.5, -0.22)
	_body.add_child(_key)
	var rod := MeshInstance3D.new()
	rod.mesh = _cyl(0.025, 0.025, 0.2)
	rod.material_override = brass
	rod.rotation.x = PI / 2.0
	rod.position = Vector3(0, 0, -0.08)
	_key.add_child(rod)
	for s in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		wing.mesh = _sphere(0.08)
		wing.material_override = brass
		wing.scale = Vector3(1.0, 0.55, 0.3)
		wing.position = Vector3(0.08 * s, 0, -0.2)
		_key.add_child(wing)


static var _mats := {}  # shared by every courier, so a new echo creates no new materials


func _m(c: Color, rough: float, metal: float, emit := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s" % [c.to_html(), rough, metal, emit, alpha]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	_mats[key] = m
	m.albedo_color = Color(c, alpha)
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _mesh(mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_body.add_child(mi)
	return mi


func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 16
	return c


## a: the sim's actor dictionary. spring: 0..1 of this loop left (slows the key).
func animate(dt: float, a: Dictionary, spring: float) -> void:
	if _halo:
		_halo.visible = held
		if held:
			_halo.rotation.y += dt * 1.5
			return  # stopped mid-stride, exactly as it was
	if dt <= 0.0:
		_turn = float(a.facing) * (PI / 2.0 - 0.55)
		_body.rotation.y = _turn
		return
	var target := float(a.facing) * (PI / 2.0 - 0.55)
	_turn = lerpf(_turn, target, 1.0 - exp(-dt * 14.0))
	_body.rotation.y = _turn
	if not a.alive:
		_dead_t += dt
		_body.rotation.z = lerpf(_body.rotation.z, -float(a.facing) * 1.3, 1.0 - exp(-dt * 8.0))
		_body.position.y = lerpf(_body.position.y, -0.2, 1.0 - exp(-dt * 6.0))
		return
	var moving: bool = absf(a.vel.x) > 0.3 and a.on_floor
	_walk += dt * (14.0 if moving else 0.0)
	for i in _legs.size():
		_legs[i].rotation.x = sin(_walk + PI * i) * 0.6 if moving else lerpf(_legs[i].rotation.x, 0.0, 0.3)
	_body.position.y = absf(sin(_walk)) * 0.04 if moving else 0.0
	if a.on_floor and not _was_floor:
		_squash = 0.8
	_was_floor = a.on_floor
	_squash = move_toward(_squash, 1.0, dt * 2.5)
	var stretch := 1.0 + clampf(a.vel.y * 0.015, -0.08, 0.1) if not a.on_floor else 1.0
	_body.scale = Vector3(1.0 / sqrt(_squash * stretch), _squash * stretch, 1.0)
	_key.rotation.z += dt * (1.0 + 5.0 * spring) * (1.0 if spring > 0.0 else 0.0)
