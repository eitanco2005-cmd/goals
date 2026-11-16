import '../data/repositories.dart';
import '../l10n/gen/app_localizations.dart';

/// Maps any error to a localized, user-friendly message.
String errorMessage(AppLocalizations l, Object error) {
  final code = error is AppException ? error.code : 'unknown';
  return switch (code) {
    'invalid-credentials' => l.errInvalidCredentials,
    'email-in-use' => l.errEmailInUse,
    'weak-password' => l.errWeakPassword,
    'invalid-email' => l.errInvalidEmail,
    'invalid-code' => l.errInvalidCode,
    'pair-full' => l.errPairFull,
    'already-paired' => l.errAlreadyPaired,
    'network' => l.errNetwork,
    'photo-too-large' => l.photoErrTooLarge,
    'photo-limit' => l.photoErrLimit(maxPhotosPerDay),
    'photo-unreadable' => l.photoErrUnreadable,
    _ => l.errUnknown,
  };
}
