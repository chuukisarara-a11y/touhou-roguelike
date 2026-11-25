class_name FamSys
extends Node2D
## 攻符系列的独特机制（每场战斗一个）：
##  阴阳玉：绕身的球 + 消弹计数 → 三段子技能
##  封魔针：保持专注叠「集中」
##  镭射：持续命中叠「过热」
##  星屑：移动距离 → 流星雨；星图按造成的伤害计数
##  使魔：跟随 / 原地切换、汇合特效、跟着放符卡
##  御柱：留在场上的墙，挡下敌弹给符卡充能
##  境界裂隙：命中计数 → 黑洞吸弹再射回去

var b   # 所在的战斗
var t := 0.0

# 阴阳玉
var orbs := []        # 每颗：{pos, r, dmg, cd, hit_cd, kind, state, tgt, rt}
var orb_ang := 0.0
var yy_cnt := 0
var yy_after := 0.0   # 子技能之后的余韵（梦想妙珠 / 阴阳反转）
var yy_seq := -1.0    # 子技能进行中：从 0 开始计时
var yy_stage := 0
# 封魔针
var nd_acc := 0.0
var nd_stack := 0
var nd_mount_cd := 0.0
# 镭射
var heat := 0.0
var heat_hit := false
var vent_cd := 0.0
# 星屑
var st_dist := 0.0
var sm_acc := 0.0
var tail_cd := 0.0
var _last_pos := Vector2.ZERO
# 使魔
var fam_stay := false
var fam_anchor := []
var fam_return := false
var fam_bomb_t := 0.0
var fam_cds := []
# 御柱
var walls := []       # {rect, life, max, kind, mult, dps}
var side_cd := 1.5
var rope_cd := 2.0
# 境界裂隙
var rf_hits := 0
var hole := {}        # {pos, t, absorbed}

func setup(battle) -> void:
	b = battle
	_last_pos = b.player.position

func yy_need() -> int:
	var n := 28 if G.has("yy_gate") else 40
	return n - (6 if G.run.char == "reimu" else 0)

func rf_need() -> int:
	return int(60 * (0.75 if G.has("rf_epic") else 1.0))

func sm_need() -> float:
	var w = G.weapon("starmap")
	return 260.0 * pow(1.55, G.run.chapter - 1) * (0.65 if (w != null and G.br("starmap") == 0) else 1.0)

func st_need() -> float:
	return 900.0 * (0.65 if G.has("st_grav") else 1.0)

# ---------------------------------------------------------------- 每帧
func tick(dt: float) -> void:
	t += dt
	var p: Player = b.player
	var play: bool = b.state == "play"
	_tick_orbs(dt, play)
	if yy_seq >= 0.0:
		_tick_yy_skill(dt)
	yy_after -= dt
	# 封魔针：专注叠集中
	if G.has_fam("needle"):
		if G.focus_on:
			nd_acc = minf(5.0, nd_acc + dt * (1.6 if G.has("nd_fast") else 1.0))
		elif p.speed_s > 60.0:
			nd_acc = 0.0
		nd_stack = int(nd_acc)
		G.nd_full = nd_stack >= 5
		if G.has("nd_mount") and nd_stack >= 5 and play:
			nd_mount_cd -= dt
			if nd_mount_cd <= 0.0:
				nd_mount_cd = 2.0
				for i in 12:
					b.shots.spawn("needle", p.position, Vector2.from_angle(TAU * i / 12.0) * 260.0, 5.0 * G.dmg_mult(), {"rot": true})
	else:
		G.nd_full = false
	# 镭射：过热
	if heat_hit:
		heat = minf(3.0, heat + dt * (2.0 if G.run.char == "marisa" else 1.0))
	else:
		heat = maxf(0.0, heat - dt * (0.75 if G.has("ls_keep") else 1.5))
	heat_hit = false
	vent_cd -= dt
	if G.has("ls_vent") and heat >= 3.0 and vent_cd <= 0.0 and play and b.spark_t <= 0.0:
		vent_cd = 6.0
		b.spark_t = 1.0
		b.spark_w = 12.0
		b.spark_dps = 70.0 * G.dmg_mult()
	# 星屑：移动距离 → 流星雨
	var moved := p.position.distance_to(_last_pos)
	_last_pos = p.position
	if G.has_fam("star") and play:
		st_dist += moved
		if st_dist >= st_need():
			st_dist = 0.0
			meteor(6 * (2 if G.has("st_big") else 1), G.has("st_big"))
	var tw = G.weapon("star_tail")
	if tw != null and play:
		tail_cd -= dt
		if p.speed_s > 50.0 and tail_cd <= 0.0:
			tail_cd = 0.07
			var big: bool = tw.lv >= 2
			b.shots.spawn("star", p.position + Vector2(0, 6), Vector2(0, -60.0) if G.br("star_tail") == 1 else Vector2(0, 0.01),
				(6.0 if big else 4.0) * G.dmg_mult(), {"pierce": 99, "life": 2.0 if G.br("star_tail") == 0 else 1.0, "radius": 5.0 if big else 4.0})
	# 使魔
	_tick_familiars(dt, play)
	# 御柱：墙
	_tick_walls(dt, play)
	# 境界裂隙：黑洞
	if not hole.is_empty():
		_tick_hole(dt)
	queue_redraw()

