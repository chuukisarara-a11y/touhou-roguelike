class_name ItemLayer
extends Node2D
## 掉落物：钱和心。靠近自动吸附，战斗胜利时全部吸过来。

var list := []   # [pos, vel, kind, age]
var magnet_all := false

func drop_coins(pos: Vector2, n: int) -> void:
	for i in n:
		list.append([pos, Vector2(randf_range(-40, 40), randf_range(-70, -20)), "coin", 0.0])

func drop_heart(pos: Vector2) -> void:
	list.append([pos, Vector2(0, -40), "heart", 0.0])

## 被消掉的敌弹变成灵点，一小会儿后自动飞向自机
func drop_points(pts: Array) -> void:
	var step := maxi(1, pts.size() / 160)
	for i in range(0, pts.size(), step):
		list.append([pts[i], Vector2(randf_range(-25, 25), randf_range(-40, -10)), "point", 0.0])

func tick(dt: float, battle) -> void:
	var pp: Vector2 = battle.player.position
	var h: float = battle.field_h
	var poc: bool = G.has("m_collect") and pp.y < h * 0.45
	for it in list:
		it[3] += dt
		var d: float = it[0].distance_to(pp)
		if it[2] == "point" and it[3] > 0.3:
			it[0] = it[0].move_toward(pp, (260.0 + it[3] * 300.0) * dt)
			if d < 7.0:
				it[2] = "got_point"
		elif magnet_all or poc or d < (85.0 if G.has("magnet") else 34.0):
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
			var v := (2 if (G.has("saisen") and randf() < 0.25) else 1) * (2 if G.has("greed") else 1)
			G.run.money += v
			Au.sfx("coin", -4.0)
			battle.earned += v
		elif it[2] == "got_point":
			battle.on_point()
		elif it[2] == "got_heart":
			G.heal(1)
			Au.sfx("heal")
			battle.fx.text(pp + Vector2(0, -14), "+1 心", Color(1, 0.5, 0.6))
	list = list.filter(func(it): return it[2] == "coin" or it[2] == "heart" or it[2] == "point")
	queue_redraw()

func _draw() -> void:
	var c := G.tex("coin")
	var hrt := G.tex("heart")
	var pt := G.tex("point")
	for it in list:
		var t: Texture2D = c if it[2] == "coin" else (hrt if it[2] == "heart" else pt)
		draw_texture(t, (it[0] - t.get_size() / 2.0))
