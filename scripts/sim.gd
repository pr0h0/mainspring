class_name Sim
extends RefCounted
## The puzzle world as a deterministic tile simulation, independent of rendering. Units are tiles,
## y points up, one step is 1/60 s. The same level plus the same inputs always gives the same
## result, which is what lets an echo replay a recorded loop (and lets tests replay solutions).
##
## Map characters (rows top to bottom):
##   #  wall          S  start          X  mailbox (exit)     *  cog (journal page)
##   a-e plate        A,B,D,E door (open while any plate of its letter is pressed; C is the crate)
##   1-5 lift (raised while plate a-e is pressed; a row of digits is one lift)
##   C  crate         -  ledge (stand on it, jump up through it)      ^  steam vent (hazard;
##                                                                      a crate on it smothers it)
##   @  bell (touch it and every echo recorded before you holds still for HUSH frames, even
##      in mid-air; so an echo that rang it replays exactly what you did)
##   > < conveyor belt (solid; carries whoever and whatever stands on it)
## A vertical run of the same door letter is one doorway: it opens and closes as a whole, and
## never closes while anyone (or any crate) is inside any part of it.

const DT := 1.0 / 60.0
const GRAVITY := 34.0
const JUMP_V := 11.0  # apex 1.78 tiles: one tile up alone, two from a head or a crate
const RUN := 4.5
const ACCEL_GROUND := 50.0
const ACCEL_AIR := 30.0
const MAX_FALL := 16.0
const PUSH := 2.4
const LIFT_SPEED := 2.5
const COYOTE := 6
const BUFFER := 6
const ACTOR := Vector2(0.6, 0.9)
const CRATE := Vector2(0.94, 0.94)
const EPS := 0.001
const STEP := 0.08  # lips a courier walks up without jumping
const HUSH := 240  # frames a bell holds the echoes (four seconds)
const BELT := 2.0  # conveyor speed, tiles per second

const IN_LEFT := 1
const IN_RIGHT := 2
const IN_JUMP := 4

var w := 0
var h := 0
var walls := PackedByteArray()
var ledges := {}  # Vector2i -> true
var plates := []  # {cell, id, pressed}
var doors := []  # {cell, id, open}
var door_at := {}  # Vector2i -> door
var door_groups := []  # [door, ...] per doorway
var lifts := []  # {pos, size, id, rise, offset, delta}
var vents := []  # Vector2i
var cogs := []  # {cell, index, taken}
var bells := []  # {cell, inside}
var belts := {}  # Vector2i -> -1 or 1
var hush := 0  # frames the echoes have left to hold still
var hush_upto := 0  # the bell holds echoes recorded before whoever rang it (index < this)
var crates := []  # {pos, vel, delta, on_floor}
var actors := []  # see _actor()
var exit_cell := Vector2i.ZERO
var start := Vector2.ZERO
var spring := 600  # frames the player may move this loop
var frame := 0
var won := false
var events := []  # sounds/feedback for this step: [name, position]


func _init(level: Dictionary, echo_inputs: Array = []) -> void:
	spring = int(round(float(level.get("spring", 10.0)) * 60.0))
	_parse(level)
	for inputs in echo_inputs:
		actors.append(_actor(true, inputs))
	actors.append(_actor(false, PackedByteArray()))


func player() -> Dictionary:
	return actors[-1]


func _actor(echo: bool, inputs: PackedByteArray) -> Dictionary:
	return {"pos": start, "vel": Vector2.ZERO, "on_floor": true, "alive": true, "echo": echo,
		"inputs": inputs, "coyote": 0, "buffer": 0, "prev": 0, "facing": 1, "delta": Vector2.ZERO,
		"ground": null, "dir": 0, "t": 0}  # t: an echo's place in its recording


