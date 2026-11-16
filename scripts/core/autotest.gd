extends Node
## 自动测试机器人：自动点选项、自动打完一整局并截图。带 --autotest 启动时加载。
## 战斗中机器人不扣血，但会统计被弹次数，用来粗略衡量难度。

var out_dir := "/tmp/shots"
var t := 0.0
var step_t := 0.0
var last_screen := ""
var shot_n := 0
var snap_in := -1.0
var runs_left := 1
var log := []

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		if a.begins_with("--runs="):
			runs_left = int(a.substr(7))
		if a.begins_with("--seed="):
			G.rng.seed = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out_dir)
	Engine.time_scale = 6.0 if DisplayServer.get_name() == "headless" else 3.0

func _process(dt: float) -> void:
	var real := dt / Engine.time_scale
	t += real
	var m = get_parent()
	if m.screen_name != last_screen:
		last_screen = m.screen_name
		snap_in = 0.5 if m.screen_name != "battle" else 3.0
	if snap_in > 0.0:
		snap_in -= real
		if snap_in <= 0.0 and shot_n < 90:
			shot_n += 1
			var img := get_viewport().get_texture().get_image()
			if img != null:
				img.save_png("%s/%02d_%s.png" % [out_dir, shot_n, m.screen_name])
	step_t += real
	if step_t > (0.8 if Engine.time_scale < 5.0 else 0.15) and snap_in <= 0.0:
		step_t = 0.0
		if m.screen != null and m.screen.has_method("bot_step"):
			m.screen.bot_step()
	if t > 900.0:
		finish("TIMEOUT")

func note(s: String) -> void:
	log.append(s)

func finish(why: String) -> void:
	runs_left -= 1
	print("AUTOTEST %s | %s" % [why, " ; ".join(log)])
	log.clear()
	if runs_left <= 0 or why == "TIMEOUT":
		get_tree().quit()
