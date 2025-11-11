import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:flavors_chef/src/config/flavors_config_parser.dart';
import 'package:flavors_chef/src/services/project_inspector.dart';

void main() {
  group('FlavorConfigParser', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flavor_chef_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('parses configuration into context and flavors', () {
      final assetsDir = Directory(p.join(tempDir.path, 'assets'));
      assetsDir.createSync(recursive: true);

      final icon = File(p.join(assetsDir.path, 'dev_icon.png'));
      final splash = File(p.join(assetsDir.path, 'dev_splash.png'));
      icon.writeAsBytesSync([0, 1, 2]);
      splash.writeAsBytesSync([0, 1, 2]);

      final metadata = ProjectMetadata(
        projectRoot: tempDir,
        pubspecName: 'example',
        displayName: 'Example App',
        androidApplicationId: 'com.example.app',
        iosBundleIdentifier: 'com.example.app',
      );

      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
project:
  app_name: Example Override
  android_application_id: com.example.base
  ios_bundle_id: com.example.base
flavors:
  - name: development
    app_name: Example Dev
    android_application_id: com.example.dev
    ios_bundle_id: com.example.dev
    primary_color_hex: '#112233'
    icon_source_path: assets/dev_icon.png
    splash_image_path: assets/dev_splash.png
    launcher_icons:
      android: true
      adaptive_icon_foreground: assets/dev_icon_fg.png
    native_splash:
      color: '#123456'
      android_12:
        image: assets/dev_splash_android12.png
    version_name_suffix: '-dev'
    environment:
      API_URL: https://dev.example.com
''');

      final parser = FlavorConfigParser(
        projectRoot: tempDir,
        metadata: metadata,
      );
      final parsed = parser.parse(configFile);

      expect(parsed.context.appName, 'Example Override');
      expect(parsed.context.androidApplicationId, 'com.example.base');
      expect(parsed.flavors, hasLength(1));

      final flavor = parsed.flavors.first;
      expect(flavor.name, 'development');
      expect(flavor.appName, 'Example Dev');
      expect(flavor.androidApplicationId, 'com.example.dev');
      expect(flavor.versionNameSuffix, '-dev');
      expect(flavor.primaryColorHex, '#112233');
      expect(
        flavor.iconSourcePath,
        p.join(tempDir.path, 'assets', 'dev_icon.png'),
      );
      expect(flavor.environmentValues['API_URL'], 'https://dev.example.com');
      expect(flavor.launcherIconConfig, containsPair('android', true));
      expect(
        flavor.launcherIconConfig['adaptive_icon_foreground'],
        'assets/dev_icon_fg.png',
      );
      expect(flavor.nativeSplashConfig, containsPair('color', '#123456'));
      expect(
        (flavor.nativeSplashConfig['android_12'] as Map)['image'],
        'assets/dev_splash_android12.png',
      );
    });

    test('throws when flavors list is missing', () {
      final configFile = File(p.join(tempDir.path, 'invalid.yaml'))
        ..writeAsStringSync('project: {}');

      final metadata = ProjectMetadata(
        projectRoot: tempDir,
        pubspecName: 'example',
        displayName: 'Example App',
        androidApplicationId: 'com.example.app',
        iosBundleIdentifier: 'com.example.app',
      );

      final parser = FlavorConfigParser(
        projectRoot: tempDir,
        metadata: metadata,
      );

      expect(() => parser.parse(configFile), throwsFormatException);
    });
  });
}
