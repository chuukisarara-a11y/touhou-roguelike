extends Node2D
## 战斗奖励：结算钱，精英给宝具，Boss 三选一宝具；之后符札三选一。

var info := {}
var _nodes := []
var _choices := []

func setup(arg: Dictionary) -> void:
	info = arg

func _ready() -> void:
	UI.backdrop(self)
	UI.status(self)
	var y := 26.0
	UI.label(self, "战斗胜利" if not info.get("skipped", false) else "卯酉东海道：直接通过", y, 12, Color(1, 0.9, 0.6))
	y += 18
	var bonus := 0
	if info.no_hit and info.earned > 0:
		bonus = int(info.earned * 0.5)
		G.run.money += bonus
	UI.label(self, "获得 %d 钱%s" % [info.earned, ("（无伤奖励 +%d）" % bonus) if bonus > 0 else ""], y, 12, Color(0.9, 0.9, 1.0))
	y += 18
	if info.get("shard", false):
		UI.label(self, "获得境界碎片（%d/3）" % G.run.shards, y, 12, Color(0.85, 0.6, 1.0))
		y += 16
	if info.kind == "elite":
		var rid := G.roll_relic(0, 1)
		if rid != "":
			G.add_relic(rid)
			var l := UI.label(self, "获得宝具：" + G.relic_text(rid), y, 12, Color(0.7, 1.0, 0.8), 8)
			y += l.size.y + 6
	if info.kind == "boss":
		G.run.hearts = G.run.max_hearts
		UI.label(self, "击破 Boss！心已回满", y, 12, Color(1, 0.6, 0.7))
		y += 20
		_show_relics(y)
	else:
		_show_cards(y)

func _clear() -> void:
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	_choices.clear()

func _show_relics(y: float) -> void:
	_nodes.append(UI.label(self, "选择一件宝具", y, 12, Color(0.85, 0.8, 1.0)))
	y += 18
	var picked := []
	for i in 3:
		var rid := G.roll_relic(1, 2, picked)
		if rid == "":
			rid = G.roll_relic(0, 2, picked)
		if rid == "":
			continue
		picked.append(rid)
		var cb := func():
			G.add_relic(rid)
			G.main.node_done()
		var b := UI.button(self, G.relic_text(rid), y, cb, 36.0, true, G.relic_icon(rid))
		_nodes.append(b)
		_choices.append(cb)
		y += b.size.y + 4
	if picked.is_empty():
		G.main.node_done()

func _show_cards(y: float) -> void:
	_nodes.append(UI.label(self, "选择一张符札", y, 12, Color(0.85, 0.8, 1.0)))
	y += 18
	for c in G.roll_cards(3):
		var cb := func():
			G.apply_card(c)
			G.main.node_done()
		var b := UI.button(self, G.card_text(c), y, cb, 36.0, true, G.card_icon(c))
		_nodes.append(b)
		_choices.append(cb)
		y += b.size.y + 4
	var skip := func():
		G.run.money += 8
		G.main.node_done()
	_nodes.append(UI.button(self, "跳过（+8 钱）", y + 4, skip, 24.0))

func bot_step() -> void:
	if not _choices.is_empty():
		_choices[G.rng.randi_range(0, _choices.size() - 1)].call()
