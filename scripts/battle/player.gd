class_name Player
extends Node2D
## 自机：移动、射击、判定点、阴阳玉与人偶。

const SPEED := 110.0
const SLOW_SPEED := 50.0
const HIT_RADIUS := 1.8
const GRAZE_RADIUS := 12.0

var invuln := 0.0
var touch_delta := Vector2.ZERO
var focused := false
var orbs := []     # [pos, eat_cd]
var orb_ang := 0.0
var dolls := []
var laser_w := 0.0
var laser_t := 0.0

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
	for w in G.run.weapons:
		w.cd = 0.0

func graze_radius() -> float:
	return GRAZE_RADIUS * (1.5 if G.has("gohei") else 1.0)

func tick(dt: float, real_dt: float, battle) -> void:
	_t += dt
	if battle.state == "lost":
		visible = false
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	focused = Input.is_action_pressed("slow")
	var sp := (SLOW_SPEED if focused else SPEED) * (1.15 if G.has("fan") else 1.0)
	position += v * sp * real_dt + touch_delta
	touch_delta = Vector2.ZERO
	position.x = clampf(position.x, 7.0, G.FIELD_W - 7.0)
	position.y = clampf(position.y, 12.0, battle.field_h - 12.0)
	# 阴阳玉
	var yy = G.weapon("yinyang")
	var n: int = yy.lv if yy != null else 0
	while orbs.size() < n:
		orbs.append([position, 0.0])
	orb_ang += dt * 3.5
	for i in n:
		var o: Array = orbs[i]
		o[0] = position + Vector2.from_angle(orb_ang + TAU * i / n) * 22.0
		o[1] -= dt
		if o[1] <= 0.0:
			for bl in battle.bullets.list:
				if not bl.dead and bl.pos.distance_squared_to(o[0]) < (bl.r + 5.0) * (bl.r + 5.0):
					bl.dead = true
					o[1] = 0.3
					battle.fx.spark(bl.pos, Color(1, 0.6, 0.6))
					break
	# 人偶
	if G.weapon("doll") != null:
		dolls = [position + Vector2(-17, 5), position + Vector2(17, 5)]
	# 射击
	laser_t -= dt
	if battle.state == "play":
		for w in G.run.weapons:
			w.cd -= dt
			if w.cd <= 0.0:
				w.cd += Weapons.fire(w, self, battle)
				Au.sfx("shoot", -6.0)
	if invuln > 0.0:
		invuln -= dt
		_sprite.visible = int(_t * 20.0) % 2 == 0
	else:
		_sprite.visible = true
	_sprite.position.y = sin(_t * 4.0)
	queue_redraw()

func _draw() -> void:
	var yt := G.tex("yinyang")
	for o in orbs:
		draw_texture(yt, (o[0] - position - yt.get_size() / 2.0))
	var dt_ := G.tex("doll")
	for d in dolls:
		draw_texture(dt_, (d - position - dt_.get_size() / 2.0))
