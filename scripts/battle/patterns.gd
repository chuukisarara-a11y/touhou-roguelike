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
		"burst3":
			for sp in [66.0, 80.0, 94.0]:
				aimed(b, e.pos, 1, 0, sp, 2, 1)
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
		"mei0":
			if every(e, "a", 1.0, dt):
				e.tm["n"] = e.tm.get("n", 0) + 1
				ring(b, e.pos, 14, 60.0, e.tm["n"] * 0.22, 0, int(e.tm["n"]) % 6)
			if every(e, "b", 2.6, dt):
				aimed(b, e.pos, 3, 26, 92.0, 1, 0)
		"mei1":  # 五瓣旋转的花
			if every(e, "a", 0.13, dt):
				e.tm["n"] = e.tm.get("n", 0) + 1
				for k in 5:
					b.bullets.add(e.pos, Vector2.from_angle(t * 1.5 + k * TAU / 5.0) * 62.0, 2, (int(e.tm["n"]) / 4 + k) % 6)
			if every(e, "b", 2.6, dt):
				aimed(b, e.pos, 3, 30, 90.0, 1, 3)
		"pat0":
			if every(e, "a", 1.4, dt):
				aimed(b, e.pos, 7, 70, 82.0, 0, 0)
			if every(e, "b", 2.2, dt):
				ring(b, e.pos, 12, 44.0, randf() * TAU, 1, 1)
		"pat1":  # 火雨 + 水环
			if every(e, "a", 0.17, dt):
				b.bullets.add(Vector2(randf_range(6, G.FIELD_W - 6), -4), Vector2.from_angle(PI / 2.0 + randf_range(-0.25, 0.25)) * randf_range(55, 92), 2, 0)
			if every(e, "b", 1.9, dt):
				ring(b, e.pos, 18, 52.0, randf() * TAU, 0, 1)
		"tewi0":
			if every(e, "a", 0.5, dt):
				e.tm["z"] = -e.tm.get("z", 1.0)
				fan(b, e.pos, (b.player.position - e.pos).angle() + 0.28 * e.tm["z"], 2, 10, 88.0, 2, 2)
			if every(e, "b", 2.6, dt):
				ring(b, e.pos, 12, 54.0, randf() * TAU, 0, 3)
		"tewi1":
			if every(e, "a", 0.75, dt):
				ring(b, e.pos, 10, 60.0, t * 1.1, 2, 3)
			if every(e, "b", 0.28, dt):
				aimed(b, e.pos, 1, 0, 108.0, 0, 6)
		"rei0":
			if every(e, "a", 1.2, dt):
				aimed(b, e.pos, 5, 56, 88.0, 2, 0)
			if every(e, "b", 2.3, dt):
				ring(b, e.pos, 14, 52.0, randf() * TAU, 0, 4)
		"rei1":  # 停顿后重新瞄准的幻觉弹
			if every(e, "a", 1.7, dt):
				for i in 18:
					b.bullets.add(e.pos, Vector2.from_angle(TAU * i / 18.0 + t) * 78.0, 0, 4, "sa")
			if every(e, "b", 0.9, dt):
				aimed(b, e.pos, 3, 34, 92.0, 2, 0)
		"saku1":
			if every(e, "a", 0.62, dt):
				e.tm["z"] = -e.tm.get("z", 1.0)
				fan(b, e.pos, (b.player.position - e.pos).angle() + 0.1 * e.tm["z"], 7, 78, 96.0, 2, 1)
			if every(e, "b", 2.3, dt):
				ring(b, e.pos, 16, 54.0, randf() * TAU, 0, 6)
		"saku2":  # The World：飞刀撒满全场 → 时间停止 → 一齐射向自机
			var c2 := fmod(t, 5.2)
			if c2 < 2.0:
				e.tm["stopped"] = false
				if every(e, "a", 0.07, dt):
					b.bullets.add(e.pos, Vector2.from_angle(randf() * TAU) * randf_range(50, 100), 2, 6, "tw")
			elif c2 < 3.0:
				if not e.tm.get("stopped", false):
					e.tm["stopped"] = true
					Au.sfx("phase", -4.0)
					for bl in b.bullets.list:
						if bl.tag == "tw":
							bl.vel = Vector2.ZERO
							bl.col = 1
				if every(e, "b", 0.34, dt):
					aimed(b, e.pos, 3, 30, 100.0, 0, 0)
			elif e.tm.get("stopped", false):
				e.tm["stopped"] = false
				for bl in b.bullets.list:
					if bl.tag == "tw":
						bl.vel = ((b.player.position - bl.pos).normalized().rotated(randf_range(-0.35, 0.35))) * randf_range(60, 84) * G.DIFF_SPEED
						bl.tag = ""
		"saku3":
			if every(e, "a", 1.15, dt):
				for i in 16:
					b.bullets.add(e.pos, Vector2.from_angle(TAU * i / 16.0 + t * 0.5) * 84.0, 2, 1, "sa")
			if every(e, "b", 2.4, dt):
				aimed(b, e.pos, 5, 60, 70.0, 1, 0)
		"kagu1":
			if every(e, "a", 0.55, dt):
				e.tm["n"] = e.tm.get("n", 0) + 1
				ring(b, e.pos, 16, 60.0, t * 0.6 * (1.0 if int(e.tm["n"]) % 2 == 0 else -1.0), 0, int(e.tm["n"]) % 6)
			if every(e, "b", 1.8, dt):
				aimed(b, e.pos, 5, 40, 104.0, 2, 6)
		"kagu2":
			if every(e, "a", 0.1, dt):
				b.bullets.add(e.pos, Vector2.from_angle(t * 2.6) * 68.0, 2, 0)
				b.bullets.add(e.pos, Vector2.from_angle(-t * 2.6 + PI) * 68.0, 2, 3)
			if every(e, "b", 2.1, dt):
				ring(b, e.pos, 10, 40.0, randf() * TAU, 1, 0)
		"kagu3":  # 七色玉枝：七个发射点左右摆动
			if every(e, "a", 0.24, dt):
				for i in 7:
					var px: float = 20.0 + i * (G.FIELD_W - 40.0) / 6.0
					b.bullets.add(Vector2(px, e.pos.y - 6), Vector2.from_angle(PI / 2.0 + sin(t * 1.4 + i * 0.9) * 0.55) * 64.0, 0, i % 7)
			if every(e, "b", 2.7, dt):
				aimed(b, e.pos, 7, 70, 80.0, 2, 4)
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
