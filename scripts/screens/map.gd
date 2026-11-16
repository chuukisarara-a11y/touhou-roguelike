extends Node2D
## 地图界面：显示本章节点，点击可到达的节点前进。

const GLYPH := {"battle": "战", "elite": "精", "event": "？", "shop": "店", "rest": "社", "boss": "王"}
const COLOR := {
	"battle": Color(0.55, 0.6, 0.9), "elite": Color(0.95, 0.45, 0.5), "event": Color(0.6, 0.85, 0.6),
	"shop": Color(0.95, 0.8, 0.4), "rest": Color(0.95, 0.6, 0.75), "boss": Color(1.0, 0.3, 0.4),
}
const NAME := {"battle": "战斗", "elite": "精英", "event": "事件", "shop": "商店", "rest": "神社", "boss": "Boss"}

var h := 356.0
const GAP_NEED := 120
const GAP_POS := Vector2(22, 46)

## 第二章：擦弹够多时，地图上会出现隙间
func gap_open() -> bool:
	return G.run.chapter == 2 and not G.run.sh[1] and G.run.grazes_ch >= GAP_NEED
var t := 0.0
var _info: Label
var _bottom := 999.0

func _ready() -> void:
	h = G.field_h()
	UI.backdrop(self)
	UI.status(self)
	if G.run.money >= 500:
		G.ach("rich")
	if G.run.skills.size() >= 6:
		G.ach("skills6")
	if G.run.weapons.filter(func(w): return w.lv >= 3).size() >= 4:
		G.ach("allmax")
	if G.run.shards >= 3:
		G.ach("shards3")
	var cl := UI.label(self, G.chap(G.run.chapter).name + ("　异变%d" % G.asc() if G.asc() > 0 else ""), 3, 12, Color(0.85, 0.8, 1.0), 52, 84)
	cl.size.y = 0
	UI.fit(cl, 14.0)
	var ex := []
	if G.run.chapter <= 3:
		var hint := ""
		if not G.run.sh[G.run.chapter - 1]:
			hint = ["　毫发无伤地战胜强敌", "　在弹幕的缝隙间游走（擦弹 %d/%d）" % [mini(G.run.grazes_ch, GAP_NEED), GAP_NEED], "　竹林里有谁留下了问题"][G.run.chapter - 1]
		ex.append("碎片 %d/3%s" % [G.run.shards, hint])
	_info = UI.label(self, "".join(ex), h - 18, 12, Color(0.75, 0.68, 0.92), 4)
	UI.button(self, Bag.summary(), h - 46, func(): Bag.open(self), 24.0)
	_bottom = h - 46 - 16.0
	if G.meta.dev:
		Dev.map_tools(self, h - 46 - 22)
		_bottom -= 22.0

func _menu() -> void:
	var ov := UI.Overlay.new("菜单", 128.0)
	add_child(ov)
	ov.add_button("继续", func(): ov.close(), 28.0)
	ov.add_button("设置", func(): UI.open_settings(ov))
	ov.add_button("保存并退出", func(): G.main.goto("title"))

func on_back() -> void:
	_menu()

func node_pos(n: Dictionary) -> Vector2:
	var top := 34.0
	var bottom := minf(h - 74.0, _bottom)
	var step := (bottom - top) / 7.0
	if n.type == "boss":
		return Vector2(G.FIELD_W / 2, top)
	return Vector2(G.FIELD_W / 2 + (n.c - 1) * 58.0 + n.jx, bottom - n.f * step)

func reachable() -> Array:
	var m: Array = G.run.map
	if G.run.pos == -1:
		var out := []
		for i in m.size():
			if m[i].f == 0:
				out.append(i)
		return out
	return m[G.run.pos].next

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_menu()
		return
	if ev is InputEventScreenTouch and ev.pressed:
		if Rect2(G.FIELD_W - 26, 0, 26, 24).has_point(ev.position):
			_menu()
			return
		if gap_open() and ev.position.distance_to(GAP_POS) < 20.0:
			Au.sfx("phase")
			G.main.goto("event", {"id": "gap", "free": true})
			return
		for i in reachable():
			if node_pos(G.run.map[i]).distance_to(ev.position) < 17.0:
				Au.sfx("select")
				G.main.enter_node(i)
				return

func _draw() -> void:
	draw_rect(Rect2(G.FIELD_W - 19, 3, 16, 14), Color(0, 0, 0, 0.35))
	for i in 3:
		draw_rect(Rect2(G.FIELD_W - 16, 6 + i * 3, 10, 2), Color(1, 1, 1, 0.85))
	if gap_open():
		var et := G.tex("eye_big")
		var k := 1.0 + 0.08 * sin(t * 4.0)
		draw_circle(GAP_POS, 18.0 * k, Color(0.5, 0.2, 0.8, 0.25))
		draw_texture_rect(et, Rect2(GAP_POS - et.get_size() * k / 2.0, et.get_size() * k), false)
		draw_string(G.font, GAP_POS + Vector2(-12, 24), "隙间", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.6, 1.0))
	var m: Array = G.run.map
	var reach := reachable()
	for i in m.size():
		var n: Dictionary = m[i]
		for j in n.next:
			var on_path: bool = i == G.run.pos and reach.has(j)
			draw_line(node_pos(n), node_pos(m[j]), Color(1, 1, 1, 0.75) if on_path else Color(0.5, 0.5, 0.7, 0.3), 1.0)
	for i in m.size():
		var n2: Dictionary = m[i]
		var p := node_pos(n2).round()
		var c: Color = COLOR[n2.type]
		var r := 10.0 if n2.type != "boss" else 12.0
		var is_reach := reach.has(i)
		var passed: bool = n2.f < G.run.floor and i != G.run.pos
		if i == G.run.pos:
			draw_circle(p, r + 3, Color(1, 1, 1, 0.9))
		elif is_reach:
			draw_arc(p, r + 3 + sin(t * 5.0), 0, TAU, 24, Color(1, 1, 1, 0.9), 1.0)
		draw_circle(p, r, c.darkened(0.8) if passed else (c.darkened(0.4) if (is_reach or i == G.run.pos) else c.darkened(0.55)))
		draw_arc(p, r, 0, TAU, 24, c if not passed else c.darkened(0.5), 1.0)
		var it := G.tex("n_" + n2.type)
		draw_texture(it, (p - it.get_size() / 2.0).round(), Color.WHITE if not passed else Color(0.55, 0.55, 0.6))

func bot_step() -> void:
	if gap_open():
		G.main.goto("event", {"id": "gap", "free": true})
		return
	var r := reachable()
	var pick: int = r[G.rng.randi_range(0, r.size() - 1)]
	for i in r:
		if G.run.map[i].type == "elite":
			pick = i
	var at = G.main.get_children().filter(func(c): return c.has_method("note"))
	if not at.is_empty():
		at[0].note("F%d:%s" % [G.run.map[pick].f + 1, G.run.map[pick].type])
	G.main.enter_node(pick)
