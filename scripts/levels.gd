class_name Levels
extends RefCounted
## Puzzle maps, their letters, the clockmaker's journal pages and the story frame.
## Map legend is in sim.gd. "id" is what saves refer to, so levels can be reordered or inserted.
## A level with a cog carries the journal "page" it unlocks; pages read in level order. "echoes" is how many echoes a level allows, "par" the fewest it
## needs (solving at par earns the wax seal). "solution" is replayed by `--verify`: loops split
## by "|", each a run of tokens like R30 (right for 30 frames), RJ20, LJ20, J20, L10, N60 (wait).

const INTRO := "At one minute to midnight the great clock of Brasswick snapped its mainspring, and the whole town stopped mid-breath. Every person. Every bird. Every falling leaf.\n\nOnly wound things still move. You are Courier Seven, built by the clockmaker Odile Vane, and your key holds a few seconds of spring at a time. When it runs down, unwind: time goes back, and the you that was keeps walking.\n\nThe mail bag on your back is full of letters no one ever delivered."

const ENDING := "Odile is at the top of the tower, her hand on the great spring. She reads Wren's letter twice.\n\n\"She heard it stop,\" she says. \"Of course she did.\"\n\nShe winds the clock. Somewhere below, a bird finishes its song. The bells of Brasswick begin to ring in the new year, and in a small house by the river a girl who is not afraid of midnight laughs at the noise.\n\nYour key turns once more, and then, gently, it rests."

const INTRO_2 := "Wren found you in the hall on New Year's morning, cold and still, with the mail bag over your shoulder. She sat on the bottom stair and turned your key until you ticked.\n\n\"There,\" she said. \"Now nothing in this house is stopped.\"\n\nThe town is running again: mills, belts, bells, all of it at once. Brasswick has a whole year of letters to catch up on, and you are still the quickest thing in it."

const ENDING_2 := "The river is frozen all the way across, just as Pip said. Wren is wrapped in two scarves and her mother's coat, and she is slower than she was, and she does not care.\n\n\"Ready,\" she says. \"Steady.\"\n\nShe lets you win. Of course she does; she promised. Then she lies on her back on the ice, laughing, while Odile and the doctor argue gently on the bank about how cold is too cold, and the great clock of Brasswick strikes noon over all of them, exactly on time.\n\nYour key turns, and turns, and does not stop."

## The story in two acts. "first" is each act's first level; each act ends on the level before
## the next act's first.
const ACTS := [
	{"title": "One Minute to Midnight", "intro_title": "Brasswick, one minute to midnight", "intro": INTRO,
		"start": "Pick up the mail bag", "ending_title": "Midnight", "ending": ENDING, "first": 0},
	{"title": "New Year", "intro_title": "Brasswick, New Year's morning", "intro": INTRO_2,
		"start": "Shoulder the mail bag", "ending_title": "Noon", "ending": ENDING_2, "first": 14},
]

