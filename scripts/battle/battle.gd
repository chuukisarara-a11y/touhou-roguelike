extends Node2D
## 战斗场景：组装各层，处理输入、时间流速、波次推进与胜负。

const SLOW_MAX := 2.0
const SLOW_SCALE := 0.3

var field_h := 356.0
var kind := "battle"
var boss_override := ""
var _paused_ov: CanvasLayer
var bg: Background
var enemies: EnemyLayer
var shots: ShotLayer
var bullets: BulletLayer
var items: ItemLayer
var fx: FxLayer
var player: Player
var hud: Hud

var state := "play"   # play / won / lost
var waves := []
var wave_i := -1
var wave_t := 0.0
var pending := []
var boss = null
var end_t := 0.0
var earned := 0
var hits := 0
var kills := 0
var bullet_slow_t := 0.0
var shake := 0.0
var banner := ""
var banner_t := 0.0
var move_finger := -1
var slow_budget := SLOW_MAX
var slowmo_active := false
var graze_combo := 0
var combo_t := 0.0
var grazes := 0
var spirit := 0
var afterglow_t := 0.0
var counter_cd := 0.0
var phase_clean := true
var defeat_line := ""
var spell_bg: SpellBg
var timestop := 0.0      # 时间停止剩余秒数（咲夜）：期间除 Boss 外一切静止，自机不能动
var ts_real := 0.0
var _ts: ColorRect
var _dim: ColorRect
var _bt := 0.0

func setup(arg: Dictionary) -> void:
	kind = arg.get("kind", "battle")
	boss_override = arg.get("boss", "")

func _ready() -> void:
	field_h = G.field_h()
	bg = Background.new(); add_child(bg); bg.setup(field_h)
	G.spirit_lv = 0
	G.combo = 0
	G.after_t = 0.0
	G.battle_t = 0.0
	slow_budget = slow_max()
	if G.has("bomb_start"):
		add_bomb(0.5)
	if kind == "boss" and G.has("phoenix"):
		G.heal(1)
	spell_bg = SpellBg.new(); spell_bg.battle = self; add_child(spell_bg)
	bg.mode = Db.CHAPTERS[G.run.chapter].bg
	enemies = EnemyLayer.new(); add_child(enemies)
	items = ItemLayer.new(); add_child(items)
	shots = ShotLayer.new(); add_child(shots)
	player = Player.new(); add_child(player)
	player.position = Vector2(G.FIELD_W / 2, field_h - 70)
	bullets = BulletLayer.new(); add_child(bullets)
	fx = FxLayer.new(); add_child(fx)
	_dim = ColorRect.new()
	_dim.color = Color(0.3, 0.5, 1.0, 0.0)
	_dim.size = Vector2(G.FIELD_W, field_h)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_ts = ColorRect.new()
	_ts.color = Color(0.55, 0.5, 0.75, 0.0)
	_ts.size = Vector2(G.FIELD_W, field_h)
	_ts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ts)
	hud = Hud.new(); add_child(hud); hud.setup(self)
	var hp_mult: float = (1.0 + (G.run.floor - 1) * 0.07) * pow(1.55, G.run.chapter - 1)
	waves = Waves.build(G.run.chapter, G.run.floor, kind)
	if boss_override != "":
		waves = [[{"t": 0.0, "boss": boss_override}]]
	set_meta("hp_mult", hp_mult)
	_next_wave()

func _next_wave() -> void:
	wave_i += 1
	wave_t = 0.0
	pending = waves[wave_i].duplicate()

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode in [KEY_ESCAPE, KEY_P]:
		pause()
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			if Rect2(G.FIELD_W - 26, 0, 26, 24).has_point(ev.position):
				pause()
				return
			if hud.bomb_rect.grow(6).has_point(ev.position):
				use_bomb()
			elif move_finger == -1:
				move_finger = ev.index
		elif ev.index == move_finger:
			move_finger = -1
	elif ev is InputEventScreenDrag and ev.index == move_finger:
		player.touch_delta += ev.relative
	elif ev.is_action_pressed("bomb"):
		use_bomb()

