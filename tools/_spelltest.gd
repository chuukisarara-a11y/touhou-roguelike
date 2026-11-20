extends Node
## 开发用：依次进入每个 Boss 的每张符卡并截图（--spelltest），统计子弹数量与帧率
var queue := []
var t := 0.0
var cur := []
var maxb := 0
var fps_min := 999
func _ready() -> void:
	G.dev_god = true
	var ids: Array = Db.BOSSES.keys()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):   # 例：--only=kaguya,sakuya
			ids = Array(arg.trim_prefix("--only=").split(","))
	for id in (["alice", "patchouli_b"] if OS.get_cmdline_user_args().has("--few") and ids.size() == Db.BOSSES.size() else ids):
		for i in Db.BOSSES[id].phases.size():
			queue.append([id, i])
	_next()
func _next() -> void:
	if queue.is_empty():
		get_tree().quit()
		return
	cur = queue.pop_front()
	var ch := 1
	for c in Db.CHAPTERS:
		if Db.CHAPTERS[c].boss == cur[0] or Db.CHAPTERS[c].elites.has(cur[0]):
			ch = c
	G.new_run("marisa")
	for i in range(1, ch):
		G.next_chapter()
	G.run.floor = 8
	G.main.goto("battle", {"kind": "boss", "boss": cur[0]})
	t = 0.0
	maxb = 0
	fps_min = 999
func _process(dt: float) -> void:
	t += dt
	var b = G.main.screen
	if b == null or not b.has_method("pause") or b.boss == null:
		return
	if t > 0.3 and t < 0.4 and b.boss.phase_i != cur[1]:
		b.boss.phase_i = cur[1]
		b.boss.load_phase()
		b.boss.pause = 0.0
	b.boss.hp = b.boss.max_hp
	if OS.get_cmdline_user_args().has("--few") and int(t * 2) != int((t - dt) * 2) and not b.bullets.lasers.is_empty():
		var l = b.bullets.lasers[0]
		print("  t=%.1f lasers=%d l.t=%.2f warn=%.1f w=%.1f" % [t, b.bullets.lasers.size(), l.t, l.warn, l.cur_w()])
	if t > 1.5:
		maxb = maxi(maxb, b.bullets.list.size())
		fps_min = mini(fps_min, Engine.get_frames_per_second())
	for st in ([5.0] if not OS.get_cmdline_user_args().has("--few") else [4.0, 6.5]):
		if t > st and t < st + dt * 1.5:
			get_viewport().get_texture().get_image().save_png("/tmp/spx/sp_%s_%d%s.png" % [cur[0], cur[1], "" if st == 5.0 else "_%d" % int(st * 10)])
	if t > (5.3 if not OS.get_cmdline_user_args().has("--few") else 7.3):
		print("SPELL %s %d %s | 最多子弹 %d" % [cur[0], cur[1], b.boss.phases[cur[1]].name, maxb])
		_next()
