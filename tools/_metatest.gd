extends Node
## 开发用：标题 / 图鉴 / 角色选择 / 说明 / 行囊详情 / 神社 截图（--metatest）
var t := 0.0
var step := 0
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/meta/%s.png" % n)
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/meta")
	G.meta.asc = {"reimu": 4}
	G.meta.chars["marisa"] = true
	G.meta.tut = true
	for id in ["amulet", "needle", "hakkero", "fan"]:
		G.meta.codex[id] = true
	G.meta.ach = {"first_win": true, "combo50": true}
	G.meta.spells = {"rumia:夜符「夜雀之歌」": {"try": 3, "cap": 1}}
	G.main.goto("title")
func _process(dt: float) -> void:
	t += dt
	var ns := int(t / 0.7)
	if ns == step:
		return
	step += 1
	t = step * 0.7
	match step:
		1: shot("title"); G.main.goto("codex")
		2: shot("codex0"); G.main.screen.tab = 1; G.main.goto("codex")
		3: shot("codex1"); Bag.detail(G.main.screen, "weapon", "amulet")
		4: shot("codex1d"); G.main.screen.tab = 3; G.main.goto("codex")
		5: shot("codex3"); G.main.goto("chars")
		6: shot("chars"); G.main.screen._pick_asc("reimu")
		7: shot("asc"); G.main.goto("title"); UI.tutorial(G.main.screen)
		8:
			shot("tut")
			G.new_run("reimu", 4); G.main.goto("map"); Bag.open(G.main.screen)
		9:
			var ov = get_tree().get_nodes_in_group("overlay")[0]
			Bag.detail(ov, "weapon", "amulet")
		10: shot("bagdetail"); print("LAYERS ", get_tree().get_nodes_in_group("overlay").map(func(o): return o.layer)); G.main.toast("成就达成：测试"); G.run.hearts = 1; G.main.goto("rest")
		11: shot("rest"); G.heal(2); G.run["rest_used"] = G.main.screen._key(); G.main.goto("rest")
		12: shot("rest2"); get_tree().quit()
