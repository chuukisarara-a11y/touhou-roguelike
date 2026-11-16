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
	var dead := false
	var age := 0.0
	var life := 3.0
	var hit_ids := {}

var list := []
var zones := []   # 御柱：[x, half_w, delay, dmg, show_t]
var gaps := []    # 隙间：[pos, life]

func _ready() -> void:
	modulate = Color(1, 1, 1, 0.82)   # 自机弹略透明，不遮挡敌弹
var _new := []

func spawn(kind: String, pos: Vector2, vel: Vector2, dmg: float, opts := {}) -> Shot:
	var s := Shot.new()
	s.kind = kind; s.pos = pos; s.vel = vel; s.dmg = dmg
	for k in opts:
		s.set(k, opts[k])
	_new.append(s)
	return s

func add_zone(x: float, half_w: float, delay: float, dmg: float) -> void:
	zones.append([x, half_w, delay, dmg, 0.25])

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
			z[4] -= dt
	zones = zones.filter(func(z): return z[4] > 0.0)
	for g in gaps:
		g[1] -= dt
	gaps = gaps.filter(func(g): return g[1] > 0.0)
	queue_redraw()

func _on_hit(s: Shot, e, battle) -> void:
	battle.fx.spark(s.pos)
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
	e.hurt(s.dmg, battle)
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
	if p.laser_t > 0.0 and battle.state != "lost":
		var lw: float = p.laser_w
		draw_rect(Rect2(p.position.x - lw / 2 - 1, 0, lw + 2, p.position.y - 10), Color(0.4, 0.8, 1.0, 0.45))
		draw_rect(Rect2(p.position.x - lw / 2 + 1, 0, maxf(lw - 2, 1), p.position.y - 10), Color(0.9, 1.0, 1.0, 0.85))
	for z in zones:
		if z[2] > 0.0:
			draw_rect(Rect2(z[0] - z[1], 0, z[1] * 2, battle.field_h), Color(1, 0.8, 0.4, 0.12))
		else:
			draw_rect(Rect2(z[0] - z[1], 0, z[1] * 2, battle.field_h), Color(1, 0.85, 0.5, 0.75 * z[4] / 0.25))
	var gt := G.tex("gap")
	for g in gaps:
		draw_texture(gt, (g[0] - gt.get_size() / 2.0), Color(1, 1, 1, minf(1.0, g[1] * 4.0)))
	for s in list:
		var t: Texture2D = G.tex(s.kind)
		var sz := t.get_size()
		if s.rot:
			draw_set_transform(s.pos, s.vel.angle() + PI / 2.0, Vector2.ONE)
			draw_texture(t, -sz / 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture(t, (s.pos - sz / 2.0))
