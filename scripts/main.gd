extends Node
## Switches between the title screen and levels. Debug args (after --):
##   --level=N        start at level N (1-based)
##   --auto           play that level's solution by itself (--auto=cog for the cog route)
##   --touch          show the touch buttons (not saved)
##   --shot=PATH      save a screenshot after --frames=F frames and quit

var _screen: Node


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("touch"):
		Save.data.settings.touch = 1
		Touch._refresh()
	Sfx.music(true)
	if args.has("level"):
		start_level(int(args["level"]) - 1)
		if args.has("auto"):
			var key := "cog_solution" if args["auto"] == "cog" else "solution"
			(_screen as Game).autoplay(Levels.get_level(int(args["level"]) - 1).get(key, ""))
	else:
		show_title()
	if args.has("shot"):
		_screenshot(args["shot"], int(args.get("frames", "90")))


func show_title() -> void:
	_swap(TitleScreen.new())
	(_screen as TitleScreen).play.connect(start_level)


func start_level(i: int) -> void:
	var g := Game.new(i)
	_swap(g)
	g.finished.connect(func(next: int):
		if next < 0:
			show_title()
		else:
			start_level(next))
	g.quit_to_menu.connect(show_title)


func _swap(n: Node) -> void:
	get_tree().paused = false
	if _screen:
		_screen.queue_free()
	_screen = n
	add_child.call_deferred(n)


func _screenshot(path: String, frames: int) -> void:
	for i in frames:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path)
	get_tree().quit()
