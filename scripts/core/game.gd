extends Node
## 全局单例：常量、输入映射、本局状态（run）与通用规则。

const FIELD_W := 200.0
const MAX_WEAPONS := 4

var touch_mode := false  # 手机/平板为 true（决定是否启用松手慢动作）
var bot := false         # 自动测试模式
var main
var run := {}
var rng := RandomNumberGenerator.new()
var font: Font
var _tex := {}

func _ready() -> void:
	_add_keys("move_left", [KEY_LEFT, KEY_A])
	_add_keys("move_right", [KEY_RIGHT, KEY_D])
	_add_keys("move_up", [KEY_UP, KEY_W])
	_add_keys("move_down", [KEY_DOWN, KEY_S])
	_add_keys("slow", [KEY_SHIFT])
	_add_keys("bomb", [KEY_X, KEY_SPACE])
	touch_mode = OS.has_feature("mobile")
	bot = OS.get_cmdline_user_args().has("--autotest")
	font = load("res://assets/fonts/fusion12.ttf")
	rng.randomize()

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func field_h() -> float:
	return get_viewport().get_visible_rect().size.y

func tex(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://assets/sprites/%s.png" % n)
	return _tex[n]

# ---------- 本局状态 ----------

func new_run() -> void:
	run = {
		"char": "reimu", "hearts": 5, "max_hearts": 5, "money": 0, "bomb": 1.0,
		"weapons": [{"id": "amulet", "lv": 1, "cd": 0.0}], "relics": [],
		"chapter": 1, "floor": 0, "pos": -1, "map": [],
		"kills": 0, "battles": 0, "revived": false, "tea_kills": 0, "onigiri": 0,
		"chapter_first": true,
	}
	run.map = MapGen.generate(1)

func has(relic: String) -> bool:
	return run.relics.has(relic)

func weapon(id: String):
	for w in run.weapons:
		if w.id == id:
			return w
	return null

func tag_count(tag: String) -> int:
	var n := 0
	for w in run.weapons:
		if Db.WEAPONS[w.id].tag == tag:
			n += 1
	return n

func has_tags(a: String, b: String) -> bool:
	return tag_count(a) > 0 and tag_count(b) > 0

func dmg_mult() -> float:
	var m := 1.0
	if has("hakkero"):
		m += 0.15
	if has("laevatein") and run.hearts >= run.max_hearts:
		m += 0.5
	if has("sage"):
		var tags := {}
		for w in run.weapons:
			tags[Db.WEAPONS[w.id].tag] = true
		m += 0.08 * tags.size()
	return m

func heal(n: int) -> void:
	run.hearts = mini(run.max_hearts, run.hearts + n)

func add_relic(id: String) -> void:
	if id == "" or has(id):
		return
	run.relics.append(id)
	if id == "charm":
		run.max_hearts += 1
		run.hearts += 1

## 随机一个未拥有的宝具；稀有度 0普通 1稀有 2传说。没有可选时返回 ""
func roll_relic(min_rar := 0, max_rar := 2, exclude := []) -> String:
	var pool := []
	var weights := []
	for id in Db.RELICS:
		var r: int = Db.RELICS[id].rar
		if has(id) or exclude.has(id) or r < min_rar or r > max_rar:
			continue
		pool.append(id)
		weights.append([6.0, 3.0, 1.0][r])
	if pool.is_empty():
		return ""
	return pool[_weighted(weights)]

func _weighted(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var x := rng.randf() * total
	for i in weights.size():
		x -= weights[i]
		if x <= 0.0:
			return i
	return weights.size() - 1

## 生成 n 张奖励卡：{"kind": "new"/"up"/"money", "id": ...}
func roll_cards(n: int) -> Array:
	var cands := []
	for w in run.weapons:
		if w.lv < 3:
			cands.append({"kind": "up", "id": w.id})
	if run.weapons.size() < MAX_WEAPONS:
		for id in Db.WEAPONS:
			if weapon(id) == null:
				cands.append({"kind": "new", "id": id})
	var out := []
	while out.size() < n and not cands.is_empty():
		var i := rng.randi_range(0, cands.size() - 1)
		out.append(cands[i])
		cands.remove_at(i)
	while out.size() < n:
		out.append({"kind": "money", "id": ""})
	return out

func apply_card(c: Dictionary) -> void:
	match c.kind:
		"new":
			run.weapons.append({"id": c.id, "lv": 1, "cd": 0.0})
		"up":
			weapon(c.id).lv += 1
		"money":
			run.money += 25

func card_text(c: Dictionary) -> String:
	if c.kind == "money":
		return "赛钱袋\n获得 25 钱"
	var d: Dictionary = Db.WEAPONS[c.id]
	if c.kind == "new":
		return "新·%s〔%s〕\n%s" % [d.name, d.tag, d.desc[0]]
	var lv: int = weapon(c.id).lv + 1
	return "强化·%s Lv%d\n%s" % [d.name, lv, d.desc[lv - 1]]

func relic_text(id: String) -> String:
	var d: Dictionary = Db.RELICS[id]
	return "%s〔%s〕\n%s" % [d.name, ["普通", "稀有", "传说"][d.rar], d.desc]

func upgradable() -> Array:
	return run.weapons.filter(func(w): return w.lv < 3)
