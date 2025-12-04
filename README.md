# JoyCon Android Plugin

Direct access to Joy-Con L buttons on Android via InputDevice API.

## Problem

Godot on Android doesn't map Joy-Con L buttons from Linux kernel events:
- `BTN_TL` (L button)
- `BTN_TL2` (ZL button)
- `BTN_Z` (Screenshot button)
- `BTN_DPAD_*` (D-pad)

Android OS receives these events (confirmed via `getevent`), but Godot's input system doesn't expose them.

## Solution

This plugin uses Android's `KeyEvent` API to intercept button presses directly and expose them via signals.

## Building

**Prerequisites:**
- Android SDK with Build Tools 34+
- Kotlin compiler
- Godot 4.3+ AAR library

**Steps:**

1. **Copy Godot AAR:**
   ```bash
   mkdir -p godot/bin
   cp path/to/godot-lib.release.aar godot/bin/
   ```

2. **Build plugin:**
   ```bash
   cd addons/joycon-android-plugin/android
   gradle assembleRelease
   ```

3. **Copy output:**
   ```bash
   cp build/outputs/aar/android-release.aar ../joycon_android_plugin.aar
   ```

## Usage

**In `project.godot`:**
```gdscript
[autoload]
JoyConAndroid="*res://addons/joycon-android-plugin/joycon_android_runtime.gd"
```

**In code:**
```gdscript
# Check if D-pad pressed
if JoyConAndroid.is_button_pressed(11):  # D-pad UP
    print("D-pad UP!")

# Or connect to signals
JoyConAndroid.button_pressed.connect(_on_joycon_button)
```

## Button Mappings

| Button | KeyEvent | Godot Index |
|--------|----------|-------------|
| L | `KEYCODE_BUTTON_L1` | 4 |
| ZL | `KEYCODE_BUTTON_L2` | 6 |
| Screenshot | `KEYCODE_BUTTON_Z` | 16 |
| D-pad UP | `KEYCODE_DPAD_UP` | 11 |
| D-pad DOWN | `KEYCODE_DPAD_DOWN` | 12 |
| D-pad LEFT | `KEYCODE_DPAD_LEFT` | 13 |
| D-pad RIGHT | `KEYCODE_DPAD_RIGHT` | 14 |
| Minus | `KEYCODE_BUTTON_SELECT` | 6 |
| Stick Click | `KEYCODE_BUTTON_THUMBL` | 10 |

## License

MIT
