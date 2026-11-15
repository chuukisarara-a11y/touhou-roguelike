extends Node2D
## 标题界面

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	UI.label(self, "东方夜行符", h * 0.2, 24, Color(1, 0.86, 0.92))
	UI.label(self, "~ Night Parade of Spell Cards ~", h * 0.2 + 30, 12, Color(0.75, 0.72, 0.95))
	var s := Sprite2D.new()
	s.texture = G.tex("reimu")
	s.position = Vector2(G.FIELD_W / 2, h * 0.47)
	s.scale = Vector2(2, 2)
	add_child(s)
	UI.button(self, "开始游戏", h * 0.62, func(): G.main.start_run(), 30.0)
	UI.label(self, "东方Project 同人作品\nv0.2 开发版 · 第一章", h - 40, 12, Color(0.6, 0.58, 0.75))

func bot_step() -> void:
	G.main.start_run()
