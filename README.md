# JoyCon Android Plugin for Godot 4.3

![Godot 4.3](https://img.shields.io/badge/Godot-4.3-blue)
![Android](https://img.shields.io/badge/Android-5.0+-green)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A native Android plugin that enables full Joy-Con L button support in Godot 4.3 games, including D-pad, L, ZL, and Screenshot buttons that aren't normally accessible.

## ✨ Features

- **Complete Joy-Con L Support** - All buttons work: D-pad (↑↓←→), L, ZL, SL, SR, Screenshot
- **Event-Driven** - Low-latency KeyEvent interception, no polling overhead
- **Signal-Based API** - Clean GDScript integration with button press/release signals
- **Docker Build** - Reproducible builds using Google Cloud Artifact Registry
- **Android Only** - Lightweight, doesn't affect other platforms

## 🚀 Quick Start

### Prerequisites

- **Godot**: 4.3.stable or newer
- **Android SDK**: API level 21+ (Android 5.0+)
- **Docker**: For building the plugin
- **Google Cloud SDK**: For Docker authentication

### Installation

#### Option 1: Download Pre-built AAR (Recommended)

1. **Download from GitHub Actions:**
   - Go to [Actions](https://github.com/Nat-Ya/godot-controller-patch/actions)
   - Select the latest successful "Build Android Plugin" run
   - Download the `joycon-android-plugin` artifact

2. **Install in your Godot project:**
   ```bash
   mkdir -p <your-project>/addons/joycon-android-plugin
   cp joycon_android_plugin.aar <your-project>/addons/joycon-android-plugin/
   cp src/joycon_android_runtime.gd <your-project>/addons/joycon-android-plugin/
   cp plugin.cfg <your-project>/addons/joycon-android-plugin/
   cp joycon_android.gd <your-project>/addons/joycon-android-plugin/
   cp joycon_android_plugin.gdap <your-project>/addons/joycon-android-plugin/
   ```

3. **Enable in Godot:**
   - Open your project in Godot
   - Project > Project Settings > Plugins
   - Enable "JoyCon Android Plugin"

4. **Add autoload (Project Settings > Autoload):**
   - Name: `JoyConRuntime`
   - Path: `res://addons/joycon-android-plugin/joycon_android_runtime.gd`

#### Option 2: Build from Source

See [docs/BUILD.md](docs/BUILD.md) for detailed build instructions including:
- Local build with Gradle
- Docker-based build
- GitHub Actions workflow
- Troubleshooting

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed installation instructions.

## 📖 Usage

```gdscript
extends Node

func _ready() -> void:
    # Connect to button signals
    JoyConRuntime.button_pressed.connect(_on_joycon_button_pressed)
    JoyConRuntime.button_released.connect(_on_joycon_button_released)

func _on_joycon_button_pressed(device_id: int, button_index: int) -> void:
    match button_index:
        4:  print("L button pressed")
        6:  print("ZL button pressed")
        11: print("D-pad UP pressed")
        12: print("D-pad DOWN pressed")
        13: print("D-pad LEFT pressed")
        14: print("D-pad RIGHT pressed")

func _on_joycon_button_released(device_id: int, button_index: int) -> void:
    print("Button ", button_index, " released")

func _process(_delta: float) -> void:
    # Or check button state directly
    if JoyConRuntime.is_button_pressed(4):  # L button
        print("L is held down")
```

## 🔧 Button Mapping

| Joy-Con L Button | Linux Event   | Godot Index |
|------------------|---------------|-------------|
| D-pad UP         | BTN_DPAD_UP   | 11          |
| D-pad DOWN       | BTN_DPAD_DOWN | 12          |
| D-pad LEFT       | BTN_DPAD_LEFT | 13          |
| D-pad RIGHT      | BTN_DPAD_RIGHT| 14          |
| L                | BTN_TL        | 4           |
| ZL               | BTN_TL2       | 6           |
| Screenshot       | BTN_Z         | 16          |

## 🏗️ Architecture

```
Game Code (GDScript)
       ↓
joycon_android_runtime.gd (Signals & State)
       ↓
JoyConAndroidPlugin.kt (KeyEvent Interception)
       ↓
Android OS (Input System)
```

The plugin intercepts Android `KeyEvent` callbacks before Godot processes them, mapping Joy-Con L buttons to standard Godot button indices.

See [docs/SPECIFICATION.md](docs/SPECIFICATION.md) for technical details.

## 🐛 Troubleshooting

**Plugin not detected:**
```bash
# Check if plugin is loaded
adb logcat -s godot:I | grep JoyConAndroid
# Should see: [JoyConAndroid] Plugin connected
```

**Joy-Con not responding:**
```bash
# Verify OS sees Joy-Con events
adb shell getevent -tl /dev/input/event11
# Press buttons, should see BTN_TL, BTN_DPAD_UP, etc.
```

**Build fails:**
```bash
# Verify Docker authentication
gcloud auth list
gcloud auth configure-docker europe-west1-docker.pkg.dev
```

See [docs/INSTALLATION.md](docs/INSTALLATION.md#troubleshooting) for more solutions.

## 📚 Documentation

- [BUILD.md](docs/BUILD.md) - Build instructions and CI/CD information
- [SPECIFICATION.md](docs/SPECIFICATION.md) - Technical architecture and API reference
- [INSTALLATION.md](docs/INSTALLATION.md) - Detailed setup instructions
- [AGENTS.md](AGENTS.md) - Development guidelines for contributors
- [CHANGELOG.md](CHANGELOG.md) - Version history

## 🤝 Contributing

1. Read [AGENTS.md](AGENTS.md) for development guidelines
2. Follow [Conventional Commits](https://www.conventionalcommits.org/)
3. Test with real Joy-Con L hardware
4. Update documentation

## 📝 License

MIT License - See [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- Godot Engine team for the plugin API
- Nintendo Switch reverse engineering community
- Google Cloud for build infrastructure

## 📞 Support

- **Issues**: https://github.com/Nat-Ya/godot-controller-patch/issues
- **Discussions**: https://github.com/Nat-Ya/godot-controller-patch/discussions
