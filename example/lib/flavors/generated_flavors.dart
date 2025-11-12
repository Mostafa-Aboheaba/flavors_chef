import 'app_flavor.dart';
import 'flavor_config.dart';

/// Generated helpers for configuring flavors.
class GeneratedFlavorBootstrapper {
  const GeneratedFlavorBootstrapper._();

  static const Map<AppFlavor, Map<String, String>> _values = {
    AppFlavor.development: <String, String>{
      "API_BASE_URL": "https://dev.api.flavorchef.app",
      "LOG_LEVEL": "debug",
    },
  };

  /// Applies the provided [flavor].
  static void bootstrap(AppFlavor flavor) {
    final values = _values[flavor] ?? const <String, String>{};
    FlavorConfig.initialize(flavor: flavor, values: values);
  }
}
