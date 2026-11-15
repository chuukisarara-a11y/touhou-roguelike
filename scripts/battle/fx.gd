class_name FxLayer
extends Node2D
## 轻量特效：火花、圆环、飘字。

var sparks := []  # [pos, vel, life, color]
var rings := []   # [pos, t, max_r, color]
var texts := []   # [pos, text, life, color]

func spark(pos: Vector2, color := Color(1, 0.9, 0.6)) -> void:
	if sparks.size() > 160:
		return
	sparks.append([pos, Vector2.from_angle(randf() * TAU) * randf_range(20, 70), 0.18, color])

func burst(pos: Vector2, color := Color(0.6, 0.9, 1.0), n := 8, r := 18.0) -> void:
	rings.append([pos, 0.0, r, color])
	for i in n:
		if sparks.size() > 220:
			break
		sparks.append([pos, Vector2.from_angle(randf() * TAU) * randf_range(30, 120), randf_range(0.2, 0.45), color])

func text(pos: Vector2, s: String, color := Color.WHITE) -> void:
	texts.append([pos, s, 0.9, color])

func tick(dt: float) -> void:
	for s in sparks:
		s[0] += s[1] * dt
		s[2] -= dt
	sparks = sparks.filter(func(s): return s[2] > 0.0)
	for r in rings:
		r[1] += dt
	rings = rings.filter(func(r): return r[1] < 0.3)
	for x in texts:
		x[0].y -= 14.0 * dt
		x[2] -= dt
	texts = texts.filter(func(x): return x[2] > 0.0)
	queue_redraw()

func _draw() -> void:
	for s in sparks:
		draw_rect(Rect2(s[0].round(), Vector2(2, 2)), s[3])
	for r in rings:
		var k: float = r[1] / 0.3
		var c: Color = r[3]
		c.a = 1.0 - k
		draw_arc(r[0], r[2] * k + 2.0, 0, TAU, 20, c, 2.0)
	for x in texts:
		var c2: Color = x[3]
		c2.a = minf(1.0, x[2] * 2.0)
		draw_string(G.font, (x[0] + Vector2(-40, 0)).round(), x[1], HORIZONTAL_ALIGNMENT_CENTER, 80, 12, c2)
