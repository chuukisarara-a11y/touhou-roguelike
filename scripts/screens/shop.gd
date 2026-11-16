extends Node2D
## 香霖堂：买符札、宝具、回血。

var _buttons := []   # [button, price, effect, repeat, sold]
var entry_label: Label

func _ready() -> void:
	UI.backdrop(self)
	UI.status(self)
	UI.label(self, "香霖堂", 22, 12, Color(1, 0.85, 0.5))
	var rs := Sprite2D.new()
	rs.texture = G.tex("rinnosuke")
	rs.position = Vector2(G.FIELD_W / 2 + 34, 24)
	add_child(rs)
	var y := 42.0
	var disc := 0.7 if G.has("member") else 1.0
	for c in G.roll_cards(2):
		if c.kind == "money":
			continue
		var price := int((70 if c.kind == "new" else (60 if G.weapon(c.id).lv == 1 else 90)) * disc)
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
	UI.button(self, "离开", y, func(): G.main.node_done(), 24.0)
	_refresh()

func _add(text: String, price: int, y: float, effect: Callable, h := 36.0, repeat := false, icon := {}) -> float:
	var entry := []
	var b := UI.button(self, text if not repeat else "%s（%d 钱）" % [text, price], y, func(): _buy(entry), h, not repeat, icon)
	if not repeat:
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
