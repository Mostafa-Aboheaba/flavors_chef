import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../config/flavors_config_parser.dart';
import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';
import '../services/flavor_project_generator.dart';
import '../services/project_inspector.dart';
import '../utils/flavor_defaults.dart';
import '../utils/validation.dart';
import 'prompter.dart';

/// Entry point for the Flavors Chef interactive CLI.
class FlavorChefCli {
  FlavorChefCli({
    required this.stdout,
    required this.stderr,
    required this.stdin,
  });

  final Stdout stdout;
  final IOSink stderr;
  final Stdin stdin;

  Future<int> run(List<String> arguments) async {
    try {
      final results = _buildArgParser().parse(arguments);
      if (results.wasParsed('help')) {
        _printUsage();
        return 0;
      }

      final projectPath =
          results['project'] as String? ?? Directory.current.path;
      final projectRoot = Directory(projectPath);
      if (!projectRoot.existsSync()) {
        stderr.writeln('Project directory not found: ${projectRoot.path}');
        return 64;
      }

      final inspector = ProjectInspector(projectRoot: projectRoot);
      final metadata = await inspector.inspect();

      final configPath = results['config'] as String?;
      final usingConfig = configPath != null;

      FlavorProjectContext context;
      late List<FlavorDefinition> flavors;
      ConsolePrompter? prompter;

      if (configPath case final String path) {
        final resolvedConfigPath = p.isAbsolute(path)
            ? path
            : p.normalize(p.join(projectRoot.path, path));
        final configFile = File(resolvedConfigPath);
        if (!configFile.existsSync()) {
          stderr.writeln('Config file not found: ${configFile.path}');
          return 66;
        }

        final parser = FlavorConfigParser(
          projectRoot: projectRoot,
          metadata: metadata,
        );
        final parsed = parser.parse(configFile);
        context = parsed.context;
        flavors = parsed.flavors;

        stdout.writeln(
          'Loaded ${flavors.length} flavor(s) from ${configFile.path}.',
        );
      } else {
        final interactivePrompter = ConsolePrompter(
          stdin: stdin,
          stdout: stdout,
        );
        prompter = interactivePrompter;

        stdout.writeln('🍽️  Welcome to Flavors Chef!');
        stdout.writeln(
          'We will guide you through configuring flavors for your Flutter app.',
        );
        stdout.writeln('');

        final appName = await interactivePrompter.askString(
          question: 'Base application display name',
          defaultValue: metadata.displayName,
        );

        final androidId = await interactivePrompter.askString(
          question: 'Base Android applicationId',
          defaultValue: metadata.androidApplicationId,
          validationMessage:
              'Application id must contain only letters, digits, and dots.',
          validate: (value) =>
              RegExp(r'^[a-zA-Z][a-zA-Z0-9_.]*$').hasMatch(value),
        );

        final iosId = await interactivePrompter.askString(
          question: 'Base iOS bundle identifier',
          defaultValue: metadata.iosBundleIdentifier,
          validationMessage:
              'Bundle identifiers should use reverse-domain notation.',
          validate: (value) =>
              RegExp(r'^[a-zA-Z][a-zA-Z0-9\.-]*$').hasMatch(value),
        );

        context = FlavorProjectContext(
          projectRoot: projectRoot,
          appName: appName,
          androidApplicationId: androidId,
          iosBundleId: iosId,
        );

        flavors = <FlavorDefinition>[];
        stdout.writeln('');
        stdout.writeln('Let us add your flavors.');

        do {
          final flavor = await _collectFlavorDefinition(
            prompter: interactivePrompter,
            context: context,
            suggestionIndex: flavors.length,
          );
          flavors.add(flavor);

          stdout.writeln('');
        } while (await interactivePrompter.askYesNo(
          question: 'Add another flavor?',
          defaultValue: flavors.length < 3,
        ));
      }

      stdout.writeln('');
      _printSummary(context: context, flavors: flavors);
      stdout.writeln('');

      if (!usingConfig) {
        final confirmed = await prompter!.askYesNo(
          question: 'Proceed with generation?',
          defaultValue: true,
        );
        if (!confirmed) {
          stdout.writeln('No changes were made. Goodbye!');
          return 0;
        }
      }

      stdout.writeln('');
      stdout.writeln('Cooking your flavors...');
      stdout.writeln('');

      final generator = FlavorProjectGenerator(
        context: context,
        flavors: flavors,
        stdout: stdout,
      );
      await generator.generate();

      stdout.writeln('');
      stdout.writeln('✅ Flavors Chef finished without errors.');
      stdout.writeln('');
      return 0;
    } on FormatException catch (error) {
      stderr.writeln(error.message);
      return 64;
    } on StateError catch (error) {
      stderr.writeln(error.message);
      return 70;
    } catch (error, stackTrace) {
      stderr.writeln('Unexpected error: $error');
      stderr.writeln(stackTrace);
      return 1;
    }
  }

