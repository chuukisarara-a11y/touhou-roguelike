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
var beams := []         # 本帧要画的射线：[起点, 角度, 宽度, 剩余时间, 颜色]
var fams := []          # 使魔：[pos, eat_cd]
var fam_cd := 0.0
var speed_s := 99.0     # 平滑后的移动速度
var focus_t := 0.0
var guard := false      # 「不动明王」的护盾
var guard_cd := 0.0
var trail_cd := 0.0
var sat_cd := 0.0

var _sprite: Sprite2D
var _hit: Sprite2D
var _t := 0.0

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = G.tex("c_" + G.run.char)
	add_child(_sprite)
	_hit = Sprite2D.new()
	_hit.texture = G.tex("hitbox")
	add_child(_hit)
	for w in G.run.weapons:
		w.cd = 0.0

func graze_radius() -> float:
	return GRAZE_RADIUS * (1.5 if G.has("gohei") else 1.0) * (2.0 if G.has("razor") else 1.0) * (1.5 if (G.has("slow_graze") and G.focus_on) else 1.0)

func tick(dt: float, real_dt: float, battle) -> void:
	_t += dt
	if battle.state == "lost":
		visible = false
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	focused = Input.is_action_pressed("slow")
	var sm: float = G.speed_mult() * (0.5 if (battle.spark_t > 0.0 and not G.has("m_comet")) else 1.0)
	var sp := (SLOW_SPEED if focused else SPEED) * sm
	var before := position
	position += v * sp * real_dt + touch_delta * sm
	touch_delta = Vector2.ZERO
	position.x = clampf(position.x, 7.0, G.FIELD_W - 7.0)
	position.y = clampf(position.y, 12.0, battle.field_h - 12.0)
	# 专注状态：移动得很慢（或按住低速键）
	if real_dt > 0.0:
		speed_s = lerpf(speed_s, position.distance_to(before) / real_dt, minf(1.0, real_dt * 10.0))
	G.focus_on = focused or speed_s < 38.0
	focus_t = focus_t + dt if G.focus_on else 0.0
	guard_cd -= dt
	if G.has("slow_shield") and not guard and guard_cd <= 0.0 and focus_t >= 2.0:
		guard = true
		Au.sfx("heal", -4.0)
	# 使魔（位置与射击由 FamSys 处理）
	var nf := G.familiar_count()
	while fams.size() < nf:
		fams.append([position, 0.0])
	orb_ang += dt * 3.5
	# 魔理沙：星屑轨迹 / 卫星幻觉
	trail_cd -= dt
	if G.has("m_star_trail") and speed_s > 60.0 and trail_cd <= 0.0 and battle.state == "play":
		trail_cd = 0.1
		battle.shots.spawn("star", position + Vector2(0, 6), Vector2(0, 0.01), 7.0 * G.dmg_mult(), {"pierce": 99, "life": 1.0})
	if G.has("m_orbit") and battle.state == "play":
		sat_cd -= dt
		if sat_cd <= 0.0:
			sat_cd = 0.8
			for i in 4:
				battle.shots.spawn("star", position + Vector2.from_angle(orb_ang * 0.8 + TAU * i / 4.0) * 20.0, Vector2(0, -240.0), 4.0 * G.dmg_mult())
	# 人偶
	if G.weapon("doll") != null:
		dolls = [position + Vector2(-17, 5), position + Vector2(17, 5)]
	# 射击
	laser_t -= dt
	for bm in beams:
		bm[3] -= dt
	beams = beams.filter(func(bm): return bm[3] > 0.0)
	if battle.state == "play" and not G.has("reflect"):
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
	if G.has("m_orbit"):
		var st := G.tex("star")
		for i in 4:
			draw_texture(st, Vector2.from_angle(orb_ang * 0.8 + TAU * i / 4.0) * 20.0 - st.get_size() / 2.0)
	if G.focus_on:
		draw_arc(Vector2.ZERO, 7.0, 0, TAU, 20, Color(1, 1, 1, 0.35), 1.0)
	if guard:
		draw_arc(Vector2.ZERO, 11.0, 0, TAU, 24, Color(0.5, 0.95, 1.0, 0.9), 1.5)
	var ft := G.tex("doll")
	for fm in fams.slice(0, G.familiar_count()):
		draw_texture(ft, (fm[0] - position - ft.get_size() / 2.0), Color(1.0, 0.8, 1.0))
	var dt_ := G.tex("doll")
	for d in dolls:
		draw_texture(dt_, (d - position - dt_.get_size() / 2.0))
