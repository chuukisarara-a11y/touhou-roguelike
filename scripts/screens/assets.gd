extends Node2D
## 开发者：素材一览（图片、音效、音乐）。导出后的包里图片以 .import 形式存在，这里按名字去重。

var _tab := "img"

func setup(arg: Dictionary) -> void:
	_tab = arg.get("tab", "img")

static func list_names(dir: String, ext: String) -> Array:
	var out := {}
	var d := DirAccess.open(dir)
	if d == null:
		return []
	for f in d.get_files():
		f = f.trim_suffix(".import").trim_suffix(".remap")
		if f.ends_with(ext):
			out[f.trim_suffix(ext)] = true
	var names := out.keys()
	names.sort()
	return names

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	var tabs := [["图片", "img"], ["音效", "sfx"], ["音乐", "bgm"]]
	for i in tabs.size():
		var t: String = tabs[i][1]
		UI.button(self, tabs[i][0] + ("◆" if t == _tab else ""), 4, func(): G.main.goto("assets", {"tab": t}), 22.0, false, {}, 8 + i * 62, 58)
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 30)
	sc.size = Vector2(G.FIELD_W, h - 30 - 32)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var content := Control.new()
	sc.add_child(content)
	var y := 0.0
	if _tab == "img":
		var names := list_names("res://assets/sprites", ".png")
		for i in names.size():
			var cx := 4 + (i % 4) * 48
			var cy := (i / 4) * 62
			var frame := ColorRect.new()
			frame.color = Color(0.14, 0.11, 0.26)
			frame.position = Vector2(cx, cy)
			frame.size = Vector2(46, 46)
			content.add_child(frame)
			var tr := TextureRect.new()
			tr.texture = G.tex(names[i])
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.position = Vector2(cx + 1, cy + 1)
			tr.size = Vector2(44, 44)
			content.add_child(tr)
			var l := UI.label(content, names[i], cy + 46, 12, Color(0.8, 0.8, 0.95), cx, 46)
			l.clip_text = true
			l.add_theme_font_size_override("font_size", 12)
			y = cy + 62
	else:
		var names2 := list_names("res://assets/sfx", ".wav") if _tab == "sfx" else list_names("res://assets/music", ".ogg")
		if names2.is_empty():
			UI.label(content, "（还没有文件）", 10, 12, Color(0.7, 0.7, 0.85))
			y = 30
		for n in names2:
			var nm: String = n
			var b2 := UI.button(content, "▶ " + nm, y, func():
				if _tab == "sfx": Au.sfx(nm, 0.0, 0.0)
				else: Au.bgm(nm), 22.0)
			y += 26
	content.custom_minimum_size = Vector2(G.FIELD_W, y)
	UI.button(self, "返回", h - 28, func():
		Au.bgm("title")
		G.main.goto("title"), 24.0)

func on_back() -> void:
	Au.bgm("title")
	G.main.goto("title")
