class_name Weapons
## 符札（攻符）的发射逻辑。fire() 发射一次并返回冷却时间（秒）。
## fire_at() 可以指定发射位置和伤害倍率（使魔·复制用）。
## 阴阳玉系、星屑系的彗星尾、御柱系的横扫/注连绳由 FamSys 每帧处理，这里只返回一个冷却。

static func fire(w: Dictionary, p: Player, b) -> float:
	return fire_at(w, p, b, p.position, 1.0)

static func fire_at(w: Dictionary, p: Player, b, pos: Vector2, mk: float) -> float:
	var mods: Array = w.get("mods", [])
	b.shots.ctx = mods
	var cd := _fire(w, p, b, pos, mk)
	b.shots.ctx = []
	if mods.has("rapid"):
		cd /= 1.35
	if mods.has("heavy"):
		cd *= 1.25
	if G.has("sniper"):
		cd *= 2.0
	return cd

static func _fire(w: Dictionary, p: Player, b, pos: Vector2, mk: float) -> float:
	var s: ShotLayer = b.shots
	var mods: Array = w.get("mods", [])
	var m: float = mk * G.dmg_mult() * (1.6 if w.get("awake", false) else 1.0) * (0.85 if mods.has("rapid") else 1.0) * (1.45 if mods.has("heavy") else 1.0)
	var lv: int = w.lv
	var br: int = w.get("br", -1) if lv >= 3 else -1
	var fam: String = Db.WEAPONS[w.id].get("fam", "")
	if fam == "needle":   # 集中：每层 +12%
		m *= 1.0 + 0.12 * b.fams.nd_stack
	elif fam == "laser":   # 过热
		m *= b.fams.heat_mult()
	elif fam == "pillar" and G.has("pl_yasaka"):
		m *= 1.4
	var track := 1.3 if G.tag_count("追踪") >= 2 else 1.0
	var line := 1.25 if G.has_tags("直线", "穿透") else 1.0
	# 符札系：擦弹连击越高，每轮多射出符札（每 20 连击 +1，最多 +3；连击护符再 +3）
	var am_extra := mini(G.combo / 20, 6 if G.has("am_combo") else 3) if fam == "amulet" else 0
	match w.id:
		"amulet":
			var n := ((2 if lv < 2 else 4) + am_extra) * (2 if G.has("oozora") else 1)
			var d := 4.0 * m * track * (1.6 if br == 0 else 1.0)
			for i in n:
				var side := (i % 2) * 2 - 1
				var k := i / 2
				s.spawn("amulet", pos + Vector2(side * (6 + 4 * k), -3), Vector2(side * (30.0 + 14.0 * k), -190.0), d, {"homing": 13.0 if br == 0 else 9.0, "rot": true, "chain": 1 if br == 1 else 0})
			return 0.22
		"amulet_fan":
			var n1 := (5 if lv < 2 else 7) + am_extra
			var spread := 0.9 + 0.08 * am_extra
			for i in n1:
				var a := -PI / 2.0 - spread / 2.0 + spread * i / (n1 - 1)
				s.spawn("amulet", pos + Vector2(0, -4), Vector2.from_angle(a) * 240.0, 3.4 * m, {"rot": true, "near_bonus": true, "pierce": 1 if br == 1 else 0, "life": 1.4})
			return 0.34
		"amulet_seal":
			var d0 := 14.0 * m * (1.4 if lv >= 2 else 1.0)
			s.spawn("amulet", pos + Vector2(0, -6), Vector2(0, -130.0), d0, {"rot": true, "big": true, "radius": 7.0, "stun": 1.0 + (0.6 if lv >= 2 else 0.0), "seal": br == 0, "clear_r": 32.0 if br == 1 else 0.0})
			return 0.9
		"needle":
			var n2 := 1 if lv < 2 else 2
			for i in n2:
				var off := 0.0 if n2 == 1 else (i * 2 - 1) * 3.0
				var sh := s.spawn("needle", pos + Vector2(off, -10), Vector2(0, -360.0), 5.0 * m * line, {"pierce": 3 if br == 0 else 0})
				if br == 1:
					sh.split_mod = true
			return 0.12
		"needle_wide":
			var n2b := 2 if br == 0 else 1
			for i in n2b:
				var off2 := 0.0 if n2b == 1 else (i * 2 - 1) * 5.0
				s.spawn("needle", pos + Vector2(off2, -10), Vector2(0, -300.0), 9.0 * m * line * (1.5 if lv >= 2 else 1.0), {"pierce": 99, "radius": 5.0, "big": true, "pen": br == 1})
			return 0.45
		"needle_side":
			var angs := [0.5] if lv < 2 else [0.4, 0.7]
			for a0 in angs:
				for side in [-1.0, 1.0]:
					s.spawn("needle", pos + Vector2(side * 4, -6), Vector2.from_angle(-PI / 2.0 + side * a0) * 330.0, 4.0 * m, {"rot": true, "homing": 2.5 if br == 0 else 0.0})
			return 0.16 / (1.5 if br == 1 else 1.0)
		"star":
			var n3 := 3 if lv < 2 else 5
			var spread3 := 0.5 if lv < 2 else 0.8
			for i in n3:
				var a3 := -PI / 2.0 - spread3 / 2.0 + spread3 * i / (n3 - 1)
				s.spawn("star", pos + Vector2(0, -6), Vector2.from_angle(a3) * 230.0, 5.0 * m * (1.4 if br == 1 else 1.0), {"big": br == 1})
			return 0.21 if br == 0 else 0.3
		"starmap", "star_tail", "yinyang", "yinyang_big", "yinyang_meteor", "pillar_side", "shimenawa":
			return 0.5   # 由 FamSys 处理
		"laser":
			var lw := 4.0 if lv < 2 else 8.0
			var d2 := 3.4 * m * line * (1.4 if lv >= 2 else 1.0) * (1.6 if br == 0 else 1.0)
			var offs := [-7.0, 7.0] if G.run.char == "marisa" else [0.0]   # 魔理沙是两道
			for o in offs:
				b.fams.beam(pos + Vector2(o, -10), -PI / 2.0, lw, d2)
			if br == 1:   # 棱镜：两侧细激光
				for o2 in [-16.0, 16.0]:
					b.fams.beam(pos + Vector2(o2, -6), -PI / 2.0, 2.0, d2 * 0.5, Color(1, 0.85, 1.0))
			return 0.1
		"laser_diag":
			var dd := 2.4 * m * (1.4 if lv >= 2 else 1.0) * (1.5 if br == 1 else 1.0)
			var wd := 5.0 if br == 1 else 3.0
			for side2 in [-1.0, 1.0]:
				b.fams.beam(pos + Vector2(side2 * 5, -8), -PI / 2.0 + side2 * deg_to_rad(30.0), wd, dd)
			if br == 0:
				b.fams.beam(pos + Vector2(0, -10), -PI / 2.0, wd, dd)
			return 0.1
		"laser_sweep":
			var spd := 3.2 if lv >= 2 else 2.2
			var sw := sin(b.fams.t * spd) * deg_to_rad(40.0)
			var ds := 3.0 * m * (1.4 if lv >= 2 else 1.0) * (1.5 if br == 1 else 1.0)
			var ws := 7.0 if br == 1 else 4.0
			b.fams.beam(pos + Vector2(0, -10), -PI / 2.0 + sw, ws, ds)
			if br == 0:
				b.fams.beam(pos + Vector2(0, -10), -PI / 2.0 - sw, ws, ds)
			return 0.1
		"knife":
			var n4 := 2 if lv < 2 else 4
			for i in n4:
				var side3 := (i % 2) * 2 - 1
				var a4 := -PI / 2.0 + side3 * (0.42 + 0.4 * (i / 2))
				s.spawn("knife", pos + Vector2(side3 * 4, -4), Vector2.from_angle(a4) * 250.0, 6.0 * m * (1.3 if lv >= 3 else 1.0), {"bounce": 2 if lv < 3 else 4, "rot": true, "life": 4.0})
			return 0.32
		"bat":
			var n5 := (1 if lv < 2 else 2) * (2 if G.has("oozora") else 1)
			for i in n5:
				var a5 := -PI / 2.0 + randf_range(-0.9, 0.9)
				s.spawn("bat", pos + Vector2(0, -4), Vector2.from_angle(a5) * 150.0, 6.0 * m * track, {"homing": 7.0, "charge": 0.004 if lv < 3 else 0.008})
			return 0.3
		"fire":
			var n6 := 1 if lv < 2 else 2
			for i in n6:
				var a6 := -PI / 2.0 + randf_range(-0.12, 0.12) + (0.0 if n6 == 1 else (i * 2 - 1) * 0.12)
				s.spawn("fire", pos + Vector2(0, -6), Vector2.from_angle(a6) * 210.0, 3.0 * m, {"burn": (8.0 if lv < 3 else 16.0) * m})
			return 0.35
		"ice":
			var n7 := 1 if lv < 2 else 2
			for i in n7:
				var off3 := 0.0 if n7 == 1 else (i * 2 - 1) * 5.0
				s.spawn("ice", pos + Vector2(off3, -6), Vector2(off3 * 3.0, -220.0), 5.0 * m, {"slow": 2.0, "ice_mark": lv >= 3})
			return 0.3
		"familiar":
			return 0.5   # 使魔由 FamSys 处理
		"doll":
			for dp in p.dolls:
				var target = s.nearest(dp, b.enemies.list)
				var dir := Vector2.UP
				if target != null:
					dir = (target.pos - dp).normalized()
				s.spawn("needle", dp, dir * 280.0, 4.0 * m, {"pierce": 2 if br == 1 else 0, "rot": true})
			if br == 0:   # 冲锋：每 4 秒一次大伤害
				w["dash"] = w.get("dash", 0) + 1
				if w.dash >= int(4.0 / (0.45 if lv < 2 else 0.3)):
					w.dash = 0
					var tg = s.nearest(pos, b.enemies.list)
					if tg != null:
						tg.hurt(40.0 * m, b)
						b.fx.burst(tg.pos, Color(1, 0.8, 0.9), 14, 26.0)
						for dp2 in p.dolls:
							b.player.beams.append([dp2, (tg.pos - dp2).angle(), 2.0, 0.15, Color(1, 0.8, 0.9)])
			var cd := 0.45 if lv < 2 else 0.3
			return cd / (1.3 if G.has_tags("召唤", "环绕") else 1.0)
		"pillar":
			var alive: Array = b.enemies.list.filter(func(e): return not e.dead and e.pos.y > 0)
			if alive.is_empty():
				return 0.5
			var e2 = alive[randi() % alive.size()]
			var hw := 11.0 if br == 0 else 7.0
			var d4 := 45.0 * m * (1.8 if br == 0 else 1.0)
			s.add_zone(e2.pos.x, hw, 0.5, d4, e2.pos.y)
			if br == 1:   # 分柱
				for sx in [-24.0, 24.0]:
					s.add_zone(clampf(e2.pos.x + sx, 6, G.FIELD_W - 6), 5.0, 0.65, d4 * 0.5, e2.pos.y + 10.0)
			return 3.0 if lv < 2 else 2.0
		"moon":
			var n8 := 1 if lv < 2 else 2
			for i in n8:
				var mult := randf_range(0.5, 2.5)
				if lv >= 3 and randf() < 0.15:
					mult = 5.0
				var a7 := -PI / 2.0 + randf_range(-0.3, 0.3)
				s.spawn("moon", pos + Vector2(0, -6), Vector2.from_angle(a7) * 200.0, 6.0 * m * mult, {"curve": randf_range(-1.6, 1.6), "radius": 5.0 if mult < 5.0 else 8.0})
			return 0.28
		"rift":
			var alive2: Array = b.enemies.list.filter(func(e): return not e.dead and e.pos.y > 4)
			if alive2.is_empty():
				return 0.3
			var d3 := 6.0 * m * (1.5 if br == 0 else 1.0)
			for i in (1 if lv < 2 else 2):
				var e3 = alive2[randi() % alive2.size()]
				var side4 := -1.0 if randf() < 0.5 else 1.0
				var gp: Vector2 = e3.pos + Vector2(side4 * (e3.radius + 14.0), randf_range(-6, 6))
				gp.x = clampf(gp.x, 8.0, G.FIELD_W - 8.0)
				s.gaps.append([gp, 0.45])
				var dir3: Vector2 = (e3.pos - gp).normalized()
				for k in (5 if br == 1 else 3):
					s.spawn("gapshot", gp - dir3 * (k * 5.0), dir3 * 190.0, d3, {"rot": true, "life": 1.2, "rift": true})
			return 0.55
		"rift_gate":
			var alive3: Array = b.enemies.list.filter(func(e): return not e.dead and e.pos.y > 4)
			if alive3.is_empty():
				return 0.3
			var d5 := 4.5 * m * (1.5 if lv >= 2 else 1.0)
			for i in (2 if br == 0 else 1):
				var e4 = alive3[randi() % alive3.size()]
				var gp2: Vector2 = Vector2(e4.pos.x, maxf(6.0, e4.pos.y - 42.0))
				s.gaps.append([gp2, 0.5])
				for k in (8 if br == 1 else 4):
					s.spawn("gapshot", gp2 + Vector2(0, -k * 7.0), Vector2(0, 260.0), d5, {"rot": true, "life": 1.0, "pierce": 99, "rift": true})
			return 0.6
	return 1.0

## 星图改为按造成的伤害计数（见 FamSys.on_dealt），这里保留接口
static func on_kill(_b) -> void:
	pass
