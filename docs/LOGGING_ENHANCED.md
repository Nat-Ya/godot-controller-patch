# Joy-Con L Plugin - Enhanced Logging Summary

## 🎯 What's Changed

### Plugin (Kotlin) - JoyConAndroidPlugin.kt
Added comprehensive logging at every stage:

1. **Initialization logs** (when plugin loads):
   - Plugin version
   - Godot version
   - Banner with clear separation

2. **Method registration logs**:
   - `getPluginName()` confirmation
   - Signal registration details

3. **Event handling logs** (when buttons pressed):
   - ✓ Success indicator for mapped buttons
   - Device ID and name
   - KeyCode → Godot button index mapping
   - Active buttons list
   - ✗ Warning for unmapped buttons (with keyCode for debugging)

4. **New helper methods**:
   - `getConnectedDevices()` - Lists all gamepads
   - `getDeviceName(deviceId)` - Gets device name
   - Enhanced `pollJoyConButtons()` with verbose logging

### Runtime (GDScript) - joycon_android_runtime.gd
Added matching logs:

1. **Initialization sequence**:
   - OS detection
   - Singleton availability check
   - Signal connection confirmation
   - Device discovery at startup

2. **Event logs**:
   - 🔘 Emoji indicators for button events
   - Button name + index + device ID
   - Current button state after each event

3. **Helper method**:
   - `_discover_devices()` - Enumerates gamepads at startup

### Test Scene - test_logging.gd
New comprehensive test script:
- Loads runtime manually
- Tests event mode
- Falls back to polling mode
- Prints test instructions
- Shows expected log format

## 📋 Testing Workflow

### 1. Pre-flight Check
```bash
./build/pre-flight.sh
```
Validates:
- All files exist
- Device connected
- Plugin built
- Ready to test

### 2. Build on VM
```bash
cd /c/Users/ygall/Documents/repos/godot-controller-patch/android
./gradlew clean assembleRelease
```

### 3. Copy to game project
```bash
cp build/outputs/aar/*-release.aar \
   /c/Users/ygall/Documents/repos/a-treasure-for-Lora/android/plugins/joycon_android_plugin.aar
```

### 4. Build game APK
```bash
cd /c/Users/ygall/Documents/repos/a-treasure-for-Lora
make clean && make install-apk
```

### 5. Test with filtered logs
```bash
adb logcat -c
adb logcat -s JoyConPlugin:I JoyConAndroid:I
```

## 🔍 What to Look For

### Stage 1: Plugin Loading (First 2 seconds)
```
I/JoyConPlugin: ========================================
I/JoyConPlugin: JoyConAndroidPlugin INITIALIZING
I/JoyConPlugin: Plugin version: 1.1.0
I/JoyConPlugin: ========================================
I/JoyConPlugin: getPluginName() called -> JoyConAndroidPlugin
I/JoyConPlugin: getPluginSignals() called - Registering signals:
I/JoyConPlugin:   - joycon_button_pressed(deviceId: Int, buttonIndex: Int)
I/JoyConPlugin:   - joycon_button_released(deviceId: Int, buttonIndex: Int)
```

**❌ If missing:** Plugin not loading - check export_presets.cfg

### Stage 2: Runtime Connection
```
I/JoyConAndroid: ========================================
I/JoyConAndroid: Runtime INITIALIZING
I/JoyConAndroid: OS: Android
I/JoyConAndroid: Checking for plugin singleton...
I/JoyConAndroid: ✅ Plugin singleton found!
I/JoyConAndroid: Connecting signals...
I/JoyConAndroid: ✅ Signals connected
```

**❌ If "singleton NOT FOUND":** Plugin not registered - check .gdap file

### Stage 3: Device Discovery
```
I/JoyConAndroid: Discovering connected gamepads...
I/JoyConPlugin: getConnectedDevices() called - Found 1 input devices
I/JoyConPlugin:   Device 0: Joy-Con (L) (gamepad=true, sources=0x401)
I/JoyConAndroid: Found 1 gamepad(s):
I/JoyConAndroid:   - Device 0: Joy-Con (L)
```

**❌ If "Found 0 gamepads":** Joy-Con not paired - check Bluetooth

