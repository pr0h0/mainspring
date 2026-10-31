extends SceneTree
## Replays every level's scripted solutions through the simulation and reports the result.
##   godot --headless --path . -s tools/verify.gd [level index] [-v]

static var trace := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var only := -1
	var verbose := args.has("-v")
	trace = args.has("-t")
	for a in args:
		if a.is_valid_int():
			only = int(a)
	var ok := true
	for i in Levels.count():
		if only != -1 and i != only:
			continue
		var l := Levels.get_level(i)
		var widths := {}
		for row in l["map"]:
			widths[String(row).length()] = true
		if widths.size() != 1:
			print("L%d %s: ragged map rows %s" % [i + 1, l.title, widths.keys()])
			ok = false
		for key in ["solution", "cog_solution"]:
			var sol: String = l.get(key, "")
			for a in args:
				if a.begins_with(key + "="):
					sol = a.get_slice("=", 1)
			if sol == "":
				continue
			var r := run(l, sol, verbose)
			var need_cog: bool = key == "cog_solution"
			var good: bool = r.won and (r.cogs > 0 or not need_cog) and r.echoes <= int(l.echoes)
			if key == "solution" and r.echoes > int(l.par):
				good = false
			print("L%d %-15s %-12s %s  won=%s echoes=%d cogs=%d time=%.1fs" % [i + 1, l.title, key, "OK " if good else "BAD", r.won, r.echoes, r.cogs, r.frames / 60.0])
			ok = ok and good
	print("ALL OK" if ok else "FAILURES")
	quit(0 if ok else 1)


static func token_ends(loop: String) -> Dictionary:
	var out := {}
	var t := 0
	for tok in loop.strip_edges().split(" ", false):
		var j := 0
		while j < tok.length() and not tok[j].is_valid_int():
			j += 1
		t += int(tok.substr(j))
		out[t] = tok
	return out


static func run(l: Dictionary, solution: String, verbose := false) -> Dictionary:
	var echoes := []
	var loops := solution.split("|")
	var sim: Sim
	for li in loops.size():
		var inp := Levels.inputs_for(loops[li])
		sim = Sim.new(l, echoes)
		var n := maxi(inp.size(), sim.spring) + 90
		var marks := token_ends(loops[li])
		for f in n:
			sim.step(inp[f] if f < inp.size() else 0)
			if trace and marks.has(f + 1):
				var pp: Dictionary = sim.player()
				print("     L%d %-5s -> (%.2f, %.2f) floor=%s alive=%s" % [li + 1, marks[f + 1], pp.pos.x, pp.pos.y, pp.on_floor, pp.alive])
			if sim.won:
				break
		if verbose:
			var desc := []
			for a in sim.actors:
				desc.append("%s(%.2f,%.2f)%s" % ["E" if a.echo else "P", a.pos.x, a.pos.y, "" if a.alive else "x"])
			for c in sim.crates:
				desc.append("C(%.2f,%.2f)" % [c.pos.x, c.pos.y])
			print("   loop %d: %s plates=%s won=%s" % [li + 1, " ".join(desc), sim.plates.map(func(p): return p.pressed), sim.won])
		if li < loops.size() - 1:
			echoes.append(sim.player().inputs)
	var cogs := 0
	for c in sim.cogs:
		if c.taken:
			cogs += 1
	return {"won": sim.won, "echoes": echoes.size(), "cogs": cogs, "frames": sim.frame}
