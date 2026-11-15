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
}

var screen: Node
var screen_name := ""

func _ready() -> void:
	G.main = self
	UI.install_theme(get_tree().root)
	if G.bot:
		add_child(load("res://scripts/core/autotest.gd").new())
	goto("title")

func goto(name: String, arg := {}) -> void:
	if screen != null:
		screen.queue_free()
	screen = Node2D.new()
	screen.set_script(load(SCREENS[name]))
	screen_name = name
	if screen.has_method("setup"):
		screen.setup(arg)
	add_child(screen)

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
			else:
				goto("battle", {"kind": node.type})
		_:
			goto(node.type)

func battle_done(info: Dictionary) -> void:
	var run: Dictionary = G.run
	run.battles += 1
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
		goto("result", {"win": true})
	else:
		goto("map")

func game_over() -> void:
	goto("result", {"win": false})
