extends Node2D
## 地图界面：显示本章节点，点击可到达的节点前进。

const GLYPH := {"battle": "战", "elite": "精", "event": "？", "shop": "店", "rest": "社", "boss": "王"}
const COLOR := {
	"battle": Color(0.55, 0.6, 0.9), "elite": Color(0.95, 0.45, 0.5), "event": Color(0.6, 0.85, 0.6),
	"shop": Color(0.95, 0.8, 0.4), "rest": Color(0.95, 0.6, 0.75), "boss": Color(1.0, 0.3, 0.4),
}
const NAME := {"battle": "战斗", "elite": "精英", "event": "事件", "shop": "商店", "rest": "神社", "boss": "Boss"}

var h := 356.0
var t := 0.0
var _info: Label

func _ready() -> void:
	h = G.field_h()
	UI.backdrop(self)
	UI.status(self)
	UI.label(self, Db.CHAPTERS[G.run.chapter].name, 2, 12, Color(0.85, 0.8, 1.0))
	_info = UI.label(self, "", h - 44, 12, Color(0.8, 0.8, 0.92), 4)
	var ws := []
	for w in G.run.weapons:
		ws.append("%s%d" % [Db.WEAPONS[w.id].name, w.lv])
	var rs := []
	for r in G.run.relics:
		rs.append(Db.RELICS[r].name)
	_info.text = "符札：" + "、".join(ws) + ("\n宝具：" + "、".join(rs) if not rs.is_empty() else "")
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info.size.y = UI.text_h(_info.text, G.FIELD_W - 8.0)
	_info.position.y = h - 4 - _info.size.y

func node_pos(n: Dictionary) -> Vector2:
	var top := 34.0
	var bottom := h - 74.0
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
	if ev is InputEventScreenTouch and ev.pressed:
		for i in reachable():
			if node_pos(G.run.map[i]).distance_to(ev.position) < 17.0:
				G.main.enter_node(i)
				return

func _draw() -> void:
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
		draw_circle(p, r, c.darkened(0.8) if passed else (c.darkened(0.45) if (is_reach or i == G.run.pos) else c.darkened(0.65)))
		draw_arc(p, r, 0, TAU, 24, c if not passed else c.darkened(0.5), 1.0)
		var it := G.tex("n_" + n2.type)
		draw_texture(it, (p - it.get_size() / 2.0).round(), Color.WHITE if not passed else Color(0.55, 0.55, 0.6))

func bot_step() -> void:
	var r := reachable()
	var pick: int = r[G.rng.randi_range(0, r.size() - 1)]
	var at = G.main.get_children().filter(func(c): return c.has_method("note"))
	if not at.is_empty():
		at[0].note("F%d:%s" % [G.run.map[pick].f + 1, G.run.map[pick].type])
	G.main.enter_node(pick)
