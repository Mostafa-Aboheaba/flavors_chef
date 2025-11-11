import 'dart:io';

import 'package:args/args.dart';
import 'package:flavors_chef/src/cli/prompter.dart';
import 'package:flavors_chef/src/models/flavor_project_context.dart';
import 'package:flavors_chef/src/services/config_template_writer.dart';
import 'package:flavors_chef/src/services/project_inspector.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Directory where the template should be generated.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print usage information.',
    );

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    stderr.writeln('Usage: dart run flavors_chef:init [options]');
    stderr.writeln(parser.usage);
    exit(64);
  }

  if (results['help'] == true) {
    stdout.writeln('Usage: dart run flavors_chef:init [options]');
    stdout.writeln('');
    stdout.writeln(parser.usage);
    return;
  }

  final projectPath = results['project'] as String? ?? Directory.current.path;
  final projectRoot = Directory(projectPath);
  if (!projectRoot.existsSync()) {
    stderr.writeln('Project directory not found: ${projectRoot.path}');
    exit(64);
  }

  final inspector = ProjectInspector(projectRoot: projectRoot);
  final metadata = await inspector.inspect();

  final context = FlavorProjectContext(
    projectRoot: projectRoot,
    appName: metadata.displayName,
    androidApplicationId: metadata.androidApplicationId,
    iosBundleId: metadata.iosBundleIdentifier,
  );

  final configFile = File(context.resolvePath('flavors_chef.yaml'));
  if (configFile.existsSync()) {
    final prompter = ConsolePrompter(stdin: stdin, stdout: stdout);
    final overwrite = await prompter.askYesNo(
      question: 'flavors_chef.yaml already exists. Overwrite?',
      defaultValue: false,
    );
    if (!overwrite) {
      stdout.writeln('  • Kept existing flavors_chef.yaml');
      return;
    }
  }

  final writer = ConfigTemplateWriter(context: context, stdout: stdout);
  await writer.writeConfig();
}
