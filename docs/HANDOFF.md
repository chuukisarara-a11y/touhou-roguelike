# 交接文档（给之后接手开发的模型 / 人）

> 截至 v0.13（2026-11-16）。之前由 Claude Fable 5.2 开发，之后由 Opus 5.5 接手。
> 用户：チュウキ（辉）。**只用中文交流**，手机上看回复，回复要短。

## 0. 和用户合作的规矩
- 一步一步做，每做完一步就停下来等指示；顺带报告大概用了多少用量。
- 每一步都要 commit 并 push 到 `main`（仓库 `chuukisarara-a11y/touhou-roguelike`）。
- 每个版本都要打 APK 发给用户（他在安卓手机上试玩，然后给反馈）。
- **音乐只能是东方原曲的改编，绝对不能自己作曲，也不能由模型自己写出 ZUN 的旋律。**
  流程：用户自己扒谱写旋律 MIDI → 放到 `assets/music/src/<槽位>.mid` → 用 `tools/chiptune.py` 编成 8-bit 风格 → `assets/music/<槽位>.ogg`。
  **编曲方针（2026-11-19）：保留主旋律，尽量多加乐器、丰富听感**（chiptune.py 已升级），每首曲子的命令记在 README 的表里。
  槽位见 `assets/music/README.md`（title 已完成；map、battleN、bossN、result、gameover 待补，缺的槽位静音）。
- 设计原则（用户反复强调过）：
  - Boss 符卡不求多，要**密、要华丽**；固定弹道要带一点随机，不能有一条直线就能穿过去的缝。
  - 激光类符卡：只扫过下方约 3/5 的区域就消失，留安全区（`Spells.sweep_lasers`）。
  - 手机屏幕很长（高度 > 356），弹幕要能铺到屏幕下半。
  - **机制放在秘符上，宝具以数值为主**。
  - 局外成长要克制：只解锁内容，不给数值。

## 1. 长期计划
1. 每周：用户扒一首曲子的旋律 → 编曲 → 加进游戏。
2. 平时：修 bug、按试玩反馈调弹幕。
3. 用量充足时做新角色：**蕾米莉亚、藤原妹红、宇佐见莲子**。规格照魔理沙：
   自己的初始攻符 + 符卡（Bomb）+ 12 张左右专属秘符 + 自己的对话 / 剧情路线 / 场景 / 专属 Boss
   （见 `Db.CHARS.marisa`、`Db.TALKS_BY`、`G.chap()`）。
4. **Windows 11 / macOS 10.15 移植推迟到音乐全部补完之后**（`tools/build.sh Windows|macOS` 已经能出包，只是没调过键鼠手感和窗口）。

## 2. 环境（工作区重置后要重装）
- Godot 4.3 stable（Linux 可执行文件）放在 `/home/claude/tools/godot`；
  导出模板放 `~/.local/share/godot/export_templates/4.3.stable/`。
- 安卓 SDK 下载不了，用 apt 的 `apksigner zipalign adb` 拼了一个假 SDK：`/home/claude/tools/android-sdk`，
  在 `~/.config/godot/editor_settings-4.3.tres` 里指过去。
- 签名：`/home/claude/tools/release.keystore`（别名 `touhourogue`）。**不在公开仓库里**，用户手里有一份；
  工作区被重置的话要让用户重新传上来，否则新包无法覆盖安装旧包。
- 打包：`tools/build.sh Android` → `build/touhou-yakou.apk`，复制成 `东方夜行符-vX.Y.apk` 发给用户。
- 每次发版要改三处：`export_presets.cfg` 的 `version/code`、`version/name`，`scripts/screens/title.gd` 里的版本号。

## 3. 测试
改完代码先跑：`godot --headless --path . --import 2>&1 | grep -E "Parse|SCRIPT"`
- 机器人整局回归：`godot --headless --path . -- --autotest --runs=2 --seed=7 [--char=marisa]`，看 `AUTOTEST win=true ...`。
  （headless 下会刷 `Parameter "t" is null`，是空渲染器的噪音，不用管。）
- 带画面截图：`xvfb-run -a -s "-screen 0 500x890x24" godot --path . --rendering-driver opengl3 -- <参数> > 日志 2>&1`
  - `--spelltest [--few]`：每张 Boss 符卡截图到 `/tmp/spx`，并统计最多子弹数
  - `--metatest`：标题 / 图鉴 / 角色选择 / 说明 / 行囊详情 / 神社
  - `--uitest --scrolltest --mobtest --bagtest --chartest`：见 `tools/*.gd`
  - 输出一定要重定向到文件再看，直接接 grep 会在超时被杀时丢掉报错。

## 4. 代码结构
- 逻辑宽度固定 200，高度随手机变化（≥356）；贴图是 2 倍密度（角色 4 倍），`G.tex()` 取图。
- `scripts/core/`：`game.gd`（自动加载 `G`：存档、本局状态、卡牌 / 宝具 / 秘符、异变等级、成就、图鉴）、
  `data.gd`（`Db`：所有数据表和文本）、`main.gd`（界面切换、BGM、提示条）、`ui.gd`（`UI`：按钮、弹出层、滚动、卡面）、
  `bag.gd`、`dev.gd`、`audio.gd`、`mapgen.gd`、`autotest.gd`。
- `scripts/battle/`：`battle.gd`（主循环、擦弹、符卡、被弹）、`bullets.gd`（子弹 / 激光 / 消弹动画）、
  `spells.gd`（所有 Boss 符卡，一张符卡一个 `match` 分支）、`patterns.gd`（杂鱼）、`enemies.gd`、`waves.gd`、
  `player.gd`、`shots.gd`、`weapons.gd`、`items.gd`、`hud.gd`、`fx.gd`。
- `scripts/screens/`：title、chars、map、talk、event、reward、shop、rest、result、gallery、codex、assets。
- 美术全部由 `tools/gen_art.py` 程序生成，音效 `tools/gen_sfx.py`，编曲 `tools/chiptune.py`。
- 标题界面点月亮输入 `gensokyo` 开关开发者菜单（跳章节、直接打某个 Boss、无敌）。
- GDScript 的坑：lambda 按值捕获局部变量（要自引用就用数组装一下）；`var x := 无类型表达式` 会推断失败，要写明类型。

## 5. v0.13 新增的系统（改的时候注意）
- 符卡限时：有名字的符卡默认 45 秒（`phases[i].time` 可单独设），到时间直接进下一张，不算收取。
- 被弹只清身边半径 64 的子弹；无敌期间碰到的子弹会被擦掉（`bullets.gd`）。
- 异变等级 0–10（`Db.ASC`，`G.asc()`），按角色记录，通关当前最高级解锁下一级。
- 成就（`Db.ACH`，`G.ach(id)`）、图鉴（`G.codex(id)`，符卡记录在 `G.meta.spells`），都不给数值。
- 游戏说明（`Db.TUTORIAL`，`UI.tutorial()`），第一次出发时自动弹出。
- 弹出层按打开顺序叠放（`UI.Overlay._enter_tree`）。

## 6. 还没在真机上验证的
v0.13 改过的符卡（露米娅、琪露诺、爱丽丝三张、帝、蓝、铃仙、辉夜）的实际难度；异变等级各级的手感；限时 45 秒是否合适。
