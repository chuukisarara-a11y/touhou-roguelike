extends Node
## 界面截图测试（开发用）：依次打开各界面并截图。用 --uitest 启动。
var t := 0.0
var step := 0
var steps := []
func _ready() -> void:
	G.meta.dev = true
	G.meta.seen = {"reimu": true, "cirno": true, "sakuya": true, "rumia": true}
	steps = [
		[0.6, func(): G.main.goto("title")],
		[0.9, func(): snap("title")],
		[0.2, func(): UI.open_settings(G.main.screen)],
		[0.6, func(): snap("settings")],
		[0.2, func(): G.main.goto("title"); Dev.open(G.main.screen)],
		[0.8, func(): snap("dev")],
		[0.2, func(): G.main.goto("gallery")],
		[0.9, func(): snap("gallery")],
		[0.2, func(): G.main.screen._show("cirno")],
		[0.6, func(): snap("gallery_cirno")],
		[0.2, func(): G.main.goto("assets")],
		[1.0, func(): snap("assets")],
		[0.2, func(): G.main.start_run()],
		[0.9, func(): snap("map")],
		[0.1, func():
			G.run.weapons = [{"id": "amulet", "lv": 3, "cd": 0.0, "mods": ["split", "rapid"], "awake": true}, {"id": "laser", "lv": 2, "cd": 0.0}, {"id": "yinyang", "lv": 1, "cd": 0.0}]
			for k in ["counter", "afterglow", "shanghai", "reflect", "slow_shield"]: G.add_skill(k)
			for k in ["hakkero", "tea", "laevatein", "slow_dmg", "bomb_big", "first_strike", "interest"]: G.add_relic(k)
			G.run.power = 2; G.run.dolls = 1
			G.main.goto("map")],
		[0.8, func(): snap("map2"); Bag.open(G.main.screen)],
		[0.8, func(): snap("bag"); Bag.detail(G.main.screen, "weapon", "amulet")],
		[0.6, func(): snap("bag_weapon")],
		[0.1, func():
			for o in get_tree().get_nodes_in_group("overlay"): o.queue_free()
			Bag.detail(G.main.screen, "skill", "reflect")],
		[0.6, func(): snap("bag_skill")],
		[0.1, func():
			for o in get_tree().get_nodes_in_group("overlay"): o.queue_free()
			G.run.money = 300; G.run.pos = 0
			G.main.goto("shop")],
		[0.8, func(): snap("shop"); G.main.screen._detail(G.main.screen.items[3])],
		[0.6, func(): snap("shop_detail")],
		[0.1, func():
			for o in get_tree().get_nodes_in_group("overlay"): o.queue_free()
			G.main.screen.tab = 3; G.main.screen._show()],
		[0.5, func(): snap("shop_up"); G.main.goto("rest")],
		[0.7, func():
			snap("rest")
			G.main.goto("reward", {"kind": "battle", "no_hit": false, "earned": 20})],
		[0.8, func(): snap("reward"); G.main.goto("map")],
		[0.5, func(): G.main.enter_node(G.main.screen.reachable()[0])],
		[2.0, func(): G.main.screen.pause()],
		[0.6, func(): snap("pause")],
		[0.1, func(): print("save exists=", G.has_save()); get_tree().paused = false; G.main.goto("title")],
		[0.8, func(): snap("title_continue")],
		[0.1, func(): G.main.continue_run()],
		[1.0, func(): print("resumed screen=", G.main.screen_name, " floor=", G.run.floor); snap("resumed")],
		[0.1, func(): get_tree().quit()],
	]
	process_mode = Node.PROCESS_MODE_ALWAYS
func snap(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/ui_%02d_%s.png" % [step, n])
func _process(dt: float) -> void:
	t += dt
	if step < steps.size() and t >= steps[step][0]:
		t = 0.0
		steps[step][1].call()
		step += 1
