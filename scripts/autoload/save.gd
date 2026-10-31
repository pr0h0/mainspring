extends Node
## Progress and settings, saved to user://save.json. Also sets up the input actions.

signal changed

const PATH := "user://save.json"
const TOUCH_MODES := ["Auto", "On", "Off"]

## Version 1 saves keyed everything by level index; these were the levels then, in order.
const V1_LEVELS := ["morning", "held", "heavy", "stepping", "relay", "late", "double", "overtime", "midnight"]
const V1_PAGES := ["morning", "heavy", "relay", "double", "midnight"]

var data := {
	"version": 2,
	"best": {},  # level id -> fewest echoes used
	"pages": [],  # ids of levels whose journal page was found
	"settings": {"master": 0.8, "music": 0.6, "sfx": 0.8, "fullscreen": false, "touch": 0, "hints": true},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_actions()
	_load()
	apply()


func _setup_actions() -> void:
	# Arrows and WASD both work; W and Up jump too.
	var keys := {
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"jump": [KEY_SPACE, KEY_UP, KEY_W],
		"unwind": [KEY_R, KEY_SHIFT],
		"undo": [KEY_Z, KEY_U],
		"restart": [KEY_BACKSPACE],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	var pads := {
		"move_left": [JOY_BUTTON_DPAD_LEFT],
		"move_right": [JOY_BUTTON_DPAD_RIGHT],
		"jump": [JOY_BUTTON_A],
		"unwind": [JOY_BUTTON_X],
		"undo": [JOY_BUTTON_Y],
		"restart": [JOY_BUTTON_BACK],
		"pause": [JOY_BUTTON_START],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		for b in pads[action]:
			var j := InputEventJoypadButton.new()
			j.button_index = b
			InputMap.action_add_event(action, j)
	for pair in [["move_left", -1.0], ["move_right", 1.0]]:
		var m := InputEventJoypadMotion.new()
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = pair[1]
		InputMap.action_add_event(pair[0], m)


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed:
			if k == "settings":
				for s in parsed[k]:
					data.settings[s] = parsed[k][s]
			else:
				data[k] = parsed[k]
		if int(parsed.get("version", 1)) < 2:
			_migrate_v1()


func _migrate_v1() -> void:
	var best := {}
	for k in data.best:
		var i := int(k)
		if i >= 0 and i < V1_LEVELS.size():
			best[V1_LEVELS[i]] = data.best[k]
	var pages := []
	for p in data.pages:
		var i := int(p)
		if i >= 0 and i < V1_PAGES.size():
			pages.append(V1_PAGES[i])
	data.best = best
	data.pages = pages
	data.erase("unlocked")
	data.version = 2
	save()


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
	changed.emit()


func setting(key: String):
	return data.settings.get(key)


func set_setting(key: String, value) -> void:
	data.settings[key] = value
	apply()
	save()


func apply() -> void:
	for bus in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var i := AudioServer.get_bus_index(bus[0])
		if i == -1:
			AudioServer.add_bus()
			i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus[0])
			AudioServer.set_bus_send(i, "Master")
		var v := float(setting(bus[1]))
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)
	if not OS.has_feature("web") or setting("fullscreen"):
		var want := Window.MODE_FULLSCREEN if setting("fullscreen") else Window.MODE_WINDOWED
		if get_window().mode != want and not (want == Window.MODE_WINDOWED and get_window().mode == Window.MODE_MAXIMIZED):
			get_window().mode = want


# ------------------------------------------------------------ progress

func _id(i: int) -> String:
	return Levels.get_level(i).id


func solved(i: int) -> bool:
	return data.best.has(_id(i))


## The first level is always open; after that, a level opens once the one before it is delivered.
func is_open(i: int) -> bool:
	return i == 0 or solved(i) or solved(i - 1)


func best(i: int) -> int:
	return int(data.best.get(_id(i), -1))


func sealed(i: int) -> bool:
	return solved(i) and best(i) <= int(Levels.get_level(i).par)


## Whether the journal page hidden in level i has been found.
func has_page(i: int) -> bool:
	return _id(i) in data.pages


## Records a delivery. Returns what's new: {"first": bool, "seal": bool, "page": bool}.
func record(i: int, echoes: int, cog: bool) -> Dictionary:
	var out := {"first": not solved(i), "seal": false, "page": false}
	var had_seal := sealed(i)
	if not solved(i) or echoes < best(i):
		data.best[_id(i)] = echoes
	out.seal = sealed(i) and not had_seal
	if cog and Levels.has_cog(i) and not has_page(i):
		data.pages.append(_id(i))
		out.page = true
	save()
	return out


func next_unsolved() -> int:
	for i in Levels.count():
		if not solved(i):
			return i
	return 0
