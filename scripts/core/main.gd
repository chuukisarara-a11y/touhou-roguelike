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

func goto(name: String, arg := {}) -> void:
	if screen != null:
		screen.queue_free()
	screen = Node2D.new()
	screen.set_script(load(SCREENS[name]))
	screen_name = name
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
		"title":
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
	G.new_run()
	goto("map")

func enter_node(i: int) -> void:
	var run: Dictionary = G.run
	run.pos = i
	var node: Dictionary = run.map[i]
	run.floor = node.f + 1
	match node.type:
		"battle", "elite", "boss":
			if node.type == "battle" and run.chapter_first and G.has("bouyu"):
				run.chapter_first = false
				run.money += 25
				battle_done({"kind": "battle", "no_hit": false, "earned": 25, "skipped": true})
			elif node.type == "boss":
				goto("talk", {"boss": Db.CHAPTERS[run.chapter].boss})
			else:
				goto("battle", {"kind": node.type})
		_:
			goto(node.type)

func battle_done(info: Dictionary) -> void:
	var run: Dictionary = G.run
	run.battles += 1
	if info.kind == "elite" and run.chapter <= 3 and run.shard_ch < run.chapter:
		run.shard_ch = run.chapter
		run.shards += 1
		info["shard"] = true
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
