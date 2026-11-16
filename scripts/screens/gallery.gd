extends Node2D
## 立绘鉴赏：见过的角色才会显示，点开看大图和介绍。

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	var n := 0
	for id in UI.GALLERY:
		if G.meta.seen.get(id, false):
			n += 1
	UI.label(self, "立绘鉴赏　%d / %d" % [n, UI.GALLERY.size()], 8, 12, Color(1, 0.85, 0.55))
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 28)
	sc.size = Vector2(G.FIELD_W, h - 28 - 34)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var content := Control.new()
	sc.add_child(content)
	var i := 0
	for id in UI.GALLERY:
		var seen: bool = G.meta.seen.get(id, false)
		var cx := 6 + (i % 3) * 64
		var cy := (i / 3) * 92
		var b := Button.new()
		b.flat = true
		b.position = Vector2(cx, cy)
		b.size = Vector2(60, 88)
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not seen
		var cid: String = id
		b.pressed.connect(func(): _show(cid))
		content.add_child(b)
		var frame := ColorRect.new()
		frame.color = Color(0.16, 0.12, 0.3, 0.9)
		frame.size = Vector2(60, 74)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(frame)
		var tr := TextureRect.new()
		tr.texture = G.tex("p_" + id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(1, 1)
		tr.size = Vector2(58, 72)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color.WHITE if seen else Color(0, 0, 0, 0.85)
		b.add_child(tr)
		var l := UI.label(b, UI.GALLERY[id][0] if seen else "？？？", 74, 12, Color(0.92, 0.9, 1.0), 0, 60)
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		i += 1
	content.custom_minimum_size = Vector2(G.FIELD_W, ceilf(i / 3.0) * 92)
	UI.button(self, "返回", h - 30, func(): G.main.goto("title"), 24.0)

func _show(id: String) -> void:
	var ov := UI.Overlay.new("", 300.0)
	add_child(ov)
	var tr := TextureRect.new()
	tr.texture = G.tex("p_" + id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = Vector2(28, 8)
	tr.size = Vector2(144, 180)
	ov.panel.add_child(tr)
	ov.y = 192
	UI.label(ov.panel, UI.GALLERY[id][0], ov.y, 12, Color(1, 0.85, 0.55))
	ov.y += 18
	ov.add_label(UI.GALLERY[id][1])
	ov.add_button("关闭", func(): ov.close())

func on_back() -> void:
	G.main.goto("title")
