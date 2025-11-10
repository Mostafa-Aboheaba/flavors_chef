import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Generates baseline iOS flavor scaffolding.
class IosConfigurator {
  IosConfigurator({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<void> apply(List<FlavorDefinition> flavors) async {
    final iosDir = Directory(p.join(context.projectRoot.path, 'ios'));
    if (!iosDir.existsSync()) {
      stdout.writeln(
        '  • Skipping iOS configuration (ios directory not found)',
      );
      return;
    }

    await _writeFlavorPlists(flavors);
    stdout.writeln(
      '  • Generated iOS flavor Info.plist overlays (manual Xcode setup '
      'still required)',
    );
  }

  Future<void> _writeFlavorPlists(List<FlavorDefinition> flavors) async {
    final flavorDir = Directory(
      p.join(context.projectRoot.path, 'ios', 'FlavorChef'),
    );
    if (!flavorDir.existsSync()) {
      flavorDir.createSync(recursive: true);
    }

    for (final flavor in flavors) {
      final file = File(p.join(flavorDir.path, '${flavor.name}.plist'));
      await file.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PRODUCT_BUNDLE_IDENTIFIER</key>
  <string>${flavor.iosBundleId}</string>
  <key>PRODUCT_NAME</key>
  <string>${flavor.appName}</string>
</dict>
</plist>
''');
    }
  }
}