# ---------------------------------------------------------------- 阴阳玉
func _orb_specs() -> Array:
	var out := []
	var w = G.weapon("yinyang")
	if w != null:
		var n: int = [0, 1, 2, 2][w.lv] + (1 if G.br("yinyang") == 0 else 0)
		for i in n:
			out.append({"kind": "yy", "r": 9.0 if G.br("yinyang") == 1 else 6.0, "dmg": 10.0, "orbit": 22.0, "spd": 3.5})
	var wb = G.weapon("yinyang_big")
	if wb != null:
		var r: float = 11.0 * (1.4 if G.br("yinyang_big") == 1 else 1.0)
		out.append({"kind": "big", "r": r, "dmg": 14.0 * (1.6 if wb.lv >= 2 else 1.0) * (2.0 if G.br("yinyang_big") == 0 else 1.0), "orbit": 28.0, "spd": 2.0})
	var wm = G.weapon("yinyang_meteor")
	if wm != null:
		for i in (2 if G.br("yinyang_meteor") == 0 else 1):
			out.append({"kind": "met", "r": 6.0, "dmg": 30.0, "orbit": 22.0, "spd": 3.5, "every": 3.0 if wm.lv < 2 else 2.0})
	return out

func _tick_orbs(dt: float, play: bool) -> void:
	var specs := _orb_specs()
	while orbs.size() < specs.size():
		orbs.append({"pos": b.player.position, "cd": 0.0, "hit_cd": 0.0, "state": 0, "rt": 1.0 + orbs.size() * 0.7})
	orbs.resize(specs.size())
	var spin := 2.0 if (G.has("yy_spin") and yy_after > 0.0) else 1.0
	orb_ang += dt * spin
	var pp: Vector2 = b.player.position
	var m: float = G.dmg_mult()
	for i in orbs.size():
		var o: Dictionary = orbs[i]
		var sp: Dictionary = specs[i]
		o.merge(sp, true)
		var home: Vector2 = pp + Vector2.from_angle(orb_ang * sp.spd + TAU * i / orbs.size()) * sp.orbit
		# 流星玉：定时脱离轨道砸向敌人
		if sp.kind == "met":
			match o.state:
				0:
					o.pos = home
					o.rt -= dt
					if o.rt <= 0.0 and play:
						var tg = b.shots.nearest(o.pos, b.enemies.list)
						if tg != null:
							o.tgt = tg
							o.state = 1
				1:
					var tg2 = o.get("tgt")
					if tg2 == null or tg2.dead or tg2.gone:
						o.state = 2
					else:
						o.pos = o.pos.move_toward(tg2.pos, 300.0 * dt)
						if o.pos.distance_to(tg2.pos) < tg2.radius + o.r:
							tg2.hurt(o.dmg * m, b)
							b.fx.burst(o.pos, Color(1, 0.5, 0.5), 12, 24.0)
							b.shake = maxf(b.shake, 0.08)
							if G.br("yinyang_meteor") == 1:   # 爆裂
								for en in b.enemies.list:
									if not en.dead and en.pos.distance_to(o.pos) < 32.0:
										en.hurt(18.0 * m, b)
								b.bullets.clear_near(o.pos, 30.0, b.fx)
							o.state = 2
				2:
					o.pos = o.pos.move_toward(home, 260.0 * dt)
					if o.pos.distance_to(home) < 3.0:
						o.state = 0
						o.rt = sp.every
		else:
			o.pos = home
		# 撞击敌人
		o.hit_cd -= dt
		if o.hit_cd <= 0.0 and play:
			for en in b.enemies.list:
				if not en.dead and en.pos.distance_squared_to(o.pos) < (en.radius + o.r) * (en.radius + o.r):
					en.hurt((o.dmg if sp.kind != "met" else 10.0) * m, b)
					b.fx.spark(o.pos)
					o.hit_cd = 0.25
		# 消弹
		o.cd -= dt
		if o.cd <= 0.0:
			var reach: float = o.r - 1.0 + (6.0 if sp.kind == "big" and G.br("yinyang_big") == 1 else 0.0)
			for bl in b.bullets.list:
				if not bl.dead and bl.pos.distance_squared_to(o.pos) < (bl.r + reach) * (bl.r + reach):
					bl.dead = true
					b.bullets._van(bl)
					o.cd = 0.0 if (G.has("yy_spin") and yy_after > 0.0) else (0.15 if sp.kind == "big" else 0.3)
					_on_orb_clear(bl.pos)
					break

