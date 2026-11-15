class_name Db
## 静态数据表：符札、宝具、敌人、Boss、事件。

const WEAPONS := {
	"amulet": {"name": "博丽符札", "tag": "追踪", "desc": ["发射2张自动追踪的符札", "符札增加到4张", "符札伤害+60%"]},
	"needle": {"name": "封魔针", "tag": "直线", "desc": ["正前方高速飞针，单体伤害高", "同时发射2根", "飞针可穿透敌人"]},
	"star": {"name": "星屑弹", "tag": "扩散", "desc": ["扇形发射3颗星弹", "增加到5颗", "射速提升40%"]},
	"laser": {"name": "魔法镭射", "tag": "穿透", "desc": ["持续激光，贯穿一整列敌人", "激光变宽，伤害+40%", "伤害再+60%"]},
	"yinyang": {"name": "阴阳玉", "tag": "环绕", "desc": ["1颗阴阳玉绕身旋转，撞击敌人并消除敌弹", "增加到2颗", "增加到3颗"]},
	"knife": {"name": "银制飞刀", "tag": "反弹", "desc": ["斜向飞刀，碰到边缘反弹2次", "同时发射4把", "反弹次数+2，伤害+30%"]},
	"bat": {"name": "绯红蝙蝠", "tag": "追踪", "desc": ["追踪蝙蝠，命中时为符卡槽充能", "增加到2只", "充能效果翻倍"]},
	"fire": {"name": "凤凰火羽", "tag": "火", "desc": ["火羽命中后点燃敌人，持续伤害", "同时发射2片", "点燃伤害翻倍"]},
	"ice": {"name": "冰晶", "tag": "冰", "desc": ["冰晶命中后使敌人减速", "同时发射2枚", "击破被冰冻的敌人时消除附近敌弹"]},
	"doll": {"name": "人偶", "tag": "召唤", "desc": ["2个人偶跟随并自动瞄准射击", "人偶射速提升50%", "人偶的子弹可穿透敌人"]},
	"pillar": {"name": "御柱", "tag": "蓄力", "desc": ["每3秒在敌人头上落下御柱，范围伤害", "间隔缩短到2秒", "御柱伤害+80%"]},
	"moon": {"name": "月之弹", "tag": "随机", "desc": ["弹道弯曲，伤害在0.5~2.5倍间浮动", "同时发射2颗", "15%概率造成5倍伤害"]},
	"rift": {"name": "境界裂隙", "tag": "特殊", "desc": ["同时向前后发射；子弹可穿越左右边界", "前后各2发", "伤害+50%"]},
	"starmap": {"name": "星图", "tag": "特殊", "desc": ["每击破8个敌人，降下一次流星雨", "流星数量翻倍", "只需击破5个敌人"]},
}

const SYNERGIES := [
	{"name": "追踪×2", "desc": "追踪类伤害+30%"},
	{"name": "火+冰", "desc": "蒸汽爆炸：范围伤害"},
	{"name": "直线+穿透", "desc": "封魔针与镭射伤害+25%"},
	{"name": "召唤+环绕", "desc": "人偶射速+30%"},
]

const RELICS := {
	"hakkero": {"name": "迷你八卦炉", "rar": 0, "desc": "伤害+15%"},
	"fan": {"name": "天狗的团扇", "rar": 0, "desc": "移动速度+15%"},
	"onigiri": {"name": "幽灵饭团", "rar": 0, "desc": "每完成2场战斗回1心"},
	"camo": {"name": "河童的光学迷彩", "rar": 0, "desc": "被弹后的无敌时间+1秒"},
	"saisen": {"name": "赛钱箱", "rar": 0, "desc": "拾取的钱有25%概率翻倍"},
	"charm": {"name": "博丽护身符", "rar": 0, "desc": "心的上限+1"},
	"tea": {"name": "上等茶叶", "rar": 0, "desc": "擦弹充能+40%"},
	"gohei": {"name": "灵梦的御币", "rar": 1, "desc": "擦弹范围×1.5"},
	"watch": {"name": "咲夜的怀表", "rar": 1, "desc": "发动符卡后敌弹减速3秒"},
	"elixir": {"name": "蓬莱之药", "rar": 1, "desc": "每局一次，心归零时复活并回2心"},
	"redtea": {"name": "吸血鬼的红茶", "rar": 1, "desc": "每击破40个敌人回1心"},
	"member": {"name": "香霖堂会员卡", "rar": 1, "desc": "商店一律7折"},
	"lantern": {"name": "人魂灯", "rar": 1, "desc": "被弹时符卡槽直接充满"},
	"camera": {"name": "天狗的相机", "rar": 1, "desc": "符卡消除的敌弹会变成钱"},
	"laevatein": {"name": "莱瓦汀", "rar": 2, "desc": "满心时伤害+50%"},
	"oozora": {"name": "大空魔术", "rar": 2, "desc": "追踪类符札的弹数翻倍"},
	"bouyu": {"name": "卯酉东海道", "rar": 2, "desc": "每章第一场普通战斗直接胜利"},
	"sage": {"name": "贤者之石", "rar": 2, "desc": "每拥有一种类型的符札，伤害+8%"},
}

