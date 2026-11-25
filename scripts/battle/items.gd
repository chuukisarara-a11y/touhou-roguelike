class_name ItemLayer
extends Node2D
## 掉落物：钱、心、灵点、P 点。靠近自动吸附；自机在「收取线」以上时全屏吸取；战斗胜利时全部吸过来。

var list := []   # [pos, vel, kind, age, 被吸取的时间（-1 = 还没被吸）]
var magnet_all := false
var poc_y := 9999.0     # 收取线的高度
var poc_on := false
var poc_flash := 0.0

func drop_coins(pos: Vector2, n: int) -> void:
	for i in n:
		list.append([pos, Vector2(randf_range(-40, 40), randf_range(-70, -20)), "coin", 0.0, -1.0])

func drop_power(pos: Vector2, n: int) -> void:
	for i in n:
		list.append([pos, Vector2(randf_range(-30, 30), randf_range(-80, -40)), "power", 0.0, -1.0])

func drop_heart(pos: Vector2) -> void:
	list.append([pos, Vector2(0, -40), "heart", 0.0, -1.0])

## 被消掉的敌弹变成灵点，一小会儿后自动飞向自机
func drop_points(pts: Array) -> void:
	var step := maxi(1, pts.size() / 160)
	for i in range(0, pts.size(), step):
		list.append([pts[i], Vector2(randf_range(-25, 25), randf_range(-40, -10)), "point", 0.0, -1.0])

func tick(dt: float, battle) -> void:
	var pp: Vector2 = battle.player.position
	var h: float = battle.field_h
	poc_y = h * (0.45 if G.has("m_collect") else 0.25)
	var poc: bool = pp.y < poc_y
	poc_on = poc
	poc_flash = 1.0 if poc else maxf(0.0, poc_flash - dt * 2.0)
	for it in list:
		it[3] += dt
		var d: float = it[0].distance_to(pp)
		# 一旦开始被吸（灵点、收取线、靠近、战斗结束），就锁定为被吸取：之后走远也照样追过来，越飞越快
		if it[4] < 0.0 and ((it[2] == "point" and it[3] > 0.3) or magnet_all or poc or d < (85.0 if G.has("magnet") else 34.0)):
			it[4] = 0.0
		if it[4] >= 0.0:
			it[4] += dt
			it[0] = it[0].move_toward(pp, (230.0 + it[4] * 560.0) * dt)
			if it[0].distance_to(pp) < 7.0:
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
		elif it[2] == "got_power":
			battle.on_power()
		elif it[2] == "got_point":
			battle.on_point()
		elif it[2] == "got_heart":
			G.heal(1)
			Au.sfx("heal")
			battle.fx.text(pp + Vector2(0, -14), "+1 心", Color(1, 0.5, 0.6))
	list = list.filter(func(it): return it[2] == "coin" or it[2] == "heart" or it[2] == "point" or it[2] == "power")
	queue_redraw()

func _draw() -> void:
	var c := G.tex("coin")
	var hrt := G.tex("heart")
	var pt := G.tex("point")
	var pw := G.tex("power")
	# 收取线：淡淡的虚线；自机在线上方时变亮
	var la := 0.16 + 0.4 * poc_flash
	var x := 0.0
	while x < G.FIELD_W:
		draw_line(Vector2(x, poc_y), Vector2(x + 5.0, poc_y), Color(0.75, 0.9, 1.0, la), 1.0)
		x += 10.0
	for it in list:
		var t: Texture2D = c if it[2] == "coin" else (hrt if it[2] == "heart" else (pw if it[2] == "power" else pt))
		draw_texture(t, (it[0] - t.get_size() / 2.0))
