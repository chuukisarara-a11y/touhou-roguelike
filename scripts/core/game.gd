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
var font10: Font   # 小一号的像素字体（文字放不下时用）
var _tex := {}

# ---------- 常驻数据（设置、立绘解锁、开发者模式）与局内存档 ----------
const META_PATH := "user://meta.dat"
const RUN_PATH := "user://run.dat"
const DEV_PASS := "gensokyo"   # 开发者模式口令（标题画面点月亮输入）
var meta := {"settings": {"bgm": 8, "sfx": 8, "shake": true, "slowmo": true}, "seen": {"reimu": true}, "chars": {"reimu": true}, "dev_char": "reimu", "asc": {}, "ach": {}, "codex": {}, "spells": {}, "kills": 0, "caps": 0, "tut": false, "dev": false, "runs": 0, "wins": 0}
var dev_god := false     # 开发者：无敌
var combo := 0           # 当前擦弹连击（战斗里实时更新，供伤害计算用）
var focus_on := false    # 专注状态（缓慢移动或静止）
var after_t := 0.0       # 「残心」剩余秒数
var battle_t := 0.0      # 本场战斗已进行的秒数
var mush := -1           # 「魔法蘑菇」本场的增益：0 伤害 1 移速 2 符卡
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
	font10 = load("res://assets/fonts/fusion10.ttf")
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
	for k in [["sh", [false, false, false]], ["grazes_ch", 0], ["seen_ev", []], ["shards", 0], ["skills", []], ["max_skills", 6], ["char", "reimu"], ["asc", 0]]:
		if not run.has(k[0]):
			run[k[0]] = k[1]
	for r in run.relics.duplicate():   # 旧版本里算宝具、现在是秘符的，挪过去
		if Db.SKILLS.has(r):
			run.relics.erase(r)
			run.skills.append(r)
	resume = {"screen": d.get("screen", "map"), "arg": d.get("arg", {})}
	return true

# ---------- 存档码：把存档变成一串文字，方便备份到备忘录 / 微信，或换手机、换电脑 ----------
const CODE_HEAD := "THYK1:"

func export_code() -> String:
	var d := {"v": 1, "meta": meta}
	if has_save():
		var f := FileAccess.open(RUN_PATH, FileAccess.READ)
		if f != null:
			d["run"] = f.get_var()
	var raw := var_to_bytes(d)
	return CODE_HEAD + str(raw.size()) + ":" + Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_GZIP))

## 读存档码：成功返回 ""，失败返回原因
func import_code(code: String) -> String:
	code = code.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")
	var i := code.find(CODE_HEAD)
	if i < 0:
		return "这不是存档码"
	code = code.substr(i + CODE_HEAD.length())
	var parts := code.split(":", true, 1)
	if parts.size() < 2 or not parts[0].is_valid_int():
		return "存档码不完整"
	var n := int(parts[0])
	var z := Marshalls.base64_to_raw(parts[1])
	if z.is_empty() or n <= 0 or n > 8000000:
		return "存档码不完整"
	var raw := z.decompress(n, FileAccess.COMPRESSION_GZIP)
	if raw.size() != n:
		return "存档码不完整（可能没复制全）"
	var d = bytes_to_var(raw)
	if not (d is Dictionary) or not d.has("meta") or not (d.meta is Dictionary):
		return "存档码已损坏"
	for k in d.meta:
		meta[k] = d.meta[k]
	save_meta()
	clear_run()
	if d.has("run") and d.run is Dictionary:
		var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
		if f != null:
			f.store_var(d.run)
	return ""

func clear_run() -> void:
	if has_save():
		DirAccess.remove_absolute(RUN_PATH)

# ---------- 本局状态 ----------