const ALL := [
	{
		"id": "morning",
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
		"page": "Workshop, autumn. Wren asked today whether clocks get tired. I told her no, they just need winding. She said then she would like to be a clock. I went out to the yard so she wouldn't see my face.",
	},
	{
		"id": "held",
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
		"id": "heavy",
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
		"page": "Courier Seven is finished. I gave it a key of its own and a spring that remembers: unwind it, and the moments it lived keep walking a little while without it. A strange gift for a mail carrier. I am not sure who I built it for.",
	},
	{
		"id": "stepping",
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
		"id": "stair",
		"title": "Stair of Selves",
		"hint": "An echo can climb onto another echo. Build the staircase out of yourself, one step per loop.",
		"spring": 8.0, "echoes": 2, "par": 2,
		"map": [
			"######################",
			"#....................#",
			"#....................#",
			"#....................#",
			"#...................X#",
			"#............#########",
			"#............#########",
			"#...........##########",
			"#S..........##########",
			"######################",
		],
		"solution": "R150 | R110 RJ25 R5 RJ25 R60 | R110 RJ25 R5 RJ25 R10 RJ25 R30 RJ25 R200",
		"from": "Maren, the baker's sister", "to": "Tomas",
		"letter": "Tomas, take the honey cake up to the Vane house tomorrow and don't let Odile pay for it. I sat with Wren this afternoon. She asked me how many steps there are in the clock tower. Two hundred and twelve, I said. She said she'll climb every one at midnight to watch the bells, and she'll do it by herself. I didn't have the heart to say anything.",
	},
	{
		"id": "relay",
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
		"page": "Hale says the new year. The bells ring at midnight; the whole town counts down. If the great spring were to stop at one minute to twelve, the minute would never end. Everyone held. Everyone but what I wind myself.",
	},
	{
		"id": "freight",
		"title": "Freight",
		"hint": "The lift takes a crate as gladly as a courier. Something heavy is needed upstairs.",
		"spring": 12.0, "echoes": 1, "par": 1,
		"rise": {"1": 4},
		"map": [
			"########################",
			"#..........*...#.......#",
			"#..............#.......#",
			"#..............B.......#",
			"#............b.B......X#",
			"#...........############",
			"#...........############",
			"#...........############",
			"#a.S...C....############",
			"##########11############",
		],
		"solution": "N150 L60 | R160 N110 R60 RJ25 R200",
		"cog_solution": "N150 L60 | R160 N110 RJ12 N20 J30 N40 L15 N20 R60 RJ25 R200",
		"from": "The Clockmakers' Guild of Varrow", "to": "Mrs. O. Vane",
		"letter": "Madam. The Guild has examined your drawings for a replacement mainspring and must decline. As drawn, the spring would hold perfectly for years and then fail, all at once, at one exact tension. No reputable maker would build a spring designed to break. We trust this is an error in the drawing. Our regards to your daughter.",
		"page": "The Guild will not make it. No matter. I have files, and long nights, and steady hands. Abel has changed the lock on the tower, but I still have the key I cut when I built its escapement, and he has never once thought to ask.",
	},
	{
		"id": "late",
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
		"id": "scald",
		"title": "Scald",
		"hint": "A crate sitting on a vent smothers the steam. The tunnel is too low to jump in.",
		"spring": 12.0, "echoes": 1, "par": 1,
		"map": [
			"######################",
			"#....................#",
			"#....................#",
			"#....................#",
			"#......###############",
			"#.a.C.S.C.......A..X.#",
			"##########^^##########",
		],
		"solution": "L10 LJ25 L14 N60 | R68 N5 L60 LJ25 L5 N15 R200 R30 RJ15 R150",
		"from": "Pip Ashby, age ten", "to": "Wren Vane",
		"letter": "Wren. Father says I'm not to come round because you need quiet, so I'm sending this with the clockwork one instead. The river froze all the way across. I walked on it to the mill and back and nobody saw. When you're better I'll show you where it's thickest. I kept you the best skating stone. It's grey with a white stripe. Don't tell Father.",
	},
	{
		"id": "double",
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
		"page": "It is done. The town is silent. I wound Seven and set it by the door with the mail bag, the way I always do, and I did not take the letters out. I think some part of me wanted them delivered.",
	},
	{
		"id": "wedge",
		"title": "Wedge",
		"hint": "Doors never close on anyone standing in the doorway. Not even on you.",
		"spring": 10.0, "echoes": 1, "par": 1,
		"map": [
			"######################",
			"#.........#....#.....#",
			"#.........#..*.#.....#",
			"#.........#....#.....#",
			"#.........A....B.....#",
			"#S..a.....A..b.B....X#",
			"######################",
		],
		"solution": "R48 N100 R114 | R120 N130 R200",
		"cog_solution": "R48 N100 R114 | R120 N130 R30 N20 RJ12 N20 J30 N40 R200",
		"from": "Odile Vane", "to": "Dr. Ansel Hale",
		"letter": "Ansel. You said she will not see the new year. You said it kindly and you said it twice, and I heard you both times. Very well. Then the year will have to wait for her. Please don't come to the house tonight. I would rather you remembered us the way we were at supper.",
		"page": "I sat with her for what would have been hours. She sleeps. She does not get worse. She does not get better. The snow hangs outside the window like a held breath, and I have begun to understand that one minute can be a very small room.",
	},
	{
		"id": "overtime",
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
		"id": "eleventh",
		"title": "Eleventh Hour",
		"hint": "Whoever goes down to the cellar needs someone upstairs to let them in. For the seal, remember what else can hold a plate down.",
		"spring": 14.0, "echoes": 2, "par": 1,
		"rise": {"1": 4},
		"map": [
			"########################",
			"#...............#......#",
			"#...............#......#",
			"#...............B......#",
			"#............d..B.....X#",
			"#...........############",
			"#............D.........#",
			"#............D.........#",
			"#a...C.S.....D........b#",
			"#########111############",
		],
		"solution": "N60 L130 N10 R100 RJ25 R400 | R40 N290 R50 N100 R200",
		"from": "Dr. Ansel Hale", "to": "Odile Vane",
		"letter": "Odile. Abel came to me tonight and told me what he saw on the stairs, and I think I understand what you mean to do. Listen to me as a friend and not as a doctor. A stopped clock heals no one. It only keeps her where she is, halfway through a breath, for as long as you can bear to watch. Go up and let it ring. Then come home and hold her.",
	},
	{
		"id": "midnight",
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
		"page": "If you are reading this, Seven, you have come all the way up anyway. Good. You were always faster than me on the stairs.",
	},
	# ---------------------------------------------------------------- Act II: New Year
	{
		"id": "firstlight",
		"title": "First Light",
		"hint": "Touch the bell and your echoes hold still for four seconds, even in mid-air. Catch one at the top of its jump.",
		"spring": 10.0, "echoes": 1, "par": 1, "light": 0.55,
		"map": [
			"####################",
			"#..................#",
			"#..................#",
			"#................X.#",
			"#........###########",
			"#......@.###########",
			"#........###########",
			"#.S...##.###########",
			"####################",
		],
		"solution": "R30 RJ14 R40 N60 J40 N200 | R30 RJ12 R6 N60 R14 N38 RJ22 N10 RJ25 R150",
		"from": "Wren Vane", "to": "Courier Seven",
		"letter": "Seven, you were stopped in the hall with your key run down, so I wound you. It took a hundred turns and Mother slept through all of them, in the chair, with her boots on. These are my letters. You don't have to hurry. Nothing has to hurry any more.",
	},
	{
		"id": "millrace",
		"title": "Mill Race",
		"hint": "Belts carry whatever stands on them, crates and couriers alike. Push with a belt and a crate goes twice as fast.",
		"spring": 7.0, "echoes": 0, "par": 0, "light": 0.75,
		"map": [
			"########################",
			"#......................#",
			"#......................#",
			"#S.C.................X.#",
			"#>>>>>>>>>>>^<<<<<<<<###",
			"########################",
		],
		"solution": "R420",
		"from": "Dr. Ansel Hale", "to": "Odile Vane",
		"letter": "Odile. I came by at first light and she was sitting up in bed, demanding toast. I have been a doctor for twenty-six years and I do not know what to write in my notes, so I have written: saw the new year. I will come again tomorrow, and the day after, and I will keep being wrong for as long as she likes.",
	},
	{
		"id": "sorting",
		"title": "Sorting Office",
		"hint": "The parcel rides the belt by itself. Someone has to let it through the door, and someone has to meet it at the far end.",
		"spring": 7.4, "echoes": 1, "par": 1, "light": 0.85,
		"map": [
			"##########################",
			"#........................#",
			"#...C.......A....b#......#",
			"#..>>>>>>>>>>>>>>##......#",
			"#........................#",
			"#........................#",
			"#..................B.....#",
			"#a..S..............B..X..#",
			"##########################",
		],
		"solution": "L60 N400 | R600",
		"from": "Odile Vane", "to": "The Clockmakers' Guild of Varrow",
		"letter": "Sirs. You were right about the drawing, and right to refuse it. Enclosed are new plans for a mainspring that should hold for a hundred years, made the ordinary way. I would be grateful if you would build it. I find I have no further use for the other kind.",
	},
	{
		"id": "treadmill",
		"title": "Treadmill",
		"hint": "Nobody can stand still on a moving belt, except an echo that a bell is holding.",
		"spring": 12.0, "echoes": 1, "par": 1, "light": 0.95,
		"map": [
			"######################",
			"#..........*.........#",
			"#....................#",
			"#...........@A.......#",
			"#S.....a.....A....X..#",
			"#<<<<<<<<<<<<#########",
			"######################",
		],
		"solution": "R220 N400 | R320 RJ20 R200",
		"cog_solution": "R250 N600 | R262 J6 N6 LJ14 N10 J24 N20 J24 N20 R250 RJ20 R200",
		"from": "Abel Rook", "to": "his son, at sea",
		"letter": "The bells rang. Mrs. Vane came down the tower stairs at ten past twelve and shook my hand, and neither of us said a word. I have told the council that the old spring simply wore out. It is not quite a lie: it was worn out by someone who loved her girl. Come home when you can. The town is very loud.",
		"page": "Second of January. Ansel came at noon and stayed for tea, and then for supper. He says spring. He says it carefully, the way he says everything, but he says it, and he did not look at the floor when he did.",
	},
	{
		"id": "carillon",
		"title": "Carillon",
		"hint": "Two echoes jumping together, held at the top, make a stair no one could stand on. Ring the bell when they peak.",
		"spring": 10.0, "echoes": 2, "par": 2, "light": 1.0,
		"map": [
			"################",
			"#..............#",
			"#..............#",
			"#............X.#",
			"#.......########",
			"#.......########",
			"#.......########",
			"#.......########",
			"#.@S.#.#########",
			"################",
		],
		"solution": "R10 RJ14 R6 N10 RJ16 R20 N60 J40 N300 | R10 RJ14 R6 N10 R20 N76 J40 N300 | N147 L8 R8 RJ20 R4 N10 R12 N4 J24 N6 R8 N4 J24 N6 RJ26 N1 RJ30 R60",
		"from": "Tomas the baker", "to": "his sister Maren",
		"letter": "Maren. I took the honey cake up like you said, and Odile paid anyway; she slipped the coins into my apron pocket when I wasn't looking, the way she used to when we were children. Wren ate two slices and asked for the recipe. I told her it's a secret. I'll tell her in the spring.",
	},
	{
		"id": "river",
		"title": "Race to the River",
		"hint": "Everything at once. One of you is a step, one of you holds the door, and one of you runs. A bell only holds the echoes that came before whoever rings it.",
		"spring": 8.0, "echoes": 2, "par": 2, "light": 1.0,
		"map": [
			"##############################",
			"#..............#.............#",
			"#..............#.............#",
			"#..............#.............#",
			"#...........a..#.............#",
			"#........#######.........*...#",
			"#......@.......#.............#",
			"#..............A.............#",
			"#.S...##.......A.C.........X.#",
			"################>>>>>>>>>>^###",
		],
		"solution": "R30 RJ14 R40 N60 J40 N300 | R30 RJ12 R6 N60 R14 N38 RJ22 N10 RJ25 R36 N300 | R25 RJ18 R600",
		"cog_solution": "R30 RJ14 R40 N60 J40 N300 | R30 RJ12 R6 N60 R14 N38 RJ22 N10 RJ25 R36 N300 | R25 RJ18 R250 R50 RJ14 R4 N12 J30 N6 RJ16 R8 N30 L10",
		"from": "Pip Ashby", "to": "Wren Vane",
		"letter": "Wren! Father says I can come round now. I'm not sending the stone, I'm bringing it, and you're to put your boots on, because the ice is thickest by the mill and Father says if your mother says yes then he says yes too. I asked Seven to tell you first. Seven is quicker than me. Not for long.",
		"page": "First of January. I slept. When I woke the clock was striking nine, and Wren was on the stairs in her nightgown reading the morning post aloud to Seven, very slowly, doing all the voices. I have spent a year trying to stop time. It turns out I only wanted it to be kind.",
	},
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


## True when level i hides a cog (its journal page is in the level's "page").
static func has_cog(i: int) -> bool:
	return ALL[i].has("page")


static func page_count() -> int:
	var n := 0
	for l in ALL:
		if l.has("page"):
			n += 1
	return n


## Level index for an id, or -1.
static func index_of(id: String) -> int:
	for i in ALL.size():
		if ALL[i].id == id:
			return i
	return -1


## Which act level i belongs to.
static func act_of(i: int) -> int:
	var a := 0
	for k in ACTS.size():
		if i >= int(ACTS[k].first):
			a = k
	return a


## The index of the last level in act a.
static func act_last(a: int) -> int:
	return int(ACTS[a + 1].first) - 1 if a + 1 < ACTS.size() else ALL.size() - 1


## True when finishing level i ends its act (and plays that act's ending).
static func ends_act(i: int) -> bool:
	return i == act_last(act_of(i))
