class_name BulletLayer
extends Node2D
## 敌弹与激光：统一更新、碰撞（被弹/擦弹）与绘制（含加法柔光、出弹闪光）。

class Bullet:
	var pos: Vector2
	var vel: Vector2
	var acc := Vector2.ZERO
	var r := 2.5
	var shape := 0   # 0小圆 1大圆 2米粒 3小刀 4星弹 5蝴蝶 6札弹
	var col := 0
	var grazed := false
	var dead := false
	var tag := ""
	var age := 0.0
	var spd := 0.0      # 停顿后再出发的速度
	var w := 0.0        # 转向（弧度/秒）
	var maxs := 0.0     # 加速时的速度上限（0 = 不限）
	var delay := 0.0    # 出生后静止多久再出发
	var hold := Vector2.ZERO
	var bounce := 0     # 碰左右边反弹次数
	var split := 0.0    # 多少秒后分裂
	var split_n := 2
	var split_spread := 0.6
	var split_depth := 0
	var emit := 0.0     # 每隔多少秒向两侧洒小弹
	var emit_t := 0.0
	var go_spread := 0.0
	var drag := 0.0     # 减速（滞留弹用）
	var life := 0.0     # 存活秒数（0 = 直到出屏）

class Laser:
	var o: Vector2
	var a := 0.0
	var length := 400.0
	var width := 6.0
	var warn := 1.0
	var life := 2.0
	var t := 0.0
	var col := 0
	var rot := 0.0
	var follow = null   # 跟随某个敌人
	var graze_cd := 0.0
	var has_stop := false   # 转到 stop_a 就停住
	var stop_a := 0.0
	var dead := false
	func active() -> bool:
		return t >= warn and t < warn + life
	func cur_w() -> float:
		if t < warn:
			return 0.0
		var k := minf(1.0, (t - warn) / 0.12) * minf(1.0, (warn + life - t) / 0.15)
		return width * k

const RADII := [2.5, 5.0, 2.0, 2.0, 3.0, 3.2, 2.4]
const ROT_SHAPES := [2, 3, 5, 6]
const COLORS := [Color(1, 0.3, 0.35), Color(0.35, 0.55, 1), Color(0.35, 0.9, 0.5), Color(1, 0.55, 0.85), Color(0.75, 0.45, 1), Color(0.45, 0.9, 1), Color(0.9, 0.92, 1)]
const CAP := 1400
var list := []
var lasers := []
var _new := []
var _atlas: Texture2D

func _ready() -> void:
	_atlas = G.tex("bullets", true)
	var glow := GlowLayer.new()
	glow.layer = self
	glow.show_behind_parent = true
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(glow)

func speed_mult() -> float:
	return G.DIFF_SPEED * (1.0 + 0.05 * (G.run.get("chapter", 1) - 1))

## 新敌弹：速度会乘上难度系数
func add(pos: Vector2, vel: Vector2, shape := 0, col := 0, tag := "") -> Bullet:
	return raw(pos, vel * speed_mult(), shape, col, tag)

## 不乘难度系数（分裂、洒出的子弹用）
func raw(pos: Vector2, vel: Vector2, shape := 0, col := 0, tag := "") -> Bullet:
	var b := Bullet.new()
	b.pos = pos; b.vel = vel; b.spd = vel.length(); b.shape = shape; b.col = col; b.tag = tag
	b.r = RADII[shape]
	if list.size() + _new.size() < CAP:
		_new.append(b)
	return b

func laser(o: Vector2, a: float, length: float, width: float, warn: float, life: float, col := 0, rot := 0.0, follow = null) -> Laser:
	var l := Laser.new()
	l.o = o; l.a = a; l.length = length; l.width = width; l.warn = warn; l.life = life; l.col = col; l.rot = rot; l.follow = follow
	lasers.append(l)
	return l

