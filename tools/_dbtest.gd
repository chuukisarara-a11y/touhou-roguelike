extends Node
## 开发用：决死机制自检（--dbtest，可 headless）
var t := 0.0
var step := 0
func _ready() -> void:
	G.new_run()
	G.run.skills = ["db_refund"]
	G.main.goto("battle", {"kind": "battle"})
func _process(dt: float) -> void:
	t += dt
	var b = G.main.screen
	if b == null or not b.has_method("use_bomb"):
		return
	match step:
		0:
			if t > 1.0:
				G.run.bomb = 2.0
				var h0: int = G.run.hearts
				b.player.invuln = 0.0
				b.player_hit()
				print("DB window=", b.db_t, " hearts=", h0)
				step = 1; t = 0.0
		1:
			if t > 0.05:
				b.use_bomb()
				print("DB after bomb: hits=", b.hits, " bomb=", G.run.bomb, " db_t=", b.db_t, " hearts=", G.run.hearts)
				step = 2; t = 0.0
		2:
			if t > 4.5:
				G.run.bomb = 1.0
				b.player.invuln = 0.0
				b.player_hit()
				step = 3; t = 0.0
		3:
			if t > 0.6:
				print("DB no press: hits=", b.hits, " hearts=", G.run.hearts)
				get_tree().quit()
