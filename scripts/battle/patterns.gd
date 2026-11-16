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
		iv /= G.DIFF_RATE
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

## Boss / 精英的符卡
static func boss(e, id: String, dt: float, b) -> void:
	var t: float = e.pt
	match id:
		"rumia0":
			if every(e, "a", 1.5, dt):
				aimed(b, e.pos, 5, 50, 75.0, 0, 0)
			if every(e, "b", 2.6, dt):
				ring(b, e.pos, 12, 50.0, randf() * TAU, 0, 1)
		"rumia1":
			if every(e, "a", 0.14, dt):
				var a := t * 2.2
				b.bullets.add(e.pos, Vector2.from_angle(a) * 62.0, 2, 1)
				b.bullets.add(e.pos, Vector2.from_angle(a + PI) * 62.0, 2, 4)
			if every(e, "b", 2.2, dt):
				aimed(b, e.pos, 3, 30, 90.0, 1, 0)
		"dai0":
			if every(e, "a", 1.1, dt):
				aimed(b, e.pos, 3, 28, 85.0, 2, 2)
			if every(e, "b", 3.0, dt):
				ring(b, e.pos, 16, 48.0, randf() * TAU, 0, 2)
		"dai1":
			if every(e, "a", 2.6, dt):
				b.fx.burst(e.pos, Color(0.5, 1, 0.6))
				e.pos = Vector2(randf_range(40, 160), randf_range(45, 95))
				e.target = e.pos
				b.fx.burst(e.pos, Color(0.5, 1, 0.6))
				ring(b, e.pos, 18, 58.0, randf() * TAU, 0, 2)
			if every(e, "b", 0.55, dt):
				aimed(b, e.pos, 1, 0, 95.0, 2, 3)
		"cirno1":  # 冰瀑：左右两侧扫动的冰柱 + 自机狙
			if every(e, "a", 0.3, dt):
				var sw := 0.55 + 0.45 * sin(t * 1.3)
				for side in [-1.0, 1.0]:
					var a2: float = PI / 2.0 + side * sw
					for sp in [55.0, 72.0, 90.0]:
						b.bullets.add(e.pos + Vector2(side * 26, 0), Vector2.from_angle(a2) * sp, 2, 5)
			if every(e, "b", 1.9, dt):
				aimed(b, e.pos, 5, 44, 78.0, 0, 3)
		"cirno2":  # 完美冻结：乱弹 → 冻结 → 缓慢散开
			var c := fmod(t, 6.0)
			if c < 2.0:
				if every(e, "a", 0.05, dt):
					b.bullets.add(e.pos, Vector2.from_angle(randf() * TAU) * randf_range(55, 105), 0, randi() % 5, "pf")
			elif c < 3.8:
				if not e.tm.get("frozen", false):
					e.tm["frozen"] = true
					for bl in b.bullets.list:
						if bl.tag == "pf":
							bl.vel = Vector2.ZERO
							bl.col = 6
				if c > 2.4 and every(e, "b", 0.45, dt):
					aimed(b, e.pos, 5, 50, 95.0, 2, 1)
			else:
				if e.tm.get("frozen", false):
					e.tm["frozen"] = false
					for bl in b.bullets.list:
						if bl.tag == "pf":
							bl.vel = Vector2.from_angle(randf() * TAU) * randf_range(22, 48)
							bl.tag = ""
		"cirno3":  # 钻石风暴：旋转环 + 飘落的冰粒
			if every(e, "a", 0.62, dt):
				ring(b, e.pos, 13, 58.0, t * 0.7, 0, 5)
			if every(e, "b", 0.2, dt):
				var p: Vector2 = e.pos + Vector2(randf_range(-45, 45), randf_range(-6, 6))
				b.bullets.add(p, Vector2.from_angle(PI / 2.0 + randf_range(-0.5, 0.5)) * randf_range(45, 85), 2, 6)