func _parse(level: Dictionary) -> void:
	var rows: Array = level["map"]
	h = rows.size()
	for r in rows:
		w = maxi(w, r.length())
	walls.resize(w * h)
	var rise: Dictionary = level.get("rise", {})
	for row in h:
		var line: String = rows[row]
		var y := h - 1 - row
		var x := 0
		while x < line.length():
			var ch := line[x]
			var c := Vector2i(x, y)
			match ch:
				"#":
					walls[y * w + x] = 1
				"S":
					start = Vector2(x + 0.5 - ACTOR.x / 2.0, y)
				"X":
					exit_cell = c
				"*":
					cogs.append({"cell": c, "index": cogs.size(), "taken": false})
				"C":
					crates.append({"pos": Vector2(x + 0.5 - CRATE.x / 2.0, y), "vel": Vector2.ZERO, "delta": Vector2.ZERO, "on_floor": true})
				"-":
					ledges[c] = true
				"^":
					vents.append(c)
				"@":
					bells.append({"cell": c, "inside": false})
				">", "<":
					walls[y * w + x] = 1
					belts[c] = 1 if ch == ">" else -1
				_:
					if ch >= "a" and ch <= "e":
						plates.append({"cell": c, "id": ch, "pressed": false})
					elif ch >= "A" and ch <= "E":
						var d := {"cell": c, "id": ch.to_lower(), "open": false}
						doors.append(d)
						door_at[c] = d
					elif ch >= "1" and ch <= "5":
						var x2 := x
						while x2 + 1 < line.length() and line[x2 + 1] == ch:
							x2 += 1
						var id := char("a".unicode_at(0) + int(ch) - 1)
						lifts.append({"pos": Vector2(x, y), "base_y": float(y), "size": Vector2(x2 - x + 1, 1),
							"id": id, "rise": int(rise.get(ch, 3)), "offset": 0.0, "delta": Vector2.ZERO})
						x = x2
			x += 1
	for d in doors:
		var below = door_at.get(Vector2i(d.cell.x, d.cell.y - 1))
		if below != null and below.id == d.id:
			continue  # not the bottom of its doorway
		var g := [d]
		var y: int = d.cell.y
		while door_at.has(Vector2i(d.cell.x, y + 1)) and door_at[Vector2i(d.cell.x, y + 1)].id == d.id:
			y += 1
			g.append(door_at[Vector2i(d.cell.x, y)])
		door_groups.append(g)


# ------------------------------------------------------------ step

## Advances one frame. `input` is the live player's buttons (IN_* bits).
func step(input: int) -> void:
	events.clear()
	if won:
		return
	_update_plates()
	_update_doors()
	_update_lifts()
	for c in crates:
		_step_crate(c)
	var p := player()
	for i in actors.size():
		var a: Dictionary = actors[i]
		var inp := 0
		if a.echo:
			if held(i):
				a.delta = Vector2.ZERO
				continue  # held by the bell: no time passes for it
			inp = a.inputs[a.t] if a.t < a.inputs.size() else 0
			a.t += 1
		elif frame < spring:
			inp = input
			a.inputs.append(input)
		_step_actor(a, inp)
	if hush > 0:
		hush -= 1
		if hush == 0:
			events.append(["release", p.pos])
	for a in actors:
		if a.alive:
			_check_hazards(a)
	_check_bells()
	if p.alive:
		var pr := Rect2(p.pos, ACTOR)
		for cg in cogs:
			if not cg.taken and pr.intersects(Rect2(Vector2(cg.cell) + Vector2(0.2, 0.2), Vector2(0.6, 0.6))):
				cg.taken = true
				events.append(["cog", Vector2(cg.cell) + Vector2(0.5, 0.5)])
		if pr.intersects(Rect2(Vector2(exit_cell) + Vector2(0.3, 0.0), Vector2(0.4, 0.9))):
			won = true
			events.append(["win", p.pos])
	frame += 1


func wound_down() -> bool:
	return frame >= spring


