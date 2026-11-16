extends Node
## 开发用：魔理沙线的界面与符卡截图（--chartest）
var t := 0.0
var step := 0
var steps := []
func snap(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/ch_%s.png" % n)
func _ready() -> void:
	G.dev_god = true
	G.meta.chars["marisa"] = true
	G.meta["dev_char"] = "marisa"
	steps = [
		[0.5, func(): G.main.goto("chars")],
		[0.9, func(): snap("1chars"); G.main.dev_start_chapter(1)],
		[0.9, func(): snap("2map"); G.run.weapons.append({"id": "doll", "lv": 1, "cd": 0.0}); G.main.goto("talk", {"boss": "alice", "kind": "boss"})],
		[0.9, func(): snap("3talk"); G.main.goto("battle", {"kind": "boss", "boss": "alice"})],
		[5.0, func(): snap("4alice"); G.run.bomb = 2.0; G.main.screen.use_bomb()],
		[1.2, func(): snap("5spark"); G.main.goto("event")],
		[1.0, func(): snap("6event"); get_tree().quit()],
	]
func _process(dt: float) -> void:
	t += dt
	if step < steps.size() and t >= steps[step][0]:
		t = 0.0
		steps[step][1].call()
		step += 1
