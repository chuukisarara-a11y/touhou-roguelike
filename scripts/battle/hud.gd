class_name Hud
extends Node2D
## 战斗界面：心、钱、波次、Boss 血条与符卡名、符卡按钮、慢动作条。

var battle
var bomb_rect := Rect2()
var cutin_t := 0.0
var cutin_tex: Texture2D

func cutin(tex_name: String) -> void:
	cutin_tex = G.tex(tex_name)
	cutin_t = 1.8

func setup(b) -> void:
	battle = b
	bomb_rect = Rect2(G.FIELD_W - 42, b.field_h - 42, 36, 36)

func tick() -> void:
	cutin_t -= get_process_delta_time()
	queue_redraw()

func _draw() -> void:
	var f := G.font
	var run: Dictionary = G.run
	if cutin_t > 0.0 and cutin_tex != null:
		var k := clampf(cutin_t / 1.8, 0, 1)
		var a := minf(1.0, minf(k * 5.0, (1.0 - k) * 7.0)) * 0.92
		var sz := cutin_tex.get_size() * 1.25
		var slide := pow(k, 3.0) * 60.0 - pow(1.0 - k, 6.0) * 40.0
		draw_rect(Rect2(0, 78, G.FIELD_W, sz.y - 36), Color(0.1, 0.06, 0.2, 0.45 * a))
		draw_texture_rect(cutin_tex, Rect2(G.FIELD_W - sz.x - 4 + slide, 50, sz.x, sz.y), false, Color(1, 1, 1, a))
	var h := G.tex("heart")
	var he := G.tex("heart_empty")
	for i in run.max_hearts:
		draw_texture(h if i < run.hearts else he, Vector2(4 + i * 10, 4))
	draw_texture(G.tex("coin"), Vector2(G.FIELD_W - 62, 6))
	draw_string(f, Vector2(G.FIELD_W - 54, 15), str(run.money), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.5))
	# 暂停键
	draw_rect(Rect2(G.FIELD_W - 19, 3, 16, 14), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(G.FIELD_W - 15, 6, 3, 8), Color(1, 1, 1, 0.85))
	draw_rect(Rect2(G.FIELD_W - 10, 6, 3, 8), Color(1, 1, 1, 0.85))
	var boss = battle.boss
	if boss != null and not boss.dead:
		var w := G.FIELD_W - 16.0
		draw_rect(Rect2(8, 20, w, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(8, 20, w * clampf(boss.hp / boss.max_hp, 0, 1), 4), Color(1, 0.4, 0.5))
		for i in boss.phases.size() - boss.phase_i - 1:
			draw_rect(Rect2(8 + i * 6, 26, 4, 3), Color(1, 0.8, 0.85))
		draw_string(f, Vector2(0, 40), boss.def.name + ("  " + boss.phase_name() if boss.phase_name() != "" else ""), HORIZONTAL_ALIGNMENT_CENTER, G.FIELD_W, 12, Color(1, 0.95, 1, 0.9))
	if boss != null and not boss.dead:
		# 屏幕底部的敌机位置标记
		var bx: float = clampf(boss.pos.x, 12, G.FIELD_W - 12)
		var by: float = battle.field_h
		draw_rect(Rect2(bx - 13, by - 3, 26, 3), Color(1, 0.25, 0.35, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 5, by - 3), Vector2(bx + 5, by - 3), Vector2(bx, by - 9)]), Color(1, 0.25, 0.35, 0.9))
		draw_string(f, Vector2(bx - 13, by - 11), "敌", HORIZONTAL_ALIGNMENT_CENTER, 26, 12, Color(1, 0.6, 0.65, 0.9))
	elif battle.kind == "battle":
		draw_string(f, Vector2(0, 15), "第 %d/%d 波" % [battle.wave_i + 1, battle.waves.size()], HORIZONTAL_ALIGNMENT_CENTER, G.FIELD_W, 12, Color(1, 1, 1, 0.6))
	# 符卡按钮：外圈是下一格的充能进度，上方的小点是已存满的格数
	var mx := G.bomb_max()
	var full := int(floorf(run.bomb))
	var frac: float = run.bomb - full if full < mx else 1.0
	var ready := full >= 1
	var ctr := bomb_rect.get_center()
	draw_circle(ctr, 18, Color(0, 0, 0, 0.35))
	draw_arc(ctr, 16, -PI / 2, -PI / 2 + TAU * frac, 32, Color(0.95, 0.35, 0.45, 0.9) if ready else Color(0.45, 0.45, 0.65, 0.7), 2.0)
	if ready:
		draw_arc(ctr, 12, 0, TAU, 24, Color(1, 0.9, 0.9, 0.5 + 0.4 * sin(Time.get_ticks_msec() / 120.0)), 1.0)
	for i in mx:
		var pp := ctr + Vector2(-(mx - 1) * 4.0 + i * 8.0, -23)
		draw_circle(pp, 2.5, Color(1, 0.4, 0.5) if i < full else Color(0.25, 0.25, 0.35, 0.8))
	draw_string(f, ctr + Vector2(-12, 4), "符卡", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if ready else Color(0.6, 0.6, 0.7))
	# 擦弹连击
	if battle.graze_combo >= 5:
		var pc: Vector2 = battle.player.position + Vector2(10, -16)
		var a := clampf(battle.combo_t * 2.0, 0.0, 1.0)
		draw_string(f, pc, "擦×%d" % battle.graze_combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 0.75, a))
	# 灵压
	if battle.spirit > 0:
		var lv: int = G.spirit_lv
		draw_string(f, Vector2(4, 30), "灵压Lv%d" % lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.95, 1.0, 0.85))
		if lv < 5:
			draw_rect(Rect2(4, 33, 40, 2), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(4, 33, 40.0 * (battle.spirit % 40) / 40.0, 2), Color(0.6, 0.95, 1.0))
	if battle.slowmo_active:
		var sw: float = 60.0 * battle.slow_budget / battle.SLOW_MAX
		draw_rect(Rect2(G.FIELD_W / 2 - 30, battle.field_h - 10, 60, 2), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(G.FIELD_W / 2 - 30, battle.field_h - 10, sw, 2), Color(0.6, 0.9, 1.0))
	if battle.banner_t > 0.0:
		var c := Color(1, 1, 1, minf(1.0, battle.banner_t))
		draw_string(f, Vector2(0, battle.field_h * 0.4), battle.banner, HORIZONTAL_ALIGNMENT_CENTER, G.FIELD_W, 24, c)
