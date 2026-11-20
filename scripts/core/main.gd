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
	"chars": "res://scripts/screens/chars.gd",
	"codex": "res://scripts/screens/codex.gd",
	"assets": "res://scripts/screens/assets.gd",
}

var screen: Node
var screen_name := ""
var _fade: ColorRect
var _cl: CanvasLayer
var _toasts := 0

## 章节过场：屏幕中间渐显再渐隐「第二幕　红魔馆」
func chapter_card(n: int) -> void:
	var nm: String = G.chap(n).name
	var parts := nm.split(" ", false, 1)
	var big: String = parts[0].replace("章", "幕")
	var sub: String = parts[1] if parts.size() > 1 else ""
	var hh := G.field_h()
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size = Vector2(G.FIELD_W, hh)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.0, 0.06, 0.6)
	bg.size = root.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var cy := hh * 0.42
	var l1 := UI.label(root, big, cy - 26, 12, Color(1.0, 0.88, 0.62), 0, G.FIELD_W / 2.0)
	l1.scale = Vector2(2, 2)   # 像素字放大两倍，保持清晰
	var line := ColorRect.new()
	line.color = Color(1.0, 0.85, 0.6, 0.7)
	line.position = Vector2(G.FIELD_W * 0.2, cy + 9)
	line.size = Vector2(G.FIELD_W * 0.6, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)
	UI.label(root, sub, cy + 15, 12, Color(0.92, 0.88, 1.0))
	_cl.add_child(root)
	root.modulate.a = 0.0
	var tw := root.create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(line, "size:x", G.FIELD_W * 0.6, 0.8).from(0.0)
	tw.tween_interval(1.5)
	tw.tween_property(root, "modulate:a", 0.0, 1.0)
	tw.tween_callback(root.queue_free)

## 屏幕顶部的提示条（成就达成等）
func toast(text: String) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.14, 0.34, 0.95)
	bg.size = Vector2(G.FIELD_W - 20, 20)
	bg.position = Vector2(10, -24)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cl.add_child(bg)
	var l := UI.label(bg, text, 4, 12, Color(1, 0.9, 0.6), 0, G.FIELD_W - 20)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	var y := 24.0 + _toasts * 24.0
	_toasts += 1
	var tw := bg.create_tween()
	tw.tween_property(bg, "position:y", y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_property(bg, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		_toasts = maxi(0, _toasts - 1)
		bg.queue_free())

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
	_cl = cl
	goto("title")
	for tn in ["uitest", "_scrolltest", "_spelltest", "_mobtest", "_bagtest", "_chartest", "_metatest"]:   # 开发用的自动测试脚本
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
		"title", "gallery", "assets", "chars", "codex":
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

func start_run(ch := "reimu", asc_lv := 0) -> void:
	G.clear_run()
	G.new_run(ch, asc_lv)
	G.meta.runs += 1
	G.save_meta()
	goto("map")
	chapter_card(1)

func continue_run() -> void:
	if G.load_run():
		goto(G.resume.screen, G.resume.arg)
	else:
		goto("title")

## 开发者：从第 n 章开头开始，并给一套像样的构筑
func dev_start_chapter(n: int) -> void:
	G.new_run(G.meta.get("dev_char", "reimu"))
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
		if G.chap(c).boss == boss_id or G.chap(c).elites.has(boss_id):
			ch = c
	dev_start_chapter(ch)
	G.run.floor = 8
	G.run.pos = G.run.map.size() - 1
	if true:
		goto("talk", {"boss": boss_id, "kind": "boss" if G.chap(ch).boss == boss_id else "elite"})
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
				goto("talk", {"boss": G.chap(run.chapter).boss})
				return
			elif node.type == "elite":
				var el: Array = G.chap(run.chapter).elites
				goto("talk", {"boss": el[G.rng.randi_range(0, el.size() - 1)], "kind": "elite"})
			else:
				goto("battle", {"kind": node.type})
		_:
			goto(node.type)

func battle_done(info: Dictionary) -> void:
	var run: Dictionary = G.run
	run.battles += 1
	if info.kind == "boss" and run.chapter == 1 and G.unlock_char("marisa"):
		info["unlock"] = "雾雨魔理沙"
	# 第一章的境界碎片：无伤击破精英
	if info.kind == "elite":
		if run.chapter == 1 and not run.sh[0]:
			if info.no_hit and G.give_shard(1):
				info["shard"] = true
			else:
				info["shard_miss"] = true
		if run.chapter == 2 and not run.sh[1]:   # 第二章：打赢 2 场精英
			run["elites_ch"] = run.get("elites_ch", 0) + 1
			if run.elites_ch >= 2 and G.give_shard(2):
				info["shard"] = true
				info["shard_say"] = "紫：「两次都赢了呢。这片碎片，就当是给你的奖赏吧。」"
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
			chapter_card(G.run.chapter)
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
