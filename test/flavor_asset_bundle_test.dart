import 'package:flavors_chef/src/models/flavor_asset_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('FlavorAssetBundle', () {
    test('hasIcon returns true when iconAssetPath is provided', () {
      const bundle = FlavorAssetBundle(iconAssetPath: 'assets/icon.png');
      expect(bundle.hasIcon, isTrue);
    });

    test('hasIcon returns false when iconAssetPath is null', () {
      const bundle = FlavorAssetBundle();
      expect(bundle.hasIcon, isFalse);
    });

    test('hasSplash returns true when splashAssetPath is provided', () {
      const bundle = FlavorAssetBundle(splashAssetPath: 'assets/splash.png');
      expect(bundle.hasSplash, isTrue);
    });

    test('hasSplash returns false when splashAssetPath is null', () {
      const bundle = FlavorAssetBundle();
      expect(bundle.hasSplash, isFalse);
    });

    test('can have both icon and splash', () {
      const bundle = FlavorAssetBundle(
        iconAssetPath: 'assets/icon.png',
        splashAssetPath: 'assets/splash.png',
      );
      expect(bundle.hasIcon, isTrue);
      expect(bundle.hasSplash, isTrue);
    });

    test('can have neither icon nor splash', () {
      const bundle = FlavorAssetBundle();
      expect(bundle.hasIcon, isFalse);
      expect(bundle.hasSplash, isFalse);
    });
  });
}
