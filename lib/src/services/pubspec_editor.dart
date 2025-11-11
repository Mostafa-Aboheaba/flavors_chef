import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../models/flavor_asset_bundle.dart';
import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Applies pubspec.yaml updates required for flavor assets and tooling.
class PubspecEditor {
  PubspecEditor({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<void> apply({
    required List<FlavorDefinition> flavors,
    required Map<String, FlavorAssetBundle> assets,
  }) async {
    final file = File(context.resolvePath('pubspec.yaml'));
    if (!file.existsSync()) {
      throw StateError('pubspec.yaml not found in ${context.projectRoot.path}');
    }
    final document = await file.readAsString();
    final editor = YamlEditor(document);
    var yaml = loadYaml(document) as YamlMap? ?? YamlMap();

    final hasIconAssets = flavors.any(
      (flavor) => assets[flavor.name]?.hasIcon ?? false,
    );
    final hasSplashAssets = flavors.any(
      (flavor) => assets[flavor.name]?.hasSplash ?? false,
    );
    final hasNativeSplashConfig = flavors.any(
      (flavor) => flavor.nativeSplashConfig.isNotEmpty,
    );

    final assetPaths =
        assets.values
            .expand((bundle) => [bundle.iconAssetPath, bundle.splashAssetPath])
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();

    if (assetPaths.isNotEmpty) {
      _ensureAssets(editor: editor, root: yaml, assets: assetPaths);
      yaml = loadYaml(editor.toString()) as YamlMap? ?? YamlMap();
    }

    if (hasIconAssets) {
      _ensureDevDependency(
        editor: editor,
        root: yaml,
        package: 'flutter_launcher_icons',
        version: '^0.13.1',
      );
      yaml = loadYaml(editor.toString()) as YamlMap? ?? YamlMap();
    }

    if (hasSplashAssets || hasNativeSplashConfig) {
      _ensureDevDependency(
        editor: editor,
        root: yaml,
        package: 'flutter_native_splash',
        version: '^2.4.0',
      );
      yaml = loadYaml(editor.toString()) as YamlMap? ?? YamlMap();
    }

    _removeSplashConfig(editor);
    yaml = loadYaml(editor.toString()) as YamlMap? ?? YamlMap();

    final updated = editor.toString();
    await file.writeAsString('$updated\n');
    stdout.writeln('  • Updated pubspec.yaml');
  }

  void _ensureDevDependency({
    required YamlEditor editor,
    required YamlMap root,
    required String package,
    required String version,
  }) {
    final devDepsPath = ['dev_dependencies'];
    final devDeps = root.nodes[devDepsPath.first] as YamlMap?;
    if (devDeps == null) {
      editor.update(devDepsPath, <String, Object?>{package: version});
      return;
    }

    if (!devDeps.value.keys.contains(package)) {
      final map = Map<String, Object?>.from(devDeps.value);
      map[package] = version;
      editor.update(devDepsPath, map);
      return;
    }
  }

  void _ensureAssets({
    required YamlEditor editor,
    required YamlMap root,
    required List<String> assets,
  }) {
    if (assets.isEmpty) {
      return;
    }

    final flutterPath = ['flutter'];
    final flutterNode = root.nodes['flutter'] as YamlMap?;
    if (flutterNode == null) {
      editor.update(flutterPath, <String, Object?>{'assets': assets});
      return;
    }

    final assetsPath = ['flutter', 'assets'];
    final existingAssets = flutterNode.nodes['assets'] as YamlList?;
    if (existingAssets == null) {
      editor.update(assetsPath, assets);
      return;
    }

    final set = {for (final entry in existingAssets.value) entry.toString()}
      ..addAll(assets);

    editor.update(assetsPath, set.toList()..sort());
  }

  void _removeSplashConfig(YamlEditor editor) {
    try {
      editor.remove(['flutter_native_splash']);
    } catch (_) {
      // Ignore if the key does not exist; nothing to remove.
    }
  }
}
