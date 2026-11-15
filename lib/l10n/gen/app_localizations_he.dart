// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'האתגר שלנו';

  @override
  String get navToday => 'היום';

  @override
  String get navWeek => 'שבוע';

  @override
  String get navBoard => 'לוח';

  @override
  String get navSettings => 'הגדרות';

  @override
  String get comingSoon => 'בקרוב';

  @override
  String get language => 'שפה';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageEnglish => 'English';

  @override
  String demoModeBanner(String code) {
    return 'מצב הדגמה – הנתונים לא נשמרים. הצטרפו עם הקוד $code כדי להתחבר לשותפה לדוגמה.';
  }

  @override
  String get errInvalidCredentials => 'אימייל או סיסמה שגויים';

  @override
  String get errEmailInUse => 'האימייל הזה כבר רשום';

  @override
  String get errWeakPassword => 'הסיסמה חייבת להכיל לפחות 6 תווים';

  @override
  String get errInvalidEmail => 'כתובת אימייל לא תקינה';

  @override
  String get errInvalidCode => 'לא נמצא אתגר עם הקוד הזה';

  @override
  String get errPairFull => 'באתגר הזה כבר יש שני אנשים';

  @override
  String get errAlreadyPaired => 'את/ה כבר באתגר';

  @override
  String get errNetwork => 'אין חיבור. בדקו את האינטרנט ונסו שוב';

  @override
  String get errUnknown => 'משהו השתבש. נסו שוב';

  @override
  String get statusMet => 'בוצע';

  @override
  String get statusNotMet => 'עוד לא';

  @override
  String get statusUnlogged => 'לא עודכן';

  @override
  String get signOut => 'התנתקות';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get displayName => 'השם שלך';
}
