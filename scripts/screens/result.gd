extends Node2D
## 结算界面：通关或失败。

var win := false
var true_end := false

func setup(arg: Dictionary) -> void:
	win = arg.get("win", false)
	true_end = arg.get("true_end", false)
	if win and not G.bot:
		G.meta.wins += 1
		G.save_meta()

func _ready() -> void:
	var h := G.field_h()
	UI.backdrop(self)
	var run: Dictionary = G.run
	var y := h * 0.14
	var body: Label
	if win:
		UI.label(self, "真·异变解决" if true_end else "异变解决", y, 24, Color(1, 0.9, 0.6))
		var msg := "境界被拨回了原位，漫长的夜晚终于结束。\n紫打着哈欠缩回了隙间里。"
		if not true_end:
			msg = "辉夜认输了，可月亮还是有点不对劲。\n（前三章各藏着一片境界碎片，获得方法都不一样。一局集齐 3 片，就能追到幕后的人。本局 %d/3）" % G.run.shards
		body = UI.label(self, msg, y + 34, 12, Color(0.9, 0.9, 1.0), 10)
	else:
		UI.label(self, "满身疮痍", y, 24, Color(1, 0.45, 0.55))
		body = UI.label(self, "在%s的第 %d 层倒下了。\n下次会更顺利的。" % [Db.CHAPTERS[run.chapter].name, run.floor], y + 34, 12, Color(0.9, 0.9, 1.0), 10)
	y = body.position.y + body.size.y + 10
	var ws := []
	for w in run.weapons:
		ws.append("%s Lv%d" % [Db.WEAPONS[w.id].name, w.lv])
	var rs := []
	for r in run.relics:
		rs.append(Db.RELICS[r].name)
	for r in run.skills:
		ws.append("〈%s〉" % Db.SKILLS[r].name)
	var txt := "击破敌人：%d\n完成战斗：%d\n持有钱：%d\n\n符札：%s\n宝具：%s" % [run.kills, run.battles, run.money, "、".join(ws), "、".join(rs) if not rs.is_empty() else "无"]
	var l := UI.label(self, txt, y, 12, Color(0.8, 0.8, 0.95), 10)
	UI.button(self, "回到标题", minf(h - 36, l.position.y + l.size.y + 12), func(): G.main.goto("title"), 28.0)

func bot_step() -> void:
	var at = G.main.get_children().filter(func(c): return c.has_method("note"))
	var ws := []
	for w in G.run.weapons:
		ws.append("%s%d" % [w.id, w.lv])
	at[0].finish("win=%s kills=%d battles=%d money=%d hearts=%d weapons=%s relics=%s" % [win, G.run.kills, G.run.battles, G.run.money, G.run.hearts, ",".join(ws), ",".join(G.run.relics)])
	if at[0].runs_left > 0:
		G.main.goto("title")
