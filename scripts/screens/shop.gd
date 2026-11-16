extends Node2D
## 香霖堂：四个分页（符札 / 宝具 / 道具 / 强化）。点商品看大图和说明，在详情里购买。
## 每次进店有一次「秘符交换」：买一张新秘符，栏位满了就挑一张旧的换掉。

const TABS := ["符札", "宝具", "道具", "强化"]
const GREET := ["欢迎。今天进了些来历不明的好东西。", "又是你。别光看不买。", "这些可都是无缘冢的珍品。", "要赊账的话，门在那边。"]
var items := []   # {tab, card:[kind,id], name, desc, price, buy:Callable, repeat, sold, swap}
var tab := 0
var sc: UI.Scroll
var _tabs := []
var h := 356.0

func _ready() -> void:
	h = G.field_h()
	UI.backdrop(self)
	UI.status(self)
	G.see("rinnosuke")
	UI.label(self, "香霖堂", 20, 12, Color(1, 0.85, 0.5))
	var rs := Sprite2D.new()
	rs.texture = G.tex("c_rinnosuke")
	rs.position = Vector2(18, 44)
	add_child(rs)
	var g := UI.label(self, "霖之助：「%s」" % GREET[G.rng.randi_range(0, GREET.size() - 1)], 34, 10, Color(0.85, 0.85, 0.98), 36, G.FIELD_W - 42)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stock()
	for i in TABS.size():
		var ti := i
		_tabs.append(UI.button(self, TABS[i], 62, func(): tab = ti; _show(), 22.0, false, {}, 6 + i * 47.5, 45))
	sc = UI.Scroll.new(Vector2(0, 88), Vector2(G.FIELD_W, h - 88 - 34))
	add_child(sc)
	UI.button(self, "离开", h - 30, func(): G.main.node_done(), 24.0)
	_show()

func _add(t: int, card: Array, name: String, desc: String, price: int, buy: Callable, repeat := false) -> Dictionary:
	var it := {"tab": t, "card": card, "name": name, "desc": desc, "price": price, "buy": buy, "repeat": repeat, "sold": false, "swap": ""}
	items.append(it)
	return it

func _stock() -> void:
	var disc := 0.7 if G.has("member") else 1.0
	var run: Dictionary = G.run
	# 符札
	for c in G.roll_cards(3):
		if c.kind == "money":
			continue
		var txt: PackedStringArray = G.card_text(c).split("\n")
		var price := 80
		match c.kind:
			"new": price = 70
			"up": price = 60 if G.weapon(c.id).lv == 1 else 90
			"skill": price = [70, 110, 160][Db.SKILLS[c.id].rar]
		_add(0, ["skill" if c.kind == "skill" else "weapon", c.id], txt[0], txt[1], int(price * disc), func(): G.apply_card(c))
	var pool := Db.SKILLS.keys().filter(func(k): return not G.has(k) and not items.any(func(it): return it.card[1] == k))
	if not pool.is_empty():
		var sid: String = pool[G._weighted(pool.map(func(k): return [6.0, 3.0, 1.2][Db.SKILLS[k].rar]))]
		var sd: Dictionary = Db.SKILLS[sid]
		var it := _add(0, ["skill", sid], "交换·%s〔%s〕" % [sd.name, ["普通", "稀有", "史诗"][sd.rar]], sd.desc + "（秘符栏满了也能买：挑一张旧秘符换掉。每次进店仅此一张）", int([70, 110, 160][sd.rar] * 0.8 * disc), func(): G.add_skill(sid))
		it.swap = sid
	# 宝具
	var picked := []
	for i in 3:
		var rid := G.roll_relic(0, 2, picked)
		if rid == "":
			continue
		picked.append(rid)
		var rd: Dictionary = Db.RELICS[rid]
		_add(1, ["relic", rid], "%s〔%s〕" % [rd.name, ["普通", "稀有", "史诗"][rd.rar]], rd.desc, int([80, 130, 180][rd.rar] * disc), func(): G.add_relic(rid))
	# 道具
	_add(2, ["util", "心"], "团子", "回复 1 心", int(30 * disc), func(): G.heal(1), true)
	_add(2, ["util", "偶"], "替身人偶", "心归零时复活一次并回 2 心（可叠加）", int(120 * disc), func(): run.dolls += 1, true)
	_add(2, ["util", "盾"], "护身结界", "抵挡接下来 2 次被弹", int(100 * disc), func(): run.shield += 2, true)
	_add(2, ["util", "符"], "灵符补充", "符卡槽充满", int(60 * disc), func(): G.fill_bomb(), true)
	# 强化
	for w in run.weapons:
		if w.lv >= 3 and not w.get("awake", false):
			_add(3, ["weapon", w.id], "觉醒·" + Db.WEAPONS[w.id].name, "这张攻符的伤害 +60%", int(240 * disc), func(): w["awake"] = true)
	_add(3, ["util", "晶"], "灵力结晶", "伤害永久 +10%（每买一次涨价 50）", int((150 + 50 * run.power) * disc), func(): run.power += 1)
	if run.max_skills < 8:
		_add(3, ["util", "秘"], "秘符栏位 +1", "可以多带一张秘符（最多 8 张）", int(160 * disc), func(): run.max_skills += 1)
	if run.max_weapons < 5:
		_add(3, ["util", "攻"], "第五个攻符栏位", "可以多带一张攻符", int(300 * disc), func(): run.max_weapons = 5)

