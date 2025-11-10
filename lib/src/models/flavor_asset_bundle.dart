/// Holds generated asset paths for a flavor.
class FlavorAssetBundle {
  const FlavorAssetBundle({this.iconAssetPath, this.splashAssetPath});

  /// Relative path declared in pubspec for the flavor icon.
  final String? iconAssetPath;

  /// Relative path declared in pubspec for the flavor splash image.
  final String? splashAssetPath;

  /// Whether a custom launcher icon asset was generated.
  bool get hasIcon => iconAssetPath != null;

  /// Whether a custom splash asset was generated.
  bool get hasSplash => splashAssetPath != null;
}
