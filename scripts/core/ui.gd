class_name UI

## 立绘鉴赏的角色表：id → [名字, 介绍]
const GALLERY := {
	"reimu": ["博丽灵梦", "博丽神社的巫女。为了查明这个漫长的夜晚是怎么回事，一路从雾之湖打到了境界的缝隙。"],
	"rumia": ["露米娅", "操纵黑暗的妖怪，常在夜里漫无目的地飘来飘去。"],
	"daiyousei": ["大妖精", "住在雾之湖附近的妖精，琪露诺的朋友。"],
	"cirno": ["琪露诺", "操纵冷气的冰之妖精，自称最强。"],
	"nitori": ["河城荷取", "擅长机械的河童，总在推销来路不明的发明。"],
	"rinnosuke": ["森近霖之助", "道具店「香霖堂」的店主，能看出道具的名字和用途，却不一定知道怎么用。"],
	"meiling": ["红美铃", "红魔馆的门番，擅长武术。"],
	"patchouli": ["帕秋莉·诺蕾姬", "住在红魔馆图书馆里的魔法使，精通属性魔法。"],
	"sakuya": ["十六夜咲夜", "红魔馆的女仆长，能够操纵时间。"],
	"tewi": ["因幡帝", "迷途竹林的妖怪兔，能给人带来好运，也很爱恶作剧。"],
	"reisen": ["铃仙·优昙华院·因幡", "永远亭的月兔，能操纵波长，让人陷入疯狂。"],
	"kaguya": ["蓬莱山辉夜", "住在永远亭的公主，曾给求婚者出过五道难题。"],
	"ran": ["八云蓝", "九尾狐，八云紫的式神。"],
	"yukari": ["八云紫", "能操纵境界的大妖怪，幻想乡的贤者之一。"],
}
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
static func button(parent: Node, text: String, y: float, cb: Callable, h := 26.0, left := false, icon := {}, x := 8.0, width := -1.0) -> Button:
	var b := Button.new()
	var w := G.FIELD_W - 16.0 if width < 0.0 else width
	var ix := 0.0 if icon.is_empty() else 20.0
	var th := text_h(text, w - 10.0 - ix)
	b.position = Vector2(x, y)
	b.custom_minimum_size = Vector2(w, maxf(h, th + 8.0))
	b.size = b.custom_minimum_size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Au.sfx("click"))
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
		draw_texture(G.tex("coin"), Vector2(G.FIELD_W - 62, 6))
		draw_string(G.font, Vector2(G.FIELD_W - 54, 15), str(G.run.money), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.5))

# ---------------------------------------------------------------- 弹出层
## 弹出层：盖在任何界面上（包括暂停中的战斗），自带半透明底和面板。
## 用 add_button / add_label 往里加东西，y 自动往下排。
class Overlay extends CanvasLayer:
	var panel: Control
	var y := 0.0
	var _h := 356.0
	func _init(title: String, height := 220.0) -> void:
		layer = 20
		add_to_group("overlay")
		process_mode = Node.PROCESS_MODE_ALWAYS
		_h = G.field_h()
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.01, 0.06, 0.72)
		dim.size = Vector2(G.FIELD_W, _h)
		add_child(dim)
		panel = Control.new()
		panel.position = Vector2(0, roundf((_h - height) / 2.0))
		panel.size = Vector2(G.FIELD_W, height)
		add_child(panel)
		var bg := ColorRect.new()
		bg.color = Color(0.09, 0.07, 0.19, 0.97)
		bg.position = Vector2(4, 0)
		bg.size = Vector2(G.FIELD_W - 8, height)
		panel.add_child(bg)
		for yy in [0.0, height - 1.0]:
			var ln := ColorRect.new()
			ln.color = Color(0.62, 0.55, 0.85)
			ln.position = Vector2(4, yy)
			ln.size = Vector2(G.FIELD_W - 8, 1)
			panel.add_child(ln)
		y = 8.0
		if title != "":
			UI.label(panel, title, y, 12, Color(1, 0.85, 0.55))
			y += 22.0
	func add_label(text: String, color := Color(0.9, 0.9, 1.0)) -> Label:
		var l := UI.label(panel, text, y, 12, color, 12)
		y += l.size.y + 6.0
		return l
	func add_button(text: String, cb: Callable, h := 24.0) -> Button:
		var b := UI.button(panel, text, y, cb, h)
		y += b.size.y + 4.0
		return b
	func close() -> void:
		queue_free()

