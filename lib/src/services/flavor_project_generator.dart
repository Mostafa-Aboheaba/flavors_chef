import 'dart:io';

import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';
import 'android_configurator.dart';
import 'assets_pipeline.dart';
import 'dart_generator.dart';
import 'ios_configurator.dart';
import 'launcher_icon_runner.dart';
import 'native_splash_runner.dart';
import 'pubspec_editor.dart';

/// Coordinates all generation steps required to flavorize a project.
class FlavorProjectGenerator {
  FlavorProjectGenerator({
    required this.context,
    required this.flavors,
    required this.stdout,
  });

  final FlavorProjectContext context;
  final List<FlavorDefinition> flavors;
  final Stdout stdout;

  Future<void> generate() async {
    if (flavors.isEmpty) {
      throw StateError('At least one flavor must be provided.');
    }

    stdout.writeln('Step 1/7 • Preparing assets');
    final assets = await AssetsPipeline(
      context: context,
      stdout: stdout,
    ).process(flavors);

    stdout.writeln('Step 2/7 • Updating pubspec.yaml');
    await PubspecEditor(
      context: context,
      stdout: stdout,
    ).apply(flavors: flavors, assets: assets);

    stdout.writeln('Step 3/7 • Generating launcher icons');
    await LauncherIconRunner(
      context: context,
      stdout: stdout,
    ).run(flavors: flavors, assets: assets);

    stdout.writeln('Step 4/7 • Generating native splash screens');
    await NativeSplashRunner(
      context: context,
      stdout: stdout,
    ).run(flavors: flavors, assets: assets);

    stdout.writeln('Step 5/7 • Configuring Android');
    await AndroidConfigurator(context: context, stdout: stdout).apply(flavors);

    stdout.writeln('Step 6/7 • Configuring iOS');
    await IosConfigurator(context: context, stdout: stdout).apply(flavors);

    stdout.writeln('Step 7/7 • Generating Dart bootstrap files');
    await DartGenerator(context: context, stdout: stdout).generate(flavors);
  }
}
