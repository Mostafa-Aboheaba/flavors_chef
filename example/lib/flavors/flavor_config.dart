import 'package:collection/collection.dart';

import 'app_flavor.dart';

/// Holds runtime configuration for the selected flavor.
class FlavorConfig {
  FlavorConfig._({required this.flavor, required Map<String, String> values})
    : values = Map.unmodifiable(values);

  static FlavorConfig? _instance;

  /// Active flavor configuration.
  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('FlavorConfig.initialize must be called before access.');
    }
    return config;
  }

  /// Initialize the active configuration.
  static void initialize({
    required AppFlavor flavor,
    required Map<String, String> values,
  }) {
    _instance = FlavorConfig._(flavor: flavor, values: values);
  }

  /// Selected application flavor.
  final AppFlavor flavor;

  /// Immutable environment values for the flavor.
  final Map<String, String> values;

  /// Returns the value for [key] or `null` when absent.
  String? operator [](String key) => values[key];

  @override
  String toString() => 'FlavorConfig(flavor: $flavor, values: $values)';

  @override
  int get hashCode =>
      Object.hash(flavor, const DeepCollectionEquality().hash(values));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlavorConfig &&
          runtimeType == other.runtimeType &&
          flavor == other.flavor &&
          const DeepCollectionEquality().equals(values, other.values);
}
