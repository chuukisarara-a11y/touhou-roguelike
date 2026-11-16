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
	"rift": {"name": "境界裂隙", "tag": "特殊", "desc": ["在敌人身旁打开隙间，贴脸射出3发光弹，必定命中", "同时打开2道隙间", "隙间伤害+50%"]},
	"starmap": {"name": "星图", "tag": "特殊", "desc": ["每击破8个敌人，降下一次流星雨", "流星数量翻倍", "只需击破5个敌人"]},
}

const WEAPON_ICON := {"laser": "ic_laser", "pillar": "ic_pillar", "starmap": "ic_starmap", "rift": "gap"}

const SYNERGIES := [
	{"name": "追踪×2", "desc": "追踪类伤害+30%"},
	{"name": "火+冰", "desc": "蒸汽爆炸：范围伤害"},
	{"name": "直线+穿透", "desc": "封魔针与镭射伤害+25%"},
	{"name": "召唤+环绕", "desc": "人偶射速+30%"},
]

const RELICS := {
	"hakkero": {"g": "炉", "name": "迷你八卦炉", "rar": 0, "desc": "伤害+15%"},
	"fan": {"g": "扇", "name": "天狗的团扇", "rar": 0, "desc": "移动速度+15%"},
	"onigiri": {"g": "饭", "name": "幽灵饭团", "rar": 0, "desc": "每完成2场战斗回1心"},
	"camo": {"g": "彩", "name": "河童的光学迷彩", "rar": 0, "desc": "被弹后的无敌时间+1秒"},
	"saisen": {"g": "钱", "name": "赛钱箱", "rar": 0, "desc": "拾取的钱有25%概率翻倍"},
	"charm": {"g": "符", "name": "博丽护身符", "rar": 0, "desc": "心的上限+1"},
	"tea": {"g": "茶", "name": "上等茶叶", "rar": 0, "desc": "擦弹充能+40%"},
	"gohei": {"g": "币", "name": "灵梦的御币", "rar": 1, "desc": "擦弹范围×1.5"},
	"watch": {"g": "表", "name": "咲夜的怀表", "rar": 1, "desc": "发动符卡后敌弹减速3秒"},
	"elixir": {"g": "药", "name": "蓬莱之药", "rar": 1, "desc": "每局一次，心归零时复活并回2心"},
	"redtea": {"g": "红", "name": "吸血鬼的红茶", "rar": 1, "desc": "每击破40个敌人回1心"},
	"member": {"g": "卡", "name": "香霖堂会员卡", "rar": 1, "desc": "商店一律7折"},
	"lantern": {"g": "灯", "name": "人魂灯", "rar": 1, "desc": "被弹时符卡槽直接充满"},
	"camera": {"g": "机", "name": "天狗的相机", "rar": 1, "desc": "符卡消除的敌弹会变成钱"},
	"laevatein": {"g": "剑", "name": "莱瓦汀", "rar": 2, "desc": "满心时伤害+50%"},
	"oozora": {"g": "空", "name": "大空魔术", "rar": 2, "desc": "追踪类符札的弹数翻倍"},
	"bouyu": {"g": "道", "name": "卯酉东海道", "rar": 2, "desc": "每章第一场普通战斗直接胜利"},
	"sage": {"g": "石", "name": "贤者之石", "rar": 2, "desc": "每拥有一种类型的符札，伤害+8%"},
}

