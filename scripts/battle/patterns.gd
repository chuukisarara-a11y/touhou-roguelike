class_name Pat
## 弹幕模式库。颜色: 0红 1蓝 2绿 3黄 4紫 5青 6白；形状: 0小圆 1大圆 2米粒

static func aimed(b, pos: Vector2, n: int, spread_deg: float, speed: float, shape := 0, col := 0) -> void:
	var base: float = (b.player.position - pos).angle()
	fan(b, pos, base, n, spread_deg, speed, shape, col)

static func fan(b, pos: Vector2, base: float, n: int, spread_deg: float, speed: float, shape := 0, col := 0) -> void:
	var spread := deg_to_rad(spread_deg)
	for i in n:
		var a := base if n == 1 else base - spread / 2.0 + spread * i / (n - 1)
		b.bullets.add(pos, Vector2.from_angle(a) * speed, shape, col)

static func ring(b, pos: Vector2, n: int, speed: float, offset := 0.0, shape := 0, col := 0) -> void:
	for i in n:
		b.bullets.add(pos, Vector2.from_angle(offset + TAU * i / n) * speed, shape, col)

static func every(e, key: String, iv: float, dt: float) -> bool:
	if not key.begins_with("_"):
		iv /= G.DIFF_RATE * G.asc_rate()
	var v: float = e.tm.get(key, iv * 0.6) - dt
	if v <= 0.0:
		e.tm[key] = v + iv
		return true
	e.tm[key] = v
	return false

## 杂鱼的攻击
static func enemy_attack(e, b) -> void:
	match e.def.atk:
		"aim1":
			aimed(b, e.pos, 1, 0, 80.0, 0, 1)
		"fan3":
			aimed(b, e.pos, 3, 36, 70.0, 2, 0)
		"ring":
			ring(b, e.pos, 10, 55.0, randf() * TAU, 0, 3)
		"burst3":
			for sp in [66.0, 80.0, 94.0]:
				aimed(b, e.pos, 1, 0, sp, 2, 1)
		"mine":   # 撒下会停住的滞留弹
			for i in 3:
				var bl = b.bullets.add(e.pos, Vector2.from_angle(randf() * TAU) * randf_range(22, 40), 1, 4)
				bl.drag = 1.6
				bl.life = 6.0
		"snipe":  # 先显示瞄准线，再射出细激光
			b.bullets.laser(e.pos, (b.player.position - e.pos).angle(), 420.0, 3.5, 0.9, 0.25, 0, 0.0, e)
		"ring8":
			ring(b, e.pos, 8, 58.0, randf() * TAU, 0, 4)
		"spiral":
			for k in 3:
				b.bullets.add(e.pos, Vector2.from_angle(e.t * 1.9 + k * TAU / 3.0) * 60.0, 0, 0)
		"fan5":
			aimed(b, e.pos, 5, 64, 76.0, 2, 3)
		"cross":
			ring(b, e.pos, 4, 66.0, e.t * 0.9, 0, 2)
		"slowbig":
			aimed(b, e.pos, 1, 0, 46.0, 1, 5)
		"ringaim":
			ring(b, e.pos, 14, 50.0, randf() * TAU, 0, 6)
			aimed(b, e.pos, 3, 30, 84.0, 2, 1)

## Boss / 精英的符卡（具体写在 spells.gd）
static func boss(e, id: String, dt: float, b) -> void:
	Spells.run(e, id, dt, b)
