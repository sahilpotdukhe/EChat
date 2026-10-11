import 'package:shadcn_kit/shadcn_kit.dart';

/// EChat's form rules, built from the shared [ShadcnValidators]. Each returns
/// an error message, or null when the value is fine.
class Validators {
  static final _emailPattern = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?"
      r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

  static const passwordRules = 'At least 8 characters with an uppercase letter, '
      'a lowercase letter, a number and a symbol (!@#\$&*~).';

  static bool isEmail(String value) => _emailPattern.hasMatch(value.trim());

  /// Runs [rule] on the trimmed value, so stray spaces around what the user
  /// typed (or pasted) don't count against them.
  static ShadcnValidator _trimmed(ShadcnValidator rule) => (value) => rule(value?.trim());

  static final ShadcnValidator email = _trimmed(ShadcnValidators.combine([
    ShadcnValidators.required('Enter your email address'),
    ShadcnValidators.pattern(_emailPattern, 'That email address doesn\'t look right'),
  ]));

  /// For signing in: only checks something was typed, so accounts made
  /// before the strength rules existed can still sign in.
  static String? requiredPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password' : null;

  static final ShadcnValidator newPassword = ShadcnValidators.combine([
    (value) => (value == null || value.isEmpty) ? 'Choose a password' : null,
    ShadcnValidators.pattern(
      RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$'),
      passwordRules,
    ),
  ]);

  static final ShadcnValidator name = _trimmed(ShadcnValidators.combine([
    ShadcnValidators.required('Enter your name'),
    ShadcnValidators.pattern(RegExp(r'^[a-z A-Z]+$'), 'Use letters and spaces only'),
  ]));

  static final ShadcnValidator phone = _trimmed(ShadcnValidators.combine([
    ShadcnValidators.required('Enter your phone number'),
    ShadcnValidators.pattern(RegExp(r'^[0-9]+$'), 'Use digits only'),
    ShadcnValidators.pattern(RegExp(r'^.{10}$'), 'Enter a 10-digit phone number'),
  ]));
}
