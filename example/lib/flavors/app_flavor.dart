/// Enumerates the supported application flavors.
enum AppFlavor { development }

extension AppFlavorDisplayName on AppFlavor {
  /// Human friendly label for the flavor.
  String get label => switch (this) {
    AppFlavor.development =>
      'Flavors Chef Development# Optional override shown on device home screens.',
  };
}