const ENEMIES := {
	"fairy": {"tex": "c_fairy", "anim": true, "hp": 38.0, "r": 7.0, "coins": 1, "atk": "aim1", "cd": 1.6},
	"fairy_red": {"tex": "c_fairy_red", "anim": true, "hp": 55.0, "r": 7.0, "coins": 2, "atk": "fan3", "cd": 1.95},
	"bigfairy": {"tex": "c_bigfairy", "anim": true, "hp": 260.0, "r": 9.0, "coins": 5, "atk": "ring", "cd": 2.1},
	"kedama": {"tex": "kedama", "anim": true, "hp": 20.0, "r": 6.0, "coins": 1, "atk": "", "cd": 9.0},
	# 第二章
	"maid": {"tex": "c_maid", "anim": true, "hp": 40.0, "r": 7.0, "coins": 1, "atk": "burst3", "cd": 1.8},
	"book": {"tex": "book", "hp": 60.0, "r": 7.0, "coins": 2, "atk": "ring8", "cd": 2.0},
	"bigbook": {"tex": "book", "hp": 280.0, "r": 8.0, "coins": 5, "atk": "spiral", "cd": 0.45},
	"bat": {"tex": "bat", "anim": true, "hp": 20.0, "r": 6.0, "coins": 1, "atk": "aim1", "cd": 1.4},
	# 第三章
	"rabbit": {"tex": "c_rabbit", "hp": 42.0, "r": 7.0, "coins": 1, "atk": "fan5", "cd": 2.0},
	"bamboo": {"tex": "c_bamboo", "anim": true, "hp": 58.0, "r": 7.0, "coins": 2, "atk": "cross", "cd": 1.5},
	"bigghost": {"tex": "ghost_big", "hp": 300.0, "r": 10.0, "coins": 5, "atk": "ringaim", "cd": 2.2},
	"ghost": {"tex": "ghost", "hp": 22.0, "r": 6.0, "coins": 1, "atk": "slowbig", "cd": 1.6},
	# 第四章
	"eye": {"tex": "eye", "hp": 44.0, "r": 7.0, "coins": 1, "atk": "burst3", "cd": 1.6},
	"shiki": {"tex": "shiki", "hp": 60.0, "r": 6.0, "coins": 2, "atk": "cross", "cd": 1.2},
	"bigeye": {"tex": "eye_big", "hp": 320.0, "r": 10.0, "coins": 6, "atk": "ringaim", "cd": 1.9},
}

const BOSSES := {
	"ran": {"name": "八云蓝", "tex": "c_ran", "r": 9.0, "coins": 60, "phases": [
		{"name": "", "hp": 500.0, "pat": "ran0"},
		{"name": "式神「十二神将之宴」", "hp": 860.0, "pat": "ran1"}]},
	"yukari": {"name": "八云紫", "tex": "c_yukari", "r": 9.0, "coins": 150, "phases": [
		{"name": "境符「四重结界」", "hp": 1500.0, "pat": "yuk1"},
		{"name": "结界「光与暗的网目」", "hp": 1600.0, "pat": "yuk2"},
		{"name": "「弹幕结界」", "hp": 1800.0, "pat": "yuk3"}]},
	"rumia": {"name": "露米娅", "tex": "c_rumia", "r": 9.0, "coins": 45, "phases": [
		{"name": "", "hp": 480.0, "pat": "rumia0"},
		{"name": "夜符「夜雀之歌」", "hp": 800.0, "pat": "rumia1"}]},
	"daiyousei": {"name": "大妖精", "tex": "c_daiyousei", "anim": true, "r": 9.0, "coins": 45, "phases": [
		{"name": "", "hp": 480.0, "pat": "dai0"},
		{"name": "妖精「绿野之风」", "hp": 800.0, "pat": "dai1"}]},
	"cirno": {"name": "琪露诺", "tex": "c_cirno", "anim": true, "r": 9.0, "coins": 90, "phases": [
		{"name": "冰符「冰瀑」", "hp": 1400.0, "pat": "cirno1"},
		{"name": "冻符「完美冻结」", "hp": 1500.0, "pat": "cirno2"},
		{"name": "雪符「钻石风暴」", "hp": 1600.0, "pat": "cirno3"}]},
	"meiling": {"name": "红美铃", "tex": "c_meiling", "r": 9.0, "coins": 50, "phases": [
		{"name": "", "hp": 480.0, "pat": "mei0"},
		{"name": "华符「芳华绚烂」", "hp": 820.0, "pat": "mei1"}]},
	"patchouli": {"name": "帕秋莉", "tex": "c_patchouli", "r": 9.0, "coins": 50, "phases": [
		{"name": "", "hp": 480.0, "pat": "pat0"},
		{"name": "火水符「燃素之雨」", "hp": 820.0, "pat": "pat1"}]},
	"sakuya": {"name": "十六夜咲夜", "tex": "c_sakuya", "r": 9.0, "coins": 100, "phases": [
		{"name": "幻象「月神之钟」", "hp": 1400.0, "pat": "saku1"},
		{"name": "幻世「The World」", "hp": 1500.0, "pat": "saku2"},
		{"name": "幻符「杀人玩偶」", "hp": 1600.0, "pat": "saku3"}]},
	"tewi": {"name": "因幡帝", "tex": "c_tewi", "r": 9.0, "coins": 55, "phases": [
		{"name": "", "hp": 480.0, "pat": "tewi0"},
		{"name": "兔符「因幡的素兔」", "hp": 820.0, "pat": "tewi1"}]},
	"reisen": {"name": "铃仙", "tex": "c_reisen", "r": 9.0, "coins": 55, "phases": [
		{"name": "", "hp": 480.0, "pat": "rei0"},
		{"name": "幻波「赤眼催眠」", "hp": 820.0, "pat": "rei1"}]},
	"kaguya": {"name": "蓬莱山辉夜", "tex": "c_kaguya", "r": 9.0, "coins": 110, "phases": [
		{"name": "难题「佛御石之钵」", "hp": 1400.0, "pat": "kagu1"},
		{"name": "难题「火鼠的皮衣」", "hp": 1500.0, "pat": "kagu2"},
		{"name": "难题「蓬莱的玉枝」", "hp": 1600.0, "pat": "kagu3"}]},
}

