import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';
import '../services/project_inspector.dart';
import '../utils/flavor_defaults.dart';
import '../utils/validation.dart';

typedef ParsedFlavorConfig = ({
  FlavorProjectContext context,
  List<FlavorDefinition> flavors,
});

/// Parses a YAML configuration file into flavor definitions.
class FlavorConfigParser {
  FlavorConfigParser({required Directory projectRoot, required this.metadata})
    : projectRoot = projectRoot.absolute;

  final Directory projectRoot;
  final ProjectMetadata metadata;

  ParsedFlavorConfig parse(File file) {
    final document = file.readAsStringSync();
    if (document.trim().isEmpty) {
      throw FormatException('Configuration file is empty.');
    }

    final root = loadYaml(document);
    if (root is! YamlMap) {
      throw FormatException('Configuration root must be a YAML map.');
    }

    final projectMap = _asYamlMap(root['project']);

    final appName = _readString(projectMap, 'app_name') ?? metadata.displayName;
    final androidId =
        _readString(projectMap, 'android_application_id') ??
        metadata.androidApplicationId;
    final iosId =
        _readString(projectMap, 'ios_bundle_id') ??
        metadata.iosBundleIdentifier;

    final context = FlavorProjectContext(
      projectRoot: projectRoot,
      appName: appName,
      androidApplicationId: androidId,
      iosBundleId: iosId,
    );

    final flavorsNode = root['flavors'];
    if (flavorsNode is! YamlList || flavorsNode.isEmpty) {
      throw FormatException('Configuration must define at least one flavor.');
    }

    final flavors = <FlavorDefinition>[];

    for (var index = 0; index < flavorsNode.length; index++) {
      final entry = flavorsNode[index];
      if (entry is! YamlMap) {
        throw FormatException('Flavor entry at index $index must be a map.');
      }
      flavors.add(_parseFlavor(entry, index, context));
    }

    return (context: context, flavors: flavors);
  }

  FlavorDefinition _parseFlavor(
    YamlMap entry,
    int index,
    FlavorProjectContext context,
  ) {
    final rawName = _requireString(entry, 'name', index);
    final flavorName = sanitizeFlavorName(rawName);
    if (!isValidFlavorName(flavorName)) {
      throw FormatException(
        'Flavor name "$rawName" (index $index) is invalid. Use lowercase '
        'letters, numbers, and underscores, starting with a letter.',
      );
    }

    final appName =
        _readString(entry, 'app_name') ??
        defaultFlavorDisplayName(
          baseAppName: context.appName,
          flavorName: flavorName,
        );

    final androidId =
        _readString(entry, 'android_application_id') ??
        defaultAndroidApplicationId(
          base: context.androidApplicationId,
          flavorName: flavorName,
        );

    final iosId =
        _readString(entry, 'ios_bundle_id') ??
        defaultIosBundleId(base: context.iosBundleId, flavorName: flavorName);

    final colorHex = _readString(entry, 'primary_color_hex') ?? '#6750A4';
    if (!isValidHexColor(colorHex)) {
      throw FormatException(
        'Invalid primary_color_hex for flavor "$flavorName": $colorHex',
      );
    }

    final iconPath = _resolveOptionalPath(
      context,
      _readString(entry, 'icon_source_path'),
      'icon_source_path',
      flavorName,
    );

    final splashPath = _resolveOptionalPath(
      context,
      _readString(entry, 'splash_image_path'),
      'splash_image_path',
      flavorName,
    );

    final launcherIconsConfig = _readLauncherIconConfig(entry, flavorName);
    final nativeSplashConfig = _readNativeSplashConfig(entry, flavorName);

    final environment = <String, String>{};
    final envNode = entry['environment'];
    if (envNode != null) {
      if (envNode is! YamlMap) {
        throw FormatException(
          'Environment for flavor "$flavorName" must be a map of key/value pairs.',
        );
      }
      for (final key in envNode.keys) {
        environment[key.toString()] = envNode[key]?.toString() ?? '';
      }
    }

    final androidSuffix = _readString(entry, 'android_application_id_suffix');
    final versionSuffix = _readString(entry, 'version_name_suffix');

    return FlavorDefinition(
      name: flavorName,
      appName: appName,
      androidApplicationId: androidId,
      androidApplicationIdSuffix:
          androidSuffix != null && androidSuffix.isNotEmpty
          ? androidSuffix
          : null,
      iosBundleId: iosId,
      versionNameSuffix: versionSuffix != null && versionSuffix.isNotEmpty
          ? versionSuffix
          : null,
      primaryColorHex: colorHex,
      iconSourcePath: iconPath,
      splashImagePath: splashPath,
      environmentValues: Map.unmodifiable(environment),
      launcherIconConfig: launcherIconsConfig,
      nativeSplashConfig: nativeSplashConfig,
    );
  }

  Map<String, Object?> _readLauncherIconConfig(
    YamlMap entry,
    String flavorName,
  ) {
    final node = entry['launcher_icons'];
    if (node == null) {
      return const {};
    }
    if (node is! YamlMap) {
      throw FormatException(
        'launcher_icons for flavor "$flavorName" must be a map.',
      );
    }
    return Map.unmodifiable(_convertYamlMap(node));
  }

  Map<String, Object?> _readNativeSplashConfig(
    YamlMap entry,
    String flavorName,
  ) {
    final node = entry.containsKey('native_splash')
        ? entry['native_splash']
        : entry['native_splash_config'];
    if (node == null) {
      return const {};
    }
    if (node is! YamlMap) {
      throw FormatException(
        'native_splash for flavor "$flavorName" must be a map.',
      );
    }
    return Map.unmodifiable(_convertYamlMap(node));
  }

  Map<String, Object?> _convertYamlMap(YamlMap map) {
    final result = <String, Object?>{};
    for (final entry in map.entries) {
      result[entry.key.toString()] = _convertYamlNode(entry.value);
    }
    return result;
  }

  Object? _convertYamlNode(Object? node) {
    if (node is YamlMap) {
      return Map.unmodifiable(_convertYamlMap(node));
    }
    if (node is YamlList) {
      return List<Object?>.unmodifiable(
        node.map<Object?>((item) => _convertYamlNode(item)),
      );
    }
    return node;
  }

  YamlMap? _asYamlMap(Object? node) {
    if (node == null) {
      return null;
    }
    if (node is! YamlMap) {
      throw FormatException('Expected a map node in configuration.');
    }
    return node;
  }

  String? _readString(YamlMap? map, String key) {
    if (map == null) {
      return null;
    }
    final value = map[key];
    return value?.toString();
  }

  String _requireString(YamlMap map, String key, int index) {
    final value = map[key];
    if (value == null) {
      throw FormatException('Missing "$key" for flavor at index $index.');
    }
    if (value is! String) {
      throw FormatException(
        'Field "$key" for flavor at index $index must be a string.',
      );
    }
    if (value.trim().isEmpty) {
      throw FormatException(
        'Field "$key" for flavor at index $index must not be empty.',
      );
    }
    return value;
  }

  String? _resolveOptionalPath(
    FlavorProjectContext context,
    String? rawPath,
    String fieldName,
    String flavorName,
  ) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }
    final resolved = context.resolvePath(rawPath);
    if (!File(resolved).existsSync()) {
      throw FormatException(
        'File for "$fieldName" not found at $resolved (flavor "$flavorName").',
      );
    }
    return resolved;
  }
}
