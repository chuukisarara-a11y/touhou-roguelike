class_name ShotLayer
extends Node2D
## 自机弹：统一更新、命中处理与绘制；另含御柱的范围区域与镭射。

class Shot:
	var kind := ""
	var pos: Vector2
	var vel: Vector2
	var dmg := 1.0
	var homing := 0.0   # 转向速度（弧度/秒）
	var pierce := 0
	var radius := 4.0
	var bounce := 0
	var wrap := false
	var curve := 0.0    # 弹道弯曲（弧度/秒）
	var burn := 0.0     # 点燃的每秒伤害
	var slow := 0.0     # 减速秒数
	var ice_mark := false
	var charge := 0.0   # 命中时符卡槽充能
	var rot := false
	var split_mod := false
	var chain := 0        # 命中后弹向下一个敌人的次数
	var near_bonus := false   # 散札：离自机越近伤害越高
	var stun := 0.0       # 封印札：定身秒数
	var seal := false
	var clear_r := 0.0    # 命中时消除敌人周围的敌弹
	var rift := false     # 境界裂隙系：命中计数
	var pen := false      # 贯魔针·破甲
	var child := false
	var big := false
	var dead := false
	var age := 0.0
	var life := 3.0
	var hit_ids := {}

var list := []
var zones := []   # 御柱：[x, half_w, delay, dmg, show_t, 落点y（<0 表示不留墙）]
var gaps := []    # 隙间：[pos, life]

func _ready() -> void:
	modulate = Color(1, 1, 1, 0.82)   # 自机弹略透明，不遮挡敌弹
var _new := []
var ctx := []     # 正在开火的符札的改造（Weapons.fire 设置）

func spawn(kind: String, pos: Vector2, vel: Vector2, dmg: float, opts := {}) -> Shot:
	var s := Shot.new()
	s.kind = kind; s.pos = pos; s.vel = vel; s.dmg = dmg
	for k in opts:
		s.set(k, opts[k])
	if not ctx.is_empty():
		if ctx.has("pierce"):
			s.pierce += 2
		if ctx.has("bounce"):
			s.bounce += 2
		if ctx.has("split"):
			s.split_mod = true
		if ctx.has("burn"):
			s.burn = maxf(s.burn, 6.0 * G.dmg_mult())
		if ctx.has("frost"):
			s.slow = maxf(s.slow, 1.5)
		if ctx.has("big"):
			s.radius *= 1.8
			s.vel *= 0.75
			s.big = true
		if ctx.has("leech"):
			s.charge += 0.003
		if ctx.has("homing") and s.homing == 0.0:
			s.homing = 3.5
	_new.append(s)
	return s

func add_zone(x: float, half_w: float, delay: float, dmg: float, land_y := -1.0) -> void:
	zones.append([x, half_w, delay, dmg, 0.25, land_y])

func tick(dt: float, battle) -> void:
	list.append_array(_new)
	_new.clear()
	var enemies: Array = battle.enemies.list
	var h: float = battle.field_h
	var w := G.FIELD_W
	for s in list:
		s.age += dt
		if s.age > s.life:
			s.dead = true
			continue
		if s.homing > 0.0:
			var target = _nearest(s.pos, enemies)
			if target != null:
				var diff := wrapf((target.pos - s.pos).angle() - s.vel.angle(), -PI, PI)
				var turn: float = (s.homing + s.age * 8.0) * dt
				s.vel = s.vel.rotated(clampf(diff, -turn, turn))
		if s.curve != 0.0:
			s.vel = s.vel.rotated(s.curve * dt)
		s.pos += s.vel * dt
		if s.wrap:
			s.pos.x = fposmod(s.pos.x, w)
		elif s.bounce > 0:
			if (s.pos.x < 2 and s.vel.x < 0) or (s.pos.x > w - 2 and s.vel.x > 0):
				s.vel.x = -s.vel.x; s.bounce -= 1
			if s.pos.y < 2 and s.vel.y < 0:
				s.vel.y = -s.vel.y; s.bounce -= 1
		if s.pos.y < -16 or s.pos.y > h + 16 or s.pos.x < -16 or s.pos.x > w + 16:
			s.dead = true
			continue
		for e in enemies:
			if e.dead or s.hit_ids.has(e.id):
				continue
			var r: float = e.radius + s.radius
			if s.pos.distance_squared_to(e.pos) < r * r:
				_on_hit(s, e, battle)
				if s.chain > 0:   # 连锁：转向下一个敌人
					s.chain -= 1
					s.hit_ids[e.id] = true
					var nx = null
					var bd := 1e12
					for o in enemies:
						if not o.dead and not s.hit_ids.has(o.id):
							var dd: float = o.pos.distance_squared_to(s.pos)
							if dd < bd:
								bd = dd; nx = o
					if nx != null:
						s.vel = (nx.pos - s.pos).normalized() * s.vel.length()
						break
					s.dead = true
					break
				if s.pierce > 0:
					s.pierce -= 1
					s.hit_ids[e.id] = true
				else:
					s.dead = true
					break
	list = list.filter(func(s): return not s.dead)
	for z in zones:
		z[2] -= dt
		if z[2] <= 0.0:
			if z[4] == 0.25:
				for e in enemies:
					if not e.dead and absf(e.pos.x - z[0]) < z[1] + e.radius:
						e.hurt(z[3], battle)
				battle.shake = 0.12
				if z[5] >= 0.0:   # 御柱落地后留在原地当墙
					battle.fams.pillar_land(z[0], z[5], z[1])
			z[4] -= dt
	zones = zones.filter(func(z): return z[4] > 0.0)
	for g in gaps:
		g[1] -= dt
	gaps = gaps.filter(func(g): return g[1] > 0.0)
	queue_redraw()

