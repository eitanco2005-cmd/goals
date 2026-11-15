// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Our Challenge';

  @override
  String get navToday => 'Today';

  @override
  String get navWeek => 'Week';

  @override
  String get navBoard => 'Board';

  @override
  String get navSettings => 'Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get language => 'Language';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageEnglish => 'English';

  @override
  String demoModeBanner(String code) {
    return 'Demo mode – data is not saved. Join code $code to pair with a demo partner.';
  }

  @override
  String get errInvalidCredentials => 'Wrong email or password';

  @override
  String get errEmailInUse => 'This email is already registered';

  @override
  String get errWeakPassword => 'Password must be at least 6 characters';

  @override
  String get errInvalidEmail => 'Invalid email address';

  @override
  String get errInvalidCode => 'No challenge found with this code';

  @override
  String get errPairFull => 'This challenge already has two people';

  @override
  String get errAlreadyPaired => 'You are already in a challenge';

  @override
  String get errNetwork => 'No connection. Check your internet and try again';

  @override
  String get errUnknown => 'Something went wrong. Please try again';

  @override
  String get statusMet => 'Done';

  @override
  String get statusNotMet => 'Not yet';

  @override
  String get statusUnlogged => 'Not logged';

  @override
  String get signOut => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get displayName => 'Your name';
}