func _update_plates() -> void:
	for pl in plates:
		var zone := Rect2(Vector2(pl.cell) + Vector2(0.05, 0.0), Vector2(0.9, 0.3))
		var on := false
		for a in actors:
			if a.alive and Rect2(a.pos, ACTOR).intersects(zone):
				on = true
		for c in crates:
			if Rect2(c.pos, CRATE).intersects(zone):
				on = true
		if on != pl.pressed:
			events.append(["plate_on" if on else "plate_off", Vector2(pl.cell) + Vector2(0.5, 0.1)])
		pl.pressed = on


func plate_down(id: String) -> bool:
	for pl in plates:
		if pl.id == id and pl.pressed:
			return true
	return false


func _update_doors() -> void:
	for g in door_groups:
		var d: Dictionary = g[0]
		var want: bool = plate_down(d.id)
		if want == d.open:
			continue
		var top: Dictionary = g[-1]
		var span := Rect2(Vector2(d.cell), Vector2(1, top.cell.y - d.cell.y + 1))
		if not want and _occupied(span):
			continue  # never closes on someone standing in the doorway
		for m in g:
			m.open = want
		events.append(["door_open" if want else "door_close", Vector2(d.cell) + Vector2(0.5, span.size.y / 2.0)])


func _occupied(r: Rect2) -> bool:
	r = r.grow(-EPS)
	for a in actors:
		if a.alive and Rect2(a.pos, ACTOR).intersects(r):
			return true
	for c in crates:
		if Rect2(c.pos, CRATE).intersects(r):
			return true
	return false


func _update_lifts() -> void:
	for l in lifts:
		var target := float(l.rise) if plate_down(l.id) else 0.0
		var step := clampf(target - l.offset, -LIFT_SPEED * DT, LIFT_SPEED * DT)
		l.delta = Vector2.ZERO
		if absf(step) < EPS:
			continue
		var top: float = l.pos.y + l.size.y
		var riders := []
		for e in actors + crates:
			if e.has("alive") and not e.alive:
				continue
			var size: Vector2 = ACTOR if e.has("echo") else CRATE
			if absf(e.pos.y - top) < 0.05 and e.pos.x < l.pos.x + l.size.x - EPS and e.pos.x + size.x > l.pos.x + EPS:
				riders.append([e, size])
		# Whoever stands on a rider rides too (an echo on a crate, you on an echo...).
		var k := 0
		while k < riders.size():
			var base: Dictionary = riders[k][0]
			var btop: float = base.pos.y + riders[k][1].y
			for e in actors + crates:
				if (e.has("alive") and not e.alive) or riders.any(func(r): return r[0] == e):
					continue
				var size: Vector2 = ACTOR if e.has("echo") else CRATE
				if absf(e.pos.y - btop) < 0.05 and e.pos.x < base.pos.x + riders[k][1].x - EPS and e.pos.x + size.x > base.pos.x + EPS:
					riders.append([e, size])
			k += 1
		if step > 0.0:
			# Riders go first; if one would be squashed against a ceiling the lift waits.
			for r in riders:
				var before: float = r[0].pos.y
				_move_y(r[0], r[1], step, r[0], false)
				step = minf(step, r[0].pos.y - before)
			step = maxf(step, 0.0)
			for r in riders:
				r[0].pos.y = top + step
		else:
			# Going down it stops on anyone underneath instead of squashing them.
			var below := Rect2(l.pos + Vector2(0, step), l.size).grow(-EPS)
			for e in actors + crates:
				if (e.has("alive") and not e.alive) or riders.any(func(r): return r[0] == e):
					continue
				var size: Vector2 = ACTOR if e.has("echo") else CRATE
				var er := Rect2(e.pos, size)
				if er.intersects(below):
					step = minf(0.0, er.end.y - l.pos.y)
			if absf(step) < EPS:
				continue
		l.pos.y += step
		l.offset += step
		l.delta = Vector2(0, step)
		if step < 0.0:
			for r in riders:
				_move_y(r[0], r[1], step, r[0], false)
		if absf(step) > EPS and (absf(l.offset) < EPS or absf(l.offset - l.rise) < EPS):
			events.append(["lift_stop", l.pos + Vector2(l.size.x / 2.0, 0.5)])


