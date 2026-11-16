extends Node2D
## 图鉴与成就：成就 / 符札 / 宝具 / 符卡 四个分页。只做记录，不影响数值。

const TABS := ["成就", "符札", "宝具", "符卡"]
static var tab := 0

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	UI.label(self, "图鉴 · 成就", 6, 12, Color(1, 0.85, 0.55))
	for i in TABS.size():
		var ti := i
		var b := UI.button(self, TABS[i], 24, func():
			tab = ti
			G.main.goto("codex"), 20.0, false, {}, 6.0 + i * 47.5, 45.0)
		if i == tab:
			b.modulate = Color(1.3, 1.1, 0.8)
	var sc := UI.Scroll.new(Vector2(0, 50), Vector2(G.FIELD_W, h - 50 - 34))
	add_child(sc)
	match tab:
		0: _ach(sc)
		1: _cards(sc, [["weapon", Db.WEAPONS], ["skill", Db.SKILLS]])
		2: _cards(sc, [["relic", Db.RELICS]])
		3: _spells(sc)
	UI.button(self, "返回", h - 30, func(): G.main.goto("title"), 24.0)

func _row(sc: UI.Scroll, y: float, title: String, sub: String, done: bool, hh := 30.0) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.22, 0.16, 0.36, 0.95) if done else Color(0.13, 0.11, 0.22, 0.9)
	bg.position = Vector2(6, y)
	bg.size = Vector2(G.FIELD_W - 12, hh - 2)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc.content.add_child(bg)
	var a := UI.label(sc.content, title, y + 3, 12, Color(1, 0.9, 0.6) if done else Color(0.6, 0.6, 0.72), 12, G.FIELD_W - 24)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	a.autowrap_mode = TextServer.AUTOWRAP_OFF
	a.clip_text = true
	var b := UI.label(sc.content, sub, y + 16, 10, Color(0.85, 0.85, 1.0) if done else Color(0.5, 0.5, 0.62), 12, G.FIELD_W - 24)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.clip_text = true

func _ach(sc: UI.Scroll) -> void:
	var n := 0
	for id in Db.ACH:
		if G.meta.ach.get(id, false):
			n += 1
	var l := UI.label(sc.content, "已达成 %d / %d　　累计击破 %d　收取符卡 %d" % [n, Db.ACH.size(), G.meta.kills, G.meta.caps], 0, 10, Color(0.75, 0.72, 0.95))
	var y := 16.0
	for id in Db.ACH:
		var done: bool = G.meta.ach.get(id, false)
		_row(sc, y, ("★ " if done else "☆ ") + Db.ACH[id][0], Db.ACH[id][1], done)
		y += 30.0
	sc.content_h = y

func _cards(sc: UI.Scroll, groups: Array) -> void:
	var y := 0.0
	for g in groups:
		var kind: String = g[0]
		var ids: Array = g[1].keys()
		var n: int = ids.filter(func(k): return G.meta.codex.get(k, false)).size()
		UI.label(sc.content, "%s　%d / %d" % [{"weapon": "攻符", "skill": "秘符", "relic": "宝具"}[kind], n, ids.size()], y, 12, Color(0.75, 0.72, 0.95))
		y += 18.0
		for i in ids.size():
			var id: String = ids[i]
			var got: bool = G.meta.codex.get(id, false)
			var cx := 8 + (i % 4) * 47
			var cy := y + (i / 4) * 80
			var c := UI.Card.new(kind, id, Vector2(36, 48))
			c.position = Vector2(cx + 4, cy)
			c.modulate = Color.WHITE if got else Color(0.12, 0.12, 0.16)
			sc.content.add_child(c)
			var nl := UI.label(sc.content, Bag.item_name(kind, id) if got else "？？？", cy + 50, 12, Color(0.92, 0.9, 1.0) if got else Color(0.5, 0.5, 0.6), cx - 1, 46)
			UI.fit(nl, 26.0)
			if got:
				sc.add_tap(Rect2(cx, cy, 46, 78), func(): Bag.detail(self, kind, id))
		y += ceilf(ids.size() / 4.0) * 80 + 6
	sc.content_h = y

func _spells(sc: UI.Scroll) -> void:
	var y := 0.0
	var tot := 0
	var got := 0
	var rows := []
	for kind in Db.BOSSES:
		for ph in Db.BOSSES[kind].phases:
			if ph.name == "":
				continue
			tot += 1
			var rec: Dictionary = G.meta.spells.get(kind + ":" + ph.name, {})
			if rec.get("cap", 0) > 0:
				got += 1
			rows.append([Db.BOSSES[kind].name, ph.name, rec])
	UI.label(sc.content, "已收取 %d / %d" % [got, tot], 0, 10, Color(0.75, 0.72, 0.95))
	y = 16.0
	for r in rows:
		var rec: Dictionary = r[2]
		if rec.is_empty():
			_row(sc, y, "？？？", "还没遇到过", false)
		else:
			_row(sc, y, r[1], "%s　收取 %d / 挑战 %d" % [r[0], rec.cap, rec.try], rec.cap > 0)
		y += 30.0
	sc.content_h = y

func on_back() -> void:
	G.main.goto("title")
