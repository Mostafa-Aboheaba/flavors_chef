import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/flavor_asset_bundle.dart';
import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Copies launcher icons and splash assets into the Flutter project.
class AssetsPipeline {
  AssetsPipeline({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<Map<String, FlavorAssetBundle>> process(
    List<FlavorDefinition> flavors,
  ) async {
    final result = <String, FlavorAssetBundle>{};
    for (final flavor in flavors) {
      final flavorDir = Directory(
        p.join(context.projectRoot.path, 'assets', 'flavors', flavor.name),
      );
      if (!flavorDir.existsSync()) {
        flavorDir.createSync(recursive: true);
      }

      String? iconAssetPath;
      if (flavor.iconSourcePath case final iconPath?) {
        final sourceFile = File(iconPath);
        if (!sourceFile.existsSync()) {
          throw StateError(
            'Launcher icon not found at $iconPath for flavor ${flavor.name}.',
          );
        }
        final iconExtension = p.extension(iconPath);
        final iconDestination = File(
          p.join(flavorDir.path, 'launcher$iconExtension'),
        );
        await sourceFile.copy(iconDestination.path);
        iconAssetPath = p.relative(
          iconDestination.path,
          from: context.projectRoot.path,
        );
      }

      String? splashAssetPath;
      if (flavor.splashImagePath case final splashPath?) {
        final sourceFile = File(splashPath);
        if (!sourceFile.existsSync()) {
          throw StateError(
            'Splash image not found at $splashPath for flavor ${flavor.name}.',
          );
        }
        final splashExtension = p.extension(splashPath);
        final splashDestination = File(
          p.join(flavorDir.path, 'splash$splashExtension'),
        );
        await sourceFile.copy(splashDestination.path);
        splashAssetPath = p.relative(
          splashDestination.path,
          from: context.projectRoot.path,
        );
      }

      if (iconAssetPath != null || splashAssetPath != null) {
        final copied = [
          if (iconAssetPath != null) 'icon',
          if (splashAssetPath != null) 'splash',
        ].join(' & ');
        stdout.writeln(
          '  • Copied $copied asset(s) for ${flavor.name} to '
          '${p.relative(flavorDir.path, from: context.projectRoot.path)}',
        );
      } else {
        stdout.writeln(
          '  • No custom assets provided for ${flavor.name}; keeping project defaults.',
        );
      }

      result[flavor.name] = FlavorAssetBundle(
        iconAssetPath: iconAssetPath,
        splashAssetPath: splashAssetPath,
      );
    }
    return result;
  }
}
