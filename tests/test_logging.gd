extends Node

## Comprehensive logging test for Joy-Con L plugin
## Run this to verify all systems are working before gameplay

var joycon_runtime: Node
var test_mode: String = "event"  # "event" or "polling"
var polling_device_id: int = 0

func _ready() -> void:
	print("========================================")
	print("JOYCON PLUGIN TEST - LOGGING MODE")
	print("========================================")
	
	# Check if running on Android
	if OS.get_name() != "Android":
		print("❌ NOT RUNNING ON ANDROID - Test invalid")
		print("Current OS: %s" % OS.get_name())
		return
	
	print("✅ Running on Android")
	
	# Load runtime
	var RuntimeClass = load("res://addons/joycon-android-plugin/src/joycon_android_runtime.gd")
	if RuntimeClass == null:
		print("❌ Failed to load joycon_android_runtime.gd")
		return
	
	print("✅ Runtime class loaded")
	
	joycon_runtime = RuntimeClass.new()
	add_child(joycon_runtime)
	
	print("✅ Runtime instantiated and added to tree")
	
	# Connect signals
	joycon_runtime.connect("button_pressed", _on_test_button_pressed)
	joycon_runtime.connect("button_released", _on_test_button_released)
	
	print("✅ Test signals connected")
	
	# Print test instructions
	print("")
	print("========================================")
	print("TEST INSTRUCTIONS:")
	print("========================================")
	print("1. Connect Joy-Con L via Bluetooth")
	print("2. Press buttons: L, ZL, D-pad (all 4 directions)")
	print("3. Watch logcat output for events")
	print("")
	print("Expected logs:")
	print("  - [JoyConPlugin] ✓ Button DOWN: ...")
	print("  - [JoyConPlugin] ✓ Button UP: ...")
	print("  - [JoyConAndroid] 🔘 PRESSED: ...")
	print("  - [JoyConAndroid] 🔘 RELEASED: ...")
	print("")
	print("Filter command: adb logcat -s JoyConPlugin:I JoyConAndroid:I godot:I")
	print("========================================")
	
	# Start polling mode after 2 seconds (fallback test)
	await get_tree().create_timer(2.0).timeout
	print("")
	print("Starting polling mode test (fallback)...")
	test_mode = "polling"

func _process(_delta: float) -> void:
	if test_mode == "polling" and joycon_runtime != null:
		var pressed = joycon_runtime.poll_buttons(polling_device_id)
		if pressed.size() > 0:
			print("[TEST] Polling detected buttons: %s" % str(pressed))

func _on_test_button_pressed(device_id: int, button_index: int) -> void:
	var button_name = joycon_runtime.get_button_name(button_index)
	print("[TEST] ✅ EVENT RECEIVED - PRESSED: %s (index %d, device %d)" % [button_name, button_index, device_id])
	
	# Visual feedback
	_print_button_state()

func _on_test_button_released(device_id: int, button_index: int) -> void:
	var button_name = joycon_runtime.get_button_name(button_index)
	print("[TEST] ✅ EVENT RECEIVED - RELEASED: %s (index %d, device %d)" % [button_name, button_index, device_id])
	
	# Visual feedback
	_print_button_state()

func _print_button_state() -> void:
	print("[TEST] Current button states:")
	for button_index in joycon_runtime.BUTTON_NAMES.keys():
		var pressed = joycon_runtime.is_button_pressed(button_index)
		if pressed:
			var button_name = joycon_runtime.get_button_name(button_index)
			print("  - %s (index %d): PRESSED" % [button_name, button_index])