func _step_crate(c: Dictionary) -> void:
	var before: Vector2 = c.pos
	var belt := _belt_under(c.pos, CRATE) if c.on_floor else 0
	if belt != 0:
		_move_x(c, CRATE, _clear_of_actors(c, belt * BELT * DT), c)
	c.vel.y = maxf(c.vel.y - GRAVITY * DT, -MAX_FALL)
	var was_floor: bool = c.on_floor
	c.on_floor = false
	if _move_y(c, CRATE, c.vel.y * DT, c, false):
		if c.vel.y < 0.0:
			c.on_floor = true
			if not was_floor and c.vel.y < -4.0:
				events.append(["thud", c.pos + Vector2(CRATE.x / 2.0, 0)])
		c.vel.y = 0.0
	c.delta = c.pos - before


func _step_actor(a: Dictionary, inp: int) -> void:
	var before: Vector2 = a.pos
	a.delta = Vector2.ZERO
	if not a.alive:
		return
	# Ride whatever we stand on (another actor or a crate being pushed).
	if a.on_floor and a.ground is Dictionary and not a.ground.has("rise"):
		var gd: Vector2 = a.ground.delta
		if absf(gd.x) > EPS:
			_move_x(a, ACTOR, gd.x, a)
	var belt := _belt_under(a.pos, ACTOR) if a.on_floor and a.ground == null else 0
	if belt != 0:
		_move_x(a, ACTOR, belt * BELT * DT, a)
	var dir := int(inp & IN_RIGHT != 0) - int(inp & IN_LEFT != 0)
	a.dir = dir
	if dir != 0:
		a.facing = dir
	var acc := ACCEL_GROUND if a.on_floor else ACCEL_AIR
	a.vel.x = move_toward(a.vel.x, dir * RUN, acc * DT)
	# Jump: buffered presses and a little grace after leaving a ledge.
	var pressed: bool = inp & IN_JUMP != 0 and a.prev & IN_JUMP == 0
	a.prev = inp
	if pressed:
		a.buffer = BUFFER
	a.coyote = COYOTE if a.on_floor else a.coyote - 1
	if a.buffer > 0 and a.coyote > 0:
		a.vel.y = JUMP_V
		a.buffer = 0
		a.coyote = 0
		a.on_floor = false
		events.append(["jump", a.pos])
	a.buffer -= 1
	if inp & IN_JUMP == 0 and a.vel.y > 4.0:
		a.vel.y = 4.0  # let go early for a short hop
	a.vel.y = maxf(a.vel.y - GRAVITY * DT, -MAX_FALL)
	# Horizontal, pushing a crate if one is in the way.
	var dx: float = a.vel.x * DT
	if absf(dx) > EPS:
		var c = _crate_ahead(a, signf(dx), absf(dx))
		if c != null and a.on_floor and c.on_floor:  # a falling crate drops straight down
			var want := signf(dx) * minf(absf(dx), PUSH * DT)
			var cx: float = c.pos.x
			_move_x(c, CRATE, want, c)
			if absf(c.pos.x - cx) > EPS:
				events.append(["push", c.pos])
			dx = want
			a.vel.x = clampf(a.vel.x, -PUSH, PUSH)
	var x0: float = a.pos.x
	if _move_x(a, ACTOR, dx, a):
		# Step up lips too small to see (a crate in a trench sits a hair below the floor).
		var y0: float = a.pos.y
		var left: float = dx - (a.pos.x - x0)
		if a.on_floor and absf(left) > EPS and not _box_hit(Rect2(a.pos + Vector2(0, STEP), ACTOR)):
			var x1: float = a.pos.x
			a.pos.y += STEP
			_move_x(a, ACTOR, left, a)
			if absf(a.pos.x - x1) < EPS:
				a.pos.y = y0
			else:
				_move_y(a, ACTOR, -STEP, a, true)
		if absf(a.pos.x - x0) < absf(dx) - EPS:
			a.vel.x = 0.0
	var was_floor: bool = a.on_floor
	var fall_v: float = a.vel.y
	a.on_floor = false
	a.ground = null
	if _move_y(a, ACTOR, a.vel.y * DT, a, true):
		if a.vel.y < 0.0:
			a.on_floor = true
			if not was_floor and fall_v < -6.0:
				events.append(["land", a.pos])
		a.vel.y = 0.0
	if a.pos.y < -3.0:
		_kill(a)
	a.delta = a.pos - before


