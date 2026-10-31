extends Node
## Sound effects from assets/audio/<name>.wav (made by tools/gen_audio.py), plus the music-box
## loop and the clockwork ambience.

const VARY := {"jump": 0.08, "land": 0.1, "push": 0.12, "tick": 0.04, "click": 0.03, "thud": 0.1}

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = _loop_player("music", "Music", -6.0)
	_ambience = _loop_player("ambience", "SFX", -10.0)


func _loop_player(name: String, bus: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.volume_db = db
	var s := _stream(name)
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
	p.stream = s
	add_child(p)
	return p


func _stream(name: String) -> AudioStream:
	if not _streams.has(name):
		var path := "res://assets/audio/%s.wav" % name
		_streams[name] = load(path) if ResourceLoader.exists(path) else null
	return _streams[name]


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var s := _stream(name)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch * (1.0 + randf_range(-1.0, 1.0) * float(VARY.get(name, 0.0)))
	p.play()


func music(on: bool) -> void:
	for p in [_music, _ambience]:
		if p.stream == null:
			continue
		if on and not p.playing:
			p.play()
		elif not on:
			p.stop()
