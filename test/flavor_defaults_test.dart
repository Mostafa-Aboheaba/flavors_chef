import 'package:flavors_chef/src/utils/flavor_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('defaultAndroidApplicationId', () {
    test('appends flavor name to base with dot', () {
      expect(
        defaultAndroidApplicationId(base: 'com.example', flavorName: 'dev'),
        equals('com.example.dev'),
      );
      expect(
        defaultAndroidApplicationId(
          base: 'com.example.app',
          flavorName: 'staging',
        ),
        equals('com.example.app.staging'),
      );
    });

    test('handles base ending with dot', () {
      expect(
        defaultAndroidApplicationId(base: 'com.example.', flavorName: 'dev'),
        equals('com.example.dev'),
      );
    });

    test('handles empty base', () {
      expect(
        defaultAndroidApplicationId(base: '', flavorName: 'dev'),
        equals('dev'),
      );
      expect(
        defaultAndroidApplicationId(base: '   ', flavorName: 'staging'),
        equals('staging'),
      );
    });

    test('removes underscores from flavor name', () {
      expect(
        defaultAndroidApplicationId(
          base: 'com.example',
          flavorName: 'qa_stage',
        ),
        equals('com.example.qastage'),
      );
      expect(
        defaultAndroidApplicationId(
          base: 'com.example',
          flavorName: 'dev_build',
        ),
        equals('com.example.devbuild'),
      );
    });

    test('trims whitespace from base', () {
      expect(
        defaultAndroidApplicationId(
          base: '  com.example  ',
          flavorName: 'dev',
        ),
        equals('com.example.dev'),
      );
    });
  });

  group('defaultIosBundleId', () {
    test('appends flavor name to base with dot', () {
      expect(
        defaultIosBundleId(base: 'com.example', flavorName: 'dev'),
        equals('com.example.dev'),
      );
      expect(
        defaultIosBundleId(base: 'com.example.app', flavorName: 'staging'),
        equals('com.example.app.staging'),
      );
    });

    test('handles base ending with dot', () {
      expect(
        defaultIosBundleId(base: 'com.example.', flavorName: 'dev'),
        equals('com.example.dev'),
      );
    });

    test('handles empty base', () {
      expect(
        defaultIosBundleId(base: '', flavorName: 'dev'),
        equals('dev'),
      );
      expect(
        defaultIosBundleId(base: '   ', flavorName: 'staging'),
        equals('staging'),
      );
    });

    test('removes underscores from flavor name', () {
      expect(
        defaultIosBundleId(base: 'com.example', flavorName: 'qa_stage'),
        equals('com.example.qastage'),
      );
    });

    test('trims whitespace from base', () {
      expect(
        defaultIosBundleId(base: '  com.example  ', flavorName: 'dev'),
        equals('com.example.dev'),
      );
    });
  });

  group('defaultFlavorDisplayName', () {
    test('formats flavor name with base app name', () {
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: 'development',
        ),
        equals('My App Development'),
      );
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: 'qa_stage',
        ),
        equals('My App Qa Stage'),
      );
    });

    test('handles single word flavor names', () {
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: 'dev',
        ),
        equals('My App Dev'),
      );
    });

    test('handles empty flavor name', () {
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: '',
        ),
        equals('My App'),
      );
    });

    test('handles whitespace-only flavor name', () {
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: '   ',
        ),
        equals('My App'),
      );
    });

    test('capitalizes first letter of each word', () {
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: 'production_build',
        ),
        equals('My App Production Build'),
      );
    });

    test('handles flavor name with multiple underscores', () {
      expect(
        defaultFlavorDisplayName(
          baseAppName: 'My App',
          flavorName: 'qa_stage_build',
        ),
        equals('My App Qa Stage Build'),
      );
    });
  });
}

