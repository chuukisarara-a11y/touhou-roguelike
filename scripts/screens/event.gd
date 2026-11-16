extends Node2D
## 文字事件

var ev := {}
var _buttons := []
var _done := false
var _res_y := 150.0
var _talk := []
var _ti := -1
var _line: Label
var _next_btn: Button

func _ready() -> void:
	UI.backdrop(self)
	UI.status(self)
	ev = Db.EVENTS[G.rng.randi_range(0, Db.EVENTS.size() - 1)]
	UI.picture(self, ev.art, 22)
	if ev.art == "ev_kappa":
		G.see("nitori")
	elif ev.art == "ev_kourin":
		G.see("rinnosuke")
	UI.label(self, ev.title, 90, 12, Color(0.7, 1.0, 0.75))
	_talk = ev.get("talk", [])
	_line = UI.label(self, "", 108, 12, Color(0.92, 0.92, 1.0), 10)
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_line.size.y = 60
	_next_btn = UI.button(self, "▼", 172, _next_line, 22.0)
	_next_line()

func _next_line() -> void:
	_ti += 1
	if _ti < _talk.size():
		var who: String = _talk[_ti][0]
		_line.text = (_talk[_ti][1] if who == "旁白" else "%s：「%s」" % [who, _talk[_ti][1]])
		_line.visible_ratio = 0.0
		_line.create_tween().tween_property(_line, "visible_ratio", 1.0, 0.3)
		return
	_next_btn.queue_free()
	_next_btn = null
	_line.text = "要怎么做？"
	_line.visible_ratio = 1.0
	var y: float = 130.0
	_res_y = y
	for ch in ev.choices:
		var b := UI.button(self, ch.text, y, func(): _choose(ch), 30.0, true)
		if ch.has("cost") and G.run.money < ch.cost:
			UI.set_disabled(b, true)
		_buttons.append(b)
		y += b.size.y + 4

func _choose(ch: Dictionary) -> void:
	if _done:
		return
	_done = true
	if ch.has("cost"):
		G.run.money -= ch.cost
	var ops: Array = ch.ops
	if ch.has("alt") and G.rng.randf() < 0.5:
		ops = ch.alt
	var lines := []
	for op in ops:
		match op[0]:
			"money":
				G.run.money = maxi(0, G.run.money + op[1])
				lines.append("%s %d 钱" % ["获得" if op[1] > 0 else "失去", absi(op[1])])
			"heal":
				G.heal(op[1])
				lines.append("回复了 %d 心" % op[1])
			"hurt":
				G.run.hearts = maxi(1, G.run.hearts - op[1])
				lines.append("失去了 %d 心" % op[1])
			"bomb":
				G.fill_bomb()
				lines.append("符卡槽充满了")
			"maxhp":
				G.run.max_hearts = maxi(1, G.run.max_hearts + op[1])
				G.run.hearts = mini(G.run.hearts, G.run.max_hearts)
				lines.append("心的上限 %+d" % op[1])
			"relic":
				var rid := G.roll_relic(op[1], 2)
				if rid == "":
					G.run.money += 40
					lines.append("没有合适的东西，换成了 40 钱")
				else:
					G.add_relic(rid)
					lines.append("获得宝具：" + G.relic_text(rid))
			"upgrade":
				var ups := G.upgradable()
				if ups.is_empty():
					G.run.money += 30
					lines.append("符札已全部满级，换成了 30 钱")
				else:
					var w: Dictionary = ups[G.rng.randi_range(0, ups.size() - 1)]
					w.lv += 1
					lines.append("%s 强化到了 Lv%d" % [Db.WEAPONS[w.id].name, w.lv])
	if lines.is_empty():
		lines.append("什么也没有发生。")
	_line.text = ch.get("say", "")
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	var l := UI.label(self, "\n".join(lines), _res_y, 12, Color(1, 0.95, 0.7), 10)
	UI.button(self, "继续", _res_y + 10 + l.size.y, func(): G.main.node_done(), 26.0)

func bot_step() -> void:
	if _next_btn != null:
		_next_line()
		return
	if _done:
		G.main.node_done()
		return
	var ok: Array = ev.choices.filter(func(c): return not c.has("cost") or G.run.money >= c.cost)
	_choose(ok[G.rng.randi_range(0, ok.size() - 1)])
