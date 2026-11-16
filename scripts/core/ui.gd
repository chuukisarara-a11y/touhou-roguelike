class_name UI
## 界面小工具：主题、标签、按钮、状态栏。

static func install_theme(root: Window) -> void:
	var th := Theme.new()
	th.default_font = G.font
	th.default_font_size = 12
	var cols := {
		"normal": [Color(0.16, 0.12, 0.30, 0.95), Color(0.62, 0.55, 0.85)],
		"hover": [Color(0.22, 0.17, 0.40, 0.95), Color(0.85, 0.78, 1.0)],
		"pressed": [Color(0.36, 0.20, 0.42, 1.0), Color(1.0, 0.8, 0.9)],
		"disabled": [Color(0.10, 0.09, 0.16, 0.9), Color(0.3, 0.28, 0.4)],
		"focus": [Color(0, 0, 0, 0), Color(0, 0, 0, 0)],
	}
	for st in cols:
		var sb := StyleBoxFlat.new()
		sb.bg_color = cols[st][0]
		sb.border_color = cols[st][1]
		sb.set_border_width_all(1)
		sb.set_content_margin_all(4)
		th.set_stylebox(st, "Button", sb)
	th.set_color("font_color", "Button", Color(0.95, 0.93, 1.0))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color(1, 0.9, 0.95))
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.43, 0.55))
	root.theme = th

## 文字按给定宽度任意断行后的高度（略偏保守，宁高勿低）
static func text_h(text: String, width: float, size := 12) -> float:
	var lines := 0.0
	for par in text.split("\n"):
		var w := G.font.get_string_size(par, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		lines += maxf(1.0, ceilf(w / (width - 4.0)))
	return lines * (G.font.get_height(size) + 2.0)

static func label(parent: Node, text: String, y: float, size := 12, color := Color.WHITE, x := 0.0, w := -1.0) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY  # 必须先于 text/size 设置，否则宽度会被长文本撑开
	l.text = text
	l.position = Vector2(x, y)
	var width := w if w > 0.0 else G.FIELD_W - x * 2.0
	l.custom_minimum_size = Vector2(width, 0)
	l.size = Vector2(width, text_h(text, width, size))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 2)
	parent.add_child(l)
	if not (parent is Button):
		_appear(l, parent, 0.0)
	return l

## 按钮：文字用内嵌 Label 显示（Button 自带的换行宽度不可靠），高度按文字自动撑开。
## 调用方用 b.size.y 排版；禁用/改字请用 set_disabled / set_text。
static func button(parent: Node, text: String, y: float, cb: Callable, h := 26.0, left := false, icon := {}) -> Button:
	var b := Button.new()
	var w := G.FIELD_W - 16.0
	var ix := 0.0 if icon.is_empty() else 20.0
	var th := text_h(text, w - 10.0 - ix)
	b.position = Vector2(8, y)
	b.custom_minimum_size = Vector2(w, maxf(h, th + 8.0))
	b.size = b.custom_minimum_size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	b.pivot_offset = b.size / 2.0
	b.button_down.connect(func(): b.create_tween().tween_property(b, "scale", Vector2(0.96, 0.96), 0.06))
	b.button_up.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_appear(b, parent, 14.0)
	var l := label(b, text, roundf((b.size.y - th) / 2.0) + 1.0, 12, Color(0.95, 0.93, 1.0), 5.0 + ix, w - 10.0 - ix)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if left:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not icon.is_empty():
		var ic := Icon.new()
		ic.spec = icon
		ic.position = Vector2(4, 4)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
	return b

## 入场动效：按创建顺序依次淡入，按钮带一点横向滑入
static func _appear(c: CanvasItem, parent: Node, slide: float) -> void:
	var n: int = parent.get_meta("ui_n", 0)
	parent.set_meta("ui_n", n + 1)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel()
	var delay := minf(0.035 * n, 0.4)
	tw.tween_property(c, "modulate:a", 1.0, 0.18).set_delay(delay)
	if slide != 0.0:
		var x: float = c.position.x
		c.position.x = x + slide
		tw.tween_property(c, "position:x", x, 0.26).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

static func set_disabled(b: Button, d: bool) -> void:
	b.disabled = d
	b.get_child(0).modulate.a = 0.4 if d else 1.0

static func set_text(b: Button, text: String) -> void:
	(b.get_child(0) as Label).text = text

static func picture(parent: Node, tex_name: String, y: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = G.tex(tex_name)
	s.centered = false
	s.position = Vector2(roundf((G.FIELD_W - s.texture.get_width()) / 2.0), y)
	parent.add_child(s)
	_appear(s, parent, 0.0)
	return s

## 16x16 图标：稀有度底板 + 贴图或单字
class Icon extends Control:
	var spec := {}
	func _draw() -> void:
		draw_texture(G.tex(spec.tile), Vector2.ZERO)
		if spec.has("tex"):
			var t := G.tex(spec.tex)
			var sz := t.get_size()
			if sz.x > 12 or sz.y > 12:
				var k := 12.0 / maxf(sz.x, sz.y)
				draw_texture_rect(t, Rect2((Vector2(16, 16) - sz * k) / 2.0, sz * k), false)
			else:
				draw_texture(t, ((Vector2(16, 16) - sz) / 2.0).round())
		else:
			draw_string(G.font, Vector2(2, 13), spec.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

static func backdrop(parent: Node) -> Background:
	var bg := Background.new()
	parent.add_child(bg)
	bg.setup(G.field_h())
	bg.auto = true
	bg.show_behind_parent = true
	return bg

static func status(parent: Node) -> Status:
	var s := Status.new()
	parent.add_child(s)
	return s

## 顶部状态栏：心与钱
class Status extends Node2D:
	func _process(_dt: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if G.run.is_empty():
			return
		var h := G.tex("heart")
		var he := G.tex("heart_empty")
		for i in G.run.max_hearts:
			draw_texture(h if i < G.run.hearts else he, Vector2(4 + i * 10, 4))
		draw_texture(G.tex("coin"), Vector2(G.FIELD_W - 44, 6))
		draw_string(G.font, Vector2(G.FIELD_W - 36, 15), str(G.run.money), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.5))
