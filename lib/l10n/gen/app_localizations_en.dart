// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Goals';

  @override
  String sessionNameTooLong(int max) {
    return 'Name can be at most $max characters';
  }

  @override
  String get sessionStuckMessage =>
      'This is taking longer than expected. Check your connection and try again.';

  @override
  String get sessionTryAgain => 'Try again';

  @override
  String get authTagline =>
      'One challenge, together. Build healthy habits day by day and keep each other going.';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignUpTitle => 'Create your account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authNameHint => 'This is how you\'ll appear in the challenge';

  @override
  String get authPasswordHint => 'At least 6 characters';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String authResetSent(String email) {
    return 'We sent a password reset link to $email';
  }

  @override
  String get authResetNeedsEmail =>
      'Enter a valid email above, then tap “Forgot password?” again';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authSignUpButton => 'Create account';

  @override
  String get authNoAccount => 'New here?';

  @override
  String get authGoToSignUp => 'Create an account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authGoToSignIn => 'Sign in';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authNameRequired => 'Please enter your name';

  @override
  String pairWelcome(String name) {
    return 'Hi $name! Let\'s get started';
  }

  @override
  String get pairIntro =>
      'Start a new challenge and invite others, or join a challenge someone already started.';

  @override
  String get pairCreateTitle => 'Start a new challenge';

  @override
  String get pairCreateSubtitle => 'Pick the dates and get a code to share';

  @override
  String get pairJoinTitle => 'Join with a code';

  @override
  String get pairJoinSubtitle => 'Got a code from someone? Enter it here';

  @override
  String get pairStartDate => 'Start date';

  @override
  String get pairEndDate => 'End date';

  @override
  String get pairLength => 'Challenge length';

  @override
  String pairDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get pairCustomLength => 'Custom';

  @override
  String get pairGoalsIncluded => 'Goals included';

  @override
  String get pairDailyGoals => 'Daily goals';

  @override
  String get pairWeeklyGoals => 'Weekly goals';

  @override
  String get pairGoalsEditLater => 'You can edit the goals later.';

  @override
  String get pairCreateButton => 'Create challenge';

  @override
  String get pairCodeLabel => 'Invite code';

  @override
  String get pairCodeHint => '6 letters and numbers';

  @override
  String get pairCodeLength => 'The code has 6 characters';

  @override
  String get pairJoinButton => 'Join challenge';

  @override
  String get pairInviteTitle => 'Your invite code';

  @override
  String get pairInviteExplain =>
      'Share this code with the people you want in the challenge (up to 8).';

  @override
  String get pairCopy => 'Copy';

  @override
  String get pairCopyCode => 'Copy invite code';

  @override
  String get pairCopied => 'Code copied';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsEditName => 'Edit name';

  @override
  String get settingsChallenge => 'Challenge';

  @override
  String get settingsWaitingForPartner => 'No one else has joined yet';

  @override
  String settingsMembers(int count, int max) {
    return 'Members ($count/$max)';
  }

  @override
  String get settingsDates => 'Dates';

  @override
  String settingsDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String settingsDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get settingsEditGoals => 'Edit goals';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmBody =>
      'You can sign back in anytime with your email and password.';

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
    return 'Demo mode – data is not saved. Join with code $code to try it with a demo member.';
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
  String get errPairFull => 'This challenge is full';

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
  String get statusFailed => 'Failed';

  @override
  String get statusOnTrack => 'On track';

  @override
  String get settingsEditGoalsHint => 'Changes apply to the whole group';

  @override
  String get statusUnlogged => 'Not logged';

  @override
  String goalsDeleted(String goal) {
    return '\"$goal\" deleted';
  }

  @override
  String get pairEditGoals => 'Edit goals';

  @override
  String get todayNeedsPhoto => 'Add a photo to complete this goal';

  @override
  String get todayNeedsPhotoShort => 'Needs a photo';

  @override
  String get todayPhotoRequiredNote => '📷 Counts only with a photo';

  @override
  String get goalsPhotoRequired => 'Photo required';

  @override
  String get goalsPhotoRequiredSub =>
      'Counts as done only with a photo of it that day';

  @override
  String get goalsSummaryPhoto => '📷 photo required';

  @override
  String get inviteShare => 'Share invite link';

  @override
  String inviteShareText(String link, String code) {
    return 'Join my challenge on Goals! $link\nInvite code: $code';
  }

  @override
  String get inviteCopied => 'Invite copied – paste it into a message';

  @override
  String get updateAvailable => 'A new version of Goals is ready';

  @override
  String get updateInstall => 'Update';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get remindersEvening => 'End-of-day check';

  @override
  String remindersEveningSub(String time) {
    return 'At $time: what\'s still not logged today';
  }

  @override
  String get remindersMidday => 'Midday nudge';

  @override
  String remindersMiddaySub(String time) {
    return 'At $time: how many goals are still open';
  }

  @override
  String get remindersDenied =>
      'Notifications are off for this app. Turn them on in your phone settings.';

  @override
  String get remindersChannel => 'Reminders';

  @override
  String get reminderEveningTitle => 'End-of-day check';

  @override
  String reminderEveningBody(String goals) {
    return 'Still to log: $goals';
  }

  @override
  String get reminderEveningGeneric =>
      'How did today go? Confirm your goals before the day ends.';

  @override
  String get reminderMiddayTitle => 'Halfway through the day';

  @override
  String reminderMiddayBody(int count, String goals) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals still open',
      one: '1 goal still open',
    );
    return '$_temp0: $goals';
  }

  @override
  String get reminderMiddayGeneric =>
      'Quick check-in: how are today\'s goals going?';

  @override
  String get groupNewCode => 'Make a new invite code';

  @override
  String get groupNewCodeBody =>
      'The current code stops working. Share the new one with the people you still want to invite.';

  @override
  String get groupNewCodeConfirm => 'Make new code';

  @override
  String groupNewCodeDone(String code) {
    return 'New invite code: $code';
  }

  @override
  String get groupLeave => 'Leave the challenge';

  @override
  String get groupLeaveTitle => 'Leave the challenge?';

  @override
  String get groupLeaveBody =>
      'You\'ll stop seeing the group and they\'ll stop seeing your new entries. What you already shared stays in the group\'s history. You can join again with a code.';

  @override
  String get groupLeaveConfirm => 'Leave';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsInfo =>
      'Changes apply to everyone in the group from today on. Past days keep their results.';

  @override
  String get goalsDaily => 'Daily';

  @override
  String get goalsWeekly => 'Weekly';

  @override
  String get goalsAdd => 'Add goal';

  @override
  String get goalsSave => 'Save';

  @override
  String get goalsSaved => 'Goals updated for the group';

  @override
  String get goalsDiscardTitle => 'Discard your changes?';

  @override
  String get goalsDiscard => 'Discard';

  @override
  String get goalsKeepEditing => 'Keep editing';

  @override
  String get goalsEditTitle => 'Edit goal';

  @override
  String get goalsNewTitle => 'New goal';

  @override
  String get goalsIcon => 'Icon';

  @override
  String get goalsName => 'Name';

  @override
  String get goalsNameRequired => 'Give the goal a name';

  @override
  String get goalsKind => 'Type';

  @override
  String get goalsKindYesNo => 'Yes / no';

  @override
  String get goalsKindCount => 'Count';

  @override
  String get goalsKindMinutes => 'Minutes';

  @override
  String get goalsKindNumber => 'Number';

  @override
  String get goalsPeriod => 'How often';

  @override
  String get goalsRule => 'Rule';

  @override
  String get goalsAtLeast => 'At least';

  @override
  String get goalsAtMost => 'At most';

  @override
  String get goalsExactly => 'Exactly';

  @override
  String get goalsTarget => 'Target';

  @override
  String get goalsTargetInvalid => 'Enter a whole number above 0';

  @override
  String get goalsDelete => 'Delete goal';

  @override
  String goalsDeleteConfirm(String goal) {
    return 'Delete “$goal”? Past results stay.';
  }

  @override
  String get goalsWorkoutsTotal => 'Workouts per week';

  @override
  String get goalsWorkoutsRuns => 'Of them, runs';

  @override
  String get goalsWorkoutsStrength => 'Of them, strength';

  @override
  String get goalsWorkoutsMinutes => 'Minimum minutes each';

  @override
  String get goalsNeedOneDaily => 'Keep at least one daily goal';

  @override
  String goalsTooMany(int max) {
    return 'Up to $max goals';
  }

  @override
  String get goalsSummaryYesNo => 'Yes / no';

  @override
  String goalsSummaryAtLeast(String target) {
    return 'at least $target';
  }

  @override
  String goalsSummaryAtMost(String target) {
    return 'at most $target';
  }

  @override
  String goalsSummaryExactly(String target) {
    return 'exactly $target';
  }

  @override
  String goalsSummaryPerWeek(String summary) {
    return '$summary a week';
  }

  @override
  String get roundTitle => 'Start a new round';

  @override
  String get roundSubtitle => 'New dates for the same group and goals';

  @override
  String get roundStart => 'Start the round';

  @override
  String get roundStarted => 'A new round started';

  @override
  String get roundInfo =>
      'The new round replaces the current one right away. The board and streaks start fresh; past days keep their results.';

  @override
  String get boardYou => 'You';

  @override
  String get boardStreak => 'Streak';

  @override
  String get boardBestStreak => 'Best';

  @override
  String get boardAverage => 'Average';

  @override
  String boardDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String boardStreakHint(int percent) {
    return 'A streak counts days in a row with $percent%+ of the daily goals.';
  }

  @override
  String get boardLegend => 'Daily goals met';

  @override
  String get boardNoData => 'Nothing logged';

  @override
  String boardCellLabel(String date, String value) {
    return '$date: $value';
  }

  @override
  String get boardGoalRates => 'How often you met each goal';

  @override
  String get boardEmptyHint =>
      'Each day gets a color once you log goals: the more daily goals met, the darker the green. Tap a day to see its photos.';

  @override
  String get boardGoalRatesSoon => 'Shows up after your first full day.';

  @override
  String get boardNoPhotos => 'No photos that day';

  @override
  String boardNotStarted(String date) {
    return 'The challenge starts on $date';
  }

  @override
  String get weekTitle => 'This week';

  @override
  String weekPastTitle(String date) {
    return 'Week of $date';
  }

  @override
  String get weekPrev => 'Previous week';

  @override
  String get weekNext => 'Next week';

  @override
  String weekDone(int done, int total) {
    return '$done/$total';
  }

  @override
  String get workoutRun => 'Run';

  @override
  String get workoutStrength => 'Strength';

  @override
  String get workoutOther => 'Other';

  @override
  String get weekAddWorkout => 'Add workout';

  @override
  String weekMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String weekTooShort(int minutes) {
    return 'Under $minutes min – doesn\'t count';
  }

  @override
  String get weekNoWorkouts => 'No workouts logged this week';

  @override
  String get weekWorkoutType => 'Type';

  @override
  String get weekWorkoutDuration => 'Duration';

  @override
  String get weekWorkoutDay => 'Day';

  @override
  String get weekDeleteWorkout => 'Delete workout';

  @override
  String weekLimitTotal(int total, int limit) {
    return '$total this week · max $limit';
  }

  @override
  String weekOnDay(String day, int count) {
    return 'On $day: $count';
  }

  @override
  String get weekGroup => 'The group this week';

  @override
  String get weekSeeWeek => 'Open the week';

  @override
  String weekNeeds(String requirements) {
    return 'Needs: $requirements';
  }

  @override
  String weekMinMinutes(int minutes) {
    return 'at least $minutes min each';
  }

  @override
  String get shortcutLogWater => '+1 glass of water';

  @override
  String get shortcutAddPhoto => 'Add a photo';

  @override
  String shortcutWaterLogged(String icon, int value, int target) {
    return '$icon $value/$target – logged';
  }

  @override
  String get shortcutChooseGoal => 'Photo for which goal?';

  @override
  String get homeSection => 'Home screen';

  @override
  String get homeAddWidget => 'Add the widget';

  @override
  String get homeAddWidgetSubtitle =>
      'The group\'s photos and progress, without opening the app';

  @override
  String get homeAddWidgetManual =>
      'Long-press an empty spot on your home screen, tap Widgets, and find “Challenge photos”.';

  @override
  String get homeShortcutsHint =>
      'Tip: long-press the app icon for a quick +1 glass of water or a photo';

  @override
  String get homeInstallTitle => 'Add the app to your home screen';

  @override
  String get homeInstallIos =>
      'In Safari, tap Share (the square with the arrow), then “Add to Home Screen”.';

  @override
  String get homeInstallOther =>
      'Open the browser menu (⋮) and choose “Install app” or “Add to Home screen”.';

  @override
  String get homeInstallWhy =>
      'It opens full-screen, like a regular app – one tap away.';

  @override
  String get homeGotIt => 'Got it';

  @override
  String widgetTitle(String name, int percent) {
    return '$name · $percent% today';
  }

  @override
  String widgetGoalsDone(int met, int total) {
    return '$met/$total';
  }

  @override
  String widgetNoPhotos(String name) {
    return 'No photos from $name yet today';
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
      other: '$count photos today',
      one: '1 photo today',
      zero: 'No photos yet today',
    );
    return '$_temp0';
  }

  @override
  String get widgetNoPhotosGroup => 'No photos from the group yet today';

  @override
  String get photoAdd => 'Add a photo';

  @override
  String photoAddFor(String goal) {
    return 'Add a photo: $goal';
  }

  @override
  String get photoUploading => 'Uploading photo…';

  @override
  String get photoTakePhoto => 'Take photo';

  @override
  String get photoChooseFromGallery => 'Choose from gallery';

  @override
  String photoOpen(String goal, String time) {
    return 'Photo: $goal, $time';
  }

  @override
  String get photoPartnerPhotos => 'Today\'s photos';

  @override
  String photoYourReaction(String emoji) {
    return 'Your reaction: $emoji';
  }

  @override
  String photoReact(String emoji) {
    return 'React $emoji';
  }

  @override
  String photoPartnerReacted(String name, String emoji) {
    return '$name reacted $emoji';
  }

  @override
  String photoReactionSnack(String name, String emoji, String goalIcon) {
    return '$name reacted $emoji to your photo $goalIcon';
  }

  @override
  String get photoView => 'View';

  @override
  String get photoClose => 'Close';

  @override
  String get photoDelete => 'Delete photo';

  @override
  String get photoDeleteTitle => 'Delete this photo?';

  @override
  String get photoDeleteBody =>
      'It will disappear for both of you. This can\'t be undone.';

  @override
  String get photoDeleteConfirm => 'Delete';

  @override
  String get photoDeleted => 'Photo deleted';

  @override
  String get photoRetry => 'Retry';

  @override
  String get photoLoadFailed => 'Couldn\'t load the full photo';

  @override
  String get photoErrTooLarge => 'This photo is too large. Try another one';

  @override
  String photoErrLimit(int count) {
    return 'You\'ve reached the limit of $count photos a day';
  }

  @override
  String get photoErrUnreadable => 'Couldn\'t read this photo. Try another one';

  @override
  String get photoErrPicker => 'Couldn\'t open the camera or gallery';

  @override
  String todayClearedGoal(String goal) {
    return '$goal cleared';
  }

  @override
  String get todayUndo => 'Undo';

  @override
  String get todayGreetingMorning => 'Good morning';

  @override
  String get todayGreetingAfternoon => 'Good afternoon';

  @override
  String get todayGreetingEvening => 'Good evening';

  @override
  String get todayGreetingNight => 'Good night';

  @override
  String todayDayOfTotal(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String todayChallengeStartsIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The challenge starts in $count days',
      one: 'The challenge starts tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get todayChallengeEnded => 'Challenge complete 🏁';

  @override
  String todayMetCount(int met, int total) {
    return '$met of $total goals done';
  }

  @override
  String todayProgressSemantics(int percent) {
    return '$percent% of today\'s goals done';
  }

  @override
  String get todayAllDone => 'All of today\'s goals are done! 🎉';

  @override
  String get todayPartnerFallbackName => 'Member';

  @override
  String todayPartnerPercent(int percent) {
    return '$percent% today';
  }

  @override
  String get todayPartnerNothingYet => 'Nothing logged yet today';

  @override
  String todayGoalStatusSemantics(String goal, String status) {
    return '$goal: $status';
  }

  @override
  String get todayWaitingTitle => 'Invite people to your challenge';

  @override
  String get todayWaitingBody => 'Share this code so others can join:';

  @override
  String get todayYourGoals => 'Your goals';

  @override
  String todayDecrease(String goal) {
    return 'Decrease $goal';
  }

  @override
  String todayIncrease(String goal) {
    return 'Increase $goal';
  }

  @override
  String get todayNoneToday => 'None today ✓';

  @override
  String get todayKeptIt => 'Kept it ✓';

  @override
  String get todayDidnt => 'Didn\'t';

  @override
  String todayValueSteps(String value) {
    return '$value steps';
  }

  @override
  String todayValueMinutes(String value) {
    return '$value min';
  }

  @override
  String todayProgressOf(String value, String target) {
    return '$value / $target';
  }

  @override
  String todayAtMost(String target) {
    return 'max $target';
  }

  @override
  String get todayUnitSteps => 'steps';

  @override
  String get todayUnitMinutes => 'min';

  @override
  String get todayTapToEdit => 'Enter an exact value';

  @override
  String get todayEnterValueLabel => 'Value';

  @override
  String get todayInvalidNumber => 'Enter a whole number';

  @override
  String get todaySave => 'Save';

  @override
  String get todayCancel => 'Cancel';

  @override
  String get todayClear => 'Clear';

  @override
  String get todayDismiss => 'Dismiss';

  @override
  String get todayThisWeek => 'This week';

  @override
  String get todayNoChallengeTitle => 'No active challenge';

  @override
  String get todayNoChallengeBody =>
      'Start a new round from Settings to begin tracking.';

  @override
  String get todayNoDailyGoals => 'This round has no daily goals.';

  @override
  String get signOut => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get displayName => 'Your name';
}