  ArgParser _buildArgParser() {
    return ArgParser()
      ..addOption(
        'project',
        abbr: 'p',
        help: 'Path to the Flutter project that should be flavorized.',
      )
      ..addOption(
        'config',
        help: 'Path to a YAML configuration file for non-interactive runs.',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print usage information.',
      );
  }

  Future<FlavorDefinition> _collectFlavorDefinition({
    required ConsolePrompter prompter,
    required FlavorProjectContext context,
    required int suggestionIndex,
  }) async {
    stdout.writeln(
      '--- Flavor #${suggestionIndex + 1} ----------------------------------',
    );

    final defaultName = switch (suggestionIndex) {
      0 => 'development',
      1 => 'staging',
      2 => 'production',
      _ => 'flavor_${suggestionIndex + 1}',
    };
    final rawName = await prompter.askString(
      question: 'Flavor key (e.g. development)',
      defaultValue: defaultName,
      validationMessage:
          'Use lowercase letters, numbers, and underscores. Must start '
          'with a letter.',
      validate: isValidFlavorName,
    );
    final flavorName = sanitizeFlavorName(rawName);

    final appName = await prompter.askString(
      question: 'Display name for $flavorName',
      defaultValue: defaultFlavorDisplayName(
        baseAppName: context.appName,
        flavorName: flavorName,
      ),
    );

    final androidId = await prompter.askString(
      question: 'Android applicationId for $flavorName',
      defaultValue: defaultAndroidApplicationId(
        base: context.androidApplicationId,
        flavorName: flavorName,
      ),
      validationMessage:
          'Application id must contain only letters, digits, underscores, '
          'and dots. It must start with a letter.',
      validate: (value) => RegExp(r'^[a-zA-Z][a-zA-Z0-9_\.]*$').hasMatch(value),
    );

    final iosId = await prompter.askString(
      question: 'iOS bundle identifier for $flavorName',
      defaultValue: defaultIosBundleId(
        base: context.iosBundleId,
        flavorName: flavorName,
      ),
      validationMessage:
          'Bundle identifiers should use reverse-domain notation.',
      validate: (value) => RegExp(r'^[a-zA-Z][a-zA-Z0-9\.-]*$').hasMatch(value),
    );

    final colorHex = await prompter.askString(
      question: 'Primary color hex (format #RRGGBB)',
      defaultValue: '#6750A4',
      validationMessage:
          'Enter a 6 or 8 digit hex color starting with #, e.g. #6750A4.',
      validate: isValidHexColor,
    );

    final iconPath = await _askForExistingFile(
      prompter: prompter,
      question:
          'Absolute or relative path to the launcher icon image for '
          '$flavorName',
      context: context,
      hint:
          'Recommend a 1024x1024 transparent PNG. Press enter to keep the '
          'project default.',
      allowSkip: true,
    );

    final splashPath = await _askForExistingFile(
      prompter: prompter,
      question: 'Absolute or relative path to the splash image for $flavorName',
      context: context,
      hint:
          'Recommend a vector or 4x asset with transparent background. Press '
          'enter to keep the project default.',
      allowSkip: true,
    );

    final envValues = await _collectEnvironmentValues(prompter: prompter);

    final androidSuffix = await prompter.askString(
      question: 'Optional Android applicationId suffix (press enter to skip)',
      defaultValue: '',
    );

    final versionSuffix = await prompter.askString(
      question: 'Optional Android versionName suffix',
      defaultValue: suggestionIndex == 0 ? '-dev' : '',
    );

    return FlavorDefinition(
      name: flavorName,
      appName: appName,
      androidApplicationId: androidId,
      androidApplicationIdSuffix: androidSuffix.isEmpty ? null : androidSuffix,
      iosBundleId: iosId,
      versionNameSuffix: versionSuffix.isEmpty ? null : versionSuffix,
      primaryColorHex: colorHex,
      iconSourcePath: iconPath,
      splashImagePath: splashPath,
      environmentValues: envValues,
      launcherIconConfig: const {},
      nativeSplashConfig: const {},
    );
  }

