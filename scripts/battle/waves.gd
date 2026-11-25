class_name Waves
## 生成一场战斗的波次。每波是 [{t, kind, move}...]；精英/Boss 战是 [{t, boss}]。
## 每场从 6 种编队模板里随机抽 3 种，再混入本章的机制小怪，保证每场都不一样。

static var _mobs := ["fairy", "fairy_red", "bigfairy", "kedama"]

static func build(chapter: int, floor_i: int, kind: String) -> Array:
	var ch: Dictionary = G.chap(chapter)
	if kind == "boss":
		return [[{"t": 0.0, "boss": ch.boss}]]
	if kind == "elite":
		return [[{"t": 0.0, "boss": ch.elites[G.rng.randi_range(0, ch.elites.size() - 1)]}]]
	var f := floor_i
	_mobs = ch.mobs
	var sp: Array = ch.get("specials", [])
	var tpl := [0, 1, 2, 3, 4, 5]
	for i in range(tpl.size() - 1, 0, -1):
		var j := G.rng.randi_range(0, i)
		var tmp: int = tpl[i]; tpl[i] = tpl[j]; tpl[j] = tmp
	var waves := []
	var used := []
	# 小怪密度：第 2 章 ×3、第 3 章 ×4、第 4 章 ×4.5。多出来的部分用其他编队模板，按批次错开出场
	var dens: float = [1.0, 1.0, 3.0, 4.0, 4.5][clampi(chapter, 1, 4)]
	for i in 3:
		var w := _template(tpl[i], f)
		var extra := dens - 1.0
		var c := 0
		while extra > 0.0:
			if extra < 1.0 and G.rng.randf() >= extra:
				break
			c += 1
			for s0 in _template(tpl[(i + c * 2) % tpl.size()], f):
				s0.t += c * 2.4
				w.append(s0)
			extra -= 1.0
		if f >= 4:
			w += _reds(2, 8.0)
		# 机制小怪：第 1 层没有；之后每波一组，高层两组
		var n_sp := 0 if f <= 1 else (1 if f <= 4 else 2)
		if chapter == 1 and f == 2 and i == 0:
			n_sp = 0
		for k in n_sp:
			var pool := sp.filter(func(x): return not used.has(x))
			if pool.is_empty():
				used.clear()
				pool = sp
			var id: String = pool[G.rng.randi_range(0, pool.size() - 1)]
			used.append(id)
			w += _special(id, G.rng.randf_range(1.0, 4.0) + k * 3.0)
		w.sort_custom(func(a, b): return a.t < b.t)
		waves.append(w)
	return waves

static func _template(id: int, f: int) -> Array:
	match id:
		0: return _line(3 + int(f >= 3), 0.0) + _stream(4, 3.0) + _line(3, 6.5)
		1: return _stream(5, 0.0) + _reds(2 + int(f >= 4), 1.5) + _line(4, 6.0)
		2: return _big(0.0) + _line(3, 4.0) + _stream(4, 7.0)
		3: return _stream(4, 0.0, 1) + _stream(4, 0.2, -1) + _reds(3, 2.5) + _line(3, 6.0)
		4: return _line(5, 0.0) + _reds(2, 3.0) + _stream(5, 5.5)
	return _reds(3, 0.0) + _big(3.0) + _stream(4, 7.0)

static func _hover(kind: String, t: float, x: float, y: float, stay: float) -> Dictionary:
	return {"t": t, "kind": kind, "move": {"type": "hover", "tx": x, "ty": y, "stay": stay}}

static func _special(id: String, t0: float) -> Array:
	var r: RandomNumberGenerator = G.rng
	var W := G.FIELD_W
	match id:
		"m_shield":
			return [_hover(id, t0, r.randf_range(60, W - 60), 66.0, 13.0)]
		"m_split":
			return [_hover(id, t0, r.randf_range(50, W - 50), 62.0, 10.0)]
		"m_bomber":
			var out := []
			for i in 3:
				out.append({"t": t0 + i * 0.7, "kind": id, "move": {"type": "chase", "x0": r.randf_range(20, W - 20)}})
			return out
		"m_mine":
			return [_hover(id, t0, r.randf_range(40, W - 40), r.randf_range(80, 120), 9.0)]
		"m_sniper":
			return [_hover(id, t0, 26.0, r.randf_range(40, 60), 9.0), _hover(id, t0 + 0.6, W - 26.0, r.randf_range(40, 60), 9.0)]
		"m_guard":
			return [_hover(id, t0, W / 2.0 + r.randf_range(-20, 20), 72.0, 11.0)]
		"m_runner":
			return [{"t": t0, "kind": id, "move": {"type": "run", "dir": 1.0 if r.randf() < 0.5 else -1.0, "y": r.randf_range(50, 110)}}]
		"m_gap":
			return [{"t": t0, "kind": id, "move": {"type": "gapdive", "tx": r.randf_range(40, W - 40), "ty": r.randf_range(44, 70)}}]
		"m_mirror":
			return [{"t": t0, "kind": id, "move": {"type": "mirror", "tx": r.randf_range(40, W - 40), "ty": 56.0, "stay": 9.0}}]
	return []

static func _line(n: int, t0: float) -> Array:
	var out := []
	var y := G.rng.randf_range(42, 70)
	for i in n:
		var x := G.FIELD_W * (i + 1.0) / (n + 1.0)
		out.append(_hover(_mobs[0], t0 + i * 0.3, x, y + (i % 2) * 14.0, 7.0))
	return out

static func _reds(n: int, t0: float) -> Array:
	var out := []
	for i in n:
		var x := G.FIELD_W * (i + 1.0) / (n + 1.0) + G.rng.randf_range(-10, 10)
		out.append(_hover(_mobs[1], t0 + i * 0.5, x, G.rng.randf_range(50, 95), 8.0))
	return out

static func _stream(n: int, t0: float, side := 0) -> Array:
	var out := []
	var left := (G.rng.randf() < 0.5) if side == 0 else side > 0
	for i in n:
		out.append({"t": t0 + i * 0.35, "kind": _mobs[3], "move": {"type": "swoop", "x0": 55.0 if left else G.FIELD_W - 55.0, "dir": 1.0 if left else -1.0, "speed": 62.0}})
	return out

static func _big(t0: float) -> Array:
	return [_hover(_mobs[2], t0, G.FIELD_W / 2, 58.0, 11.0), _hover(_mobs[1], t0 + 1.0, 38.0, 86.0, 8.0), _hover(_mobs[1], t0 + 1.4, G.FIELD_W - 38.0, 86.0, 8.0)]
