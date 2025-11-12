import 'dart:io';

import 'package:flavors_chef/src/models/flavor_project_context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FlavorProjectContext', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flavor_context_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('stores project metadata correctly', () {
      final context = FlavorProjectContext(
        projectRoot: tempDir,
        appName: 'Test App',
        androidApplicationId: 'com.test.app',
        iosBundleId: 'com.test.app',
      );

      expect(context.appName, equals('Test App'));
      expect(context.androidApplicationId, equals('com.test.app'));
      expect(context.iosBundleId, equals('com.test.app'));
      expect(context.projectRoot.path, equals(tempDir.absolute.path));
    });

    test('normalizes project root to absolute path', () {
      final relativeDir = Directory('relative');
      final context = FlavorProjectContext(
        projectRoot: relativeDir,
        appName: 'Test App',
        androidApplicationId: 'com.test.app',
        iosBundleId: 'com.test.app',
      );

      expect(p.isAbsolute(context.projectRoot.path), isTrue);
    });

    group('resolvePath', () {
      test('resolves relative paths against project root', () {
        final context = FlavorProjectContext(
          projectRoot: tempDir,
          appName: 'Test App',
          androidApplicationId: 'com.test.app',
          iosBundleId: 'com.test.app',
        );

        final resolved = context.resolvePath('assets/icon.png');
        expect(resolved, equals(p.join(tempDir.path, 'assets', 'icon.png')));
      });

      test('normalizes absolute paths', () {
        final context = FlavorProjectContext(
          projectRoot: tempDir,
          appName: 'Test App',
          androidApplicationId: 'com.test.app',
          iosBundleId: 'com.test.app',
        );

        final absolutePath = p.join(tempDir.path, 'assets', 'icon.png');
        final resolved = context.resolvePath(absolutePath);
        expect(resolved, equals(p.normalize(absolutePath)));
      });

      test('handles paths with .. segments', () {
        final context = FlavorProjectContext(
          projectRoot: tempDir,
          appName: 'Test App',
          androidApplicationId: 'com.test.app',
          iosBundleId: 'com.test.app',
        );

        final resolved = context.resolvePath('assets/../icon.png');
        expect(resolved, equals(p.normalize(p.join(tempDir.path, 'icon.png'))));
      });

      test('handles paths with . segments', () {
        final context = FlavorProjectContext(
          projectRoot: tempDir,
          appName: 'Test App',
          androidApplicationId: 'com.test.app',
          iosBundleId: 'com.test.app',
        );

        final resolved = context.resolvePath('./assets/icon.png');
        expect(
          resolved,
          equals(p.normalize(p.join(tempDir.path, 'assets', 'icon.png'))),
        );
      });
    });
  });
}
