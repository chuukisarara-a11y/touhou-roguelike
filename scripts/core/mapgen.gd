class_name MapGen
## 生成一章的地图：7 层 + Boss，三条随机路径合并。

static func generate(chapter: int) -> Array:
	var rng: RandomNumberGenerator = G.rng
	var grid := {}
	var nodes := []
	for p in 3:
		var c := rng.randi_range(0, 2) if p > 0 else 1
		var prev := -1
		for f in 7:
			if f > 0:
				c = clampi(c + rng.randi_range(-1, 1), 0, 2)
			var key := f * 3 + c
			if not grid.has(key):
				grid[key] = nodes.size()
				nodes.append({"f": f, "c": c, "type": "battle", "next": [], "jx": rng.randf_range(-6.0, 6.0)})
			var idx: int = grid[key]
			if prev >= 0 and not nodes[prev].next.has(idx):
				nodes[prev].next.append(idx)
			prev = idx
	for n in nodes:
		var f: int = n.f
		if f == 0:
			n.type = "battle"
		elif f == 6:
			n.type = "rest"
		else:
			var types := ["battle", "event", "shop"]
			var weights := [45.0, 24.0, 12.0]
			if f >= 2:
				types.append("elite"); weights.append(14.0)
			if f >= 3:
				types.append("rest"); weights.append(6.0)
			n.type = types[G._weighted(weights)]
	_ensure(nodes, "shop", 2, 4)
	_ensure(nodes, "elite", 3, 5)
	if chapter == 2:   # 第二章的碎片要打赢 2 场精英：保证至少有一条路线经过 2 个精英
		_ensure_elite_path(nodes, 2)
	var boss := nodes.size()
	nodes.append({"f": 7, "c": 1, "type": "boss", "next": [], "jx": 0.0})
	for n in nodes:
		if n.f == 6:
			n.next = [boss]
	return nodes

static func _ensure(nodes: Array, type: String, f0: int, f1: int) -> void:
	for n in nodes:
		if n.type == type:
			return
	var cands := nodes.filter(func(n): return n.f >= f0 and n.f <= f1 and n.type == "battle")
	if cands.is_empty():
		cands = nodes.filter(func(n): return n.f >= f0 and n.f <= f1)
	if not cands.is_empty():
		cands[G.rng.randi_range(0, cands.size() - 1)].type = type

## 某条路线上最多能遇到几个精英（按层从后往前算）
static func _max_elites(nodes: Array) -> int:
	var best := {}
	var order := range(nodes.size())
	order.sort_custom(func(a, b): return nodes[a].f > nodes[b].f)
	for i in order:
		var m := 0
		for j in nodes[i].next:
			m = maxi(m, best.get(j, 0))
		best[i] = m + (1 if nodes[i].type == "elite" else 0)
	var top := 0
	for i in nodes.size():
		if nodes[i].f == 0:
			top = maxi(top, best[i])
	return top

static func _ensure_elite_path(nodes: Array, need: int) -> void:
	if _max_elites(nodes) >= need:
		return
	# 随机走一条路，在第 2～5 层里挑不相邻的两层改成精英
	var starts := []
	for i in nodes.size():
		if nodes[i].f == 0:
			starts.append(i)
	var path := []
	var cur: int = starts[G.rng.randi_range(0, starts.size() - 1)]
	while nodes[cur].f < 6:
		path.append(cur)
		var nx: Array = nodes[cur].next
		cur = nx[G.rng.randi_range(0, nx.size() - 1)]
	var mids := path.filter(func(i): return nodes[i].f >= 2 and nodes[i].f <= 5)
	var have := mids.filter(func(i): return nodes[i].type == "elite").size()
	mids.shuffle()
	for i in mids:
		if have >= need:
			break
		if nodes[i].type == "elite":
			continue
		var adj := false
		for k in mids:
			if nodes[k].type == "elite" and absi(nodes[k].f - nodes[i].f) == 1:
				adj = true
		if adj and mids.size() > need + 1:
			continue
		nodes[i].type = "elite"
		have += 1
	for i in mids:   # 实在不够（路线太短）就不管相邻了
		if have >= need:
			break
		if nodes[i].type != "elite":
			nodes[i].type = "elite"
			have += 1
