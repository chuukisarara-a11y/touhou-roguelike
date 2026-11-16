extends Node2D
## 场景管理：在标题、地图、战斗、奖励、商店、事件、神社、结算之间切换。

const SCREENS := {
	"title": "res://scripts/screens/title.gd",
	"map": "res://scripts/screens/map.gd",
	"battle": "res://scripts/battle/battle.gd",
	"reward": "res://scripts/screens/reward.gd",
	"shop": "res://scripts/screens/shop.gd",
	"event": "res://scripts/screens/event.gd",
	"rest": "res://scripts/screens/rest.gd",
	"result": "res://scripts/screens/result.gd",
	"talk": "res://scripts/screens/talk.gd",
	"gallery": "res://scripts/screens/gallery.gd",
	"assets": "res://scripts/screens/assets.gd",
}

var screen: Node
var screen_name := ""
var _fade: ColorRect

func _ready() -> void:
	G.main = self
	UI.install_theme(get_tree().root)
	if G.bot:
		add_child(load("res://scripts/core/autotest.gd").new())
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.04, 0.1, 0.0)
	_fade.size = Vector2(G.FIELD_W, 2000)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_fade)
	goto("title")
	for tn in ["uitest", "_scrolltest", "_spelltest", "_mobtest", "_bagtest"]:   # 开发用的自动测试脚本
		if OS.get_cmdline_user_args().has("--" + tn.trim_prefix("_")):
			add_child(load("res://tools/%s.gd" % tn).new())

func goto(name: String, arg := {}) -> void:
	if screen != null:
		screen.queue_free()
	screen = Node2D.new()
	screen.set_script(load(SCREENS[name]))
	screen_name = name
	if name in ["map", "battle", "reward", "shop", "event", "rest", "talk"]:
		G.save_run(name, arg)
	elif name == "result":
		G.clear_run()
	_pick_bgm(name, arg)
	if screen.has_method("setup"):
		screen.setup(arg)
	add_child(screen)
	# 切换界面时的淡入
	_fade.color.a = 1.0
	_fade.create_tween().tween_property(_fade, "color:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE)

## 各界面对应的 BGM 槽位（文件放在 assets/music/ 下，缺文件则静音）
func _pick_bgm(name: String, arg: Dictionary) -> void:
	match name:
		"title", "gallery", "assets":
			Au.bgm("title")
		"talk":
			Au.bgm("")
		"battle":
			var ch: int = G.run.chapter
			Au.bgm(("boss%d" % ch) if arg.get("kind", "") == "boss" else ("battle%d" % ch))
		"result":
			Au.bgm("result" if arg.get("win", false) else "gameover")
		_:
			Au.bgm("map")

func start_run() -> void:
	G.clear_run()
	G.new_run()
	G.meta.runs += 1
	G.save_meta()
	goto("map")

func continue_run() -> void:
	if G.load_run():
		goto(G.resume.screen, G.resume.arg)
	else:
		goto("title")

## 开发者：从第 n 章开头开始，并给一套像样的构筑
func dev_start_chapter(n: int) -> void:
	G.new_run()
	var ids := ["amulet", "needle", "laser", "yinyang"]
	G.run.weapons = []
	for id in ids:
		G.run.weapons.append({"id": id, "lv": mini(3, n + 1), "cd": 0.0})
	G.run.money = 150 * n
	for i in range(1, n):
		G.next_chapter()
		G.give_shard(i)
	goto("map")

## 开发者：直接打某个 Boss / 精英
func dev_fight(boss_id: String) -> void:
	var ch := 1
	for c in Db.CHAPTERS:
		if Db.CHAPTERS[c].boss == boss_id or Db.CHAPTERS[c].elites.has(boss_id):
			ch = c
	dev_start_chapter(ch)
	G.run.floor = 8
	G.run.pos = G.run.map.size() - 1
	if Db.TALKS.has(boss_id):
		goto("talk", {"boss": boss_id, "kind": "boss" if Db.CHAPTERS[ch].boss == boss_id else "elite"})
	else:
		goto("battle", {"kind": "elite", "boss": boss_id})

func enter_node(i: int) -> void:
	var run: Dictionary = G.run
	run.pos = i
	var node: Dictionary = run.map[i]
	run.floor = node.f + 1
	if G.has("interest"):
		run.money += mini(15, (run.money / 50) * 3)
	match node.type:
		"battle", "elite", "boss":
			if node.type == "battle" and run.chapter_first and G.has("bouyu"):
				run.chapter_first = false
				run.money += 25
				battle_done({"kind": "battle", "no_hit": false, "earned": 25, "skipped": true})
			elif node.type == "boss":
				goto("talk", {"boss": Db.CHAPTERS[run.chapter].boss})
				return
			elif node.type == "elite":
				var el: Array = Db.CHAPTERS[run.chapter].elites
				goto("talk", {"boss": el[G.rng.randi_range(0, el.size() - 1)], "kind": "elite"})
			else:
				goto("battle", {"kind": node.type})
		_:
			goto(node.type)

func battle_done(info: Dictionary) -> void:
	var run: Dictionary = G.run
	run.battles += 1
	# 第一章的境界碎片：无伤击破精英
	if info.kind == "elite":
		if run.chapter == 1 and not run.sh[0]:
			if info.no_hit and G.give_shard(1):
				info["shard"] = true
			else:
				info["shard_miss"] = true
		if G.has("elite_hunter"):
			run.money += 40
			info.earned += 40
	run.chapter_first = false
	if G.has("onigiri"):
		run.onigiri += 1
		if run.onigiri >= 2:
			run.onigiri = 0
			G.heal(1)
	goto("reward", info)

func node_done() -> void:
	var node: Dictionary = G.run.map[G.run.pos]
	if node.type == "boss":
		var ch: int = G.run.chapter
		if ch < 3 or (ch == 3 and G.run.shards >= 3):
			G.next_chapter()
			goto("map")
		else:
			goto("result", {"win": true, "true_end": ch == 4})
	else:
		goto("map")

func game_over() -> void:
	goto("result", {"win": false})

## Android 返回键 / 切到后台：存档已在进入界面时写好，这里只保存设置
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		G.save_meta()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var ovs := get_tree().get_nodes_in_group("overlay").filter(func(o): return not o.is_queued_for_deletion())
		if not ovs.is_empty() and not get_tree().paused:   # 返回键先关最上面的弹出层
			ovs[-1].queue_free()
			return
		if screen != null and screen.has_method("on_back"):
			screen.on_back()