func new_run(ch := "reimu", asc_lv := 0) -> void:
	var cd: Dictionary = Db.CHARS[ch]
	var hp: int = cd.hearts - (1 if asc_lv >= 3 else 0)
	run = {
		"char": ch, "asc": asc_lv, "hearts": hp, "max_hearts": hp, "money": 0, "bomb": 0.0 if asc_lv >= 10 else 1.0,
		"weapons": [{"id": cd.start, "lv": 1, "cd": 0.0}], "relics": [],
		"chapter": 1, "floor": 0, "pos": -1, "map": [],
		"kills": 0, "battles": 0, "revived": false, "tea_kills": 0, "onigiri": 0,
		"chapter_first": true,
		"max_weapons": 4, "dolls": 0, "shield": 0, "power": 0, "shards": 0, "sh": [false, false, false],
		"grazes_ch": 0, "seen_ev": [], "skills": [], "max_skills": 6,
	}
	run.map = MapGen.generate(1)
	codex(cd.start)

# ---------- 异变等级 / 成就 / 图鉴 ----------
func asc() -> int:
	return run.get("asc", 0)

func asc_speed() -> float:
	return (1.08 if asc() >= 1 else 1.0) * (1.08 if asc() >= 9 else 1.0)

func asc_hp() -> float:
	return 1.15 if asc() >= 2 else 1.0

func asc_rate() -> float:
	return 1.15 if asc() >= 5 else 1.0

## 达成成就（已达成过的不会重复提示）
func ach(id: String) -> void:
	if meta.ach.get(id, false) or bot:
		return
	meta.ach[id] = true
	save_meta()
	if main != null:
		main.toast("成就达成：" + Db.ACH[id][0])
		Au.sfx("win", -4.0)

## 记入图鉴
func codex(id: String) -> void:
	if not meta.codex.get(id, false):
		meta.codex[id] = true
		save_meta()

## 当前角色的定义
func cdef() -> Dictionary:
	return Db.CHARS[run.get("char", "reimu")]

## 第 n 章的设定（按角色路线覆盖名字、背景、精英、Boss）
func chap(n: int) -> Dictionary:
	var d: Dictionary = Db.CHAPTERS[n].duplicate()
	d.merge(cdef().route.get(n, {}), true)
	return d

## 这张秘符当前角色能不能用
func skill_ok(id: String) -> bool:
	var d: Dictionary = Db.SKILLS[id]
	return not d.has("chars") or d.chars.has(run.char)

func unlock_char(id: String) -> bool:
	if meta.chars.get(id, false):
		return false
	meta.chars[id] = true
	save_meta()
	return true

func next_chapter() -> void:
	run.chapter += 1
	run.floor = 0
	run.pos = -1
	run.chapter_first = true
	run.grazes_ch = 0
	run["elites_ch"] = 0
	run.map = MapGen.generate(run.chapter)

## 拿到第 ch 章的境界碎片（每章一片）
func give_shard(ch: int) -> bool:
	if ch < 1 or ch > 3 or run.sh[ch - 1]:
		return false
	run.sh[ch - 1] = true
	run.shards += 1
	return true

## 是否持有某个宝具或秘符（效果代码统一用这个判断）
func has(id: String) -> bool:
	return run.relics.has(id) or run.skills.has(id)

func remove_skill(id: String) -> void:
	run.skills.erase(id)
	if id == "m_power":
		run.max_weapons += 1
	if id == "razor":   # 剃刀边缘被遗忘：心的上限恢复
		run.max_hearts = maxi(1, cdef().hearts + (1 if has("charm") else 0) - (2 if has("greed") else 0))

func add_skill(id: String) -> void:
	if id == "" or has(id):
		return
	run.skills.append(id)
	codex(id)
	if Db.SKILLS[id].rar == 2:
		ach("epic")
	if id == "m_power":
		run.max_weapons = maxi(1, run.max_weapons - 1)
	if id == "razor":
		run.max_hearts = 2
		run.hearts = mini(run.hearts, 2)

func weapon(id: String):
	for w in run.get("weapons", []):
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
	if has("m_speed") and not focus_on:
		m += 0.2
	if has("m_blaze") and combo >= 10:
		m += 0.15
	if mush == 0:
		m += 0.3
	m *= cdef().dmg
	if has("m_power"):
		m *= 1.5
	if has("sniper"):
		m *= 2.4
	if has("puppeteer"):
		m *= 0.6
	return m

