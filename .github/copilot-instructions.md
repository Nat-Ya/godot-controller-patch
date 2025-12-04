# GitHub Copilot Workspace Instructions

## Project Context

This workspace contains a **Godot 4.3 Android native plugin** that enables Joy-Con L button detection on Android devices. The plugin solves a specific issue where Godot doesn't map certain Linux kernel events (BTN_TL, BTN_TL2, BTN_Z, BTN_DPAD_*) to InputEventJoypadButton.

## Architecture

**Plugin Flow:**
```
Android OS (KeyEvent) → JoyConAndroidPlugin.kt → Signals → joycon_android_runtime.gd → Game Code
```

**Key Components:**
- `android/plugins/JoyConAndroidPlugin.kt` - Native Android plugin (Kotlin)
- `src/joycon_android_runtime.gd` - GDScript wrapper
- `build/build.sh` - Docker-based build script
- `docs/SPECIFICATION.md` - Technical architecture
- `AGENTS.md` - Development guidelines

## Working with This Project

### Before Making Changes

1. **Read First:**
   - `docs/SPECIFICATION.md` - Understand current architecture
   - `AGENTS.md` - Development methodology and best practices

2. **Verify Environment:**
   - Check Docker authentication: `gcloud auth list`
   - Verify godot-lib.release.aar exists in `android/godot-lib/`

### Making Code Changes

**Kotlin (android/plugins/JoyConAndroidPlugin.kt):**
- Add logging for debugging: `println("[JoyConAndroid] message")`
- Update BUTTON_MAP for new button support
- Test with Docker build after changes

**GDScript (src/joycon_android_runtime.gd):**
- Maintain signal-based API
- Keep button_states dictionary up to date
- Add doc comments for public methods

### Build System

**Docker Build (Recommended for releases):**
```bash
./build/build.sh
```

**Manual Build (Quick iterations):**
```bash
cd android
gradle assembleRelease
```

### Testing

**Unit Tests:**
```bash
# Run GUT tests in Godot editor
# See tests/test_plugin.gd
```

**Hardware Tests:**
```bash
./build/test.sh path/to/test.apk
# Press Joy-Con L buttons, verify logs
```

### Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new button support
fix: prevent crash on invalid index
docs: update installation guide
chore: bump Godot version
```

## Common Tasks

### Adding Button Support

1. Find KeyCode: `adb shell getevent -tl /dev/input/eventX`
2. Add to BUTTON_MAP in `JoyConAndroidPlugin.kt`
3. Update `docs/SPECIFICATION.md` mapping table
4. Rebuild and test
5. Commit: `feat: add support for BUTTON_NAME`

### Updating Godot Version

1. Download new godot-lib.release.aar
2. Update `android/build.gradle.kts` compileSdk if needed
3. Test build
4. Update README.md compatibility notes
5. Commit: `chore: update Godot compatibility to X.X`

### Debugging Issues

**Check System Layers:**
1. Hardware: Does Joy-Con pair/LED respond?
2. OS: `adb shell getevent` shows events?
3. Framework: `adb logcat -s godot:I` shows plugin logs?
4. Code: Add debug prints, rebuild

## File Structure Reference

```
godot-controller-patch/
├── android/                      # Android plugin project
│   ├── plugins/
│   │   └── JoyConAndroidPlugin.kt   # Main plugin logic
│   ├── godot-lib/                   # Godot AAR (not in git)
│   ├── build.gradle.kts             # Gradle configuration
│   ├── settings.gradle.kts          # Gradle settings
│   └── AndroidManifest.xml          # Plugin registration
├── src/                          # GDScript source
│   └── joycon_android_runtime.gd    # Runtime wrapper
├── build/                        # Build scripts
│   ├── build.sh                     # Docker build
│   ├── test.sh                      # Testing script
│   └── Dockerfile                   # Build environment
├── docs/                         # Documentation
│   ├── SPECIFICATION.md             # Technical architecture
│   └── INSTALLATION.md              # Setup guide
├── tests/                        # Test suite
│   └── test_plugin.gd               # GUT unit tests
├── plugin.cfg                    # Godot plugin metadata
├── joycon_android.gd             # Editor plugin script
├── joycon_android_plugin.gdap    # Binary config
├── AGENTS.md                     # AI agent guidelines
├── README.md                     # User documentation
├── CHANGELOG.md                  # Version history
└── LICENSE                       # MIT License
```

## Important Constraints

1. **Android Only** - Plugin has no effect on other platforms
2. **Godot 4.3+** - Requires Godot 4.3.stable or newer
3. **KeyEvent API** - Uses Android KeyEvent, not InputDevice motion sensors
4. **Joy-Con L Focus** - Designed specifically for Joy-Con L hardware

## Resources

- **Godot Docs:** https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html
- **Android KeyEvent:** https://developer.android.com/reference/android/view/KeyEvent
- **Project Repo:** https://github.com/Nat-Ya/godot-controller-patch

## Questions?

Check `AGENTS.md` for detailed development guidelines and best practices.