func _process(real_dt: float) -> void:
	real_dt = minf(real_dt, 0.05)
	slowmo_active = false
	ts_real = real_dt
	_ts.color.a = move_toward(_ts.color.a, 0.32 if timestop > 0.0 else 0.0, real_dt * 2.5)
	if timestop > 0.0:
		_tick_timestop(real_dt)
		return
	if G.touch_mode and state == "play" and G.meta.settings.slowmo:
		if move_finger == -1 and slow_budget > 0.0:
			slowmo_active = true
			slow_budget -= real_dt
		elif move_finger != -1:
			slow_budget = minf(slow_max(), slow_budget + real_dt * 1.5)
	var dt := real_dt * (SLOW_SCALE if slowmo_active else 1.0)
	_dim.color.a = move_toward(_dim.color.a, 0.12 if slowmo_active else 0.0, real_dt * 0.8)
	if G.bot:
		_bt += dt
		player.touch_delta += Vector2(cos(_bt * 1.3) * 1.2, sin(_bt * 2.1) * 0.5)
		if G.run.bomb >= 2.0 and bullets.list.size() > 120:
			use_bomb()

	bg.tick(dt)
	combo_t -= dt
	if combo_t <= 0.0:
		graze_combo = 0
	afterglow_t -= dt
	G.after_t -= dt
	G.battle_t += dt
	G.combo = graze_combo
	counter_cd -= dt
	spell_bg.tick(dt)
	player.tick(dt, real_dt, self)
	if state == "play":
		_tick_waves(dt)
	enemies.tick(dt, self)
	shots.tick(dt, self)
	bullet_slow_t -= dt
	bullets.tick(dt * (0.35 if bullet_slow_t > 0.0 else 1.0), self)
	items.tick(dt, self)
	fx.tick(dt)
	banner_t -= real_dt
	if shake > 0.0:
		shake -= real_dt
		position = Vector2(randf_range(-2, 2), randf_range(-2, 2)) if (shake > 0.0 and G.meta.settings.shake) else Vector2.ZERO
	hud.tick()
	if state != "play":
		end_t -= real_dt
		if end_t <= 0.0:
			set_process(false)
			if G.bot:
				var at = G.main.get_children().filter(func(c): return c.has_method("note"))
				at[0].note("%s hits=%d kills=%d t=%.0fs" % [kind, hits, kills, _bt])
			if state == "won":
				G.main.battle_done({"kind": kind, "no_hit": hits == 0, "earned": earned})
			else:
				G.main.game_over()

## 时间停止：只有 Boss 在动（布置飞刀），其余全部冻结；自机不能移动也不能射击
## 暂停：冻结整棵场景树，只有暂停菜单在动
func pause() -> void:
	if get_tree().paused or state != "play" or G.bot:
		return
	get_tree().paused = true
	move_finger = -1
	var ov := UI.Overlay.new("暂停", 178.0)
	add_child(ov)
	_paused_ov = ov
	ov.add_button("继续", unpause, 28.0)
	ov.add_button("查看行囊", func(): Bag.open(ov))
	ov.add_button("设置", func(): UI.open_settings(ov))
	ov.add_button("保存并退出", func():
		get_tree().paused = false
		G.main.goto("title"))
	ov.add_label("※ 下次继续时，这场战斗从头开始", Color(0.65, 0.65, 0.8))

func unpause() -> void:
	if _paused_ov != null:
		_paused_ov.queue_free()
		_paused_ov = null
	get_tree().paused = false

func on_back() -> void:
	if get_tree().paused:
		unpause()
	else:
		pause()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		pause()

func _tick_timestop(real_dt: float) -> void:
	timestop -= real_dt
	player.touch_delta = Vector2.ZERO
	enemies.tick(0.0, self)
	bullets.queue_redraw()
	fx.tick(real_dt * 0.3)
	banner_t -= real_dt
	hud.tick()

func _tick_waves(dt: float) -> void:
	wave_t += dt
	var hp_mult: float = get_meta("hp_mult")
	while not pending.is_empty() and pending[0].t <= wave_t:
		var s: Dictionary = pending.pop_front()
		if s.has("boss"):
			boss = enemies.spawn_boss(s.boss, hp_mult)
			if boss.phase_name() != "":
				spell_bg.declare()
			G.see(Db.BOSSES[s.boss].tex.trim_prefix("c_"))
			hud.cutin("p_" + Db.BOSSES[s.boss].tex.trim_prefix("c_"))
			Au.sfx("warn")
		else:
			var en = enemies.spawn(s.kind, s.move, hp_mult)
			if en.mech == "shield":
				for i in 3:
					enemies.spawn("familiar", {"type": "orbit", "owner": en, "ang": TAU * i / 3.0, "r": 20.0}, hp_mult)
	if pending.is_empty() and enemies.alive() == 0:
		if wave_i + 1 < waves.size():
			_next_wave()
		else:
			_win()

func _win() -> void:
	state = "won"
	end_t = 1.6 if defeat_line == "" else 3.2
	_clear_to_points()
	items.magnet_all = true
	player.invuln = 0.0
	Au.sfx("win")
	banner = "胜利"
	banner_t = 1.6

func slow_max() -> float:
	return SLOW_MAX * (2.0 if G.has("bullet_time") else 1.0)

