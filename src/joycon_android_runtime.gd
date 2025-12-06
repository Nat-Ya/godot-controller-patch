extends Node

## JoyConAndroid - Direct access to Joy-Con L buttons on Android
## Works around Godot's missing InputEvent mapping for BTN_TL, BTN_TL2, BTN_Z, BTN_DPAD_*
## Comprehensive logging for: L, ZL, SL, SR, D-pad (all 4 directions), Stick click, Minus, Screenshot

var plugin: Object = null
var button_states: Dictionary = {}  # button_index -> bool

# Button index mapping (from Kotlin plugin BUTTON_MAP)
var BUTTON_NAMES = {
	4: "L",
	6: "ZL / Minus",
	10: "Stick Click",
	11: "D-Pad UP",
	12: "D-Pad DOWN",
	13: "D-Pad LEFT",
	14: "D-Pad RIGHT",
	16: "Screenshot (-)",
}

signal button_pressed(device_id: int, button_index: int)
signal button_released(device_id: int, button_index: int)

func _ready() -> void:
	if OS.get_name() == "Android":
		if Engine.has_singleton("JoyConAndroidPlugin"):
			plugin = Engine.get_singleton("JoyConAndroidPlugin")
			plugin.connect("joycon_button_pressed", _on_button_pressed)
			plugin.connect("joycon_button_released", _on_button_released)
			print("[JoyConAndroid] ✅ Plugin connected - Ready for Joy-Con L button detection")
			_log_button_mapping()
		else:
			push_warning("[JoyConAndroid] ❌ Plugin not available - Joy-Con L buttons won't work")
	else:
		print("[JoyConAndroid] ℹ️ Not on Android, plugin disabled (running on %s)" % OS.get_name())

func _log_button_mapping() -> void:
	print("[JoyConAndroid] Button mapping:")
	for button_index in BUTTON_NAMES.keys():
		print("  - Index %d: %s" % [button_index, BUTTON_NAMES[button_index]])

func _on_button_pressed(device_id: int, button_index: int) -> void:
	button_states[button_index] = true
	var button_name = BUTTON_NAMES.get(button_index, "Unknown (index %d)" % button_index)
	print("[JoyConAndroid] 🔘 PRESSED: %s (index %d, device %d)" % [button_name, button_index, device_id])
	button_pressed.emit(device_id, button_index)

func _on_button_released(device_id: int, button_index: int) -> void:
	button_states[button_index] = false
	var button_name = BUTTON_NAMES.get(button_index, "Unknown (index %d)" % button_index)
	print("[JoyConAndroid] 🔘 RELEASED: %s (index %d, device %d)" % [button_name, button_index, device_id])
	button_released.emit(device_id, button_index)

## Check if button is pressed
func is_button_pressed(button_index: int) -> bool:
	return button_states.get(button_index, false)

## Get button name for logging
func get_button_name(button_index: int) -> String:
	return BUTTON_NAMES.get(button_index, "Unknown")

## Poll all buttons (if events aren't working)
func poll_buttons(device_id: int) -> Array:
	if plugin != null:
		var pressed = plugin.pollJoyConButtons(device_id)
		if pressed:
			print("[JoyConAndroid] 📊 Polling device %d: %s buttons pressed" % [device_id, pressed])
		return pressed if pressed else []
	return []
