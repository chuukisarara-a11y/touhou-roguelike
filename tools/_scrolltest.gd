extends Node
var t := 0.0
var step := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	G.main.goto("assets")
func drag(from: Vector2, dy: float) -> void:
	var a := InputEventScreenTouch.new(); a.position = from; a.pressed = true; Input.parse_input_event(a)
	for i in 10:
		var d := InputEventScreenDrag.new(); d.position = from + Vector2(0, dy * (i + 1) / 10.0); d.relative = Vector2(0, dy / 10.0); Input.parse_input_event(d)
	var r := InputEventScreenTouch.new(); r.position = from + Vector2(0, dy); r.pressed = false; Input.parse_input_event(r)
func _process(dt: float) -> void:
	t += dt
	if step == 0 and t > 0.8:
		step = 1; drag(Vector2(100, 300), -200)
	elif step == 1 and t > 1.6:
		step = 2
		var sc = G.main.screen.get_children().filter(func(c): return c is UI.Scroll)[0]
		print("assets scrolled to ", sc.content.position.y, " / max ", -sc._max_scroll(), " overlays=", get_tree().get_nodes_in_group("overlay").size())
		G.meta.seen = {"reimu": true, "cirno": true, "sakuya": true, "yukari": true}
		G.main.goto("gallery")
	elif step == 2 and t > 2.4:
		step = 3; drag(Vector2(100, 250), 0)
	elif step == 3 and t > 3.2:
		step = 4
		var sc2 = G.main.screen.get_children().filter(func(c): return c is UI.Scroll)[0]
		print("gallery scrolled to ", sc2.content.position.y, " / max ", -sc2._max_scroll())
		var a := InputEventScreenTouch.new(); a.position = Vector2(30, 60); a.pressed = true; Input.parse_input_event(a)
		var r := InputEventScreenTouch.new(); r.position = Vector2(30, 60); r.pressed = false; Input.parse_input_event(r)
	elif step == 4 and t > 3.8:
		print("tap opened overlay: ", get_tree().get_nodes_in_group("overlay").size())
		get_tree().quit()