### Stage 4: Button Events (when you press L button)
```
I/JoyConPlugin: ✓ Button DOWN: keyCode=102 -> godot=4, device=0 (Joy-Con (L))
I/JoyConPlugin:   Active buttons on device 0: 4
I/JoyConAndroid: 🔘 PRESSED: L (index 4, device 0)

I/JoyConPlugin: ✓ Button UP: keyCode=102 -> godot=4, device=0 (Joy-Con (L))
I/JoyConPlugin:   Active buttons on device 0: none
I/JoyConAndroid: 🔘 RELEASED: L (index 4, device 0)
```

**❌ If no events:** Button not detected - check with `adb shell getevent`

## 🚨 Error Scenarios

### Unmapped Button Warning
```
W/JoyConPlugin: ✗ Unmapped button DOWN: keyCode=105, device=0 (Joy-Con (L)) - Not in BUTTON_MAP
```
**Action:** Note the keyCode (105), add to BUTTON_MAP in plugin

### Non-Gamepad Event (Verbose)
```
V/JoyConPlugin: Non-gamepad KeyDown: keyCode=4, source=0x101
```
**Normal:** Touch screen or keyboard event, ignored

## 📊 Button Mapping Reference

| Button | KeyCode | Godot Index | Expected Log |
|--------|---------|-------------|--------------|
| L | 102 | 4 | `keyCode=102 -> godot=4` |
| ZL | 104 | 6 | `keyCode=104 -> godot=6` |
| D-pad UP | 19 | 11 | `keyCode=19 -> godot=11` |
| D-pad DOWN | 20 | 12 | `keyCode=20 -> godot=12` |
| D-pad LEFT | 21 | 13 | `keyCode=21 -> godot=13` |
| D-pad RIGHT | 22 | 14 | `keyCode=22 -> godot=14` |
| Stick Click | 106 | 10 | `keyCode=106 -> godot=10` |
| Minus | 4 | 6 | `keyCode=4 -> godot=6` |

## ⏱️ Time-Saving Tips

### Quick 60-Second Test
```bash
# Start VM, run these commands, shut down VM
adb logcat -c && \
adb logcat -s JoyConPlugin:I JoyConAndroid:I > test-$(date +%H%M%S).log & \
LOGCAT_PID=$! && \
echo "Press ALL Joy-Con buttons NOW (60 sec)..." && \
sleep 60 && \
kill $LOGCAT_PID && \
cat test-*.log | grep -E "(INITIALIZING|Button (DOWN|UP)|PRESSED|RELEASED)"
```

### Check Specific Button
```bash
# Filter for L button only (index 4)
adb logcat -s JoyConPlugin:I JoyConAndroid:I | grep "godot=4\|index 4"
```

### Validate All Buttons Quickly
```bash
# Count unique button indices seen
adb logcat -s JoyConPlugin:I | grep "Button DOWN" | awk '{print $8}' | sort -u
# Should see: godot=4,6,10,11,12,13,14
```

## 📝 Documentation

- **Full test guide:** `docs/QUICK_TEST.md`
- **Pre-flight script:** `build/pre-flight.sh`
- **Test scene:** `tests/test_logging.gd`

## ✅ Success Criteria

You'll know it works when you see:
1. Plugin initialization banner
2. Runtime initialization banner
3. Device discovery (Joy-Con L found)
4. Button DOWN logs with ✓ indicator
5. Button UP logs with ✓ indicator
6. GDScript PRESSED/RELEASED logs with 🔘 emoji
7. All 8 buttons detected (L, ZL, D-pad×4, stick, minus)

**Total test time on VM: < 2 minutes** ⚡

## 🔧 Next Steps After Testing

If all tests pass:
1. Remove verbose logging (change `Log.i` to `Log.v` for less noise)
2. Keep error logs (`Log.e`) and warnings (`Log.w`)
3. Integrate into game's controller_handler.gd
4. Add gameplay-specific button mappings

If tests fail:
1. Save full log to file
2. Check which stage failed (loading, connection, detection, events)
3. Review specific error messages
4. Check QUICK_TEST.md troubleshooting section

---

**Good luck with your VM test! The logs will tell you exactly what's happening. 🎮✨**
