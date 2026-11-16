extends Node
## 音频单例：BGM（按槽位名找 assets/music/<名字>.ogg，没有文件就保持安静）与音效。

const MIN_GAP := {"shoot": 0.09, "hit": 0.05, "graze": 0.05, "coin": 0.04, "kill": 0.03}
var bgm_db := -9.0
var sfx_db := -6.0
var _bgm: AudioStreamPlayer
var _bgm_name := ""
var _pool := []
var _next := 0
var _last := {}
var _cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

## 播放某个槽位的 BGM；名字相同则不打断。找不到文件时淡出为静音。
func bgm(name: String) -> void:
	if name == _bgm_name:
		return
	_bgm_name = name
	var path := "res://assets/music/%s.ogg" % name
	var tw := create_tween()
	if _bgm.playing:
		tw.tween_property(_bgm, "volume_db", -50.0, 0.35)
	tw.tween_callback(func():
		_bgm.stop()
		if name != "" and ResourceLoader.exists(path):
			var st: AudioStream = load(path)
			if st is AudioStreamOggVorbis:
				st.loop = true
			_bgm.stream = st
			_bgm.volume_db = bgm_db
			_bgm.play())

func sfx(name: String, db := 0.0, pitch_var := 0.04) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last.get(name, -1.0) < MIN_GAP.get(name, 0.0):
		return
	_last[name] = now
	if not _cache.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	if _cache[name] == null:
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = _cache[name]
	p.volume_db = sfx_db + db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()