## 清掉全部敌弹（激光也一起），返回被清掉的子弹位置（用来变成灵点）
func clear_all(fx: FxLayer = null) -> Array:
	list.append_array(_new)
	_new.clear()
	var pts := []
	for b in list:
		pts.append(b.pos)
	if fx != null:
		for i in range(0, pts.size(), 3):
			fx.spark(pts[i], Color(0.8, 0.9, 1.0))
	list.clear()
	lasers.clear()
	return pts

func clear_near(pos: Vector2, radius: float, fx: FxLayer) -> void:
	for b in list:
		if b.pos.distance_squared_to(pos) < radius * radius:
			b.dead = true
			fx.spark(b.pos, Color(0.7, 0.95, 1.0))

func tick(dt: float, battle) -> void:
	list.append_array(_new)
	_new.clear()
	var h: float = battle.field_h
	var pp: Vector2 = battle.player.position
	var graze_r: float = battle.graze_radius()
	var alive: bool = battle.state == "play"
	for b in list:
		if b.dead:
			continue
		b.age += dt
		if b.delay > 0.0:
			if b.age < b.delay:
				continue
			b.vel = b.hold
			b.delay = 0.0
		if b.tag == "sa":   # 飞一小段后停住，再朝自机射出
			if b.age > 1.5:
				b.vel = (pp - b.pos).normalized().rotated(b.go_spread) * b.spd
				b.tag = ""
			elif b.age > 0.7:
				b.vel = Vector2.ZERO
		if b.life > 0.0 and b.age > b.life:
			b.dead = true
			continue
		if b.drag > 0.0:
			b.vel *= maxf(0.0, 1.0 - b.drag * dt)
		if b.w != 0.0:
			b.vel = b.vel.rotated(b.w * dt)
		if b.acc != Vector2.ZERO:
			b.vel += b.acc * dt
			if b.maxs > 0.0 and b.vel.length() > b.maxs:
				b.vel = b.vel.normalized() * b.maxs
		b.pos += b.vel * dt
		if b.bounce > 0 and ((b.pos.x < 2 and b.vel.x < 0) or (b.pos.x > G.FIELD_W - 2 and b.vel.x > 0)):
			b.vel.x = -b.vel.x
			b.bounce -= 1
		if b.split > 0.0 and b.age >= b.split:
			_split(b)
			continue
		if b.emit > 0.0 and b.age < 1.6:   # 只在前 1.6 秒洒火星，避免满屏
			b.emit_t -= dt
			if b.emit_t <= 0.0:
				b.emit_t = b.emit
				var n: Vector2 = b.vel.normalized().orthogonal()
				for s in [1.0, -1.0]:
					var em := raw(b.pos, n * s * 20.0, 0, 3)
					em.acc = n * s * 30.0
					em.maxs = 60.0
		if b.pos.x < -12 or b.pos.x > G.FIELD_W + 12 or b.pos.y < -12 or b.pos.y > h + 12:
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
			if G.has("reflect"):
				b.dead = true
	list = list.filter(func(b): return not b.dead)
	_tick_lasers(dt, battle, pp, graze_r, alive)
	queue_redraw()

func _split(b: Bullet) -> void:
	b.dead = true
	var base := b.vel.angle()
	for i in b.split_n:
		var a := base if b.split_n == 1 else base - b.split_spread / 2.0 + b.split_spread * i / (b.split_n - 1)
		var c := raw(b.pos, Vector2.from_angle(a) * b.vel.length(), b.shape if b.split_depth > 0 else 0, b.col)
		if b.split_depth > 0:
			c.split = b.split
			c.split_n = b.split_n
			c.split_spread = b.split_spread
			c.split_depth = b.split_depth - 1

