import 'package:flavors_chef/src/utils/validation.dart';
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

    test('handles multiple underscores', () {
      expect(sanitizeFlavorName('dev__build'), equals('dev_build'));
      expect(sanitizeFlavorName('test___flavor'), equals('test_flavor'));
    });

    test('removes leading and trailing underscores', () {
      expect(sanitizeFlavorName('_dev'), equals('dev'));
      expect(sanitizeFlavorName('dev_'), equals('dev'));
      expect(sanitizeFlavorName('_dev_'), equals('dev'));
    });
  });

  group('isValidFlavorName', () {
    test('accepts valid names', () {
      expect(isValidFlavorName('development'), isTrue);
      expect(isValidFlavorName('qa_stage'), isTrue);
      expect(isValidFlavorName('prod1'), isTrue);
      expect(isValidFlavorName('a'), isTrue);
    });

    test('rejects invalid names', () {
      expect(isValidFlavorName('Dev'), isFalse);
      expect(isValidFlavorName('qa-stage'), isFalse);
      expect(isValidFlavorName('_prod'), isFalse);
      expect(isValidFlavorName('1prod'), isFalse);
      expect(isValidFlavorName(''), isFalse);
      expect(isValidFlavorName('dev__build'), isFalse);
    });
  });

  group('isValidHexColor', () {
    test('accepts valid 6-digit hex colors', () {
      expect(isValidHexColor('#000000'), isTrue);
      expect(isValidHexColor('#FFFFFF'), isTrue);
      expect(isValidHexColor('#abcdef'), isTrue);
      expect(isValidHexColor('#123456'), isTrue);
      expect(isValidHexColor('#ABCDEF'), isTrue);
    });

    test('accepts valid 8-digit hex colors with alpha', () {
      expect(isValidHexColor('#00000000'), isTrue);
      expect(isValidHexColor('#FFFFFFFF'), isTrue);
      expect(isValidHexColor('#12345678'), isTrue);
      expect(isValidHexColor('#abcdef00'), isTrue);
    });

    test('rejects invalid hex colors', () {
      expect(isValidHexColor('000000'), isFalse); // missing #
      expect(isValidHexColor('#00000'), isFalse); // too short
      expect(isValidHexColor('#0000000'), isFalse); // wrong length
      expect(isValidHexColor('#000000000'), isFalse); // too long
      expect(isValidHexColor('#GGGGGG'), isFalse); // invalid chars
      expect(isValidHexColor(''), isFalse); // empty
      expect(isValidHexColor('#'), isFalse); // just #
      expect(isValidHexColor('#12345'), isFalse); // 5 digits
      expect(isValidHexColor('#1234567'), isFalse); // 7 digits
    });
  });
}
