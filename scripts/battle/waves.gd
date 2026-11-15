class_name Waves
## 生成一场战斗的波次。每波是 [{t, kind, move}...]；精英/Boss 战是 [{t, boss}]。

static func build(chapter: int, floor_i: int, kind: String) -> Array:
	var ch: Dictionary = Db.CHAPTERS[chapter]
	if kind == "boss":
		return [[{"t": 0.0, "boss": ch.boss}]]
	if kind == "elite":
		return [[{"t": 0.0, "boss": ch.elites[G.rng.randi_range(0, ch.elites.size() - 1)]}]]
	var f := floor_i
	# 每波分两批登场，层数越高敌人越多
	var w0 := _line(3 + int(f >= 3), 0.0) + _stream(4, 3.0) + _line(3, 6.5)
	if f >= 4:
		w0 += _reds(2, 8.0)
	var w1 := _stream(5, 0.0) + _reds(2 + int(f >= 4), 1.5) + _line(4, 6.0)
	if f >= 3:
		w1 += _stream(5, 8.0)
	var w2 := _big(0.0) + _line(3, 4.0) + _stream(4, 7.0)
	if f >= 5:
		w2 += _reds(2, 6.0)
	var waves := [w0, w1, w2]
	for w in waves:
		w.sort_custom(func(a, b): return a.t < b.t)
	return waves

static func _line(n: int, t0: float) -> Array:
	var out := []
	var y := G.rng.randf_range(42, 70)
	for i in n:
		var x := G.FIELD_W * (i + 1.0) / (n + 1.0)
		out.append({"t": t0 + i * 0.3, "kind": "fairy", "move": {"type": "hover", "tx": x, "ty": y + (i % 2) * 14.0, "stay": 7.0}})
	return out

static func _reds(n: int, t0: float) -> Array:
	var out := []
	for i in n:
		var x := G.FIELD_W * (i + 1.0) / (n + 1.0) + G.rng.randf_range(-10, 10)
		out.append({"t": t0 + i * 0.5, "kind": "fairy_red", "move": {"type": "hover", "tx": x, "ty": G.rng.randf_range(50, 95), "stay": 8.0}})
	return out

static func _stream(n: int, t0: float) -> Array:
	var out := []
	var left := G.rng.randf() < 0.5
	for i in n:
		out.append({"t": t0 + i * 0.35, "kind": "kedama", "move": {"type": "swoop", "x0": 55.0 if left else G.FIELD_W - 55.0, "dir": 1.0 if left else -1.0, "speed": 62.0}})
	return out

static func _big(t0: float) -> Array:
	return [
		{"t": t0, "kind": "bigfairy", "move": {"type": "hover", "tx": G.FIELD_W / 2, "ty": 58.0, "stay": 11.0}},
		{"t": t0 + 1.0, "kind": "fairy_red", "move": {"type": "hover", "tx": 38.0, "ty": 86.0, "stay": 8.0}},
		{"t": t0 + 1.4, "kind": "fairy_red", "move": {"type": "hover", "tx": G.FIELD_W - 38.0, "ty": 86.0, "stay": 8.0}},
	]
