import 'package:echat/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('empty', () => expect(Validators.email(''), 'Enter your email address'));
    test('null', () => expect(Validators.email(null), 'Enter your email address'));
    test('invalid', () => expect(Validators.email('sahil@'), 'That email address doesn\'t look right'));
    test('valid', () => expect(Validators.email('sahil@example.com'), isNull));
    test('surrounding spaces are ignored', () => expect(Validators.email('  sahil@example.com '), isNull));
  });

  group('passwords', () {
    test('sign-in only needs something typed', () {
      expect(Validators.requiredPassword(''), 'Enter your password');
      expect(Validators.requiredPassword('weak'), isNull);
    });
    test('new password must be strong', () {
      expect(Validators.newPassword(''), 'Choose a password');
      expect(Validators.newPassword('weakpass'), Validators.passwordRules);
      expect(Validators.newPassword('Str0ng!pass'), isNull);
    });
  });

  group('name', () {
    test('empty', () => expect(Validators.name('   '), 'Enter your name'));
    test('digits rejected', () => expect(Validators.name('Sahil 2'), 'Use letters and spaces only'));
    test('valid', () => expect(Validators.name('Sahil Potdukhe'), isNull));
  });

  group('phone', () {
    test('empty', () => expect(Validators.phone(''), 'Enter your phone number'));
    test('letters rejected', () => expect(Validators.phone('98765abcde'), 'Use digits only'));
    test('too short', () => expect(Validators.phone('98765'), 'Enter a 10-digit phone number'));
    test('valid', () => expect(Validators.phone('9876543210'), isNull));
  });

  test('isEmail', () {
    expect(Validators.isEmail(' a@b.co '), isTrue);
    expect(Validators.isEmail('nope'), isFalse);
  });
}
