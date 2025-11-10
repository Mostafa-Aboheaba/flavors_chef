import 'dart:io';

import 'package:flavor_chef/flavor_chef.dart';

Future<void> main(List<String> arguments) async {
  final cli = FlavorChefCli(stdout: stdout, stderr: stderr, stdin: stdin);
  final exitCode = await cli.run(arguments);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
