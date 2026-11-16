extends Node2D
## Boss 战前对话：左右立绘 + 对话框，点击推进，最后有一个带小奖励的选项。

var boss_id := ""
var kind := "boss"
var lines := []
var choices := []
var idx := -1
var _left: Sprite2D
var _right: Sprite2D
var _name: Label
var _text: Label
var _hint: Label
var _buttons := []
var _chosen := false
var _reply := ""
var h := 356.0

func setup(arg: Dictionary) -> void:
	boss_id = arg.boss
	kind = arg.get("kind", "boss")
	var d: Dictionary = Db.TALKS[boss_id]
	lines = d.lines
	choices = d.choices

func _ready() -> void:
	h = G.field_h()
	G.see(Db.BOSSES[boss_id].tex.trim_prefix("c_"))
	var bg := UI.backdrop(self)
	bg.mode = Db.CHAPTERS[G.run.chapter].bg
	var py := h - 96 - 118
	_left = UI.picture(self, "p_reimu", py)
	_left.position.x = -6
	_left.flip_h = true
	_right = UI.picture(self, "p_" + Db.BOSSES[boss_id].tex.trim_prefix("c_"), py)
	_right.position.x = G.FIELD_W - 90
	var box := ColorRect.new()
	box.color = Color(0.07, 0.05, 0.16, 0.92)
	box.position = Vector2(4, h - 100)
	box.size = Vector2(G.FIELD_W - 8, 96)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var line := ColorRect.new()
	line.color = Color(0.62, 0.55, 0.85)
	line.position = Vector2(4, h - 100)
	line.size = Vector2(G.FIELD_W - 8, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	_name = UI.label(self, "", h - 96, 12, Color(1, 0.85, 0.5), 10)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text = UI.label(self, "", h - 80, 12, Color(0.95, 0.95, 1.0), 10)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text.size.y = 60
	_hint = UI.label(self, "▼ 点击继续", h - 18, 12, Color(0.7, 0.7, 0.9, 0.7), 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance()

func _say(who: String, text: String) -> void:
	var is_me := who == "reimu"
	_name.text = "博丽灵梦" if is_me else Db.BOSSES[boss_id].name
	_text.text = text
	UI.fit(_text, 62.0)
	_text.visible_ratio = 0.0
	_text.create_tween().tween_property(_text, "visible_ratio", 1.0, minf(0.6, text.length() * 0.025))
	_left.create_tween().tween_property(_left, "modulate", Color.WHITE if is_me else Color(0.45, 0.45, 0.55), 0.15)
	_right.create_tween().tween_property(_right, "modulate", Color(0.45, 0.45, 0.55) if is_me else Color.WHITE, 0.15)
	var sp := _left if is_me else _right
	var y0 := h - 96 - 118
	var tw := sp.create_tween()
	tw.tween_property(sp, "position:y", y0 - 4.0, 0.08)
	tw.tween_property(sp, "position:y", y0, 0.12)

func _advance() -> void:
	if _chosen:
		G.main.goto("battle", {"kind": kind, "boss": boss_id})
		return
	if not _buttons.is_empty():
		return
	if _text.visible_ratio < 1.0 and idx >= 0:
		_text.visible_ratio = 1.0
		return
	idx += 1
	if idx < lines.size():
		_say(lines[idx][0], lines[idx][1])
		Au.sfx("click", -6.0)
	else:
		_show_choices()

func _show_choices() -> void:
	_hint.visible = false
	var y := h - 100 - 8.0
	for i in range(choices.size() - 1, -1, -1):
		var ch: Dictionary = choices[i]
		var b := UI.button(self, ch.text, 0, func(): _choose(ch), 26.0)
		y -= b.size.y + 4
		b.position.y = y
		_buttons.append(b)

func _choose(ch: Dictionary) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	_chosen = true
	var note := ""
	match ch.op:
		"bomb":
			G.fill_bomb()
			note = "（符卡槽充满了）"
		"heal":
			G.heal(1)
			note = "（回复了 1 心）"
		"money":
			G.run.money += ch.n
			note = "（获得 %d 钱）" % ch.n
	_say("boss", ch.reply + "\n" + note)
	_hint.visible = true
	_hint.text = "▼ 开战"
	Au.sfx("select")

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch and ev.pressed:
		_advance()
	elif ev.is_action_pressed("bomb"):
		_advance()

func bot_step() -> void:
	if not _buttons.is_empty():
		_choose(choices[G.rng.randi_range(0, choices.size() - 1)])
	else:
		_text.visible_ratio = 1.0
		_advance()
