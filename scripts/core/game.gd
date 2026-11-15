extends Node
## 全局单例：常量、输入映射、通用工具。

const FIELD_W := 270.0
var touch_mode := false  # 手机/平板为 true（决定是否启用松手慢动作）

func _ready() -> void:
	_add_keys("move_left", [KEY_LEFT, KEY_A])
	_add_keys("move_right", [KEY_RIGHT, KEY_D])
	_add_keys("move_up", [KEY_UP, KEY_W])
	_add_keys("move_down", [KEY_DOWN, KEY_S])
	_add_keys("slow", [KEY_SHIFT])
	_add_keys("bomb", [KEY_X, KEY_SPACE])
	touch_mode = OS.has_feature("mobile")

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func field_h() -> float:
	return get_viewport().get_visible_rect().size.y

func tex(name: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % name)
