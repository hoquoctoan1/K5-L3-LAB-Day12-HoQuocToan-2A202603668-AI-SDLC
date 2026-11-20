extends Node
## AudioBus: play_sfx(name), play_music(), stop_music(). Am luong theo settings.volume.
## No-op khi headless (enabled=false): khong tao player, khong anh huong gameplay.
const Synth = preload("res://src/adapters/view/audio/synth.gd")
var settings            # tuy chon: doi tuong Settings (volume 0..1)
var enabled: bool = DisplayServer.get_name() != "headless"
var _cache := {}
var _music: AudioStreamPlayer
var _pool: Array = []

func _stream(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		_cache[name] = Synth.to_wav(Synth.music() if name == "music" else Synth.sfx(name), name == "music")
	return _cache[name]

func _db(extra: float = 0.0) -> float:
	var v: float = settings.volume if settings != null else 0.8
	return linear_to_db(maxf(v, 0.0001)) + extra

func apply_volume() -> void:
	if _music:
		_music.volume_db = _db(-10.0)

func play_sfx(name: String) -> void:
	if not enabled or not Synth.SFX_NAMES.has(name):
		return
	var p: AudioStreamPlayer = null
	for q in _pool:
		if not q.playing:
			p = q
			break
	if p == null and _pool.size() < 8:
		p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	if p == null:
		return
	p.stream = _stream(name)
	p.volume_db = _db()
	p.play()

func play_music() -> void:
	if not enabled:
		return
	if _music == null:
		_music = AudioStreamPlayer.new()
		add_child(_music)
	_music.stream = _stream("music")
	_music.volume_db = _db(-10.0)
	if not _music.playing:
		_music.play()

func stop_music() -> void:
	if _music:
		_music.stop()
