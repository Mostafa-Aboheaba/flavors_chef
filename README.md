# Flavors Chef

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/flavors_chef_banner_dark.png">
  <img src="assets/flavors_chef_banner.png" alt="Flavors Chef banner">
</picture>

Flavors Chef is an interactive command‑line assistant that automates common
Flutter flavor setup tasks. The tool guides you through collecting flavor
metadata, updates Android and iOS scaffolding, prepares launcher icon and splash
configurations, and generates type-safe Dart helpers for runtime access.

## Features

- Collect multiple flavor definitions via an interactive wizard.
- Copy launcher icon and splash assets into organized flavor-specific folders.
- Configure `flutter_launcher_icons` and `flutter_native_splash`, generating per-flavor launcher icon and splash YAML files.
- Generate a documented `flavors_chef.yaml` you can uncomment and adapt.
- Scaffold Android product flavors and per-flavor resources.
- Generate reusable Dart helpers (`AppFlavor`, `FlavorConfig`, bootstrapper).
- Produce per-flavor Info.plist overlays for iOS (final scheme wiring required).

## Installation

```
dart pub global activate --source path .
```

Alternatively, add `flavors_chef` as a dev dependency and run it with
`dart run flavors_chef`.

## Usage

```
flavors_chef --project <path-to-flutter-project>
```

Follow the prompts to describe each flavor:

- Flavor key (machine readable)
- Display name
- Android/iOS identifiers and optional suffixes
- Primary color
- Launcher icon and splash asset paths
- Arbitrary key/value environment variables

After confirmation, Flavors Chef:

1. Writes a commented `flavors_chef.template.yaml` if one does not already exist.
2. Copies assets into `assets/flavors/<flavor>/`.
3. Updates `pubspec.yaml` with flavor-aware icon and splash configuration.
4. Configures Android product flavors with manifests and resource overrides.
5. Writes `flutter_launcher_icons-<flavor>.yaml` and `flutter_native_splash-<flavor>.yaml` files reflecting your flavor configuration and invokes the generators.
6. Emits iOS plist overlays (import into Xcode schemes).
7. Generates `lib/flavors/` helpers for runtime access.

### Configuration-Driven Runs

Skip the interactive wizard by supplying a YAML file:

```
flavors_chef --project <path> --config flavors_chef.yaml
```

### Quick Start Template

Create a documented template without running the full generator:

```
dart run flavors_chef:init --project <path-to-flutter-project>
```

This writes `flavors_chef.yaml` into the target directory (optionally
overwriting an existing file) so you can uncomment the sections you need and
start from a well-documented baseline immediately.

Example structure:

```yaml
project:
  app_name: Flavors Chef
  android_application_id: com.example.flavorchef
  ios_bundle_id: com.example.flavorchef
flavors:
  - name: development
    android_application_id: com.example.flavorchef.dev
    ios_bundle_id: com.example.flavorchef.dev
    primary_color_hex: '#6750A4'
    icon_source_path: assets/source/dev_icon.png
    splash_image_path: assets/source/dev_splash.png
    launcher_icons:
      adaptive_icon_foreground: assets/source/dev_icon_fg.png
      adaptive_icon_background: '#F5F5F5'
      min_sdk_android: 26
    native_splash:
      android: true
      ios: true
      android_12:
        image: assets/source/dev_splash_android12.png
      image_dark: assets/source/dev_splash_dark.png
      color: '#6750A4'
      color_dark: '#201A2C'
    environment:
      API_BASE_URL: https://dev.api.flavorchef.app
```

Every field accepted in the wizard can be provided in the file (including optional suffixes, environment variables, and the `launcher_icons` / `native_splash` maps for any [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) or [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash) overrides). Relative asset paths are resolved from the project root.

When `launcher_icons` is present, Flavors Chef merges those attributes with sensible defaults (`image_path`, platform toggles, `remove_alpha_ios`) and writes dedicated `flutter_launcher_icons-<flavor>.yaml` files before invoking the generator. Omit the section to keep the default behavior of using `icon_source_path` alone.

Similarly, the `native_splash` section is merged with defaults (`android`, `ios`, `color`, Android 12 fallbacks, and the copied `splash_image_path` when available) before producing `flutter_native_splash-<flavor>.yaml`. Exclude the section to rely on the basic color/image defaults derived from your flavor metadata.

> **Tip:** Running `dart run flavors_chef:init` writes a fully documented `flavors_chef.yaml`. Edit that file directly—uncomment, add, or remove flavors as needed, then apply it with `flavors_chef --config flavors_chef.yaml`.

### Manual iOS Finishing Steps

Flavors Chef generates per-flavor plist overlays and assets, but iOS still needs
scheme/build configuration wiring in Xcode. Until a future release automates
this, follow these steps after running the CLI:

1. Open `ios/Runner.xcodeproj` in Xcode.
2. Duplicate the `Runner` scheme once per flavor (e.g. `Runner-development`).
3. Create matching build configurations (`Debug-development`, `Release-development`, …) or repurpose existing ones.
4. For each configuration, point `Info.plist File` to the generated overlay under `ios/FlavorChef/<flavor>.plist`.
5. Adjust signing/bundle identifiers as needed per configuration.
6. Verify `flutter run --flavor yourFlavor -t lib/main.dart` launches the correct scheme.

> **TODO**: future release—automate scheme/config duplication and plist wiring via `--config` data.

## Next Steps For iOS

Flavors Chef ships flavor-specific plist overlays but cannot yet automate Xcode
scheme wiring. After running the tool:

1. Open `ios/Runner.xcodeproj` in Xcode.
2. Duplicate the `Runner` scheme for each flavor (match the flavor key).
3. Point each scheme to the appropriate plist overlay to set bundle identifiers.
4. Update build configurations if you require unique signing settings.

> **Future TODO**: enhance Flavors Chef to generate the Xcode schemes/configuration
> scaffolding automatically.

## Roadmap

- Full Xcode flavor automation (schemes + build configuration cloning).
- Support for non-interactive generation via configuration files.
- Automatic invocation of launcher icon and splash generators.
