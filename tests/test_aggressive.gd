extends Node

# AGGRESSIVE TEST v1.3.0 - Multi-strategy event detection
# Run this with: adb logcat -s JoyConPlugin:I godot:I

var frame_count = 0
var last_device_scan = 0
var plugin = null

func _ready():
	print("[AggressiveTest] ========================================")
	print("[AggressiveTest] MULTI-STRATEGY EVENT DETECTION TEST")
	print("[AggressiveTest] Version 1.3.0")
	print("[AggressiveTest] ========================================")
	
	# Check if plugin is available
	if Engine.has_singleton("JoyConAndroidPlugin"):
		plugin = Engine.get_singleton("JoyConAndroidPlugin")
		print("[AggressiveTest] ✓ Plugin singleton found")
		
		# Test basic methods
		var devices = plugin.getConnectedDevices()
		print("[AggressiveTest] Connected gamepad devices: ", devices)
		
		for device_id in devices:
			var device_name = plugin.getDeviceName(device_id)
			print("[AggressiveTest] Device ", device_id, ": ", device_name)
			
			# Try polling button states
			var button_map = plugin.pollButtonStates(device_id)
			print("[AggressiveTest] Button map: ", button_map)
	else:
		print("[AggressiveTest] ✗ Plugin NOT FOUND")
		print("[AggressiveTest] Make sure joycon_android_plugin.aar is in addons/")
	
	print("[AggressiveTest] ========================================")
	print("[AggressiveTest] INSTRUCTIONS:")
	print("[AggressiveTest] 1. Open terminal: adb logcat -s JoyConPlugin:I")
	print("[AggressiveTest] 2. Press ANY Joy-Con L button")
	print("[AggressiveTest] 3. Look for emoji logs: 🔍 RAW, 📥 DOWN, 📤 UP")
	print("[AggressiveTest] 4. Check DecorView/GenericMotion logs")
	print("[AggressiveTest] ========================================")

func _process(_delta):
	frame_count += 1
	
	if plugin == null:
		return
	
	# Rescan devices every 300 frames (~5 seconds)
	if frame_count - last_device_scan > 300:
		last_device_scan = frame_count
		var devices = plugin.getConnectedDevices()
		if devices.size() > 0:
			print("[AggressiveTest] Devices at frame ", frame_count, ": ", devices)
	
	# Poll button states continuously
	var devices = plugin.getConnectedDevices()
	for device_id in devices:
		var buttons = plugin.pollJoyConButtons(device_id)
		if buttons.size() > 0:
			print("[AggressiveTest] 🎮 BUTTONS DETECTED: device=", device_id, " buttons=", buttons)

func _input(event):
	# Strategy 1: Catch InputEventJoypadButton (standard Godot path)
	if event is InputEventJoypadButton:
		print("[AggressiveTest] 🎯 Godot JoypadButton: device=", event.device, 
			" button=", event.button_index, " pressed=", event.pressed)
	
	# Strategy 2: Catch InputEventKey (Joy-Con might send as keyboard)
	if event is InputEventKey:
		if event.pressed:
			print("[AggressiveTest] ⌨️ Godot Key DOWN: keycode=", event.keycode, 
				" physical=", event.physical_keycode)
	
	# Strategy 3: Catch motion events
	if event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.5:  # Only log significant movements
			print("[AggressiveTest] 🕹️ Godot JoypadMotion: device=", event.device,
				" axis=", event.axis, " value=", event.axis_value)

func _notification(what):
	if what == NOTIFICATION_WM_FOCUS_IN:
		print("[AggressiveTest] 🔆 App gained focus")
	elif what == NOTIFICATION_WM_FOCUS_OUT:
		print("[AggressiveTest] 🌑 App lost focus")
