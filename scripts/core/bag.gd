class_name Bag
## 行囊：攻符、秘符、宝具的一览；点卡片看大图和完整说明。地图和暂停菜单都能打开。

static func summary() -> String:
	return "行囊　攻符%d · 秘符%d · 宝具%d" % [G.run.weapons.size(), G.run.skills.size(), G.run.relics.size()]

static func open(parent: Node) -> void:
	var h := G.field_h()
	var ov := UI.Overlay.new("行囊", h - 16.0)
	parent.add_child(ov)
	var sc := UI.Scroll.new(Vector2(0, 28), Vector2(G.FIELD_W, h - 16.0 - 28 - 32))
	ov.panel.add_child(sc)
	var y := 0.0
	var run: Dictionary = G.run
	y = _section(sc, ov, "攻符　%d / %d" % [run.weapons.size(), run.max_weapons], run.weapons.map(func(w): return ["weapon", w.id]), y)
	y = _section(sc, ov, "秘符　%d / %d" % [run.skills.size(), run.max_skills], run.skills.map(func(s): return ["skill", s]), y)
	y = _section(sc, ov, "宝具　%d" % run.relics.size(), run.relics.map(func(r): return ["relic", r]), y)
	var ex := []
	if run.power > 0:
		ex.append("灵力结晶 ×%d（伤害 +%d%%）" % [run.power, run.power * 10])
	if run.dolls > 0:
		ex.append("替身人偶 ×%d" % run.dolls)
	if run.shield > 0:
		ex.append("护身结界 ×%d" % run.shield)
	if not ex.is_empty():
		var l := UI.label(sc.content, "\n".join(ex), y + 2, 12, Color(0.8, 0.85, 1.0), 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		y += l.size.y + 8
	sc.content_h = y
	ov.add_close()
	UI.button(ov.panel, "关闭", h - 16.0 - 30, func(): ov.close(), 26.0)

static func _section(sc: UI.Scroll, ov: UI.Overlay, title: String, items: Array, y: float) -> float:
	var l := UI.label(sc.content, title, y, 12, Color(1, 0.85, 0.55), 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	y += 16
	if items.is_empty():
		var e := UI.label(sc.content, "（还没有）", y, 12, Color(0.55, 0.55, 0.7), 10)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		return y + 20
	for i in items.size():
		var kind: String = items[i][0]
		var id: String = items[i][1]
		var cx := 6 + (i % 4) * 47
		var cy := y + (i / 4) * 82
		var c := UI.Card.new(kind, id, Vector2(36, 48))
		c.position = Vector2(cx + 4, cy)
		sc.content.add_child(c)
		var nl := UI.label(sc.content, item_name(kind, id), cy + 50, 12, Color(0.92, 0.9, 1.0), cx - 1, 46)
		UI.fit(nl, 14.0)
		sc.add_tap(Rect2(cx, cy, 46, 78), func(): detail(ov, kind, id))
	return y + ceilf(items.size() / 4.0) * 82 + 2

static func item_name(kind: String, id: String) -> String:
	if kind == "weapon":
		return Db.WEAPONS[id].name
	return (Db.SKILLS[id] if kind == "skill" else Db.RELICS[id]).name

## 详情：大卡面 + 完整说明
static func detail(parent: Node, kind: String, id: String) -> void:
	var lines := []
	var head := ""
	if kind == "weapon":
		var d: Dictionary = Db.WEAPONS[id]
		var w = G.weapon(id)
		var lv: int = w.lv if w != null else 0
		head = "攻符 · %s系 · %s" % [Db.FAMS.get(d.get("fam", ""), "其他"), d.tag]
		for i in 2:
			lines.append("%s Lv%d　%s" % ["◆" if i < lv else "◇", i + 1, d.desc[i]])
		if d.has("br"):   # Lv3：二选一的分支
			var bsel: int = w.get("br", -1) if (w != null and lv >= 3) else -1
			for k in 2:
				lines.append("%s Lv3·%s　%s" % ["◆" if bsel == k else "◇", d.br[k][0], d.br[k][1]])
		else:
			lines.append("%s Lv3　%s" % ["◆" if lv >= 3 else "◇", d.desc[2]])
		if w != null:
			for m in w.get("mods", []):
				lines.append("改造〔%s〕%s" % [Db.MODS[m].name, Db.MODS[m].desc])
			if w.get("awake", false):
				lines.append("已觉醒：伤害 +60%")
	else:
		var d2: Dictionary = Db.SKILLS[id] if kind == "skill" else Db.RELICS[id]
		head = "%s · %s%s" % ["秘符" if kind == "skill" else "宝具", ["普通", "稀有", "史诗"][d2.rar], ("　" + d2.arch + ("系" if d2.has("fam") else "流")) if d2.has("arch") else ""]
		lines.append(d2.desc)
	var text := "\n".join(lines)
	var th := UI.text_h(text, G.FIELD_W - 24.0)
	var ov := UI.Overlay.new("", 96.0 + 46.0 + th + 40.0)
	parent.add_child(ov)
	var c := UI.Card.new(kind, id, Vector2(66, 88))
	c.position = Vector2((G.FIELD_W - 66) / 2.0, 8)
	ov.panel.add_child(c)
	ov.y = 100
	UI.label(ov.panel, item_name(kind, id), ov.y, 12, Color(1, 0.85, 0.55))
	ov.y += 16
	UI.label(ov.panel, head, ov.y, 12, Color(0.7, 0.75, 0.95))
	ov.y += 18
	var l := ov.add_label(text)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ov.add_close()
	ov.add_button("关闭", func(): ov.close(), 26.0)