func _why_not(it: Dictionary) -> String:
	if it.sold:
		return "已售出"
	if G.run.money < it.price:
		return "钱不够"
	if it.name == "团子" and G.run.hearts >= G.run.max_hearts:
		return "心是满的"
	if it.name == "灵符补充" and G.run.bomb >= G.bomb_max():
		return "符卡槽是满的"
	if it.card[0] == "skill" and it.swap == "" and G.run.skills.size() >= G.run.max_skills:
		return "秘符栏已满"
	return ""

func _show() -> void:
	for i in _tabs.size():
		UI.set_text(_tabs[i], TABS[i])
		_tabs[i].self_modulate = Color(1.5, 1.3, 1.0) if i == tab else Color.WHITE
	for c in sc.content.get_children():
		c.queue_free()
	sc.taps.clear()
	sc.content.position.y = 0
	var y := 0.0
	for it in items:
		if it.tab != tab:
			continue
		var item: Dictionary = it
		var dh := UI.text_h(it.desc, G.FIELD_W - 52.0, 10)
		var rh := maxf(42.0, 20.0 + dh + 4.0)
		var bg := ColorRect.new()
		bg.color = Color(0.16, 0.12, 0.30, 0.95)
		bg.position = Vector2(6, y)
		bg.size = Vector2(G.FIELD_W - 12, rh)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc.content.add_child(bg)
		var card := UI.Card.new(it.card[0], it.card[1], Vector2(27, 36))
		card.position = Vector2(9, y + 3)
		sc.content.add_child(card)
		var nl := UI.label(sc.content, it.name, y + 3, 12, Color(0.97, 0.95, 1.0), 40, G.FIELD_W - 40 - 46)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nl.clip_text = true
		if G.font.get_string_size(it.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > nl.size.x:
			nl.add_theme_font_override("font", G.font10)
			nl.add_theme_font_size_override("font_size", 10)
		var why := _why_not(it)
		var pl := UI.label(sc.content, "已售出" if it.sold else "%d钱" % it.price, y + 3, 12, Color(1, 0.88, 0.45) if why == "" else Color(0.6, 0.55, 0.6), G.FIELD_W - 50, 42)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var dl := UI.label(sc.content, it.desc, y + 19, 10, Color(0.78, 0.78, 0.92), 40, G.FIELD_W - 52)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if it.sold:
			for n in [card, nl, dl]:
				n.modulate.a = 0.4
		sc.add_tap(Rect2(6, y, G.FIELD_W - 12, rh), func(): _detail(item))
		y += rh + 4
	if y == 0.0:
		UI.label(sc.content, "（这一页没有货了）", 12, 12, Color(0.6, 0.6, 0.75))
	sc.content_h = y

func _detail(it: Dictionary) -> void:
	var th := UI.text_h(it.desc, G.FIELD_W - 24.0)
	var ov := UI.Overlay.new("", 100.0 + 40.0 + th + 66.0)
	add_child(ov)
	var c := UI.Card.new(it.card[0], it.card[1], Vector2(66, 88))
	c.position = Vector2((G.FIELD_W - 66) / 2.0, 8)
	ov.panel.add_child(c)
	ov.add_close()
	ov.y = 100
	var nl := UI.label(ov.panel, it.name, ov.y, 12, Color(1, 0.85, 0.55))
	UI.fit(nl, 14.0)
	ov.y += 18
	var l := ov.add_label(it.desc)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var why := _why_not(it)
	var b := ov.add_button("购买（%d 钱，持有 %d）" % [it.price, G.run.money] if why == "" else why, func():
		ov.close()
		_buy(it), 26.0)
	UI.set_disabled(b, why != "")
	ov.add_button("再看看", func(): ov.close(), 22.0)

func _buy(it: Dictionary) -> void:
	if _why_not(it) != "":
		return
	if it.swap != "" and G.run.skills.size() >= G.run.max_skills:
		_pick_swap(it)
		return
	_pay(it)

func _pay(it: Dictionary) -> void:
	G.run.money -= it.price
	it.buy.call()
	Au.sfx("coin")
	if it.name == "灵力结晶":
		it.price += 50
	elif not it.repeat:
		it.sold = true
	_show()

func _pick_swap(it: Dictionary) -> void:
	var ov := UI.Overlay.new("用它换掉哪一张？", 40.0 + G.run.skills.size() * 28.0 + 30.0)
	add_child(ov)
	for sid in G.run.skills:
		var id: String = sid
		ov.add_button(Db.SKILLS[id].name, func():
			G.remove_skill(id)
			ov.close()
			_pay(it))
	ov.add_button("算了", func(): ov.close())

func bot_step() -> void:
	for it in items:
		if _why_not(it) == "":
			if it.swap != "" and G.run.skills.size() >= G.run.max_skills:
				G.remove_skill(G.run.skills[0])
			_pay(it)
			return
	G.main.node_done()