func add_bomb(v: float) -> void:
	G.run.bomb = minf(float(G.bomb_max()), G.run.bomb + v)

func graze_radius() -> float:
	return player.graze_radius() * (1.0 + 0.08 * G.spirit_lv) * (1.5 if afterglow_t > 0.0 else 1.0)

## 擦弹：连击越高充能越快；「御札返し」会顺手反击
func on_graze(pos: Vector2) -> void:
	graze_combo += 1
	combo_t = 0.8 * (2.0 if G.has("focus") else 1.0)
	grazes += 1
	G.run.grazes_ch += 1
	if G.has("graze_coin") and grazes % 15 == 0:
		items.drop_coins(pos, 1)
	if G.has("graze_shield") and graze_combo % 30 == 0:
		bullets.clear_near(player.position, 55.0, fx)
		fx.burst(player.position, Color(0.8, 1.0, 1.0), 16, 55.0)
	if G.has("reflect"):
		var tg = shots.nearest(pos, enemies.list)
		var dir: Vector2 = Vector2.UP if tg == null else (tg.pos - pos).normalized()
		shots.spawn("amulet", pos, dir * 260.0, 16.0 * G.dmg_mult(), {"homing": 10.0, "rot": true})
	var mult := 1.0 + 0.08 * mini(graze_combo, 25)
	add_bomb(0.02 * mult * (2.0 if G.has("razor") else 1.0) * (1.4 if G.has("tea") else 1.0) * (2.0 if afterglow_t > 0.0 else 1.0))
	Au.sfx("graze", -4.0, 0.0, 1.0 + 0.02 * mini(graze_combo, 30))
	fx.spark(pos, Color(1, 1, 1))
	if G.has("counter") and counter_cd <= 0.0:
		counter_cd = 0.06
		shots.spawn("amulet", player.position, Vector2.UP.rotated(randf_range(-0.6, 0.6)) * 220.0, 5.0 * G.dmg_mult(), {"homing": 12.0, "rot": true})

## 灵点：提升本场战斗的灵压等级
func on_point() -> void:
	spirit += 1
	var lv := mini(5, spirit / 40)
	if lv > G.spirit_lv:
		G.spirit_lv = lv
		fx.text(player.position + Vector2(0, -18), "灵压 Lv%d" % lv, Color(0.6, 0.95, 1.0))
	if G.has("cycle"):
		add_bomb(0.006)

## 把消掉的敌弹变成灵点
func _clear_to_points() -> int:
	var pts := bullets.clear_all(fx)
	items.drop_points(pts)
	return pts.size()

func on_enemy_killed(e) -> void:
	kills += 1
	G.run.kills += 1
	Au.sfx("bosskill" if e.is_boss else "kill", 0.0 if e.is_boss else -5.0)
	fx.burst(e.pos, Color(0.6, 0.9, 1.0), 8 if not e.is_boss else 40, 18.0 if not e.is_boss else 50.0)
	items.drop_coins(e.pos, e.coins)
	add_bomb(0.015 * (2.0 if G.has("burst_cd") else 1.0))
	if e.mech == "split" and e.split_lv > 0:
		for sg in [-1.0, 1.0]:
			enemies.spawn("m_split", {"type": "drift", "pos": e.pos + Vector2(sg * 6.0, 0), "vel": Vector2(sg * 45.0, -30.0)}, get_meta("hp_mult"), {"split_lv": e.split_lv - 1, "scale": e.scale * 0.68, "hp_k": 0.45 if e.split_lv == 2 else 0.2})
	elif e.mech == "bomber":
		Pat.ring(self, e.pos, 12, 62.0, randf() * TAU, 0, 0)
		fx.burst(e.pos, Color(1, 0.5, 0.4), 16, 34.0)
	Weapons.on_kill(self)
	if e.ice_mark:
		bullets.clear_near(e.pos, 45.0, fx)
	if e.is_boss:
		_spell_result(e.phases[e.phase_i])
		if Db.DEFEAT.has(e.kind):
			defeat_line = "%s：「%s」" % [e.def.name, Db.DEFEAT[e.kind]]
		_clear_to_points()
		shake = 0.4
	elif G.run.hearts < G.run.max_hearts and randf() < 0.025:
		items.drop_heart(e.pos)
	if G.has("redtea"):
		G.run.tea_kills += 1
		if G.run.tea_kills >= 40:
			G.run.tea_kills = 0
			G.heal(1)
			fx.text(player.position + Vector2(0, -14), "+1 心", Color(1, 0.5, 0.6))

func on_boss_phase(e) -> void:
	_spell_result(e.phases[e.phase_i - 1])
	hud.cutin("p_" + e.def.tex.trim_prefix("c_"))
	Au.sfx("phase")
	_clear_to_points()
	fx.burst(e.pos, Color(1, 0.8, 0.9), 24, 40.0)
	items.drop_coins(e.pos, 8)
	shake = 0.25
	if e.phase_name() != "":
		spell_bg.declare()

