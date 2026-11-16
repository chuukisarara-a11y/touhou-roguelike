class_name Spells
## 精英 / Boss 的弹幕（v0.9 重做：更密、更华丽，每张符卡一个躲法主题）。
## 形状 0小圆 1大圆 2米粒 3小刀 4星弹 5蝴蝶 6札弹；颜色 0红 1蓝 2绿 3粉 4紫 5青 6白

static func every(e, key: String, iv: float, dt: float) -> bool:
	return Pat.every(e, key, iv, dt)

static func shot(b, pos: Vector2, ang: float, spd: float, shape: int, col: int):
	return b.bullets.add(pos, Vector2.from_angle(ang) * spd, shape, col)

static func ring(b, pos: Vector2, n: int, spd: float, off: float, shape: int, col: int) -> Array:
	var out := []
	for i in n:
		out.append(shot(b, pos, off + TAU * i / n, spd, shape, col))
	return out

static func fan(b, pos: Vector2, base: float, n: int, spread: float, spd: float, shape: int, col: int) -> Array:
	var out := []
	for i in n:
		var a := base if n == 1 else base - spread / 2.0 + spread * i / (n - 1)
		out.append(shot(b, pos, a, spd, shape, col))
	return out

static func aim(b, from: Vector2) -> float:
	return (b.player.position - from).angle()

## 先静止 d 秒再出发
static func hold(bl, d: float) -> void:
	if bl == null:
		return
	bl.hold = bl.vel
	bl.vel = Vector2.ZERO
	bl.delay = d

