# AI Agent Guidelines for JoyCon Android Plugin

**Version:** 1.0  
**Last Updated:** December 4, 2025

## Project Overview

This is a **Godot 4.3 Android native plugin** that solves Joy-Con L button detection issues on Android. The project uses Docker-based builds with Google Cloud Artifact Registry.

## Core Philosophy

1. **Evidence-First Debugging** - Always verify assumptions with system-level tools (`adb`, `getevent`, `logcat`)
2. **Isolated Testing** - Build and test plugin independently before integration
3. **Clear Documentation** - Every decision must be documented with WHY
4. **Minimal Scope** - Solve ONE problem well (Joy-Con L buttons), don't add unrelated features

## Project Structure

```
godot-controller-patch/
├── android/
│   ├── plugins/
│   │   └── JoyConAndroidPlugin.kt    # Main plugin logic
│   ├── godot-lib/
│   │   └── godot-lib.release.aar     # Godot library (not in git)
│   ├── build.gradle.kts               # Gradle config
│   ├── settings.gradle.kts
│   └── AndroidManifest.xml            # Plugin registration
├── src/
│   └── joycon_android_runtime.gd      # GDScript wrapper
├── build/
│   ├── build.sh                       # Docker build script
│   ├── test.sh                        # Testing script
│   └── Dockerfile                     # Build environment
├── docs/
│   ├── SPECIFICATION.md               # Technical architecture
│   └── INSTALLATION.md                # Setup instructions
├── tests/                             # Test scripts/scenes
├── plugin.cfg                         # Godot plugin metadata
├── joycon_android.gd                  # Editor plugin script
├── joycon_android_plugin.gdap         # Plugin binary config
└── README.md                          # User-facing documentation
```

## Development Workflow

### Problem-Solving Methodology

When encountering input issues:

1. **Hardware Layer** - Does the controller physically respond? (LEDs, pairing)
2. **OS Layer** - Does Android see the events? (`adb shell getevent`)
3. **Framework Layer** - Does Godot receive them? (`InputEvent` logs)
4. **Code Layer** - Does our code handle them? (GDScript logic)

**Never skip layers!** If OS doesn't see events, framework-level fixes won't work.

### Making Changes

**Before Editing:**
1. Read SPECIFICATION.md to understand current architecture
2. Check if change affects build process (Gradle, Docker)
3. Consider backward compatibility

**When Adding Features:**
1. Update SPECIFICATION.md first (design document)
2. Implement in Kotlin/GDScript
3. Add test case
4. Update README.md with usage example
5. Update AGENTS.md if workflow changes
6. Commit with conventional commit message

**When Fixing Bugs:**
1. Reproduce with minimal test case
2. Add logging to isolate root cause
3. Document finding in commit message
4. Add regression test if possible

### Build System

**Docker Build:**
- Uses Google Cloud Artifact Registry image
- Requires `gcloud auth login` + `gcloud auth configure-docker`
- Image contains: Android SDK 34, Gradle 8.x, Kotlin, JDK 17
- Build output: `joycon_android_plugin.aar` (~50KB)

**Local Build:**
- Requires Android SDK + Gradle installed
- Use for quick iterations during development
- Docker build is source of truth for releases

### Testing Strategy

**Unit Tests:**
- Button mapping validation (KeyCode → Godot index)
- Signal emission verification
- Device ID tracking

**Integration Tests:**
- Test with actual Joy-Con L hardware
- Verify all buttons (D-pad, L, ZL, Screenshot)
- Check event vs polling behavior
- Test with Godot 4.3 export

**Manual Testing Checklist:**
```bash
# 1. Build plugin
./build/build.sh

# 2. Install in test project
cp joycon_android_plugin.aar ../test-project/addons/joycon-android-plugin/

# 3. Export and install APK
# (via Godot editor)

# 4. Monitor logs
adb logcat -s godot:I

# 5. Press Joy-Con L buttons
# Expected logs:
# [JoyConAndroid] Plugin connected
# [JoyConAndroid] Button 11 pressed on device 0  # D-pad UP
# [JoyConAndroid] Button 4 pressed on device 0   # L button
```

## Code Style

### Kotlin

```kotlin
// Use descriptive variable names
val godotButtonIndex = BUTTON_MAP[keyCode]

// Log important state changes
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
```

### GDScript

