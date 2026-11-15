class_name FxLayer
extends Node2D
## 轻量特效：命中火花、击破圆环、飘字。

var sparks: Array = []  # [pos, vel, life, color]
var rings: Array = []   # [pos, t, max_r, color]

func spark(pos: Vector2, color := Color(1, 0.9, 0.6)) -> void:
	if sparks.size() > 150:
		return
	sparks.append([pos, Vector2.from_angle(randf() * TAU) * randf_range(30, 90), 0.18, color])

func burst(pos: Vector2, color := Color(0.6, 0.9, 1.0), n := 10) -> void:
	rings.append([pos, 0.0, 22.0, color])
	for i in n:
		sparks.append([pos, Vector2.from_angle(randf() * TAU) * randf_range(40, 160), randf_range(0.2, 0.45), color])

func tick(dt: float) -> void:
	for s in sparks:
		s[0] += s[1] * dt
		s[2] -= dt
	sparks = sparks.filter(func(s): return s[2] > 0.0)
	for r in rings:
		r[1] += dt
	rings = rings.filter(func(r): return r[1] < 0.3)
	queue_redraw()

func _draw() -> void:
	for s in sparks:
		draw_rect(Rect2(s[0].round(), Vector2(2, 2)), s[3])
	for r in rings:
		var k: float = r[1] / 0.3
		var c: Color = r[3]
		c.a = 1.0 - k
		draw_arc(r[0], r[2] * k + 2.0, 0, TAU, 20, c, 2.0)
