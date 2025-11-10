import 'package:collection/collection.dart';

/// Immutable description of a single application flavor.
const _undefined = Object();

class FlavorDefinition {
  const FlavorDefinition({
    required this.name,
    required this.appName,
    required this.androidApplicationId,
    required this.iosBundleId,
    required this.primaryColorHex,
    required this.environmentValues,
    this.iconSourcePath,
    this.splashImagePath,
    this.androidApplicationIdSuffix,
    this.versionNameSuffix,
  });

  /// Machine friendly identifier (e.g. `development`).
  final String name;

  /// Display name shown to end users.
  final String appName;

  /// Full application id used for Android builds.
  final String androidApplicationId;

  /// Optional suffix appended to the Android application id.
  final String? androidApplicationIdSuffix;

  /// Full bundle identifier used for iOS builds.
  final String iosBundleId;

  /// Optional version name suffix appended on Android.
  final String? versionNameSuffix;

  /// Hex color used as a seed for splash backgrounds (e.g. `#6750A4`).
  final String primaryColorHex;

  /// Optional absolute path to the launcher icon source image.
  final String? iconSourcePath;

  /// Optional absolute path to the splash image provided by the user.
  final String? splashImagePath;

  /// Key-value environment values exposed at runtime.
  final Map<String, String> environmentValues;

  /// Converts to a serializable map for persistence.
  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'appName': appName,
    'androidApplicationId': androidApplicationId,
    if (androidApplicationIdSuffix != null)
      'androidApplicationIdSuffix': androidApplicationIdSuffix,
    'iosBundleId': iosBundleId,
    if (versionNameSuffix != null) 'versionNameSuffix': versionNameSuffix,
    'primaryColorHex': primaryColorHex,
    'iconSourcePath': iconSourcePath,
    'splashImagePath': splashImagePath,
    'environmentValues': environmentValues,
  };

  /// Creates an instance from persisted JSON.
  factory FlavorDefinition.fromJson(Map<String, Object?> json) {
    return FlavorDefinition(
      name: json['name']! as String,
      appName: json['appName']! as String,
      androidApplicationId: json['androidApplicationId']! as String,
      androidApplicationIdSuffix: json['androidApplicationIdSuffix'] as String?,
      iosBundleId: json['iosBundleId']! as String,
      versionNameSuffix: json['versionNameSuffix'] as String?,
      primaryColorHex: json['primaryColorHex']! as String,
      iconSourcePath: json['iconSourcePath'] as String?,
      splashImagePath: json['splashImagePath'] as String?,
      environmentValues: Map<String, String>.from(
        (json['environmentValues'] as Map<Object?, Object?>?) ?? const {},
      ),
    );
  }

  /// Returns a copy with updated fields.
  FlavorDefinition copyWith({
    String? name,
    String? appName,
    String? androidApplicationId,
    String? androidApplicationIdSuffix,
    String? iosBundleId,
    String? versionNameSuffix,
    String? primaryColorHex,
    Object? iconSourcePath = _undefined,
    Object? splashImagePath = _undefined,
    Map<String, String>? environmentValues,
  }) {
    return FlavorDefinition(
      name: name ?? this.name,
      appName: appName ?? this.appName,
      androidApplicationId: androidApplicationId ?? this.androidApplicationId,
      androidApplicationIdSuffix:
          androidApplicationIdSuffix ?? this.androidApplicationIdSuffix,
      iosBundleId: iosBundleId ?? this.iosBundleId,
      versionNameSuffix: versionNameSuffix ?? this.versionNameSuffix,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      iconSourcePath: iconSourcePath == _undefined
          ? this.iconSourcePath
          : iconSourcePath as String?,
      splashImagePath: splashImagePath == _undefined
          ? this.splashImagePath
          : splashImagePath as String?,
      environmentValues: environmentValues ?? this.environmentValues,
    );
  }

  @override
  String toString() => 'FlavorDefinition(${toJson()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlavorDefinition &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}
