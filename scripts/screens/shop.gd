extends Node2D
## 香霖堂：买符札、宝具、回血。

var _buttons := []   # [button, price, effect, repeat, sold]
var entry_label: Label
var _pages := []
var _page := 0
var _switch: Button

func _ready() -> void:
	UI.backdrop(self)
	UI.status(self)
	UI.label(self, "香霖堂", 22, 12, Color(1, 0.85, 0.5))
	G.see("rinnosuke")
	var rs := Sprite2D.new()
	rs.texture = G.tex("c_rinnosuke")
	rs.position = Vector2(G.FIELD_W / 2 + 36, 22)
	add_child(rs)
	var y := 42.0
	var disc := 0.7 if G.has("member") else 1.0
	for c in G.roll_cards(2):
		if c.kind == "money":
			continue
		var price := int((70 if c.kind == "new" else ([70, 110, 160][Db.SKILLS[c.id].rar] if c.kind == "skill" else (80 if c.kind == "mod" else (60 if G.weapon(c.id).lv == 1 else 90)))) * disc)
		y += _add(G.card_text(c), price, y, func(): G.apply_card(c), 36.0, false, G.card_icon(c))
	var picked := []
	for i in 2:
		var rid := G.roll_relic(0, 2, picked)
		if rid == "":
			continue
		picked.append(rid)
		var price2 := int([80, 130, 180][Db.RELICS[rid].rar] * disc)
		y += _add(G.relic_text(rid), price2, y, func(): G.add_relic(rid), 36.0, false, G.relic_icon(rid))
	y += _add("回复 1 心", int(30 * disc), y, func(): G.heal(1), 24.0, true)
	var n1 := _buttons.size()
	# 第二页：高价强化与一次性道具
	var y2 := 42.0
	for w in G.run.weapons:
		if w.lv >= 3 and not w.get("awake", false) and y2 < 100.0:
			y2 += _add("觉醒·%s\n这张符札的伤害 +60%%" % Db.WEAPONS[w.id].name, int(240 * disc), y2, func(): w["awake"] = true, 36.0, false, G.card_icon({"kind": "up", "id": w.id}))
	if G.run.max_skills < 8:
		y2 += _add("秘符栏位 +1", int(160 * disc), y2, func(): G.run.max_skills += 1, 24.0, false, {}, true)
	if G.run.max_weapons < 5:
		y2 += _add("第五个符札栏位", int(300 * disc), y2, func(): G.run.max_weapons = 5, 24.0, false, {}, true)
	y2 += _add("灵力结晶：伤害永久 +10%", int((150 + 50 * G.run.power) * disc), y2, func(): G.run.power += 1, 24.0, false, {}, true)
	y2 += _add("替身人偶：心归零时复活一次", int(120 * disc), y2, func(): G.run.dolls += 1, 24.0, true)
	y2 += _add("护身结界：抵挡接下来 2 次被弹", int(100 * disc), y2, func(): G.run.shield += 2, 24.0, true)
	y2 += _add("灵符补充：符卡槽充满", int(60 * disc), y2, func(): G.fill_bomb(), 24.0, true)
	for i in _buttons.size():
		_pages.append(0 if i < n1 else 1)
	var yb := maxf(y, y2)
	_switch = UI.button(self, "", yb, _toggle, 24.0)
	UI.button(self, "离开", yb + 28, func(): G.main.node_done(), 24.0)
	_show_page()
	_refresh()

func _toggle() -> void:
	_page = 1 - _page
	_show_page()

func _show_page() -> void:
	for i in _buttons.size():
		_buttons[i][0].visible = _pages[i] == _page
	UI.set_text(_switch, "看看高价货与道具 ▶" if _page == 0 else "◀ 回到符札与宝具")

func _add(text: String, price: int, y: float, effect: Callable, h := 36.0, repeat := false, icon := {}, oneline := false) -> float:
	var entry := []
	var small := repeat or oneline
	var b := UI.button(self, text if not small else "%s（%d钱）" % [text, price], y, func(): _buy(entry), h, not small, icon)
	if not small:
		var pl := Label.new()
		pl.text = "%d钱" % price
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pl.position = Vector2(b.size.x - 44, 3)
		pl.size = Vector2(40, 14)
		pl.add_theme_color_override("font_color", Color(1, 0.88, 0.45))
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pl)
		entry_label = pl
	entry.append_array([b, price, effect, repeat, false])
	_buttons.append(entry)
	return b.size.y + 4

func _with_price(text: String, price: int) -> String:
	var i := text.find("\n")
	return "%s  %d钱%s" % [text.substr(0, i), price, text.substr(i)]

func _buy(entry: Array) -> void:
	if G.run.money < entry[1] or entry[4]:
		return
	G.run.money -= entry[1]
	entry[2].call()
	if not entry[3]:
		entry[4] = true
		UI.set_text(entry[0], "已售出")
		for i in range(1, entry[0].get_child_count()):
			entry[0].get_child(i).queue_free()
	_refresh()

func _refresh() -> void:
	for e in _buttons:
		var heal_full: bool = e[3] and G.run.hearts >= G.run.max_hearts
		UI.set_disabled(e[0], e[4] or G.run.money < e[1] or heal_full)

func bot_step() -> void:
	for e in _buttons:
		if not e[0].disabled:
			_buy(e)
			return
	G.main.node_done()
