# Flavor Chef

Flavor Chef is an interactive command‑line assistant that automates common
Flutter flavor setup tasks. The tool guides you through collecting flavor
metadata, updates Android and iOS scaffolding, prepares launcher icon and splash
configurations, and generates type-safe Dart helpers for runtime access.

## Features

- Collect multiple flavor definitions via an interactive wizard.
- Copy launcher icon and splash assets into organized flavor-specific folders.
- Configure `flutter_launcher_icons` and `flutter_native_splash` in `pubspec.yaml`.
- Scaffold Android product flavors and per-flavor resources.
- Generate reusable Dart helpers (`AppFlavor`, `FlavorConfig`, bootstrapper).
- Produce per-flavor Info.plist overlays for iOS (final scheme wiring required).

## Installation

```
dart pub global activate --source path .
```

Alternatively, add `flavor_chef` as a dev dependency and run it with
`dart run flavor_chef`.

## Usage

```
flavor_chef --project <path-to-flutter-project>
```

Follow the prompts to describe each flavor:

- Flavor key (machine readable)
- Display name
- Android/iOS identifiers and optional suffixes
- Primary color
- Launcher icon and splash asset paths
- Arbitrary key/value environment variables

After confirmation, Flavor Chef:

1. Copies assets into `assets/flavors/<flavor>/`.
2. Updates `pubspec.yaml` with flavor-aware icon and splash configuration.
3. Configures Android product flavors with manifests and resource overrides.
4. Emits iOS plist overlays (import into Xcode schemes).
5. Generates `lib/flavors/` helpers for runtime access.

### Configuration-Driven Runs

Skip the interactive wizard by supplying a YAML file:

```
flavor_chef --project <path> --config flavor_chef.yaml
```

Example structure:

```yaml
project:
  app_name: Flavor Chef
  android_application_id: com.example.flavorchef
  ios_bundle_id: com.example.flavorchef
flavors:
  - name: development
    android_application_id: com.example.flavorchef.dev
    ios_bundle_id: com.example.flavorchef.dev
    primary_color_hex: '#6750A4'
    icon_source_path: assets/source/dev_icon.png
    splash_image_path: assets/source/dev_splash.png
    environment:
      API_BASE_URL: https://dev.api.flavorchef.app
```

Every field accepted in the wizard can be provided in the file (including
optional suffixes and environment variables). Relative asset paths are resolved
from the project root.

### Manual iOS Finishing Steps

Flavor Chef generates per-flavor plist overlays and assets, but iOS still needs
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

Flavor Chef ships flavor-specific plist overlays but cannot yet automate Xcode
scheme wiring. After running the tool:

1. Open `ios/Runner.xcodeproj` in Xcode.
2. Duplicate the `Runner` scheme for each flavor (match the flavor key).
3. Point each scheme to the appropriate plist overlay to set bundle identifiers.
4. Update build configurations if you require unique signing settings.

> **Future TODO**: enhance Flavor Chef to generate the Xcode schemes/configuration
> scaffolding automatically.

## Roadmap

- Full Xcode flavor automation (schemes + build configuration cloning).
- Support for non-interactive generation via configuration files.
- Automatic invocation of launcher icon and splash generators.