```gdscript
## Use doc comments for public API
## Check if button is pressed
func is_button_pressed(button_index: int) -> bool:
    return button_states.get(button_index, false)

# Log initialization
func _ready() -> void:
    if OS.get_name() == "Android":
        if Engine.has_singleton("JoyConAndroidPlugin"):
            plugin = Engine.get_singleton("JoyConAndroidPlugin")
            print("[JoyConAndroid] Plugin connected")
```

## Common Tasks

### Adding New Button

1. **Find KeyCode:**
   ```bash
   adb shell getevent -tl /dev/input/event11
   # Press button, note KEYCODE
   ```

2. **Add to Mapping (JoyConAndroidPlugin.kt):**
   ```kotlin
   private val BUTTON_MAP = mapOf(
       // ... existing mappings
       KeyEvent.KEYCODE_NEW_BUTTON to 99  // Choose unused index
   )
   ```

3. **Update SPECIFICATION.md:**
   - Add row to button mapping table
   - Update API examples if needed

4. **Test:**
   - Rebuild plugin
   - Verify button detected in logs

5. **Commit:**
   ```bash
   git add -A
   git commit -m "feat: add support for NEW_BUTTON (index 99)"
   ```

### Changing Godot Version

1. **Download new Godot AAR:**
   ```bash
   # From https://godotengine.org/download
   cp godot-lib.release.aar android/godot-lib/
   ```

2. **Update gradle version if needed (build.gradle.kts):**
   ```kotlin
   compileSdk = 35  // Match Godot's target
   ```

3. **Rebuild and test:**
   ```bash
   ./build/build.sh
   ```

4. **Update README.md:**
   - Update "Godot: X.X.X" version badge
   - Update compatibility notes

5. **Commit:**
   ```bash
   git commit -m "chore: update Godot compatibility to 4.X"
   ```

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style (formatting, no logic change)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Build process, dependencies

**Examples:**
```bash
feat: add support for ZL button detection
fix: prevent crash on screenshot button (-58 index)
docs: add troubleshooting section to INSTALLATION.md
chore: update Gradle to 8.10
```

## Security Considerations

- **No sensitive data** - Plugin doesn't access network, storage, or personal info
- **Minimal permissions** - Only reads gamepad input events
- **Open source** - All code is auditable
- **No telemetry** - No analytics or crash reporting

## Performance Guidelines

- **No polling loops** - Use event-driven approach
- **Minimal allocations** - Reuse collections where possible
- **Lazy initialization** - Only create objects when needed
- **Early returns** - Check device type before processing events

## Release Checklist

- [ ] All tests pass
- [ ] Documentation updated (README, SPEC, INSTALLATION)
- [ ] Version bumped in plugin.cfg
- [ ] CHANGELOG.md updated
- [ ] Build with Docker (not local Gradle)
- [ ] Test on physical Android device with Joy-Con L
- [ ] Verify all buttons work (D-pad, L, ZL, Screenshot)
- [ ] Tag release in git: `git tag v1.0.0`
- [ ] Push with tags: `git push --tags`
- [ ] Create GitHub release with AAR attached

## Known Limitations

1. **Android Only** - Plugin has no effect on Windows/Linux/macOS
2. **Joy-Con L Focus** - Designed for Joy-Con L, untested with other controllers
3. **No Vibration** - Plugin doesn't expose rumble API
4. **KeyEvent Only** - Doesn't handle motion sensors (accelerometer, gyro)

## Future Improvements

- [ ] Add unit tests with mock InputDevice
- [ ] Support Joy-Con R shoulder buttons
- [ ] Expose battery level
- [ ] Add vibration support
- [ ] Contribute fix to Godot upstream (if accepted)
- [ ] Create GDNative version for Godot 3.x

## Resources

- [Godot Android Plugin Docs](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html)
- [Android KeyEvent Reference](https://developer.android.com/reference/android/view/KeyEvent)
- [Android InputDevice API](https://developer.android.com/reference/android/view/InputDevice)
- [Linux Input Event Codes](https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h)
- [Joy-Con Reverse Engineering](https://github.com/dekuNukem/Nintendo_Switch_Reverse_Engineering)

## Support Channels

- **GitHub Issues** - Bug reports and feature requests
- **Godot Discord** - #android channel for general Android dev questions
- **Email** - For private inquiries

---

**Remember:** This plugin exists because Godot doesn't map Joy-Con L buttons on Android. If Godot fixes this upstream, we can deprecate this plugin. Always check latest Godot releases for native support!