func _crate_ahead(a: Dictionary, s: float, dist: float):
	var r := Rect2(a.pos, ACTOR)
	for c in crates:
		var cr := Rect2(c.pos, CRATE)
		if r.position.y + 0.2 >= cr.end.y or r.end.y <= cr.position.y + 0.2:
			continue
		var gap: float = cr.position.x - r.end.x if s > 0.0 else r.position.x - cr.end.x
		if gap > -0.05 and gap <= dist + 0.02:
			return c
	return null


## The belt direction under the middle of a box standing on a floor, or 0.
func _belt_under(pos: Vector2, size: Vector2) -> int:
	if absf(pos.y - roundf(pos.y)) > 0.02:
		return 0
	return belts.get(Vector2i(floori(pos.x + size.x / 2.0), int(roundf(pos.y)) - 1), 0)


## Shortens a crate's belt ride so it stops against anyone standing in its way.
func _clear_of_actors(c: Dictionary, dx: float) -> float:
	var cr := Rect2(c.pos, CRATE)
	for a in actors:
		if not a.alive:
			continue
		var r := Rect2(a.pos, ACTOR)
		if r.position.y + 0.2 >= cr.end.y or r.end.y <= cr.position.y + 0.2:
			continue
		if dx > 0.0 and r.position.x >= cr.end.x - 0.05:
			dx = minf(dx, maxf(r.position.x - cr.end.x, 0.0))
		elif dx < 0.0 and r.end.x <= cr.position.x + 0.05:
			dx = maxf(dx, minf(r.end.x - cr.position.x, 0.0))
	return dx


## Whether actor i is an echo the bell is holding still right now.
func held(i: int) -> bool:
	return hush > 0 and actors[i].echo and i < hush_upto


## Anyone stepping into a bell rings it, unless it is already ringing.
func _check_bells() -> void:
	for b in bells:
		var zone := Rect2(Vector2(b.cell) + Vector2(0.15, 0.1), Vector2(0.7, 0.8))
		var ringer := -1
		for i in actors.size():
			if actors[i].alive and Rect2(actors[i].pos, ACTOR).intersects(zone):
				ringer = maxi(ringer, i)
		var inside := ringer >= 0
		if inside and not b.inside and hush == 0:
			hush = HUSH
			hush_upto = ringer
			events.append(["chime", Vector2(b.cell) + Vector2(0.5, 0.5)])
		b.inside = inside


## A crate sitting over most of a vent smothers the steam.
func vent_blocked(v: Vector2i) -> bool:
	var zone := Rect2(Vector2(v) + Vector2(0.15, 0.0), Vector2(0.7, 0.5))
	for c in crates:
		var cr := Rect2(c.pos, CRATE)
		if cr.intersects(zone) and cr.intersection(zone).size.x > 0.35:
			return true
	return false


func _check_hazards(a: Dictionary) -> void:
	var r := Rect2(a.pos, ACTOR)
	for v in vents:
		if not vent_blocked(v) and r.intersects(Rect2(Vector2(v) + Vector2(0.15, 0.0), Vector2(0.7, 0.5))):
			_kill(a)
			return


