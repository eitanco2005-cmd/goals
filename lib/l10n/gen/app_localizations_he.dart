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
  String sessionNameTooLong(int max) {
    return 'השם יכול להכיל עד $max תווים';
  }

  @override
  String get sessionStuckMessage =>
      'הטעינה לוקחת יותר זמן מהרגיל. כדאי לבדוק את החיבור ולנסות שוב.';

  @override
  String get sessionTryAgain => 'לנסות שוב';

  @override
  String get authTagline =>
      'שניים, אתגר אחד. בונים הרגלים בריאים יחד, יום אחרי יום.';

  @override
  String get authSignInTitle => 'טוב שחזרתם';

  @override
  String get authSignUpTitle => 'יצירת חשבון';

  @override
  String get authEmailLabel => 'אימייל';

  @override
  String get authPasswordLabel => 'סיסמה';

  @override
  String get authNameHint => 'כך השם שלכם יופיע באתגר';

  @override
  String get authPasswordHint => 'לפחות 6 תווים';

  @override
  String get authShowPassword => 'הצגת הסיסמה';

  @override
  String get authHidePassword => 'הסתרת הסיסמה';

  @override
  String get authForgotPassword => 'שכחתם סיסמה?';

  @override
  String authResetSent(String email) {
    return 'שלחנו קישור לאיפוס סיסמה אל $email';
  }

  @override
  String get authResetNeedsEmail =>
      'הזינו למעלה אימייל תקין ולחצו שוב על „שכחתם סיסמה?”';

  @override
  String get authSignInButton => 'התחברות';

  @override
  String get authSignUpButton => 'יצירת חשבון';

  @override
  String get authNoAccount => 'חדשים כאן?';

  @override
  String get authGoToSignUp => 'צרו חשבון';

  @override
  String get authHaveAccount => 'כבר יש לכם חשבון?';

  @override
  String get authGoToSignIn => 'התחברו';

  @override
  String get authEmailRequired => 'הזינו אימייל';

  @override
  String get authPasswordRequired => 'הזינו סיסמה';

  @override
  String get authNameRequired => 'הזינו את השם שלכם';

  @override
  String pairWelcome(String name) {
    return 'היי $name! בואו נתחיל';
  }

  @override
  String get pairIntro =>
      'פתחו אתגר חדש והזמינו את בן/בת הזוג, או הצטרפו לאתגר שבן/בת הזוג כבר פתחו.';

  @override
  String get pairCreateTitle => 'פתיחת אתגר חדש';

  @override
  String get pairCreateSubtitle =>
      'בוחרים תאריכים ומקבלים קוד לשלוח לבן/בת הזוג';

  @override
  String get pairJoinTitle => 'הצטרפות עם קוד';

  @override
  String get pairJoinSubtitle => 'בן/בת הזוג כבר פתחו אתגר? הזינו את הקוד';

  @override
  String get pairStartDate => 'תאריך התחלה';

  @override
  String get pairEndDate => 'תאריך סיום';

  @override
  String get pairLength => 'משך האתגר';

  @override
  String pairDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return '$_temp0';
  }

  @override
  String get pairCustomLength => 'תאריך אחר';

  @override
  String get pairGoalsIncluded => 'היעדים באתגר';

  @override
  String get pairDailyGoals => 'יעדים יומיים';

  @override
  String get pairWeeklyGoals => 'יעדים שבועיים';

  @override
  String get pairGoalsEditLater => 'אפשר לערוך את היעדים גם בהמשך.';

  @override
  String get pairCreateButton => 'יצירת האתגר';

  @override
  String get pairCodeLabel => 'קוד הזמנה';

  @override
  String get pairCodeHint => '6 אותיות ומספרים';

  @override
  String get pairCodeLength => 'הקוד מכיל 6 תווים';

  @override
  String get pairJoinButton => 'הצטרפות לאתגר';

  @override
  String get pairInviteTitle => 'קוד ההזמנה שלכם';

  @override
  String get pairInviteExplain => 'שלחו את הקוד לבן/בת הזוג כדי להצטרף לאתגר.';

  @override
  String get pairCopy => 'העתקה';

  @override
  String get pairCopyCode => 'העתקת קוד ההזמנה';

  @override
  String get pairCopied => 'הקוד הועתק';

  @override
  String get settingsProfile => 'פרופיל';

  @override
  String get settingsEditName => 'עריכת השם';

  @override
  String get settingsChallenge => 'האתגר';

  @override
  String get settingsPartner => 'בן/בת הזוג';

  @override
  String get settingsWaitingForPartner => 'מחכים שבן/בת הזוג יצטרפו';

  @override
  String get settingsDates => 'תאריכים';

  @override
  String settingsDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String settingsDayOf(int day, int total) {
    return 'יום $day מתוך $total';
  }

  @override
  String get settingsEditGoals => 'עריכת יעדים';

  @override
  String get settingsAccount => 'חשבון';

  @override
  String get settingsSignOutConfirmTitle => 'להתנתק?';

  @override
  String get settingsSignOutConfirmBody =>
      'אפשר להתחבר שוב בכל עת עם האימייל והסיסמה.';

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
  String widgetTitle(String name, int percent) {
    return '$name · $percent% היום';
  }

  @override
  String widgetGoalsDone(int met, int total) {
    return '$met/$total';
  }

  @override
  String widgetNoPhotos(String name) {
    return 'עוד אין תמונות של $name היום';
  }

  @override
  String get photoAdd => 'הוספת תמונה';

  @override
  String photoAddFor(String goal) {
    return 'הוספת תמונה: $goal';
  }

  @override
  String get photoUploading => 'מעלים את התמונה…';

  @override
  String get photoTakePhoto => 'צילום תמונה';

  @override
  String get photoChooseFromGallery => 'בחירה מהגלריה';

  @override
  String photoOpen(String goal, String time) {
    return 'תמונה: $goal, $time';
  }

  @override
  String get photoPartnerPhotos => 'התמונות של היום';

  @override
  String photoYourReaction(String emoji) {
    return 'התגובה שלך: $emoji';
  }

  @override
  String photoReact(String emoji) {
    return 'תגובה $emoji';
  }

  @override
  String photoPartnerReacted(String name, String emoji) {
    return 'תגובה מ$name: $emoji';
  }

  @override
  String photoReactionSnack(String name, String emoji, String goalIcon) {
    return 'תגובה חדשה מ$name: $emoji על התמונה שלך $goalIcon';
  }

  @override
  String get photoView => 'לצפייה';

  @override
  String get photoClose => 'סגירה';

  @override
  String get photoDelete => 'מחיקת התמונה';

  @override
  String get photoDeleteTitle => 'למחוק את התמונה?';

  @override
  String get photoDeleteBody =>
      'התמונה תיעלם אצל שני הצדדים. אי אפשר לבטל את המחיקה.';

  @override
  String get photoDeleteConfirm => 'מחיקה';

  @override
  String get photoDeleted => 'התמונה נמחקה';

  @override
  String get photoRetry => 'נסו שוב';

  @override
  String get photoLoadFailed => 'לא הצלחנו לטעון את התמונה המלאה';

  @override
  String get photoErrTooLarge => 'התמונה גדולה מדי. נסו תמונה אחרת';

  @override
  String photoErrLimit(int count) {
    return 'הגעת למגבלה של $count תמונות ביום';
  }

  @override
  String get photoErrUnreadable => 'לא הצלחנו לקרוא את התמונה. נסו תמונה אחרת';

  @override
  String get photoErrPicker => 'לא הצלחנו לפתוח את המצלמה או את הגלריה';

  @override
  String todayClearedGoal(String goal) {
    return '$goal: הרישום נמחק';
  }

  @override
  String get todayUndo => 'ביטול';

  @override
  String get todayGreetingMorning => 'בוקר טוב';

  @override
  String get todayGreetingAfternoon => 'צהריים טובים';

  @override
  String get todayGreetingEvening => 'ערב טוב';

  @override
  String get todayGreetingNight => 'לילה טוב';

  @override
  String todayDayOfTotal(int day, int total) {
    return 'יום $day מתוך $total';
  }

  @override
  String todayChallengeStartsIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'האתגר מתחיל בעוד $count ימים',
      two: 'האתגר מתחיל בעוד יומיים',
      one: 'האתגר מתחיל מחר',
    );
    return '$_temp0';
  }

  @override
  String get todayChallengeEnded => 'האתגר הסתיים 🏁';

  @override
  String todayMetCount(int met, int total) {
    return '$met מתוך $total יעדים הושלמו';
  }

  @override
  String todayProgressSemantics(int percent) {
    return '$percent% מהיעדים של היום הושלמו';
  }

  @override
  String get todayAllDone => 'כל היעדים של היום הושלמו! 🎉';

  @override
  String get todayPartnerFallbackName => 'בן/בת הזוג';

  @override
  String todayPartnerPercent(int percent) {
    return '$percent% היום';
  }

  @override
  String get todayPartnerNothingYet => 'עדיין אין עדכונים היום';

  @override
  String todayGoalStatusSemantics(String goal, String status) {
    return '$goal: $status';
  }

  @override
  String get todayWaitingTitle => 'מחכים לבן/בת הזוג';

  @override
  String get todayWaitingBody => 'שלחו את הקוד הזה כדי שיצטרפו לאתגר שלכם:';

  @override
  String get todayYourGoals => 'היעדים שלי';

  @override
  String todayDecrease(String goal) {
    return 'הפחתה: $goal';
  }

  @override
  String todayIncrease(String goal) {
    return 'הוספה: $goal';
  }

  @override
  String get todayNoneToday => 'כלום היום ✓';

  @override
  String get todayKeptIt => 'עמדתי בזה ✓';

  @override
  String get todayDidnt => 'לא הפעם';

  @override
  String todayValueSteps(String value) {
    return '$value צעדים';
  }

  @override
  String todayValueMinutes(String value) {
    return '$value דק׳';
  }

  @override
  String todayProgressOf(String value, String target) {
    return '$value / $target';
  }

  @override
  String todayAtMost(String target) {
    return 'עד $target';
  }

  @override
  String get todayUnitSteps => 'צעדים';

  @override
  String get todayUnitMinutes => 'דק׳';

  @override
  String get todayTapToEdit => 'הזנת ערך מדויק';

  @override
  String get todayEnterValueLabel => 'ערך';

  @override
  String get todayInvalidNumber => 'יש להזין מספר שלם';

  @override
  String get todaySave => 'שמירה';

  @override
  String get todayCancel => 'ביטול';

  @override
  String get todayClear => 'ניקוי';

  @override
  String get todayDismiss => 'סגירה';

  @override
  String get todayThisWeek => 'השבוע';

  @override
  String get todayNoChallengeTitle => 'אין אתגר פעיל';

  @override
  String get todayNoChallengeBody =>
      'אפשר לפתוח סבב חדש בהגדרות ולהתחיל לעקוב.';

  @override
  String get todayNoDailyGoals => 'בסבב הזה אין יעדים יומיים.';

  @override
  String get signOut => 'התנתקות';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get displayName => 'השם שלך';
}