func _on_orb_clear(pos: Vector2) -> void:
	b.fx.spark(pos, Color(1, 0.75, 0.7))
	b.fx.burst(pos, Color(1, 1, 1), 4, 10.0)
	Au.sfx("graze", -8.0, 0.0, 1.0 + minf(1.0, yy_cnt / float(yy_need())) * 0.8)   # 越接近门槛音越高
	if G.has("yy_p") and randf() < 0.06:
		b.items.drop_power(pos, 1)
	if G.has("yy_epic") and yy_after > 0.0:
		b.on_graze(pos)
	if yy_seq < 0.0:
		yy_cnt += 1
		if yy_cnt >= yy_need() and b.state == "play":
			yy_cnt = 0
			yy_seq = 0.0
			yy_stage = 0

## 三段子技能：① 身边消弹 + 冲击波 → ② 大球横扫一圈 → ③ 炸开成小阴阳玉弹向敌人
func _tick_yy_skill(dt: float) -> void:
	var pp: Vector2 = b.player.position
	var m: float = G.dmg_mult()
	yy_seq += dt
	if yy_stage == 0:
		yy_stage = 1
		b.player.invuln = maxf(b.player.invuln, 0.3)
		b.bullets.clear_near(pp, 46.0, b.fx)
		for en in b.enemies.list:
			if not en.dead and en.pos.distance_to(pp) < 64.0:
				en.hurt(30.0 * m, b)
		b.fx.burst(pp, Color(1, 0.6, 0.6), 24, 46.0)
		b.shake = maxf(b.shake, 0.12)
		Au.sfx("bomb", -6.0)
		b.fx.text(pp + Vector2(0, -22), "阴阳玉！", Color(1, 0.8, 0.8))
	elif yy_stage == 1 and yy_seq >= 0.2:
		yy_stage = 2
		for en in b.enemies.list:
			if not en.dead and en.pos.distance_to(pp) < 60.0:
				en.hurt(50.0 * m, b)
		b.bullets.clear_near(pp, 58.0, b.fx)
		b.shake = maxf(b.shake, 0.15)
		Au.sfx("phase", -6.0)
	elif yy_stage == 2 and yy_seq >= 0.4:
		yy_stage = 3
		var n := 8 * (2 if G.has("yy_split") else 1)
		for i in n:
			b.shots.spawn("orb", pp, Vector2.from_angle(TAU * i / n) * 170.0, 16.0 * m, {"homing": 8.0, "pierce": 1, "radius": 5.0, "life": 3.0})
		b.fx.burst(pp, Color(1, 0.9, 0.9), 30, 60.0)
		Au.sfx("bomb", -8.0)
	elif yy_seq >= 0.75:
		yy_seq = -1.0
		yy_after = 5.0

