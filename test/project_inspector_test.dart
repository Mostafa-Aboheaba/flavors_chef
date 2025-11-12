import 'dart:io';

import 'package:flavors_chef/src/services/project_inspector.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ProjectInspector', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_inspector_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws when pubspec.yaml is missing', () async {
      final inspector = ProjectInspector(projectRoot: tempDir);

      expect(
        () => inspector.inspect(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('No pubspec.yaml'),
        )),
      );
    });

    test('extracts metadata from pubspec.yaml', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: test_app
description: Test Application
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.pubspecName, 'test_app');
      expect(metadata.displayName, 'Test Application');
      expect(metadata.androidApplicationId, 'com.example.test_app');
      expect(metadata.iosBundleIdentifier, 'com.example.test_app');
    });

    test('uses app as default name when name is missing', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('description: Test App');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.pubspecName, 'app');
    });

    test('uses name as display name when description is missing', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.displayName, 'Test App');
    });

    test('converts description to title case', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: test_app
description: my test application
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.displayName, 'My Test Application');
    });

    test('handles underscores in description', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: test_app
description: my_test_application
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.displayName, 'My Test Application');
    });

    test('handles hyphens in description', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: test_app
description: my-test-application
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.displayName, 'My Test Application');
    });

    test('reads Android application ID from AndroidManifest.xml', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final manifestDir = Directory(
        p.join(tempDir.path, 'android', 'app', 'src', 'main'),
      );
      manifestDir.createSync(recursive: true);
      final manifestFile = File(
        p.join(manifestDir.path, 'AndroidManifest.xml'),
      );
      manifestFile.writeAsStringSync('''
<manifest package="com.custom.app">
</manifest>
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.androidApplicationId, 'com.custom.app');
    });


    test('falls back to default when Android files are missing', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      // Should use default format when Android files don't exist
      expect(metadata.androidApplicationId, 'com.example.test_app');
    });

    test('reads Android application ID from build.gradle.kts', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final gradleDir = Directory(p.join(tempDir.path, 'android', 'app'));
      gradleDir.createSync(recursive: true);
      final gradleFile = File(p.join(gradleDir.path, 'build.gradle.kts'));
      gradleFile.writeAsStringSync('''
android {
    defaultConfig {
        applicationId = "com.gradle.app"
    }
}
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      // Should fall back to default since build.gradle doesn't exist
      expect(metadata.androidApplicationId, 'com.example.test_app');
    });

    test('prefers AndroidManifest over build.gradle', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final manifestDir = Directory(
        p.join(tempDir.path, 'android', 'app', 'src', 'main'),
      );
      manifestDir.createSync(recursive: true);
      final manifestFile = File(
        p.join(manifestDir.path, 'AndroidManifest.xml'),
      );
      manifestFile.writeAsStringSync('''
<manifest package="com.manifest.app">
</manifest>
''');

      final gradleDir = Directory(p.join(tempDir.path, 'android', 'app'));
      final gradleFile = File(p.join(gradleDir.path, 'build.gradle'));
      gradleFile.writeAsStringSync('''
android {
    defaultConfig {
        applicationId "com.gradle.app"
    }
}
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.androidApplicationId, 'com.manifest.app');
    });

    test('reads iOS bundle identifier from Info.plist', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final runnerDir = Directory(p.join(tempDir.path, 'ios', 'Runner'));
      runnerDir.createSync(recursive: true);
      final plistFile = File(p.join(runnerDir.path, 'Info.plist'));
      plistFile.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<plist>
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.ios.app</string>
</dict>
</plist>
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.iosBundleIdentifier, 'com.ios.app');
    });

    test('falls back to default when iOS files are missing', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      // Should use default format when iOS files don't exist
      expect(metadata.iosBundleIdentifier, 'com.example.test_app');
    });

    test('ignores placeholder bundle identifier in Info.plist', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('name: test_app');

      final runnerDir = Directory(p.join(tempDir.path, 'ios', 'Runner'));
      runnerDir.createSync(recursive: true);
      final plistFile = File(p.join(runnerDir.path, 'Info.plist'));
      plistFile.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<plist>
<dict>
    <key>CFBundleIdentifier</key>
    <string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</dict>
</plist>
''');

      final pbxDir = Directory(
        p.join(tempDir.path, 'ios', 'Runner.xcodeproj'),
      );
      pbxDir.createSync(recursive: true);
      final pbxFile = File(p.join(pbxDir.path, 'project.pbxproj'));
      pbxFile.writeAsStringSync('''
PRODUCT_BUNDLE_IDENTIFIER = com.pbx.app;
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.iosBundleIdentifier, 'com.pbx.app');
    });

    test('handles empty pubspec.yaml', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.pubspecName, 'app');
      expect(metadata.displayName, 'App');
    });

    test('normalizes project root to absolute path', () {
      final relativeDir = Directory('relative');
      final inspector = ProjectInspector(projectRoot: relativeDir);

      expect(
        p.isAbsolute(inspector.projectRoot.path),
        isTrue,
      );
    });

    test('handles multi-line description', () async {
      final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: test_app
description: |
  First line
  Second line
''');

      final inspector = ProjectInspector(projectRoot: tempDir);
      final metadata = await inspector.inspect();

      expect(metadata.displayName, 'First Line Second Line');
    });
  });
}