func _kill(a: Dictionary) -> void:
	if not a.alive:
		return
	a.alive = false
	a.vel = Vector2.ZERO
	events.append(["die", a.pos])


# ------------------------------------------------------------ collision

func cell_solid(c: Vector2i) -> bool:
	if c.x < 0 or c.x >= w or c.y < 0:
		return true
	if c.y >= h:
		return false
	if walls[c.y * w + c.x] == 1:
		return true
	var d = door_at.get(c)
	return d != null and not d.open


## Solid boxes near `area` as [rect, owner] (owner null for the map).
func _solids(area: Rect2, self_e: Dictionary) -> Array:
	var out := []
	for x in range(floori(area.position.x) - 1, floori(area.end.x) + 2):
		for y in range(floori(area.position.y) - 1, floori(area.end.y) + 2):
			if cell_solid(Vector2i(x, y)):
				out.append([Rect2(x, y, 1, 1), null])
	for l in lifts:
		out.append([Rect2(l.pos, l.size), l])
	for c in crates:
		if c != self_e:
			out.append([Rect2(c.pos, CRATE), c])
	return out


## Whether a box overlaps any solid (map, door, lift or crate).
func _box_hit(r: Rect2) -> bool:
	r = r.grow(-EPS)
	for s in _solids(r, {}):
		if s[0].intersects(r):
			return true
	return false


## Moves along x, stopping at solids. Returns true when blocked.
func _move_x(e: Dictionary, size: Vector2, dx: float, self_e: Dictionary) -> bool:
	if absf(dx) < EPS * 0.1:
		return false
	var box := Rect2(e.pos, size)
	var hit := false
	for s in _solids(box.merge(Rect2(e.pos + Vector2(dx, 0), size)), self_e):
		var r: Rect2 = s[0]
		if box.position.y >= r.end.y - EPS or box.end.y <= r.position.y + EPS:
			continue
		if dx > 0.0 and r.position.x >= box.end.x - EPS:
			var lim := r.position.x - box.end.x
			if lim < dx:
				dx = maxf(lim, 0.0)
				hit = true
		elif dx < 0.0 and r.end.x <= box.position.x + EPS:
			var lim := r.end.x - box.position.x
			if lim > dx:
				dx = minf(lim, 0.0)
				hit = true
	e.pos.x += dx
	return hit


## Moves along y. Falling lands on ledges, and actors also land on other actors' heads.
func _move_y(e: Dictionary, size: Vector2, dy: float, self_e: Dictionary, is_actor: bool) -> bool:
	if absf(dy) < EPS * 0.1:
		return false
	var box := Rect2(e.pos, size)
	var area := box.merge(Rect2(e.pos + Vector2(0, dy), size))
	var solids := _solids(area, self_e)
	if dy < 0.0:
		for x in range(floori(area.position.x), floori(area.end.x) + 1):
			for y in range(floori(area.position.y), floori(area.end.y) + 1):
				if ledges.has(Vector2i(x, y)):
					solids.append([Rect2(x, y + 0.8, 1, 0.2), null, true])
		if is_actor:
			for o in actors:
				if o != self_e and o.alive:
					solids.append([Rect2(o.pos, ACTOR), o, true])
	var hit := false
	var owner = null
	for s in solids:
		var r: Rect2 = s[0]
		if box.position.x >= r.end.x - EPS or box.end.x <= r.position.x + EPS:
			continue
		if dy > 0.0:
			if s.size() > 2:
				continue
			if r.position.y >= box.end.y - EPS:
				var lim := r.position.y - box.end.y
				if lim < dy:
					dy = maxf(lim, 0.0)
					hit = true
		elif r.end.y <= box.position.y + EPS:
			var lim := r.end.y - box.position.y
			if lim > dy:
				dy = minf(lim, 0.0)
				hit = true
				owner = s[1]
	e.pos.y += dy
	if is_actor and owner != null:
		e.ground = owner
	return hit