# ---------------------------------------------------------------- 镭射：射线
## 从 from 沿 ang 发出的射线，宽 width，打到的敌人受到伤害；返回是否打中
func beam(from: Vector2, ang: float, width: float, dmg: float, col := Color(0.9, 1.0, 1.0), fam_laser := true) -> bool:
	var dir := Vector2.from_angle(ang)
	var hit := false
	for e in b.enemies.list:
		if e.dead:
			continue
		var rel: Vector2 = e.pos - from
		var along := rel.dot(dir)
		if along <= 0.0:
			continue
		if absf(rel.cross(dir)) < width / 2.0 + e.radius:
			e.hurt(dmg, b)
			hit = true
			if randf() < 0.25:
				b.fx.spark(from + dir * along, Color(0.7, 0.95, 1))
	b.player.beams.append([from, ang, width, 0.12, col])
	if hit and fam_laser:
		heat_hit = true
	return hit

func heat_mult() -> float:
	return 1.0 + heat * 0.25

# ---------------------------------------------------------------- 星屑
func meteor(n: int, pierce_all := false) -> void:
	for i in n:
		var s = b.shots.spawn("star", Vector2(randf_range(10, G.FIELD_W - 10), -10 - i * 8.0), Vector2(randf_range(-25, 25), 240.0), 14.0 * G.dmg_mult(), {"pierce": 99 if pierce_all else 3, "radius": 6.0})
		if G.br("starmap") == 1:
			s.split_mod = true

func on_dealt(d: float) -> void:
	var w = G.weapon("starmap")
	if w == null or b.state != "play":
		return
	sm_acc += d
	if sm_acc >= sm_need():
		sm_acc = 0.0
		meteor(6 if w.lv < 2 else 12)
		b.fx.text(b.player.position + Vector2(0, -22), "流星雨", Color(1, 1, 0.6))

# ---------------------------------------------------------------- 使魔
func toggle_familiars() -> void:
	fam_stay = not fam_stay
	var p: Player = b.player
	if fam_stay:
		fam_anchor = p.fams.map(func(f): return f[0])
		b.fx.text(p.position + Vector2(0, -22), "原地输出", Color(1, 0.85, 1))
	else:
		fam_return = true
		b.fx.text(p.position + Vector2(0, -22), "跟随", Color(1, 0.85, 1))
	Au.sfx("click")

## 使魔的位置（跟随时绕着自机，原地时停在放下的地方）
func familiar_target(i: int, n: int) -> Vector2:
	var p: Player = b.player
	var orbit: Vector2 = Vector2.from_angle(-p.orb_ang * 0.45 + TAU * i / maxf(n, 1)) * 30.0
	if fam_stay and i < fam_anchor.size():
		return fam_anchor[i] + orbit * 0.15
	return p.position + orbit

