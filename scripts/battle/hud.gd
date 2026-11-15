class_name Hud
extends Node2D
## 战斗界面：心、符卡槽、符卡按钮、提示文字。

var battle
var bomb_rect := Rect2()
var _label: Label
var _info: Label
var _heart: Texture2D
var _heart_e: Texture2D

func setup(b) -> void:
	battle = b
	_heart = G.tex("heart")
	_heart_e = G.tex("heart_empty")
	bomb_rect = Rect2(G.FIELD_W - 52, b.field_h - 52, 44, 44)
	_label = Label.new()
	_label.position = Vector2(8, 22)
	add_child(_label)
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.position = Vector2(0, b.field_h - 130)
	_info.size = Vector2(G.FIELD_W, 40)
	_info.modulate = Color(1, 1, 1, 0.7)
	add_child(_info)
	var bl := Label.new()
	bl.text = "符卡"
	bl.position = bomb_rect.position + Vector2(10, 14)
	add_child(bl)

func tick() -> void:
	_label.text = "击破 %d    FPS %d" % [battle.kills, Engine.get_frames_per_second()]
	if G.touch_mode:
		_info.text = "拖动屏幕移动 · 松手进入慢动作"
	else:
		_info.text = "方向键/WASD 移动 · Shift 低速\nX 符卡 · 也可以用鼠标拖动"
	queue_redraw()

func _draw() -> void:
	var p: Player = battle.player
	for i in p.max_hearts:
		draw_texture(_heart if i < p.hearts else _heart_e, Vector2(8 + i * 11, 8))
	# 符卡按钮
	var ready: bool = p.bomb_gauge >= 1.0
	var c := Color(0.9, 0.3, 0.4, 0.85) if ready else Color(0.3, 0.3, 0.45, 0.6)
	var ctr := bomb_rect.get_center()
	draw_circle(ctr, 22, Color(0, 0, 0, 0.35))
	draw_arc(ctr, 20, -PI / 2, -PI / 2 + TAU * clampf(p.bomb_gauge, 0, 1), 40, c, 3.0)
	if ready:
		draw_arc(ctr, 16, 0, TAU, 32, Color(1, 0.9, 0.9, 0.5 + 0.4 * sin(Time.get_ticks_msec() / 120.0)), 1.0)
	# 慢动作条
	if battle.slowmo_active:
		var w: float = 80.0 * battle.slow_budget / battle.SLOW_MAX
		draw_rect(Rect2(G.FIELD_W / 2 - 40, battle.field_h - 20, 80, 3), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(G.FIELD_W / 2 - 40, battle.field_h - 20, w, 3), Color(0.6, 0.9, 1.0))
