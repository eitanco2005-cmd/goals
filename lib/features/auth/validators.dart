import '../../data/repositories.dart' show maxNameLength;
import '../../l10n/gen/app_localizations.dart';

/// Localized form validators shared by the auth screens.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(AppLocalizations l, String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l.authEmailRequired;
    if (!_email.hasMatch(value)) return l.errInvalidEmail;
    return null;
  }

  static bool isValidEmail(String v) => _email.hasMatch(v.trim());

  /// Sign-in only checks presence; sign-up also checks the length.
  static String? password(AppLocalizations l, String? v,
      {bool checkLength = false}) {
    final value = v ?? '';
    if (value.isEmpty) return l.authPasswordRequired;
    if (checkLength && value.length < 6) return l.errWeakPassword;
    return null;
  }

  /// Required, at most [maxNameLength] characters (the rules' limit).
  static String? name(AppLocalizations l, String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l.authNameRequired;
    if (value.length > maxNameLength) return l.sessionNameTooLong(maxNameLength);
    return null;
  }
}
