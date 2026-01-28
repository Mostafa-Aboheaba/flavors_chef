# Flavors Chef

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/flavors_chef_banner_dark.png">
  <img src="assets/flavors_chef_banner.png" alt="Flavors Chef banner">
</picture>

**Flavors Chef** automates Flutter flavor setup. Generate launcher icons, splash screens, Android product flavors, iOS configurations, and type-safe Dart helpers—all from a single YAML file.

## Quick Start

### 1. Install

```bash
dart pub global activate flavors_chef
```

Or add as a dev dependency:

```yaml
dev_dependencies:
  flavors_chef: ^0.1.0
```

### 2. Initialize Configuration

Generate a ready-to-use configuration file:

```bash
dart run flavors_chef:init
```

This creates `flavors_chef.yaml` in your project root with documented examples for development, staging, and production flavors.

### 3. Edit Configuration

Open `flavors_chef.yaml` and uncomment the flavors you need. The file includes:
- Project defaults (pre-filled from your `pubspec.yaml`)
- Three example flavors (development, staging, production) with comments
- All available options documented inline

### 4. Generate Flavors

Apply your configuration:

```bash
dart run flavors_chef:generate
```

Or use the full command:

```bash
flavors_chef --project . --config flavors_chef.yaml
```

## What Gets Generated

Flavors Chef automatically:

1. ✅ Copies assets to `assets/flavors/<flavor>/`
2. ✅ Updates `pubspec.yaml` with required dependencies
3. ✅ Generates `flutter_launcher_icons-<flavor>.yaml` files
4. ✅ Generates `flutter_native_splash-<flavor>.yaml` files
5. ✅ Runs launcher icon and splash screen generators
6. ✅ Configures Android product flavors and resources
7. ✅ Creates iOS Info.plist overlays
8. ✅ Generates Dart helpers in `lib/flavors/`

## Configuration Example

```yaml
project:
  app_name: My App
  android_application_id: com.example.myapp
  ios_bundle_id: com.example.myapp

flavors:
  - name: development
    app_name: My App Dev
    android_application_id: com.example.myapp.dev
    ios_bundle_id: com.example.myapp.dev
    primary_color_hex: '#6750A4'
    icon_source_path: assets/icons/dev_icon.png
    splash_image_path: assets/splash/dev_splash.png
    launcher_icons:
      adaptive_icon_foreground: assets/icons/dev_fg.png
      adaptive_icon_background: '#FFFFFF'
    native_splash:
      color: '#6750A4'
      image: assets/splash/dev_splash.png
    environment:
      API_BASE_URL: https://dev.api.example.com
      LOG_LEVEL: debug
```

## Advanced Configuration

### Launcher Icons

Customize launcher icon generation with any [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) options:

```yaml
launcher_icons:
  android: true
  ios: true
  min_sdk_android: 26
  adaptive_icon_foreground: assets/icons/fg.png
  adaptive_icon_background: '#F5F5F5'
  adaptive_icon_monochrome: assets/icons/mono.png
  image_path_ios_dark_transparent: assets/icons/dark.png
```

### Native Splash

Customize splash screens with any [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash) options:

```yaml
native_splash:
  android: true
  ios: true
  color: '#6750A4'
  color_dark: '#201A2C'
  image: assets/splash/splash.png
  image_dark: assets/splash/splash_dark.png
  android_12:
    color: '#6750A4'
    image: assets/splash/android12.png
```

## Interactive Mode

Run without a config file for a guided setup:

```bash
flavors_chef --project .
```

Follow the prompts to configure each flavor interactively.

## iOS Setup

After generating flavors, configure Xcode:

1. Open `ios/Runner.xcodeproj` in Xcode
2. Duplicate the `Runner` scheme for each flavor (e.g., `Runner-development`)
3. Create build configurations (`Debug-development`, `Release-development`, etc.)
4. Point each configuration's `Info.plist File` to `ios/FlavorChef/<flavor>.plist`
5. Adjust signing and bundle identifiers per configuration

Then run:

```bash
flutter run --flavor development
```

## Features

- 🎨 **Unified Configuration** - One YAML file for all flavor settings
- 🚀 **Zero Manual Setup** - Automatically configures Android and iOS
- 🎯 **Type-Safe Helpers** - Generated Dart code for runtime flavor access
- 📱 **Icon & Splash** - Integrated with `flutter_launcher_icons` and `flutter_native_splash`
- 🔧 **Flexible** - Supports all launcher icon and splash screen options
- 📝 **Well-Documented** - Generated config includes inline documentation

## Commands

| Command | Description |
|---------|-------------|
| `dart run flavors_chef:init` | Generate `flavors_chef.yaml` template |
| `dart run flavors_chef:generate` | Apply config (uses `flavors_chef.yaml` by default) |
| `flavors_chef --project . --config flavors_chef.yaml` | Full command with explicit paths |
| `flavors_chef --project .` | Interactive mode |

## Requirements

- Flutter SDK
- `flutter_launcher_icons` (auto-added as dev dependency)
- `flutter_native_splash` (auto-added as dev dependency)

## Contributing

For local development:

```bash
dart pub global activate --source path .
```

## License

See [LICENSE](LICENSE) file for details.
