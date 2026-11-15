extends Node2D
## 战斗场景根节点：组装各层、处理输入与时间流速。

const SLOW_MAX := 2.0      # 松手慢动作最长秒数
const SLOW_SCALE := 0.3

var field_h := 640.0
var bg: Background
var enemies: EnemyLayer
var shots: ShotLayer
var fx: FxLayer
var player: Player
var hud: Hud

var kills := 0
var move_finger := -1
var slow_budget := SLOW_MAX
var slowmo_active := false
var _respawn: Array = []   # [timer, base_pos]
var _dim: ColorRect

func _ready() -> void:
	field_h = G.field_h()
	bg = Background.new(); add_child(bg); bg.setup(field_h)
	enemies = EnemyLayer.new(); add_child(enemies)
	shots = ShotLayer.new(); add_child(shots)
	player = Player.new(); add_child(player)
	player.position = Vector2(G.FIELD_W / 2, field_h - 90)
	fx = FxLayer.new(); add_child(fx)
	_dim = ColorRect.new()
	_dim.color = Color(0.3, 0.5, 1.0, 0.0)
	_dim.size = Vector2(G.FIELD_W, field_h)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	hud = Hud.new(); add_child(hud); hud.setup(self)
	for fx_ in [0.2, 0.5, 0.8]:
		enemies.spawn("fairy", Vector2(G.FIELD_W * fx_, 90), 60.0)
	enemies.spawn("fairy", Vector2(G.FIELD_W * 0.35, 150), 60.0)
	enemies.spawn("fairy", Vector2(G.FIELD_W * 0.65, 150), 60.0)
	if OS.get_cmdline_user_args().has("--autotest"):
		add_child(load("res://scripts/core/autotest.gd").new())

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
	# 松手慢动作：只在触屏设备上启用
	slowmo_active = false
	if G.touch_mode:
		if move_finger == -1 and slow_budget > 0.0:
			slowmo_active = true
			slow_budget -= real_dt
		elif move_finger != -1:
			slow_budget = minf(SLOW_MAX, slow_budget + real_dt * 1.5)
	var dt := real_dt * (SLOW_SCALE if slowmo_active else 1.0)
	_dim.color.a = move_toward(_dim.color.a, 0.12 if slowmo_active else 0.0, real_dt * 0.8)

	bg.tick(dt)
	player.tick(dt, real_dt, self)
	enemies.tick(dt, self)
	shots.tick(dt, self)
	fx.tick(dt)
	# 训练场：符卡槽自动回充，靶子被击破后重生
	player.bomb_gauge = minf(1.0, player.bomb_gauge + dt / 8.0)
	for r in _respawn:
		r[0] -= dt
		if r[0] <= 0.0:
			enemies.spawn("fairy", r[1], 60.0)
	_respawn = _respawn.filter(func(r): return r[0] > 0.0)
	hud.tick()

func on_enemy_killed(e) -> void:
	kills += 1
	fx.burst(e.pos)
	_respawn.append([1.5, e.base])

func use_bomb() -> void:
	if player.bomb_gauge < 1.0:
		return
	player.bomb_gauge = 0.0
	player.invuln = 2.5
	# 灵符「梦想封印」：8 颗追踪光球
	for i in 8:
		var a := TAU * i / 8.0
		shots.spawn("orb", player.position, Vector2.from_angle(a) * 170.0, 80.0, 7.0, 2, 8.0)
	fx.burst(player.position, Color(1, 0.5, 0.6), 30)
