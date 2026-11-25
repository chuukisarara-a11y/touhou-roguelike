extends Node
## 开发用：把 8 种机制小怪一次放出来截图（--mobtest）
var t := 0.0
var n := 0
func _ready() -> void:
	G.dev_god = true
	G.new_run()
	G.next_chapter()
	if OS.get_cmdline_user_args().has("--gap"):
		G.next_chapter(); G.next_chapter()
	G.run.floor = 3
	G.run.weapons = [{"id": "needle", "lv": 1, "cd": 0.0}]
	G.main.goto("battle", {"kind": "battle"})
	await get_tree().process_frame
	var b = G.main.screen
	b.waves = [[]]
	b.wave_i = 0
	b.pending = []
	var tt := 0.0
	var ids := ["m_gap", "m_gap", "m_gap"] if OS.get_cmdline_user_args().has("--gap") else ["m_shield", "m_split", "m_bomber", "m_mine", "m_sniper", "m_guard", "m_runner", "m_mirror"]
	for id in ids:
		for s in Waves._special(id, tt):
			b.pending.append(s)
		tt += 0.3
	b.pending.sort_custom(func(a, c): return a.t < c.t)
func _process(dt: float) -> void:
	t += dt
	var ks := [4.3, 5.4] if OS.get_cmdline_user_args().has("--gap") else [4.2, 7.0]
	for k in ks:
		if n == ks.find(k) and t > k:
			n += 1
			get_viewport().get_texture().get_image().save_png("/tmp/mob_%d.png" % n)
			print("MOB enemies=", G.main.screen.enemies.list.size(), " bullets=", G.main.screen.bullets.list.size(), " lasers=", G.main.screen.bullets.lasers.size())
	if t > 7.3:
		get_tree().quit()
