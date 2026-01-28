## 0.2.0

- Add `flavors_chef:init` command to generate documented `flavors_chef.yaml` template
- Add `flavors_chef:generate` shortcut command (defaults to current directory and `flavors_chef.yaml`)
- Integrate `flutter_launcher_icons` with per-flavor configuration support
- Integrate `flutter_native_splash` with per-flavor configuration support
- Add `launcher_icons` configuration section supporting all `flutter_launcher_icons` options
- Add `native_splash` configuration section supporting all `flutter_native_splash` options
- Generate per-flavor `flutter_launcher_icons-<flavor>.yaml` files
- Generate per-flavor `flutter_native_splash-<flavor>.yaml` files
- Automatically run launcher icon and splash screen generators during flavor setup
- Auto-detect project defaults (app name, bundle IDs) from `pubspec.yaml` when generating config template
- Improve README with better structure and user-friendly documentation

## 0.1.0

- Convert package into a Dart CLI for Flutter flavor automation.
- Add interactive wizard, asset pipeline, Android scaffolding, and Dart helpers.
- Provide initial iOS plist overlays and documentation for manual wiring.
- Introduce `--config` flag to drive generation from a YAML file (non-interactive mode).
