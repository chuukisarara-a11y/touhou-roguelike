extends Node
## 全局单例：常量、输入映射、本局状态（run）与通用规则。

const FIELD_W := 200.0
const MAX_WEAPONS := 4
const TEX_SCALE := 2
# 难度系数（v0.4：整体压力约 +50%）
const DIFF_SPEED := 1.25    # 敌弹速度
const DIFF_RATE := 1.3      # 敌人射击频率
const DIFF_HP := 1.2        # 杂鱼血量
const DIFF_BOSS_HP := 1.25  # 精英/Boss 血量

var touch_mode := false  # 手机/平板为 true（决定是否启用松手慢动作）
var bot := false         # 自动测试模式
var main
var run := {}
var rng := RandomNumberGenerator.new()
var font: Font
var _tex := {}

# ---------- 常驻数据（设置、立绘解锁、开发者模式）与局内存档 ----------
const META_PATH := "user://meta.dat"
const RUN_PATH := "user://run.dat"
const DEV_PASS := "gensokyo"   # 开发者模式口令（标题画面点月亮输入）
var meta := {"settings": {"bgm": 8, "sfx": 8, "shake": true, "slowmo": true}, "seen": {"reimu": true}, "dev": false, "runs": 0, "wins": 0}
var dev_god := false     # 开发者：无敌
var combo := 0           # 当前擦弹连击（战斗里实时更新，供伤害计算用）
var focus_on := false    # 专注状态（缓慢移动或静止）
var after_t := 0.0       # 「残心」剩余秒数
var battle_t := 0.0      # 本场战斗已进行的秒数
var spirit_lv := 0       # 本场战斗的灵压等级（吸收灵点提升，战斗结束清零）
var resume := {}         # 读档后要回到的界面 {"screen", "arg"}

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
	load_meta()

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func field_h() -> float:
	return get_viewport().get_visible_rect().size.y

## 贴图按 2 倍像素密度绘制：加载后把显示尺寸设为一半，逻辑坐标不变。
## raw=true 时不改尺寸（图集按真实像素取区域时用）。
func tex(n: String, raw := false) -> Texture2D:
	var key := n + ("#raw" if raw else "")
	if not _tex.has(key):
		var src: Texture2D = load("res://assets/sprites/%s.png" % n)
		if raw:
			_tex[key] = src
		else:
			var it := ImageTexture.create_from_image(src.get_image())
			var sc := 4 if n.begins_with("c_") else TEX_SCALE   # c_ 开头的角色贴图是 4 倍密度
			it.set_size_override(Vector2i(src.get_width() / sc, src.get_height() / sc))
			_tex[key] = it
	return _tex[key]

func load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return
	var d = f.get_var()
	if d is Dictionary:
		for k in d:
			if meta.has(k) and meta[k] is Dictionary and d[k] is Dictionary:
				meta[k].merge(d[k], true)
			else:
				meta[k] = d[k]

func save_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f != null:
		f.store_var(meta)

func see(id: String) -> void:
	if not meta.seen.get(id, false):
		meta.seen[id] = true
		save_meta()

func has_save() -> bool:
	return FileAccess.file_exists(RUN_PATH)

## 进入每个界面时自动存档：保存「进入这个界面之前」的状态与界面名。
## 中途退出后读档，会从这个界面的开头重来（战斗从头打，商店重新进货）。
func save_run(screen: String, arg: Dictionary) -> void:
	if run.is_empty() or bot:
		return
	var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if f != null:
		f.store_var({"run": run, "screen": screen, "arg": arg, "ver": 1})

