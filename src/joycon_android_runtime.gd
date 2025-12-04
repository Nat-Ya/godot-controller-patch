extends Node

## JoyConAndroid - Direct access to Joy-Con L buttons on Android
## Works around Godot's missing InputEvent mapping for BTN_TL, BTN_TL2, BTN_Z, BTN_DPAD_*

var plugin: Object = null
var button_states: Dictionary = {}  # button_index -> bool

signal button_pressed(device_id: int, button_index: int)
signal button_released(device_id: int, button_index: int)

func _ready() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("JoyConAndroidPlugin"):
			plugin = Engine.get_singleton("JoyConAndroidPlugin")
			plugin.connect("joycon_button_pressed", _on_button_pressed)
			plugin.connect("joycon_button_released", _on_button_released)
			print("[JoyConAndroid] Plugin connected")
		else:
			push_warning("[JoyConAndroid] Plugin not available - Joy-Con L buttons won't work")
	else:
		print("[JoyConAndroid] Not on Android, plugin disabled")

func _on_button_pressed(device_id: int, button_index: int) -> void:
	button_states[button_index] = true
	button_pressed.emit(device_id, button_index)
	print("[JoyConAndroid] Button %d pressed on device %d" % [button_index, device_id])

func _on_button_released(device_id: int, button_index: int) -> void:
	button_states[button_index] = false
	button_released.emit(device_id, button_index)

## Check if button is pressed
func is_button_pressed(button_index: int) -> bool:
	return button_states.get(button_index, false)

## Poll all buttons (if events aren't working)
func poll_buttons(device_id: int) -> Array:
	if plugin != null:
		var pressed = plugin.pollJoyConButtons(device_id)
		return pressed if pressed else []
	return []
