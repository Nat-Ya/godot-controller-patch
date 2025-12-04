# JoyCon Android Plugin - Technical Specification

## Version 1.0.0

## Overview

Godot 4.3 Android plugin that provides direct access to Nintendo Joy-Con L controller buttons via Android's InputDevice API. Solves the issue where Godot doesn't map certain Joy-Con L buttons from Linux kernel events.

## Problem Statement

### Current Limitation

When Joy-Con L is connected to Android via Bluetooth, the Android OS correctly receives button events at the kernel level:

```bash
$ adb shell getevent /dev/input/event11
BTN_TL (L button)
BTN_TL2 (ZL button)
BTN_Z (Screenshot button)
BTN_DPAD_UP/DOWN/LEFT/RIGHT
```

However, **Godot's Android input backend doesn't translate these kernel events into `InputEventJoypadButton`**, making these buttons completely inaccessible to Godot games.

### Affected Buttons

- **L button** (`BTN_TL`)
- **ZL button** (`BTN_TL2`)
- **Screenshot/Capture button** (`BTN_Z`)
- **D-pad** (`BTN_DPAD_UP`, `BTN_DPAD_DOWN`, `BTN_DPAD_LEFT`, `BTN_DPAD_RIGHT`)
- **Minus button** (`BTN_SELECT`)
- **Stick click** (`BTN_THUMBL`)

### Working Components

- ✅ Analog stick (axes work fine)
- ✅ Joy-Con R buttons (work because they map to standard ABXY)
- ✅ Dual Joy-Con mode analog sticks

## Solution Architecture

### Approach

Create a native Android plugin that:
1. Intercepts `KeyEvent` callbacks from Android's input system
2. Maps Android `KEYCODE_*` values to Godot-compatible button indices
3. Emits GDScript signals when buttons are pressed/released
4. Provides polling API as fallback

### Technology Stack

- **Language:** Kotlin (Android plugin), GDScript (runtime wrapper)
- **Build System:** Gradle + Docker
- **Godot Version:** 4.3.stable
- **Android API:** Level 21+ (Android 5.0+)
- **Build Container:** `europe-west1-docker.pkg.dev/general-476320/android-build-images/android-build-image:latest`

## Architecture

### Component Diagram

```
┌─────────────────────────────────────┐
│   Godot Game (GDScript)             │
│   - Uses ControllerHandler API      │
└───────────┬─────────────────────────┘
            │
            ├─ signals: button_pressed, button_released
            │
┌───────────▼─────────────────────────┐
│   joycon_android_runtime.gd         │
│   - Connects to plugin singleton    │
│   - Maintains button state dict     │
│   - Provides is_button_pressed()    │
└───────────┬─────────────────────────┘
            │
            ├─ Engine.get_singleton("JoyConAndroidPlugin")
            │
┌───────────▼─────────────────────────┐
│   JoyConAndroidPlugin.kt            │
│   - Extends GodotPlugin             │
│   - Override onMainKeyDown/Up()     │
│   - Maps KEYCODE_* to button index  │
└───────────┬─────────────────────────┘
            │
            ├─ KeyEvent.getKeyCode()
            │
┌───────────▼─────────────────────────┐
│   Android Input System              │
│   - Receives BTN_* from kernel      │
│   - Translates to KEYCODE_*         │
└─────────────────────────────────────┘
```

### Button Mapping

| Linux Kernel Event | Android KeyCode | Godot Index | Godot Constant |
|-------------------|-----------------|-------------|----------------|
| `BTN_TL` | `KEYCODE_BUTTON_L1` | 4 | `JOY_BUTTON_LEFT_SHOULDER` |
| `BTN_TL2` | `KEYCODE_BUTTON_L2` | 6 | `JOY_BUTTON_LEFT_TRIGGER` |
| `BTN_Z` | `KEYCODE_BUTTON_Z` | 16 | (custom) |
| `BTN_DPAD_UP` | `KEYCODE_DPAD_UP` | 11 | `JOY_BUTTON_DPAD_UP` |
| `BTN_DPAD_DOWN` | `KEYCODE_DPAD_DOWN` | 12 | `JOY_BUTTON_DPAD_DOWN` |
| `BTN_DPAD_LEFT` | `KEYCODE_DPAD_LEFT` | 13 | `JOY_BUTTON_DPAD_LEFT` |
| `BTN_DPAD_RIGHT` | `KEYCODE_DPAD_RIGHT` | 14 | `JOY_BUTTON_DPAD_RIGHT` |
| `BTN_SELECT` | `KEYCODE_BUTTON_SELECT` | 6 | `JOY_BUTTON_BACK` |
| `BTN_THUMBL` | `KEYCODE_BUTTON_THUMBL` | 10 | `JOY_BUTTON_LEFT_STICK` |

## Plugin API

### Signals

```gdscript
signal button_pressed(device_id: int, button_index: int)
signal button_released(device_id: int, button_index: int)
```

### Methods

```gdscript
# Check if button is currently pressed
func is_button_pressed(button_index: int) -> bool

# Poll all pressed buttons (returns array of indices)
func poll_buttons(device_id: int) -> Array
```

### Usage Example

```gdscript
extends Node

func _ready() -> void:
    if JoyConAndroid:
        JoyConAndroid.button_pressed.connect(_on_joycon_button)

func _on_joycon_button(device_id: int, button_index: int) -> void:
    if button_index == 11:  # D-pad UP
        print("D-pad UP pressed on device ", device_id)
    elif button_index == 4:  # L button
        print("L button pressed")
```

## Build System

### Docker-Based Build

Uses Google Cloud Artifact Registry container with pre-configured Android SDK and build tools.

**Build Steps:**
1. Authenticate with GCloud (`gcloud auth login`)
2. Configure Docker auth (`gcloud auth configure-docker europe-west1-docker.pkg.dev`)
3. Pull build image
4. Run Gradle inside container
5. Extract AAR artifact

### Output

- **File:** `joycon_android_plugin.aar`
- **Size:** ~50KB
- **Installation:** Copy to Godot project's `addons/` folder

## Performance

- **Memory:** < 1MB
- **CPU:** Negligible (event-driven)
- **Latency:** < 1ms (direct KeyEvent interception)
- **Battery Impact:** None (no polling loops)

## Limitations

- **Android Only:** Plugin has no effect on other platforms
- **Joy-Con L Specific:** Designed for Joy-Con L, but should work with other controllers reporting similar keycodes
- **No Vibration:** Plugin doesn't expose rumble features (separate implementation needed)

## Future Enhancements

- [ ] Add rumble/vibration support via Android Vibrator API
- [ ] Expose battery level
- [ ] Support Joy-Con R shoulder buttons (if needed)
- [ ] Contribute fix to Godot upstream

## References

- [Godot Android Plugins Documentation](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html)
- [Android KeyEvent Reference](https://developer.android.com/reference/android/view/KeyEvent)
- [Android InputDevice API](https://developer.android.com/reference/android/view/InputDevice)
- [Linux Input Event Codes](https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h)

---

**Document Version:** 1.0.0  
**Last Updated:** December 4, 2025  
**Author:** Nat-Ya