static func run(e, id: String, dt: float, b) -> void:
	var t: float = e.pt
	var P: Vector2 = e.pos
	match id:
		# ---------------------------------------------------------------- 第一章
		"rumia0":
			if every(e, "a", 0.8, dt):
				ring(b, P, 22, 50.0, t * 0.7, 2, 4)
				ring(b, P, 22, 36.0, -t * 0.7 + 0.14, 2, 1)
			if every(e, "b", 1.5, dt):
				fan(b, P, aim(b, P), 7, 0.9, 80.0, 0, 0)
		"rumia1":  # 夜符「夜雀之歌」：左右交替扫出的弧形米弹，像鸟群展翅
			if every(e, "a", 0.04, dt):
				var ph := fmod(t * 0.8, 1.0)
				var side := 1.0 if int(t * 0.8) % 2 == 0 else -1.0
				var a := PI / 2.0 + side * (1.35 - ph * 2.2)
				var bl = shot(b, P, a, 46.0 + ph * 26.0, 2, 1 if side > 0 else 4)
				bl.w = -side * 0.45
			if every(e, "b", 1.3, dt):
				fan(b, P, aim(b, P), 3, 0.35, 70.0, 1, 0)
		"dai0":
			if every(e, "a", 0.11, dt):
				for k in 6:
					shot(b, P, t * 1.1 + k * TAU / 6.0, 52.0, 2, 2)
			if every(e, "b", 1.1, dt):
				fan(b, P, aim(b, P), 5, 0.5, 82.0, 0, 6)
		"dai1":  # 妖精「绿野之风」：瞬移 → 三层延迟花环；顶部飘落旋转的叶弹
			if every(e, "tp", 2.6, dt):
				b.fx.burst(P, Color(0.5, 1, 0.6), 16, 30.0)
				e.pos = Vector2(randf_range(40, 160), randf_range(45, 95))
				e.target = e.pos
				P = e.pos
				b.fx.burst(P, Color(0.5, 1, 0.6), 16, 30.0)
				var off := randf() * TAU
				for layer in 3:
					for bl in ring(b, P, 20 + layer * 6, 34.0 + layer * 14.0, off + layer * 0.1, 0 if layer < 2 else 4, [2, 6, 2][layer]):
						hold(bl, 0.35 + layer * 0.12)
			if every(e, "leaf", 0.09, dt):
				var bl2 = b.bullets.add(Vector2(randf_range(0, G.FIELD_W), -4), Vector2(randf_range(-20, 20), 52.0), 2, 2)
				bl2.w = randf_range(-0.8, 0.8)
		"cirno1":  # 冰符「冰瀑」：两侧冰柱往外甩出再向中间折回，正前方留一条缝
			if every(e, "a", 0.06, dt):
				for side in [-1.0, 1.0]:
					var bl = b.bullets.add(P + Vector2(side * 8, 0), Vector2(side * randf_range(55, 80), randf_range(-10, 10)), 2, 5)
					bl.acc = Vector2(-side * 22.0, 58.0)
					bl.maxs = 95.0
			if every(e, "b", 1.4, dt):
				fan(b, P, aim(b, P), 5, 0.6, 70.0, 1, 1)
		"cirno2":  # 冻符「完美冻结」：彩色乱弹 → 全部冻成白色 → 缓慢随机散开
			var c := fmod(t, 6.0)
			if c < 2.0:
				if every(e, "a", 0.022, dt):
					shot(b, P, randf() * TAU, randf_range(50, 105), 0 if randf() < 0.75 else 1, randi() % 6).tag = "pf"
			elif c < 3.6:
				if not e.tm.get("frozen", false):
					e.tm["frozen"] = true
					b.shake = 0.15
					b.fx.burst(P, Color(0.9, 1, 1), 30, 120.0)
					for bl in b.bullets.list:
						if bl.tag == "pf":
							bl.vel = Vector2.ZERO
							bl.col = 6
				if c > 2.3 and every(e, "b", 0.4, dt):
					fan(b, P, aim(b, P), 7, 0.8, 92.0, 2, 1)
			elif e.tm.get("frozen", false):
				e.tm["frozen"] = false
				for bl in b.bullets.list:
					if bl.tag == "pf":
						bl.vel = Vector2.from_angle(randf() * TAU) * 6.0
						bl.acc = bl.vel.normalized() * randf_range(20, 45)
						bl.maxs = 60.0
						bl.tag = ""
		"cirno3":  # 雪符「钻石风暴」：Boss 周围随机炸开冰晶；星形雪花环缓缓旋转
			if every(e, "a", 0.04, dt):
				var p: Vector2 = P + Vector2.from_angle(randf() * TAU) * randf_range(0, 32)
				for i in 3:
					shot(b, p, randf() * TAU, randf_range(40, 105), 2 if randf() < 0.6 else 0, 5 if randf() < 0.7 else 6)
			if every(e, "b", 0.85, dt):
				ring(b, P, 14, 44.0, t * 0.6, 4, 5)
		# ---------------------------------------------------------------- 第二章
		"saku0":
			if every(e, "a", 0.5, dt):
				e.tm["z"] = -e.tm.get("z", 1.0)
				fan(b, P, aim(b, P) + 0.12 * e.tm["z"], 5, 0.7, 90.0, 3, 1)
			if every(e, "b", 2.2, dt):
				ring(b, P, 20, 55.0, randf() * TAU, 3, 6)
		"alice1":  # 咒符「上海人偶」：四个人偶绕着爱丽丝转并各自开火，打掉人偶可以减轻火力
			if not e.tm.has("dolls"):
				e.tm["dolls"] = true
				for i in 4:
					b.enemies.spawn("a_doll", {"type": "orbit", "owner": e, "ang": TAU * i / 4.0, "r": 36.0}, b.get_meta("hp_mult"))
			if every(e, "a", 1.3, dt):
				ring(b, P, 20, 46.0, t * 0.7, 0, 1)
				ring(b, P, 20, 34.0, -t * 0.7, 2, 5)
		"alice2":  # 战符「小小军势」：一排排札弹列队行军，缺口像蛇一样左右摆动
			if every(e, "a", 0.75, dt):
				var g: int = clampi(e.tm.get("g", 5) + randi_range(-1, 1), 1, 8)
				e.tm["g"] = g
				e.tm["row"] = e.tm.get("row", 0) + 1
				for i in 11:
					if i == g or i == g + 1:
						continue
					b.bullets.add(Vector2((i + 0.5) / 11.0 * G.FIELD_W, -4), Vector2(0, 44), 6, 1 if int(e.tm["row"]) % 2 == 0 else 5)
			if every(e, "b", 1.6, dt):
				fan(b, P, aim(b, P), 3, 0.4, 84.0, 3, 3)
		"alice3":  # 咒诅「魔彩光的上海人偶」：五个人偶各自射出缓缓转动的彩色激光
			if not e.tm.has("dolls"):
				e.tm["dolls"] = true
				for i in 5:
					b.enemies.spawn("a_doll", {"type": "orbit", "owner": e, "ang": TAU * i / 5.0, "r": 42.0}, b.get_meta("hp_mult"))
			if not e.tm.has("_las"):
				e.tm["_las"] = 1.0
			if every(e, "_las", 4.2, dt):
				var ci := 0
				for en in b.enemies.list:
					if en.owner == e and not en.dead:
						b.bullets.laser(en.pos, (en.pos - P).angle(), 320.0, 4.5, 1.2, 1.8, ci % 7, 0.22, en)
						ci += 1
			if every(e, "a", 0.11, dt):
				shot(b, P, t * 1.9, 52.0, 2, int(t * 3.0) % 6)
				shot(b, P, t * 1.9 + PI, 52.0, 2, int(t * 3.0 + 3) % 6)
		"patb1":  # 火符「火神之光」：五条火焰旋臂
			if every(e, "a", 0.07, dt):
				for k in 5:
					var bl = shot(b, P, t * 1.5 + k * TAU / 5.0, 54.0, 2, 0)
					bl.w = 0.45
			if every(e, "b", 1.7, dt):
				fan(b, P, aim(b, P), 3, 0.3, 78.0, 1, 3)
		"patb3":  # 日符「皇家烈焰」：一圈圈向外加速的烈焰 + 缓慢转动的日冕激光
			if every(e, "a", 0.8, dt):
				e.tm["n"] = e.tm.get("n", 0) + 1
				var n3: int = e.tm["n"]
				for bl in ring(b, P, 26, 14.0, n3 * 0.12, 0 if n3 % 2 == 0 else 1, 0 if n3 % 2 == 0 else 3):
					bl.acc = bl.vel.normalized() * 34.0
					bl.maxs = 74.0
			if not e.tm.has("_c"):
				e.tm["_c"] = 2.0
			if every(e, "_c", 6.5, dt):
				e.tm["lr"] = -e.tm.get("lr", -0.12)
				var off6 := randf() * TAU
				for i in 6:
					b.bullets.laser(P, off6 + i * TAU / 6.0, 420.0, 6.0, 1.5, 2.4, 3, e.tm["lr"], e)
		"mei0":
			if every(e, "a", 0.45, dt):
				e.tm["n"] = e.tm.get("n", 0) + 1
				var n: int = e.tm["n"]
				ring(b, P, 22, 56.0, n * 0.16, 0 if n % 2 == 0 else 2, n % 6)
			if every(e, "b", 1.7, dt):
				fan(b, P, aim(b, P), 3, 0.3, 90.0, 1, 0)
		"mei1":  # 华符「芳华绚烂」：八瓣彩虹风车 + 绽开成小花的大玉
			if every(e, "a", 0.075, dt):
				for k in 6:
					var bl = shot(b, P, t * 1.15 + k * TAU / 6.0, 50.0, 2, k % 6)
					bl.w = 0.32
			if every(e, "b", 1.5, dt):
				for bl in ring(b, P, 8, 55.0, randf() * TAU, 1, 3):
					bl.split = 0.9
					bl.split_n = 7
					bl.split_spread = TAU * 6.0 / 7.0
		"pat0":
			if every(e, "a", 0.85, dt):
				var k2: int = e.tm.get("el", 0)
				e.tm["el"] = (k2 + 1) % 5
				match k2:
					0: fan(b, P, aim(b, P), 11, 1.3, 78.0, 2, 0)
					1: ring(b, P, 12, 36.0, randf() * TAU, 1, 1)
					2: ring(b, P, 34, 55.0, randf() * TAU, 0, 2)
					3: ring(b, P, 16, 60.0, randf() * TAU, 4, 6)
					4: ring(b, P, 24, 46.0, randf() * TAU, 6, 4)
		"pat1":  # 火水符「燃素之雨」：漫天火雨 + 缓缓膨胀上浮的水泡
			if every(e, "a", 0.04, dt):
				var bl = b.bullets.add(Vector2(randf_range(0, G.FIELD_W), -4), Vector2(randf_range(-12, 12), randf_range(55, 95)), 2, 0)
				bl.w = randf_range(-0.2, 0.2)
			if every(e, "b", 1.0, dt):
				for bl in ring(b, P, 18, 12.0, randf() * TAU, 1, 1):
					bl.acc = bl.vel.normalized() * 30.0
					bl.maxs = 52.0
			if every(e, "_c", 5.0, dt):
				# 两道激光从外八字合拢成竖直平行（预警阶段就停稳），保持 1.8 秒后消失
				for s in [-1.0, 1.0]:
					var lz = b.bullets.laser(P + Vector2(s * 36.0, 0), PI / 2.0 - s * 0.6, 420.0, 7.0, 1.4, 1.8, 4, s * 0.6)
					lz.stop_a = PI / 2.0
					lz.has_stop = true
		"saku1":  # 幻象「月神之钟」：正反两圈飞刀旋转 + 停住后瞄准自机的刀环
			if every(e, "a", 0.42, dt):
				ring(b, P, 18, 62.0, t * 0.9, 3, 1)
				ring(b, P, 18, 62.0, -t * 0.9 + 0.17, 3, 5)
			if every(e, "b", 1.9, dt):
				for bl in ring(b, P, 24, 80.0, randf() * TAU, 3, 6):
					bl.tag = "sa"
					bl.go_spread = randf_range(-0.12, 0.12)
		"saku2":  # 幻世「The World」：撒刀 → 真·时间停止 → 布置刀阵 → 时间恢复
			var c2 := fmod(t, 6.6)
			if c2 < 2.2:
				e.tm["placed"] = 0
				if every(e, "a", 0.05, dt):
					shot(b, P, randf() * TAU, randf_range(50, 100), 3, 6).tag = "tw"
			elif not e.tm.get("stopped", false) and c2 < 2.5:
				e.tm["stopped"] = true
				b.timestop = 2.2
				b.banner = "幻世「The World」"
				b.banner_t = 1.2
				Au.sfx("phase")
				for bl in b.bullets.list:
					if bl.tag == "tw":
						bl.vel = Vector2.ZERO
						bl.col = 1
			elif e.tm.get("stopped", false) and b.timestop > 0.0:
				var k3: int = e.tm.get("placed", 0)
				if k3 < 4 and every(e, "ring", 0.4, dt):
					e.tm["placed"] = k3 + 1
					var rad := 44.0 + k3 * 11.0
					var gap := randi() % 10
					var off2 := randf() * TAU
					for i in 10:
						if i == gap or i == (gap + 1) % 10:
							continue
						var a3 := off2 + TAU * i / 10.0
						b.bullets.add(b.player.position + Vector2.from_angle(a3) * rad, Vector2.from_angle(a3 + PI) * 0.01, 3, 5, "tw")
			elif e.tm.get("stopped", false):
				e.tm["stopped"] = false
				for bl in b.bullets.list:
					if bl.tag == "tw":
						bl.vel = (b.player.position - bl.pos).normalized().rotated(randf_range(-0.12, 0.12)) * 62.0 * G.DIFF_SPEED
						bl.tag = ""
		"saku3":  # 幻符「杀人玩偶」：三层刀环同时停住，再一齐射向自机
			if every(e, "a", 1.7, dt):
				var off3 := randf() * TAU
				for layer in 3:
					for bl in ring(b, P, 20, 48.0 + layer * 16.0, off3 + layer * 0.1, 3, [1, 5, 6][layer]):
						bl.tag = "sa"
						bl.go_spread = randf_range(-0.3, 0.3)
			if every(e, "b", 0.6, dt):
				fan(b, P, aim(b, P), 3, 0.25, 95.0, 3, 0)
		# ---------------------------------------------------------------- 第三章
		"tewi0":
			if every(e, "a", 0.45, dt):
				e.tm["z"] = -e.tm.get("z", 1.0)
				fan(b, P, aim(b, P) + 0.3 * e.tm["z"], 3, 0.2, 86.0, 2, 3)
			if every(e, "b", 2.0, dt):
				ring(b, P, 24, 50.0, randf() * TAU, 4, 3)
		"tewi1":  # 兔符「因幡的素兔」：会在墙上反弹的大玉 + 星弹花环
			if every(e, "a", 0.6, dt):
				for bl in ring(b, P, 12, 58.0, t * 0.8, 1, 3):
					bl.bounce = 1
			if every(e, "b", 0.3, dt):
				shot(b, P, aim(b, P), 104.0, 0, 6)
			if every(e, "c", 1.4, dt):
				ring(b, P, 20, 40.0, -t, 4, 6)
		"rei0":
			if every(e, "a", 0.9, dt):
				fan(b, P, aim(b, P), 7, 0.8, 84.0, 2, 0)
			if every(e, "b", 1.8, dt):
				ring(b, P, 32, 48.0, randf() * TAU, 0, 4)
		"rei1":  # 幻波「赤眼催眠」：旋转的红色激光 + 停顿后重新瞄准的幻觉弹环
			if every(e, "las", 4.5, dt):
				var off4 := randf() * TAU
				for i in 4:
					b.bullets.laser(P, off4 + i * TAU / 4.0, 420.0, 7.0, 1.0, 2.6, 0, 0.5, e)
			if every(e, "a", 1.4, dt):
				var n2 := 0
				for bl in ring(b, P, 28, 76.0, t, 0, 4):
					n2 += 1
					bl.col = 0 if n2 % 2 == 0 else 4
					bl.tag = "sa"
					bl.go_spread = randf_range(-0.2, 0.2)
		"kagu1":  # 难题「佛御石之钵」：四道彩色激光缓缓旋转（每轮换方向），激光之间涌出子弹
			if not e.tm.has("_las"):
				e.tm["_las"] = 0.8
			if every(e, "_las", 7.0, dt):
				e.tm["lo"] = randf() * TAU
				e.tm["lt"] = t
				e.tm["lr"] = -e.tm.get("lr", -0.16)
				for i in 4:
					b.bullets.laser(P, e.tm["lo"] + i * TAU / 4.0, 420.0, 6.0, 1.3, 4.2, i * 2 % 7, e.tm["lr"], e)
			if every(e, "a", 0.2, dt):
				var lo: float = e.tm.get("lo", 0.0) + e.tm.get("lr", 0.16) * (t - e.tm.get("lt", t))
				for i in 4:
					shot(b, P, lo + (i + 0.5) * TAU / 4.0 + randf_range(-0.25, 0.25), 50.0, 0, 6)
		"kagu2":  # 难题「火鼠的皮衣」：旋转的火球一边飞一边向两侧洒下火星
			if every(e, "a", 0.4, dt):
				for k in 3:
					var bl = shot(b, P, t * 0.9 + k * TAU / 3.0, 40.0, 1, 0)
					bl.emit = 0.3
			if every(e, "b", 1.6, dt):
				fan(b, P, aim(b, P), 5, 0.5, 86.0, 2, 3)
		"kagu3":  # 难题「蓬莱的玉枝」：七色枝条不断分叉，长成一棵光之树
			if every(e, "a", 0.85, dt):
				for i in 7:
					var a5 := PI / 2.0 + (i - 3) * 0.32
					var bl = shot(b, P, a5, 52.0, 0, i)
					bl.split = 0.55
					bl.split_n = 2
					bl.split_spread = 0.55
					bl.split_depth = 2
			if every(e, "b", 0.16, dt):
				for i in 7:
					shot(b, P, t * 1.4 + i * TAU / 7.0, 45.0, 4, i)
		# ---------------------------------------------------------------- 终章
		"ran0":
			if every(e, "a", 0.7, dt):
				e.tm["z"] = -e.tm.get("z", 1.0)
				ring(b, P, 18, 56.0, t * 0.5 * e.tm["z"], 2, 3)
			if every(e, "b", 1.4, dt):
				fan(b, P, aim(b, P), 5, 0.5, 92.0, 6, 0)
		"ran1":  # 式神「十二神将之宴」：十二个式神绕着蓝旋转，各自向外开火
			if every(e, "a", 0.3, dt):
				for i in 12:
					var a6: float = t * 0.9 + i * TAU / 12.0
					shot(b, P + Vector2.from_angle(a6) * 28.0, a6 + 0.5, 58.0, 6, i % 6)
			if every(e, "b", 1.8, dt):
				ring(b, P, 36, 34.0, randf() * TAU, 0, 6)
		"yuk1":  # 境符「四重结界」：四面八方推来的弹墙，每面墙留一个缺口；中心不断放蝴蝶
			if every(e, "wall", 1.1, dt):
				var side2: int = e.tm.get("side", 0)
				e.tm["side"] = (side2 + 1) % 4
				var gap2 := randi_range(2, 11)
				for i in 14:
					if abs(i - gap2) <= 1:
						continue
					var f := (i + 0.5) / 14.0
					match side2:
						0: b.bullets.add(Vector2(f * G.FIELD_W, -4), Vector2(0, 42), 6, 4)
						1: b.bullets.add(Vector2(-4, f * b.field_h * 0.8), Vector2(42, 0), 6, 1)
						2: b.bullets.add(Vector2(G.FIELD_W + 4, f * b.field_h * 0.8), Vector2(-42, 0), 6, 1)
						3: b.bullets.add(Vector2(f * G.FIELD_W, -4), Vector2(0, 30), 6, 3)
			if every(e, "b", 1.0, dt):
				ring(b, P, 16, 50.0, t * 0.8, 5, 4)
		"yuk2":  # 结界「光与暗的网目」：左右交叉的激光织成网，网眼里飞出蝴蝶
			if every(e, "_las", 3.4, dt):
				# 每轮随机角度和偏移，从屏幕上下全范围织出整张网；网会缓慢平移
				var ang := randf_range(0.42, 0.72)
				var gap := 74.0
				var off := randf() * gap
				var light: bool = e.tm.get("light", true)
				e.tm["light"] = not light
				var drift := randf_range(-0.04, 0.04)
				var y: float = -b.field_h + off
				while y < b.field_h:
					b.bullets.laser(Vector2(-2, y), ang, 700.0, 5.0, 1.2, 1.4, 6 if light else 4, drift)
					b.bullets.laser(Vector2(G.FIELD_W + 2, y + gap * 0.5), PI - ang, 700.0, 5.0, 1.2, 1.4, 4 if light else 6, -drift)
					y += gap
			if every(e, "a", 0.4, dt):
				fan(b, P, aim(b, P) + randf_range(-0.3, 0.3), 3, 0.5, 66.0, 5, 4 if randf() < 0.5 else 1)
		"yuk3":  # 「弹幕结界」：围绕自机出现的弹环向内收拢（留缺口）；紫的双螺旋蝴蝶
			if every(e, "a", 2.2, dt):
				var pp: Vector2 = b.player.position
				var gap3 := randi() % 32
				var off5 := randf() * TAU
				for i in 32:
					if abs(i - gap3) <= 1 or abs(i - gap3) >= 31:
						continue
					var a7 := off5 + TAU * i / 32.0
					var bl = b.bullets.add(pp + Vector2.from_angle(a7) * 130.0, Vector2.from_angle(a7 + PI) * 42.0, 0, 4 if i % 2 == 0 else 1)
					hold(bl, 0.5)
			if every(e, "b", 0.1, dt):
				shot(b, P, t * 2.0, 58.0, 5, 4)
				shot(b, P, -t * 2.0 + PI, 58.0, 5, 3)
