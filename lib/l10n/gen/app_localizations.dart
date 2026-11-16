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
  /// **'Goals'**
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
  /// **'One challenge, together. Build healthy habits day by day and keep each other going.'**
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
  /// **'Start a new challenge and invite others, or join a challenge someone already started.'**
  String get pairIntro;

  /// No description provided for @pairCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new challenge'**
  String get pairCreateTitle;

  /// No description provided for @pairCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the dates and get a code to share'**
  String get pairCreateSubtitle;

  /// No description provided for @pairJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get pairJoinTitle;

  /// No description provided for @pairJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Got a code from someone? Enter it here'**
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
  /// **'Share this code with the people you want in the challenge (up to 8).'**
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

  /// No description provided for @settingsWaitingForPartner.
  ///
  /// In en, this message translates to:
  /// **'No one else has joined yet'**
  String get settingsWaitingForPartner;

  /// No description provided for @settingsMembers.
  ///
  /// In en, this message translates to:
  /// **'Members ({count}/{max})'**
  String settingsMembers(int count, int max);

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
  /// **'Demo mode – data is not saved. Join with code {code} to try it with a demo member.'**
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
  /// **'This challenge is full'**
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

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get statusOnTrack;

  /// No description provided for @settingsEditGoalsHint.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to the whole group'**
  String get settingsEditGoalsHint;

  /// No description provided for @goalsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get goalsUnit;

  /// No description provided for @goalsUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. pages, km'**
  String get goalsUnitHint;

  /// No description provided for @statusUnlogged.
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get statusUnlogged;

  /// No description provided for @goalsDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{goal}\" deleted'**
  String goalsDeleted(String goal);

  /// No description provided for @pairEditGoals.
  ///
  /// In en, this message translates to:
  /// **'Edit goals'**
  String get pairEditGoals;

  /// No description provided for @todayNeedsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo to complete this goal'**
  String get todayNeedsPhoto;

  /// No description provided for @todayNeedsPhotoShort.
  ///
  /// In en, this message translates to:
  /// **'Needs a photo'**
  String get todayNeedsPhotoShort;

  /// No description provided for @todayPhotoRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'📷 Counts only with a photo'**
  String get todayPhotoRequiredNote;

  /// No description provided for @goalsPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo required'**
  String get goalsPhotoRequired;

  /// No description provided for @goalsPhotoRequiredSub.
  ///
  /// In en, this message translates to:
  /// **'Counts as done only with a photo of it that day'**
  String get goalsPhotoRequiredSub;

  /// No description provided for @goalsSummaryPhoto.
  ///
  /// In en, this message translates to:
  /// **'📷 photo required'**
  String get goalsSummaryPhoto;

  /// No description provided for @inviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get inviteShare;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my challenge on Goals! {link}\nInvite code: {code}'**
  String inviteShareText(String link, String code);

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied – paste it into a message'**
  String get inviteCopied;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version of Goals is ready'**
  String get updateAvailable;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateInstall;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @remindersEvening.
  ///
  /// In en, this message translates to:
  /// **'End-of-day check'**
  String get remindersEvening;

  /// No description provided for @remindersEveningSub.
  ///
  /// In en, this message translates to:
  /// **'At {time}: what\'s still not logged today'**
  String remindersEveningSub(String time);

  /// No description provided for @remindersMidday.
  ///
  /// In en, this message translates to:
  /// **'Midday nudge'**
  String get remindersMidday;

  /// No description provided for @remindersMiddaySub.
  ///
  /// In en, this message translates to:
  /// **'At {time}: how many goals are still open'**
  String remindersMiddaySub(String time);

  /// No description provided for @remindersDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this app. Turn them on in your phone settings.'**
  String get remindersDenied;

  /// No description provided for @remindersChannel.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersChannel;

  /// No description provided for @reminderEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'End-of-day check'**
  String get reminderEveningTitle;

  /// No description provided for @reminderEveningBody.
  ///
  /// In en, this message translates to:
  /// **'Still to log: {goals}'**
  String reminderEveningBody(String goals);

  /// No description provided for @reminderEveningGeneric.
  ///
  /// In en, this message translates to:
  /// **'How did today go? Confirm your goals before the day ends.'**
  String get reminderEveningGeneric;

  /// No description provided for @reminderMiddayTitle.
  ///
  /// In en, this message translates to:
  /// **'Halfway through the day'**
  String get reminderMiddayTitle;

  /// No description provided for @reminderMiddayBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 goal still open} other{{count} goals still open}}: {goals}'**
  String reminderMiddayBody(int count, String goals);

  /// No description provided for @reminderMiddayGeneric.
  ///
  /// In en, this message translates to:
  /// **'Quick check-in: how are today\'s goals going?'**
  String get reminderMiddayGeneric;

  /// No description provided for @groupNewCode.
  ///
  /// In en, this message translates to:
  /// **'Make a new invite code'**
  String get groupNewCode;

  /// No description provided for @groupNewCodeBody.
  ///
  /// In en, this message translates to:
  /// **'The current code stops working. Share the new one with the people you still want to invite.'**
  String get groupNewCodeBody;

  /// No description provided for @groupNewCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make new code'**
  String get groupNewCodeConfirm;

  /// No description provided for @groupNewCodeDone.
  ///
  /// In en, this message translates to:
  /// **'New invite code: {code}'**
  String groupNewCodeDone(String code);

  /// No description provided for @groupLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave the challenge'**
  String get groupLeave;

  /// No description provided for @groupLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the challenge?'**
  String get groupLeaveTitle;

  /// No description provided for @groupLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop seeing the group and they\'ll stop seeing your new entries. What you already shared stays in the group\'s history. You can join again with a code.'**
  String get groupLeaveBody;

  /// No description provided for @groupLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupLeaveConfirm;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsInfo.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to everyone in the group from today on. Past days keep their results.'**
  String get goalsInfo;

  /// No description provided for @goalsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get goalsDaily;

  /// No description provided for @goalsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get goalsWeekly;

  /// No description provided for @goalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get goalsAdd;

  /// No description provided for @goalsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalsSave;

  /// No description provided for @goalsSaved.
  ///
  /// In en, this message translates to:
  /// **'Goals updated for the group'**
  String get goalsSaved;

  /// No description provided for @goalsDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get goalsDiscardTitle;

  /// No description provided for @goalsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get goalsDiscard;

  /// No description provided for @goalsKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get goalsKeepEditing;

  /// No description provided for @goalsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalsEditTitle;

  /// No description provided for @goalsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNewTitle;

  /// No description provided for @goalsIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goalsIcon;

  /// No description provided for @goalsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get goalsName;

  /// No description provided for @goalsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the goal a name'**
  String get goalsNameRequired;

  /// No description provided for @goalsKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get goalsKind;

  /// No description provided for @goalsKindYesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes / no'**
  String get goalsKindYesNo;

  /// No description provided for @goalsKindCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get goalsKindCount;

  /// No description provided for @goalsKindMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get goalsKindMinutes;

  /// No description provided for @goalsKindNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get goalsKindNumber;

  /// No description provided for @goalsPeriod.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get goalsPeriod;

  /// No description provided for @goalsRule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get goalsRule;

  /// No description provided for @goalsAtLeast.
  ///
  /// In en, this message translates to:
  /// **'At least'**
  String get goalsAtLeast;

  /// No description provided for @goalsAtMost.
  ///
  /// In en, this message translates to:
  /// **'At most'**
  String get goalsAtMost;

  /// No description provided for @goalsExactly.
  ///
  /// In en, this message translates to:
  /// **'Exactly'**
  String get goalsExactly;

  /// No description provided for @goalsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalsTarget;

  /// No description provided for @goalsTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number above 0'**
  String get goalsTargetInvalid;

  /// No description provided for @goalsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get goalsDelete;

  /// No description provided for @goalsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{goal}”? Past results stay.'**
  String goalsDeleteConfirm(String goal);

  /// No description provided for @goalsWorkoutsTotal.
  ///
  /// In en, this message translates to:
  /// **'Workouts per week'**
  String get goalsWorkoutsTotal;

  /// No description provided for @goalsWorkoutsRuns.
  ///
  /// In en, this message translates to:
  /// **'Of them, runs'**
  String get goalsWorkoutsRuns;

  /// No description provided for @goalsWorkoutsStrength.
  ///
  /// In en, this message translates to:
  /// **'Of them, strength'**
  String get goalsWorkoutsStrength;

  /// No description provided for @goalsWorkoutsMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minimum minutes each'**
  String get goalsWorkoutsMinutes;

  /// No description provided for @goalsNeedOneDaily.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one daily goal'**
  String get goalsNeedOneDaily;

  /// No description provided for @goalsTooMany.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} goals'**
  String goalsTooMany(int max);

  /// No description provided for @goalsSummaryYesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes / no'**
  String get goalsSummaryYesNo;

  /// No description provided for @goalsSummaryAtLeast.
  ///
  /// In en, this message translates to:
  /// **'at least {target}'**
  String goalsSummaryAtLeast(String target);

  /// No description provided for @goalsSummaryAtMost.
  ///
  /// In en, this message translates to:
  /// **'at most {target}'**
  String goalsSummaryAtMost(String target);

  /// No description provided for @goalsSummaryExactly.
  ///
  /// In en, this message translates to:
  /// **'exactly {target}'**
  String goalsSummaryExactly(String target);

  /// No description provided for @goalsSummaryPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{summary} a week'**
  String goalsSummaryPerWeek(String summary);

  /// No description provided for @roundTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new round'**
  String get roundTitle;

  /// No description provided for @roundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New dates for the same group and goals'**
  String get roundSubtitle;

  /// No description provided for @roundStart.
  ///
  /// In en, this message translates to:
  /// **'Start the round'**
  String get roundStart;

  /// No description provided for @roundStarted.
  ///
  /// In en, this message translates to:
  /// **'A new round started'**
  String get roundStarted;

  /// No description provided for @roundInfo.
  ///
  /// In en, this message translates to:
  /// **'The new round replaces the current one right away. The board and streaks start fresh; past days keep their results.'**
  String get roundInfo;

  /// No description provided for @boardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get boardYou;

  /// No description provided for @boardStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get boardStreak;

  /// No description provided for @boardBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get boardBestStreak;

  /// No description provided for @boardAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get boardAverage;

  /// No description provided for @boardDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String boardDays(int count);

  /// No description provided for @boardStreakHint.
  ///
  /// In en, this message translates to:
  /// **'A streak counts days in a row with {percent}%+ of the daily goals.'**
  String boardStreakHint(int percent);

  /// No description provided for @boardLegend.
  ///
  /// In en, this message translates to:
  /// **'Daily goals met'**
  String get boardLegend;

  /// No description provided for @boardNoData.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged'**
  String get boardNoData;

  /// No description provided for @boardCellLabel.
  ///
  /// In en, this message translates to:
  /// **'{date}: {value}'**
  String boardCellLabel(String date, String value);

  /// No description provided for @boardGoalRates.
  ///
  /// In en, this message translates to:
  /// **'How often you met each goal'**
  String get boardGoalRates;

  /// No description provided for @boardEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Each day gets a color once you log goals: the more daily goals met, the darker the green. Tap a day to see its photos.'**
  String get boardEmptyHint;

  /// No description provided for @boardGoalRatesSoon.
  ///
  /// In en, this message translates to:
  /// **'Shows up after your first full day.'**
  String get boardGoalRatesSoon;

  /// No description provided for @boardNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos that day'**
  String get boardNoPhotos;

  /// No description provided for @boardNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The challenge starts on {date}'**
  String boardNotStarted(String date);

  /// No description provided for @weekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get weekTitle;

  /// No description provided for @weekPastTitle.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekPastTitle(String date);

  /// No description provided for @weekPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get weekPrev;

  /// No description provided for @weekNext.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get weekNext;

  /// No description provided for @weekDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String weekDone(int done, int total);

  /// No description provided for @workoutRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get workoutRun;

  /// No description provided for @workoutStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get workoutStrength;

  /// No description provided for @workoutOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get workoutOther;

  /// No description provided for @weekAddWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add workout'**
  String get weekAddWorkout;

  /// No description provided for @weekMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String weekMinutes(int minutes);

  /// No description provided for @weekTooShort.
  ///
  /// In en, this message translates to:
  /// **'Under {minutes} min – doesn\'t count'**
  String weekTooShort(int minutes);

  /// No description provided for @weekNoWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged this week'**
  String get weekNoWorkouts;

  /// No description provided for @weekWorkoutType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get weekWorkoutType;

  /// No description provided for @weekWorkoutDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get weekWorkoutDuration;

  /// No description provided for @weekWorkoutDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get weekWorkoutDay;

  /// No description provided for @weekDeleteWorkout.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get weekDeleteWorkout;

  /// No description provided for @weekLimitTotal.
  ///
  /// In en, this message translates to:
  /// **'{total} this week · max {limit}'**
  String weekLimitTotal(int total, int limit);

  /// No description provided for @weekOnDay.
  ///
  /// In en, this message translates to:
  /// **'On {day}: {count}'**
  String weekOnDay(String day, int count);

  /// No description provided for @weekGroup.
  ///
  /// In en, this message translates to:
  /// **'The group this week'**
  String get weekGroup;

  /// No description provided for @weekSeeWeek.
  ///
  /// In en, this message translates to:
  /// **'Open the week'**
  String get weekSeeWeek;

  /// No description provided for @weekNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs: {requirements}'**
  String weekNeeds(String requirements);

  /// No description provided for @weekMinMinutes.
  ///
  /// In en, this message translates to:
  /// **'at least {minutes} min each'**
  String weekMinMinutes(int minutes);

  /// No description provided for @shortcutLogWater.
  ///
  /// In en, this message translates to:
  /// **'+1 glass of water'**
  String get shortcutLogWater;

  /// No description provided for @shortcutAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get shortcutAddPhoto;

  /// No description provided for @shortcutWaterLogged.
  ///
  /// In en, this message translates to:
  /// **'{icon} {value}/{target} – logged'**
  String shortcutWaterLogged(String icon, int value, int target);

  /// No description provided for @shortcutChooseGoal.
  ///
  /// In en, this message translates to:
  /// **'Photo for which goal?'**
  String get shortcutChooseGoal;

  /// No description provided for @homeSection.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get homeSection;

  /// No description provided for @homeAddWidget.
  ///
  /// In en, this message translates to:
  /// **'Add the widget'**
  String get homeAddWidget;

  /// No description provided for @homeAddWidgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The group\'s photos and progress, without opening the app'**
  String get homeAddWidgetSubtitle;

  /// No description provided for @homeAddWidgetManual.
  ///
  /// In en, this message translates to:
  /// **'Long-press an empty spot on your home screen, tap Widgets, and find “Challenge photos”.'**
  String get homeAddWidgetManual;

  /// No description provided for @homeShortcutsHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: long-press the app icon for a quick +1 glass of water or a photo'**
  String get homeShortcutsHint;

  /// No description provided for @homeInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Add the app to your home screen'**
  String get homeInstallTitle;

  /// No description provided for @homeInstallIos.
  ///
  /// In en, this message translates to:
  /// **'In Safari, tap Share (the square with the arrow), then “Add to Home Screen”.'**
  String get homeInstallIos;

  /// No description provided for @homeInstallOther.
  ///
  /// In en, this message translates to:
  /// **'Open the browser menu (⋮) and choose “Install app” or “Add to Home screen”.'**
  String get homeInstallOther;

  /// No description provided for @homeInstallWhy.
  ///
  /// In en, this message translates to:
  /// **'It opens full-screen, like a regular app – one tap away.'**
  String get homeInstallWhy;

  /// No description provided for @homeGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get homeGotIt;

  /// No description provided for @widgetTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} · {percent}% today'**
  String widgetTitle(String name, int percent);

  /// No description provided for @widgetGoalsDone.
  ///
  /// In en, this message translates to:
  /// **'{met}/{total}'**
  String widgetGoalsDone(int met, int total);

  /// No description provided for @widgetNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos from {name} yet today'**
  String widgetNoPhotos(String name);

  /// No description provided for @widgetMemberPercent.
  ///
  /// In en, this message translates to:
  /// **'{name} {percent}%'**
  String widgetMemberPercent(String name, int percent);

  /// No description provided for @widgetGroupPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos yet today} =1{1 photo today} other{{count} photos today}}'**
  String widgetGroupPhotos(int count);

  /// No description provided for @widgetNoPhotosGroup.
  ///
  /// In en, this message translates to:
  /// **'No photos from the group yet today'**
  String get widgetNoPhotosGroup;

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
  /// **'Member'**
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
  /// **'Invite people to your challenge'**
  String get todayWaitingTitle;

  /// No description provided for @todayWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code so others can join:'**
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
