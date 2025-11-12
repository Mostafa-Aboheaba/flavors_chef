import 'package:flavors_chef/src/models/flavor_definition.dart';
import 'package:test/test.dart';

void main() {
  group('FlavorDefinition', () {
    test('toJson includes all fields', () {
      const definition = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        environmentValues: {'API_URL': 'https://dev.example.com'},
      );

      final json = definition.toJson();

      expect(json['name'], equals('dev'));
      expect(json['appName'], equals('Dev App'));
      expect(json['androidApplicationId'], equals('com.example.dev'));
      expect(json['iosBundleId'], equals('com.example.dev'));
      expect(json['primaryColorHex'], equals('#123456'));
      expect(json['environmentValues'], equals({'API_URL': 'https://dev.example.com'}));
      expect(json['iconSourcePath'], isNull);
      expect(json['splashImagePath'], isNull);
      expect(json.containsKey('androidApplicationIdSuffix'), isFalse);
      expect(json.containsKey('versionNameSuffix'), isFalse);
    });

    test('toJson includes optional fields when present', () {
      const definition = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        iconSourcePath: '/path/to/icon.png',
        splashImagePath: '/path/to/splash.png',
        androidApplicationIdSuffix: '.dev',
        versionNameSuffix: '-dev',
        environmentValues: {},
        launcherIconConfig: {'android': true},
        nativeSplashConfig: {'color': '#123456'},
      );

      final json = definition.toJson();

      expect(json['iconSourcePath'], equals('/path/to/icon.png'));
      expect(json['splashImagePath'], equals('/path/to/splash.png'));
      expect(json['androidApplicationIdSuffix'], equals('.dev'));
      expect(json['versionNameSuffix'], equals('-dev'));
      expect(json['launcherIconConfig'], equals({'android': true}));
      expect(json['nativeSplashConfig'], equals({'color': '#123456'}));
    });

    test('fromJson creates instance correctly', () {
      final json = {
        'name': 'dev',
        'appName': 'Dev App',
        'androidApplicationId': 'com.example.dev',
        'iosBundleId': 'com.example.dev',
        'primaryColorHex': '#123456',
        'iconSourcePath': '/path/to/icon.png',
        'splashImagePath': '/path/to/splash.png',
        'androidApplicationIdSuffix': '.dev',
        'versionNameSuffix': '-dev',
        'environmentValues': {'API_URL': 'https://dev.example.com'},
        'launcherIconConfig': {'android': true},
        'nativeSplashConfig': {'color': '#123456'},
      };

      final definition = FlavorDefinition.fromJson(json);

      expect(definition.name, equals('dev'));
      expect(definition.appName, equals('Dev App'));
      expect(definition.androidApplicationId, equals('com.example.dev'));
      expect(definition.iosBundleId, equals('com.example.dev'));
      expect(definition.primaryColorHex, equals('#123456'));
      expect(definition.iconSourcePath, equals('/path/to/icon.png'));
      expect(definition.splashImagePath, equals('/path/to/splash.png'));
      expect(definition.androidApplicationIdSuffix, equals('.dev'));
      expect(definition.versionNameSuffix, equals('-dev'));
      expect(definition.environmentValues, equals({'API_URL': 'https://dev.example.com'}));
      expect(definition.launcherIconConfig, equals({'android': true}));
      expect(definition.nativeSplashConfig, equals({'color': '#123456'}));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'name': 'dev',
        'appName': 'Dev App',
        'androidApplicationId': 'com.example.dev',
        'iosBundleId': 'com.example.dev',
        'primaryColorHex': '#123456',
        'environmentValues': {},
      };

      final definition = FlavorDefinition.fromJson(json);

      expect(definition.iconSourcePath, isNull);
      expect(definition.splashImagePath, isNull);
      expect(definition.androidApplicationIdSuffix, isNull);
      expect(definition.versionNameSuffix, isNull);
      expect(definition.launcherIconConfig, isEmpty);
      expect(definition.nativeSplashConfig, isEmpty);
    });

    test('copyWith updates specified fields', () {
      const original = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        environmentValues: {},
      );

      final updated = original.copyWith(
        appName: 'Updated App',
        primaryColorHex: '#789ABC',
      );

      expect(updated.name, equals('dev'));
      expect(updated.appName, equals('Updated App'));
      expect(updated.primaryColorHex, equals('#789ABC'));
      expect(updated.androidApplicationId, equals('com.example.dev'));
    });

    test('copyWith can set optional fields to null', () {
      const original = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        iconSourcePath: '/path/to/icon.png',
        splashImagePath: '/path/to/splash.png',
        environmentValues: {},
      );

      final updated = original.copyWith(
        iconSourcePath: null,
        splashImagePath: null,
      );

      expect(updated.iconSourcePath, isNull);
      expect(updated.splashImagePath, isNull);
    });

    test('equality works correctly', () {
      const def1 = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        environmentValues: {},
      );

      const def2 = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        environmentValues: {},
      );

      const def3 = FlavorDefinition(
        name: 'prod',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        environmentValues: {},
      );

      expect(def1 == def2, isTrue);
      expect(def1 == def3, isFalse);
      expect(def1.hashCode == def2.hashCode, isTrue);
    });

    test('toString returns formatted string', () {
      const definition = FlavorDefinition(
        name: 'dev',
        appName: 'Dev App',
        androidApplicationId: 'com.example.dev',
        iosBundleId: 'com.example.dev',
        primaryColorHex: '#123456',
        environmentValues: {},
      );

      final str = definition.toString();
      expect(str, contains('FlavorDefinition'));
      expect(str, contains('dev'));
    });
  });
}

