class_name EnemyLayer
extends Node2D
## 敌人层：杂鱼与 Boss 的移动、攻击、状态与绘制。

class Enemy:
	var id: int
	var kind := ""
	var def := {}
	var pos: Vector2
	var hp := 1.0
	var max_hp := 1.0
	var radius := 7.0
	var coins := 1
	var flash := 0.0
	var t := 0.0
	var dead := false
	var gone := false
	var move := {}
	var mphase := 0
	var stay := 0.0
	var atk_t := 1.0
	var burn_t := 0.0
	var burn_dps := 0.0
	var slow_t := 0.0
	var steam_cd := 0.0
	var ice_mark := false
	# Boss 专用
	var is_boss := false
	var phases := []
	var phase_i := 0
	var pt := 0.0
	var tm := {}
	var pause := 0.0
	var target: Vector2
	var hp_mult := 1.0

	func hurt(d: float, battle) -> void:
		if dead or pause > 0.0:
			return
		hp -= d
		flash = 0.06
		Au.sfx("hit", -8.0)
		if hp <= 0.0:
			if is_boss and phase_i < phases.size() - 1:
				phase_i += 1
				load_phase()
				battle.on_boss_phase(self)
			else:
				dead = true
				battle.on_enemy_killed(self)

	func load_phase() -> void:
		max_hp = phases[phase_i].hp * hp_mult
		hp = max_hp
		pt = 0.0
		tm.clear()
		pause = 1.2
		burn_t = 0.0

	func phase_name() -> String:
		return phases[phase_i].name

var list := []
var _next_id := 1

func alive() -> int:
	return list.size()

func spawn(kind: String, move: Dictionary, hp_mult: float) -> Enemy:
	var e := Enemy.new()
	var d: Dictionary = Db.ENEMIES[kind]
	e.id = _next_id; _next_id += 1
	e.kind = kind; e.def = d
	e.max_hp = d.hp * hp_mult * G.DIFF_HP; e.hp = e.max_hp
	e.radius = d.r; e.coins = d.coins
	e.move = move
	e.atk_t = randf_range(0.5, 1.3)
	if move.type == "hover":
		e.pos = Vector2(move.tx + randf_range(-20, 20), -12)
		e.stay = move.stay
	else:
		e.pos = Vector2(move.x0, -10)
	list.append(e)
	return e

func spawn_boss(bid: String, hp_mult: float) -> Enemy:
	var e := Enemy.new()
	var d: Dictionary = Db.BOSSES[bid]
	e.id = _next_id; _next_id += 1
	e.kind = bid; e.def = d; e.is_boss = true
	e.radius = d.r; e.coins = d.coins
	e.phases = d.phases; e.hp_mult = hp_mult * G.DIFF_BOSS_HP
	e.pos = Vector2(G.FIELD_W / 2, -20)
	e.target = Vector2(G.FIELD_W / 2, 62)
	e.load_phase()
	e.pause = 1.8
	list.append(e)
	return e

func tick(dt: float, battle) -> void:
	var h: float = battle.field_h
	var pp: Vector2 = battle.player.position
	for e in list:
		if e.dead:
			continue
		e.flash -= dt
		e.steam_cd -= dt
		if e.burn_t > 0.0:
			e.burn_t -= dt
			e.hurt(e.burn_dps * dt, battle)
			e.flash = -1.0
			if e.dead:
				continue
		var edt := dt
		if e.slow_t > 0.0:
			e.slow_t -= dt
			edt *= 0.5
		e.t += edt
		if e.is_boss:
			_tick_boss(e, edt, battle)
		else:
			_tick_mob(e, edt, h, battle)
		if battle.state == "play" and e.pos.distance_squared_to(pp) < (e.radius + 2.0) * (e.radius + 2.0):
			battle.player_hit()
	list = list.filter(func(e): return not e.dead and not e.gone)
	queue_redraw()

func _tick_mob(e: Enemy, dt: float, h: float, battle) -> void:
	var can_shoot := false
	if e.move.type == "hover":
		match e.mphase:
			0:
				e.pos = e.pos.move_toward(Vector2(e.move.tx, e.move.ty), 80.0 * dt)
				if e.pos.distance_to(Vector2(e.move.tx, e.move.ty)) < 1.0:
					e.mphase = 1
			1:
				e.stay -= dt
				e.pos = Vector2(e.move.tx + sin(e.t * 1.3) * 6.0, e.move.ty + sin(e.t * 2.1) * 3.0)
				can_shoot = true
				if e.stay <= 0.0:
					e.mphase = 2
			2:
				e.pos.y -= 50.0 * dt
				if e.pos.y < -14:
					e.gone = true
	else:  # swoop
		e.pos.y += e.move.speed * dt
		e.pos.x = e.move.x0 + sin(e.t * 2.2) * 28.0 * e.move.dir
		can_shoot = e.pos.y > 10 and e.pos.y < h * 0.5
		if e.pos.y > h + 14:
			e.gone = true
	if can_shoot and e.def.atk != "":
		e.atk_t -= dt
		if e.atk_t <= 0.0:
			e.atk_t = e.def.cd / G.DIFF_RATE * randf_range(0.85, 1.15)
			Pat.enemy_attack(e, battle)

func _tick_boss(e: Enemy, dt: float, battle) -> void:
	e.pos = e.pos.move_toward(e.target, 34.0 * dt)
	if e.pause > 0.0:
		e.pause -= dt
		return
	if Pat.every(e, "_mv", 3.6, dt):
		e.target = Vector2(randf_range(45, G.FIELD_W - 45), randf_range(48, 82))
	e.pt += dt
	Pat.boss(e, e.phases[e.phase_i].pat, dt, battle)

func _draw() -> void:
	for e in list:
		var tn: String = e.def.tex
		if e.def.get("anim", false):
			tn += "_%d" % (int(e.t * 5.0) % 2)
		var t: Texture2D = G.tex(tn)
		var p: Vector2 = (e.pos - t.get_size() / 2.0)
		if e.is_boss:
			p.y += sin(e.t * 2.5) * 2.0
		var c := Color.WHITE
		if e.flash > 0.0:
			c = Color(4, 4, 4)
		elif e.burn_t > 0.0:
			c = Color(1.6, 1.0, 0.7)
		elif e.slow_t > 0.0:
			c = Color(0.7, 1.0, 1.7)
		if e.is_boss and e.pause > 0.0 and int(e.pause * 12.0) % 2 == 0:
			c.a = 0.5
		draw_texture(t, p, c)
		if not e.is_boss and e.hp < e.max_hp:
			var w := 14.0
			draw_rect(Rect2(e.pos.x - w / 2, p.y - 3, w, 2), Color(0.1, 0.1, 0.15))
			draw_rect(Rect2(e.pos.x - w / 2, p.y - 3, w * maxf(e.hp, 0) / e.max_hp, 2), Color(1, 0.35, 0.4))
