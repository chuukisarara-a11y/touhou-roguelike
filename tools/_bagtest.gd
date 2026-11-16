extends Node
var t := 0.0
var step := 0
func _ready() -> void:
	G.new_run()
	G.main.goto("map")
func tap(p: Vector2) -> void:
	for pr in [true, false]:
		var a := InputEventMouseButton.new(); a.position = p * 2.5; a.global_position = p * 2.5; a.button_index = MOUSE_BUTTON_LEFT; a.pressed = pr; Input.parse_input_event(a)
func _process(dt: float) -> void:
	t += dt
	var h := G.field_h()
	if step == 0 and t > 0.8:
		step = 1; Bag.open(G.main.screen)
	elif step == 1 and t > 1.6:
		step = 2; print("before: ", get_tree().get_nodes_in_group("overlay").map(func(o): return o.get_instance_id())); var ov = get_tree().get_nodes_in_group("overlay")[0]; for c in ov.panel.get_children(): print("  ", c.get_class(), " ", c.position, " ", c.size, " mf=", c.mouse_filter); tap(Vector2(100, 8 + h - 16 - 28 + 11))
	elif step == 2 and t > 2.4:
		print("after: ", get_tree().get_nodes_in_group("overlay").map(func(o): return o.get_instance_id()))
		get_tree().quit()
