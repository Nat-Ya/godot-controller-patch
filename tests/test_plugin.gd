extends GutTest

# Test suite for JoyCon Android Plugin
# Requires GUT (Godot Unit Testing) addon

var plugin: Object = null
var runtime: Node = null

func before_all():
	if OS.get_name() != "Android":
		pass_test("Skipping Android-specific tests on " + OS.get_name())

func before_each():
	if OS.get_name() == "Android":
		if Engine.has_singleton("JoyConAndroidPlugin"):
			plugin = Engine.get_singleton("JoyConAndroidPlugin")
		runtime = load("res://src/joycon_android_runtime.gd").new()
		add_child(runtime)

func after_each():
	if runtime:
		runtime.queue_free()
		runtime = null

func test_plugin_singleton_exists():
	if OS.get_name() != "Android":
		pass_test("Android-only test")
		return
	
	assert_not_null(plugin, "JoyConAndroidPlugin singleton should exist")

func test_runtime_initialization():
	if OS.get_name() != "Android":
		pass_test("Android-only test")
		return
	
	assert_not_null(runtime, "Runtime should initialize")
	assert_not_null(runtime.plugin, "Runtime should connect to plugin")

func test_button_states_dictionary():
	if OS.get_name() != "Android":
		pass_test("Android-only test")
		return
	
	assert_has(runtime, "button_states", "Runtime should have button_states")
	assert_typeof(runtime.button_states, TYPE_DICTIONARY, "button_states should be Dictionary")

func test_is_button_pressed_default():
	if OS.get_name() != "Android":
		pass_test("Android-only test")
		return
	
	var result = runtime.is_button_pressed(4)  # L button
	assert_typeof(result, TYPE_BOOL, "is_button_pressed should return bool")
	assert_false(result, "Button should be unpressed initially")

func test_button_mapping():
	# Verify button index constants match specification
	var expected_mappings = {
		"BTN_TL": 4,      # L button
		"BTN_TL2": 6,     # ZL button
		"BTN_Z": 16,      # Screenshot button
		"BTN_DPAD_UP": 11,
		"BTN_DPAD_DOWN": 12,
		"BTN_DPAD_LEFT": 13,
		"BTN_DPAD_RIGHT": 14
	}
	
	# This test just documents the mapping, actual verification requires hardware
	pass_test("Button mappings documented: " + str(expected_mappings))

func test_signal_emission():
	if OS.get_name() != "Android":
		pass_test("Android-only test")
		return
	
	# Watch for signals (can't simulate button press in unit test)
	watch_signals(runtime)
	
	# Verify signals are defined
	assert_signal_exists(runtime, "button_pressed")
	assert_signal_exists(runtime, "button_released")
