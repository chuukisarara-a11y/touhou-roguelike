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
	# 外观与机制
	var tex := ""
	var anim := false
	var tint := Color.WHITE
	var scale := 1.0
	var mech := ""
	var owner = null      # 使魔所属的本体
	var ang := 0.0
	var shield_n := 0     # 还活着的使魔数量
	var armor := false    # 被护卫型敌人保护中
	var split_lv := 0
	var vel := Vector2.ZERO

	func hurt(d: float, battle) -> void:
		if dead or pause > 0.0:
			return
		if mech == "shield" and shield_n > 0:
			flash = 0.03
			return
		if armor:
			d *= 0.35
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

func spawn(kind: String, move: Dictionary, hp_mult: float, opts := {}) -> Enemy:
	var e := Enemy.new()
	var d: Dictionary = Db.ENEMIES[kind]
	e.id = _next_id; _next_id += 1
	e.kind = kind; e.def = d
	e.radius = d.r; e.coins = d.coins
	e.move = move
	e.atk_t = randf_range(0.5, 1.3)
	e.tex = d.tex
	e.anim = d.get("anim", false)
	if e.tex.begins_with("@"):   # 借用本章杂鱼的外观
		var mk: String = G.chap(G.run.chapter).mobs[int(e.tex.substr(1))]
		e.tex = Db.ENEMIES[mk].tex
		e.anim = Db.ENEMIES[mk].get("anim", false)
	e.tint = d.get("tint", Color.WHITE)
	e.mech = d.get("mech", "")
	e.split_lv = opts.get("split_lv", 2 if e.mech == "split" else 0)
	e.scale = opts.get("scale", d.get("scale", 1.0))
	e.radius *= e.scale / d.get("scale", 1.0)
	e.max_hp = d.hp * hp_mult * G.DIFF_HP * opts.get("hp_k", 1.0); e.hp = e.max_hp
	match move.type:
		"hover", "mirror":
			e.pos = Vector2(move.tx + randf_range(-20, 20), -12)
			e.stay = move.get("stay", 8.0)
		"orbit":
			e.owner = move.owner
			e.ang = move.ang
			e.pos = e.owner.pos
		"drift":
			e.pos = move.pos
			e.vel = move.vel
		"run":
			e.pos = Vector2(-12.0 if move.dir > 0 else G.FIELD_W + 12.0, move.y)
		"chase":
			e.pos = Vector2(move.x0, -10)
			e.vel = Vector2(0, 40)
		_:
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
	# 护盾（数使魔）与护卫（附近敌人减伤）
	for e in list:
		e.armor = false
		e.shield_n = 0
	for e in list:
		if e.dead:
			continue
		if e.owner != null and not e.owner.dead:
			e.owner.shield_n += 1
		if e.mech == "guard":
			for o in list:
				if o != e and not o.dead and not o.is_boss and o.pos.distance_squared_to(e.pos) < 56.0 * 56.0:
					o.armor = true
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
			_tick_boss(e, battle.ts_real if battle.timestop > 0.0 else edt, battle)
		else:
			_tick_mob(e, edt, h, battle)
		if battle.state == "play" and e.pos.distance_squared_to(pp) < (e.radius + 2.0) * (e.radius + 2.0):
			battle.player_hit()
	list = list.filter(func(e): return not e.dead and not e.gone)
	queue_redraw()

func _tick_mob(e: Enemy, dt: float, h: float, battle) -> void:
	var can_shoot := false
	var pp: Vector2 = battle.player.position
	match e.move.type:
		"orbit":   # 绕着本体转的使魔
			if e.owner == null or e.owner.dead or e.owner.gone:
				e.gone = true
				return
			e.pos = e.owner.pos + Vector2.from_angle(e.ang + e.t * 1.7) * e.move.r
			can_shoot = true
		"drift":   # 分裂出来的碎片：往下飘
			e.vel.y = minf(e.vel.y + 30.0 * dt, 70.0)
			e.vel.x = move_toward(e.vel.x, 0.0, 40.0 * dt)
			e.pos += e.vel * dt
			if e.pos.y > h + 16:
				e.gone = true
		"chase":   # 自爆型：追着自机飞，靠近就爆炸
			var want: Vector2 = (pp - e.pos).normalized() * 52.0
			e.vel = e.vel.move_toward(want, 45.0 * dt)
			e.pos += e.vel * dt
			if e.pos.distance_to(pp) < 24.0 and battle.state == "play":
				e.dead = true
				battle.on_enemy_killed(e)
				return
			if e.t > 14.0:
				e.gone = true
		"run":     # 逃跑型：横穿屏幕，不攻击
			e.pos.x += e.move.dir * 62.0 * dt
			e.pos.y = e.move.y + sin(e.t * 3.0) * 10.0
			if e.pos.x < -16 or e.pos.x > G.FIELD_W + 16:
				e.gone = true
		"mirror":  # 镜像型：总是待在自机的左右镜像位置
			if e.mphase == 0:
				e.pos = e.pos.move_toward(Vector2(e.move.tx, e.move.ty), 80.0 * dt)
				if e.pos.y >= e.move.ty - 1.0:
					e.mphase = 1
			else:
				e.pos.x = move_toward(e.pos.x, G.FIELD_W - pp.x, 70.0 * dt)
				e.stay -= dt
				can_shoot = true
				if e.stay <= 0.0:
					e.pos.y -= 60.0 * dt
					if e.pos.y < -14:
						e.gone = true
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
	elif e.move.type == "swoop":
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
		var tn: String = e.tex if not e.is_boss else e.def.tex
		if (e.anim if not e.is_boss else e.def.get("anim", false)):
			tn += "_%d" % (int(e.t * 5.0) % 2)
		var t: Texture2D = G.tex(tn)
		var sz: Vector2 = t.get_size() * e.scale
		var p: Vector2 = (e.pos - sz / 2.0)
		if e.is_boss:
			p.y += sin(e.t * 2.5) * 2.0
		# 机制提示
		if e.mech == "shield" and e.shield_n > 0:
			draw_arc(e.pos, e.radius + 6.0, 0, TAU, 28, Color(0.75, 0.55, 1.0, 0.75), 1.5)
			draw_circle(e.pos, e.radius + 6.0, Color(0.6, 0.4, 1.0, 0.12))
		if e.mech == "guard":
			draw_arc(e.pos, 56.0, 0, TAU, 40, Color(1.0, 0.85, 0.4, 0.25), 1.0)
		if e.armor:
			draw_arc(e.pos, e.radius + 3.0, 0, TAU, 20, Color(1.0, 0.85, 0.4, 0.8), 1.0)
		if e.mech == "bomber":
			draw_circle(e.pos, e.radius + 2.0 + sin(e.t * 12.0) * 1.5, Color(1, 0.3, 0.3, 0.25))
		var c: Color = e.tint
		if e.flash > 0.0:
			c = Color(4, 4, 4)
		elif e.burn_t > 0.0:
			c = Color(1.6, 1.0, 0.7)
		elif e.slow_t > 0.0:
			c = Color(0.7, 1.0, 1.7)
		if e.is_boss and e.pause > 0.0 and int(e.pause * 12.0) % 2 == 0:
			c.a = 0.5
		draw_texture_rect(t, Rect2(p, sz), false, c)
		if not e.is_boss and e.hp < e.max_hp:
			var w := 14.0
			draw_rect(Rect2(e.pos.x - w / 2, p.y - 3, w, 2), Color(0.1, 0.1, 0.15))
			draw_rect(Rect2(e.pos.x - w / 2, p.y - 3, w * maxf(e.hp, 0) / e.max_hp, 2), Color(1, 0.35, 0.4))
