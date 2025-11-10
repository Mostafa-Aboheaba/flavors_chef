import 'package:flavor_chef/src/utils/validation.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizeFlavorName', () {
    test('normalizes whitespace and punctuation', () {
      expect(sanitizeFlavorName('Dev Build'), equals('dev_build'));
      expect(sanitizeFlavorName('Production!'), equals('production'));
      expect(sanitizeFlavorName('  QA-Stage  '), equals('qa_stage'));
    });

    test('falls back to flavor when empty', () {
      expect(sanitizeFlavorName(''), equals('flavor'));
      expect(sanitizeFlavorName('!!!'), equals('flavor'));
    });
  });

  group('isValidFlavorName', () {
    test('accepts valid names', () {
      expect(isValidFlavorName('development'), isTrue);
      expect(isValidFlavorName('qa_stage'), isTrue);
    });

    test('rejects invalid names', () {
      expect(isValidFlavorName('Dev'), isFalse);
      expect(isValidFlavorName('qa-stage'), isFalse);
      expect(isValidFlavorName('_prod'), isFalse);
    });
  });
}
