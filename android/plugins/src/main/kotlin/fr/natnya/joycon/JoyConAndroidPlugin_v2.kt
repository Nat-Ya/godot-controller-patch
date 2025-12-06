package fr.natnya.joycon

import android.util.Log
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.concurrent.thread

/**
 * JoyConAndroidPlugin v2.0 - Raw Input Reader
 * 
 * Directly reads /dev/input/eventX to bypass Godot's broken Joy-Con L button mapping.
 * Detects D-pad, L, ZL, and Screenshot buttons via Linux input events.
 */
class JoyConAndroidPlugin(godot: Godot) : GodotPlugin(godot) {
    
    companion object {
        private const val TAG = "JoyConPlugin"
        
        // Linux input event structure constants
        private const val EVENT_SIZE = 24  // sizeof(struct input_event) on 64-bit Android
        private const val EV_KEY = 0x01
        
        // Button event codes from linux/input-event-codes.h
        private const val BTN_DPAD_UP = 0x220
        private const val BTN_DPAD_DOWN = 0x221
        private const val BTN_DPAD_LEFT = 0x222
        private const val BTN_DPAD_RIGHT = 0x223
        private const val BTN_TL = 0x136  // L button
        private const val BTN_TL2 = 0x138  // ZL button
        private const val BTN_Z = 0x135  // Screenshot/Capture button
        private const val BTN_SELECT = 0x13a  // SL button
        private const val BTN_START = 0x13b  // SR button
    }
    
    private var readerThread: Thread? = null
    private var isReading = false
    
    init {
        Log.i(TAG, "========================================")
        Log.i(TAG, "JoyConAndroidPlugin v2.0 - RAW INPUT READER")
        Log.i(TAG, "Strategy: Direct /dev/input/eventX reading")
        Log.i(TAG, "Target: Joy-Con L D-pad, L, ZL, Screenshot buttons")
        Log.i(TAG, "========================================")
        
        startRawInputReader()
    }
    
    override fun getPluginName(): String = "JoyConAndroidPlugin"
    
    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo("joycon_button_pressed", Int::class.javaObjectType, Int::class.javaObjectType),
            SignalInfo("joycon_button_released", Int::class.javaObjectType, Int::class.javaObjectType)
        )
    }
    
    /**
     * Start background thread to read raw input events from /dev/input/eventX
     */
    private fun startRawInputReader() {
        isReading = true
        readerThread = thread(start = true, isDaemon = true, name = "JoyConRawInput") {
            Log.i(TAG, "🔥 Raw input reader thread started")
            
            val inputDevice = findJoyConLInputDevice()
            if (inputDevice == null) {
                Log.e(TAG, "❌ No readable input device found in /dev/input/")
                return@thread
            }
            
            Log.i(TAG, "✅ Reading from: ${inputDevice.absolutePath}")
            
            try {
                FileInputStream(inputDevice).use { stream ->
                    val buffer = ByteArray(EVENT_SIZE)
                    
                    while (isReading) {
                        val bytesRead = stream.read(buffer)
                        if (bytesRead == EVENT_SIZE) {
                            parseInputEvent(buffer)
                        }
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "❌ Permission denied: ${e.message}")
                Log.i(TAG, "💡 Note: Android requires root or system app to read /dev/input directly")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error reading input events: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Find /dev/input/eventX device (try all readable event files)
     */
    private fun findJoyConLInputDevice(): File? {
        val inputDir = File("/dev/input")
        if (!inputDir.exists() || !inputDir.isDirectory) {
            Log.e(TAG, "/dev/input directory not accessible")
            return null
        }
        
        val eventFiles = inputDir.listFiles { file ->
            file.name.startsWith("event") && file.canRead()
        } ?: emptyArray()
        
        if (eventFiles.isEmpty()) {
            Log.w(TAG, "No readable event devices found (may require root)")
            return null
        }
        
        Log.i(TAG, "Found ${eventFiles.size} readable input devices:")
        eventFiles.forEach { file ->
            Log.i(TAG, "  - ${file.name}")
        }
        
        // Return first readable device (we'll filter by actual events received)
        return eventFiles.firstOrNull()
    }
    
    /**
     * Parse Linux input_event structure:
     * struct input_event {
     *   struct timeval time;  // 16 bytes (tv_sec 8 + tv_usec 8)
     *   __u16 type;           // 2 bytes
     *   __u16 code;           // 2 bytes
     *   __s32 value;          // 4 bytes
     * };
     */
    private fun parseInputEvent(buffer: ByteArray) {
        val bb = ByteBuffer.wrap(buffer).order(ByteOrder.LITTLE_ENDIAN)
        
        // Skip timestamp (16 bytes)
        bb.position(16)
        
        val type = bb.short.toInt() and 0xFFFF
        val code = bb.short.toInt() and 0xFFFF
        val value = bb.int
        
        // Only process key events (EV_KEY = 0x01)
        if (type == EV_KEY) {
            handleRawKeyEvent(code, value)
        }
    }
    
    /**
     * Handle raw key event from /dev/input
     * @param code Linux button code (BTN_DPAD_UP, BTN_TL, etc.)
     * @param value 0 = release, 1 = press, 2 = repeat
     */
    private fun handleRawKeyEvent(code: Int, value: Int) {
        val pressed = value == 1
        val released = value == 0
        
        if (!pressed && !released) return  // Ignore repeats
        
        val buttonName = when (code) {
            BTN_DPAD_UP -> "DPAD_UP"
            BTN_DPAD_DOWN -> "DPAD_DOWN"
            BTN_DPAD_LEFT -> "DPAD_LEFT"
            BTN_DPAD_RIGHT -> "DPAD_RIGHT"
            BTN_TL -> "L_BUTTON"
            BTN_TL2 -> "ZL_BUTTON"
            BTN_Z -> "SCREENSHOT"
            BTN_SELECT -> "SL_BUTTON"
            BTN_START -> "SR_BUTTON"
            else -> return  // Ignore unknown buttons
        }
        
        val action = if (pressed) "PRESSED" else "RELEASED"
        Log.i(TAG, "🎮 RAW INPUT: $buttonName (code=0x${code.toString(16)}) $action")
        
        // Emit signal to Godot (device_id = 0 for Joy-Con L)
        if (pressed) {
            emitSignal("joycon_button_pressed", 0, code)
        } else {
            emitSignal("joycon_button_released", 0, code)
        }
    }
    
    @UsedByGodot
    fun getConnectedDevices(): IntArray {
        // Return device 0 (Joy-Con L) if reader thread is alive
        return if (readerThread?.isAlive == true) intArrayOf(0) else intArrayOf()
    }
    
    @UsedByGodot
    fun isReaderActive(): Boolean {
        return isReading && readerThread?.isAlive == true
    }
    
    override fun onMainDestroy() {
        super.onMainDestroy()
        isReading = false
        readerThread?.interrupt()
        Log.i(TAG, "Raw input reader stopped")
    }
}
