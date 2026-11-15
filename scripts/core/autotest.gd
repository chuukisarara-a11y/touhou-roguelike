extends Node
## 自动测试：模拟拖动与符卡，定时截图后退出。仅在带 --autotest 参数启动时加载。

var t := 0.0
var shot_n := 0
var bombed := false
var out_dir := "/tmp/shots"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(dt: float) -> void:
	t += dt
	var b = get_parent()
	b.player.touch_delta += Vector2(cos(t * 2.0) * 2.0, cos(t * 3.0) * 1.0)
	if t > 2.5 and shot_n == 0:
		_snap()
	if t > 4.0 and not bombed:
		bombed = true
		b.player.bomb_gauge = 1.0
		b.use_bomb()
	if t > 4.4 and shot_n == 1:
		_snap()
	if t > 7.0:
		print("AUTOTEST kills=%d fps=%d shots=%d" % [b.kills, Engine.get_frames_per_second(), b.shots.list.size()])
		get_tree().quit()

func _snap() -> void:
	shot_n += 1
	get_viewport().get_texture().get_image().save_png("%s/shot%d.png" % [out_dir, shot_n])
