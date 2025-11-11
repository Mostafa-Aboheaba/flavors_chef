import 'dart:io';

import 'package:flavors_chef/flavors_chef.dart';

Future<void> main(List<String> arguments) async {
  final cli = FlavorChefCli(stdout: stdout, stderr: stderr, stdin: stdin);

  final hasProjectArg = arguments.any(
    (arg) =>
        arg == '--project' ||
        arg == '-p' ||
        arg.startsWith('--project=') ||
        arg.startsWith('-p'),
  );
  final hasConfigArg = arguments.any(
    (arg) => arg == '--config' || arg.startsWith('--config='),
  );

  final effectiveArgs = <String>[
    if (!hasProjectArg) ...['--project', '.'],
    if (!hasConfigArg) ...['--config', 'flavors_chef.yaml'],
    ...arguments,
  ];

  final exitCode = await cli.run(effectiveArgs);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
