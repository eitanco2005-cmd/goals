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
  String get statusUnlogged => 'Not logged';

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
