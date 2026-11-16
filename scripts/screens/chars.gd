extends Node2D
## 角色选择：每个角色的立绘、特点和开场白；没解锁的显示解锁条件。

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	UI.label(self, "选择角色", 8, 12, Color(1, 0.85, 0.55))
	var sc := UI.Scroll.new(Vector2(0, 28), Vector2(G.FIELD_W, h - 28 - 34))
	add_child(sc)
	var y := 0.0
	for id in Db.CHARS:
		var cid: String = id
		var d: Dictionary = Db.CHARS[id]
		var open: bool = G.meta.chars.get(id, false)
		var bg := ColorRect.new()
		bg.color = Color(0.16, 0.12, 0.30, 0.95)
		bg.position = Vector2(6, y)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc.content.add_child(bg)
		var tr := TextureRect.new()
		tr.texture = G.tex("p_" + id)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(8, y + 4)
		tr.size = Vector2(60, 76)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color.WHITE if open else Color(0, 0, 0, 0.85)
		sc.content.add_child(tr)
		var nl := UI.label(sc.content, d.name if open else "？？？", y + 6, 12, Color(1, 0.9, 0.7), 72, 118)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var yy := y + 84.0
		if open:
			var tl := UI.label(sc.content, d.title, y + 22, 10, Color(0.75, 0.72, 0.95), 72, 118)
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			var tx := UI.label(sc.content, d.traits, y + 36, 10, Color(0.9, 0.9, 1.0), 72, 118)
			tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			yy = maxf(yy, y + 36 + tx.size.y + 4)
			var il := UI.label(sc.content, d.intro, yy, 10, Color(0.7, 0.7, 0.85), 12, G.FIELD_W - 24)
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			yy += il.size.y + 4
			var go := ColorRect.new()
			go.color = Color(0.5, 0.25, 0.4)
			go.position = Vector2(G.FIELD_W - 62, yy)
			go.size = Vector2(52, 20)
			go.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sc.content.add_child(go)
			UI.label(sc.content, "出发", yy + 4, 12, Color.WHITE, G.FIELD_W - 62, 52)
			yy += 26
			var top_asc: int = G.meta.asc.get(cid, 0)
			if top_asc > 0:   # 通关过才有异变等级可选
				var al := UI.label(sc.content, "异变等级 %d ▶ 更换" % _asc(cid), yy - 22, 10, Color(1, 0.6, 0.6), 12, 120)
				al.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				sc.add_tap(Rect2(6, yy - 26, 124, 24), func(): _pick_asc(cid))
				sc.add_tap(Rect2(G.FIELD_W - 66, yy - 28, 60, 26), func(): _go(cid))
				sc.add_tap(Rect2(6, y, G.FIELD_W - 12, yy - y - 28), func(): _go(cid))
			else:
				sc.add_tap(Rect2(6, y, G.FIELD_W - 12, yy - y), func(): _go(cid))
		else:
			var ul := UI.label(sc.content, "解锁条件：\n" + d.unlock, y + 30, 10, Color(0.7, 0.7, 0.85), 72, 118)
			ul.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		bg.size = Vector2(G.FIELD_W - 12, yy - y)
		y = yy + 6
	sc.content_h = y
	UI.button(self, "返回", h - 30, func(): G.main.goto("title"), 24.0)

static var asc_pick := {}

func _asc(cid: String) -> int:
	return mini(asc_pick.get(cid, 0), G.meta.asc.get(cid, 0))

## 出发；第一次玩先看一遍游戏说明
func _go(cid: String) -> void:
	if not G.meta.tut:
		G.meta.tut = true
		G.save_meta()
		UI.tutorial(self, 0, func(): G.main.start_run(cid, _asc(cid)))
	else:
		G.main.start_run(cid, _asc(cid))

func _pick_asc(cid: String) -> void:
	var top_asc: int = G.meta.asc.get(cid, 0)
	var ov := UI.Overlay.new("异变等级", G.field_h() - 40.0)
	add_child(ov)
	ov.add_close()
	var sc := UI.Scroll.new(Vector2(0, ov.y), Vector2(G.FIELD_W, G.field_h() - 40.0 - ov.y - 8))
	ov.panel.add_child(sc)
	var y := 0.0
	for i in top_asc + 1:
		var lv := i
		var txt := "等级 0　没有额外词条" if i == 0 else "等级 %d　%s" % [i, Db.ASC[i - 1]]
		var bg := ColorRect.new()
		bg.color = Color(0.5, 0.25, 0.4) if i == _asc(cid) else Color(0.2, 0.16, 0.34)
		bg.position = Vector2(8, y)
		bg.size = Vector2(G.FIELD_W - 16, 22)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc.content.add_child(bg)
		var l := UI.label(sc.content, txt, y + 5, 10, Color.WHITE, 12, G.FIELD_W - 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sc.add_tap(Rect2(8, y, G.FIELD_W - 16, 22), func():
			asc_pick[cid] = lv
			ov.close()
			G.main.goto("chars"))
		y += 25.0
	var note := UI.label(sc.content, "每一级都包含它之前所有等级的词条。\n通关当前最高等级会解锁下一级。", y + 2, 10, Color(0.7, 0.7, 0.85), 12, G.FIELD_W - 24)
	sc.content_h = y + 34

func on_back() -> void:
	G.main.goto("title")