## 「◀ 数值 ▶」式的调节行
static func stepper(ov: Overlay, label: String, get_v: Callable, set_v: Callable, lo: int, hi: int) -> void:
	var row := Control.new()
	row.position = Vector2(0, ov.y)
	row.size = Vector2(G.FIELD_W, 24)
	ov.panel.add_child(row)
	var l := UI.label(row, "", 4, 12, Color(0.92, 0.92, 1.0), 14, 100)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var refresh := func(): l.text = "%s　%s" % [label, str(get_v.call())]
	refresh.call()
	UI.button(row, "◀", 0, func():
		set_v.call(clampi(get_v.call() - 1, lo, hi)); refresh.call(), 22.0, false, {}, G.FIELD_W - 80, 32)
	UI.button(row, "▶", 0, func():
		set_v.call(clampi(get_v.call() + 1, lo, hi)); refresh.call(), 22.0, false, {}, G.FIELD_W - 44, 32)
	ov.y += 28.0

## 设置界面（标题、暂停菜单共用）
static func open_settings(parent: Node) -> Overlay:
	var ov := Overlay.new("设置", 196.0)
	parent.add_child(ov)
	var st: Dictionary = G.meta.settings
	stepper(ov, "音乐音量", func(): return st.bgm, func(v):
		st.bgm = v; Au.apply_volume(), 0, 10)
	stepper(ov, "音效音量", func(): return st.sfx, func(v):
		st.sfx = v; Au.apply_volume(); Au.sfx("coin"), 0, 10)
	var onoff := func(k): return "开" if st[k] else "关"
	var box := []   # lambda 按值捕获局部变量，用数组装按钮以便回调里改文字
	box.append(ov.add_button("画面震动：" + onoff.call("shake"), func():
		st.shake = not st.shake; UI.set_text(box[0], "画面震动：" + onoff.call("shake"))))
	box.append(ov.add_button("松手慢动作：" + onoff.call("slowmo"), func():
		st.slowmo = not st.slowmo; UI.set_text(box[1], "松手慢动作：" + onoff.call("slowmo"))))
	ov.add_button("返回", func():
		G.save_meta(); ov.close())
	return ov

## 二次确认
static func confirm(parent: Node, text: String, yes: Callable) -> void:
	var ov := Overlay.new("", 120.0)
	parent.add_child(ov)
	ov.y = 14.0
	ov.add_label(text)
	ov.add_button("确定", func():
		ov.close(); yes.call())
	ov.add_button("取消", func(): ov.close())

# ---------------------------------------------------------------- 滚动区域
## 自己处理触摸拖动的滚动区域（自带惯性）。内容放进 content；
## 可点击的格子用 add_tap(区域, 回调) 注册：手指几乎没移动才算点击，拖动不会误触。
class Scroll extends Control:
	var content: Control
	var taps := []
	var content_h := 0.0
	var _press := false
	var _moved := 0.0
	var _vel := 0.0
	func _init(pos: Vector2, sz: Vector2) -> void:
		position = pos
		size = sz
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		content = Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(content)
	func add_tap(r: Rect2, cb: Callable) -> void:
		taps.append([r, cb])
	func _max_scroll() -> float:
		return maxf(0.0, content_h - size.y)
	func scroll_by(dy: float) -> void:
		content.position.y = clampf(content.position.y + dy, -_max_scroll(), 0.0)
	func _blocked() -> bool:
		return not get_tree().get_nodes_in_group("overlay").is_empty()
	func _input(ev: InputEvent) -> void:
		if not is_visible_in_tree() or _blocked():
			_press = false
			return
		if ev is InputEventScreenTouch:
			if ev.pressed and get_global_rect().has_point(ev.position):
				_press = true
				_moved = 0.0
				_vel = 0.0
			elif not ev.pressed and _press:
				_press = false
				if _moved < 8.0:
					_tap(ev.position)
		elif ev is InputEventScreenDrag and _press:
			_moved += ev.relative.length()
			scroll_by(ev.relative.y)
			_vel = ev.relative.y * 60.0
		elif ev is InputEventMouseButton and ev.pressed and get_global_rect().has_point(ev.position):
			if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_by(30.0)
			elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_by(-30.0)
	func _process(dt: float) -> void:
		if not _press and absf(_vel) > 5.0:
			scroll_by(_vel * dt)
			_vel = move_toward(_vel, 0.0, 900.0 * dt)
	func _tap(p: Vector2) -> void:
		var local := p - global_position - content.position
		for t in taps:
			if t[0].has_point(local):
				Au.sfx("click")
				t[1].call()
				return