func _on_hit(s: Shot, e, battle) -> void:
	battle.fx.spark(s.pos)
	if s.split_mod and not s.child:
		for sg in [-1.0, 1.0]:
			var c := spawn(s.kind, s.pos, s.vel.rotated(sg * 0.7), s.dmg * 0.4, {"child": true, "rot": s.rot, "life": 1.2, "radius": s.radius, "homing": s.homing})
			c.hit_ids[e.id] = true
	var steam := false
	if s.burn > 0.0:
		steam = e.slow_t > 0.0
		e.burn_t = 3.0
		e.burn_dps = maxf(e.burn_dps, s.burn)
	if s.slow > 0.0:
		steam = steam or e.burn_t > 0.0
		e.slow_t = s.slow
		if s.ice_mark:
			e.ice_mark = true
	if s.charge > 0.0:
		battle.add_bomb(s.charge)
	var d: float = s.dmg
	if s.near_bonus:
		var dist: float = battle.player.position.distance_to(e.pos)
		d *= clampf(1.8 - dist / 90.0, 0.6, 1.8) * (2.0 if (G.br("amulet_fan") == 0 and dist < 50.0) else 1.0)
	if e.stun_t > 0.0 and e.sealed:
		d *= 1.3
	if s.stun > 0.0:
		e.stun_t = maxf(e.stun_t, s.stun * (0.35 if e.is_boss else 1.0))
		e.sealed = s.seal
	if s.clear_r > 0.0:
		battle.bullets.clear_near(e.pos, s.clear_r, battle.fx)
	if G.has_fam("amulet") and G.has("am_seal") and s.kind == "amulet":
		battle.on_graze(s.pos)
	if s.rift:
		battle.fams.on_rift_hit()
	if s.pen and (e.armor or (e.mech == "shield" and e.shield_n > 0)):
		var sn: int = e.shield_n
		e.shield_n = 0
		e.hurt(d * 2.0, battle)
		e.shield_n = sn
	else:
		e.hurt(d, battle)
	if steam and e.steam_cd <= 0.0 and G.has_tags("火", "冰"):
		e.steam_cd = 1.0
		battle.fx.burst(e.pos, Color(1, 1, 1), 12, 30.0)
		for o in battle.enemies.list:
			if not o.dead and o.pos.distance_squared_to(e.pos) < 34.0 * 34.0:
				o.hurt(18.0 * G.dmg_mult(), battle)

func _nearest(pos: Vector2, enemies: Array):
	var best = null
	var bd := 1e12
	for e in enemies:
		if e.dead:
			continue
		var d := pos.distance_squared_to(e.pos)
		if d < bd:
			bd = d; best = e
	return best

func nearest(pos: Vector2, enemies: Array):
	return _nearest(pos, enemies)

func _draw() -> void:
	var battle = get_parent()
	var p: Player = battle.player
	if battle.state != "lost":   # 镭射类射线
		for bm in p.beams:
			var o: Vector2 = bm[0]
			var e: Vector2 = o + Vector2.from_angle(bm[1]) * 420.0
			var bw: float = bm[2]
			var c: Color = bm[4]
			draw_line(o, e, Color(c.r * 0.5, c.g * 0.85, 1.0, 0.45), bw + 2.0)
			draw_line(o, e, Color(c, 0.85), maxf(bw - 2.0, 1.0))
	for z in zones:
		if z[2] > 0.0:
			draw_rect(Rect2(z[0] - z[1], 0, z[1] * 2, battle.field_h), Color(1, 0.8, 0.4, 0.12))
		else:
			draw_rect(Rect2(z[0] - z[1], 0, z[1] * 2, battle.field_h), Color(1, 0.85, 0.5, 0.75 * z[4] / 0.25))
	if battle.spark_t > 0.0:   # 极限火花
		var sw: float = battle.spark_w * minf(1.0, battle.spark_t * 4.0) * (1.0 + 0.06 * sin(battle.spark_t * 50.0))
		var sx: float = p.position.x
		var sy: float = p.position.y - 8.0
		var hue := fmod(battle.spark_t * 1.5, 1.0)
		draw_rect(Rect2(sx - sw / 2.0 - 5, -10, sw + 10, sy + 10), Color.from_hsv(hue, 0.6, 1.0, 0.35))
		draw_rect(Rect2(sx - sw / 2.0, -10, sw, sy + 10), Color.from_hsv(fmod(hue + 0.15, 1.0), 0.35, 1.0, 0.8))
		draw_rect(Rect2(sx - sw * 0.3, -10, sw * 0.6, sy + 10), Color(1, 1, 1, 0.95))
		draw_circle(Vector2(sx, sy), sw * 0.6, Color(1, 1, 1, 0.9))
	var gt := G.tex("gap")
	for g in gaps:
		draw_texture(gt, (g[0] - gt.get_size() / 2.0), Color(1, 1, 1, minf(1.0, g[1] * 4.0)))
	for s in list:
		var t: Texture2D = G.tex(s.kind)
		var sz := t.get_size()
		draw_set_transform(s.pos, (s.vel.angle() + PI / 2.0) if s.rot else 0.0, Vector2(1.7, 1.7) if s.big else Vector2.ONE)
		draw_texture(t, -sz / 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
