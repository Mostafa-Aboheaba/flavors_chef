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

    test('throws when config file is empty', () {
      final configFile = File(p.join(tempDir.path, 'empty.yaml'))
        ..writeAsStringSync('');

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

    test('throws when root is not a map', () {
      final configFile = File(p.join(tempDir.path, 'invalid.yaml'))
        ..writeAsStringSync('- item1\n- item2');

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

    test('uses metadata defaults when project section is missing', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
''');

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

      final parsed = parser.parse(configFile);

      expect(parsed.context.appName, 'Example App');
      expect(parsed.context.androidApplicationId, 'com.example.app');
      expect(parsed.context.iosBundleId, 'com.example.app');
    });

    test('throws when flavor name is invalid', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: 123invalid
''');

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

    test('throws when primary_color_hex is invalid', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    primary_color_hex: 'invalid'
''');

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

    test('throws when icon file does not exist', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    icon_source_path: assets/nonexistent.png
''');

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

    test('throws when flavors list is empty', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors: []
''');

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

    test('throws when flavor entry is not a map', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - not a map
''');

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

    test('throws when flavor name is missing', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - app_name: Dev App
''');

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

    test('throws when flavor name is empty', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: ''
''');

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

    test('throws when environment is not a map', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    environment: not a map
''');

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

    test('throws when launcher_icons is not a map', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    launcher_icons: not a map
''');

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

    test('throws when native_splash is not a map', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    native_splash: not a map
''');

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

    test('handles native_splash_config alias', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    native_splash_config:
      color: '#123456'
''');

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

      final parsed = parser.parse(configFile);
      expect(parsed.flavors.first.nativeSplashConfig['color'], '#123456');
    });

    test('parses multiple flavors', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
  - name: staging
  - name: prod
''');

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

      final parsed = parser.parse(configFile);
      expect(parsed.flavors, hasLength(3));
      expect(parsed.flavors[0].name, 'dev');
      expect(parsed.flavors[1].name, 'staging');
      expect(parsed.flavors[2].name, 'prod');
    });

    test('uses default values for flavor fields', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
project:
  app_name: Base App
  android_application_id: com.base.app
  ios_bundle_id: com.base.app
flavors:
  - name: dev
''');

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

      final parsed = parser.parse(configFile);
      final flavor = parsed.flavors.first;

      expect(flavor.appName, 'Base App Dev');
      expect(flavor.androidApplicationId, 'com.base.app.dev');
      expect(flavor.iosBundleId, 'com.base.app.dev');
      expect(flavor.primaryColorHex, '#6750A4');
    });

    test('handles empty environment map', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    environment: {}
''');

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

      final parsed = parser.parse(configFile);
      expect(parsed.flavors.first.environmentValues, isEmpty);
    });

    test('handles null environment values', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    environment:
      KEY1: value1
      KEY2: null
      KEY3: ''
''');

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

      final parsed = parser.parse(configFile);
      expect(parsed.flavors.first.environmentValues['KEY1'], 'value1');
      expect(parsed.flavors.first.environmentValues['KEY2'], '');
      expect(parsed.flavors.first.environmentValues['KEY3'], '');
    });

    test('handles android_application_id_suffix when provided', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    android_application_id_suffix: '.dev'
''');

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

      final parsed = parser.parse(configFile);
      expect(parsed.flavors.first.androidApplicationIdSuffix, '.dev');
    });

    test('handles empty android_application_id_suffix', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    android_application_id_suffix: ''
''');

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

      final parsed = parser.parse(configFile);
      expect(parsed.flavors.first.androidApplicationIdSuffix, isNull);
    });

    test('handles nested lists in launcher_icons config', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: dev
    launcher_icons:
      android: true
      adaptive_icon_background: '#123456'
      adaptive_icon_foreground: assets/icon.png
      custom_icons:
        - icon1.png
        - icon2.png
''');

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

      final parsed = parser.parse(configFile);
      final launcherConfig = parsed.flavors.first.launcherIconConfig;
      expect(launcherConfig['android'], isTrue);
      expect(launcherConfig['custom_icons'], isA<List>());
      final icons = launcherConfig['custom_icons'] as List;
      expect(icons.length, 2);
    });

    test('throws when project section is not a map', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
project: not a map
flavors:
  - name: dev
''');

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

    test('throws when flavor name is not a string', () {
      final configFile = File(p.join(tempDir.path, 'flavors.yaml'))
        ..writeAsStringSync('''
flavors:
  - name: 123
''');

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
