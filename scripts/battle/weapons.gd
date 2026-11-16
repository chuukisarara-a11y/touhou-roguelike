class_name Weapons
## 符札（武器）的发射逻辑。fire() 发射一次并返回冷却时间（秒）。

static func fire(w: Dictionary, p: Player, b) -> float:
	var mods: Array = w.get("mods", [])
	b.shots.ctx = mods
	var cd := _fire(w, p, b)
	b.shots.ctx = []
	if mods.has("rapid"):
		cd /= 1.35
	if mods.has("heavy"):
		cd *= 1.25
	if G.has("sniper"):
		cd *= 2.0
	return cd

static func _fire(w: Dictionary, p: Player, b) -> float:
	var s: ShotLayer = b.shots
	var mods: Array = w.get("mods", [])
	var m: float = G.dmg_mult() * (1.6 if w.get("awake", false) else 1.0) * (0.85 if mods.has("rapid") else 1.0) * (1.45 if mods.has("heavy") else 1.0)
	var lv: int = w.lv
	var pos := p.position
	var track := 1.3 if G.tag_count("追踪") >= 2 else 1.0
	var line := 1.25 if G.has_tags("直线", "穿透") else 1.0
	match w.id:
		"amulet":
			var n := (2 if lv < 2 else 4) * (2 if G.has("oozora") else 1)
			var d := 4.0 * m * track * (1.6 if lv >= 3 else 1.0)
			for i in n:
				var side := (i % 2) * 2 - 1
				var k := i / 2
				s.spawn("amulet", pos + Vector2(side * (6 + 4 * k), -3), Vector2(side * (30.0 + 18.0 * k), -190.0), d, {"homing": 9.0, "rot": true})
			return 0.22
		"needle":
			var n2 := 1 if lv < 2 else 2
			for i in n2:
				var off := 0.0 if n2 == 1 else (i * 2 - 1) * 3.0
				s.spawn("needle", pos + Vector2(off, -10), Vector2(0, -360.0), 5.0 * m * line, {"pierce": 2 if lv >= 3 else 0})
			return 0.12
		"star":
			var n3 := 3 if lv < 2 else 5
			var spread := 0.5 if lv < 2 else 0.8
			for i in n3:
				var a := -PI / 2.0 - spread / 2.0 + spread * i / (n3 - 1)
				s.spawn("star", pos + Vector2(0, -6), Vector2.from_angle(a) * 230.0, 5.0 * m)
			return 0.3 if lv < 3 else 0.21
		"laser":
			var lw := 4.0 if lv < 2 else 8.0
			var d2 := 3.4 * m * line * (1.4 if lv >= 2 else 1.0) * (1.6 if lv >= 3 else 1.0)
			p.laser_w = lw
			p.laser_t = 0.16
			p.laser_offs = [-7.0, 7.0] if G.run.char == "marisa" else [0.0]   # 魔理沙是两道
			for e in b.enemies.list:
				if e.dead or e.pos.y >= pos.y:
					continue
				for off0 in p.laser_offs:
					if absf(e.pos.x - pos.x - off0) < lw / 2 + e.radius:
						e.hurt(d2, b)
						if randf() < 0.3:
							b.fx.spark(Vector2(pos.x + off0, e.pos.y + e.radius), Color(0.7, 0.95, 1))
			return 0.1
		"yinyang":
			for o in p.orbs:
				for e in b.enemies.list:
					if not e.dead and e.pos.distance_squared_to(o[0]) < (e.radius + 6.0) * (e.radius + 6.0):
						e.hurt(10.0 * m, b)
						b.fx.spark(o[0])
			return 0.25
		"knife":
			var n4 := 2 if lv < 2 else 4
			for i in n4:
				var side2 := (i % 2) * 2 - 1
				var a2 := -PI / 2.0 + side2 * (0.42 + 0.4 * (i / 2))
				s.spawn("knife", pos + Vector2(side2 * 4, -4), Vector2.from_angle(a2) * 250.0, 6.0 * m * (1.3 if lv >= 3 else 1.0), {"bounce": 2 if lv < 3 else 4, "rot": true, "life": 4.0})
			return 0.32
		"bat":
			var n5 := (1 if lv < 2 else 2) * (2 if G.has("oozora") else 1)
			for i in n5:
				var a3 := -PI / 2.0 + randf_range(-0.9, 0.9)
				s.spawn("bat", pos + Vector2(0, -4), Vector2.from_angle(a3) * 150.0, 6.0 * m * track, {"homing": 7.0, "charge": 0.004 if lv < 3 else 0.008})
			return 0.3
		"fire":
			var n6 := 1 if lv < 2 else 2
			for i in n6:
				var a4 := -PI / 2.0 + randf_range(-0.12, 0.12) + (0.0 if n6 == 1 else (i * 2 - 1) * 0.12)
				s.spawn("fire", pos + Vector2(0, -6), Vector2.from_angle(a4) * 210.0, 3.0 * m, {"burn": (8.0 if lv < 3 else 16.0) * m})
			return 0.35
		"ice":
			var n7 := 1 if lv < 2 else 2
			for i in n7:
				var off2 := 0.0 if n7 == 1 else (i * 2 - 1) * 5.0
				s.spawn("ice", pos + Vector2(off2, -6), Vector2(off2 * 3.0, -220.0), 5.0 * m, {"slow": 2.0, "ice_mark": lv >= 3})
			return 0.3
		"doll":
			for dp in p.dolls:
				var target = s.nearest(dp, b.enemies.list)
				var dir := Vector2.UP
				if target != null:
					dir = (target.pos - dp).normalized()
				s.spawn("needle", dp, dir * 280.0, 4.0 * m, {"pierce": 2 if lv >= 3 else 0, "rot": true})
			var cd := 0.45 if lv < 2 else 0.3
			return cd / (1.3 if G.has_tags("召唤", "环绕") else 1.0)
		"pillar":
			var alive: Array = b.enemies.list.filter(func(e): return not e.dead and e.pos.y > 0)
			if alive.is_empty():
				return 0.5
			var e2 = alive[randi() % alive.size()]
			s.add_zone(e2.pos.x, 14.0, 0.5, 45.0 * m * (1.8 if lv >= 3 else 1.0))
			return 3.0 if lv < 2 else 2.0
		"moon":
			var n8 := 1 if lv < 2 else 2
			for i in n8:
				var mult := randf_range(0.5, 2.5)
				if lv >= 3 and randf() < 0.15:
					mult = 5.0
				var a5 := -PI / 2.0 + randf_range(-0.3, 0.3)
				s.spawn("moon", pos + Vector2(0, -6), Vector2.from_angle(a5) * 200.0, 6.0 * m * mult, {"curve": randf_range(-1.6, 1.6), "radius": 5.0 if mult < 5.0 else 8.0})
			return 0.28
		"rift":
			var alive2: Array = b.enemies.list.filter(func(e): return not e.dead and e.pos.y > 4)
			if alive2.is_empty():
				return 0.3
			var d3 := 6.0 * m * (1.5 if lv >= 3 else 1.0)
			for i in (1 if lv < 2 else 2):
				var e3 = alive2[randi() % alive2.size()]
				var side3 := -1.0 if randf() < 0.5 else 1.0
				var gp: Vector2 = e3.pos + Vector2(side3 * (e3.radius + 14.0), randf_range(-6, 6))
				gp.x = clampf(gp.x, 8.0, G.FIELD_W - 8.0)
				s.gaps.append([gp, 0.45])
				var dir3: Vector2 = (e3.pos - gp).normalized()
				for k in 3:
					s.spawn("gapshot", gp - dir3 * (k * 5.0), dir3 * 190.0, d3, {"rot": true, "life": 1.2})
			return 0.55
	return 1.0

## 星图：击破计数，满了降下流星雨
static func on_kill(b) -> void:
	var w = G.weapon("starmap")
	if w == null:
		return
	w["count"] = w.get("count", 0) + 1
	if w.count >= (8 if w.lv < 3 else 5):
		w.count = 0
		var n := 6 if w.lv < 2 else 12
		for i in n:
			b.shots.spawn("star", Vector2(randf_range(10, G.FIELD_W - 10), -10 - i * 8.0), Vector2(randf_range(-25, 25), 240.0), 14.0 * G.dmg_mult(), {"pierce": 3, "radius": 6.0})
