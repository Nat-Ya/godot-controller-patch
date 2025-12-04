# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial plugin implementation
- Docker-based build system
- Comprehensive documentation (SPECIFICATION, INSTALLATION, AGENTS)

## [1.0.0] - 2025-12-04

### Added
- Joy-Con L button support on Android (D-pad, L, ZL, Screenshot)
- Kotlin plugin using Android KeyEvent API
- GDScript runtime wrapper with signal-based API
- Button mapping: BTN_TL→4, BTN_TL2→6, BTN_Z→16, BTN_DPAD_*→11-14
- Google Cloud Artifact Registry Docker build support
- ADB-based testing tools
- MIT License

### Fixed
- Joy-Con L buttons not detected by Godot on Android
- Screenshot button crash (invalid -58 index)

### Known Issues
- Screenshot button emits -58 index (filtered out by plugin)
- Only tested with Joy-Con L hardware
- No vibration support

[Unreleased]: https://github.com/Nat-Ya/godot-controller-patch/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Nat-Ya/godot-controller-patch/releases/tag/v1.0.0
