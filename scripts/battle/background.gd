class_name Background
extends Node2D
## 滚动星空背景（占位，第7步替换为各章节背景）。

var stars := []
var scroll := 0.0
var h := 356.0
var auto := false  # 菜单界面用：自己滚动

func setup(height: float) -> void:
	h = height
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 50:
		stars.append([rng.randf() * G.FIELD_W, rng.randf() * h, rng.randi_range(0, 2)])

func _process(dt: float) -> void:
	if auto:
		tick(dt * 0.5)

func tick(dt: float) -> void:
	scroll += dt
	queue_redraw()

func _draw() -> void:
	var bands := 12
	for i in bands:
		var k := float(i) / bands
		draw_rect(Rect2(0, h * k, G.FIELD_W, h / bands + 1), Color(0.05, 0.04, 0.12).lerp(Color(0.13, 0.08, 0.25), k))
	for s in stars:
		var layer: int = s[2]
		var speed: float = [6.0, 14.0, 30.0][layer]
		var y := fposmod(s[1] + scroll * speed, h)
		var c: Color = [Color(0.35, 0.35, 0.6), Color(0.6, 0.6, 0.9), Color(1, 1, 0.9)][layer]
		draw_rect(Rect2(roundf(s[0]), roundf(y), 1, 1), c)
