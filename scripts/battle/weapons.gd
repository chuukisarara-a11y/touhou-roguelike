class_name Weapons
## 符札（武器）定义。fire() 发射一次并返回冷却时间（秒）。

static func fire(id: String, lv: int, p: Player, shots: ShotLayer) -> float:
	match id:
		"amulet":  # 博丽符札：追踪
			var n := 2 if lv < 2 else 4
			for i in n:
				var side := (i % 2) * 2 - 1
				var spread := 8.0 + 7.0 * (i / 2)
				shots.spawn("amulet", p.position + Vector2(side * spread, -4), Vector2(side * 50.0, -260.0), 4.0, 9.0, 0)
			return 0.22
		"needle":  # 封魔针：直线高速
			var n2 := 1 if lv < 2 else 2
			for i in n2:
				var off := 0.0 if n2 == 1 else (i * 2 - 1) * 4.0
				shots.spawn("needle", p.position + Vector2(off, -12), Vector2(0, -480.0), 5.0, 0.0, 1 if lv >= 3 else 0)
			return 0.12
	return 1.0
