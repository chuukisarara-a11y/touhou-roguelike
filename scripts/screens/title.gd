extends Node2D
## 标题界面：继续游戏 / 新游戏 / 设置 / 立绘鉴赏；点月亮可输入口令（开发者模式）。

var top := 0.0
var _moon := Vector2.ZERO

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	top = maxf(0.0, (h - 356.0) * 0.3)
	UI.picture(self, "title_art", top + 62)
	_moon = Vector2(152, top + 62 + 36)
	var pr := UI.picture(self, "p_reimu", top + 62 + 150 - 120 - 2)
	var tw := pr.create_tween().set_loops()
	tw.tween_property(pr, "position:y", pr.position.y - 3.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pr, "position:y", pr.position.y, 1.4).set_trans(Tween.TRANS_SINE)
	UI.label(self, "东方夜行符", top + 16, 24, Color(1, 0.86, 0.92))
	UI.label(self, "~ Night Parade of Spell Cards ~", top + 44, 12, Color(0.75, 0.72, 0.95))
	var items := []
	if G.has_save():
		items.append(["继续游戏", func(): G.main.continue_run()])
	items.append(["新游戏", _new_game])
	items.append(["设置", func(): UI.open_settings(self)])
	items.append(["立绘鉴赏", func(): G.main.goto("gallery")])
	if G.meta.dev:
		items.append(["开发者菜单", func(): Dev.open(self)])
	var y := maxf(top + 218, h - 22 - items.size() * 27)
	for it in items:
		UI.button(self, it[0], y, it[1], 24.0)
		y += 27
	UI.label(self, "东方Project 同人作品　v0.11 开发版", h - 16, 12, Color(0.55, 0.53, 0.7))

func _new_game() -> void:
	if G.has_save():
		UI.confirm(self, "已有进行中的存档。\n开始新游戏会覆盖它，确定吗？", func(): G.main.start_run())
	else:
		G.main.start_run()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch and ev.pressed and ev.position.distance_to(_moon) < 20.0:
		_ask_pass()

## 彩蛋：月亮里藏着一个输入框
func _ask_pass() -> void:
	var ov := UI.Overlay.new("……月亮在看着你", 128.0)
	add_child(ov)
	var le := LineEdit.new()
	le.position = Vector2(12, ov.y)
	le.size = Vector2(G.FIELD_W - 24, 24)
	le.placeholder_text = "说点什么？"
	le.add_theme_font_override("font", G.font)
	le.add_theme_font_size_override("font_size", 12)
	ov.panel.add_child(le)
	ov.y += 30
	var submit := func():
		if le.text.strip_edges().to_lower() == G.DEV_PASS:
			G.meta.dev = not G.meta.dev
			G.save_meta()
			Au.sfx("phase")
			ov.close()
			G.main.goto("title")
		else:
			Au.sfx("click")
			ov.close()
	le.text_submitted.connect(func(_t): submit.call())
	ov.add_button("确定", submit)
	ov.add_button("算了", func(): ov.close())
	le.grab_focus()

func on_back() -> void:
	get_tree().quit()

func bot_step() -> void:
	G.main.start_run()
