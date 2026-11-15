class_name EnemyLayer
extends Node2D
## 敌人层。第3步只有训练用的妖精靶子，第4步扩展为完整敌人系统。

class Enemy:
	var id: int
	var kind := "fairy"
	var pos: Vector2
	var base: Vector2
	var hp := 60.0
	var max_hp := 60.0
	var radius := 9.0
	var flash := 0.0
	var t := 0.0
	var dead := false

	func hurt(d: float, battle) -> void:
		hp -= d
		flash = 0.06
		if hp <= 0.0 and not dead:
			dead = true
			battle.on_enemy_killed(self)

var list: Array[Enemy] = []
var _next_id := 1
var _tex := {}

func spawn(kind: String, pos: Vector2, hp: float) -> Enemy:
	var e := Enemy.new()
	e.id = _next_id; _next_id += 1
	e.kind = kind; e.pos = pos; e.base = pos; e.hp = hp; e.max_hp = hp
	e.t = randf() * TAU
	list.append(e)
	if not _tex.has(kind):
		_tex[kind] = G.tex(kind)
	return e

func tick(dt: float, _battle) -> void:
	for e in list:
		e.t += dt
		e.flash -= dt
		e.pos = e.base + Vector2(sin(e.t * 0.9) * 28.0, sin(e.t * 1.7) * 8.0)
	list = list.filter(func(e): return not e.dead)
	queue_redraw()

func _draw() -> void:
	for e in list:
		var t: Texture2D = _tex[e.kind]
		var p: Vector2 = (e.pos - t.get_size() / 2.0).round()
		draw_texture(t, p, Color(4, 4, 4) if e.flash > 0.0 else Color.WHITE)
		if e.hp < e.max_hp:
			var w := 16.0
			draw_rect(Rect2(e.pos.x - w / 2, e.pos.y - 12, w, 2), Color(0.1, 0.1, 0.15))
			draw_rect(Rect2(e.pos.x - w / 2, e.pos.y - 12, w * maxf(e.hp, 0) / e.max_hp, 2), Color(1, 0.35, 0.4))
