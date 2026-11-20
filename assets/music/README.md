# BGM 槽位

把编配好的 OGG 放在这个文件夹里，文件名对应槽位，游戏会自动循环播放；缺哪个文件，哪个场景就保持安静。

| 文件名 | 场景 |
|---|---|
| title.ogg | 标题画面 |
| map.ogg | 地图、商店、事件、神社、奖励界面 |
| battle1.ogg | 第一章普通战斗与精英战 |
| boss1.ogg | 第一章 Boss 战 |
| result.ogg | 通关结算 |
| gameover.ogg | 失败结算 |

之后的章节依次是 battle2 / boss2、battle3 / boss3、battle4 / boss4。

8bit 版（当前采用）：`python3 tools/chiptune.py assets/music/src/<名字>.mid <槽位> --sections "起始小节:调:强度,..."`，参数说明见脚本开头。

**编曲方针（用户要求，2026-11-19）**：保留用户写的主旋律一音不改，在此基础上尽量多加乐器、丰富听感（8bit 方波主音 + 失谐加厚、三度和声、合成铺底、钟琴、三角波+正弦贝斯、完整鼓组与过门、混响）。之后每首曲子都按这个标准编。

已完成的曲子与参数：

| 槽位 | 命令 |
|---|---|
| title | `python3 tools/chiptune.py assets/music/src/title.mid title --sections "0:E:1,18:E:3,20:Eb:3,42:E:2,62:E:4" --intro-prog "E,C#m,A,B"` |

GM 乐器版：`python3 tools/arrange.py 旋律.mid battle1 --style stage`
风格：stage（道中，小号+钢琴+摇滚鼓）、boss（合成主音+小号+快鼓）、calm（钢琴+长笛，轻打击）。
