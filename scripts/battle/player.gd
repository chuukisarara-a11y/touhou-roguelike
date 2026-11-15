class_name Player
extends Node2D
## 自机：移动、射击、判定点。

const SPEED := 150.0
const SLOW_SPEED := 68.0
const HIT_RADIUS := 2.0
const GRAZE_RADIUS := 14.0

var max_hearts := 5
var hearts := 5
var invuln := 0.0
var bomb_gauge := 0.0          # 0..1
var touch_delta := Vector2.ZERO # 本帧触屏拖动量（由 Battle 写入）
var weapons: Array = [{"id": "amulet", "lv": 1, "cd": 0.0}, {"id": "needle", "lv": 1, "cd": 0.0}]
var focused := false

var _sprite: Sprite2D
var _hit: Sprite2D
var _t := 0.0

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = G.tex("reimu")
	add_child(_sprite)
	_hit = Sprite2D.new()
	_hit.texture = G.tex("hitbox")
	add_child(_hit)

func tick(dt: float, real_dt: float, battle) -> void:
	_t += dt
	# 键盘
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	focused = Input.is_action_pressed("slow")
	position += v * (SLOW_SPEED if focused else SPEED) * real_dt
	# 触屏：1:1 相对拖动（不受慢动作影响，保证手感）
	position += touch_delta
	touch_delta = Vector2.ZERO
	var h: float = battle.field_h
	position.x = clampf(position.x, 10.0, G.FIELD_W - 10.0)
	position.y = clampf(position.y, 16.0, h - 16.0)
	# 射击
	for w in weapons:
		w.cd -= dt
		if w.cd <= 0.0:
			w.cd += Weapons.fire(w.id, w.lv, self, battle.shots)
	# 无敌闪烁
	if invuln > 0.0:
		invuln -= dt
		_sprite.visible = int(_t * 20.0) % 2 == 0
	else:
		_sprite.visible = true
	_sprite.position.y = roundf(sin(_t * 4.0) * 1.0)
