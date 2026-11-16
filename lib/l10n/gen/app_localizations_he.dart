// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Goals';

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
      'אתגר אחד, ביחד. בונים הרגלים בריאים יום אחרי יום ודוחפים אחד את השני.';

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
      'פתחו אתגר חדש והזמינו אחרים, או הצטרפו לאתגר שמישהו כבר פתח.';

  @override
  String get pairCreateTitle => 'פתיחת אתגר חדש';

  @override
  String get pairCreateSubtitle => 'בוחרים תאריכים ומקבלים קוד לשיתוף';

  @override
  String get pairJoinTitle => 'הצטרפות עם קוד';

  @override
  String get pairJoinSubtitle => 'קיבלתם קוד? הזינו אותו כאן';

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
  String get pairInviteExplain =>
      'שתפו את הקוד עם מי שתרצו שיצטרפו לאתגר (עד 8 משתתפים).';

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
  String get settingsWaitingForPartner => 'עוד אף אחד לא הצטרף';

  @override
  String settingsMembers(int count, int max) {
    return 'משתתפים ($count/$max)';
  }

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
    return 'מצב הדגמה – הנתונים לא נשמרים. הצטרפו עם הקוד $code כדי לנסות עם משתתפת לדוגמה.';
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
  String get errPairFull => 'האתגר הזה מלא';

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
  String get pairEditGoals => 'עריכת היעדים';

  @override
  String get todayNeedsPhoto => 'הוסיפו תמונה כדי להשלים את היעד';

  @override
  String get todayNeedsPhotoShort => 'חסרה תמונה';

  @override
  String get todayPhotoRequiredNote => '📷 נספר רק עם תמונה';

  @override
  String get goalsPhotoRequired => 'חובת תמונה';

  @override
  String get goalsPhotoRequiredSub => 'נחשב כבוצע רק עם תמונה שלו באותו יום';

  @override
  String get goalsSummaryPhoto => '📷 חובת תמונה';

  @override
  String get inviteShare => 'שיתוף קישור הזמנה';

  @override
  String inviteShareText(String link, String code) {
    return 'הצטרפו לאתגר שלי ב-Goals! $link\nקוד הצטרפות: $code';
  }

  @override
  String get inviteCopied => 'ההזמנה הועתקה – הדביקו אותה בהודעה';

  @override
  String get updateAvailable => 'גרסה חדשה של Goals מוכנה';

  @override
  String get updateInstall => 'עדכון';

  @override
  String get remindersSection => 'תזכורות';

  @override
  String get remindersEvening => 'וידוא סוף יום';

  @override
  String remindersEveningSub(String time) {
    return 'ב־$time: מה עוד לא עודכן היום';
  }

  @override
  String get remindersMidday => 'תזכורת צהריים';

  @override
  String remindersMiddaySub(String time) {
    return 'ב־$time: כמה יעדים עוד פתוחים';
  }

  @override
  String get remindersDenied =>
      'ההתראות כבויות לאפליקציה. אפשר להפעיל אותן בהגדרות הטלפון.';

  @override
  String get remindersChannel => 'תזכורות';

  @override
  String get reminderEveningTitle => 'וידוא סוף יום';

  @override
  String reminderEveningBody(String goals) {
    return 'עוד לא עודכן: $goals';
  }

  @override
  String get reminderEveningGeneric =>
      'איך היה היום? עדכנו את היעדים לפני שהיום נגמר.';

  @override
  String get reminderMiddayTitle => 'חצי יום עבר';

  @override
  String reminderMiddayBody(int count, String goals) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count יעדים עוד פתוחים',
      one: 'יעד אחד עוד פתוח',
    );
    return '$_temp0: $goals';
  }

  @override
  String get reminderMiddayGeneric => 'בדיקה קצרה: איך מתקדמים היעדים של היום?';

  @override
  String get groupNewCode => 'יצירת קוד הזמנה חדש';

  @override
  String get groupNewCodeBody =>
      'הקוד הנוכחי יפסיק לעבוד. שתפו את החדש עם מי שעוד רוצים להזמין.';

  @override
  String get groupNewCodeConfirm => 'יצירת קוד חדש';

  @override
  String groupNewCodeDone(String code) {
    return 'קוד ההזמנה החדש: $code';
  }

  @override
  String get groupLeave => 'עזיבת האתגר';

  @override
  String get groupLeaveTitle => 'לעזוב את האתגר?';

  @override
  String get groupLeaveBody =>
      'לא תראו יותר את הקבוצה והיא לא תראה רישומים חדשים שלכם. מה שכבר שיתפתם נשאר בהיסטוריה של הקבוצה. אפשר להצטרף שוב עם קוד.';

  @override
  String get groupLeaveConfirm => 'עזיבה';

  @override
  String get goalsTitle => 'יעדים';

  @override
  String get goalsInfo =>
      'השינויים חלים על כל הקבוצה מהיום והלאה. ימים קודמים שומרים על התוצאות שלהם.';

  @override
  String get goalsDaily => 'יומיים';

  @override
  String get goalsWeekly => 'שבועיים';

  @override
  String get goalsAdd => 'הוספת יעד';

  @override
  String get goalsSave => 'שמירה';

  @override
  String get goalsSaved => 'היעדים עודכנו לכל הקבוצה';

  @override
  String get goalsDiscardTitle => 'לבטל את השינויים?';

  @override
  String get goalsDiscard => 'ביטול השינויים';

  @override
  String get goalsKeepEditing => 'להמשיך לערוך';

  @override
  String get goalsEditTitle => 'עריכת יעד';

  @override
  String get goalsNewTitle => 'יעד חדש';

  @override
  String get goalsIcon => 'אייקון';

  @override
  String get goalsName => 'שם';

  @override
  String get goalsNameRequired => 'תנו שם ליעד';

  @override
  String get goalsKind => 'סוג';

  @override
  String get goalsKindYesNo => 'כן / לא';

  @override
  String get goalsKindCount => 'ספירה';

  @override
  String get goalsKindMinutes => 'דקות';

  @override
  String get goalsKindNumber => 'מספר';

  @override
  String get goalsPeriod => 'באיזו תדירות';

  @override
  String get goalsRule => 'כלל';

  @override
  String get goalsAtLeast => 'לפחות';

  @override
  String get goalsAtMost => 'לכל היותר';

  @override
  String get goalsExactly => 'בדיוק';

  @override
  String get goalsTarget => 'יעד';

  @override
  String get goalsTargetInvalid => 'הזינו מספר שלם גדול מ־0';

  @override
  String get goalsDelete => 'מחיקת יעד';

  @override
  String goalsDeleteConfirm(String goal) {
    return 'למחוק את \"$goal\"? תוצאות קודמות נשמרות.';
  }

  @override
  String get goalsWorkoutsTotal => 'אימונים בשבוע';

  @override
  String get goalsWorkoutsRuns => 'מתוכם ריצות';

  @override
  String get goalsWorkoutsStrength => 'מתוכם כוח';

  @override
  String get goalsWorkoutsMinutes => 'מינימום דקות לכל אימון';

  @override
  String get goalsNeedOneDaily => 'צריך לפחות יעד יומי אחד';

  @override
  String goalsTooMany(int max) {
    return 'עד $max יעדים';
  }

  @override
  String get goalsSummaryYesNo => 'כן / לא';

  @override
  String goalsSummaryAtLeast(String target) {
    return 'לפחות $target';
  }

  @override
  String goalsSummaryAtMost(String target) {
    return 'לכל היותר $target';
  }

  @override
  String goalsSummaryExactly(String target) {
    return 'בדיוק $target';
  }

  @override
  String goalsSummaryPerWeek(String summary) {
    return '$summary בשבוע';
  }

  @override
  String get roundTitle => 'פתיחת סבב חדש';

  @override
  String get roundSubtitle => 'תאריכים חדשים לאותה קבוצה ואותם יעדים';

  @override
  String get roundStart => 'פתיחת הסבב';

  @override
  String get roundStarted => 'סבב חדש התחיל';

  @override
  String get roundInfo =>
      'הסבב החדש מחליף את הנוכחי מיד. הלוח והרצפים מתחילים מחדש; ימים קודמים שומרים על התוצאות שלהם.';

  @override
  String get boardYou => 'אני';

  @override
  String get boardStreak => 'רצף';

  @override
  String get boardBestStreak => 'שיא';

  @override
  String get boardAverage => 'ממוצע';

  @override
  String boardDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      one: 'יום אחד',
    );
    return '$_temp0';
  }

  @override
  String boardStreakHint(int percent) {
    return 'רצף סופר ימים ברצף עם $percent% ומעלה מהיעדים היומיים.';
  }

  @override
  String get boardLegend => 'יעדים יומיים שהושלמו';

  @override
  String get boardNoData => 'לא עודכן';

  @override
  String boardCellLabel(String date, String value) {
    return '$date: $value';
  }

  @override
  String get boardGoalRates => 'כמה פעמים עמדת בכל יעד';

  @override
  String get boardNoPhotos => 'אין תמונות מהיום הזה';

  @override
  String boardNotStarted(String date) {
    return 'האתגר מתחיל ב־$date';
  }

  @override
  String get weekTitle => 'השבוע';

  @override
  String weekPastTitle(String date) {
    return 'השבוע של $date';
  }

  @override
  String get weekPrev => 'השבוע הקודם';

  @override
  String get weekNext => 'השבוע הבא';

  @override
  String weekDone(int done, int total) {
    return '$done/$total';
  }

  @override
  String get workoutRun => 'ריצה';

  @override
  String get workoutStrength => 'כוח';

  @override
  String get workoutOther => 'אחר';

  @override
  String get weekAddWorkout => 'הוספת אימון';

  @override
  String weekMinutes(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String weekTooShort(int minutes) {
    return 'פחות מ־$minutes דק׳ – לא נספר';
  }

  @override
  String get weekNoWorkouts => 'עוד לא נרשמו אימונים השבוע';

  @override
  String get weekWorkoutType => 'סוג';

  @override
  String get weekWorkoutDuration => 'משך';

  @override
  String get weekWorkoutDay => 'יום';

  @override
  String get weekDeleteWorkout => 'מחיקת אימון';

  @override
  String weekLimitTotal(int total, int limit) {
    return '$total השבוע · עד $limit';
  }

  @override
  String weekOnDay(String day, int count) {
    return 'ב$day: $count';
  }

  @override
  String get weekGroup => 'הקבוצה השבוע';

  @override
  String get weekSeeWeek => 'לשבוע המלא';

  @override
  String weekNeeds(String requirements) {
    return 'צריך: $requirements';
  }

  @override
  String weekMinMinutes(int minutes) {
    return 'לפחות $minutes דק׳ כל אחד';
  }

  @override
  String get shortcutLogWater => '+1 כוס מים';

  @override
  String get shortcutAddPhoto => 'הוספת תמונה';

  @override
  String shortcutWaterLogged(String icon, int value, int target) {
    return '$icon $value/$target – נרשם';
  }

  @override
  String get shortcutChooseGoal => 'לאיזה יעד התמונה?';

  @override
  String get homeSection => 'מסך הבית';

  @override
  String get homeAddWidget => 'הוספת הווידג׳ט';

  @override
  String get homeAddWidgetSubtitle =>
      'התמונות וההתקדמות של הקבוצה, בלי לפתוח את האפליקציה';

  @override
  String get homeAddWidgetManual =>
      'לחצו לחיצה ארוכה על מקום ריק במסך הבית, בחרו \"ווידג׳טים\" ומצאו את \"תמונות האתגר\".';

  @override
  String get homeShortcutsHint =>
      'טיפ: לחיצה ארוכה על אייקון האפליקציה ל־+1 כוס מים או לתמונה מהירה';

  @override
  String get homeInstallTitle => 'הוסיפו את האפליקציה למסך הבית';

  @override
  String get homeInstallIos =>
      'ב־Safari הקישו על \"שיתוף\" (הריבוע עם החץ) ואז על \"הוסף למסך הבית\".';

  @override
  String get homeInstallOther =>
      'פתחו את תפריט הדפדפן (⋮) ובחרו \"התקנת אפליקציה\" או \"הוספה למסך הבית\".';

  @override
  String get homeInstallWhy =>
      'היא תיפתח במסך מלא, כמו אפליקציה רגילה – במרחק נגיעה.';

  @override
  String get homeGotIt => 'הבנתי';

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
  String widgetMemberPercent(String name, int percent) {
    return '$name $percent%';
  }

  @override
  String widgetGroupPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תמונות היום',
      one: 'תמונה אחת היום',
      zero: 'עוד אין תמונות היום',
    );
    return '$_temp0';
  }

  @override
  String get widgetNoPhotosGroup => 'עוד אין תמונות מהקבוצה היום';

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
  String get todayPartnerFallbackName => 'משתתף/ת';

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
  String get todayWaitingTitle => 'הזמינו אנשים לאתגר';

  @override
  String get todayWaitingBody => 'שתפו את הקוד כדי שאחרים יצטרפו:';

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