func _tick_familiars(dt: float, play: bool) -> void:
	var p: Player = b.player
	var n := G.familiar_count()
	if n <= 0:
		return
	if fam_stay:
		while fam_anchor.size() < n:
			fam_anchor.append(p.position)
	var all_home := true
	for i in mini(n, p.fams.size()):
		var tg := familiar_target(i, n)
		if fam_return:
			p.fams[i][0] = p.fams[i][0].move_toward(tg, 320.0 * dt)
			if p.fams[i][0].distance_to(tg) > 4.0:
				all_home = false
		else:
			p.fams[i][0] = tg
	if fam_return and all_home:   # 汇合的一瞬间
		fam_return = false
		b.fx.burst(p.position, Color(1, 0.8, 1.0), 20, 34.0)
		b.fx.burst(p.position, Color(1, 1, 1), 8, 16.0)
		Au.sfx("select", -4.0)
		if G.has("fm_home"):
			b.bullets.clear_near(p.position, 42.0, b.fx)
	# 射击
	while fam_cds.size() < n:
		fam_cds.append(randf() * 0.3)
	fam_bomb_t -= dt
	if not play:
		return
	var m: float = G.familiar_dmg() * (1.0 + 0.1 * G.run.power + 0.05 * G.spirit_lv) * (1.5 if (fam_stay and G.has("fm_array")) else 1.0)
	var fw = G.weapon("familiar")
	var copy_id: String = fw.get("copy", "") if (fw != null and G.br("familiar") == 1) else ""
	for i in mini(n, p.fams.size()):
		var fp: Vector2 = p.fams[i][0]
		if fam_bomb_t > 0.0:   # 跟着自机放削弱版符卡
			if G.run.char == "marisa":
				beam(fp, -PI / 2.0, 9.0, m * 0.9, Color(1, 0.95, 0.7), false)
		fam_cds[i] -= dt
		if fam_cds[i] > 0.0:
			continue
		if copy_id != "" and G.weapon(copy_id) != null:
			var cw: Dictionary = G.weapon(copy_id).duplicate()
			fam_cds[i] = Weapons.fire_at(cw, p, b, fp, 0.4 * m / 5.0) * 1.2
		elif G.run.char == "marisa":   # 初始攻击的削弱版：细镭射
			beam(fp, -PI / 2.0, 2.0, m * 0.45, Color(1, 0.95, 0.8), false)
			fam_cds[i] = 0.1
		else:   # 灵梦：小追踪符札
			var tg = b.shots.nearest(fp, b.enemies.list)
			var dir: Vector2 = Vector2.UP if tg == null else (tg.pos - fp).normalized()
			b.shots.spawn("amulet", fp, dir * 200.0, m * 0.8, {"homing": 7.0, "rot": true})
			fam_cds[i] = 0.4 / (2.0 if G.has("puppeteer") else 1.0)

func on_bomb(k: int) -> void:
	var p: Player = b.player
	var n := mini(G.familiar_count(), p.fams.size())
	if n <= 0:
		return
	if G.run.char == "marisa":
		fam_bomb_t = 0.8 + 0.4 * k
	else:
		var m: float = G.familiar_dmg() * 4.0 * G.dmg_mult()
		for i in n:
			for j in 3:
				b.shots.spawn("orb", p.fams[i][0], Vector2.from_angle(TAU * j / 3.0 + i) * 160.0, m, {"homing": 7.0, "pierce": 1, "radius": 4.0, "life": 2.5})

# ---------------------------------------------------------------- 御柱：墙
func add_wall(rect: Rect2, kind: String, life := 3.0, mult := 1.0, dps := 0.0) -> void:
	var l := life * (2.0 if G.has("pl_castle") else 1.0)
	walls.append({"rect": rect, "life": l, "max": l, "kind": kind, "mult": mult, "dps": dps})

func pillar_land(x: float, y: float, hw: float) -> void:
	add_wall(Rect2(x - hw, y - 30.0, hw * 2.0, 90.0), "pillar")
	if G.has("pl_quake"):
		var c := Vector2(x, y + 15.0)
		for en in b.enemies.list:
			if not en.dead and en.pos.distance_to(c) < 50.0:
				en.hurt(20.0 * G.dmg_mult(), b)
		b.bullets.clear_near(c, 36.0, b.fx)
		b.fx.burst(c, Color(1, 0.85, 0.5), 16, 40.0)