## mobs: 波次生成用的四种角色 [排成一排的, 火力点, 大型, 成串冲下来的]
const CHAPTERS := {
	1: {"name": "第一章 雾之湖", "bg": "lake", "elites": ["rumia", "daiyousei"], "boss": "cirno", "mobs": ["fairy", "fairy_red", "bigfairy", "kedama"]},
	2: {"name": "第二章 红魔馆", "bg": "mansion", "elites": ["meiling", "patchouli"], "boss": "sakuya", "mobs": ["maid", "book", "bigbook", "bat"]},
	3: {"name": "第三章 迷途竹林", "bg": "bamboo", "elites": ["tewi", "reisen"], "boss": "kaguya", "mobs": ["rabbit", "bamboo", "bigghost", "ghost"]},
	4: {"name": "终章 境界的缝隙", "bg": "gap", "elites": ["ran"], "boss": "yukari", "mobs": ["eye", "shiki", "bigeye", "ghost"]},
}

## Boss 战前对话。choices 的 op: bomb 符卡槽充满 / heal 回1心 / money 得 n 钱
const TALKS := {
	"yukari": {"lines": [
		["boss", "哎呀，居然真的找到这里来了。把碎片一片一片捡起来，辛苦你了。"],
		["reimu", "果然是你。月亮是你动的手脚？"],
		["boss", "只是把夜晚和白天的境界稍微挪了一下。夜长一点，不是正适合赏月吗。"],
		["reimu", "托你的福，妖精、女仆、兔子全都乱了套。"],
		["boss", "那么，就请博丽的巫女亲手把它拨回去吧——如果你做得到的话。"]],
	 "choices": [
		{"text": "「做不到的话，我就不会来了。」", "op": "bomb", "reply": "呵呵，这才像话。来吧，让我看看这一夜你长进了多少。"},
		{"text": "「打完请我喝酒，就当没发生过。」", "op": "heal", "reply": "成交。不过酒钱嘛，就从你的赛钱箱里出好了。"}]},
	"cirno": {"lines": [
		["boss", "站住！这片湖是本大爷的地盘！"],
		["reimu", "又是你啊。今晚雾这么大，是你搞的鬼？"],
		["boss", "不知道！但是只要打赢你，大家就会承认我是最强的了！"],
		["reimu", "……算了，问你也是白问。"]],
	 "choices": [
		{"text": "「那就速战速决。」", "op": "bomb", "reply": "哼，可别哭着回去哦！"},
		{"text": "「输了的话，湖边的赛钱归我。」", "op": "money", "n": 30, "reply": "赛、赛钱？！那是我攒了好久的……才不会输！"}]},
	"sakuya": {"lines": [
		["boss", "欢迎光临红魔馆。很遗憾，大小姐今晚不见客。"],
		["reimu", "我不是来做客的。馆里的妖精发了疯似的往外冲，怎么回事？"],
		["boss", "那是……馆内的事务。请回吧，地毯才刚打扫过。"],
		["reimu", "那可不行。月亮变成那个样子，总得有人负责。"],
		["boss", "那么，请容我用飞刀送客。"]],
	 "choices": [
		{"text": "「我赶时间，快点。」", "op": "bomb", "reply": "时间吗。在这座馆里，那是我说了算的东西。"},
		{"text": "「打完记得上茶。」", "op": "heal", "reply": "……茶已经备好了。不过，要等您站得起来再说。"}]},
	"kaguya": {"lines": [
		["boss", "哎呀，这么晚了还有客人。永琳，是你叫的外卖吗？"],
		["reimu", "谁是外卖啊。竹林里的兔子到处乱窜，是你们干的吧。"],
		["boss", "今晚的月亮有些奇怪，她们只是坐不住罢了。"],
		["reimu", "月亮……果然，一路上的异变都和它有关。"],
		["boss", "想知道的话，就先解开我的难题吧。放心，今晚只出三道。"]],
	 "choices": [
		{"text": "「三道就三道。」", "op": "bomb", "reply": "真干脆。上一个这么说的人，现在还在竹林里迷路呢。"},
		{"text": "「解开了有奖品吗？」", "op": "money", "n": 40, "reply": "呵呵，先付你一点定金好了。剩下的，赢了再说。"}]},
}