## 移动速度倍率（键盘是速度，触屏是手指位移的放大倍数）
func speed_mult() -> float:
	var m: float = cdef().speed
	if has("fan"):
		m *= 1.15
	if has("m_blaze") and combo >= 10:
		m *= 1.2
	if mush == 1:
		m *= 1.25
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
	codex(id)
	if Db.RELICS.has(id) and Db.RELICS[id].rar == 2:
		ach("epic")
	if id == "charm":
		run.max_hearts += 1
		run.hearts += 1
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

## 当前所有可能出现的卡：{"kind": "new"/"up"/"mod"/"skill", "id": ...}
func card_pool() -> Array:
	var cands := []
	for w in run.weapons:
		if w.lv < 3:
			cands.append({"kind": "up", "id": w.id})
	if run.weapons.size() < run.max_weapons:
		for id in Db.WEAPONS:
			if weapon(id) == null:
				cands.append({"kind": "new", "id": id})
	if run.skills.size() < run.max_skills:
		for id in Db.SKILLS:
			if not has(id) and skill_ok(id):
				cands.append({"kind": "skill", "id": id})
	# 符札改造：每张攻符最多 2 个
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
	return cands

## 抽 n 张奖励卡：先按权重抽种类，再在种类里抽（秘符按稀有度加权）
func roll_cards(n: int) -> Array:
	var by := {}
	for c in card_pool():
		if not by.has(c.kind):
			by[c.kind] = []
		by[c.kind].append(c)
	var kw := {"new": 3.0, "up": 3.0, "mod": 2.0, "skill": 3.5}
	var out := []
	while out.size() < n and not by.is_empty():
		var kinds := by.keys()
		var k: String = kinds[_weighted(kinds.map(func(x): return kw[x]))]
		var arr: Array = by[k]
		var i := rng.randi_range(0, arr.size() - 1)
		if k == "skill":
			i = _weighted(arr.map(func(c): return [6.0, 3.0, 1.2][Db.SKILLS[c.id].rar]))
		out.append(arr[i])
		arr.remove_at(i)
		if arr.is_empty():
			by.erase(k)
	while out.size() < n:
		out.append({"kind": "money", "id": ""})
	return out

func apply_card(c: Dictionary) -> void:
	match c.kind:
		"new":
			run.weapons.append({"id": c.id, "lv": 1, "cd": 0.0})
			codex(c.id)
		"up":
			weapon(c.id).lv += 1
		"skill":
			add_skill(c.id)
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
	if c.kind == "skill":
		var sd: Dictionary = Db.SKILLS[c.id]
		return "秘符·%s〔%s·%s〕\n%s" % [sd.name, sd.get("arch", "通用"), ["普通", "稀有", "史诗"][sd.rar], sd.desc]
	var d: Dictionary = Db.WEAPONS[c.id]
	if c.kind == "mod":
		return "改造·%s〔%s〕\n%s" % [d.name, Db.MODS[c.mod].name, Db.MODS[c.mod].desc]
	if c.kind == "new":
		return "新·%s〔%s〕\n%s" % [d.name, d.tag, d.desc[0]]
	var lv: int = weapon(c.id).lv + 1
	return "强化·%s Lv%d\n%s" % [d.name, lv, d.desc[lv - 1]]

func relic_text(id: String) -> String:
	var d: Dictionary = Db.RELICS[id]
	return "宝具·%s〔%s〕\n%s" % [d.name, ["普通", "稀有", "史诗"][d.rar], d.desc]

func card_icon(c: Dictionary) -> Dictionary:
	if c.kind == "money":
		return {"tile": "tile_0", "tex": "coin"}
	if c.kind == "skill":
		return {"tile": "tile_%d" % Db.SKILLS[c.id].rar, "glyph": Db.SKILLS[c.id].g}
	return {"tile": "tile_1" if c.kind == "mod" else "tile_w", "tex": Db.WEAPON_ICON.get(c.id, c.id)}

func relic_icon(id: String) -> Dictionary:
	return {"tile": "tile_%d" % Db.RELICS[id].rar, "glyph": Db.RELICS[id].g}

## 给随机一张符札装上随机改造；返回说明文字（没有可装的返回 ""）
func random_mod() -> String:
	var c := card_pool().filter(func(x): return x.kind == "mod")
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
