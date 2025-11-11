import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/flavor_asset_bundle.dart';
import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Runs flutter_native_splash to generate flavor-specific splash screens.
class NativeSplashRunner {
  NativeSplashRunner({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<void> run({
    required List<FlavorDefinition> flavors,
    required Map<String, FlavorAssetBundle> assets,
  }) async {
    final shouldGenerate = flavors.any(
      (flavor) =>
          (assets[flavor.name]?.hasSplash ?? false) ||
          flavor.nativeSplashConfig.isNotEmpty,
    );
    if (!shouldGenerate) {
      stdout.writeln(
        '  • No splash configuration provided; skipping flutter_native_splash.',
      );
      return;
    }

    stdout.writeln(
      '  • Generating native splash screens with flutter_native_splash',
    );

    for (final flavor in flavors) {
      final bundle = assets[flavor.name];
      final hasSplashAsset = bundle?.hasSplash ?? false;
      if (!hasSplashAsset && flavor.nativeSplashConfig.isEmpty) {
        continue;
      }

      final configFile = await _writeFlavorConfig(
        flavor: flavor,
        bundle: bundle,
      );
      stdout.writeln('    • ${flavor.name}: ${configFile.path}');

      final process = await Process.start(
        'flutter',
        [
          'pub',
          'run',
          'flutter_native_splash:create',
          '--path',
          configFile.path,
        ],
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
          'flutter_native_splash failed for flavor ${flavor.name} with '
          'exit code $exitCode.\n${stdoutBuffer.toString()}'
          '${stderrBuffer.toString()}',
        );
      }
    }

    stdout.writeln(
      '  • Generated native splash screens for all configured flavors.',
    );
  }

  Future<File> _writeFlavorConfig({
    required FlavorDefinition flavor,
    required FlavorAssetBundle? bundle,
  }) async {
    final configFile = File(
      p.join(
        context.projectRoot.path,
        'flutter_native_splash-${flavor.name}.yaml',
      ),
    );

    final config =
        _clone(flavor.nativeSplashConfig) as Map<String, Object?>? ??
        <String, Object?>{};

    config.putIfAbsent('android', () => true);
    config.putIfAbsent('ios', () => true);
    config.putIfAbsent('flavor', () => flavor.name);
    config.putIfAbsent('color', () => flavor.primaryColorHex);

    final splashPath = bundle?.splashAssetPath;
    if (splashPath != null) {
      final normalizedPath = p
          .normalize(p.relative(splashPath, from: context.projectRoot.path))
          .replaceAll(r'\', '/');

      if (!config.containsKey('image')) {
        config['image'] = normalizedPath;
      }

      config.update(
        'android_12',
        (value) =>
            _ensureAndroid12Config(value, normalizedPath, config['color']),
        ifAbsent: () =>
            _ensureAndroid12Config(null, normalizedPath, config['color']),
      );
    }

    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert({'flutter_native_splash': config});
    await configFile.writeAsString('$encoded\n');
    return configFile;
  }

  Object? _clone(Object? value) {
    if (value is Map) {
      final map = <String, Object?>{};
      value.forEach((key, entry) {
        map[key.toString()] = _clone(entry);
      });
      return map;
    }
    if (value is Iterable) {
      return value.map(_clone).toList();
    }
    return value;
  }

  Map<String, Object?> _ensureAndroid12Config(
    Object? existing,
    String imagePath,
    Object? color,
  ) {
    final map = <String, Object?>{};
    if (existing is Map) {
      existing.forEach((key, value) {
        map[key.toString()] = value;
      });
    }
    map.putIfAbsent('image', () => imagePath);
    if (color != null) {
      map.putIfAbsent('color', () => color);
      map.putIfAbsent('icon_background_color', () => color);
    }
    return map;
  }
}