## 事件。ops: ["money",n] ["heal",n] ["hurt",n] ["bomb"] ["relic",最低稀有度] ["upgrade"] ["maxhp",n]
## cost: 需要花的钱；alt: 50% 概率改为执行 alt
const EVENTS := [
	{"title": "路边的小神社", "art": "ev_shrine", "text": "参道旁有一座没人打理的小神社，赛钱箱里空空如也。",
	 "talk": [["旁白", "参道旁有一座没人打理的小神社，赛钱箱里空空如也。"], ["灵梦", "……同行啊。看着怪心酸的。"]],
	 "choices": [
		{"text": "投入20钱（回2心）", "cost": 20, "say": "（清脆的一声，心里踏实了不少。）", "ops": [["heal", 2]]},
		{"text": "只是拜一拜（符卡槽充满）", "ops": [["bomb"]]},
		{"text": "离开", "ops": []}]},
	{"title": "河童的摊位", "art": "ev_kappa", "text": "荷取在路边兜售一些看起来很可疑的发明。",
	 "talk": [["荷取", "哟，盟友！来看看河童的最新发明吧，童叟无欺！"], ["灵梦", "上次你卖我的自动扫帚，把神社的屋顶扫飞了。"], ["荷取", "那、那是旧型号！这次的绝对没问题！"]],
	 "choices": [
		{"text": "花40钱买一件（随机宝具）", "cost": 40, "say": "荷取：「谢谢惠顾！坏了不退哦！」", "ops": [["relic", 0]]},
		{"text": "帮忙试用（一半概率强化符札，一半概率受伤）", "ops": [["upgrade"]], "alt": [["hurt", 1]]},
		{"text": "离开", "ops": []}]},
	{"title": "三月精的恶作剧", "art": "ev_fairies", "text": "回过神来，钱包已经被光之三妖精摸走了。",
	 "talk": [["桑尼", "嘿嘿，得手啦！巫女的钱包好轻哦！"], ["露娜", "嘘——！她看过来了！"], ["灵梦", "……你们三个，给我站住。"]],
	 "choices": [
		{"text": "追上去（失去1心，夺回并多拿50钱）", "say": "斯塔：「呜哇，她真的追上来了——！」", "ops": [["hurt", 1], ["money", 50]]},
		{"text": "算了（失去15钱）", "ops": [["money", -15]]}]},
	{"title": "湖边的茶会", "art": "ev_tea", "text": "雾气里摆着一张小桌，一壶红茶还冒着热气，四下无人。",
	 "talk": [["旁白", "雾气里摆着一张小桌，一壶红茶还冒着热气，四下无人。"], ["灵梦", "这个香味……是红魔馆的茶叶。谁落在这儿的？"]],
	 "choices": [
		{"text": "坐下喝一杯（回1心）", "say": "（很好喝。身体暖和起来了。）", "ops": [["heal", 1]]},
		{"text": "顺走茶叶（获得30钱）", "ops": [["money", 30]]}]},
	{"title": "毛玉的大群", "art": "ev_kedama", "text": "数不清的毛玉堵住了去路，在空中滚来滚去。",
	 "talk": [["旁白", "数不清的毛玉堵住了去路，在空中滚来滚去。"], ["灵梦", "啧，偏偏在这种时候。"]],
	 "choices": [
		{"text": "强行突破（失去1心，强化一张符札）", "say": "（弄得一身毛，不过手感练出来了。）", "ops": [["hurt", 1], ["upgrade"]]},
		{"text": "绕路走", "ops": []}]},
	{"title": "香霖的委托", "art": "ev_kourin", "text": "森近霖之助拿出一件来历不明的古道具，想请你试用。",
	 "talk": [["霖之助", "你来得正好。这件道具是今早在无缘冢捡到的。"], ["灵梦", "又是来历不明的东西。它有什么用？"], ["霖之助", "名字是知道的，用途嘛……所以才想请你试试。"]],
	 "choices": [
		{"text": "接受（心的上限-1，获得稀有宝具）", "say": "霖之助：「果然很有意思。记得告诉我使用感想。」", "ops": [["maxhp", -1], ["relic", 1]]},
		{"text": "婉拒（获得15钱）", "ops": [["money", 15]]}]},
]
