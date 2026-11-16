class_name BulletLayer
extends Node2D
## 敌弹：统一更新、碰撞（被弹/擦弹）与绘制。

class Bullet:
	var pos: Vector2
	var vel: Vector2
	var acc := Vector2.ZERO
	var r := 2.5
	var shape := 0   # 0小圆 1大圆 2米粒
	var col := 0
	var grazed := false
	var dead := false
	var tag := ""

const RADII := [2.5, 5.0, 2.0]
var list := []
var _atlas: Texture2D

func _ready() -> void:
	_atlas = G.tex("bullets", true)

func add(pos: Vector2, vel: Vector2, shape := 0, col := 0, tag := "") -> Bullet:
	var b := Bullet.new()
	b.pos = pos; b.vel = vel * G.DIFF_SPEED; b.shape = shape; b.col = col; b.tag = tag
	b.r = RADII[shape]
	if list.size() < 700:
		list.append(b)
	return b

func clear_all(fx: FxLayer = null) -> int:
	var n := list.size()
	if fx != null:
		for i in range(0, n, 3):
			fx.spark(list[i].pos, Color(0.8, 0.9, 1.0))
	list.clear()
	return n

func clear_near(pos: Vector2, radius: float, fx: FxLayer) -> void:
	for b in list:
		if b.pos.distance_squared_to(pos) < radius * radius:
			b.dead = true
			fx.spark(b.pos, Color(0.7, 0.95, 1.0))

func tick(dt: float, battle) -> void:
	var h: float = battle.field_h
	var pp: Vector2 = battle.player.position
	var graze_r: float = battle.player.graze_radius()
	var alive: bool = battle.state == "play"
	for b in list:
		if b.dead:
			continue
		b.vel += b.acc * dt
		b.pos += b.vel * dt
		if b.pos.x < -10 or b.pos.x > G.FIELD_W + 10 or b.pos.y < -10 or b.pos.y > h + 10:
			b.dead = true
			continue
		if not alive:
			continue
		var d2: float = b.pos.distance_squared_to(pp)
		var hr: float = b.r + Player.HIT_RADIUS
		if d2 < hr * hr:
			b.dead = true
			battle.player_hit()
		elif not b.grazed and d2 < (b.r + graze_r) * (b.r + graze_r):
			b.grazed = true
			battle.on_graze(b.pos)
	list = list.filter(func(b): return not b.dead)
	queue_redraw()

func _draw() -> void:
	for b in list:
		var src := Rect2(b.col * 32, b.shape * 32, 32, 32)
		if b.shape == 2:
			draw_set_transform(b.pos, b.vel.angle() + PI / 2.0, Vector2.ONE)
			draw_texture_rect_region(_atlas, Rect2(-8, -8, 16, 16), src)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect_region(_atlas, Rect2((b.pos - Vector2(8, 8)), Vector2(16, 16)), src)