func _tick_lasers(dt: float, battle, pp: Vector2, graze_r: float, alive: bool) -> void:
	for l in lasers:
		l.t += dt
		l.a += l.rot * dt
		if l.has_stop and ((l.rot > 0.0 and l.a >= l.stop_a) or (l.rot < 0.0 and l.a <= l.stop_a)):
			l.a = l.stop_a
			l.rot = 0.0
		if l.follow != null:
			if l.follow.dead:
				l.dead = true
				continue
			l.o = l.follow.pos
		if l.t > l.warn + l.life:
			l.dead = true
			continue
		if not alive or not l.active():
			continue
		var dir := Vector2.from_angle(l.a)
		var rel: Vector2 = pp - l.o
		var along: float = clampf(rel.dot(dir), 0.0, l.length)
		var dist: float = (rel - dir * along).length()
		var half: float = l.cur_w() * 0.35
		if dist < half + Player.HIT_RADIUS:
			battle.player_hit()
		elif dist < half + graze_r:
			l.graze_cd -= dt
			if l.graze_cd <= 0.0:
				l.graze_cd = 0.1
				battle.on_graze(l.o + dir * along)
	lasers = lasers.filter(func(l): return not l.dead)

func _draw() -> void:
	# 激光：预警线 → 实体
	for l in lasers:
		var end: Vector2 = l.o + Vector2.from_angle(l.a) * l.length
		var c: Color = COLORS[l.col]
		if l.t < l.warn:
			var k: float = l.t / l.warn
			draw_line(l.o, end, Color(c.r, c.g, c.b, 0.25 + 0.35 * k * (0.5 + 0.5 * sin(l.t * 30.0))), 1.0)
		else:
			var w: float = l.cur_w()
			draw_line(l.o, end, Color(c.r, c.g, c.b, 0.85), w)
			draw_line(l.o, end, Color(1, 1, 1, 0.95), w * 0.45)
	for b in list:
		if b.delay > 0.0 and b.age < b.delay:
			pass
		var src := Rect2(b.col * 32, b.shape * 32, 32, 32)
		var s := 1.0
		var a := 1.0
		if b.age < 0.12:   # 出弹闪光：从大到小、从透明到实
			var k: float = b.age / 0.12
			s = 1.0 + (1.0 - k) * 1.4
			a = 0.35 + 0.65 * k
		var rect := Rect2(-8.0 * s, -8.0 * s, 16.0 * s, 16.0 * s)
		if b.life > 0.0 and b.life - b.age < 1.0:   # 快消失时闪烁
			a *= 0.45 + 0.55 * absf(sin(b.age * 14.0))
		var mod := Color(1, 1, 1, a)
		if b.shape in ROT_SHAPES:
			draw_set_transform(b.pos, (b.vel.angle() if b.vel != Vector2.ZERO else -PI / 2.0) + PI / 2.0, Vector2.ONE)
			draw_texture_rect_region(_atlas, rect, src, mod)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif b.shape == 4:
			draw_set_transform(b.pos, b.age * 5.0, Vector2.ONE)
			draw_texture_rect_region(_atlas, rect, src, mod)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect_region(_atlas, Rect2(b.pos + rect.position, rect.size), src, mod)

## 加法混合的柔光层：画在子弹下面，让弹幕看起来发光
class GlowLayer extends Node2D:
	var layer
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var g := G.tex("glow", true)
		for b in layer.list:
			var c: Color = layer.COLORS[b.col]
			var rad: float = 10.0 if b.shape == 1 else 6.0
			if b.age < 0.15:
				rad *= 1.0 + (0.15 - b.age) * 8.0
			draw_texture_rect(g, Rect2(b.pos.x - rad, b.pos.y - rad, rad * 2, rad * 2), false, Color(c.r, c.g, c.b, 0.33))
		for l in layer.lasers:
			if l.t >= l.warn:
				var end: Vector2 = l.o + Vector2.from_angle(l.a) * l.length
				var c2: Color = layer.COLORS[l.col]
				draw_line(l.o, end, Color(c2.r, c2.g, c2.b, 0.35), l.cur_w() * 2.6)
