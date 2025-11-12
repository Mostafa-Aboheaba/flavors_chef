import 'dart:io';

import '../models/flavor_project_context.dart';

/// Writes a documented sample configuration file that users can adapt.
class ConfigTemplateWriter {
  ConfigTemplateWriter({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  /// Writes `flavors_chef.yaml`, overwriting any existing file.
  Future<void> writeConfig() async {
    final file = File(context.resolvePath('flavors_chef.yaml'));
    await file.writeAsString(_buildTemplate());
    stdout.writeln('  • Wrote flavors_chef.yaml');
  }

  String _buildTemplate() =>
      '''
# flavors_chef.yaml
# -----------------------------------------------------------------------------
# This documented template shows how to describe your Flutter flavors using
# Flavors Chef. Uncomment the project defaults below to override the detected
# values. Each flavor section includes commented guidance you can enable when
# ready.
#
# Each flavor definition can override application names, bundle identifiers,
# launcher icons, splash screens, and environment variables.
#
# Tips:
# • Use absolute or project-relative paths for icon/splash assets.
# • When unsure, run `dart run flavors_chef --config flavors_chef.yaml` to apply
#   the configuration in a non-interactive way.
# • You can keep any sections commented out until you need them.
#
# -----------------------------------------------------------------------------

project:
  app_name: ${context.appName} # Shared display name used when a flavor does not override it.
  android_application_id: ${context.androidApplicationId} # Base Android applicationId.
  ios_bundle_id: ${context.iosBundleId} # Base iOS bundle identifier.

flavors:
  # ---------------------------------------------------------------------------
  # Development flavor
  # ---------------------------------------------------------------------------
  # - name: development
  #   app_name: ${context.appName} Dev # Optional override shown on device home screens.
  #   android_application_id: ${context.androidApplicationId}.dev # Unique package name per flavor.
  #   ios_bundle_id: ${context.iosBundleId}.dev # Unique bundle id per flavor.
  #   primary_color_hex: '#6750A4' # Seed color used for splash + theming defaults.
  #   icon_source_path: assets/flavors/development/icon.png # Launcher icon (1024x1024 recommended).
  #   splash_image_path: assets/flavors/development/splash.png # Optional splash illustration.
  #   launcher_icons:
  #     android: true
  #     ios: true
  #     adaptive_icon_foreground: assets/flavors/development/icon_foreground.png
  #     adaptive_icon_background: '#FFFFFF'
  #   native_splash:
  #     android: true
  #     ios: true
  #     color: '#6750A4'
  #     color_dark: '#201A2C'
  #     image: assets/flavors/development/splash.png
  #     image_dark: assets/flavors/development/splash_dark.png
  #     android_12:
  #       image: assets/flavors/development/splash_android12.png
  #   environment:
  #     API_BASE_URL: https://dev.api.flavorchef.app
  #     LOG_LEVEL: debug

  # ---------------------------------------------------------------------------
  # Staging flavor
  # ---------------------------------------------------------------------------
  # - name: staging
  #   app_name: ${context.appName} Staging
  #   android_application_id: ${context.androidApplicationId}.stg
  #   ios_bundle_id: ${context.iosBundleId}.stg
  #   primary_color_hex: '#2962FF'
  #   icon_source_path: assets/flavors/staging/icon.png
  #   splash_image_path: assets/flavors/staging/splash.png
  #   launcher_icons:
  #     android: true
  #     ios: true
  #   native_splash:
  #     android: true
  #     ios: true
  #     color: '#2962FF'
  #     image: assets/flavors/staging/splash.png
  #     android_12:
  #       color: '#2962FF'
  #       image: assets/flavors/staging/splash_android12.png
  #   environment:
  #     API_BASE_URL: https://staging.api.flavorchef.app
  #     LOG_LEVEL: info

  # ---------------------------------------------------------------------------
  # Production flavor
  # ---------------------------------------------------------------------------
  # - name: production
  #   app_name: ${context.appName}
  #   android_application_id: ${context.androidApplicationId}
  #   ios_bundle_id: ${context.iosBundleId}
  #   primary_color_hex: '#0D47A1'
  #   icon_source_path: assets/flavors/production/icon.png
  #   splash_image_path: assets/flavors/production/splash.png
  #   launcher_icons:
  #     android: true
  #     ios: true
  #   native_splash:
  #     android: true
  #     ios: true
  #     color: '#0D47A1'
  #     android_12:
  #       color: '#0D47A1'
  #   environment:
  #     API_BASE_URL: https://api.flavorchef.app
  #     LOG_LEVEL: warning

# End of template -------------------------------------------------------------
''';
}