## 符卡收取：本阶段没被弹、没放符卡 → 额外奖励
func _spell_result(ph: Dictionary) -> void:
	if ph.name != "" and phase_clean:
		var bonus: int = 12 * G.run.chapter
		G.run.money += bonus
		earned += bonus
		banner = "收取符卡　+%d钱" % bonus
		banner_t = 1.6
		Au.sfx("win", -3.0)
	phase_clean = true

func player_hit() -> void:
	if player.invuln > 0.0 or state != "play" or G.dev_god:
		return
	if player.guard:
		player.guard = false
		player.guard_cd = 12.0
		player.invuln = 1.0
		bullets.clear_near(player.position, 45.0, fx)
		fx.text(player.position + Vector2(0, -16), "不动明王！", Color(0.6, 0.95, 1.0))
		return
	hits += 1
	phase_clean = false
	graze_combo = 0
	Au.sfx("phit")
	bullets.clear_all(fx)
	fx.burst(player.position, Color(1, 0.3, 0.4), 24, 36.0)
	shake = 0.3
	player.invuln = 2.0 + (1.0 if G.has("camo") else 0.0)
	if G.has("overload"):
		G.run.bomb = 0.0
	if G.has("lantern"):
		add_bomb(1.0)
	if G.has("thorn"):
		for en in enemies.list:
			if not en.dead:
				en.hurt(100.0, self)
	if G.bot or G.dev_god:
		return
	if G.run.shield > 0:
		G.run.shield -= 1
		fx.text(player.position + Vector2(0, -16), "护身结界！", Color(0.6, 0.9, 1.0))
		return
	G.run.hearts -= 1
	if G.run.hearts <= 0:
		if G.has("elixir") and not G.run.revived:
			G.run.revived = true
			G.run.hearts = 2
			fx.text(player.position + Vector2(0, -16), "蓬莱之药！", Color(1, 0.9, 0.5))
		elif G.run.dolls > 0:
			G.run.dolls -= 1
			G.run.hearts = 2
			fx.text(player.position + Vector2(0, -16), "替身人偶！", Color(1, 0.9, 0.5))
		else:
			state = "lost"
			end_t = 1.8
			banner = "满身疮痍"
			banner_t = 1.8

## 符卡：一次用掉所有存满的格数，格数越多越强（憋大放小）
const BOMB_NAMES := ["", "灵符「梦想封印」", "神灵「梦想封印·瞬」", "「梦想天生」"]
func use_bomb() -> void:
	var k := int(floorf(G.run.bomb))
	if k < 1 or state != "play":
		return
	k = mini(k, 3)
	G.run.bomb -= k
	phase_clean = false
	Au.sfx("bomb")
	player.invuln = maxf(player.invuln, 2.0 + 0.8 * k)
	var n := _clear_to_points()
	if G.has("camera"):
		items.drop_coins(player.position + Vector2(0, -30), mini(n / 4, 20))
	if G.has("watch"):
		bullet_slow_t = 3.0
	if G.has("afterglow"):
		afterglow_t = 4.0
	var orbs: int = [0, 8, 14, 22][k]
	G.after_t = 5.0
	var dmg: float = [0.0, 60.0, 75.0, 90.0][k] * G.dmg_mult() * (1.4 if G.has("bomb_big") else 1.0)
	if G.has("bomb_shock"):
		for en in enemies.list:
			if not en.dead:
				en.hurt(45.0 * k * G.dmg_mult(), self)
	if G.has("bomb_heal") and k >= 3:
		G.heal(1)
		fx.text(player.position + Vector2(0, -26), "+1 心", Color(1, 0.5, 0.6))
	if G.has("burst_free") and randf() < 0.25:
		add_bomb(1.0)
		fx.text(player.position + Vector2(0, -36), "二重结界！", Color(1, 0.8, 0.9))
	for i in orbs:
		shots.spawn("orb", player.position, Vector2.from_angle(TAU * i / orbs) * (150.0 + 20.0 * k), dmg, {"homing": 7.0, "pierce": 2 + k, "radius": 6.0 + k, "life": 3.5 + k * 0.5})
	if k >= 3:
		bullet_slow_t = maxf(bullet_slow_t, 2.5)
	fx.burst(player.position, Color(1, 0.5, 0.6), 20 + 15 * k, 40.0 + 25.0 * k)
	shake = 0.15 + 0.1 * k
	banner = BOMB_NAMES[k]
	banner_t = 1.0 + 0.3 * k

func bot_step() -> void:
	pass