  Future<Map<String, String>> _collectEnvironmentValues({
    required ConsolePrompter prompter,
  }) async {
    final values = <String, String>{};
    while (await prompter.askYesNo(
      question: 'Add a key-value environment variable?',
      defaultValue: values.isEmpty,
    )) {
      final key = await prompter.askString(
        question: 'Environment key (e.g. API_BASE_URL)',
        hint: 'Use uppercase letters, numbers, and underscores.',
        validationMessage:
            'Keys should contain only uppercase letters, numbers, and '
            'underscores.',
        validate: (value) => RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(value),
      );
      final value = await prompter.askString(question: 'Value for $key');
      values[key] = value;
    }
    return Map.unmodifiable(values);
  }

  Future<String?> _askForExistingFile({
    required ConsolePrompter prompter,
    required FlavorProjectContext context,
    required String question,
    String? hint,
    bool allowSkip = false,
  }) async {
    while (true) {
      final path = await prompter.askString(question: question, hint: hint);
      if (allowSkip && path.trim().isEmpty) {
        return null;
      }
      final resolved = context.resolvePath(path);
      final file = File(resolved);
      if (file.existsSync()) {
        return file.path;
      }
      stdout.writeln('File not found at $resolved. Please try again.');
    }
  }

  void _printSummary({
    required FlavorProjectContext context,
    required List<FlavorDefinition> flavors,
  }) {
    stdout.writeln('Summary:');
    stdout.writeln('Project: ${context.projectRoot.path}');
    stdout.writeln('Base Android id: ${context.androidApplicationId}');
    stdout.writeln('Base iOS id: ${context.iosBundleId}');
    stdout.writeln('');
    for (final flavor in flavors) {
      stdout.writeln('• ${flavor.name}');
      stdout.writeln('  App name: ${flavor.appName}');
      stdout.writeln(
        '  Android id: ${flavor.androidApplicationId}'
        '${flavor.androidApplicationIdSuffix ?? ''}',
      );
      stdout.writeln('  iOS id: ${flavor.iosBundleId}');
      stdout.writeln(
        '  Icon source: ${flavor.iconSourcePath ?? 'default project icon'}',
      );
      stdout.writeln(
        '  Splash image: ${flavor.splashImagePath ?? 'default splash asset'}',
      );
      stdout.writeln('  Color: ${flavor.primaryColorHex}');
      if (flavor.environmentValues.isNotEmpty) {
        stdout.writeln('  Environment:');
        for (final entry in flavor.environmentValues.entries) {
          stdout.writeln('    ${entry.key}=${entry.value}');
        }
      }
      stdout.writeln('');
    }
  }

  void _printUsage() {
    stdout.writeln('Usage: flavors_chef [options]');
    stdout.writeln('');
    stdout.writeln('Options:');
    stdout.writeln('  -p, --project   Path to the Flutter project.');
    stdout.writeln('  -h, --help      Display this help message.');
    stdout.writeln(
      '      --config    Path to a YAML flavor configuration file.',
    );
  }
}
