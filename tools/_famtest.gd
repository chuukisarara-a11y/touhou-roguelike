extends Node
## 开发用：指定攻符/秘符直接开打并截图（--famtest --w=yinyang:3:0,pillar:2 --s=pl_quake --char=reimu）
var t := 0.0
var n := 0
var tag := "fam"
func _ready() -> void:
	G.dev_god = true
	var ch := "reimu"
	var ws := []
	var ss := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--char="): ch = a.trim_prefix("--char=")
		if a.begins_with("--w="): ws = Array(a.trim_prefix("--w=").split(","))
		if a.begins_with("--s="): ss = Array(a.trim_prefix("--s=").split(","))
		if a.begins_with("--tag="): tag = a.trim_prefix("--tag=")
	G.new_run(ch)
	G.next_chapter()
	G.run.weapons = []
	for x in ws:
		var p: PackedStringArray = x.split(":")
		var w := {"id": p[0], "lv": int(p[1]) if p.size() > 1 else 1, "cd": 0.0}
		if p.size() > 2: w["br"] = int(p[2])
		if p.size() > 3: w["copy"] = p[3]
		G.run.weapons.append(w)
	G.run.skills = ss
	G.run.bomb = 2.0
	G.main.goto("battle", {"kind": "battle"})
func _process(dt: float) -> void:
	t += dt
	var b = G.main.screen
	if b != null and "fams" in b and b.fams != null:
		b.fams.yy_cnt = maxi(b.fams.yy_cnt, 0)
		if t > 2.0 and t < 2.1 and OS.get_cmdline_user_args().has("--skill"):
			b.fams.yy_cnt = 999; b.fams.rf_hits = 999
		if t > 3.0 and t < 3.05 and OS.get_cmdline_user_args().has("--toggle"):
			b.fams.toggle_familiars()
	for k in [3.4, 5.5]:
		if n == [3.4, 5.5].find(k) and t > k:
			n += 1
			get_viewport().get_texture().get_image().save_png("/tmp/fam_%s_%d.png" % [tag, n])
	if t > 5.8:
		get_tree().quit()
