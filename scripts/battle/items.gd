class_name ItemLayer
extends Node2D
## 掉落物：钱和心。靠近自动吸附，战斗胜利时全部吸过来。

var list := []   # [pos, vel, kind]
var magnet_all := false

func drop_coins(pos: Vector2, n: int) -> void:
	for i in n:
		list.append([pos, Vector2(randf_range(-40, 40), randf_range(-70, -20)), "coin"])

func drop_heart(pos: Vector2) -> void:
	list.append([pos, Vector2(0, -40), "heart"])

func tick(dt: float, battle) -> void:
	var pp: Vector2 = battle.player.position
	var h: float = battle.field_h
	for it in list:
		var d: float = it[0].distance_to(pp)
		if magnet_all or d < 34.0:
			it[0] = it[0].move_toward(pp, 260.0 * dt)
			if d < 7.0:
				it[2] = "got_" + it[2]
		else:
			it[1].y = minf(it[1].y + 120.0 * dt, 45.0)
			it[1].x = move_toward(it[1].x, 0.0, 60.0 * dt)
			it[0] += it[1] * dt
			if it[0].y > h + 8:
				it[2] = "lost"
		if it[2] == "got_coin":
			var v := 2 if (G.has("saisen") and randf() < 0.25) else 1
			G.run.money += v
			battle.earned += v
		elif it[2] == "got_heart":
			G.heal(1)
			battle.fx.text(pp + Vector2(0, -14), "+1 心", Color(1, 0.5, 0.6))
	list = list.filter(func(it): return it[2] == "coin" or it[2] == "heart")
	queue_redraw()

func _draw() -> void:
	var c := G.tex("coin")
	var hrt := G.tex("heart")
	for it in list:
		var t: Texture2D = c if it[2] == "coin" else hrt
		draw_texture(t, (it[0] - t.get_size() / 2.0).round())
