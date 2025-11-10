/// Enumerates the supported application flavors.
enum AppFlavor {
  development,
  staging,
}

extension AppFlavorDisplayName on AppFlavor {
  /// Human friendly label for the flavor.
  String get label => switch (this) {
      AppFlavor.development => 'Flavor Chef Development',
      AppFlavor.staging => 'Flavor Chef Staging',
  };
}