func load_run() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(RUN_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = f.get_var()
	if not (d is Dictionary) or not d.has("run"):
		return false
	run = d.run
	# 旧存档补上新版本才有的字段
	for k in [["sh", [false, false, false]], ["grazes_ch", 0], ["seen_ev", []], ["shards", 0]]:
		if not run.has(k[0]):
			run[k[0]] = k[1]
	resume = {"screen": d.get("screen", "map"), "arg": d.get("arg", {})}
	return true

func clear_run() -> void:
	if has_save():
		DirAccess.remove_absolute(RUN_PATH)

# ---------- 本局状态 ----------

func new_run() -> void:
	run = {
		"char": "reimu", "hearts": 5, "max_hearts": 5, "money": 0, "bomb": 1.0,
		"weapons": [{"id": "amulet", "lv": 1, "cd": 0.0}], "relics": [],
		"chapter": 1, "floor": 0, "pos": -1, "map": [],
		"kills": 0, "battles": 0, "revived": false, "tea_kills": 0, "onigiri": 0,
		"chapter_first": true,
		"max_weapons": 4, "dolls": 0, "shield": 0, "power": 0, "shards": 0, "sh": [false, false, false],
		"grazes_ch": 0, "seen_ev": [],
	}
	run.map = MapGen.generate(1)

func next_chapter() -> void:
	run.chapter += 1
	run.floor = 0
	run.pos = -1
	run.chapter_first = true
	run.grazes_ch = 0
	run.map = MapGen.generate(run.chapter)

## 拿到第 ch 章的境界碎片（每章一片）
func give_shard(ch: int) -> bool:
	if ch < 1 or ch > 3 or run.sh[ch - 1]:
		return false
	run.sh[ch - 1] = true
	run.shards += 1
	return true

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
	m += 0.1 * run.power
	m += 0.05 * spirit_lv
	if has("hold"):
		m += 0.12 * floorf(run.bomb)
	if has("sage"):
		var tags := {}
		for w in run.weapons:
			tags[Db.WEAPONS[w.id].tag] = true
		m += 0.08 * tags.size()
	if has("graze_dmg"):
		m += 0.04 * mini(8, combo / 5)
	if has("slow_dmg") and focus_on:
		m += 0.25
	if has("burst_after") and after_t > 0.0:
		m += 0.4
	if has("first_strike") and battle_t < 6.0:
		m += 0.5
	if has("berserk"):
		m += 0.12 * (run.max_hearts - run.hearts)
	if has("sniper"):
		m *= 2.4
	if has("puppeteer"):
		m *= 0.6
	return m

## 使魔：数量与单发伤害（不受自机伤害加成中的「人形师」惩罚）
func familiar_count() -> int:
	var n := (1 if has("shanghai") else 0) + (1 if has("hourai") else 0) + (1 if has("puppeteer") else 0)
	return n * (2 if has("puppeteer") else 1)

func familiar_dmg() -> float:
	return 5.0 * (1.3 if has("hourai") else 1.0) * (1.0 + 0.1 * run.power + 0.05 * spirit_lv)

## 符卡槽：以「格」为单位，默认最多存 2 格
func bomb_max() -> int:
	return 2 + (1 if has("stock3") else 0) + (2 if has("overload") else 0)

func fill_bomb() -> void:
	run.bomb = float(bomb_max())

func heal(n: int) -> void:
	run.hearts = mini(run.max_hearts, run.hearts + n)

func add_relic(id: String) -> void:
	if id == "" or has(id):
		return
	run.relics.append(id)
	if id == "charm":
		run.max_hearts += 1
		run.hearts += 1
	elif id == "razor":
		run.max_hearts = 2
		run.hearts = mini(run.hearts, 2)
	elif id == "greed":
		run.max_hearts = maxi(1, run.max_hearts - 2)
		run.hearts = mini(run.hearts, run.max_hearts)

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
	if run.weapons.size() < run.max_weapons:
		for id in Db.WEAPONS:
			if weapon(id) == null:
				cands.append({"kind": "new", "id": id})
	# 符札改造：每张符札最多 2 个
	for w in run.weapons:
		var have: Array = w.get("mods", [])
		if have.size() >= 2:
			continue
		var ok := []
		for mid in Db.MODS:
			if have.has(mid) or (Db.MODS[mid].shot and not Db.SHOT_WEAPONS.has(w.id)):
				continue
			if (mid == "rapid" and have.has("heavy")) or (mid == "heavy" and have.has("rapid")):
				continue
			if mid == "homing" and Db.WEAPONS[w.id].tag == "追踪":
				continue
			ok.append(mid)
		if not ok.is_empty():
			cands.append({"kind": "mod", "id": w.id, "mod": ok[rng.randi_range(0, ok.size() - 1)]})
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
		"mod":
			var w: Dictionary = weapon(c.id)
			if not w.has("mods"):
				w["mods"] = []
			w.mods.append(c.mod)
		"money":
			run.money += 25

func card_text(c: Dictionary) -> String:
	if c.kind == "money":
		return "赛钱袋\n获得 25 钱"
	var d: Dictionary = Db.WEAPONS[c.id]
	if c.kind == "mod":
		return "改造·%s〔%s〕\n%s" % [d.name, Db.MODS[c.mod].name, Db.MODS[c.mod].desc]
	if c.kind == "new":
		return "新·%s〔%s〕\n%s" % [d.name, d.tag, d.desc[0]]
	var lv: int = weapon(c.id).lv + 1
	return "强化·%s Lv%d\n%s" % [d.name, lv, d.desc[lv - 1]]

func relic_text(id: String) -> String:
	var d: Dictionary = Db.RELICS[id]
	return "%s〔%s〕\n%s" % [d.name, ["普通", "稀有", "史诗"][d.rar], d.desc]

func card_icon(c: Dictionary) -> Dictionary:
	if c.kind == "money":
		return {"tile": "tile_0", "tex": "coin"}
	return {"tile": "tile_1" if c.kind == "mod" else "tile_w", "tex": Db.WEAPON_ICON.get(c.id, c.id)}

func relic_icon(id: String) -> Dictionary:
	return {"tile": "tile_%d" % Db.RELICS[id].rar, "glyph": Db.RELICS[id].g}

## 给随机一张符札装上随机改造；返回说明文字（没有可装的返回 ""）
func random_mod() -> String:
	var c := roll_cards(40).filter(func(x): return x.kind == "mod")
	if c.is_empty():
		return ""
	var pick: Dictionary = c[rng.randi_range(0, c.size() - 1)]
	apply_card(pick)
	return "%s 获得改造〔%s〕：%s" % [Db.WEAPONS[pick.id].name, Db.MODS[pick.mod].name, Db.MODS[pick.mod].desc]

## 符札的显示名：封魔针3〔贯通·连射〕
func weapon_label(w: Dictionary) -> String:
	var s := "%s%d" % [Db.WEAPONS[w.id].name, w.lv]
	var ms: Array = w.get("mods", [])
	if not ms.is_empty():
		s += "〔" + "·".join(ms.map(func(m): return Db.MODS[m].name)) + "〕"
	return s

func upgradable() -> Array:
	return run.weapons.filter(func(w): return w.lv < 3)
