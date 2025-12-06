# Quick Test Guide - Joy-Con L Plugin

## 🎯 Goal
Verify Joy-Con L button detection works on Android device with comprehensive logging.

## 📋 Pre-flight Checklist

### 1. Build Plugin (from Windows host)
```bash
cd /c/Users/ygall/Documents/repos/godot-controller-patch/android
./gradlew clean assembleRelease
```

### 2. Copy to Game Project
```bash
cp build/outputs/aar/*-release.aar \
   /c/Users/ygall/Documents/repos/a-treasure-for-Lora/android/plugins/joycon_android_plugin.aar
```

### 3. Build Game APK
```bash
cd /c/Users/ygall/Documents/repos/a-treasure-for-Lora
make clean && make install-apk
```

## 🔬 Testing on Device (VM)

### Step 1: Clear logs and prepare
```bash
adb logcat -c
```

### Step 2: Filter for plugin logs ONLY
```bash
adb logcat -s JoyConPlugin:I JoyConAndroid:I
```

### Step 3: Launch app, watch for initialization
**Expected logs:**
```
I/JoyConPlugin: ========================================
I/JoyConPlugin: JoyConAndroidPlugin INITIALIZING
I/JoyConPlugin: Plugin version: 1.1.0
I/JoyConPlugin: ========================================
I/JoyConPlugin: getPluginName() called -> JoyConAndroidPlugin
I/JoyConPlugin: getPluginSignals() called - Registering signals:
I/JoyConPlugin:   - joycon_button_pressed(deviceId: Int, buttonIndex: Int)
I/JoyConPlugin:   - joycon_button_released(deviceId: Int, buttonIndex: Int)

I/JoyConAndroid: ========================================
I/JoyConAndroid: Runtime INITIALIZING
I/JoyConAndroid: OS: Android
I/JoyConAndroid: Checking for plugin singleton...
I/JoyConAndroid: ✅ Plugin singleton found!
I/JoyConAndroid: Connecting signals...
I/JoyConAndroid: ✅ Signals connected
I/JoyConAndroid: Discovering connected gamepads...
I/JoyConAndroid: Found X gamepad(s):
I/JoyConAndroid:   - Device 0: Joy-Con (L)
I/JoyConAndroid: ✅ READY - Listening for Joy-Con L button events
I/JoyConAndroid: ========================================
```

### Step 4: Press Joy-Con L buttons
**Test sequence:**
1. L button
2. ZL button
3. D-pad UP
4. D-pad DOWN
5. D-pad LEFT
6. D-pad RIGHT
7. Stick click (press analog stick)
8. Minus button (-)

**Expected per button press:**
```
I/JoyConPlugin: ✓ Button DOWN: keyCode=102 -> godot=4, device=0 (Joy-Con (L))
I/JoyConPlugin:   Active buttons on device 0: 4
I/JoyConAndroid: 🔘 PRESSED: L (index 4, device 0)
```

**Expected per button release:**
```
I/JoyConPlugin: ✓ Button UP: keyCode=102 -> godot=4, device=0 (Joy-Con (L))
I/JoyConPlugin:   Active buttons on device 0: none
I/JoyConAndroid: 🔘 RELEASED: L (index 4, device 0)
```

### Step 5: Check for unmapped buttons
If you see warnings like:
```
W/JoyConPlugin: ✗ Unmapped button DOWN: keyCode=XXX, device=0 (Joy-Con (L)) - Not in BUTTON_MAP
```
This means a button is detected but not mapped. Note the keyCode!

## 🚨 Troubleshooting

### Problem: No initialization logs at all
**Check:**
```bash
adb logcat | grep -i joycon
```
If nothing: Plugin not loading. Check `export_presets.cfg` has plugin enabled.

### Problem: Plugin initializes but singleton not found
**Look for:**
```
W/JoyConAndroid: ❌ Plugin singleton NOT FOUND
W/JoyConAndroid: Available singletons: [...]
```
Plugin not registered. Check `AndroidManifest.xml` and `.gdap` file.

### Problem: No button events
**Check device detection:**
```bash
adb logcat -s JoyConPlugin:I | grep "getConnectedDevices"
```
Should show: "Found X input devices" with Joy-Con listed.

**If device found but no events:**
- Try moving the analog stick (should NOT trigger, but verifies connection)
- Check Joy-Con L is paired and LEDs are on
- Try `adb shell getevent -lt` to see raw Linux events

### Problem: Wrong button indices
**Compare logs:**
```
Plugin says: keyCode=102 -> godot=4  (our mapping)
Runtime says: PRESSED: L (index 4)   (should match)
```
If mismatch: Button mapping table in plugin is wrong.

## 📊 Success Criteria

✅ **PASS** if you see:
1. Plugin initialization logs
2. Runtime initialization logs
3. Device detection (Joy-Con L found)
4. All 8 buttons trigger DOWN/UP events
5. Button indices match expected mapping:
   - L = 4
   - ZL = 6
   - D-pad UP = 11
   - D-pad DOWN = 12
   - D-pad LEFT = 13
   - D-pad RIGHT = 14
   - Stick click = 10
   - Minus = 6

❌ **FAIL** if:
- No plugin initialization
- Singleton not found
- No devices detected
- Buttons don't trigger events
- Wrong button indices

## 🎬 One-Liner for VM Testing

**Quick test (2-minute timer):**
```bash
# Clear logs, run app, collect 2 minutes of logs, then shut down VM
adb logcat -c && \
adb logcat -s JoyConPlugin:I JoyConAndroid:I > /tmp/joycon-test.log & \
LOGCAT_PID=$! && \
echo "✅ Logging started - Press Joy-Con buttons NOW!" && \
echo "📊 Logs saving to /tmp/joycon-test.log" && \
sleep 120 && \
kill $LOGCAT_PID && \
echo "✅ Test complete - Review logs:" && \
cat /tmp/joycon-test.log
```

## 📝 Post-Test Report Template

```
# Joy-Con L Plugin Test Results

Date: [DATE]
Device: RFCNB0CQ4ZX
APK: a-treasure-for-lora v[VERSION]

## Initialization
- [ ] Plugin loaded
- [ ] Singleton registered
- [ ] Signals connected
- [ ] Devices detected

## Button Detection
- [ ] L button (index 4)
- [ ] ZL button (index 6)
- [ ] D-pad UP (index 11)
- [ ] D-pad DOWN (index 12)
- [ ] D-pad LEFT (index 13)
- [ ] D-pad RIGHT (index 14)
- [ ] Stick click (index 10)
- [ ] Minus button (index 6)

## Issues Found
[List any problems, with log excerpts]

## Conclusion
[PASS / FAIL / PARTIAL]
```

## 🔧 Debug Commands

### See ALL logs (not filtered)
```bash
adb logcat | grep -E "(JoyConPlugin|JoyConAndroid|godot)"
```

### See raw kernel events
```bash
adb shell getevent -lt /dev/input/event11
# Press buttons, see KEYCODE events
```

### Check Godot singleton registration
```bash
adb logcat | grep -i "singleton"
```

### Dump entire session for offline analysis
```bash
adb logcat > full-session-$(date +%Y%m%d-%H%M%S).log
```
