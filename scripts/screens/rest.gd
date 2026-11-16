extends Node2D
## 神社：回 2 心或强化一张符札（二选一，每座神社一次）；另外可以遗忘秘符。做完再手动离开。

func _key() -> int:
	return G.run.chapter * 100 + G.run.pos

func _used() -> bool:
	return G.run.get("rest_used", -1) == _key()

func _ready() -> void:
	UI.backdrop(self)
	UI.status(self)
	UI.picture(self, "ev_rest", 22)
	UI.label(self, "博丽神社的分社", 90, 12, Color(1, 0.7, 0.8))
	UI.label(self, "已经休整过了。还可以整理一下秘符。" if _used() else "鸟居下很安静，可以稍作休整。", 108, 12, Color(0.9, 0.9, 1.0), 10)
	var heal := 1 if G.asc() >= 6 else 2
	var b := UI.button(self, "休息（回复 %d 心）" % heal, 134, func():
		G.heal(heal)
		G.run["rest_used"] = _key()
		Au.sfx("heal")
		G.main.goto("rest"), 30.0)
	UI.set_disabled(b, _used() or G.run.hearts >= G.run.max_hearts)
	var b2 := UI.button(self, "祈愿（强化一张符札）", 168, _pick_upgrade, 30.0)
	UI.set_disabled(b2, _used() or G.upgradable().is_empty())
	var b3 := UI.button(self, "遗忘一张秘符（不占用休息）", 202, _pick_forget, 24.0)
	UI.set_disabled(b3, G.run.skills.is_empty())
	UI.button(self, "离开", 230, func(): G.main.node_done(), 24.0)

func _pick_upgrade() -> void:
	var ups := G.upgradable()
	var ov := UI.Overlay.new("强化哪一张？", 40.0 + ups.size() * 40.0 + 30.0)
	add_child(ov)
	for w in ups:
		var c := {"kind": "up", "id": w.id}
		ov.add_button(G.card_text(c), func():
			G.apply_card(c)
			G.run["rest_used"] = _key()
			Au.sfx("select")
			ov.close()
			G.main.goto("rest"), 34.0)
	ov.add_button("算了", func(): ov.close())

func _pick_forget() -> void:
	var ov := UI.Overlay.new("遗忘哪一张秘符？", 44.0 + G.run.skills.size() * 28.0 + 30.0)
	add_child(ov)
	for sid in G.run.skills:
		var id: String = sid
		ov.add_button("%s　%s" % [Db.SKILLS[id].name, Db.SKILLS[id].desc], func():
			G.remove_skill(id)
			G.ach("forget")
			ov.close()
			G.main.goto("rest"))
	ov.add_button("算了", func(): ov.close())

func bot_step() -> void:
	if not _used():
		if G.run.hearts < G.run.max_hearts:
			G.heal(2)
		elif not G.upgradable().is_empty():
			G.upgradable()[0].lv += 1
	G.main.node_done()
