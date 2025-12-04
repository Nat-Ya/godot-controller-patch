package fr.natnya.joycon

import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class JoyConAndroidPlugin(godot: Godot) : GodotPlugin(godot) {
    
    override fun getPluginName(): String = "JoyConAndroidPlugin"
    
    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo("joycon_button_pressed", Int::class.javaObjectType, Int::class.javaObjectType),
            SignalInfo("joycon_button_released", Int::class.javaObjectType, Int::class.javaObjectType)
        )
    }
    
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
    
    @UsedByGodot
    fun pollJoyConButtons(deviceId: Int): IntArray {
        val device = InputDevice.getDevice(deviceId) ?: return intArrayOf()
        val pressedButtons = mutableListOf<Int>()
        
        // Check all mapped buttons
        for ((keyCode, godotIndex) in BUTTON_MAP) {
            if (device.hasKeys(keyCode).any { it }) {
                pressedButtons.add(godotIndex)
            }
        }
        
        return pressedButtons.toIntArray()
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
    
    // Handle key events directly from Android
    override fun onMainKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (event != null && event.source and InputDevice.SOURCE_GAMEPAD != 0) {
            val godotButton = BUTTON_MAP[keyCode]
            if (godotButton != null) {
                emitSignal("joycon_button_released", event.deviceId, godotButton)
                return true
            }
        }
        return super.onMainKeyUp(keyCode, event)
    }
    
    override fun onMainKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (event != null && event.source and InputDevice.SOURCE_GAMEPAD != 0) {
            val godotButton = BUTTON_MAP[keyCode]
            if (godotButton != null) {
                emitSignal("joycon_button_pressed", event.deviceId, godotButton)
                return true
            }
        }
        return super.onMainKeyDown(keyCode, event)
    }
}
