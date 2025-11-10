import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Generates Dart helpers for accessing flavor metadata at runtime.
class DartGenerator {
  DartGenerator({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<void> generate(List<FlavorDefinition> flavors) async {
    final flavorsDir = Directory(
      p.join(context.projectRoot.path, 'lib', 'flavors'),
    );
    if (!flavorsDir.existsSync()) {
      flavorsDir.createSync(recursive: true);
    }

    await _writeAppFlavorFile(flavorsDir, flavors);
    await _writeFlavorConfigFile(flavorsDir);
    await _writeGeneratedFlavorsFile(flavorsDir, flavors);

    stdout.writeln('  • Generated lib/flavors helpers');
  }

  Future<void> _writeAppFlavorFile(
    Directory flavorsDir,
    List<FlavorDefinition> flavors,
  ) async {
    final enumEntries = flavors.map((flavor) => '  ${flavor.name},').join('\n');

    final labelSwitch = flavors
        .map(
          (flavor) =>
              '      AppFlavor.${flavor.name} => '
              "'${flavor.appName}',",
        )
        .join('\n');

    final file = File(p.join(flavorsDir.path, 'app_flavor.dart'));
    await file.writeAsString('''
/// Enumerates the supported application flavors.
enum AppFlavor {
$enumEntries
}

extension AppFlavorDisplayName on AppFlavor {
  /// Human friendly label for the flavor.
  String get label => switch (this) {
$labelSwitch
  };
}
''');
  }

  Future<void> _writeFlavorConfigFile(Directory flavorsDir) async {
    final file = File(p.join(flavorsDir.path, 'flavor_config.dart'));
    await file.writeAsString('''
import 'package:collection/collection.dart';

import 'app_flavor.dart';

/// Holds runtime configuration for the selected flavor.
class FlavorConfig {
  FlavorConfig._({
    required this.flavor,
    required Map<String, String> values,
  }) : values = Map.unmodifiable(values);

  static FlavorConfig? _instance;

  /// Active flavor configuration.
  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'FlavorConfig.initialize must be called before access.',
      );
    }
    return config;
  }

  /// Initialize the active configuration.
  static void initialize({
    required AppFlavor flavor,
    required Map<String, String> values,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      values: values,
    );
  }

  /// Selected application flavor.
  final AppFlavor flavor;

  /// Immutable environment values for the flavor.
  final Map<String, String> values;

  /// Returns the value for [key] or `null` when absent.
  String? operator [](String key) => values[key];

  @override
  String toString() => 'FlavorConfig(flavor: \$flavor, values: \$values)';

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
''');
  }

  Future<void> _writeGeneratedFlavorsFile(
    Directory flavorsDir,
    List<FlavorDefinition> flavors,
  ) async {
    final mapEntries = flavors
        .map((flavor) {
          final envEntries = flavor.environmentValues.entries
              .map(
                (entry) =>
                    '"${entry.key}": "${entry.value.replaceAll('"', r'\"')}"',
              )
              .join(', ');
          return '    AppFlavor.${flavor.name}: <String, String>{'
              '$envEntries},';
        })
        .join('\n');

    final file = File(p.join(flavorsDir.path, 'generated_flavors.dart'));
    await file.writeAsString('''
import 'app_flavor.dart';
import 'flavor_config.dart';

/// Generated helpers for configuring flavors.
class GeneratedFlavorBootstrapper {
  const GeneratedFlavorBootstrapper._();

  static const Map<AppFlavor, Map<String, String>> _values = {
$mapEntries
  };

  /// Applies the provided [flavor].
  static void bootstrap(AppFlavor flavor) {
    final values = _values[flavor] ?? const <String, String>{};
    FlavorConfig.initialize(flavor: flavor, values: values);
  }
}
''');
  }
}
