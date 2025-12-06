package fr.natnya.joycon

import android.util.Log
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class JoyConAndroidPlugin(godot: Godot) : GodotPlugin(godot) {
    
    companion object {
        private const val TAG = "JoyConPlugin"
    }
    
    init {
        Log.i(TAG, "========================================")
        Log.i(TAG, "JoyConAndroidPlugin INITIALIZING")
        Log.i(TAG, "Plugin version: 1.2.0 - AGGRESSIVE LOGGING")
        Log.i(TAG, "Godot version: ${godot.javaClass.simpleName}")
        Log.i(TAG, "Activity: ${activity?.javaClass?.simpleName}")
        Log.i(TAG, "========================================")
        
        // Immediately set up listeners
        setupKeyListeners()
    }
    
    private fun setupKeyListeners() {
        try {
            // Method 1: DecorView key listener
            activity?.runOnUiThread {
                activity?.window?.decorView?.setOnKeyListener { view, keyCode, event ->
                    Log.i(TAG, "[DecorView] Key event: keyCode=$keyCode, action=${event.action}, source=0x${event.source.toString(16)}")
                    handleKeyEvent(keyCode, event)
                }
                Log.i(TAG, "✓ DecorView key listener registered")
            }
            
            // Method 2: Input callback via Godot activity
            Log.i(TAG, "Activity methods available: ${activity?.javaClass?.methods?.joinToString { it.name }}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup listeners: ${e.message}", e)
        }
    }
    
    override fun getPluginName(): String {
        Log.i(TAG, "getPluginName() called -> JoyConAndroidPlugin")
        return "JoyConAndroidPlugin"
    }
    
    override fun getPluginSignals(): Set<SignalInfo> {
        Log.i(TAG, "getPluginSignals() called - Registering signals:")
        Log.i(TAG, "  - joycon_button_pressed(deviceId: Int, buttonIndex: Int)")
        Log.i(TAG, "  - joycon_button_released(deviceId: Int, buttonIndex: Int)")
        return setOf(
            SignalInfo("joycon_button_pressed", Int::class.javaObjectType, Int::class.javaObjectType),
            SignalInfo("joycon_button_released", Int::class.javaObjectType, Int::class.javaObjectType)
        )
    }
    
    // Track currently pressed buttons per device
    private val pressedButtons = mutableMapOf<Int, MutableSet<Int>>()
    
    // Map Linux button codes to Godot-friendly indices
    private val BUTTON_MAP = mapOf(
        KeyEvent.KEYCODE_BUTTON_L1 to 4,      // L button (BTN_TL) -> 4
        KeyEvent.KEYCODE_BUTTON_L2 to 6,      // ZL button (BTN_TL2) -> 6
        KeyEvent.KEYCODE_BUTTON_Z to 16,      // Screenshot (BTN_Z) -> 16 (custom)
        KeyEvent.KEYCODE_DPAD_UP to 11,       // D-pad UP -> 11
        KeyEvent.KEYCODE_DPAD_DOWN to 12,     // D-pad DOWN -> 12
        KeyEvent.KEYCODE_DPAD_LEFT to 13,     // D-pad LEFT -> 13
        KeyEvent.KEYCODE_DPAD_RIGHT to 14,    // D-pad RIGHT -> 14
        KeyEvent.KEYCODE_BUTTON_THUMBL to 10, // Stick click -> 10
        KeyEvent.KEYCODE_BUTTON_SELECT to 6   // Minus button -> 6
    )
    
    private fun handleKeyEvent(keyCode: Int, event: KeyEvent): Boolean {
        Log.i(TAG, "🔍 RAW EVENT: keyCode=$keyCode, action=${event.action}, device=${event.deviceId}, source=0x${event.source.toString(16)}")
        
        when (event.action) {
            KeyEvent.ACTION_DOWN -> return handleKeyDown(keyCode, event)
            KeyEvent.ACTION_UP -> return handleKeyUp(keyCode, event)
            else -> {
                Log.i(TAG, "Other action: ${event.action}")
                return false
            }
        }
    }
    
    fun handleKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        Log.i(TAG, "📥 handleKeyDown called: keyCode=$keyCode")
        
        if (event == null) {
            Log.w(TAG, "Event is null!")
            return false
        }
        
        val deviceId = event.deviceId
        val device = InputDevice.getDevice(deviceId)
        val deviceName = device?.name ?: "Unknown"
        val isGamepad = (event.source and InputDevice.SOURCE_GAMEPAD) != 0
        
        Log.i(TAG, "  Device: $deviceId ($deviceName), isGamepad=$isGamepad")
        
        if (isGamepad) {
            val godotButton = BUTTON_MAP[keyCode]
            
            if (godotButton != null) {
                pressedButtons.getOrPut(deviceId) { mutableSetOf() }.add(godotButton)
                emitSignal("joycon_button_pressed", deviceId, godotButton)
                Log.i(TAG, "✓ MAPPED Button DOWN: keyCode=$keyCode -> godot=$godotButton, device=$deviceId ($deviceName)")
                Log.i(TAG, "  Active buttons on device $deviceId: ${pressedButtons[deviceId]?.joinToString()}")
                return true
            } else {
                Log.w(TAG, "✗ UNMAPPED gamepad button DOWN: keyCode=$keyCode, device=$deviceId ($deviceName)")
                Log.w(TAG, "  Add to BUTTON_MAP: KeyEvent.KEYCODE_??? to X")
            }
        } else {
            Log.i(TAG, "❌ Not a gamepad event: keyCode=$keyCode, source=0x${event.source.toString(16)}")
        }
        return false
    }
    
    fun handleKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        Log.i(TAG, "📤 handleKeyUp called: keyCode=$keyCode")
        
        if (event == null) {
            Log.w(TAG, "Event is null!")
            return false
        }
        
        val deviceId = event.deviceId
        val device = InputDevice.getDevice(deviceId)
        val deviceName = device?.name ?: "Unknown"
        val isGamepad = (event.source and InputDevice.SOURCE_GAMEPAD) != 0
        
        Log.i(TAG, "  Device: $deviceId ($deviceName), isGamepad=$isGamepad")
        
        if (isGamepad) {
            val godotButton = BUTTON_MAP[keyCode]
            
            if (godotButton != null) {
                pressedButtons[deviceId]?.remove(godotButton)
                emitSignal("joycon_button_released", deviceId, godotButton)
                Log.i(TAG, "✓ MAPPED Button UP: keyCode=$keyCode -> godot=$godotButton, device=$deviceId ($deviceName)")
                Log.i(TAG, "  Active buttons on device $deviceId: ${pressedButtons[deviceId]?.joinToString() ?: "none"}")
                return true
            } else {
                Log.w(TAG, "✗ UNMAPPED gamepad button UP: keyCode=$keyCode, device=$deviceId ($deviceName)")
            }
        } else {
            Log.i(TAG, "❌ Not a gamepad event: keyCode=$keyCode, source=0x${event.source.toString(16)}")
        }
        return false
    }
    
    // Godot 4.3 plugin lifecycle methods
    override fun onMainResume() {
        super.onMainResume()
        Log.i(TAG, "========================================")
        Log.i(TAG, "onMainResume called - Setting up listeners")
        Log.i(TAG, "========================================")
        
        // Re-setup listeners
        setupKeyListeners()
        
        // Log all input devices
        logAllInputDevices()
    }
    
    override fun onMainPause() {
        super.onMainPause()
        Log.i(TAG, "onMainPause called - Removing listeners")
        
        // Remove listener
        activity?.runOnUiThread {
            activity?.window?.decorView?.setOnKeyListener(null)
        }
    }
    
    private fun logAllInputDevices() {
        Log.i(TAG, "========================================")
        Log.i(TAG, "SCANNING ALL INPUT DEVICES")
        Log.i(TAG, "========================================")
        
        val deviceIds = InputDevice.getDeviceIds()
        Log.i(TAG, "Found ${deviceIds.size} input devices:")
        
        deviceIds.forEach { id ->
            val device = InputDevice.getDevice(id)
            if (device != null) {
                val isGamepad = (device.sources and InputDevice.SOURCE_GAMEPAD) != 0
                val isJoystick = (device.sources and InputDevice.SOURCE_JOYSTICK) != 0
                val isDpad = (device.sources and InputDevice.SOURCE_DPAD) != 0
                val isKeyboard = (device.sources and InputDevice.SOURCE_KEYBOARD) != 0
                
                Log.i(TAG, "Device $id: ${device.name}")
                Log.i(TAG, "  Vendor: ${device.vendorId}, Product: ${device.productId}")
                Log.i(TAG, "  Sources: 0x${device.sources.toString(16)}")
                Log.i(TAG, "  - Gamepad: $isGamepad")
                Log.i(TAG, "  - Joystick: $isJoystick")
                Log.i(TAG, "  - Dpad: $isDpad")
                Log.i(TAG, "  - Keyboard: $isKeyboard")
            }
        }
        Log.i(TAG, "========================================")
    }
    
    @UsedByGodot
    fun pollJoyConButtons(deviceId: Int): IntArray {
        val buttons = pressedButtons[deviceId]?.toIntArray() ?: intArrayOf()
        if (buttons.isNotEmpty()) {
            Log.v(TAG, "pollJoyConButtons(device=$deviceId) -> [${buttons.joinToString()}]")
        }
        return buttons
    }
    
    @UsedByGodot
    fun getConnectedDevices(): IntArray {
        val deviceIds = InputDevice.getDeviceIds()
        Log.i(TAG, "getConnectedDevices() called - Found ${deviceIds.size} input devices")
        deviceIds.forEach { id ->
            val device = InputDevice.getDevice(id)
            if (device != null) {
                val isGamepad = (device.sources and InputDevice.SOURCE_GAMEPAD) != 0
                Log.i(TAG, "  Device $id: ${device.name} (gamepad=$isGamepad, sources=0x${device.sources.toString(16)})")
            }
        }
        return deviceIds.filter { id ->
            val device = InputDevice.getDevice(id)
            device != null && (device.sources and InputDevice.SOURCE_GAMEPAD) != 0
        }.toIntArray()
    }
    
    @UsedByGodot
    fun getDeviceName(deviceId: Int): String {
        val device = InputDevice.getDevice(deviceId)
        val name = device?.name ?: "Unknown Device"
        Log.i(TAG, "getDeviceName($deviceId) -> $name")
        return name
    }
    
    override fun onMainRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onMainRequestPermissionsResult(requestCode, permissions, grantResults)
    }
    
    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onMainActivityResult(requestCode, resultCode, data)
    }
}
