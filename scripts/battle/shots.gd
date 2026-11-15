class_name ShotLayer
extends Node2D
## 自机弹：统一更新与绘制。

class Shot:
	var kind: String
	var pos: Vector2
	var vel: Vector2
	var dmg: float
	var homing: float   # 转向速度（弧度/秒），0 = 不追踪
	var pierce: int
	var radius := 5.0
	var dead := false
	var age := 0.0
	var life := 3.0
	var hit_ids := {}

var list: Array[Shot] = []
var _tex := {}

func spawn(kind: String, pos: Vector2, vel: Vector2, dmg: float, homing: float, pierce: int, radius := 5.0) -> Shot:
	var s := Shot.new()
	s.kind = kind; s.pos = pos; s.vel = vel; s.dmg = dmg
	s.homing = homing; s.pierce = pierce; s.radius = radius
	list.append(s)
	if not _tex.has(kind):
		_tex[kind] = G.tex(kind)
	return s

func tick(dt: float, battle) -> void:
	var enemies: Array = battle.enemies.list
	var h: float = battle.field_h
	for s in list:
		s.age += dt
		if s.age > s.life:
			s.dead = true
			continue
		if s.homing > 0.0:
			var target = _nearest(s.pos, enemies)
			if target != null:
				var want: float = (target.pos - s.pos).angle()
				var cur := s.vel.angle()
				var diff := wrapf(want - cur, -PI, PI)
				var turn := (s.homing + s.age * 8.0) * dt  # 越飞越灵活，避免绕圈
				var step := clampf(diff, -turn, turn)
				s.vel = s.vel.rotated(step)
		s.pos += s.vel * dt
		if s.pos.y < -20 or s.pos.y > h + 20 or s.pos.x < -20 or s.pos.x > G.FIELD_W + 20:
			s.dead = true
			continue
		for e in enemies:
			if e.dead or s.hit_ids.has(e.id):
				continue
			var r: float = e.radius + s.radius
			if s.pos.distance_squared_to(e.pos) < r * r:
				e.hurt(s.dmg, battle)
				battle.fx.spark(s.pos)
				if s.pierce > 0:
					s.pierce -= 1
					s.hit_ids[e.id] = true
				else:
					s.dead = true
					break
	list = list.filter(func(s): return not s.dead)
	queue_redraw()

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

func _draw() -> void:
	for s in list:
		var t: Texture2D = _tex[s.kind]
		var sz := t.get_size()
		if s.homing > 0.0 or s.kind == "orb":
			draw_set_transform(s.pos.round(), s.vel.angle() + PI / 2.0, Vector2.ONE)
			draw_texture(t, -sz / 2.0)
		else:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_texture(t, (s.pos - sz / 2.0).round())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
