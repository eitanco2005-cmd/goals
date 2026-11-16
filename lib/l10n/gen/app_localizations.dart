import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Challenge'**
  String get appTitle;

  /// No description provided for @sessionNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name can be at most {max} characters'**
  String sessionNameTooLong(int max);

  /// No description provided for @sessionStuckMessage.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than expected. Check your connection and try again.'**
  String get sessionStuckMessage;

  /// No description provided for @sessionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sessionTryAgain;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Two people, one challenge. Build healthy habits together, one day at a time.'**
  String get authTagline;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authNameHint.
  ///
  /// In en, this message translates to:
  /// **'This is how you\'ll appear in the challenge'**
  String get authNameHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get authPasswordHint;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a password reset link to {email}'**
  String authResetSent(String email);

  /// No description provided for @authResetNeedsEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email above, then tap “Forgot password?” again'**
  String get authResetNeedsEmail;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInButton;

  /// No description provided for @authSignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get authNoAccount;

  /// No description provided for @authGoToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authGoToSignUp;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authGoToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authGoToSignIn;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEmailRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authNameRequired;

  /// No description provided for @pairWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! Let\'s get started'**
  String pairWelcome(String name);

  /// No description provided for @pairIntro.
  ///
  /// In en, this message translates to:
  /// **'Start a new challenge and invite your partner, or join the challenge your partner already started.'**
  String get pairIntro;

  /// No description provided for @pairCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new challenge'**
  String get pairCreateTitle;

  /// No description provided for @pairCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the dates and get a code to send your partner'**
  String get pairCreateSubtitle;

  /// No description provided for @pairJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get pairJoinTitle;

  /// No description provided for @pairJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your partner already started? Enter their code'**
  String get pairJoinSubtitle;

  /// No description provided for @pairStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get pairStartDate;

  /// No description provided for @pairEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get pairEndDate;

  /// No description provided for @pairLength.
  ///
  /// In en, this message translates to:
  /// **'Challenge length'**
  String get pairLength;

  /// No description provided for @pairDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String pairDays(int count);

  /// No description provided for @pairCustomLength.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get pairCustomLength;

  /// No description provided for @pairGoalsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Goals included'**
  String get pairGoalsIncluded;

  /// No description provided for @pairDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get pairDailyGoals;

  /// No description provided for @pairWeeklyGoals.
  ///
  /// In en, this message translates to:
  /// **'Weekly goals'**
  String get pairWeeklyGoals;

  /// No description provided for @pairGoalsEditLater.
  ///
  /// In en, this message translates to:
  /// **'You can edit the goals later.'**
  String get pairGoalsEditLater;

  /// No description provided for @pairCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get pairCreateButton;

  /// No description provided for @pairCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get pairCodeLabel;

  /// No description provided for @pairCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6 letters and numbers'**
  String get pairCodeHint;

  /// No description provided for @pairCodeLength.
  ///
  /// In en, this message translates to:
  /// **'The code has 6 characters'**
  String get pairCodeLength;

  /// No description provided for @pairJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join challenge'**
  String get pairJoinButton;

  /// No description provided for @pairInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get pairInviteTitle;

  /// No description provided for @pairInviteExplain.
  ///
  /// In en, this message translates to:
  /// **'Send this code to your partner so they can join the challenge.'**
  String get pairInviteExplain;

  /// No description provided for @pairCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get pairCopy;

  /// No description provided for @pairCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get pairCopyCode;

  /// No description provided for @pairCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get pairCopied;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get settingsEditName;

  /// No description provided for @settingsChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get settingsChallenge;

  /// No description provided for @settingsPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get settingsPartner;

  /// No description provided for @settingsWaitingForPartner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner to join'**
  String get settingsWaitingForPartner;

  /// No description provided for @settingsDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get settingsDates;

  /// No description provided for @settingsDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String settingsDateRange(String start, String end);

  /// No description provided for @settingsDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String settingsDayOf(int day, int total);

  /// No description provided for @settingsEditGoals.
  ///
  /// In en, this message translates to:
  /// **'Edit goals'**
  String get settingsEditGoals;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime with your email and password.'**
  String get settingsSignOutConfirmBody;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get navWeek;

  /// No description provided for @navBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get navBoard;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get languageHebrew;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode – data is not saved. Join code {code} to pair with a demo partner.'**
  String demoModeBanner(String code);

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errWeakPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get errInvalidEmail;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'No challenge found with this code'**
  String get errInvalidCode;

  /// No description provided for @errPairFull.
  ///
  /// In en, this message translates to:
  /// **'This challenge already has two people'**
  String get errPairFull;

  /// No description provided for @errAlreadyPaired.
  ///
  /// In en, this message translates to:
  /// **'You are already in a challenge'**
  String get errAlreadyPaired;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again'**
  String get errNetwork;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get errUnknown;

  /// No description provided for @statusMet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusMet;

  /// No description provided for @statusNotMet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get statusNotMet;

  /// No description provided for @statusUnlogged.
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get statusUnlogged;

  /// No description provided for @photoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get photoAdd;

  /// No description provided for @photoAddFor.
  ///
  /// In en, this message translates to:
  /// **'Add a photo: {goal}'**
  String photoAddFor(String goal);

  /// No description provided for @photoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get photoUploading;

  /// No description provided for @photoTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoTakePhoto;

  /// No description provided for @photoChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoChooseFromGallery;

  /// No description provided for @photoOpen.
  ///
  /// In en, this message translates to:
  /// **'Photo: {goal}, {time}'**
  String photoOpen(String goal, String time);

  /// No description provided for @photoPartnerPhotos.
  ///
  /// In en, this message translates to:
  /// **'Today\'s photos'**
  String get photoPartnerPhotos;

  /// No description provided for @photoYourReaction.
  ///
  /// In en, this message translates to:
  /// **'Your reaction: {emoji}'**
  String photoYourReaction(String emoji);

  /// No description provided for @photoReact.
  ///
  /// In en, this message translates to:
  /// **'React {emoji}'**
  String photoReact(String emoji);

  /// No description provided for @photoPartnerReacted.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted {emoji}'**
  String photoPartnerReacted(String name, String emoji);

  /// No description provided for @photoReactionSnack.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted {emoji} to your photo {goalIcon}'**
  String photoReactionSnack(String name, String emoji, String goalIcon);

  /// No description provided for @photoView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get photoView;

  /// No description provided for @photoClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get photoClose;

  /// No description provided for @photoDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get photoDelete;

  /// No description provided for @photoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get photoDeleteTitle;

  /// No description provided for @photoDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will disappear for both of you. This can\'t be undone.'**
  String get photoDeleteBody;

  /// No description provided for @photoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get photoDeleteConfirm;

  /// No description provided for @photoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photoDeleted;

  /// No description provided for @photoRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get photoRetry;

  /// No description provided for @photoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the full photo'**
  String get photoLoadFailed;

  /// No description provided for @photoErrTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This photo is too large. Try another one'**
  String get photoErrTooLarge;

  /// No description provided for @photoErrLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit of {count} photos a day'**
  String photoErrLimit(int count);

  /// No description provided for @photoErrUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this photo. Try another one'**
  String get photoErrUnreadable;

  /// No description provided for @photoErrPicker.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera or gallery'**
  String get photoErrPicker;

  /// No description provided for @todayClearedGoal.
  ///
  /// In en, this message translates to:
  /// **'{goal} cleared'**
  String todayClearedGoal(String goal);

  /// No description provided for @todayUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get todayUndo;

  /// No description provided for @todayGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get todayGreetingMorning;

  /// No description provided for @todayGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get todayGreetingAfternoon;

  /// No description provided for @todayGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get todayGreetingEvening;

  /// No description provided for @todayGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get todayGreetingNight;

  /// No description provided for @todayDayOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String todayDayOfTotal(int day, int total);

  /// No description provided for @todayChallengeStartsIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The challenge starts tomorrow} other{The challenge starts in {count} days}}'**
  String todayChallengeStartsIn(int count);

  /// No description provided for @todayChallengeEnded.
  ///
  /// In en, this message translates to:
  /// **'Challenge complete 🏁'**
  String get todayChallengeEnded;

  /// No description provided for @todayMetCount.
  ///
  /// In en, this message translates to:
  /// **'{met} of {total} goals done'**
  String todayMetCount(int met, int total);

  /// No description provided for @todayProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of today\'s goals done'**
  String todayProgressSemantics(int percent);

  /// No description provided for @todayAllDone.
  ///
  /// In en, this message translates to:
  /// **'All of today\'s goals are done! 🎉'**
  String get todayAllDone;

  /// No description provided for @todayPartnerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Your partner'**
  String get todayPartnerFallbackName;

  /// No description provided for @todayPartnerPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% today'**
  String todayPartnerPercent(int percent);

  /// No description provided for @todayPartnerNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet today'**
  String get todayPartnerNothingYet;

  /// No description provided for @todayGoalStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'{goal}: {status}'**
  String todayGoalStatusSemantics(String goal, String status);

  /// No description provided for @todayWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner'**
  String get todayWaitingTitle;

  /// No description provided for @todayWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Send them this code so they can join your challenge:'**
  String get todayWaitingBody;

  /// No description provided for @todayYourGoals.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get todayYourGoals;

  /// No description provided for @todayDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease {goal}'**
  String todayDecrease(String goal);

  /// No description provided for @todayIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase {goal}'**
  String todayIncrease(String goal);

  /// No description provided for @todayNoneToday.
  ///
  /// In en, this message translates to:
  /// **'None today ✓'**
  String get todayNoneToday;

  /// No description provided for @todayKeptIt.
  ///
  /// In en, this message translates to:
  /// **'Kept it ✓'**
  String get todayKeptIt;

  /// No description provided for @todayDidnt.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t'**
  String get todayDidnt;

  /// No description provided for @todayValueSteps.
  ///
  /// In en, this message translates to:
  /// **'{value} steps'**
  String todayValueSteps(String value);

  /// No description provided for @todayValueMinutes.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String todayValueMinutes(String value);

  /// No description provided for @todayProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{value} / {target}'**
  String todayProgressOf(String value, String target);

  /// No description provided for @todayAtMost.
  ///
  /// In en, this message translates to:
  /// **'max {target}'**
  String todayAtMost(String target);

  /// No description provided for @todayUnitSteps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get todayUnitSteps;

  /// No description provided for @todayUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get todayUnitMinutes;

  /// No description provided for @todayTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Enter an exact value'**
  String get todayTapToEdit;

  /// No description provided for @todayEnterValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get todayEnterValueLabel;

  /// No description provided for @todayInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get todayInvalidNumber;

  /// No description provided for @todaySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get todaySave;

  /// No description provided for @todayCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get todayCancel;

  /// No description provided for @todayClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get todayClear;

  /// No description provided for @todayDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get todayDismiss;

  /// No description provided for @todayThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get todayThisWeek;

  /// No description provided for @todayNoChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'No active challenge'**
  String get todayNoChallengeTitle;

  /// No description provided for @todayNoChallengeBody.
  ///
  /// In en, this message translates to:
  /// **'Start a new round from Settings to begin tracking.'**
  String get todayNoChallengeBody;

  /// No description provided for @todayNoDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'This round has no daily goals.'**
  String get todayNoDailyGoals;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
