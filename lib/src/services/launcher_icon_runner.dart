import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/flavor_asset_bundle.dart';
import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Runs flutter_launcher_icons to generate platform launcher icons.
class LauncherIconRunner {
  LauncherIconRunner({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<void> run({
    required List<FlavorDefinition> flavors,
    required Map<String, FlavorAssetBundle> assets,
  }) async {
    final hasLauncherIcons = assets.values.any((bundle) => bundle.hasIcon);
    if (!hasLauncherIcons) {
      stdout.writeln(
        '  • No custom launcher icons configured; skipping generation.',
      );
      return;
    }

    stdout.writeln('  • Generating launcher icons with flutter_launcher_icons');

    for (final flavor in flavors) {
      final bundle = assets[flavor.name];
      final iconPath = bundle?.iconAssetPath;
      if (iconPath == null) {
        continue;
      }

      final configFile = await _writeFlavorConfig(
        flavorName: flavor.name,
        iconPath: iconPath,
        overrides: flavor.launcherIconConfig,
      );
      stdout.writeln('    • ${flavor.name}: ${configFile.path}');

      final process = await Process.start(
        'flutter',
        ['pub', 'run', 'flutter_launcher_icons:main', '-f', configFile.path],
        workingDirectory: context.projectRoot.path,
        runInShell: true,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      final stdoutSubscription = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.trim().isEmpty) {
              return;
            }
            stdoutBuffer.writeln(line);
            stdout.writeln('      $line');
          });
      final stderrSubscription = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.trim().isEmpty) {
              return;
            }
            stderrBuffer.writeln(line);
            stdout.writeln('      $line');
          });

      final exitCode = await process.exitCode;
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
      if (exitCode != 0) {
        throw StateError(
          'flutter_launcher_icons failed for flavor ${flavor.name} with '
          'exit code $exitCode.\n${stdoutBuffer.toString()}${stderrBuffer.toString()}',
        );
      }
    }

    stdout.writeln('  • Generated launcher icons for all configured flavors.');
  }

  Future<File> _writeFlavorConfig({
    required String flavorName,
    required String iconPath,
    required Map<String, Object?> overrides,
  }) async {
    final configFile = File(
      p.join(
        context.projectRoot.path,
        'flutter_launcher_icons-$flavorName.yaml',
      ),
    );
    final relativePath = p.normalize(
      p.relative(iconPath, from: context.projectRoot.path),
    );
    final config = Map<String, Object?>.from(overrides);
    final normalizedPath = relativePath.replaceAll(r'\', '/');
    final hasImagePath =
        config.containsKey('image_path') ||
        config.containsKey('image_path_android') ||
        config.containsKey('image_path_ios');
    if (!hasImagePath) {
      config['image_path'] = normalizedPath;
    }
    config.putIfAbsent('android', () => true);
    config.putIfAbsent('ios', () => true);
    config.putIfAbsent('remove_alpha_ios', () => true);
    config.putIfAbsent('flavor', () => flavorName);

    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert({'flutter_launcher_icons': config});
    await configFile.writeAsString('$encoded\n');
    return configFile;
  }
}
