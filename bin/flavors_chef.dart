import 'dart:io';

import 'package:flavors_chef/src/cli/flavor_chef_cli.dart';

Future<void> main(List<String> arguments) async {
  final cli = FlavorChefCli(stdout: stdout, stderr: stderr, stdin: stdin);
  final exitCode = await cli.run(arguments);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
