import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/utils/profile_validation.dart';

void main() {
  group('ProfileValidation.parseAge', () {
    test('accepts valid boundary values and trims whitespace', () {
      expect(ProfileValidation.parseAge(' 1 '), 1);
      expect(ProfileValidation.parseAge('120'), 120);
    });

    test('uses null for an optional empty age', () {
      expect(ProfileValidation.parseAge(''), isNull);
      expect(ProfileValidation.parseAge('   '), isNull);
    });

    test('rejects non-numeric and out-of-range ages', () {
      for (final value in ['hello', '0', '-1', '121', '20.5']) {
        expect(
          () => ProfileValidation.parseAge(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });
}
