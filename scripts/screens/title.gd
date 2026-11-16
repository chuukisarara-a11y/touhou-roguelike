extends Node2D
## 标题界面

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	var top := maxf(0.0, (h - 356.0) * 0.4)
	UI.picture(self, "title_art", top + 70)
	var pr := UI.picture(self, "p_reimu", top + 70 + 150 - 104 - 4)
	var tw := pr.create_tween().set_loops()
	tw.tween_property(pr, "position:y", pr.position.y - 3.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pr, "position:y", pr.position.y, 1.4).set_trans(Tween.TRANS_SINE)
	UI.label(self, "东方夜行符", top + 22, 24, Color(1, 0.86, 0.92))
	UI.label(self, "~ Night Parade of Spell Cards ~", top + 52, 12, Color(0.75, 0.72, 0.95))
	UI.button(self, "开始游戏", top + 236, func(): G.main.start_run(), 30.0)
	UI.label(self, "东方Project 同人作品\nv0.4 开发版 · 第一章", h - 40, 12, Color(0.6, 0.58, 0.75))

func bot_step() -> void:
	G.main.start_run()
