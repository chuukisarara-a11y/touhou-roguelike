class_name Dev
## 开发者菜单：跳章、直接打 Boss、无敌、素材一览、局内作弊。

static func open(parent: Node) -> void:
	var ov := UI.Overlay.new("开发者菜单", 300.0)
	parent.add_child(ov)
	ov.add_label("从某章开头开始（自动给一套构筑）", Color(0.8, 0.8, 0.95))
	var row := Control.new()
	row.position = Vector2(0, ov.y)
	ov.panel.add_child(row)
	for i in 4:
		var n := i + 1
		UI.button(row, "第%d章" % n, 0, func(): ov.close(); G.main.dev_start_chapter(n), 22.0, false, {}, 8 + i * 46, 42)
	ov.y += 28
	ov.add_button("直接打 Boss / 精英 ▶", func(): ov.close(); _pick_boss(parent))
	var box := []
	box.append(ov.add_button("无敌：" + ("开" if G.dev_god else "关"), func():
		G.dev_god = not G.dev_god; UI.set_text(box[0], "无敌：" + ("开" if G.dev_god else "关"))))
	ov.add_button("素材一览（图片、音效、音乐）", func(): ov.close(); G.main.goto("assets"))
	ov.add_button("解锁全部立绘", func():
		for id in UI.GALLERY: G.meta.seen[id] = true
		G.save_meta(); Au.sfx("win"))
	ov.add_button("关闭开发者模式", func():
		G.meta.dev = false; G.save_meta(); ov.close(); G.main.goto("title"))
	ov.add_button("返回", func(): ov.close())

static func _pick_boss(parent: Node) -> void:
	var ov := UI.Overlay.new("选择对手", 330.0)
	parent.add_child(ov)
	var row := Control.new()
	row.position = Vector2(0, ov.y)
	ov.panel.add_child(row)
	var i := 0
	for id in Db.BOSSES:
		var bid: String = id
		UI.button(row, Db.BOSSES[id].name, (i / 2) * 26, func(): ov.close(); G.main.dev_fight(bid), 22.0, false, {}, 8 + (i % 2) * 94, 90)
		i += 1
	ov.y += ceilf(i / 2.0) * 26 + 6
	ov.add_button("返回", func(): ov.close())

## 地图界面的作弊按钮
static func map_tools(parent: Node, y: float) -> void:
	var items := [
		["+300钱", func(): G.run.money += 300],
		["满级", func():
			for w in G.run.weapons: w.lv = 3],
		["宝具", func(): G.add_relic(G.roll_relic(0, 2))],
		["跳层", func():
			var r: Array = G.run.map[G.run.pos].next if G.run.pos >= 0 else []
			if G.run.pos == -1:
				for k in G.run.map.size():
					if G.run.map[k].f == 0:
						r = [k]
						break
			if not r.is_empty():
				G.run.pos = r[0]; G.run.floor = G.run.map[r[0]].f + 1
			G.main.goto("map")],
	]
	for i in items.size():
		var b := UI.button(parent, items[i][0], y, items[i][1], 18.0, false, {}, 4 + i * 49, 46)
		b.self_modulate = Color(1, 0.8, 0.6)