func _tick_walls(dt: float, play: bool) -> void:
	var m: float = G.dmg_mult() * (1.4 if G.has("pl_yasaka") else 1.0)
	# 横扫御柱
	var ws = G.weapon("pillar_side")
	if ws != null and play:
		side_cd -= dt
		if side_cd <= 0.0:
			side_cd = 3.5
			var alive: Array = b.enemies.list.filter(func(e): return not e.dead and e.pos.y > 0)
			for k in (2 if G.br("pillar_side") == 0 else 1):
				if alive.is_empty():
					break
				var e = alive[randi() % alive.size()]
				var hl := 40.0 * (1.5 if G.br("pillar_side") == 1 else 1.0)
				var r := Rect2(clampf(e.pos.x - hl, 0, G.FIELD_W - hl * 2), e.pos.y + 18.0, hl * 2.0, 10.0)
				for en in b.enemies.list:
					if not en.dead and r.grow(12.0).has_point(en.pos):
						en.hurt(36.0 * m * (1.6 if ws.lv >= 2 else 1.0), b)
				add_wall(r, "beam")
				b.shake = maxf(b.shake, 0.1)
				Au.sfx("hit", -2.0)
	# 注连绳
	var wr = G.weapon("shimenawa")
	if wr != null and play:
		rope_cd -= dt
		if rope_cd <= 0.0:
			rope_cd = 4.0
			var tg = b.shots.nearest(b.player.position, b.enemies.list)
			if tg != null:
				var y: float = tg.pos.y + 10.0
				var dps: float = 14.0 * (1.6 if wr.lv >= 2 else 1.0) * (2.0 if G.br("shimenawa") == 0 else 1.0)
				add_wall(Rect2(clampf(tg.pos.x - 36.0, 0, G.FIELD_W - 72.0), y - 2.0, 72.0, 5.0), "rope", 3.0, 3.0 if G.br("shimenawa") == 1 else 1.0, dps)
	# 挡弹 + 注连绳的持续伤害
	var charge := 0.004 * (2.0 if G.has("pl_yasaka") else 1.0)
	for w in walls:
		w.life -= dt
		var r: Rect2 = w.rect
		for bl in b.bullets.list:
			if not bl.dead and r.has_point(bl.pos):
				bl.dead = true
				b.bullets._van(bl)
				b.add_bomb(charge * w.mult)
				if G.has("pl_epic"):
					b.shots.spawn("orb", bl.pos, Vector2(0, -150.0), 4.0 * G.dmg_mult(), {"homing": 9.0, "radius": 3.0, "life": 2.0})
		if w.dps > 0.0:
			for en in b.enemies.list:
				if not en.dead and r.grow(10.0).has_point(en.pos):
					en.hurt(w.dps * m * dt, b)
	walls = walls.filter(func(w): return w.life > 0.0)

# ---------------------------------------------------------------- 境界裂隙：黑洞
func on_rift_hit() -> void:
	if not hole.is_empty() or b.state != "play":
		return
	rf_hits += 1
	if rf_hits >= rf_need():
		rf_hits = 0
		var pos: Vector2 = b.player.position + Vector2(0, -60)
		pos.y = maxf(pos.y, 40.0)
		hole = {"pos": pos, "t": 2.2, "absorbed": 0}
		b.fx.text(pos + Vector2(0, -20), "黑洞", Color(0.85, 0.6, 1.0))
		Au.sfx("phase", -4.0)

func _tick_hole(dt: float) -> void:
	hole.t -= dt
	var rad := 62.0 * (1.5 if G.has("rf_range") else 1.0)
	var c: Vector2 = hole.pos
	if G.has("rf_epic"):
		b.player.invuln = maxf(b.player.invuln, 0.1)
	for bl in b.bullets.list:
		if bl.dead:
			continue
		var d: float = bl.pos.distance_to(c)
		if d < rad:
			bl.pos = bl.pos.move_toward(c, (90.0 + (rad - d) * 3.0) * dt)
			bl.vel *= 0.9
			if bl.pos.distance_to(c) < 7.0:
				bl.dead = true
				hole.absorbed += 1
	if hole.t <= 0.0:
		var n := clampi(hole.absorbed / 2, 6, 30) * (2 if G.has("rf_quad") else 1)
		for i in n:
			b.shots.spawn("gapshot", c, Vector2.from_angle(TAU * i / n) * 180.0, 6.0 * G.dmg_mult(), {"homing": 9.0, "rot": true, "life": 2.5})
		b.fx.burst(c, Color(0.8, 0.5, 1.0), 30, 50.0)
		Au.sfx("bomb", -6.0)
		hole = {}

# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	var yt := G.tex("yinyang")
	for o in orbs:
		var s: float = o.get("r", 6.0) / 6.0
		var sz := yt.get_size() * s
		draw_texture_rect(yt, Rect2(o.pos - sz / 2.0, sz), false)
	if yy_seq >= 0.0 and yy_stage >= 2:   # 子技能第二段：大球横扫
		var a: float = yy_seq * 18.0
		var c: Vector2 = b.player.position + Vector2.from_angle(a) * 40.0
		var sz2 := yt.get_size() * 3.0
		draw_texture_rect(yt, Rect2(c - sz2 / 2.0, sz2), false, Color(1, 1, 1, 0.9))
		draw_arc(b.player.position, 58.0, 0, TAU, 40, Color(1, 0.7, 0.7, 0.5), 2.0)
	for w in walls:
		var r: Rect2 = w.rect
		var a2: float = clampf(w.life / 0.4, 0.0, 1.0)
		match w.kind:
			"pillar":
				draw_rect(r, Color(0.62, 0.38, 0.2, 0.85 * a2))
				draw_rect(Rect2(r.position.x, r.position.y + 8, r.size.x, 3), Color(0.95, 0.9, 0.75, 0.9 * a2))
				draw_rect(Rect2(r.position.x + 1, r.position.y, 2, r.size.y), Color(0.85, 0.6, 0.35, 0.8 * a2))
			"beam":
				draw_rect(r, Color(0.62, 0.38, 0.2, 0.85 * a2))
				draw_rect(Rect2(r.position.x + r.size.x / 2 - 2, r.position.y, 4, r.size.y), Color(0.95, 0.9, 0.75, 0.9 * a2))
			"rope":
				draw_rect(Rect2(r.position.x - 3, r.position.y - 10, 5, 16), Color(0.62, 0.38, 0.2, 0.9 * a2))
				draw_rect(Rect2(r.end.x - 2, r.position.y - 10, 5, 16), Color(0.62, 0.38, 0.2, 0.9 * a2))
				draw_line(Vector2(r.position.x, r.position.y + 2), Vector2(r.end.x, r.position.y + 2), Color(0.95, 0.9, 0.75, a2), 2.0)
				for k in 4:
					var x: float = r.position.x + r.size.x * (k + 1) / 5.0
					draw_rect(Rect2(x - 1, r.position.y + 3, 3, 6), Color(1, 1, 1, 0.9 * a2))
	if not hole.is_empty():
		var c2: Vector2 = hole.pos
		var rad := 62.0 * (1.5 if G.has("rf_range") else 1.0)
		draw_circle(c2, 12.0 + sin(t * 9.0) * 1.5, Color(0.05, 0.0, 0.1, 0.95))
		draw_arc(c2, 14.0, t * 4.0, t * 4.0 + PI * 1.4, 20, Color(0.85, 0.5, 1.0), 2.0)
		draw_arc(c2, rad, 0, TAU, 48, Color(0.7, 0.4, 1.0, 0.25), 1.0)
	# 系列计量（左下角）
	var f := G.font
	var y: float = b.field_h - 50.0
	var lines := []
	if not _orb_specs().is_empty():
		lines.append(["阴阳 %d/%d" % [yy_cnt, yy_need()], Color(1, 0.7, 0.7)])
	if G.has_fam("needle"):
		lines.append(["集中 " + "●".repeat(nd_stack) + "○".repeat(5 - nd_stack), Color(0.8, 0.9, 1.0)])
	if G.has_fam("laser") and heat > 0.05:
		lines.append(["过热 %d%%" % int(heat / 3.0 * 100.0), Color(1, 0.75, 0.5)])
	if G.has_fam("star"):
		lines.append(["流星 %d%%" % int(st_dist / st_need() * 100.0), Color(1, 1, 0.6)])
	if G.has_fam("rift"):
		lines.append(["隙间 %d/%d" % [rf_hits, rf_need()], Color(0.85, 0.6, 1.0)])
	for ln in lines:
		draw_string(f, Vector2(4, y), ln[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(ln[1], 0.85))
		y -= 11.0
