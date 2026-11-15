class_name Background
extends Node2D
## 滚动星空背景（占位，第7步替换为各章节背景）。

var stars: Array = []
var scroll := 0.0
var h := 640.0

func setup(height: float) -> void:
	h = height
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		var layer := rng.randi_range(0, 2)
		stars.append([rng.randf() * G.FIELD_W, rng.randf() * h, layer])

func tick(dt: float) -> void:
	scroll += dt
	queue_redraw()

func _draw() -> void:
	var bands := 16
	for i in bands:
		var k := float(i) / bands
		var c := Color(0.05, 0.04, 0.12).lerp(Color(0.13, 0.08, 0.25), k)
		draw_rect(Rect2(0, h * k, G.FIELD_W, h / bands + 1), c)
	for s in stars:
		var speed: float = [8.0, 20.0, 45.0][s[2]]
		var y := fposmod(s[1] + scroll * speed, h)
		var c2: Color = [Color(0.35, 0.35, 0.6), Color(0.6, 0.6, 0.9), Color(1, 1, 0.9)][s[2]]
		draw_rect(Rect2(roundf(s[0]), roundf(y), 1 + int(s[2] == 2), 1 + int(s[2] == 2)), c2)
