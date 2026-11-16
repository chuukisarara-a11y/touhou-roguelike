extends Node2D
## 神社：回 2 心，或强化一张符札。

var _stage := 0

func _ready() -> void:
	UI.backdrop(self)
	UI.status(self)
	UI.picture(self, "ev_rest", 22)
	UI.label(self, "博丽神社的分社", 90, 12, Color(1, 0.7, 0.8))
	UI.label(self, "鸟居下很安静，可以稍作休整。", 108, 12, Color(0.9, 0.9, 1.0), 10)
	var b := UI.button(self, "休息（回复 2 心）", 134, func():
		G.heal(2)
		G.main.node_done(), 30.0)
	UI.set_disabled(b, G.run.hearts >= G.run.max_hearts)
	var b2 := UI.button(self, "祈愿（强化一张符札）", 168, _pick_upgrade, 30.0)
	UI.set_disabled(b2, G.upgradable().is_empty())
	var b3 := UI.button(self, "遗忘一张秘符（不占用休息）", 202, _pick_forget, 24.0)
	UI.set_disabled(b3, G.run.skills.is_empty())
	UI.button(self, "直接离开", 230, func(): G.main.node_done(), 24.0)

func _pick_upgrade() -> void:
	_stage = 1
	for c in get_children():
		if c is Button or c is Label or c is Sprite2D:
			c.queue_free()
	UI.label(self, "强化哪一张？", 26, 12, Color(1, 0.7, 0.8))
	var y := 46.0
	for w in G.upgradable():
		var c := {"kind": "up", "id": w.id}
		var b := UI.button(self, G.card_text(c), y, func():
			G.apply_card(c)
			G.main.node_done(), 36.0, true, G.card_icon(c))
		y += b.size.y + 4

func _pick_forget() -> void:
	var ov := UI.Overlay.new("遗忘哪一张秘符？", 44.0 + G.run.skills.size() * 28.0 + 30.0)
	add_child(ov)
	for sid in G.run.skills:
		var id: String = sid
		ov.add_button("%s　%s" % [Db.SKILLS[id].name, Db.SKILLS[id].desc], func():
			G.remove_skill(id)
			ov.close()
			G.main.goto("rest"))
	ov.add_button("算了", func(): ov.close())

func bot_step() -> void:
	if G.run.hearts < G.run.max_hearts:
		G.heal(2)
	elif not G.upgradable().is_empty():
		G.upgradable()[0].lv += 1
	G.main.node_done()