const ENEMIES := {
	"fairy": {"tex": "fairy", "hp": 38.0, "r": 7.0, "coins": 1, "atk": "aim1", "cd": 1.9},
	"fairy_red": {"tex": "fairy_red", "hp": 55.0, "r": 7.0, "coins": 2, "atk": "fan3", "cd": 2.3},
	"bigfairy": {"tex": "bigfairy", "hp": 240.0, "r": 11.0, "coins": 5, "atk": "ring", "cd": 2.5},
	"kedama": {"tex": "kedama", "hp": 20.0, "r": 6.0, "coins": 1, "atk": "", "cd": 9.0},
}

const BOSSES := {
	"rumia": {"name": "露米娅", "tex": "rumia", "r": 9.0, "coins": 45, "phases": [
		{"name": "", "hp": 420.0, "pat": "rumia0"},
		{"name": "夜符「夜雀之歌」", "hp": 700.0, "pat": "rumia1"}]},
	"daiyousei": {"name": "大妖精", "tex": "daiyousei", "r": 9.0, "coins": 45, "phases": [
		{"name": "", "hp": 420.0, "pat": "dai0"},
		{"name": "妖精「绿野之风」", "hp": 700.0, "pat": "dai1"}]},
	"cirno": {"name": "琪露诺", "tex": "cirno", "r": 9.0, "coins": 90, "phases": [
		{"name": "冰符「冰瀑」", "hp": 1200.0, "pat": "cirno1"},
		{"name": "冻符「完美冻结」", "hp": 1300.0, "pat": "cirno2"},
		{"name": "雪符「钻石风暴」", "hp": 1400.0, "pat": "cirno3"}]},
}

const CHAPTERS := {
	1: {"name": "第一章 雾之湖", "elites": ["rumia", "daiyousei"], "boss": "cirno"},
}

## 事件。ops: ["money",n] ["heal",n] ["hurt",n] ["bomb"] ["relic",最低稀有度] ["upgrade"] ["maxhp",n]
## cost: 需要花的钱；alt: 50% 概率改为执行 alt
const EVENTS := [
	{"title": "路边的小神社", "text": "参道旁有一座没人打理的小神社，赛钱箱里空空如也。",
	 "choices": [
		{"text": "投入20钱（回2心）", "cost": 20, "ops": [["heal", 2]]},
		{"text": "只是拜一拜（符卡槽充满）", "ops": [["bomb"]]},
		{"text": "离开", "ops": []}]},
	{"title": "河童的摊位", "text": "荷取在路边兜售一些看起来很可疑的发明。",
	 "choices": [
		{"text": "花40钱买一件（随机宝具）", "cost": 40, "ops": [["relic", 0]]},
		{"text": "帮忙试用（一半概率强化符札，一半概率受伤）", "ops": [["upgrade"]], "alt": [["hurt", 1]]},
		{"text": "离开", "ops": []}]},
	{"title": "三月精的恶作剧", "text": "回过神来，钱包已经被光之三妖精摸走了。",
	 "choices": [
		{"text": "追上去（失去1心，夺回并多拿50钱）", "ops": [["hurt", 1], ["money", 50]]},
		{"text": "算了（失去15钱）", "ops": [["money", -15]]}]},
	{"title": "湖边的茶会", "text": "雾气里摆着一张小桌，一壶红茶还冒着热气，四下无人。",
	 "choices": [
		{"text": "坐下喝一杯（回1心）", "ops": [["heal", 1]]},
		{"text": "顺走茶叶（获得30钱）", "ops": [["money", 30]]}]},
	{"title": "毛玉的大群", "text": "数不清的毛玉堵住了去路，在空中滚来滚去。",
	 "choices": [
		{"text": "强行突破（失去1心，强化一张符札）", "ops": [["hurt", 1], ["upgrade"]]},
		{"text": "绕路走", "ops": []}]},
	{"title": "香霖的委托", "text": "森近霖之助拿出一件来历不明的古道具，想请你试用。",
	 "choices": [
		{"text": "接受（心的上限-1，获得稀有宝具）", "ops": [["maxhp", -1], ["relic", 1]]},
		{"text": "婉拒（获得15钱）", "ops": [["money", 15]]}]},
]
