extends Node2D
## 战斗场景：组装各层，处理输入、时间流速、波次推进与胜负。

const SLOW_MAX := 2.0
const SLOW_SCALE := 0.3

var field_h := 356.0
var kind := "battle"
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
var _dim: ColorRect
var _bt := 0.0

func setup(arg: Dictionary) -> void:
	kind = arg.get("kind", "battle")

func _ready() -> void:
	field_h = G.field_h()
	bg = Background.new(); add_child(bg); bg.setup(field_h)
	bg.mode = "lake"
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
	hud = Hud.new(); add_child(hud); hud.setup(self)
	var hp_mult: float = 1.0 + (G.run.floor - 1) * 0.07
	waves = Waves.build(G.run.chapter, G.run.floor, kind)
	set_meta("hp_mult", hp_mult)
	_next_wave()

func _next_wave() -> void:
	wave_i += 1
	wave_t = 0.0
	pending = waves[wave_i].duplicate()

func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
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
	if G.touch_mode and state == "play":
		if move_finger == -1 and slow_budget > 0.0:
			slowmo_active = true
			slow_budget -= real_dt
		elif move_finger != -1:
			slow_budget = minf(SLOW_MAX, slow_budget + real_dt * 1.5)
	var dt := real_dt * (SLOW_SCALE if slowmo_active else 1.0)
	_dim.color.a = move_toward(_dim.color.a, 0.12 if slowmo_active else 0.0, real_dt * 0.8)
	if G.bot:
		_bt += dt
		player.touch_delta += Vector2(cos(_bt * 1.3) * 1.2, sin(_bt * 2.1) * 0.5)
		if G.run.bomb >= 1.0 and bullets.list.size() > 60:
			use_bomb()

	bg.tick(dt)
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
		position = Vector2(randf_range(-2, 2), randf_range(-2, 2)) if shake > 0.0 else Vector2.ZERO
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

func _tick_waves(dt: float) -> void:
	wave_t += dt
	var hp_mult: float = get_meta("hp_mult")
	while not pending.is_empty() and pending[0].t <= wave_t:
		var s: Dictionary = pending.pop_front()
		if s.has("boss"):
			boss = enemies.spawn_boss(s.boss, hp_mult)
			hud.cutin("p_" + Db.BOSSES[s.boss].tex)
			Au.sfx("warn")
		else:
			enemies.spawn(s.kind, s.move, hp_mult)
	if pending.is_empty() and enemies.alive() == 0:
		if wave_i + 1 < waves.size():
			_next_wave()
		else:
			_win()

func _win() -> void:
	state = "won"
	end_t = 1.6
	bullets.clear_all(fx)
	items.magnet_all = true
	player.invuln = 0.0
	Au.sfx("win")
	banner = "胜利"
	banner_t = 1.6

func add_bomb(v: float) -> void:
	G.run.bomb = minf(1.0, G.run.bomb + v)

func on_graze(pos: Vector2) -> void:
	add_bomb(0.022 * (1.4 if G.has("tea") else 1.0))
	Au.sfx("graze", -4.0)
	fx.spark(pos, Color(1, 1, 1))

func on_enemy_killed(e) -> void:
	kills += 1
	G.run.kills += 1
	Au.sfx("bosskill" if e.is_boss else "kill", 0.0 if e.is_boss else -5.0)
	fx.burst(e.pos, Color(0.6, 0.9, 1.0), 8 if not e.is_boss else 40, 18.0 if not e.is_boss else 50.0)
	items.drop_coins(e.pos, e.coins)
	add_bomb(0.015)
	Weapons.on_kill(self)
	if e.ice_mark:
		bullets.clear_near(e.pos, 45.0, fx)
	if e.is_boss:
		bullets.clear_all(fx)
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
	hud.cutin("p_" + e.def.tex)
	Au.sfx("phase")
	bullets.clear_all(fx)
	fx.burst(e.pos, Color(1, 0.8, 0.9), 24, 40.0)
	items.drop_coins(e.pos, 8)
	shake = 0.25

func player_hit() -> void:
	if player.invuln > 0.0 or state != "play":
		return
	hits += 1
	Au.sfx("phit")
	bullets.clear_all(fx)
	fx.burst(player.position, Color(1, 0.3, 0.4), 24, 36.0)
	shake = 0.3
	player.invuln = 2.0 + (1.0 if G.has("camo") else 0.0)
	if G.has("lantern"):
		G.run.bomb = 1.0
	if G.bot:
		return
	G.run.hearts -= 1
	if G.run.hearts <= 0:
		if G.has("elixir") and not G.run.revived:
			G.run.revived = true
			G.run.hearts = 2
			fx.text(player.position + Vector2(0, -16), "蓬莱之药！", Color(1, 0.9, 0.5))
		else:
			state = "lost"
			end_t = 1.8
			banner = "满身疮痍"
			banner_t = 1.8

func use_bomb() -> void:
	if G.run.bomb < 1.0 or state != "play":
		return
	G.run.bomb = 0.0
	Au.sfx("bomb")
	player.invuln = maxf(player.invuln, 2.5)
	var n := bullets.clear_all(fx)
	if G.has("camera"):
		items.drop_coins(player.position + Vector2(0, -30), mini(n / 4, 20))
	if G.has("watch"):
		bullet_slow_t = 3.0
	# 灵符「梦想封印」
	for i in 8:
		shots.spawn("orb", player.position, Vector2.from_angle(TAU * i / 8.0) * 150.0, 60.0 * G.dmg_mult(), {"homing": 7.0, "pierce": 3, "radius": 7.0, "life": 4.0})
	fx.burst(player.position, Color(1, 0.5, 0.6), 30, 60.0)
	shake = 0.2
	banner = "灵符「梦想封印」"
	banner_t = 1.0

func bot_step() -> void:
	pass
