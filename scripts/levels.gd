class_name Levels
extends RefCounted
## Puzzle maps, their letters, the clockmaker's journal pages and the story frame.
## Map legend is in sim.gd. "echoes" is how many echoes a level allows, "par" the fewest it
## needs (solving at par earns the wax seal). "solution" is replayed by `--verify`: loops split
## by "|", each a run of tokens like R30 (right for 30 frames), RJ20, LJ20, J20, L10, N60 (wait).

const INTRO := "At one minute to midnight the great clock of Brasswick snapped its mainspring, and the whole town stopped mid-breath. Every person. Every bird. Every falling leaf.\n\nOnly wound things still move. You are Courier Seven, built by the clockmaker Odile Vane, and your key holds a few seconds of spring at a time. When it runs down, unwind: time goes back, and the you that was keeps walking.\n\nThe mail bag on your back is full of letters no one ever delivered."

const ENDING := "Odile is at the top of the tower, her hand on the great spring. She reads Wren's letter twice.\n\n\"She heard it stop,\" she says. \"Of course she did.\"\n\nShe winds the clock. Somewhere below, a bird finishes its song. The bells of Brasswick begin to ring in the new year, and in a small house by the river a girl who is not afraid of midnight laughs at the noise.\n\nYour key turns once more, and then, gently, it rests."

const ALL := [
	{
		"title": "Morning Round",
		"hint": "Move with ←/→ (or A/D), jump with Space or ↑. Reach the mailbox before your spring runs down.",
		"spring": 15.0, "echoes": 0, "par": 0,
		"map": [
			"########################",
			"#......................#",
			"#......................#",
			"#............*.........#",
			"#...........---........#",
			"#........##............#",
			"#.....#................#",
			"#S...##.....#.....^...X#",
			"########################",
		],
		"solution": "R50 RJ20 N10 RJ22 R28 N30 R60 RJ25 R60 RJ25 R80",
		"cog_solution": "R50 RJ20 N10 RJ22 N20 RJ34 N10 R18 RJ34 N30 R30 N30 R24 RJ25 R80",
		"from": "Tomas the baker", "to": "his sister Maren",
		"letter": "Maren, the bread won't rise this winter, and neither will I before dawn. Odile Vane came by the shop again before sunrise. She bought nothing. She stood at the window with her coat buttoned wrong and stared up at the clock tower until the oven bell rang. I think the little one is worse.",
	},
	{
		"title": "Held Open",
		"hint": "Stand on the plate and press R to unwind. Your echo repeats everything you did and keeps the plate down while you walk through.",
		"spring": 10.0, "echoes": 1, "par": 1,
		"map": [
			"######################",
			"#...........#........#",
			"#...........#........#",
			"#...........#........#",
			"#...........A........#",
			"#S..a.......A.......X#",
			"######################",
		],
		"solution": "R40 | R260",
		"from": "Wren Vane, age nine", "to": "Courier Seven",
		"letter": "Dear Seven. Mother says you can't read but I am writing anyway because you are the only one who comes up the stairs fast. When I am better we will race to the river and I will let you win once. Do not tell Mother I was out of bed to write this.",
	},
	{
		"title": "Heavy Parcel",
		"hint": "Walk into a crate to push it. Crates hold plates down too. (Stuck? Backspace starts the level over.)",
		"spring": 12.0, "echoes": 1, "par": 0,
		"map": [
			"######################",
			"#.............#......#",
			"#.............#..*...#",
			"#.............#......#",
			"#.............A......#",
			"#S...C....a...A.....X#",
			"######################",
		],
		"solution": "R165 N5 RJ30 R150",
		"cog_solution": "R165 N5 RJ30 R80 | N180 R100 N5 RJ30 R50 N10 R5 RJ25 N25 J30 N30 R60",
		"from": "Dr. Ansel Hale", "to": "Odile Vane",
		"letter": "Odile. I have read everything there is to read, and I am sorry. There is nothing more medicine can do for her. She will not see the new year. Please, spend the hours you have with her, not in that workshop. Clocks will keep. Children don't.",
	},
	{
		"title": "Stepping Stone",
		"hint": "Echoes are solid on top. Stand where you want a step, unwind, and climb yourself.",
		"spring": 10.0, "echoes": 1, "par": 1,
		"map": [
			"######################",
			"#....................#",
			"#....................#",
			"#....................#",
			"#....................#",
			"#.........##.........#",
			"#S........##........X#",
			"######################",
		],
		"solution": "R120 | R75 RJ25 N20 RJ30 R150",
		"from": "Abel Rook, keeper of the tower", "to": "the town council",
		"letter": "Sirs. Someone has been in the clock room at night. Nothing is taken, but the great mainspring has fresh marks along its edge, as if someone had been filing it thin, very carefully, over many nights. I have changed the lock. I would like it noted that I did this before midnight on the last night of the year.",
	},
	{
		"title": "Relay",
		"hint": "Every echo replays at once. The later one can walk through a door the earlier one is holding.",
		"spring": 10.0, "echoes": 2, "par": 2,
		"map": [
			"########################",
			"#.......#......#.......#",
			"#.......#..*...#.......#",
			"#.......#......#.......#",
			"#.......A......B.......#",
			"#S.a....A..b...B......X#",
			"########################",
		],
		"solution": "R25 | R140 | R320",
		"cog_solution": "R25 | R140 | R110 RJ25 N20 J30 N30 R200",
		"from": "Mayor Corwin Ashby", "to": "all households",
		"letter": "Notice. As is tradition, the bells of the great clock will ring in the new year at midnight. All are welcome in the square. Mrs. Vane's request that the bells be silenced this year has been considered by the council with every sympathy, and declined.",
	},
	{
		"title": "Late Arrival",
		"hint": "The lift rises while its plate is held. An echo also repeats your waiting: arrive at the plate only after you're aboard.",
		"spring": 10.0, "echoes": 1, "par": 1,
		"map": [
			"######################",
			"#....................#",
			"#....................#",
			"#...................X#",
			"#............#########",
			"#............#########",
			"#............#########",
			"#S..a......11#########",
			"######################",
		],
		"solution": "N180 R40 | R140 RJ20 N140 R140",
		"from": "Odile Vane", "to": "Wren",
		"letter": "My bird. I know you heard me on the stairs again. I am making something for you: a clock that is very slow. So slow that one minute could last as long as we like. Then there is no hurry about anything at all, and you can sleep as late as you want. Go back to bed. I'll be up soon.",
	},
	{
		"title": "Double Duty",
		"hint": "One crate, one echo, two jobs. Which of them should hold the plate?",
		"spring": 14.0, "echoes": 2, "par": 1,
		"map": [
			"########################",
			"#...........#..........#",
			"#.......*...#..........#",
			"#...........#..........#",
			"#...........#........X.#",
			"#...........A.......####",
			"#S...C..a...A.......####",
			"########################",
		],
		"solution": "R35 RJ25 R25 N30 | N70 R400 N5 RJ25 N15 RJ30 R60",
		"cog_solution": "R118 N5 J25 R8 N30 | N150 R80 RJ30 R250 | N150 R70 RJ20 N25 J30 N30 J30 N40 R140 N10 RJ25 N20 RJ30 R60",
		"from": "Abel Rook", "to": "his son, at sea",
		"letter": "I saw Mrs. Vane on the tower stairs tonight with her toolbag. I should have stopped her. She was crying, and she said, \"One more minute, Abel. Just one more,\" and I stood aside. If anything is wrong with the clock by morning, it is my fault, not hers. Write when you make port.",
	},
	{
		"title": "Overtime",
		"hint": "Two plates, two echoes, one lift. Who goes first, and who waits?",
		"spring": 12.0, "echoes": 2, "par": 2,
		"map": [
			"########################",
			"#..............#.......#",
			"#..............#.......#",
			"#..............#.......#",
			"#..............B......X#",
			"#.............##########",
			"#.............##########",
			"#.............##########",
			"#S.a....b...11##########",
			"########################",
		],
		"solution": "R100 | N200 R25 | R150 RJ20 N130 R200",
		"from": "Wren Vane", "to": "her mother",
		"letter": "Mother, I know what you did. I heard the tower stop. It is so quiet that I can hear the snow. I am not scared of midnight. I was only scared of you being sad. Please let it ring. Please. Seven will bring you this, Seven is quick.",
	},
	{
		"title": "Midnight",
		"hint": "Sometimes a plan only works once the future helps. Record what you'll need, even if it fails right now.",
		"spring": 12.0, "echoes": 2, "par": 1,
		"map": [
			"##########################",
			"#........................#",
			"#................#.......#",
			"#................#.......#",
			"#...............a#.......#",
			"#..........######...*....#",
			"#..........######........#",
			"#..........######........#",
			"#.b.C.S..22.....A......X.#",
			"##########################",
		],
		"solution": "R12 RJ20 N150 R120 | L10 L70 N60 R300",
		"cog_solution": "R12 RJ20 N150 R120 | L10 L70 N180 R235 | N340 R160 RJ25 N25 J30 N40 R60",
		"from": "Courier Seven", "to": "Odile Vane, at the top of the tower",
		"letter": "",
	},
]

