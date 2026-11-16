class_name SpellBg
extends Node2D
## 符卡演出：符卡期间背景压暗并铺上 Boss 主题色的旋转光芒，Boss 身边转着魔法阵；宣言时有一圈冲击波。

const THEME := {
	"rumia": Color(0.5, 0.3, 0.9), "daiyousei": Color(0.35, 0.9, 0.5), "cirno": Color(0.45, 0.85, 1.0),
	"meiling": Color(1.0, 0.55, 0.35), "patchouli": Color(0.75, 0.45, 1.0), "sakuya": Color(0.55, 0.65, 1.0),
	"tewi": Color(1.0, 0.6, 0.8), "reisen": Color(1.0, 0.3, 0.4), "kaguya": Color(0.9, 0.5, 1.0),
	"ran": Color(1.0, 0.8, 0.35), "yukari": Color(0.7, 0.35, 0.95),
}
var battle
var t := 0.0
var k := 0.0        # 演出强度 0..1
var wave := -1.0    # 宣言冲击波

func declare() -> void:
	wave = 0.0

func tick(dt: float) -> void:
	t += dt
	var on := false
	var b = battle.boss
	if b != null and not b.dead and b.phase_name() != "":
		on = true
	k = move_toward(k, 1.0 if on else 0.0, dt * 2.0)
	if wave >= 0.0:
		wave += dt
		if wave > 0.8:
			wave = -1.0
	queue_redraw()

func _draw() -> void:
	if k <= 0.0 and wave < 0.0:
		return
	var b = battle.boss
	var h: float = battle.field_h
	var c: Color = THEME.get(b.kind if b != null else "", Color(0.7, 0.5, 1.0)) if b != null else Color(0.7, 0.5, 1.0)
	var ctr: Vector2 = b.pos if b != null else Vector2(G.FIELD_W / 2, 60)
	if k > 0.0:
		draw_rect(Rect2(0, 0, G.FIELD_W, h), Color(0.02, 0.0, 0.06, 0.45 * k))
		# 旋转光芒
		var rays := 12
		for i in rays:
			var a0 := t * 0.25 + TAU * i / rays
			var a1 := a0 + TAU / rays * 0.45
			var pts := PackedVector2Array([ctr, ctr + Vector2.from_angle(a0) * 600.0, ctr + Vector2.from_angle(a1) * 600.0])
			draw_colored_polygon(pts, Color(c.r, c.g, c.b, 0.07 * k))
		# 魔法阵：两个反向旋转的六芒星 + 圆环
		for j in 2:
			var rr := 26.0 + j * 10.0
			var rot := t * (0.8 if j == 0 else -0.6)
			var col := Color(c.r, c.g, c.b, (0.55 - j * 0.2) * k)
			draw_arc(ctr, rr, 0, TAU, 48, col, 1.0)
			for tri in 2:
				var p := PackedVector2Array()
				for v in 4:
					p.append(ctr + Vector2.from_angle(rot + tri * PI / 3.0 + v * TAU / 3.0) * rr)
				draw_polyline(p, col, 1.0)
	if wave >= 0.0:
		var r := wave * 360.0
		draw_arc(ctr, r, 0, TAU, 64, Color(1, 1, 1, 0.7 * (1.0 - wave / 0.8)), 3.0)
		draw_arc(ctr, r * 0.8, 0, TAU, 64, Color(c.r, c.g, c.b, 0.6 * (1.0 - wave / 0.8)), 2.0)