## Journal pages, found as cogs. In the order the levels hide them.
const PAGES := [
	"Workshop, autumn. Wren asked today whether clocks get tired. I told her no, they just need winding. She said then she would like to be a clock. I went out to the yard so she wouldn't see my face.",
	"Courier Seven is finished. I gave it a key of its own and a spring that remembers: unwind it, and the moments it lived keep walking a little while without it. A strange gift for a mail carrier. I am not sure who I built it for.",
	"Hale says the new year. The bells ring at midnight; the whole town counts down. If the great spring were to stop at one minute to twelve, the minute would never end. Everyone held. Everyone but what I wind myself.",
	"It is done. The town is silent. I wound Seven and set it by the door with the mail bag, the way I always do, and I did not take the letters out. I think some part of me wanted them delivered.",
	"If you are reading this, Seven, you have come all the way up anyway. Good. You were always faster than me on the stairs.",
]


## Inputs for one loop of a solution string (see the header).
static func inputs_for(loop: String) -> PackedByteArray:
	var out := PackedByteArray()
	for tok in loop.strip_edges().split(" ", false):
		var bits := 0
		var j := 0
		while j < tok.length() and not tok[j].is_valid_int():
			match tok[j]:
				"L": bits |= Sim.IN_LEFT
				"R": bits |= Sim.IN_RIGHT
				"J": bits |= Sim.IN_JUMP
			j += 1
		for k in int(tok.substr(j)):
			out.append(bits)
	return out


static func count() -> int:
	return ALL.size()


static func get_level(i: int) -> Dictionary:
	return ALL[i]


## Page index for the cog in level i (cogs are numbered in level order), or -1.
static func page_for(i: int) -> int:
	var n := 0
	for k in i:
		n += _cogs_in(ALL[k])
	return n if _cogs_in(ALL[i]) > 0 else -1


static func _cogs_in(l: Dictionary) -> int:
	var n := 0
	for row in l["map"]:
		n += String(row).count("*")
	return n
