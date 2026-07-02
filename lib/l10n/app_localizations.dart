import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('fr'),
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Management area'**
  String get loginEyebrow;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your school\'s dashboard.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// No description provided for @loginSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get loginSubmitting;

  /// No description provided for @loginSignature.
  ///
  /// In en, this message translates to:
  /// **'eteyelo · the school, in Lingala'**
  String get loginSignature;

  /// No description provided for @loginBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'The Congolese school, now digital.'**
  String get loginBrandTitle;

  /// No description provided for @loginBrandTitleCondensed.
  ///
  /// In en, this message translates to:
  /// **'The school, now digital.'**
  String get loginBrandTitleCondensed;

  /// No description provided for @loginBrandTitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'digital'**
  String get loginBrandTitleHighlight;

  /// No description provided for @loginBrandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Registrations, finances, classes and attendance — one app, on every screen.'**
  String get loginBrandSubtitle;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required.'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get loginPasswordRequired;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Check your credentials and try again.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network.'**
  String get loginErrorNetwork;

  /// No description provided for @loginErrorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account disabled. Contact your school administrator.'**
  String get loginErrorAccountDisabled;

  /// No description provided for @loginErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again shortly.'**
  String get loginErrorServer;

  /// 429 error banner — temporary lockout with countdown
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s'**
  String loginErrorRateLimited(int seconds);

  /// No description provided for @loginContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact the administrator'**
  String get loginContactAdmin;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePassword;

  /// No description provided for @schoolApp.
  ///
  /// In en, this message translates to:
  /// **'ETEELO CONNECT'**
  String get schoolApp;

  /// No description provided for @splashBrandPrimary.
  ///
  /// In en, this message translates to:
  /// **'ETEELO'**
  String get splashBrandPrimary;

  /// No description provided for @splashBrandSecondary.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get splashBrandSecondary;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Simplify your school management'**
  String get splashTagline;

  /// No description provided for @splashSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'ETEELO CONNECT — splash screen'**
  String get splashSemanticsLabel;

  /// No description provided for @bootstrapOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline mode — cached data'**
  String get bootstrapOfflineBanner;

  /// No description provided for @splashErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get splashErrorTitle;

  /// No description provided for @splashErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the application data. Check your connection, then try again.'**
  String get splashErrorMessage;

  /// No description provided for @splashErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get splashErrorRetry;

  /// Technical version shown in the splash footer
  ///
  /// In en, this message translates to:
  /// **'v{version} (build {build})'**
  String splashVersion(String version, String build);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome{name}!'**
  String welcome(String name);

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @receiveOtp.
  ///
  /// In en, this message translates to:
  /// **'Receive an OTP code'**
  String get receiveOtp;

  /// No description provided for @enterEmailToReceiveOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a verification code.'**
  String get enterEmailToReceiveOtp;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @otpValidation.
  ///
  /// In en, this message translates to:
  /// **'OTP Validation'**
  String get otpValidation;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String codeSentTo(String email);

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCodeLabel;

  /// No description provided for @validateCode.
  ///
  /// In en, this message translates to:
  /// **'Validate code'**
  String get validateCode;

  /// No description provided for @otpMustBeSixDigits.
  ///
  /// In en, this message translates to:
  /// **'OTP code must contain 6 digits'**
  String get otpMustBeSixDigits;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @chooseNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get chooseNewPassword;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account: {email}'**
  String account(String email);

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @validateAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Validate and Login'**
  String get validateAndLogin;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Confirm password validation message
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @resetEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get resetEyebrow;

  /// No description provided for @resetBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover your access securely.'**
  String get resetBrandTitle;

  /// No description provided for @resetBrandTitleCondensed.
  ///
  /// In en, this message translates to:
  /// **'Account access recovery.'**
  String get resetBrandTitleCondensed;

  /// No description provided for @resetBrandTitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'access'**
  String get resetBrandTitleHighlight;

  /// No description provided for @resetBrandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password safely.'**
  String get resetBrandSubtitle;

  /// No description provided for @resetStepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · {label}'**
  String resetStepIndicator(int step, int total, String label);

  /// No description provided for @resetStepLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get resetStepLabelEmail;

  /// No description provided for @resetStepLabelCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get resetStepLabelCode;

  /// No description provided for @resetStepLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetStepLabelPassword;

  /// No description provided for @resetBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get resetBackToLogin;

  /// Inscriptions menu title
  ///
  /// In en, this message translates to:
  /// **'Registrations'**
  String get menuInscriptions;

  /// Finances menu title
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get menuFinances;

  /// Classes menu title
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get menuClasses;

  /// Disciplines menu title
  ///
  /// In en, this message translates to:
  /// **'Disciplines'**
  String get menuDisciplines;

  /// Dashboard sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get subMenuDashboard;

  /// Pre-registrations sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Pre-Registrations'**
  String get subMenuPreRegistrations;

  /// Re-registrations sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Re-Registrations'**
  String get subMenuReRegistrations;

  /// First registration sub-menu title
  ///
  /// In en, this message translates to:
  /// **'First Registration'**
  String get subMenuFirstRegistration;

  /// Billing sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get subMenuBilling;

  /// Organization sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Class\ncomposition'**
  String get subMenuOrganization;

  /// No description provided for @classesOrganisationHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Class composition'**
  String get classesOrganisationHeroTitle;

  /// No description provided for @classesOrganisationHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Distribute students from one level into sub-classes (e.g. Grade 1 A, Grade 1 B, Grade 1 C) and view the student list for each sub-class.'**
  String get classesOrganisationHeroSubtitle;

  /// No description provided for @classesOrganisationSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Level selection for class distribution'**
  String get classesOrganisationSearchTitle;

  /// No description provided for @classesOrganisationHeaderEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Class composition · Year {schoolYear}'**
  String classesOrganisationHeaderEyebrow(String schoolYear);

  /// No description provided for @classesOrganisationLevelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a cycle first'**
  String get classesOrganisationLevelPlaceholder;

  /// No description provided for @classesOrganisationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Select the cycle and level to organize, then run the search to view the current distribution or prepare sub-class distribution.'**
  String get classesOrganisationSearchHint;

  /// No description provided for @classesOrganisationClassroomFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get classesOrganisationClassroomFieldLabel;

  /// No description provided for @classesOrganisationDistributionLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution criterion'**
  String get classesOrganisationDistributionLabel;

  /// No description provided for @classesOrganisationDistributionByGender.
  ///
  /// In en, this message translates to:
  /// **'Distribute by gender'**
  String get classesOrganisationDistributionByGender;

  /// No description provided for @classesOrganisationDistributionByPercentage.
  ///
  /// In en, this message translates to:
  /// **'Distribute by average'**
  String get classesOrganisationDistributionByPercentage;

  /// No description provided for @classesOrganisationDistributeByGenderAction.
  ///
  /// In en, this message translates to:
  /// **'Start gender-based distribution'**
  String get classesOrganisationDistributeByGenderAction;

  /// No description provided for @classesDistributionResultEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Gender distribution'**
  String get classesDistributionResultEyebrow;

  /// No description provided for @classesDistributionProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution in progress…'**
  String get classesDistributionProcessingTitle;

  /// No description provided for @classesDistributionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution complete'**
  String get classesDistributionSuccessTitle;

  /// No description provided for @classesDistributionSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students were evenly distributed by gender.'**
  String get classesDistributionSuccessSubtitle;

  /// No description provided for @classesDistributionRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Headcount per class'**
  String get classesDistributionRecapTitle;

  /// No description provided for @classesDistributionClassHeadcount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String classesDistributionClassHeadcount(int count);

  /// No description provided for @classesDistributionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution failed'**
  String get classesDistributionErrorTitle;

  /// No description provided for @classesDistributionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The classes were left intact. You can try again.'**
  String get classesDistributionErrorMessage;

  /// No description provided for @classesDistributionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get classesDistributionRetry;

  /// No description provided for @classesDistributionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get classesDistributionClose;

  /// No description provided for @classesDistributionKpiHeadcount.
  ///
  /// In en, this message translates to:
  /// **'Headcount'**
  String get classesDistributionKpiHeadcount;

  /// No description provided for @classesDistributionKpiClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesDistributionKpiClasses;

  /// No description provided for @classesDistributionKpiBoys.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get classesDistributionKpiBoys;

  /// No description provided for @classesDistributionKpiGirls.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get classesDistributionKpiGirls;

  /// No description provided for @classesDistributionViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get classesDistributionViewGrid;

  /// No description provided for @classesDistributionViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get classesDistributionViewList;

  /// No description provided for @classesDistributionClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Class {code}'**
  String classesDistributionClassLabel(String code);

  /// No description provided for @classesDistributionClassCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count} students · capacity {capacity}'**
  String classesDistributionClassCapacity(int count, int capacity);

  /// No description provided for @classesDistributionCapacityFull.
  ///
  /// In en, this message translates to:
  /// **'full'**
  String get classesDistributionCapacityFull;

  /// No description provided for @classesOrganisationDistributionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Distribution completed successfully.'**
  String get classesOrganisationDistributionSuccess;

  /// No description provided for @classesOrganisationSplitInfo.
  ///
  /// In en, this message translates to:
  /// **'Split mode enabled: classroom grid with members and stats.'**
  String get classesOrganisationSplitInfo;

  /// No description provided for @classesOrganisationNonSplitInfo.
  ///
  /// In en, this message translates to:
  /// **'Non-split mode enabled: student list for the selected level.'**
  String get classesOrganisationNonSplitInfo;

  /// No description provided for @classesOrganisationLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading classes…'**
  String get classesOrganisationLoadingTitle;

  /// No description provided for @classesOrganisationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No student to distribute'**
  String get classesOrganisationEmptyTitle;

  /// No description provided for @classesOrganisationEmptyInvite.
  ///
  /// In en, this message translates to:
  /// **'Enroll students in this level to start the distribution.'**
  String get classesOrganisationEmptyInvite;

  /// No description provided for @classesOrganisationOverviewErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get classesOrganisationOverviewErrorTitle;

  /// No description provided for @classesOrganisationTransferDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer student'**
  String get classesOrganisationTransferDialogTitle;

  /// No description provided for @classesReassignCurrentClassState.
  ///
  /// In en, this message translates to:
  /// **'Current class'**
  String get classesReassignCurrentClassState;

  /// No description provided for @classesReassignUnassignedState.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get classesReassignUnassignedState;

  /// No description provided for @classesReassignCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get classesReassignCurrentBadge;

  /// No description provided for @classesReassignFullBadge.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get classesReassignFullBadge;

  /// No description provided for @classesReassignOptionStats.
  ///
  /// In en, this message translates to:
  /// **'{eff}/{cap} · B {boys} · G {girls}'**
  String classesReassignOptionStats(int eff, int cap, int boys, int girls);

  /// No description provided for @classesOrganisationTransferAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get classesOrganisationTransferAction;

  /// No description provided for @classesOrganisationTransferInProgress.
  ///
  /// In en, this message translates to:
  /// **'Transfer in progress...'**
  String get classesOrganisationTransferInProgress;

  /// No description provided for @classesOrganisationTransferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed successfully.'**
  String get classesOrganisationTransferSuccess;

  /// No description provided for @classesOrganisationTransferNoTarget.
  ///
  /// In en, this message translates to:
  /// **'No destination classroom is available.'**
  String get classesOrganisationTransferNoTarget;

  /// No description provided for @classesOrganisationSelectCycleAndLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a cycle and a level'**
  String get classesOrganisationSelectCycleAndLevelTitle;

  /// No description provided for @classesOrganisationSelectCycleAndLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start by selecting a cycle, then a level to display class composition.'**
  String get classesOrganisationSelectCycleAndLevelSubtitle;

  /// No description provided for @classesOrganisationSelectLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a level'**
  String get classesOrganisationSelectLevelTitle;

  /// No description provided for @classesOrganisationSelectLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Now select a level in the {cycleName} cycle.'**
  String classesOrganisationSelectLevelSubtitle(String cycleName);

  /// No description provided for @classesOrganisationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Level not distributed yet'**
  String get classesOrganisationPendingTitle;

  /// No description provided for @classesOrganisationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} students in {levelName} aren\'\'t assigned to any class. Automatic distribution balances the classes by gender.'**
  String classesOrganisationPendingMessage(int count, String levelName);

  /// No description provided for @classesOrganisationPendingStudentsToDistribute.
  ///
  /// In en, this message translates to:
  /// **'{count} students to distribute'**
  String classesOrganisationPendingStudentsToDistribute(int count);

  /// No description provided for @classesOrganisationGenderBoysPill.
  ///
  /// In en, this message translates to:
  /// **'B · {count}'**
  String classesOrganisationGenderBoysPill(int count);

  /// No description provided for @classesOrganisationGenderGirlsPill.
  ///
  /// In en, this message translates to:
  /// **'G · {count}'**
  String classesOrganisationGenderGirlsPill(int count);

  /// No description provided for @classesOrganisationUnassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unassigned students'**
  String get classesOrganisationUnassignedTitle;

  /// No description provided for @classesOrganisationUnassignedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New arrivals, cancelled transfers…'**
  String get classesOrganisationUnassignedSubtitle;

  /// No description provided for @classesOrganisationUnassignedBadge.
  ///
  /// In en, this message translates to:
  /// **'To assign'**
  String get classesOrganisationUnassignedBadge;

  /// No description provided for @classesOrganisationNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No student in this classroom.'**
  String get classesOrganisationNoMembers;

  /// No description provided for @classesOrganisationAssignAction.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get classesOrganisationAssignAction;

  /// No description provided for @classesOrganisationAssignDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign the student'**
  String get classesOrganisationAssignDialogTitle;

  /// No description provided for @classesOrganisationLoadingClassroomsCount.
  ///
  /// In en, this message translates to:
  /// **'Loading members for {count} classrooms...'**
  String classesOrganisationLoadingClassroomsCount(int count);

  /// No description provided for @classesOrganisationStudentDetailSoon.
  ///
  /// In en, this message translates to:
  /// **'Student details will be available in the next batch.'**
  String get classesOrganisationStudentDetailSoon;

  /// No description provided for @classesOrganisationErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get classesOrganisationErrorNetwork;

  /// No description provided for @classesOrganisationErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'No data found for these criteria.'**
  String get classesOrganisationErrorNotFound;

  /// No description provided for @classesOrganisationErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some entered information is invalid.'**
  String get classesOrganisationErrorValidation;

  /// No description provided for @classesOrganisationErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Access is not authorized.'**
  String get classesOrganisationErrorUnauthorized;

  /// No description provided for @classesOrganisationErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials.'**
  String get classesOrganisationErrorInvalidCredentials;

  /// No description provided for @classesOrganisationErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error, try again later.'**
  String get classesOrganisationErrorServer;

  /// No description provided for @classesOrganisationErrorStorage.
  ///
  /// In en, this message translates to:
  /// **'Local storage error.'**
  String get classesOrganisationErrorStorage;

  /// No description provided for @classesOrganisationErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Session is not valid, please sign in again.'**
  String get classesOrganisationErrorAuth;

  /// No description provided for @classesOrganisationErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get classesOrganisationErrorUnknown;

  /// No description provided for @classesListSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search form'**
  String get classesListSearchTitle;

  /// No description provided for @classesListSearchHint.
  ///
  /// In en, this message translates to:
  /// **''**
  String get classesListSearchHint;

  /// No description provided for @classesListClassroomOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Classroom (optional)'**
  String get classesListClassroomOptionalLabel;

  /// No description provided for @classesListFirstNameOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'First name (optional)'**
  String get classesListFirstNameOptionalLabel;

  /// No description provided for @classesListLastNameOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name (optional)'**
  String get classesListLastNameOptionalLabel;

  /// No description provided for @classesListSurnameOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Surname (optional)'**
  String get classesListSurnameOptionalLabel;

  /// No description provided for @classesListInitialEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No search in progress'**
  String get classesListInitialEmptyTitle;

  /// No description provided for @classesListInitialEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Fill in at least one criterion to display students.'**
  String get classesListInitialEmptyMessage;

  /// No description provided for @classesListNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No student matches the criteria'**
  String get classesListNoMatchTitle;

  /// No description provided for @classesListNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try broadening your filters or adjusting your search.'**
  String get classesListNoMatchMessage;

  /// No description provided for @classesListResultsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} students found — {criteria}'**
  String classesListResultsSummary(int count, String criteria);

  /// No description provided for @classesListResultsSummaryWithoutCriteria.
  ///
  /// In en, this message translates to:
  /// **'{count} students found'**
  String classesListResultsSummaryWithoutCriteria(int count);

  /// No description provided for @classesListClassroomChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get classesListClassroomChipLabel;

  /// No description provided for @classesListLoadingClassroomMembers.
  ///
  /// In en, this message translates to:
  /// **'Loading classroom members...'**
  String get classesListLoadingClassroomMembers;

  /// No description provided for @classesListClassroomEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No student is currently assigned to this classroom.'**
  String get classesListClassroomEmptyMessage;

  /// No description provided for @classesListClassroomFilteredEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No student in this classroom matches the entered filters.'**
  String get classesListClassroomFilteredEmptyMessage;

  /// No description provided for @classesListStudentDetailSoon.
  ///
  /// In en, this message translates to:
  /// **'Student details will be available in a future release.'**
  String get classesListStudentDetailSoon;

  /// No description provided for @classesListExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export copied to clipboard.'**
  String get classesListExportSuccess;

  /// No description provided for @classesListExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare the export right now.'**
  String get classesListExportFailed;

  /// No description provided for @classesListExportNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'There is no data to export for this search.'**
  String get classesListExportNothingToExport;

  /// No description provided for @classesListExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get classesListExportPdf;

  /// Classes list sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Class lists'**
  String get subMenuClassesList;

  /// Attendance sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get subMenuAttendance;

  /// Disciplines list sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Disciplines List'**
  String get subMenuDisciplinesList;

  /// No description provided for @menuCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get menuCourses;

  /// No description provided for @subMenuMyCourses.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get subMenuMyCourses;

  /// No description provided for @myCoursesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get myCoursesEyebrow;

  /// No description provided for @myCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get myCoursesTitle;

  /// No description provided for @myCoursesCount.
  ///
  /// In en, this message translates to:
  /// **'{classCount, plural, =1{1 class} other{{classCount} classes}} · {courseCount, plural, =1{1 course} other{{courseCount} courses}}'**
  String myCoursesCount(int classCount, int courseCount);

  /// No description provided for @myCoursesExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get myCoursesExpandAll;

  /// No description provided for @myCoursesCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get myCoursesCollapseAll;

  /// No description provided for @myCoursesClassCourseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 course} other{{count} courses}}'**
  String myCoursesClassCourseCount(int count);

  /// No description provided for @myCoursesStudentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No students} =1{1 student} other{{count} students}}'**
  String myCoursesStudentCount(int count);

  /// No description provided for @myCoursesLoadingA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading your courses'**
  String get myCoursesLoadingA11yLabel;

  /// No description provided for @myCoursesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No course assigned'**
  String get myCoursesEmptyTitle;

  /// No description provided for @myCoursesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No course is linked to you yet. The courses you teach will appear here, grouped by class.'**
  String get myCoursesEmptyDescription;

  /// No description provided for @myCoursesErrorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get myCoursesErrorNetworkTitle;

  /// No description provided for @myCoursesErrorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your internet connection, then try again.'**
  String get myCoursesErrorNetworkMessage;

  /// No description provided for @myCoursesErrorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get myCoursesErrorUnauthorizedTitle;

  /// No description provided for @myCoursesErrorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again to view your courses.'**
  String get myCoursesErrorUnauthorizedMessage;

  /// No description provided for @myCoursesErrorForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get myCoursesErrorForbiddenTitle;

  /// No description provided for @myCoursesErrorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have the required permissions to view these courses.'**
  String get myCoursesErrorForbiddenMessage;

  /// No description provided for @myCoursesErrorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get myCoursesErrorServerTitle;

  /// No description provided for @myCoursesErrorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again in a moment.'**
  String get myCoursesErrorServerMessage;

  /// No description provided for @myCoursesErrorUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get myCoursesErrorUnknownTitle;

  /// No description provided for @myCoursesErrorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading your courses.'**
  String get myCoursesErrorUnknownMessage;

  /// No description provided for @myCoursesErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get myCoursesErrorRetry;

  /// No description provided for @myCoursesErrorReconnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get myCoursesErrorReconnect;

  /// No description provided for @myCoursesErrorContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact the administrator'**
  String get myCoursesErrorContactAdmin;

  /// No description provided for @myCoursesErrorIncidentCode.
  ///
  /// In en, this message translates to:
  /// **'Incident code: {code}'**
  String myCoursesErrorIncidentCode(String code);

  /// No description provided for @courseDetailBackToCourses.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get courseDetailBackToCourses;

  /// No description provided for @courseDetailEvaluationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No evaluation} =1{1 evaluation} other{{count} evaluations}}'**
  String courseDetailEvaluationCount(int count);

  /// No description provided for @courseDetailToGrade.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 to grade} other{{count} to grade}}'**
  String courseDetailToGrade(int count);

  /// No description provided for @courseDetailNextEvalEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Next evaluation'**
  String get courseDetailNextEvalEyebrow;

  /// No description provided for @courseDetailEvalMetaShort.
  ///
  /// In en, this message translates to:
  /// **'{date} · /{max} pts'**
  String courseDetailEvalMetaShort(String date, String max);

  /// No description provided for @courseDetailEvalMeta.
  ///
  /// In en, this message translates to:
  /// **'{date} · /{max} pts · weight {poids}'**
  String courseDetailEvalMeta(String date, String max, int poids);

  /// No description provided for @courseDetailPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period {ordre}'**
  String courseDetailPeriodLabel(int ordre);

  /// No description provided for @courseDetailSubPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-period {ordre}'**
  String courseDetailSubPeriodLabel(int ordre);

  /// No description provided for @courseDetailExamLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get courseDetailExamLabel;

  /// No description provided for @courseDetailStatutClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get courseDetailStatutClosed;

  /// No description provided for @courseDetailStatutCurrent.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get courseDetailStatutCurrent;

  /// No description provided for @courseDetailStatutUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get courseDetailStatutUpcoming;

  /// No description provided for @courseDetailBucketNotes.
  ///
  /// In en, this message translates to:
  /// **'{saisies}/{total} marks · {evals, plural, =1{1 eval.} other{{evals} evals.}}'**
  String courseDetailBucketNotes(int saisies, int total, int evals);

  /// No description provided for @courseDetailBucketNoEval.
  ///
  /// In en, this message translates to:
  /// **'No evaluation'**
  String get courseDetailBucketNoEval;

  /// No description provided for @courseDetailExamToPlan.
  ///
  /// In en, this message translates to:
  /// **'To be scheduled'**
  String get courseDetailExamToPlan;

  /// No description provided for @courseDetailNoteGlobaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall mark — {label}'**
  String courseDetailNoteGlobaleTitle(String label);

  /// No description provided for @courseDetailProvisional.
  ///
  /// In en, this message translates to:
  /// **'provisional'**
  String get courseDetailProvisional;

  /// No description provided for @courseDetailClassAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Class average'**
  String get courseDetailClassAverageLabel;

  /// No description provided for @courseDetailAbove50.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} students ≥ 50%'**
  String courseDetailAbove50(int count, int total);

  /// No description provided for @courseDetailNoAverage.
  ///
  /// In en, this message translates to:
  /// **'No average yet'**
  String get courseDetailNoAverage;

  /// No description provided for @courseDetailByStudent.
  ///
  /// In en, this message translates to:
  /// **'By student'**
  String get courseDetailByStudent;

  /// No description provided for @courseDetailBadgeGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get courseDetailBadgeGraded;

  /// No description provided for @courseDetailBadgeInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress · {saisies}/{total}'**
  String courseDetailBadgeInProgress(int saisies, int total);

  /// No description provided for @courseDetailBadgeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get courseDetailBadgeUpcoming;

  /// No description provided for @courseDetailEvalExpected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student expected} other{{count} students expected}}'**
  String courseDetailEvalExpected(int count);

  /// No description provided for @courseDetailReleveTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall marks — {label}'**
  String courseDetailReleveTitle(String label);

  /// No description provided for @courseDetailReleveKpiAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get courseDetailReleveKpiAverage;

  /// No description provided for @courseDetailReleveKpiAbove50.
  ///
  /// In en, this message translates to:
  /// **'≥ 50%'**
  String get courseDetailReleveKpiAbove50;

  /// No description provided for @courseDetailReleveKpiEvals.
  ///
  /// In en, this message translates to:
  /// **'Evals'**
  String get courseDetailReleveKpiEvals;

  /// No description provided for @courseDetailSortRanking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get courseDetailSortRanking;

  /// No description provided for @courseDetailSortAlpha.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get courseDetailSortAlpha;

  /// No description provided for @courseDetailReleveMethod.
  ///
  /// In en, this message translates to:
  /// **'Overall mark = points earned ÷ maximum, weighted by coefficient.'**
  String get courseDetailReleveMethod;

  /// No description provided for @courseDetailReleveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No marks entered'**
  String get courseDetailReleveEmpty;

  /// No description provided for @courseDetailLoadingA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading course'**
  String get courseDetailLoadingA11yLabel;

  /// No description provided for @courseDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No evaluation'**
  String get courseDetailEmptyTitle;

  /// No description provided for @courseDetailEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'This course has no evaluation yet.'**
  String get courseDetailEmptyDescription;

  /// No description provided for @courseDetailBucketEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming selection — no evaluation scheduled yet.'**
  String get courseDetailBucketEmptyUpcoming;

  /// No description provided for @courseDetailBucketEmptyNone.
  ///
  /// In en, this message translates to:
  /// **'No evaluation attached to this selection.'**
  String get courseDetailBucketEmptyNone;

  /// No description provided for @courseDetailErrorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection, then try again.'**
  String get courseDetailErrorNetworkMessage;

  /// No description provided for @courseDetailErrorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again to view this course.'**
  String get courseDetailErrorUnauthorizedMessage;

  /// No description provided for @courseDetailErrorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have the required permissions to view this course.'**
  String get courseDetailErrorForbiddenMessage;

  /// No description provided for @courseDetailErrorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again in a moment.'**
  String get courseDetailErrorServerMessage;

  /// No description provided for @courseDetailErrorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading the course.'**
  String get courseDetailErrorUnknownMessage;

  /// No description provided for @courseDetailErrorNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Course not found'**
  String get courseDetailErrorNotFoundTitle;

  /// No description provided for @courseDetailErrorNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This course no longer exists or is not accessible.'**
  String get courseDetailErrorNotFoundMessage;

  /// No description provided for @evalTypeInterro.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get evalTypeInterro;

  /// No description provided for @evalTypeDevoir.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get evalTypeDevoir;

  /// No description provided for @evalTypeExamen.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get evalTypeExamen;

  /// No description provided for @evalCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New evaluation'**
  String get evalCreateTitle;

  /// No description provided for @evalCreateFieldPeriode.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get evalCreateFieldPeriode;

  /// No description provided for @evalCreateFieldSousPeriode.
  ///
  /// In en, this message translates to:
  /// **'Sub-period'**
  String get evalCreateFieldSousPeriode;

  /// No description provided for @evalCreateExamPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Term exam'**
  String get evalCreateExamPlaceholder;

  /// No description provided for @evalCreateFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get evalCreateFieldDate;

  /// No description provided for @evalCreateFieldDateHint.
  ///
  /// In en, this message translates to:
  /// **'dd/mm/yyyy'**
  String get evalCreateFieldDateHint;

  /// No description provided for @evalCreateFieldMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get evalCreateFieldMax;

  /// No description provided for @evalCreateFieldPoids.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get evalCreateFieldPoids;

  /// No description provided for @evalCreateFieldChapitres.
  ///
  /// In en, this message translates to:
  /// **'Related chapters'**
  String get evalCreateFieldChapitres;

  /// No description provided for @evalCreateChapitresComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get evalCreateChapitresComingSoon;

  /// No description provided for @evalCreateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get evalCreateCancel;

  /// No description provided for @evalCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create evaluation'**
  String get evalCreateSubmit;

  /// No description provided for @evalCreateHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The student in {classroom} will be added} other{The {count} students in {classroom} will be added}} with the “Pending” status.'**
  String evalCreateHint(int count, String classroom);

  /// No description provided for @evalCreateSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Evaluation created'**
  String get evalCreateSuccessToast;

  /// No description provided for @evalCreateErrorToast.
  ///
  /// In en, this message translates to:
  /// **'Creating the evaluation failed. Please try again.'**
  String get evalCreateErrorToast;

  /// No description provided for @evalDetailBack.
  ///
  /// In en, this message translates to:
  /// **'Back to course'**
  String get evalDetailBack;

  /// No description provided for @evalBadgeComplete.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get evalBadgeComplete;

  /// No description provided for @evalBadgePartial.
  ///
  /// In en, this message translates to:
  /// **'Grading · {done}/{total}'**
  String evalBadgePartial(int done, int total);

  /// No description provided for @evalBadgeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get evalBadgeUpcoming;

  /// No description provided for @evalChipMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum: {max} pts'**
  String evalChipMax(String max);

  /// No description provided for @evalChipPoids.
  ///
  /// In en, this message translates to:
  /// **'Weight: {poids}'**
  String evalChipPoids(int poids);

  /// No description provided for @evalModeTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get evalModeTable;

  /// No description provided for @evalModeFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get evalModeFocus;

  /// No description provided for @evalCountNotee.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} graded} other{{count} graded}}'**
  String evalCountNotee(int count);

  /// No description provided for @evalCountEnAttente.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String evalCountEnAttente(int count);

  /// No description provided for @evalCountAbsJust.
  ///
  /// In en, this message translates to:
  /// **'{count} exc. abs.'**
  String evalCountAbsJust(int count);

  /// No description provided for @evalCountAbsNonJust.
  ///
  /// In en, this message translates to:
  /// **'{count} unexc. abs.'**
  String evalCountAbsNonJust(int count);

  /// No description provided for @evalStatutNotee.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get evalStatutNotee;

  /// No description provided for @evalStatutEnAttente.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get evalStatutEnAttente;

  /// No description provided for @evalStatutAbsJust.
  ///
  /// In en, this message translates to:
  /// **'Exc. abs.'**
  String get evalStatutAbsJust;

  /// No description provided for @evalStatutAbsNonJust.
  ///
  /// In en, this message translates to:
  /// **'Unexc. abs.'**
  String get evalStatutAbsNonJust;

  /// No description provided for @evalNoteMaxError.
  ///
  /// In en, this message translates to:
  /// **'max {max}'**
  String evalNoteMaxError(String max);

  /// No description provided for @evalAbsenceJustifieTooltip.
  ///
  /// In en, this message translates to:
  /// **'Excused absence'**
  String get evalAbsenceJustifieTooltip;

  /// No description provided for @evalAbsenceNonJustifieTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unexcused absence'**
  String get evalAbsenceNonJustifieTooltip;

  /// No description provided for @evalFocusClear.
  ///
  /// In en, this message translates to:
  /// **'Clear · pending'**
  String get evalFocusClear;

  /// No description provided for @evalFocusPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get evalFocusPrevious;

  /// No description provided for @evalFocusNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get evalFocusNext;

  /// No description provided for @evalFocusLast.
  ///
  /// In en, this message translates to:
  /// **'Last student'**
  String get evalFocusLast;

  /// No description provided for @evalFocusPosition.
  ///
  /// In en, this message translates to:
  /// **'Student {index} / {total}'**
  String evalFocusPosition(int index, int total);

  /// No description provided for @evalSaveCounter.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} entered'**
  String evalSaveCounter(int done, int total);

  /// No description provided for @evalSaveErrorsAlert.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 grade above the maximum} other{{count} grades above the maximum}}'**
  String evalSaveErrorsAlert(int count);

  /// No description provided for @evalSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save grades'**
  String get evalSaveButton;

  /// No description provided for @evalSaveButtonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get evalSaveButtonSaving;

  /// No description provided for @evalSaveSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Grades saved — {notees, plural, =1{{notees} graded} other{{notees} graded}} · {enAttente} pending'**
  String evalSaveSuccessToast(int notees, int enAttente);

  /// No description provided for @evalSaveErrorToast.
  ///
  /// In en, this message translates to:
  /// **'Saving failed. Your entries are kept.'**
  String get evalSaveErrorToast;

  /// No description provided for @evalSaisieEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No students'**
  String get evalSaisieEmptyTitle;

  /// No description provided for @evalSaisieEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No students are enrolled in this class.'**
  String get evalSaisieEmptyDescription;

  /// No description provided for @evalSaisieLoadingA11y.
  ///
  /// In en, this message translates to:
  /// **'Loading grade entry'**
  String get evalSaisieLoadingA11y;

  /// No description provided for @evalSaisieErrorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection, then try again.'**
  String get evalSaisieErrorNetworkMessage;

  /// No description provided for @evalSaisieErrorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again to enter grades.'**
  String get evalSaisieErrorUnauthorizedMessage;

  /// No description provided for @evalSaisieErrorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have the required permissions to enter these grades.'**
  String get evalSaisieErrorForbiddenMessage;

  /// No description provided for @evalSaisieErrorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again in a moment.'**
  String get evalSaisieErrorServerMessage;

  /// No description provided for @evalSaisieErrorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading grade entry.'**
  String get evalSaisieErrorUnknownMessage;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Home banner greeting with the signed-in user's first name.
  ///
  /// In en, this message translates to:
  /// **'Hello, {firstName}'**
  String accueilBannerGreeting(String firstName);

  /// No description provided for @accueilBannerGreetingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get accueilBannerGreetingGeneric;

  /// No description provided for @accueilBannerContextTail.
  ///
  /// In en, this message translates to:
  /// **'Here is the essential view of your school today.'**
  String get accueilBannerContextTail;

  /// No description provided for @accueilModulesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your modules'**
  String get accueilModulesEyebrow;

  /// No description provided for @accueilModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to go?'**
  String get accueilModulesTitle;

  /// No description provided for @accueilModulesIntro.
  ///
  /// In en, this message translates to:
  /// **'Four modules cover the administrative life of the school. Everything stays accessible from the side menu.'**
  String get accueilModulesIntro;

  /// No description provided for @accueilModuleInscriptionsDescription.
  ///
  /// In en, this message translates to:
  /// **'New enrolments, re-enrolments and pre-enrolments for your students.'**
  String get accueilModuleInscriptionsDescription;

  /// No description provided for @accueilModuleFinancesDescription.
  ///
  /// In en, this message translates to:
  /// **'Revenue, invoicing and tracking of school fee collection.'**
  String get accueilModuleFinancesDescription;

  /// No description provided for @accueilModuleClassesDescription.
  ///
  /// In en, this message translates to:
  /// **'Class composition and student lists by cycle.'**
  String get accueilModuleClassesDescription;

  /// No description provided for @accueilModuleDisciplinesDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily attendance, disciplinary records and student follow-up.'**
  String get accueilModuleDisciplinesDescription;

  /// Accessibility label for the module card (button role, explicit destination).
  ///
  /// In en, this message translates to:
  /// **'{module} — open the dashboard'**
  String accueilModuleCardSemantics(String module);

  /// No description provided for @accueilSignature.
  ///
  /// In en, this message translates to:
  /// **'eteyelo · l\'école en lingala'**
  String get accueilSignature;

  /// No description provided for @homeTopBarPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending files follow-up'**
  String get homeTopBarPendingSubtitle;

  /// No description provided for @homeTopBarNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeTopBarNotificationsTooltip;

  /// No description provided for @homeUserMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'User menu'**
  String get homeUserMenuTooltip;

  /// No description provided for @homeSidebarCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse menu'**
  String get homeSidebarCollapseTooltip;

  /// No description provided for @homeSidebarExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand menu'**
  String get homeSidebarExpandTooltip;

  /// No description provided for @homeOpenNavigationDrawerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get homeOpenNavigationDrawerTooltip;

  /// No description provided for @homeSidebarFooterLabel.
  ///
  /// In en, this message translates to:
  /// **'School dashboard'**
  String get homeSidebarFooterLabel;

  /// No description provided for @homeSidebarNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get homeSidebarNavigationLabel;

  /// No description provided for @pageUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'This page is under development'**
  String get pageUnderConstruction;

  /// No description provided for @preRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Pre-Registrations'**
  String get preRegistrations;

  /// No description provided for @searchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search Students'**
  String get searchStudents;

  /// No description provided for @searchFormSubtitleFirstRegistration.
  ///
  /// In en, this message translates to:
  /// **'Filter the enrollments list'**
  String get searchFormSubtitleFirstRegistration;

  /// No description provided for @searchFormSubtitlePreRegistration.
  ///
  /// In en, this message translates to:
  /// **'Online requests received, pending validation'**
  String get searchFormSubtitlePreRegistration;

  /// No description provided for @reRegistrationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find a student or a class from the previous year to re-enroll'**
  String get reRegistrationSearchHint;

  /// No description provided for @reRegistrationSearchHelpPill.
  ///
  /// In en, this message translates to:
  /// **'Find a specific student (last name + middle name + first name) or a whole class from the previous year (cycle + level) to re-enroll for the new year. You can also combine both.'**
  String get reRegistrationSearchHelpPill;

  /// No description provided for @reRegistrationSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search a student'**
  String get reRegistrationSearchTitle;

  /// No description provided for @reRegistrationSearchByNameGroup.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get reRegistrationSearchByNameGroup;

  /// No description provided for @reRegistrationSearchByLevelGroup.
  ///
  /// In en, this message translates to:
  /// **'By cycle / level'**
  String get reRegistrationSearchByLevelGroup;

  /// No description provided for @reRegistrationSearchOrSeparator.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get reRegistrationSearchOrSeparator;

  /// No description provided for @reRegistrationSearchActiveModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active search by:'**
  String get reRegistrationSearchActiveModeLabel;

  /// No description provided for @reRegistrationSearchModeNameBadge.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get reRegistrationSearchModeNameBadge;

  /// No description provided for @reRegistrationSearchModeLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'Cycle / level'**
  String get reRegistrationSearchModeLevelBadge;

  /// No description provided for @reRegistrationSearchLevelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a cycle first'**
  String get reRegistrationSearchLevelPlaceholder;

  /// No description provided for @reRegistrationAcademicInfoHelp.
  ///
  /// In en, this message translates to:
  /// **'Select the target cycle and level to filter results.'**
  String get reRegistrationAcademicInfoHelp;

  /// No description provided for @reRegistrationSearchNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No cycle/level is available for this search.'**
  String get reRegistrationSearchNoOptions;

  /// No description provided for @reRegistrationSearchNeedCriteria.
  ///
  /// In en, this message translates to:
  /// **'Provide either First name, Last name and Surname, or Cycle/Level.'**
  String get reRegistrationSearchNeedCriteria;

  /// No description provided for @reRegistrationSearchReady.
  ///
  /// In en, this message translates to:
  /// **'Valid criteria, you can run the search.'**
  String get reRegistrationSearchReady;

  /// No description provided for @reRegistrationSearchInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a re-registration search'**
  String get reRegistrationSearchInvitationTitle;

  /// No description provided for @reRegistrationSearchInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Fill the form above then click Search to display enrollment files.'**
  String get reRegistrationSearchInvitationMessage;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @editEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editEnrollment;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportData;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @enrollmentNoResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'No student matches your search criteria.'**
  String get enrollmentNoResultsDescription;

  /// No description provided for @enrollmentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get enrollmentEmptyTitle;

  /// No description provided for @enrollmentEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No enrollment matches these criteria. Adjust your search, or create the record if the student is not yet registered.'**
  String get enrollmentEmptyDescription;

  /// No description provided for @enrollmentEmptyWithoutFilterDescription.
  ///
  /// In en, this message translates to:
  /// **'No enrollment yet.'**
  String get enrollmentEmptyWithoutFilterDescription;

  /// No description provided for @enrollmentEmptyCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Enroll a new student'**
  String get enrollmentEmptyCreateAction;

  /// No description provided for @enrollmentErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get enrollmentErrorRetry;

  /// No description provided for @enrollmentErrorReconnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get enrollmentErrorReconnect;

  /// No description provided for @enrollmentErrorContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact administrator'**
  String get enrollmentErrorContactAdmin;

  /// No description provided for @enrollmentErrorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get enrollmentErrorNetworkTitle;

  /// No description provided for @enrollmentErrorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your internet connection, then retry.'**
  String get enrollmentErrorNetworkMessage;

  /// No description provided for @enrollmentErrorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get enrollmentErrorUnauthorizedTitle;

  /// No description provided for @enrollmentErrorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again to continue.'**
  String get enrollmentErrorUnauthorizedMessage;

  /// No description provided for @enrollmentErrorForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get enrollmentErrorForbiddenTitle;

  /// No description provided for @enrollmentErrorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have the required permissions to view this list.'**
  String get enrollmentErrorForbiddenMessage;

  /// No description provided for @enrollmentErrorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get enrollmentErrorServerTitle;

  /// No description provided for @enrollmentErrorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred on our side. Please try again in a moment.'**
  String get enrollmentErrorServerMessage;

  /// No description provided for @enrollmentErrorIncidentCode.
  ///
  /// In en, this message translates to:
  /// **'Incident code: {code}'**
  String enrollmentErrorIncidentCode(String code);

  /// No description provided for @enrollmentErrorUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get enrollmentErrorUnknownTitle;

  /// No description provided for @enrollmentErrorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading results.'**
  String get enrollmentErrorUnknownMessage;

  /// No description provided for @loadingStudents.
  ///
  /// In en, this message translates to:
  /// **'Loading students...'**
  String get loadingStudents;

  /// No description provided for @enrollmentResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 result} =1{1 result} other{{count} results}}'**
  String enrollmentResultsCount(int count);

  /// No description provided for @paginationPageIndicator.
  ///
  /// In en, this message translates to:
  /// **'Page {current} / {total}'**
  String paginationPageIndicator(int current, int total);

  /// No description provided for @paginationResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 result} =1{1 result} other{{count} results}}'**
  String paginationResultsCount(int count);

  /// No description provided for @paginationRange.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end} of {total} {unit}'**
  String paginationRange(int start, int end, int total, String unit);

  /// No description provided for @paginationNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pagination'**
  String get paginationNavigationLabel;

  /// No description provided for @unitStudents.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get unitStudents;

  /// No description provided for @enrollmentResultCardOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Open {name}\'s record, status {status}'**
  String enrollmentResultCardOpenLabel(String name, String status);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusValidated.
  ///
  /// In en, this message translates to:
  /// **'Validated'**
  String get statusValidated;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @enrollmentCode.
  ///
  /// In en, this message translates to:
  /// **'Enrollment Code'**
  String get enrollmentCode;

  /// No description provided for @enrollmentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrollment file'**
  String get enrollmentDetailTitle;

  /// No description provided for @enrollmentUnknownStudent.
  ///
  /// In en, this message translates to:
  /// **'Student not specified'**
  String get enrollmentUnknownStudent;

  /// No description provided for @firstRegistrationNewEnrollmentAction.
  ///
  /// In en, this message translates to:
  /// **'New enrollment'**
  String get firstRegistrationNewEnrollmentAction;

  /// No description provided for @enrollmentDetailLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading enrollment file'**
  String get enrollmentDetailLoadingTitle;

  /// No description provided for @enrollmentDetailLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait while enrollment details are being loaded.'**
  String get enrollmentDetailLoadingMessage;

  /// No description provided for @enrollmentDetailLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load enrollment file'**
  String get enrollmentDetailLoadErrorTitle;

  /// No description provided for @enrollmentDetailLoadErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading enrollment details.'**
  String get enrollmentDetailLoadErrorFallback;

  /// No description provided for @enrollmentDetailRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get enrollmentDetailRetryAction;

  /// No description provided for @enrollmentDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Details not found'**
  String get enrollmentDetailNotFoundTitle;

  /// No description provided for @enrollmentDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This enrollment file does not exist or is no longer available.'**
  String get enrollmentDetailNotFoundMessage;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @previousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous Year'**
  String get previousYear;

  /// No description provided for @targetYear.
  ///
  /// In en, this message translates to:
  /// **'Target Year'**
  String get targetYear;

  /// No description provided for @guardianInformation.
  ///
  /// In en, this message translates to:
  /// **'Guardian Information'**
  String get guardianInformation;

  /// No description provided for @guardianAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add guardian/contact'**
  String get guardianAddAction;

  /// No description provided for @guardianSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get guardianSaveAction;

  /// No description provided for @guardianRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get guardianRelationshipLabel;

  /// No description provided for @guardianMarkAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as primary guardian'**
  String get guardianMarkAsPrimary;

  /// No description provided for @guardianPrimaryRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'At least one primary guardian is required'**
  String get guardianPrimaryRequiredHint;

  /// No description provided for @guardianPrincipalBadge.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get guardianPrincipalBadge;

  /// No description provided for @guardianToggleCard.
  ///
  /// In en, this message translates to:
  /// **'Open or close guardian card'**
  String get guardianToggleCard;

  /// No description provided for @guardianIncompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Incomplete profile'**
  String get guardianIncompleteHint;

  /// No description provided for @guardianEmailOptionalInline.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get guardianEmailOptionalInline;

  /// No description provided for @guardianDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Remove this guardian'**
  String get guardianDeleteAction;

  /// No description provided for @guardianDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm removal'**
  String get guardianDeleteConfirmTitle;

  /// No description provided for @guardianDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to remove this guardian? This action cannot be undone.'**
  String get guardianDeleteConfirmMessage;

  /// No description provided for @guardianDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get guardianDeleteConfirmAction;

  /// No description provided for @guardianUnlinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Guardian removed successfully.'**
  String get guardianUnlinkSuccess;

  /// No description provided for @guardianUnlinkError.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove guardian: {message}'**
  String guardianUnlinkError(String message);

  /// No description provided for @schoolFees.
  ///
  /// In en, this message translates to:
  /// **'School Fees'**
  String get schoolFees;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @summaryYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get summaryYes;

  /// No description provided for @summaryNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get summaryNo;

  /// No description provided for @summaryChargesTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get summaryChargesTotalDue;

  /// No description provided for @summaryChargesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Amounts are unavailable for now.'**
  String get summaryChargesUnavailable;

  /// No description provided for @summaryValidationNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before validation'**
  String get summaryValidationNoticeTitle;

  /// No description provided for @summaryValidationNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'You certify that the information is accurate. The file will move to validated status and a receipt can be generated.'**
  String get summaryValidationNoticeBody;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @personalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Editable personal information'**
  String get personalInfoSubtitle;

  /// No description provided for @firstNameHelp.
  ///
  /// In en, this message translates to:
  /// **'The student\'s official first name.'**
  String get firstNameHelp;

  /// No description provided for @lastNameHelp.
  ///
  /// In en, this message translates to:
  /// **'The student\'s family name.'**
  String get lastNameHelp;

  /// No description provided for @surnameHelp.
  ///
  /// In en, this message translates to:
  /// **'The middle name or other common name.'**
  String get surnameHelp;

  /// No description provided for @dateOfBirthHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the selector to choose the date of birth.'**
  String get dateOfBirthHelp;

  /// No description provided for @birthPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get birthPlace;

  /// No description provided for @birthPlaceHelp.
  ///
  /// In en, this message translates to:
  /// **'City or locality of birth.'**
  String get birthPlaceHelp;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @nationalityHelp.
  ///
  /// In en, this message translates to:
  /// **'The student\'s main nationality.'**
  String get nationalityHelp;

  /// No description provided for @genderHelp.
  ///
  /// In en, this message translates to:
  /// **'Gender recorded in the administrative file.'**
  String get genderHelp;

  /// No description provided for @selectDateOfBirthHelpText.
  ///
  /// In en, this message translates to:
  /// **'Select a date of birth'**
  String get selectDateOfBirthHelpText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @enterFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Enter {label}'**
  String enterFieldHint(String label);

  /// No description provided for @firstNameExample.
  ///
  /// In en, this message translates to:
  /// **'Claudine'**
  String get firstNameExample;

  /// No description provided for @lastNameExample.
  ///
  /// In en, this message translates to:
  /// **'Furah'**
  String get lastNameExample;

  /// No description provided for @surnameExample.
  ///
  /// In en, this message translates to:
  /// **'Sifiwe'**
  String get surnameExample;

  /// No description provided for @selectPlaceholderChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get selectPlaceholderChoose;

  /// No description provided for @requiredSemanticSuffix.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get requiredSemanticSuffix;

  /// No description provided for @dateHint.
  ///
  /// In en, this message translates to:
  /// **'dd/mm/yyyy'**
  String get dateHint;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityHelp.
  ///
  /// In en, this message translates to:
  /// **'Student\'s city of residence.'**
  String get cityHelp;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @districtHelp.
  ///
  /// In en, this message translates to:
  /// **'District or borough.'**
  String get districtHelp;

  /// No description provided for @municipality.
  ///
  /// In en, this message translates to:
  /// **'Municipality'**
  String get municipality;

  /// No description provided for @municipalityHelp.
  ///
  /// In en, this message translates to:
  /// **'Municipality of residence.'**
  String get municipalityHelp;

  /// No description provided for @neighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get neighborhood;

  /// No description provided for @neighborhoodHelp.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood or street of residence.'**
  String get neighborhoodHelp;

  /// No description provided for @addressComplementary.
  ///
  /// In en, this message translates to:
  /// **'Additional address'**
  String get addressComplementary;

  /// No description provided for @addressComplementaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Add street, avenue and number when needed.'**
  String get addressComplementaryHelp;

  /// No description provided for @addressComplementaryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ex: 10, Avenue La source'**
  String get addressComplementaryPlaceholder;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get fullAddress;

  /// No description provided for @fullAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Full residential address.'**
  String get fullAddressHelp;

  /// No description provided for @academicYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic year'**
  String get academicYearLabel;

  /// No description provided for @academicYearLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Reference academic year.'**
  String get academicYearLabelHelp;

  /// No description provided for @schoolLabel.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get schoolLabel;

  /// No description provided for @schoolLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Name of the previous school.'**
  String get schoolLabelHelp;

  /// No description provided for @schoolCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get schoolCycle;

  /// No description provided for @schoolCycleHelp.
  ///
  /// In en, this message translates to:
  /// **'Previous teaching cycle.'**
  String get schoolCycleHelp;

  /// No description provided for @schoolLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get schoolLevelLabel;

  /// No description provided for @schoolLevelLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Previous study level.'**
  String get schoolLevelLabelHelp;

  /// No description provided for @averageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get averageLabel;

  /// No description provided for @averageLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Annual average obtained.'**
  String get averageLabelHelp;

  /// No description provided for @rankingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get rankingLabel;

  /// No description provided for @rankingLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Class ranking.'**
  String get rankingLabelHelp;

  /// No description provided for @yearValidated.
  ///
  /// In en, this message translates to:
  /// **'Year validated'**
  String get yearValidated;

  /// No description provided for @yearValidatedHelp.
  ///
  /// In en, this message translates to:
  /// **'Indicates whether the student validated the previous school year.'**
  String get yearValidatedHelp;

  /// No description provided for @yearNotValidated.
  ///
  /// In en, this message translates to:
  /// **'Not validated'**
  String get yearNotValidated;

  /// No description provided for @currentAcademicYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic year'**
  String get currentAcademicYearLabel;

  /// No description provided for @currentAcademicYearHelp.
  ///
  /// In en, this message translates to:
  /// **'Target academic year.'**
  String get currentAcademicYearHelp;

  /// No description provided for @targetCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Target cycle'**
  String get targetCycleLabel;

  /// No description provided for @targetCycleLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Target cycle for this enrollment.'**
  String get targetCycleLabelHelp;

  /// No description provided for @targetLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Target level'**
  String get targetLevelLabel;

  /// No description provided for @targetLevelLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Target level for this enrollment.'**
  String get targetLevelLabelHelp;

  /// No description provided for @optionLabel.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get optionLabel;

  /// No description provided for @optionLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Desired option or specialization.'**
  String get optionLabelHelp;

  /// No description provided for @toDefine.
  ///
  /// In en, this message translates to:
  /// **'To be defined'**
  String get toDefine;

  /// No description provided for @primaryGuardian.
  ///
  /// In en, this message translates to:
  /// **'Primary Guardian'**
  String get primaryGuardian;

  /// No description provided for @guardianNumber.
  ///
  /// In en, this message translates to:
  /// **'Guardian {number}'**
  String guardianNumber(int number);

  /// No description provided for @noGuardianInfo.
  ///
  /// In en, this message translates to:
  /// **'No guardian information available'**
  String get noGuardianInfo;

  /// No description provided for @identificationNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Identification number'**
  String get identificationNumberLabel;

  /// No description provided for @identificationNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Official identification number.'**
  String get identificationNumberHelp;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Guardian\'s phone number.'**
  String get phoneNumberHelp;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailLabelHelp.
  ///
  /// In en, this message translates to:
  /// **'Guardian\'s email address.'**
  String get emailLabelHelp;

  /// No description provided for @relationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationshipFather;

  /// No description provided for @relationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationshipMother;

  /// No description provided for @relationshipGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get relationshipGuardian;

  /// No description provided for @relationshipUncle.
  ///
  /// In en, this message translates to:
  /// **'Uncle'**
  String get relationshipUncle;

  /// No description provided for @relationshipAunt.
  ///
  /// In en, this message translates to:
  /// **'Aunt'**
  String get relationshipAunt;

  /// No description provided for @relationshipGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get relationshipGrandparent;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// No description provided for @stepPersonalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'General student information'**
  String get stepPersonalInfoSubtitle;

  /// No description provided for @stepAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Location and full address'**
  String get stepAddressSubtitle;

  /// No description provided for @stepAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Student\'s address'**
  String get stepAddressTitle;

  /// No description provided for @stepAcademicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Academic history and goals'**
  String get stepAcademicSubtitle;

  /// No description provided for @stepAcademicPreviousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Previous year academic history'**
  String get stepAcademicPreviousSubtitle;

  /// No description provided for @stepAcademicTargetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Target year academic objectives'**
  String get stepAcademicTargetSubtitle;

  /// No description provided for @stepGuardianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Legal guardians and contacts'**
  String get stepGuardianSubtitle;

  /// No description provided for @stepSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Final enrollment summary'**
  String get stepSummarySubtitle;

  /// No description provided for @wizardStepShortPersonal.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get wizardStepShortPersonal;

  /// No description provided for @wizardStepShortAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get wizardStepShortAddress;

  /// No description provided for @wizardStepShortPrevious.
  ///
  /// In en, this message translates to:
  /// **'Prev. year'**
  String get wizardStepShortPrevious;

  /// No description provided for @wizardStepShortTarget.
  ///
  /// In en, this message translates to:
  /// **'Target year'**
  String get wizardStepShortTarget;

  /// No description provided for @wizardStepShortCharges.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get wizardStepShortCharges;

  /// No description provided for @wizardStepShortGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardians'**
  String get wizardStepShortGuardian;

  /// No description provided for @wizardStepShortSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get wizardStepShortSummary;

  /// No description provided for @stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} / {total}'**
  String stepIndicator(int current, int total);

  /// No description provided for @wizardStepNumberShort.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String wizardStepNumberShort(int number);

  /// No description provided for @stepForwardHint.
  ///
  /// In en, this message translates to:
  /// **'Click Continue to advance step by step.'**
  String get stepForwardHint;

  /// No description provided for @journeyModeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get journeyModeNew;

  /// No description provided for @journeyModeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get journeyModeEdit;

  /// No description provided for @journeyModeView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get journeyModeView;

  /// No description provided for @journeyCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get journeyCloseAction;

  /// No description provided for @stepSaveStateIdle.
  ///
  /// In en, this message translates to:
  /// **'No input yet'**
  String get stepSaveStateIdle;

  /// No description provided for @stepSaveStateIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete fields'**
  String get stepSaveStateIncomplete;

  /// No description provided for @stepSaveStatePending.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get stepSaveStatePending;

  /// No description provided for @stepSaveStateSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get stepSaveStateSaving;

  /// No description provided for @stepSaveStateSaved.
  ///
  /// In en, this message translates to:
  /// **'Step saved'**
  String get stepSaveStateSaved;

  /// No description provided for @validatePersonalInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Please complete the personal information.'**
  String get validatePersonalInfoHint;

  /// No description provided for @validateAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Please complete the student\'s address.'**
  String get validateAddressHint;

  /// No description provided for @validateAcademicInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Please complete the academic information.'**
  String get validateAcademicInfoHint;

  /// No description provided for @validateGuardianInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Please check the guardian information.'**
  String get validateGuardianInfoHint;

  /// No description provided for @enrollmentReadyForValidation.
  ///
  /// In en, this message translates to:
  /// **'File ready for final validation.'**
  String get enrollmentReadyForValidation;

  /// No description provided for @completedEnrollmentRedirecting.
  ///
  /// In en, this message translates to:
  /// **'This enrollment is already completed. Redirecting to First Registration.'**
  String get completedEnrollmentRedirecting;

  /// No description provided for @validateEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Validate enrollment'**
  String get validateEnrollment;

  /// No description provided for @validatingEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validatingEnrollment;

  /// No description provided for @goToFirstRegistration.
  ///
  /// In en, this message translates to:
  /// **'Go to First Registration'**
  String get goToFirstRegistration;

  /// No description provided for @enrollmentStatusUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully.'**
  String get enrollmentStatusUpdateSuccess;

  /// No description provided for @enrollmentStatusUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status: {message}'**
  String enrollmentStatusUpdateError(String message);

  /// No description provided for @personalInfoSaveHintBeforeContinue.
  ///
  /// In en, this message translates to:
  /// **'Please save your changes before continuing.'**
  String get personalInfoSaveHintBeforeContinue;

  /// No description provided for @personalInfoValidationReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Please correct the following fields:'**
  String get personalInfoValidationReasonsTitle;

  /// No description provided for @requiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'The {field} field is required.'**
  String requiredFieldError(String field);

  /// No description provided for @invalidNumberFieldError.
  ///
  /// In en, this message translates to:
  /// **'The {field} field must contain a valid number.'**
  String invalidNumberFieldError(String field);

  /// No description provided for @savePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savePersonalInfo;

  /// No description provided for @savingPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingPersonalInfo;

  /// No description provided for @personalInfoSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Personal information updated successfully.'**
  String get personalInfoSaveSuccess;

  /// No description provided for @personalInfoSaveError.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {message}'**
  String personalInfoSaveError(String message);

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @savingAddress.
  ///
  /// In en, this message translates to:
  /// **'Saving address...'**
  String get savingAddress;

  /// No description provided for @saveAcademicInfo.
  ///
  /// In en, this message translates to:
  /// **'Save academic info'**
  String get saveAcademicInfo;

  /// No description provided for @savingAcademicInfo.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingAcademicInfo;

  /// No description provided for @saveGuardianInfo.
  ///
  /// In en, this message translates to:
  /// **'Save guardian'**
  String get saveGuardianInfo;

  /// No description provided for @savingGuardianInfo.
  ///
  /// In en, this message translates to:
  /// **'Saving guardian...'**
  String get savingGuardianInfo;

  /// No description provided for @academicInfoValidationReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Please correct the following academic fields:'**
  String get academicInfoValidationReasonsTitle;

  /// No description provided for @academicInfoSaveHintBeforeContinue.
  ///
  /// In en, this message translates to:
  /// **'Please save academic changes before continuing.'**
  String get academicInfoSaveHintBeforeContinue;

  /// No description provided for @academicInfoSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Academic information updated successfully.'**
  String get academicInfoSaveSuccess;

  /// No description provided for @academicInfoSaveError.
  ///
  /// In en, this message translates to:
  /// **'Academic info update failed: {message}'**
  String academicInfoSaveError(String message);

  /// No description provided for @addressValidationReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Please correct the following address fields:'**
  String get addressValidationReasonsTitle;

  /// No description provided for @addressNoCityAvailable.
  ///
  /// In en, this message translates to:
  /// **'No city is available in the catalog.'**
  String get addressNoCityAvailable;

  /// No description provided for @addressSelectCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a city first.'**
  String get addressSelectCityFirst;

  /// No description provided for @addressNoDistrictAvailable.
  ///
  /// In en, this message translates to:
  /// **'No district is available for this city.'**
  String get addressNoDistrictAvailable;

  /// No description provided for @addressSelectDistrictFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a district first.'**
  String get addressSelectDistrictFirst;

  /// No description provided for @addressNoMunicipalityAvailable.
  ///
  /// In en, this message translates to:
  /// **'No municipality is available for this district.'**
  String get addressNoMunicipalityAvailable;

  /// No description provided for @addressSelectMunicipalityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a municipality first.'**
  String get addressSelectMunicipalityFirst;

  /// No description provided for @addressNoNeighborhoodAvailable.
  ///
  /// In en, this message translates to:
  /// **'No neighborhood is available for this municipality.'**
  String get addressNoNeighborhoodAvailable;

  /// No description provided for @addressSaveHintBeforeContinue.
  ///
  /// In en, this message translates to:
  /// **'Please save address changes before continuing.'**
  String get addressSaveHintBeforeContinue;

  /// No description provided for @addressSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Address updated successfully.'**
  String get addressSaveSuccess;

  /// No description provided for @addressSaveError.
  ///
  /// In en, this message translates to:
  /// **'Address update failed: {message}'**
  String addressSaveError(String message);

  /// No description provided for @enrollmentStudentColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get enrollmentStudentColumnLabel;

  /// No description provided for @enrollmentStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get enrollmentStatusFilterLabel;

  /// No description provided for @enrollmentStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get enrollmentStatusInProgress;

  /// No description provided for @enrollmentStatusAdminCompleted.
  ///
  /// In en, this message translates to:
  /// **'Admin Completed'**
  String get enrollmentStatusAdminCompleted;

  /// No description provided for @enrollmentStatusFinancialCompleted.
  ///
  /// In en, this message translates to:
  /// **'Financial Completed'**
  String get enrollmentStatusFinancialCompleted;

  /// No description provided for @enrollmentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get enrollmentStatusCompleted;

  /// No description provided for @enrollmentStatusValidated.
  ///
  /// In en, this message translates to:
  /// **'Validated'**
  String get enrollmentStatusValidated;

  /// No description provided for @enrollmentStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get enrollmentStatusRejected;

  /// No description provided for @enrollmentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get enrollmentStatusCancelled;

  /// No description provided for @enrollmentReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'View-only mode'**
  String get enrollmentReadOnlyTitle;

  /// No description provided for @enrollmentReadOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Student already enrolled — record can be viewed but not edited. Browse the steps to review the information.'**
  String get enrollmentReadOnlyMessage;

  /// No description provided for @enrollmentEditableTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit mode'**
  String get enrollmentEditableTitle;

  /// No description provided for @enrollmentEditableMessage.
  ///
  /// In en, this message translates to:
  /// **'This enrollment is in progress (IN_PROGRESS). Information can be updated.'**
  String get enrollmentEditableMessage;

  /// No description provided for @studentChargesStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Student charges'**
  String get studentChargesStepTitle;

  /// No description provided for @studentChargesStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Financial charges applied to the student'**
  String get studentChargesStepSubtitle;

  /// No description provided for @studentChargesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading student charges...'**
  String get studentChargesLoading;

  /// No description provided for @studentChargesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get studentChargesRetry;

  /// No description provided for @studentChargesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No charges are available for this student.'**
  String get studentChargesEmpty;

  /// No description provided for @studentChargesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Student charges cannot be loaded without a student or target level.'**
  String get studentChargesUnavailable;

  /// No description provided for @studentChargesAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get studentChargesAmountColumn;

  /// No description provided for @studentChargesLabelColumn.
  ///
  /// In en, this message translates to:
  /// **'Charge label'**
  String get studentChargesLabelColumn;

  /// No description provided for @studentChargesActionsColumn.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get studentChargesActionsColumn;

  /// No description provided for @studentChargesAmountPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid amount'**
  String get studentChargesAmountPaidLabel;

  /// No description provided for @studentChargesSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save charges'**
  String get studentChargesSaveAction;

  /// No description provided for @studentChargesSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving charges...'**
  String get studentChargesSavingAction;

  /// No description provided for @studentChargesSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Charges saved successfully.'**
  String get studentChargesSaveSuccess;

  /// No description provided for @studentChargesSaveHintBeforeContinue.
  ///
  /// In en, this message translates to:
  /// **'Please save charge changes before continuing.'**
  String get studentChargesSaveHintBeforeContinue;

  /// No description provided for @studentChargesTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get studentChargesTotalLabel;

  /// No description provided for @studentChargesHelperText.
  ///
  /// In en, this message translates to:
  /// **'Amounts can be updated later from the student\'s profile.'**
  String get studentChargesHelperText;

  /// No description provided for @studentChargesNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load charges. Please check your internet connection.'**
  String get studentChargesNetworkError;

  /// No description provided for @studentChargesNotFound.
  ///
  /// In en, this message translates to:
  /// **'No charges were found for this student.'**
  String get studentChargesNotFound;

  /// No description provided for @studentChargesValidationError.
  ///
  /// In en, this message translates to:
  /// **'The requested charge data is invalid.'**
  String get studentChargesValidationError;

  /// No description provided for @studentChargesUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to access these charges.'**
  String get studentChargesUnauthorizedError;

  /// No description provided for @studentChargesInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow access to these charges.'**
  String get studentChargesInvalidCredentialsError;

  /// No description provided for @studentChargesServerError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable.'**
  String get studentChargesServerError;

  /// No description provided for @studentChargesStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local error prevents charges from being displayed.'**
  String get studentChargesStorageError;

  /// No description provided for @studentChargesAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents charges from loading.'**
  String get studentChargesAuthError;

  /// No description provided for @studentChargesUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading charges.'**
  String get studentChargesUnknownError;

  /// No description provided for @studentChargeStatusDue.
  ///
  /// In en, this message translates to:
  /// **'To settle'**
  String get studentChargeStatusDue;

  /// No description provided for @studentChargeStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get studentChargeStatusPartial;

  /// No description provided for @studentChargeStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get studentChargeStatusPaid;

  /// No description provided for @studentChargeFeeCodeTuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition'**
  String get studentChargeFeeCodeTuition;

  /// No description provided for @studentChargeFeeCodeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get studentChargeFeeCodeRegistration;

  /// No description provided for @studentChargeFeeCodeEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Enrollment'**
  String get studentChargeFeeCodeEnrollment;

  /// No description provided for @studentChargeFeeCodeApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get studentChargeFeeCodeApplication;

  /// No description provided for @studentChargeFeeCodeAdmission.
  ///
  /// In en, this message translates to:
  /// **'Admission'**
  String get studentChargeFeeCodeAdmission;

  /// No description provided for @studentChargeFeeCodeCanteen.
  ///
  /// In en, this message translates to:
  /// **'Canteen'**
  String get studentChargeFeeCodeCanteen;

  /// No description provided for @studentChargeFeeCodeTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get studentChargeFeeCodeTransport;

  /// No description provided for @studentChargeFeeCodeBoarding.
  ///
  /// In en, this message translates to:
  /// **'Boarding'**
  String get studentChargeFeeCodeBoarding;

  /// No description provided for @studentChargeFeeCodeBooks.
  ///
  /// In en, this message translates to:
  /// **'Books & Materials'**
  String get studentChargeFeeCodeBooks;

  /// No description provided for @studentChargeFeeCodeUniform.
  ///
  /// In en, this message translates to:
  /// **'Uniform'**
  String get studentChargeFeeCodeUniform;

  /// No description provided for @studentChargeFeeCodeExamination.
  ///
  /// In en, this message translates to:
  /// **'Examination'**
  String get studentChargeFeeCodeExamination;

  /// No description provided for @studentChargeFeeCodeLabFee.
  ///
  /// In en, this message translates to:
  /// **'Laboratory Fee'**
  String get studentChargeFeeCodeLabFee;

  /// No description provided for @studentChargeFeeCodeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity Fee'**
  String get studentChargeFeeCodeActivity;

  /// No description provided for @studentChargeFeeCodeSports.
  ///
  /// In en, this message translates to:
  /// **'Sports Fee'**
  String get studentChargeFeeCodeSports;

  /// No description provided for @studentChargeFeeCodeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library Fee'**
  String get studentChargeFeeCodeLibrary;

  /// No description provided for @studentChargeFeeCodeTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology / IT Fee'**
  String get studentChargeFeeCodeTechnology;

  /// No description provided for @studentChargeFeeCodeDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development / Infrastructure Fee'**
  String get studentChargeFeeCodeDevelopment;

  /// No description provided for @studentChargeFeeCodeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get studentChargeFeeCodeInsurance;

  /// No description provided for @studentChargeFeeCodeSecurityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit'**
  String get studentChargeFeeCodeSecurityDeposit;

  /// No description provided for @studentChargeFeeCodeProcessingFee.
  ///
  /// In en, this message translates to:
  /// **'Processing Fee'**
  String get studentChargeFeeCodeProcessingFee;

  /// No description provided for @studentChargeFeeCodeLatePaymentFee.
  ///
  /// In en, this message translates to:
  /// **'Late Payment Fee'**
  String get studentChargeFeeCodeLatePaymentFee;

  /// No description provided for @studentChargeFeeCodeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get studentChargeFeeCodeRefund;

  /// No description provided for @studentChargeFeeCodeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get studentChargeFeeCodeOther;

  /// No description provided for @studentChargeFeeCodeFallback.
  ///
  /// In en, this message translates to:
  /// **'School fee'**
  String get studentChargeFeeCodeFallback;

  /// No description provided for @facturationSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Students'**
  String get facturationSearchTitle;

  /// No description provided for @facturationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter First name, Last name, Surname and/or Cycle/Level to filter results.'**
  String get facturationSearchHint;

  /// No description provided for @facturationSearchInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'No search in progress'**
  String get facturationSearchInvitationTitle;

  /// No description provided for @facturationSearchInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a name or level above to display matching students.'**
  String get facturationSearchInvitationMessage;

  /// No description provided for @facturationViewChargesLabel.
  ///
  /// In en, this message translates to:
  /// **'View charges'**
  String get facturationViewChargesLabel;

  /// No description provided for @facturationActionsColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get facturationActionsColumnLabel;

  /// No description provided for @facturationNoResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'No student matches these criteria. Update the form and try again.'**
  String get facturationNoResultsDescription;

  /// No description provided for @facturationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No student found'**
  String get facturationEmptyTitle;

  /// No description provided for @facturationSearchHelpBanner.
  ///
  /// In en, this message translates to:
  /// **'Search for a specific student (last name + middle name + first name) or a whole class (cycle + level). You can also combine both to refine.'**
  String get facturationSearchHelpBanner;

  /// No description provided for @facturationSearchByStudentGroup.
  ///
  /// In en, this message translates to:
  /// **'By student'**
  String get facturationSearchByStudentGroup;

  /// No description provided for @facturationSearchByClassGroup.
  ///
  /// In en, this message translates to:
  /// **'By class'**
  String get facturationSearchByClassGroup;

  /// No description provided for @facturationSearchOrSeparator.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get facturationSearchOrSeparator;

  /// No description provided for @facturationSearchActiveModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active search by:'**
  String get facturationSearchActiveModeLabel;

  /// No description provided for @facturationSearchModeStudentBadge.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get facturationSearchModeStudentBadge;

  /// No description provided for @facturationSearchModeClassBadge.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get facturationSearchModeClassBadge;

  /// No description provided for @facturationSearchCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get facturationSearchCycleLabel;

  /// No description provided for @facturationSearchLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get facturationSearchLevelLabel;

  /// No description provided for @facturationSearchLevelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pick a cycle first'**
  String get facturationSearchLevelPlaceholder;

  /// Billing AppBar pill when the balance is outstanding.
  ///
  /// In en, this message translates to:
  /// **'{amount} due'**
  String facturationBalanceDuePill(String amount);

  /// No description provided for @facturationBalanceUpToDatePill.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get facturationBalanceUpToDatePill;

  /// Fee line footer: amount remaining to pay.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String facturationChargeLineRemainingSuffix(String amount);

  /// Confirmation toast after a successful payment.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} recorded'**
  String facturationPaymentRecordedToast(String amount);

  /// No description provided for @facturationChargeStatementCopied.
  ///
  /// In en, this message translates to:
  /// **'Statement copied to clipboard'**
  String get facturationChargeStatementCopied;

  /// No description provided for @facturationChargeStatementEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payment to export for this fee.'**
  String get facturationChargeStatementEmpty;

  /// No description provided for @facturationCsvHeaderFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get facturationCsvHeaderFee;

  /// No description provided for @facturationCsvHeaderImputedAmount.
  ///
  /// In en, this message translates to:
  /// **'Imputed amount (USD)'**
  String get facturationCsvHeaderImputedAmount;

  /// No description provided for @facturationDetailBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to billing'**
  String get facturationDetailBackLabel;

  /// No description provided for @facturationDetailContextErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail context unavailable'**
  String get facturationDetailContextErrorTitle;

  /// No description provided for @facturationDetailContextErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Required context for this detail view is missing. Go back to billing list and open the detail again.'**
  String get facturationDetailContextErrorMessage;

  /// No description provided for @facturationDetailUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get facturationDetailUnknownValue;

  /// No description provided for @facturationDetailStudentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Student information'**
  String get facturationDetailStudentSectionTitle;

  /// No description provided for @facturationDetailStudentLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get facturationDetailStudentLastName;

  /// No description provided for @facturationDetailStudentFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get facturationDetailStudentFirstName;

  /// No description provided for @facturationDetailStudentSurname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get facturationDetailStudentSurname;

  /// No description provided for @facturationDetailStudentLevelGroup.
  ///
  /// In en, this message translates to:
  /// **'Level group'**
  String get facturationDetailStudentLevelGroup;

  /// No description provided for @facturationDetailStudentLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get facturationDetailStudentLevel;

  /// No description provided for @facturationDetailInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial record'**
  String get facturationDetailInfoTitle;

  /// No description provided for @facturationDetailEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get facturationDetailEyebrow;

  /// No description provided for @facturationDetailInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review recent payments and student charge status for this student.'**
  String get facturationDetailInfoSubtitle;

  /// No description provided for @facturationDetailHeaderKpiTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get facturationDetailHeaderKpiTotalDue;

  /// No description provided for @facturationDetailHeaderKpiAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Already paid'**
  String get facturationDetailHeaderKpiAlreadyPaid;

  /// No description provided for @facturationDetailHeaderKpiRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining due'**
  String get facturationDetailHeaderKpiRemaining;

  /// No description provided for @facturationDetailInfoChipPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get facturationDetailInfoChipPayments;

  /// No description provided for @facturationDetailInfoChipCharges.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get facturationDetailInfoChipCharges;

  /// No description provided for @facturationDetailPaymentsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get facturationDetailPaymentsSectionTitle;

  /// No description provided for @facturationDetailPaymentsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recorded payment history for this student.'**
  String get facturationDetailPaymentsSectionSubtitle;

  /// No description provided for @facturationDetailPaymentsRecordedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payment recorded} =1{1 payment recorded} other{{count} payments recorded}}'**
  String facturationDetailPaymentsRecordedCount(num count);

  /// Payments section subtitle: payment count + total paid.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payment recorded} =1{1 payment · {total}} other{{count} payments · {total}}}'**
  String facturationDetailPaymentsRecordedWithTotal(int count, String total);

  /// No description provided for @facturationPaymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get facturationPaymentMethodCash;

  /// No description provided for @facturationDetailCollectPaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Collect payment'**
  String get facturationDetailCollectPaymentAction;

  /// No description provided for @facturationDetailPaymentsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get facturationDetailPaymentsRetry;

  /// No description provided for @facturationDetailPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payment has been recorded for this student.'**
  String get facturationDetailPaymentsEmpty;

  /// No description provided for @facturationDetailPaymentPayerColumn.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get facturationDetailPaymentPayerColumn;

  /// No description provided for @facturationDetailPaymentPaidAtColumn.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get facturationDetailPaymentPaidAtColumn;

  /// No description provided for @facturationDetailPaymentAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get facturationDetailPaymentAmountColumn;

  /// No description provided for @facturationDetailPaymentActionsColumn.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get facturationDetailPaymentActionsColumn;

  /// No description provided for @facturationDetailViewPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'View payment detail'**
  String get facturationDetailViewPaymentLabel;

  /// No description provided for @facturationDetailViewChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'View charge detail'**
  String get facturationDetailViewChargeLabel;

  /// No description provided for @facturationPaymentDetailHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment detail'**
  String get facturationPaymentDetailHeroTitle;

  /// No description provided for @facturationPaymentDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review this payment information and the breakdown of allocated amounts.'**
  String get facturationPaymentDetailHeroSubtitle;

  /// No description provided for @facturationPaymentInfoSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment information'**
  String get facturationPaymentInfoSectionTitle;

  /// No description provided for @facturationPaymentPayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get facturationPaymentPayerLabel;

  /// No description provided for @facturationPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total paid amount'**
  String get facturationPaymentAmountLabel;

  /// No description provided for @facturationPaymentPaidAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid at'**
  String get facturationPaymentPaidAtLabel;

  /// No description provided for @facturationPaymentAmountPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get facturationPaymentAmountPaidLabel;

  /// No description provided for @facturationPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get facturationPaymentMethodLabel;

  /// No description provided for @facturationPaymentCollectedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Collected by'**
  String get facturationPaymentCollectedByLabel;

  /// No description provided for @facturationPaymentReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt no.'**
  String get facturationPaymentReceiptLabel;

  /// No description provided for @facturationPaymentStudentLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get facturationPaymentStudentLabel;

  /// No description provided for @facturationPaymentDownloadReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get facturationPaymentDownloadReceiptLabel;

  /// No description provided for @facturationPaymentCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get facturationPaymentCloseLabel;

  /// No description provided for @facturationPaymentAllocationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown by fee'**
  String get facturationPaymentAllocationsSectionTitle;

  /// No description provided for @facturationPaymentAllocationsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List of charges covered by this payment.'**
  String get facturationPaymentAllocationsSectionSubtitle;

  /// No description provided for @facturationPaymentAllocationsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Allocated total'**
  String get facturationPaymentAllocationsTotalLabel;

  /// No description provided for @facturationPaymentAllocationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No allocation was found for this payment.'**
  String get facturationPaymentAllocationsEmpty;

  /// No description provided for @facturationPaymentAllocationsConsistencyOk.
  ///
  /// In en, this message translates to:
  /// **'Allocation sum is consistent with the total paid amount.'**
  String get facturationPaymentAllocationsConsistencyOk;

  /// No description provided for @facturationPaymentAllocationsConsistencyWarning.
  ///
  /// In en, this message translates to:
  /// **'Inconsistency detected: allocation sum does not match the total paid amount.'**
  String get facturationPaymentAllocationsConsistencyWarning;

  /// No description provided for @facturationPaymentAllocationsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load payment allocations. Please check your internet connection.'**
  String get facturationPaymentAllocationsNetworkError;

  /// No description provided for @facturationPaymentAllocationsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No allocation found for this payment.'**
  String get facturationPaymentAllocationsNotFound;

  /// No description provided for @facturationPaymentAllocationsValidationError.
  ///
  /// In en, this message translates to:
  /// **'Requested allocation data is invalid.'**
  String get facturationPaymentAllocationsValidationError;

  /// No description provided for @facturationPaymentAllocationsUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to access allocations for this payment.'**
  String get facturationPaymentAllocationsUnauthorizedError;

  /// No description provided for @facturationPaymentAllocationsInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow access to allocations for this payment.'**
  String get facturationPaymentAllocationsInvalidCredentialsError;

  /// No description provided for @facturationPaymentAllocationsServerError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable.'**
  String get facturationPaymentAllocationsServerError;

  /// No description provided for @facturationPaymentAllocationsStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local error prevents allocations from being displayed.'**
  String get facturationPaymentAllocationsStorageError;

  /// No description provided for @facturationPaymentAllocationsAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents allocations from loading.'**
  String get facturationPaymentAllocationsAuthError;

  /// No description provided for @facturationPaymentAllocationsUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading allocations.'**
  String get facturationPaymentAllocationsUnknownError;

  /// No description provided for @facturationDetailChargesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get facturationDetailChargesSectionTitle;

  /// No description provided for @facturationDetailChargesSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown of expected, paid and remaining amounts.'**
  String get facturationDetailChargesSectionSubtitle;

  /// No description provided for @facturationDetailChargesSummary.
  ///
  /// In en, this message translates to:
  /// **'{totalCount, plural, =0{0 charge} =1{1 charge} other{{totalCount} charges}} · {partialCount} partial, {dueCount} to settle'**
  String facturationDetailChargesSummary(
    num totalCount,
    Object partialCount,
    Object dueCount,
  );

  /// No description provided for @facturationDetailChargesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get facturationDetailChargesRetry;

  /// No description provided for @facturationDetailChargesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No charge was found for this student.'**
  String get facturationDetailChargesEmpty;

  /// No description provided for @facturationDetailChargeLabelColumn.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get facturationDetailChargeLabelColumn;

  /// No description provided for @facturationDetailChargeExpectedAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get facturationDetailChargeExpectedAmountColumn;

  /// No description provided for @facturationDetailChargePaidAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get facturationDetailChargePaidAmountColumn;

  /// No description provided for @facturationDetailChargeRemainingAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get facturationDetailChargeRemainingAmountColumn;

  /// No description provided for @facturationDetailChargeStatusColumn.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get facturationDetailChargeStatusColumn;

  /// No description provided for @facturationDetailChargeTotalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get facturationDetailChargeTotalsLabel;

  /// No description provided for @facturationPaymentsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load payments. Please check your internet connection.'**
  String get facturationPaymentsNetworkError;

  /// No description provided for @facturationPaymentsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No payment was found for this student.'**
  String get facturationPaymentsNotFound;

  /// No description provided for @facturationPaymentsValidationError.
  ///
  /// In en, this message translates to:
  /// **'Requested payment data is invalid.'**
  String get facturationPaymentsValidationError;

  /// No description provided for @facturationPaymentsUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to access these payments.'**
  String get facturationPaymentsUnauthorizedError;

  /// No description provided for @facturationPaymentsInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow access to these payments.'**
  String get facturationPaymentsInvalidCredentialsError;

  /// No description provided for @facturationPaymentsServerError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable.'**
  String get facturationPaymentsServerError;

  /// No description provided for @facturationPaymentsStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local error prevents payments from being displayed.'**
  String get facturationPaymentsStorageError;

  /// No description provided for @facturationPaymentsAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents payments from loading.'**
  String get facturationPaymentsAuthError;

  /// No description provided for @facturationPaymentsUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading payments.'**
  String get facturationPaymentsUnknownError;

  /// No description provided for @facturationPrintReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get facturationPrintReceiptLabel;

  /// No description provided for @facturationPrintReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate and download the receipt for this payment'**
  String get facturationPrintReceiptSubtitle;

  /// No description provided for @facturationPaymentDownloadPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get facturationPaymentDownloadPdfLabel;

  /// No description provided for @facturationPrintStatementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Print statements'**
  String get facturationPrintStatementsLabel;

  /// No description provided for @facturationPrintStatementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate and download the billing statements for this student'**
  String get facturationPrintStatementsSubtitle;

  /// No description provided for @facturationChargeDetailBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to billing detail'**
  String get facturationChargeDetailBackLabel;

  /// No description provided for @facturationChargeDetailHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Fee details'**
  String get facturationChargeDetailHeroTitle;

  /// No description provided for @facturationChargeDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review this charge status and the payments allocated to it.'**
  String get facturationChargeDetailHeroSubtitle;

  /// No description provided for @facturationChargeDetailInfoSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Charge information'**
  String get facturationChargeDetailInfoSectionTitle;

  /// No description provided for @facturationChargeDetailExpectedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected amount'**
  String get facturationChargeDetailExpectedAmountLabel;

  /// No description provided for @facturationChargeDetailPaidAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid amount'**
  String get facturationChargeDetailPaidAmountLabel;

  /// No description provided for @facturationChargeDetailRemainingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get facturationChargeDetailRemainingAmountLabel;

  /// No description provided for @facturationChargeDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get facturationChargeDetailStatusLabel;

  /// No description provided for @facturationChargeDetailAllocationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Applied payments'**
  String get facturationChargeDetailAllocationsSectionTitle;

  /// No description provided for @facturationChargeDetailAllocationsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown of payments allocated to this charge.'**
  String get facturationChargeDetailAllocationsSectionSubtitle;

  /// No description provided for @facturationChargeDetailAllocationLabelColumn.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get facturationChargeDetailAllocationLabelColumn;

  /// No description provided for @facturationChargeDetailAllocationsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Allocated total'**
  String get facturationChargeDetailAllocationsTotalLabel;

  /// No description provided for @facturationChargeDetailAllocationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No allocation was found for this charge.'**
  String get facturationChargeDetailAllocationsEmpty;

  /// No description provided for @facturationChargeDetailAllocationsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get facturationChargeDetailAllocationsRetry;

  /// No description provided for @facturationChargeDetailAllocationsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load allocations. Please check your internet connection.'**
  String get facturationChargeDetailAllocationsNetworkError;

  /// No description provided for @facturationChargeDetailAllocationsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No allocation found for this charge.'**
  String get facturationChargeDetailAllocationsNotFound;

  /// No description provided for @facturationChargeDetailAllocationsValidationError.
  ///
  /// In en, this message translates to:
  /// **'Requested allocation data is invalid.'**
  String get facturationChargeDetailAllocationsValidationError;

  /// No description provided for @facturationChargeDetailAllocationsUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to access allocations for this charge.'**
  String get facturationChargeDetailAllocationsUnauthorizedError;

  /// No description provided for @facturationChargeDetailAllocationsInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow access to allocations for this charge.'**
  String get facturationChargeDetailAllocationsInvalidCredentialsError;

  /// No description provided for @facturationChargeDetailAllocationsServerError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable.'**
  String get facturationChargeDetailAllocationsServerError;

  /// No description provided for @facturationChargeDetailAllocationsStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local error prevents allocations from being displayed.'**
  String get facturationChargeDetailAllocationsStorageError;

  /// No description provided for @facturationChargeDetailAllocationsAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents allocations from loading.'**
  String get facturationChargeDetailAllocationsAuthError;

  /// No description provided for @facturationChargeDetailAllocationsUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading allocations.'**
  String get facturationChargeDetailAllocationsUnknownError;

  /// No description provided for @facturationChargeDetailContextErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Charge detail context unavailable'**
  String get facturationChargeDetailContextErrorTitle;

  /// No description provided for @facturationChargeDetailContextErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Required context for this charge detail view is missing. Go back and open the detail again.'**
  String get facturationChargeDetailContextErrorMessage;

  /// No description provided for @facturationCreatePaymentBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to billing detail'**
  String get facturationCreatePaymentBackLabel;

  /// No description provided for @facturationCreatePaymentHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'New payment'**
  String get facturationCreatePaymentHeroTitle;

  /// No description provided for @facturationCreatePaymentHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the payer information and allocations to record a payment.'**
  String get facturationCreatePaymentHeroSubtitle;

  /// No description provided for @facturationCreatePaymentPayerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payer information'**
  String get facturationCreatePaymentPayerSectionTitle;

  /// No description provided for @facturationCreatePaymentPayerLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get facturationCreatePaymentPayerLastNameLabel;

  /// No description provided for @facturationCreatePaymentPayerLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get facturationCreatePaymentPayerLastNameHint;

  /// No description provided for @facturationCreatePaymentPayerFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get facturationCreatePaymentPayerFirstNameLabel;

  /// No description provided for @facturationCreatePaymentPayerFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get facturationCreatePaymentPayerFirstNameHint;

  /// No description provided for @facturationCreatePaymentPayerMiddleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Surname (optional)'**
  String get facturationCreatePaymentPayerMiddleNameLabel;

  /// No description provided for @facturationCreatePaymentPayerMiddleNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter surname'**
  String get facturationCreatePaymentPayerMiddleNameHint;

  /// No description provided for @facturationCreatePaymentPayerFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get facturationCreatePaymentPayerFieldRequired;

  /// No description provided for @facturationCreatePaymentDetailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get facturationCreatePaymentDetailsSectionTitle;

  /// No description provided for @facturationCreatePaymentDetailsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the received amount, currency and payment date.'**
  String get facturationCreatePaymentDetailsSectionSubtitle;

  /// No description provided for @facturationCreatePaymentReceivedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get facturationCreatePaymentReceivedAmountLabel;

  /// No description provided for @facturationCreatePaymentReceivedAmountHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: 200'**
  String get facturationCreatePaymentReceivedAmountHint;

  /// No description provided for @facturationCreatePaymentCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get facturationCreatePaymentCurrencyLabel;

  /// No description provided for @facturationCreatePaymentCurrencyReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple currencies detected: read-only value.'**
  String get facturationCreatePaymentCurrencyReadOnlyHint;

  /// No description provided for @facturationCreatePaymentCurrencyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currency unavailable'**
  String get facturationCreatePaymentCurrencyUnavailable;

  /// No description provided for @facturationCreatePaymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get facturationCreatePaymentDateLabel;

  /// No description provided for @facturationCreatePaymentAllocationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment allocations'**
  String get facturationCreatePaymentAllocationSectionTitle;

  /// No description provided for @facturationCreatePaymentAllocationSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Associate an amount to one or more student charges.'**
  String get facturationCreatePaymentAllocationSectionSubtitle;

  /// No description provided for @facturationCreatePaymentAddAllocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Add allocation'**
  String get facturationCreatePaymentAddAllocationLabel;

  /// No description provided for @facturationCreatePaymentAllChargesPaid.
  ///
  /// In en, this message translates to:
  /// **'All student charges are already paid.'**
  String get facturationCreatePaymentAllChargesPaid;

  /// No description provided for @facturationCreatePaymentChargesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No charges available. Go back to the list and try again.'**
  String get facturationCreatePaymentChargesUnavailable;

  /// No description provided for @facturationCreatePaymentChargeDropdownHint.
  ///
  /// In en, this message translates to:
  /// **'Select a charge'**
  String get facturationCreatePaymentChargeDropdownHint;

  /// No description provided for @facturationCreatePaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get facturationCreatePaymentAmountLabel;

  /// No description provided for @facturationCreatePaymentAmountHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: 5000'**
  String get facturationCreatePaymentAmountHint;

  /// No description provided for @facturationCreatePaymentAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get facturationCreatePaymentAmountRequired;

  /// No description provided for @facturationCreatePaymentAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get facturationCreatePaymentAmountInvalid;

  /// No description provided for @facturationCreatePaymentAmountExceedsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed remaining balance'**
  String get facturationCreatePaymentAmountExceedsRemaining;

  /// No description provided for @facturationCreatePaymentAmountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get facturationCreatePaymentAmountMustBePositive;

  /// No description provided for @facturationCreatePaymentBeforeLabel.
  ///
  /// In en, this message translates to:
  /// **'Before payment'**
  String get facturationCreatePaymentBeforeLabel;

  /// No description provided for @facturationCreatePaymentAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'After payment'**
  String get facturationCreatePaymentAfterLabel;

  /// No description provided for @facturationCreatePaymentRemoveAllocationConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm removal'**
  String get facturationCreatePaymentRemoveAllocationConfirmTitle;

  /// No description provided for @facturationCreatePaymentRemoveAllocationConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to remove allocation #{allocationIndex}? This action cannot be undone.'**
  String facturationCreatePaymentRemoveAllocationConfirmMessage(
    int allocationIndex,
  );

  /// No description provided for @facturationCreatePaymentRemoveAllocationConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get facturationCreatePaymentRemoveAllocationConfirmAction;

  /// No description provided for @facturationCreatePaymentSubmitLabel.
  ///
  /// In en, this message translates to:
  /// **'Validate payment'**
  String get facturationCreatePaymentSubmitLabel;

  /// No description provided for @facturationCreatePaymentNoAllocations.
  ///
  /// In en, this message translates to:
  /// **'Add at least one allocation to validate the payment.'**
  String get facturationCreatePaymentNoAllocations;

  /// No description provided for @facturationCreatePaymentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get facturationCreatePaymentConfirmTitle;

  /// No description provided for @facturationCreatePaymentConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This operation is irreversible. Do you confirm recording this payment?'**
  String get facturationCreatePaymentConfirmMessage;

  /// No description provided for @facturationCreatePaymentConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get facturationCreatePaymentConfirmCancel;

  /// No description provided for @facturationCreatePaymentConfirmValidate.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get facturationCreatePaymentConfirmValidate;

  /// No description provided for @facturationCreatePaymentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Payment successfully recorded.'**
  String get facturationCreatePaymentSuccessMessage;

  /// No description provided for @facturationCreatePaymentExpectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get facturationCreatePaymentExpectedLabel;

  /// No description provided for @facturationCreatePaymentPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Already paid'**
  String get facturationCreatePaymentPaidLabel;

  /// No description provided for @facturationCreatePaymentRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get facturationCreatePaymentRemainingLabel;

  /// No description provided for @facturationCreatePaymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get facturationCreatePaymentStatusLabel;

  /// No description provided for @facturationCreatePaymentChargeImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Impact on charge'**
  String get facturationCreatePaymentChargeImpactTitle;

  /// No description provided for @facturationCreatePaymentChargeRemainingHelper.
  ///
  /// In en, this message translates to:
  /// **'Remaining on this charge: {remainingAmount}'**
  String facturationCreatePaymentChargeRemainingHelper(String remainingAmount);

  /// No description provided for @facturationCreatePaymentPayAllAction.
  ///
  /// In en, this message translates to:
  /// **'Pay all'**
  String get facturationCreatePaymentPayAllAction;

  /// No description provided for @facturationCreatePaymentDistributionTrackerIdle.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one allocation to compute total payments.'**
  String get facturationCreatePaymentDistributionTrackerIdle;

  /// No description provided for @facturationCreatePaymentFooterTotalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total payments: {allocatedAmount}'**
  String facturationCreatePaymentFooterTotalPayments(String allocatedAmount);

  /// No description provided for @facturationCreatePaymentNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get facturationCreatePaymentNetworkError;

  /// No description provided for @facturationCreatePaymentNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get facturationCreatePaymentNotFoundError;

  /// No description provided for @facturationCreatePaymentValidationError.
  ///
  /// In en, this message translates to:
  /// **'Submitted data is invalid. Please review the form.'**
  String get facturationCreatePaymentValidationError;

  /// No description provided for @facturationCreatePaymentUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform this operation.'**
  String get facturationCreatePaymentUnauthorizedError;

  /// No description provided for @facturationCreatePaymentInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow recording this payment.'**
  String get facturationCreatePaymentInvalidCredentialsError;

  /// No description provided for @facturationCreatePaymentServerError.
  ///
  /// In en, this message translates to:
  /// **'Server is unavailable. Please try again later.'**
  String get facturationCreatePaymentServerError;

  /// No description provided for @facturationCreatePaymentStorageError.
  ///
  /// In en, this message translates to:
  /// **'A storage error occurred.'**
  String get facturationCreatePaymentStorageError;

  /// No description provided for @facturationCreatePaymentAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error occurred.'**
  String get facturationCreatePaymentAuthError;

  /// No description provided for @facturationCreatePaymentUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get facturationCreatePaymentUnknownError;

  /// No description provided for @facturationCreatePaymentNoChargesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No unpaid charges available for this student.'**
  String get facturationCreatePaymentNoChargesAvailable;

  /// No description provided for @facturationCreatePaymentChargesToSettleTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees to settle'**
  String get facturationCreatePaymentChargesToSettleTitle;

  /// No description provided for @facturationCreatePaymentChargesToSettleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the fees to settle and adjust the amounts.'**
  String get facturationCreatePaymentChargesToSettleSubtitle;

  /// No description provided for @facturationCreatePaymentAllFeesSettled.
  ///
  /// In en, this message translates to:
  /// **'All fees are already settled.'**
  String get facturationCreatePaymentAllFeesSettled;

  /// No description provided for @facturationCreatePaymentChargeDue.
  ///
  /// In en, this message translates to:
  /// **'Due {amount}'**
  String facturationCreatePaymentChargeDue(String amount);

  /// No description provided for @facturationCreatePaymentChargePaid.
  ///
  /// In en, this message translates to:
  /// **'Already paid {amount}'**
  String facturationCreatePaymentChargePaid(String amount);

  /// No description provided for @facturationCreatePaymentChargeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining {amount}'**
  String facturationCreatePaymentChargeRemaining(String amount);

  /// No description provided for @facturationCreatePaymentAmountToSettleLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to settle'**
  String get facturationCreatePaymentAmountToSettleLabel;

  /// No description provided for @facturationCreatePaymentSettleAllAction.
  ///
  /// In en, this message translates to:
  /// **'Settle all'**
  String get facturationCreatePaymentSettleAllAction;

  /// No description provided for @facturationCreatePaymentAmountClampedWarning.
  ///
  /// In en, this message translates to:
  /// **'Amount capped to the remaining balance ({amount}).'**
  String facturationCreatePaymentAmountClampedWarning(String amount);

  /// No description provided for @facturationCreatePaymentRemainingAfter.
  ///
  /// In en, this message translates to:
  /// **'Remaining after: {amount}'**
  String facturationCreatePaymentRemainingAfter(String amount);

  /// No description provided for @facturationCreatePaymentSettledChip.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get facturationCreatePaymentSettledChip;

  /// No description provided for @facturationCreatePaymentTotalToCollect.
  ///
  /// In en, this message translates to:
  /// **'Total to collect'**
  String get facturationCreatePaymentTotalToCollect;

  /// No description provided for @facturationCreatePaymentCollectAmountAction.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount}'**
  String facturationCreatePaymentCollectAmountAction(String amount);

  /// No description provided for @facturationCreatePaymentConfirmCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount}?'**
  String facturationCreatePaymentConfirmCollectTitle(String amount);

  /// No description provided for @facturationCreatePaymentConfirmSentence.
  ///
  /// In en, this message translates to:
  /// **'You are about to collect {amount} for {student}, paid by {payer}.'**
  String facturationCreatePaymentConfirmSentence(
    String amount,
    String student,
    String payer,
  );

  /// No description provided for @facturationCreatePaymentConfirmDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get facturationCreatePaymentConfirmDistributionTitle;

  /// No description provided for @facturationCollectStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get facturationCollectStepConfirm;

  /// No description provided for @facturationCollectStepResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get facturationCollectStepResult;

  /// No description provided for @facturationCollectSimulateFailure.
  ///
  /// In en, this message translates to:
  /// **'Simulate a failure'**
  String get facturationCollectSimulateFailure;

  /// No description provided for @facturationCollectProcessing.
  ///
  /// In en, this message translates to:
  /// **'Recording the payment…'**
  String get facturationCollectProcessing;

  /// No description provided for @facturationCollectSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get facturationCollectSuccessTitle;

  /// No description provided for @facturationCollectReceiptChip.
  ///
  /// In en, this message translates to:
  /// **'Receipt no. {code}'**
  String facturationCollectReceiptChip(String code);

  /// No description provided for @facturationCollectErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection failed'**
  String get facturationCollectErrorTitle;

  /// No description provided for @facturationCollectErrorNoDebit.
  ///
  /// In en, this message translates to:
  /// **'No amount was debited.'**
  String get facturationCollectErrorNoDebit;

  /// No description provided for @facturationCollectIncidentChip.
  ///
  /// In en, this message translates to:
  /// **'Incident code: {code}'**
  String facturationCollectIncidentChip(String code);

  /// No description provided for @facturationCollectEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get facturationCollectEditAction;

  /// No description provided for @facturationCollectRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get facturationCollectRetryAction;

  /// No description provided for @attendanceHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceHeroTitle;

  /// No description provided for @attendanceHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View class attendance by date for reliable daily tracking.'**
  String get attendanceHeroSubtitle;

  /// No description provided for @attendanceHeroChipClass.
  ///
  /// In en, this message translates to:
  /// **'Class-based search'**
  String get attendanceHeroChipClass;

  /// No description provided for @attendanceHeroChipDate.
  ///
  /// In en, this message translates to:
  /// **'Date filter'**
  String get attendanceHeroChipDate;

  /// No description provided for @attendanceSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Search'**
  String get attendanceSearchTitle;

  /// No description provided for @attendanceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Select cycle, level, class and date to display attendance records.'**
  String get attendanceSearchHint;

  /// No description provided for @attendanceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get attendanceDateLabel;

  /// No description provided for @attendanceCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get attendanceCycleLabel;

  /// No description provided for @attendanceLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get attendanceLevelLabel;

  /// No description provided for @attendanceClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get attendanceClassLabel;

  /// No description provided for @attendanceShowClassAction.
  ///
  /// In en, this message translates to:
  /// **'Show class'**
  String get attendanceShowClassAction;

  /// No description provided for @attendanceInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Run a search to display attendance for the selected class.'**
  String get attendanceInvitationMessage;

  /// No description provided for @attendanceSelectClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a class'**
  String get attendanceSelectClassTitle;

  /// No description provided for @attendanceEmptySelectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a cycle, a level, and then a class to load the attendance list.'**
  String get attendanceEmptySelectionMessage;

  /// No description provided for @attendanceLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading attendance records...'**
  String get attendanceLoadingMessage;

  /// No description provided for @attendanceEmptyStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No students in this class'**
  String get attendanceEmptyStudentsTitle;

  /// No description provided for @attendanceEmptyStudentsDescription.
  ///
  /// In en, this message translates to:
  /// **'This class has no students yet. Add students from the class Composition to take attendance.'**
  String get attendanceEmptyStudentsDescription;

  /// No description provided for @attendanceEmptyOpenComposition.
  ///
  /// In en, this message translates to:
  /// **'Open Composition'**
  String get attendanceEmptyOpenComposition;

  /// No description provided for @attendanceExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get attendanceExportAction;

  /// No description provided for @attendanceExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Prepare result export'**
  String get attendanceExportTooltip;

  /// No description provided for @attendanceExportSoon.
  ///
  /// In en, this message translates to:
  /// **'Export will be available soon.'**
  String get attendanceExportSoon;

  /// No description provided for @attendanceSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get attendanceSaveAction;

  /// No description provided for @attendanceSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get attendanceSavingAction;

  /// No description provided for @attendanceSaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save all entered changes'**
  String get attendanceSaveTooltip;

  /// No description provided for @attendanceSaveValidationHint.
  ///
  /// In en, this message translates to:
  /// **'Fix absent rows without a reason before saving.'**
  String get attendanceSaveValidationHint;

  /// No description provided for @attendanceSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Attendance records were saved successfully.'**
  String get attendanceSaveSuccess;

  /// No description provided for @attendanceValidateCallAction.
  ///
  /// In en, this message translates to:
  /// **'Validate attendance'**
  String get attendanceValidateCallAction;

  /// No description provided for @attendancePendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get attendancePendingChanges;

  /// No description provided for @attendancePendingInvalidChanges.
  ///
  /// In en, this message translates to:
  /// **'Fixes required'**
  String get attendancePendingInvalidChanges;

  /// No description provided for @attendanceRowModifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get attendanceRowModifiedLabel;

  /// No description provided for @attendanceUnsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get attendanceUnsavedChangesTitle;

  /// No description provided for @attendanceUnsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'A new search will discard unsaved changes. Do you want to continue?'**
  String get attendanceUnsavedChangesMessage;

  /// No description provided for @attendanceDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Choose the attendance date'**
  String get attendanceDateTooltip;

  /// No description provided for @attendanceStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Attendance in progress'**
  String get attendanceStatusInProgress;

  /// No description provided for @attendanceStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to validate'**
  String get attendanceStatusReady;

  /// No description provided for @attendancePresentCount.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresentCount;

  /// No description provided for @attendanceJustifiedCount.
  ///
  /// In en, this message translates to:
  /// **'Justified'**
  String get attendanceJustifiedCount;

  /// No description provided for @attendanceUnjustifiedCount.
  ///
  /// In en, this message translates to:
  /// **'Unjustified'**
  String get attendanceUnjustifiedCount;

  /// No description provided for @attendancePendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending reason'**
  String get attendancePendingCount;

  /// No description provided for @attendanceAbsentCount.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsentCount;

  /// No description provided for @attendanceTotalCountCompact.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get attendanceTotalCountCompact;

  /// No description provided for @attendanceDefaultPresenceHelper.
  ///
  /// In en, this message translates to:
  /// **'All students are marked present by default. Tap Absent to report an exception.'**
  String get attendanceDefaultPresenceHelper;

  /// No description provided for @attendanceReadyToValidate.
  ///
  /// In en, this message translates to:
  /// **'No absence is missing a reason. You can validate attendance.'**
  String get attendanceReadyToValidate;

  /// No description provided for @attendanceMissingReasonsStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} absence(s) without reason - complete required'**
  String attendanceMissingReasonsStatus(int count);

  /// No description provided for @attendanceAllPresentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm attendance'**
  String get attendanceAllPresentConfirmTitle;

  /// No description provided for @attendanceAllPresentConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you confirm that all {count} students are present?'**
  String attendanceAllPresentConfirmMessage(int count);

  /// No description provided for @attendanceTotalCount.
  ///
  /// In en, this message translates to:
  /// **'Total students'**
  String get attendanceTotalCount;

  /// No description provided for @attendanceGirlsCount.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get attendanceGirlsCount;

  /// No description provided for @attendanceBoysCount.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get attendanceBoysCount;

  /// No description provided for @attendanceCriteriaSummary.
  ///
  /// In en, this message translates to:
  /// **'Class: {classroomName} · Date: {formattedDate}'**
  String attendanceCriteriaSummary(String classroomName, String formattedDate);

  /// No description provided for @attendanceTableLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get attendanceTableLastName;

  /// No description provided for @attendanceTableMiddleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get attendanceTableMiddleName;

  /// No description provided for @attendanceTableFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get attendanceTableFirstName;

  /// No description provided for @attendanceTablePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendanceTablePresent;

  /// No description provided for @attendanceTableAbsenceReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get attendanceTableAbsenceReason;

  /// No description provided for @attendanceTableAbsenceReasonNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get attendanceTableAbsenceReasonNote;

  /// No description provided for @attendancePresenceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance status'**
  String get attendancePresenceStatusLabel;

  /// No description provided for @attendancePresentValue.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresentValue;

  /// No description provided for @attendanceAbsentValue.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsentValue;

  /// No description provided for @attendanceReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only informational status'**
  String get attendanceReadOnlyHint;

  /// No description provided for @attendanceReasonRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for this absence.'**
  String get attendanceReasonRequiredError;

  /// No description provided for @attendanceReasonRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Reason required for an absence.'**
  String get attendanceReasonRequiredHint;

  /// No description provided for @attendanceMotifRequisLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason required'**
  String get attendanceMotifRequisLabel;

  /// No description provided for @attendanceReasonDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Reason is required only when the student is absent.'**
  String get attendanceReasonDisabledHint;

  /// No description provided for @attendanceNoteDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Note is optional only when the student is absent.'**
  String get attendanceNoteDisabledHint;

  /// No description provided for @attendanceNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add details if needed'**
  String get attendanceNotePlaceholder;

  /// No description provided for @attendanceNoMiddleName.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get attendanceNoMiddleName;

  /// No description provided for @attendanceNoAbsenceReason.
  ///
  /// In en, this message translates to:
  /// **'No reason'**
  String get attendanceNoAbsenceReason;

  /// No description provided for @attendanceNoAbsenceNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get attendanceNoAbsenceNote;

  /// No description provided for @attendanceErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get attendanceErrorNetwork;

  /// No description provided for @attendanceErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'No attendance resource was found.'**
  String get attendanceErrorNotFound;

  /// No description provided for @attendanceErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Submitted data is invalid.'**
  String get attendanceErrorValidation;

  /// No description provided for @attendanceErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to access this resource.'**
  String get attendanceErrorUnauthorized;

  /// No description provided for @attendanceErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow access to attendance.'**
  String get attendanceErrorInvalidCredentials;

  /// No description provided for @attendanceErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server is unavailable. Please try again later.'**
  String get attendanceErrorServer;

  /// No description provided for @attendanceErrorStorage.
  ///
  /// In en, this message translates to:
  /// **'A local storage error occurred.'**
  String get attendanceErrorStorage;

  /// No description provided for @attendanceErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'An authentication error occurred.'**
  String get attendanceErrorAuth;

  /// No description provided for @attendanceErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get attendanceErrorUnknown;

  /// No description provided for @attendanceErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have the required permissions to view attendance.'**
  String get attendanceErrorForbidden;

  /// No description provided for @attendanceErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get attendanceErrorRetry;

  /// No description provided for @attendanceErrorReconnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get attendanceErrorReconnect;

  /// No description provided for @attendanceErrorContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact the administrator'**
  String get attendanceErrorContactAdmin;

  /// No description provided for @attendanceErrorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get attendanceErrorNetworkTitle;

  /// No description provided for @attendanceErrorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your internet connection, then try again.'**
  String get attendanceErrorNetworkMessage;

  /// No description provided for @attendanceErrorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get attendanceErrorUnauthorizedTitle;

  /// No description provided for @attendanceErrorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again to resume attendance.'**
  String get attendanceErrorUnauthorizedMessage;

  /// No description provided for @attendanceErrorForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get attendanceErrorForbiddenTitle;

  /// No description provided for @attendanceErrorForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have the required permissions to view this class\'s attendance.'**
  String get attendanceErrorForbiddenMessage;

  /// No description provided for @attendanceErrorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get attendanceErrorServerTitle;

  /// No description provided for @attendanceErrorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our end. Try again in a moment.'**
  String get attendanceErrorServerMessage;

  /// No description provided for @attendanceErrorIncidentCode.
  ///
  /// In en, this message translates to:
  /// **'Incident code: {code}'**
  String attendanceErrorIncidentCode(String code);

  /// No description provided for @attendanceErrorUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get attendanceErrorUnknownTitle;

  /// No description provided for @attendanceErrorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading attendance.'**
  String get attendanceErrorUnknownMessage;

  /// No description provided for @attendanceSaveCallAction.
  ///
  /// In en, this message translates to:
  /// **'Save attendance'**
  String get attendanceSaveCallAction;

  /// No description provided for @attendanceMarkAllPresentAction.
  ///
  /// In en, this message translates to:
  /// **'All present'**
  String get attendanceMarkAllPresentAction;

  /// No description provided for @attendanceSaveOverlayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceSaveOverlayEyebrow;

  /// No description provided for @attendanceSaveProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving attendance…'**
  String get attendanceSaveProcessingTitle;

  /// No description provided for @attendanceSaveSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved!'**
  String get attendanceSaveSuccessTitle;

  /// No description provided for @attendanceSaveSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Class attendance records have been saved.'**
  String get attendanceSaveSuccessSubtitle;

  /// No description provided for @attendanceSaveErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get attendanceSaveErrorTitle;

  /// No description provided for @attendanceSaveErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Your entries are preserved. Check your connection and try again.'**
  String get attendanceSaveErrorMessage;

  /// No description provided for @attendanceSaveRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get attendanceSaveRetryAction;

  /// No description provided for @attendanceSaveCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get attendanceSaveCloseAction;

  /// No description provided for @absenceReasonSickness.
  ///
  /// In en, this message translates to:
  /// **'Sickness'**
  String get absenceReasonSickness;

  /// No description provided for @absenceReasonFamilyEmergency.
  ///
  /// In en, this message translates to:
  /// **'Family emergency'**
  String get absenceReasonFamilyEmergency;

  /// No description provided for @absenceReasonPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get absenceReasonPersonal;

  /// No description provided for @absenceReasonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get absenceReasonUnknown;

  /// No description provided for @absenceReasonVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get absenceReasonVacation;

  /// No description provided for @absenceReasonUnderGraduateLeave.
  ///
  /// In en, this message translates to:
  /// **'Study leave'**
  String get absenceReasonUnderGraduateLeave;

  /// No description provided for @absenceReasonMarriageLeave.
  ///
  /// In en, this message translates to:
  /// **'Marriage leave'**
  String get absenceReasonMarriageLeave;

  /// No description provided for @absenceReasonParentalLeave.
  ///
  /// In en, this message translates to:
  /// **'Parental leave'**
  String get absenceReasonParentalLeave;

  /// No description provided for @absenceReasonWorkLeave.
  ///
  /// In en, this message translates to:
  /// **'Work leave'**
  String get absenceReasonWorkLeave;

  /// No description provided for @absenceReasonUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Unjustified absence'**
  String get absenceReasonUnjustified;

  /// No description provided for @absenceReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get absenceReasonOther;

  /// No description provided for @bootstrapContextUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrollment context unavailable'**
  String get bootstrapContextUnavailableTitle;

  /// No description provided for @bootstrapContextUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap data (academic year / school) is missing. Please sign out and sign in again to reload the configuration.'**
  String get bootstrapContextUnavailableMessage;

  /// No description provided for @signOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutAction;

  /// No description provided for @disciplinaryDetailBackLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to disciplines'**
  String get disciplinaryDetailBackLabel;

  /// No description provided for @disciplinaryFollowUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary follow-up'**
  String get disciplinaryFollowUpTitle;

  /// No description provided for @disciplinaryHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary case file detail'**
  String get disciplinaryHeroTitle;

  /// No description provided for @disciplinaryHeroChipCases.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary cases'**
  String get disciplinaryHeroChipCases;

  /// No description provided for @disciplinaryDetailContextErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail context unavailable'**
  String get disciplinaryDetailContextErrorTitle;

  /// No description provided for @disciplinaryDetailContextErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Required context for this detail view is missing. Go back to the list and open the detail again.'**
  String get disciplinaryDetailContextErrorMessage;

  /// No description provided for @disciplinaryTabCasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary cases'**
  String get disciplinaryTabCasesLabel;

  /// No description provided for @disciplinaryTabAttendanceHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance history'**
  String get disciplinaryTabAttendanceHistoryLabel;

  /// No description provided for @presenceStatusPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presenceStatusPresent;

  /// No description provided for @presenceStatusJustified.
  ///
  /// In en, this message translates to:
  /// **'Justified absence'**
  String get presenceStatusJustified;

  /// No description provided for @presenceStatusUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Unjustified absence'**
  String get presenceStatusUnjustified;

  /// No description provided for @presenceSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance summary'**
  String get presenceSummaryTitle;

  /// No description provided for @presenceSummaryA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance summary, rate {rate}%'**
  String presenceSummaryA11yLabel(int rate);

  /// No description provided for @presenceKpiRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get presenceKpiRate;

  /// No description provided for @presenceRateValue.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String presenceRateValue(int rate);

  /// No description provided for @presenceSchoolDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 school day} other{{count} school days}}'**
  String presenceSchoolDaysCount(int count);

  /// No description provided for @presenceDistributionA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution of days by status'**
  String get presenceDistributionA11yLabel;

  /// No description provided for @presencePresentOutOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{present} days present out of {total}'**
  String presencePresentOutOfTotal(int present, int total);

  /// No description provided for @presenceAbsenceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Absences detail'**
  String get presenceAbsenceListTitle;

  /// No description provided for @presenceAbsenceDate.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String presenceAbsenceDate(DateTime date);

  /// No description provided for @presencePerfectTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect attendance'**
  String get presencePerfectTitle;

  /// No description provided for @presencePerfectMessage.
  ///
  /// In en, this message translates to:
  /// **'No absence on this period.'**
  String get presencePerfectMessage;

  /// No description provided for @presenceLoadingA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading attendance summary…'**
  String get presenceLoadingA11yLabel;

  /// No description provided for @presencePeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get presencePeriodWeek;

  /// No description provided for @presencePeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get presencePeriodMonth;

  /// No description provided for @presencePeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get presencePeriodYear;

  /// No description provided for @presencePeriodFilterA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance period'**
  String get presencePeriodFilterA11yLabel;

  /// No description provided for @presenceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No school days'**
  String get presenceEmptyTitle;

  /// No description provided for @presenceEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No school days on this period. Pick another period to view attendance.'**
  String get presenceEmptyMessage;

  /// No description provided for @presenceRangeYear.
  ///
  /// In en, this message translates to:
  /// **'School year {name}'**
  String presenceRangeYear(String name);

  /// No description provided for @presenceRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String presenceRangeMonth(DateTime date);

  /// No description provided for @presenceRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String presenceRangeWeek(DateTime date);

  /// No description provided for @disciplinaryUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get disciplinaryUnknownValue;

  /// No description provided for @disciplinaryCaseCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New case'**
  String get disciplinaryCaseCreateAction;

  /// No description provided for @disciplinaryCaseCreateCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Document a new disciplinary incident for this student.'**
  String get disciplinaryCaseCreateCtaSubtitle;

  /// No description provided for @disciplinaryCasesSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} recorded cases - {open} open'**
  String disciplinaryCasesSummary(int total, int open);

  /// No description provided for @disciplinaryCasesTableTitleColumn.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get disciplinaryCasesTableTitleColumn;

  /// No description provided for @disciplinaryCasesTableStatusColumn.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get disciplinaryCasesTableStatusColumn;

  /// No description provided for @disciplinaryCasesTableActionColumn.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get disciplinaryCasesTableActionColumn;

  /// No description provided for @disciplinaryCasesDateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get disciplinaryCasesDateUnavailable;

  /// No description provided for @disciplinaryCaseViewLabel.
  ///
  /// In en, this message translates to:
  /// **'View case'**
  String get disciplinaryCaseViewLabel;

  /// No description provided for @disciplinaryCasesLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading disciplinary cases...'**
  String get disciplinaryCasesLoadingMessage;

  /// No description provided for @disciplinaryCasesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No disciplinary cases for this student.'**
  String get disciplinaryCasesEmptyMessage;

  /// No description provided for @disciplinaryCaseViewDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary case detail'**
  String get disciplinaryCaseViewDialogTitle;

  /// No description provided for @disciplinaryCaseViewDialogSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Case information'**
  String get disciplinaryCaseViewDialogSectionTitle;

  /// No description provided for @disciplinaryCaseViewDialogTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get disciplinaryCaseViewDialogTitleField;

  /// No description provided for @disciplinaryCaseViewDialogStatusField.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get disciplinaryCaseViewDialogStatusField;

  /// No description provided for @disciplinaryCaseViewDialogContentField.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get disciplinaryCaseViewDialogContentField;

  /// No description provided for @disciplinaryCaseViewDialogLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading case detail...'**
  String get disciplinaryCaseViewDialogLoadingMessage;

  /// No description provided for @disciplinaryCaseViewDialogErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load case detail'**
  String get disciplinaryCaseViewDialogErrorMessage;

  /// No description provided for @disciplinaryCaseCreateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create disciplinary case'**
  String get disciplinaryCaseCreateDialogTitle;

  /// No description provided for @disciplinaryCaseCreateDialogTitleField.
  ///
  /// In en, this message translates to:
  /// **'Case title'**
  String get disciplinaryCaseCreateDialogTitleField;

  /// No description provided for @disciplinaryCaseCreateDialogTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give a brief case description'**
  String get disciplinaryCaseCreateDialogTitleHint;

  /// No description provided for @disciplinaryCaseCreateDialogContentField.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get disciplinaryCaseCreateDialogContentField;

  /// No description provided for @disciplinaryCaseCreateDialogContentHint.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary case details'**
  String get disciplinaryCaseCreateDialogContentHint;

  /// No description provided for @disciplinaryCaseCreateDialogCaseDateField.
  ///
  /// In en, this message translates to:
  /// **'Case date'**
  String get disciplinaryCaseCreateDialogCaseDateField;

  /// No description provided for @disciplinaryCaseCreateDialogCaseDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get disciplinaryCaseCreateDialogCaseDateHint;

  /// No description provided for @disciplinaryCaseCreateDialogSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Create case'**
  String get disciplinaryCaseCreateDialogSubmitAction;

  /// No description provided for @disciplinaryCaseCreateDialogCreatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get disciplinaryCaseCreateDialogCreatingMessage;

  /// No description provided for @disciplinaryCaseCreateDialogSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary case created successfully.'**
  String get disciplinaryCaseCreateDialogSuccessMessage;

  /// No description provided for @disciplinaryCaseCreateDialogRequiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get disciplinaryCaseCreateDialogRequiredFieldError;

  /// No description provided for @disciplinaryCasesNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get disciplinaryCasesNetworkError;

  /// No description provided for @disciplinaryCasesNotFound.
  ///
  /// In en, this message translates to:
  /// **'No disciplinary cases found.'**
  String get disciplinaryCasesNotFound;

  /// No description provided for @disciplinaryCasesValidationError.
  ///
  /// In en, this message translates to:
  /// **'Requested data is invalid.'**
  String get disciplinaryCasesValidationError;

  /// No description provided for @disciplinaryCasesUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to access these cases.'**
  String get disciplinaryCasesUnauthorizedError;

  /// No description provided for @disciplinaryCasesInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Your credentials do not allow access to cases.'**
  String get disciplinaryCasesInvalidCredentialsError;

  /// No description provided for @disciplinaryCasesServerError.
  ///
  /// In en, this message translates to:
  /// **'Server is unavailable. Please try again later.'**
  String get disciplinaryCasesServerError;

  /// No description provided for @disciplinaryCasesStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local storage error occurred.'**
  String get disciplinaryCasesStorageError;

  /// No description provided for @disciplinaryCasesAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents loading cases.'**
  String get disciplinaryCasesAuthError;

  /// No description provided for @disciplinaryCasesUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get disciplinaryCasesUnknownError;

  /// No description provided for @disciplinaryCaseStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get disciplinaryCaseStatusOpen;

  /// No description provided for @disciplinaryCaseStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get disciplinaryCaseStatusInProgress;

  /// No description provided for @disciplinaryCaseStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get disciplinaryCaseStatusClosed;

  /// No description provided for @disciplinaryCaseStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get disciplinaryCaseStatusUnknown;

  /// No description provided for @disciplinarySeverityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get disciplinarySeverityMinor;

  /// No description provided for @disciplinarySeverityMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get disciplinarySeverityMajor;

  /// No description provided for @disciplinarySeveritySerious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get disciplinarySeveritySerious;

  /// No description provided for @disciplinarySeverityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get disciplinarySeverityUnknown;

  /// No description provided for @disciplinaryCategoryDisruptiveBehavior.
  ///
  /// In en, this message translates to:
  /// **'Disruptive behavior'**
  String get disciplinaryCategoryDisruptiveBehavior;

  /// No description provided for @disciplinaryCategoryLateness.
  ///
  /// In en, this message translates to:
  /// **'Lateness'**
  String get disciplinaryCategoryLateness;

  /// No description provided for @disciplinaryCategoryRepeatedLateness.
  ///
  /// In en, this message translates to:
  /// **'Repeated lateness'**
  String get disciplinaryCategoryRepeatedLateness;

  /// No description provided for @disciplinaryCategoryUnjustifiedAbsence.
  ///
  /// In en, this message translates to:
  /// **'Unjustified absence'**
  String get disciplinaryCategoryUnjustifiedAbsence;

  /// No description provided for @disciplinaryCategoryInsolence.
  ///
  /// In en, this message translates to:
  /// **'Insolence'**
  String get disciplinaryCategoryInsolence;

  /// No description provided for @disciplinaryCategoryCheating.
  ///
  /// In en, this message translates to:
  /// **'Cheating'**
  String get disciplinaryCategoryCheating;

  /// No description provided for @disciplinaryCategoryFighting.
  ///
  /// In en, this message translates to:
  /// **'Fighting'**
  String get disciplinaryCategoryFighting;

  /// No description provided for @disciplinaryCategoryDressCodeViolation.
  ///
  /// In en, this message translates to:
  /// **'Dress code violation'**
  String get disciplinaryCategoryDressCodeViolation;

  /// No description provided for @disciplinaryCategoryTalkingInClass.
  ///
  /// In en, this message translates to:
  /// **'Talking in class'**
  String get disciplinaryCategoryTalkingInClass;

  /// No description provided for @disciplinaryCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get disciplinaryCategoryUnknown;

  /// No description provided for @disciplinarySanctionOralWarning.
  ///
  /// In en, this message translates to:
  /// **'Oral warning'**
  String get disciplinarySanctionOralWarning;

  /// No description provided for @disciplinarySanctionWrittenWarning.
  ///
  /// In en, this message translates to:
  /// **'Written warning'**
  String get disciplinarySanctionWrittenWarning;

  /// No description provided for @disciplinarySanctionDetention.
  ///
  /// In en, this message translates to:
  /// **'Detention'**
  String get disciplinarySanctionDetention;

  /// No description provided for @disciplinarySanctionParentsSummoned.
  ///
  /// In en, this message translates to:
  /// **'Parents summoned'**
  String get disciplinarySanctionParentsSummoned;

  /// No description provided for @disciplinarySanctionTemporaryExclusion.
  ///
  /// In en, this message translates to:
  /// **'Temporary exclusion'**
  String get disciplinarySanctionTemporaryExclusion;

  /// No description provided for @disciplinarySanctionDisciplinaryCouncil.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary council'**
  String get disciplinarySanctionDisciplinaryCouncil;

  /// No description provided for @disciplinarySanctionPermanentExclusion.
  ///
  /// In en, this message translates to:
  /// **'Permanent exclusion'**
  String get disciplinarySanctionPermanentExclusion;

  /// No description provided for @disciplinarySanctionUnknown.
  ///
  /// In en, this message translates to:
  /// **'No sanction'**
  String get disciplinarySanctionUnknown;

  /// No description provided for @disciplinaryCaseSeverityChip.
  ///
  /// In en, this message translates to:
  /// **'Severity {severity}'**
  String disciplinaryCaseSeverityChip(String severity);

  /// No description provided for @disciplinaryAdvanceTakeCharge.
  ///
  /// In en, this message translates to:
  /// **'Take charge'**
  String get disciplinaryAdvanceTakeCharge;

  /// No description provided for @disciplinaryAdvanceClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get disciplinaryAdvanceClose;

  /// No description provided for @disciplinaryCaseClosedLabel.
  ///
  /// In en, this message translates to:
  /// **'Case closed'**
  String get disciplinaryCaseClosedLabel;

  /// No description provided for @disciplinaryCasesCountPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 case} other{{count} cases}}'**
  String disciplinaryCasesCountPill(int count);

  /// No description provided for @disciplinaryCasesOpenPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open} other{{count} open}}'**
  String disciplinaryCasesOpenPill(int count);

  /// No description provided for @disciplinaryCasesGravePill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serious} other{{count} serious}}'**
  String disciplinaryCasesGravePill(int count);

  /// No description provided for @disciplinaryCasesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No discipline case'**
  String get disciplinaryCasesEmptyTitle;

  /// No description provided for @disciplinaryCasesEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No incident recorded for this student. All good.'**
  String get disciplinaryCasesEmptyDescription;

  /// No description provided for @disciplinaryFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get disciplinaryFieldCategory;

  /// No description provided for @disciplinaryFieldSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get disciplinaryFieldSeverity;

  /// No description provided for @disciplinaryFieldSanction.
  ///
  /// In en, this message translates to:
  /// **'Sanction'**
  String get disciplinaryFieldSanction;

  /// No description provided for @disciplinaryStatusAtCreationLabel.
  ///
  /// In en, this message translates to:
  /// **'Status at creation'**
  String get disciplinaryStatusAtCreationLabel;

  /// No description provided for @disciplinaryStatusAtCreationHint.
  ///
  /// In en, this message translates to:
  /// **'The case will be created as Open. You will then advance it from the record.'**
  String get disciplinaryStatusAtCreationHint;

  /// No description provided for @disciplinaryErrorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get disciplinaryErrorNetworkTitle;

  /// No description provided for @disciplinaryErrorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get disciplinaryErrorUnauthorizedTitle;

  /// No description provided for @disciplinaryErrorForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get disciplinaryErrorForbiddenTitle;

  /// No description provided for @disciplinaryErrorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get disciplinaryErrorServerTitle;

  /// No description provided for @disciplinaryErrorUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get disciplinaryErrorUnknownTitle;

  /// No description provided for @disciplinaryErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get disciplinaryErrorRetry;

  /// No description provided for @disciplinaryErrorReconnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get disciplinaryErrorReconnect;

  /// No description provided for @disciplinaryErrorContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact the administrator'**
  String get disciplinaryErrorContactAdmin;

  /// No description provided for @enrollmentStatusPreRegistered.
  ///
  /// In en, this message translates to:
  /// **'Pre-registered'**
  String get enrollmentStatusPreRegistered;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get statusPresent;

  /// No description provided for @statusAbsentJustified.
  ///
  /// In en, this message translates to:
  /// **'Justified'**
  String get statusAbsentJustified;

  /// No description provided for @statusAbsentUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get statusAbsentUnjustified;

  /// No description provided for @statusSynced.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get statusSynced;

  /// No description provided for @statusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get statusSyncing;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusPendingUpload.
  ///
  /// In en, this message translates to:
  /// **'Pending upload'**
  String get statusPendingUpload;

  /// No description provided for @statusSyncConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get statusSyncConflict;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @componentGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get componentGalleryTitle;

  /// No description provided for @enrollmentStatsDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrollment Dashboard'**
  String get enrollmentStatsDashboardTitle;

  /// No description provided for @enrollmentStatsPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get enrollmentStatsPeriodYear;

  /// No description provided for @enrollmentStatsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get enrollmentStatsPeriodMonth;

  /// No description provided for @enrollmentStatsPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get enrollmentStatsPeriodWeek;

  /// No description provided for @enrollmentStatsKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get enrollmentStatsKpiTotal;

  /// No description provided for @enrollmentStatsKpiFirst.
  ///
  /// In en, this message translates to:
  /// **'First enrollments'**
  String get enrollmentStatsKpiFirst;

  /// No description provided for @enrollmentStatsKpiRe.
  ///
  /// In en, this message translates to:
  /// **'Re-enrollments'**
  String get enrollmentStatsKpiRe;

  /// No description provided for @enrollmentStatsKpiPre.
  ///
  /// In en, this message translates to:
  /// **'Pre-enrollments'**
  String get enrollmentStatsKpiPre;

  /// No description provided for @enrollmentStatsKpiInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get enrollmentStatsKpiInProgress;

  /// No description provided for @enrollmentStatsSectionEvolution.
  ///
  /// In en, this message translates to:
  /// **'Evolution'**
  String get enrollmentStatsSectionEvolution;

  /// No description provided for @enrollmentStatsSectionCycle.
  ///
  /// In en, this message translates to:
  /// **'By cycle'**
  String get enrollmentStatsSectionCycle;

  /// No description provided for @enrollmentStatsSectionGender.
  ///
  /// In en, this message translates to:
  /// **'By gender'**
  String get enrollmentStatsSectionGender;

  /// No description provided for @enrollmentStatsSectionEvolutionEnrollments.
  ///
  /// In en, this message translates to:
  /// **'Enrollment evolution'**
  String get enrollmentStatsSectionEvolutionEnrollments;

  /// No description provided for @enrollmentStatsSectionLevelEvolution.
  ///
  /// In en, this message translates to:
  /// **'Evolution by level'**
  String get enrollmentStatsSectionLevelEvolution;

  /// No description provided for @enrollmentStatsSectionGenderEvolution.
  ///
  /// In en, this message translates to:
  /// **'Evolution by gender'**
  String get enrollmentStatsSectionGenderEvolution;

  /// No description provided for @enrollmentStatsGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get enrollmentStatsGenderMale;

  /// No description provided for @enrollmentStatsGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get enrollmentStatsGenderFemale;

  /// No description provided for @enrollmentStatsGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get enrollmentStatsGenderOther;

  /// No description provided for @enrollmentStatsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available for this period'**
  String get enrollmentStatsNoData;

  /// No description provided for @enrollmentStatsLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load statistics'**
  String get enrollmentStatsLoadingError;

  /// No description provided for @enrollmentStatsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get enrollmentStatsRetry;

  /// No description provided for @enrollmentStatsStudents.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get enrollmentStatsStudents;

  /// No description provided for @enrollmentStatsPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String enrollmentStatsPercent(int percent);

  /// No description provided for @enrollmentStatsPeriodWeekCurrent.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get enrollmentStatsPeriodWeekCurrent;

  /// No description provided for @enrollmentStatsPeriodMonthCurrent.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get enrollmentStatsPeriodMonthCurrent;

  /// No description provided for @enrollmentStatsPeriodYearCurrent.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get enrollmentStatsPeriodYearCurrent;

  /// No description provided for @enrollmentStatsSchoolYearUnavailable.
  ///
  /// In en, this message translates to:
  /// **'School year unavailable'**
  String get enrollmentStatsSchoolYearUnavailable;

  /// No description provided for @enrollmentStatsHeaderA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrollment dashboard, school year {schoolYear}'**
  String enrollmentStatsHeaderA11yLabel(String schoolYear);

  /// No description provided for @enrollmentStatsPeriodFilterA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrollment statistics time filter, active period: {selectedPeriod}'**
  String enrollmentStatsPeriodFilterA11yLabel(String selectedPeriod);

  /// No description provided for @enrollmentStatsContextSchoolYear.
  ///
  /// In en, this message translates to:
  /// **'Overview - School year {schoolYear}'**
  String enrollmentStatsContextSchoolYear(String schoolYear);

  /// No description provided for @classesStatsDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes Overview - School year'**
  String get classesStatsDashboardTitle;

  /// No description provided for @classesStatsSchoolYearUnavailable.
  ///
  /// In en, this message translates to:
  /// **'School year unavailable'**
  String get classesStatsSchoolYearUnavailable;

  /// No description provided for @classesStatsHeaderA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Classes dashboard, school year {schoolYear}'**
  String classesStatsHeaderA11yLabel(String schoolYear);

  /// No description provided for @classesStatsKpiTotalStudents.
  ///
  /// In en, this message translates to:
  /// **'TOTAL STUDENTS'**
  String get classesStatsKpiTotalStudents;

  /// No description provided for @classesStatsKpiActiveGirls.
  ///
  /// In en, this message translates to:
  /// **'TOTAL GIRLS'**
  String get classesStatsKpiActiveGirls;

  /// No description provided for @classesStatsKpiActiveBoys.
  ///
  /// In en, this message translates to:
  /// **'BOYS'**
  String get classesStatsKpiActiveBoys;

  /// No description provided for @classesStatsKpiInactiveStudents.
  ///
  /// In en, this message translates to:
  /// **'TOTAL INACTIVE STUDENTS'**
  String get classesStatsKpiInactiveStudents;

  /// No description provided for @classesStatsSectionCycleDistribution.
  ///
  /// In en, this message translates to:
  /// **'Active students distribution by cycle'**
  String get classesStatsSectionCycleDistribution;

  /// No description provided for @classesStatsSectionLevelDistribution.
  ///
  /// In en, this message translates to:
  /// **'Levels distribution - {cycleCode}'**
  String classesStatsSectionLevelDistribution(String cycleCode);

  /// No description provided for @classesStatsSectionClassroomDetail.
  ///
  /// In en, this message translates to:
  /// **'Classrooms detail'**
  String get classesStatsSectionClassroomDetail;

  /// No description provided for @classesStatsDetailColumnClassroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get classesStatsDetailColumnClassroom;

  /// No description provided for @classesStatsDetailColumnCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get classesStatsDetailColumnCycle;

  /// No description provided for @classesStatsDetailColumnLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get classesStatsDetailColumnLevel;

  /// No description provided for @classesStatsDetailColumnTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get classesStatsDetailColumnTotal;

  /// No description provided for @classesStatsDetailColumnGirls.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get classesStatsDetailColumnGirls;

  /// No description provided for @classesStatsDetailColumnBoys.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get classesStatsDetailColumnBoys;

  /// No description provided for @classesStatsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available for this period'**
  String get classesStatsNoData;

  /// No description provided for @classesStatsKpiBandA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Classes key performance indicators band'**
  String get classesStatsKpiBandA11yLabel;

  /// No description provided for @classesStatsCycleChartA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Chart of active students distribution by cycle'**
  String get classesStatsCycleChartA11yLabel;

  /// No description provided for @classesStatsLevelChartA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Chart of active students distribution by level for cycle {cycleCode}'**
  String classesStatsLevelChartA11yLabel(String cycleCode);

  /// No description provided for @classesStatsDetailA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed classrooms table with gender breakdown'**
  String get classesStatsDetailA11yLabel;

  /// No description provided for @classesStatsLoadingA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading classes statistics'**
  String get classesStatsLoadingA11yLabel;

  /// No description provided for @classesStatsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get classesStatsErrorTitle;

  /// No description provided for @classesStatsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get classesStatsRetry;

  /// No description provided for @classesStatsRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Retry loading classes statistics'**
  String get classesStatsRetryHint;

  /// No description provided for @classesStatsErrorA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Classes statistics loading error: {message}'**
  String classesStatsErrorA11yLabel(String message);

  /// No description provided for @classesStatsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load classes statistics. Check your internet connection.'**
  String get classesStatsNetworkError;

  /// No description provided for @classesStatsNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'No classes statistics available.'**
  String get classesStatsNotFoundError;

  /// No description provided for @classesStatsValidationError.
  ///
  /// In en, this message translates to:
  /// **'The requested parameters are invalid.'**
  String get classesStatsValidationError;

  /// No description provided for @classesStatsUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to view these statistics.'**
  String get classesStatsUnauthorizedError;

  /// No description provided for @classesStatsInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Invalid session, please sign in again.'**
  String get classesStatsInvalidCredentialsError;

  /// No description provided for @classesStatsServerError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable.'**
  String get classesStatsServerError;

  /// No description provided for @classesStatsStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local error prevents displaying statistics.'**
  String get classesStatsStorageError;

  /// No description provided for @classesStatsAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents loading statistics.'**
  String get classesStatsAuthError;

  /// No description provided for @classesStatsUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading statistics.'**
  String get classesStatsUnknownError;

  /// No description provided for @financeStatsDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview - School year'**
  String get financeStatsDashboardTitle;

  /// No description provided for @financeStatsSchoolYearUnavailable.
  ///
  /// In en, this message translates to:
  /// **'School year unavailable'**
  String get financeStatsSchoolYearUnavailable;

  /// No description provided for @financeStatsContextSchoolYear.
  ///
  /// In en, this message translates to:
  /// **'Overview - School year {schoolYear}'**
  String financeStatsContextSchoolYear(String schoolYear);

  /// No description provided for @financeStatsPeriodWeekCurrent.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get financeStatsPeriodWeekCurrent;

  /// No description provided for @financeStatsPeriodMonthCurrent.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get financeStatsPeriodMonthCurrent;

  /// No description provided for @financeStatsPeriodYearCurrent.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get financeStatsPeriodYearCurrent;

  /// No description provided for @financeStatsKpiCollected.
  ///
  /// In en, this message translates to:
  /// **'Total collected'**
  String get financeStatsKpiCollected;

  /// No description provided for @financeStatsKpiExpected.
  ///
  /// In en, this message translates to:
  /// **'Total expected'**
  String get financeStatsKpiExpected;

  /// No description provided for @financeStatsKpiOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get financeStatsKpiOutstanding;

  /// No description provided for @financeStatsKpiCollectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection rate'**
  String get financeStatsKpiCollectionRate;

  /// No description provided for @financeStatsSectionEvolution.
  ///
  /// In en, this message translates to:
  /// **'Collection evolution'**
  String get financeStatsSectionEvolution;

  /// No description provided for @financeStatsLegendCurrentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current period'**
  String get financeStatsLegendCurrentPeriod;

  /// No description provided for @financeStatsLegendOtherPeriods.
  ///
  /// In en, this message translates to:
  /// **'Other periods'**
  String get financeStatsLegendOtherPeriods;

  /// No description provided for @financeStatsSectionFeeTypeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution by fee type'**
  String get financeStatsSectionFeeTypeDistribution;

  /// No description provided for @financeStatsFeeTypeCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected: {amount}'**
  String financeStatsFeeTypeCollected(String amount);

  /// No description provided for @financeStatsFeeTypeExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected: {amount}'**
  String financeStatsFeeTypeExpected(String amount);

  /// No description provided for @financeStatsFeeTypeRate.
  ///
  /// In en, this message translates to:
  /// **'Rate: {rate}%'**
  String financeStatsFeeTypeRate(int rate);

  /// No description provided for @financeStatsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available for this period'**
  String get financeStatsNoData;

  /// No description provided for @financeStatsNoDataHint.
  ///
  /// In en, this message translates to:
  /// **'Try another period to display more insights.'**
  String get financeStatsNoDataHint;

  /// No description provided for @financeStatsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get financeStatsErrorTitle;

  /// No description provided for @financeStatsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get financeStatsRetry;

  /// No description provided for @financeStatsRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Reload finance statistics'**
  String get financeStatsRetryHint;

  /// No description provided for @financeStatsLoadingA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Finance statistics are loading'**
  String get financeStatsLoadingA11yLabel;

  /// No description provided for @financeStatsHeaderA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Finance dashboard, school year {schoolYear}'**
  String financeStatsHeaderA11yLabel(String schoolYear);

  /// No description provided for @financeStatsPeriodFilterA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Finance statistics time filter, active period: {selectedPeriod}'**
  String financeStatsPeriodFilterA11yLabel(String selectedPeriod);

  /// No description provided for @financeStatsKpiBandA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial key performance indicators band'**
  String get financeStatsKpiBandA11yLabel;

  /// No description provided for @financeStatsEvolutionChartA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection amount evolution chart'**
  String get financeStatsEvolutionChartA11yLabel;

  /// No description provided for @financeStatsFeeTypeSectionA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution of amounts by fee type'**
  String get financeStatsFeeTypeSectionA11yLabel;

  /// No description provided for @financeStatsFeeTypeItemA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Type {code}, collected {collected}, expected {expected}, rate {rate}%'**
  String financeStatsFeeTypeItemA11yLabel(
    String code,
    String collected,
    String expected,
    int rate,
  );

  /// No description provided for @financeStatsErrorA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Finance statistics loading error: {message}'**
  String financeStatsErrorA11yLabel(String message);

  /// No description provided for @financeStatsEmptyA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'No finance data available for this period'**
  String get financeStatsEmptyA11yLabel;

  /// No description provided for @financeStatsNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load finance statistics. Check your internet connection.'**
  String get financeStatsNetworkError;

  /// No description provided for @financeStatsNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'No finance statistics available.'**
  String get financeStatsNotFoundError;

  /// No description provided for @financeStatsValidationError.
  ///
  /// In en, this message translates to:
  /// **'The requested parameters are invalid.'**
  String get financeStatsValidationError;

  /// No description provided for @financeStatsUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to view these statistics.'**
  String get financeStatsUnauthorizedError;

  /// No description provided for @financeStatsInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Invalid session, please sign in again.'**
  String get financeStatsInvalidCredentialsError;

  /// No description provided for @financeStatsServerError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently unavailable.'**
  String get financeStatsServerError;

  /// No description provided for @financeStatsStorageError.
  ///
  /// In en, this message translates to:
  /// **'A local error prevents displaying statistics.'**
  String get financeStatsStorageError;

  /// No description provided for @financeStatsAuthError.
  ///
  /// In en, this message translates to:
  /// **'An authentication error prevents loading statistics.'**
  String get financeStatsAuthError;

  /// No description provided for @financeStatsUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading statistics.'**
  String get financeStatsUnknownError;

  /// No description provided for @enrollmentResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get enrollmentResults;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @switchToTableView.
  ///
  /// In en, this message translates to:
  /// **'Switch to table view'**
  String get switchToTableView;

  /// No description provided for @switchToGridView.
  ///
  /// In en, this message translates to:
  /// **'Switch to grid view'**
  String get switchToGridView;

  /// No description provided for @enrollmentViewTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get enrollmentViewTable;

  /// No description provided for @enrollmentViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get enrollmentViewGrid;

  /// No description provided for @enrollmentResultsA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrollment results'**
  String get enrollmentResultsA11yLabel;

  /// No description provided for @dataTableSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending sort'**
  String get dataTableSortAscending;

  /// No description provided for @dataTableSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending sort'**
  String get dataTableSortDescending;

  /// No description provided for @dataTableSortNone.
  ///
  /// In en, this message translates to:
  /// **'No sort'**
  String get dataTableSortNone;

  /// No description provided for @openDetailsForStudent.
  ///
  /// In en, this message translates to:
  /// **'Open student file for {studentName}'**
  String openDetailsForStudent(String studentName);

  /// No description provided for @removeFilterNamed.
  ///
  /// In en, this message translates to:
  /// **'Remove filter {filter}'**
  String removeFilterNamed(String filter);

  /// No description provided for @attendanceOverviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Discipline · Attendance'**
  String get attendanceOverviewEyebrow;

  /// No description provided for @attendanceOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get attendanceOverviewTitle;

  /// No description provided for @attendanceOverviewContextSchoolYear.
  ///
  /// In en, this message translates to:
  /// **'School year'**
  String get attendanceOverviewContextSchoolYear;

  /// No description provided for @attendanceOverviewContextWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get attendanceOverviewContextWindow;

  /// No description provided for @attendanceOverviewContextGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated on'**
  String get attendanceOverviewContextGeneratedAt;

  /// No description provided for @attendanceOverviewContextA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance statistics context'**
  String get attendanceOverviewContextA11yLabel;

  /// No description provided for @attendanceOverviewKpiPresence.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get attendanceOverviewKpiPresence;

  /// No description provided for @attendanceOverviewKpiJustified.
  ///
  /// In en, this message translates to:
  /// **'Justified absences'**
  String get attendanceOverviewKpiJustified;

  /// No description provided for @attendanceOverviewKpiUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Unjustified absences'**
  String get attendanceOverviewKpiUnjustified;

  /// No description provided for @attendanceOverviewKpiRecordedDays.
  ///
  /// In en, this message translates to:
  /// **'Recorded days'**
  String get attendanceOverviewKpiRecordedDays;

  /// No description provided for @attendanceOverviewRateValue.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String attendanceOverviewRateValue(String rate);

  /// No description provided for @attendanceOverviewStudentDays.
  ///
  /// In en, this message translates to:
  /// **'{count} student-days'**
  String attendanceOverviewStudentDays(String count);

  /// No description provided for @attendanceOverviewKpiBandA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Key attendance indicators'**
  String get attendanceOverviewKpiBandA11yLabel;

  /// No description provided for @attendanceOverviewSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance / absence breakdown'**
  String get attendanceOverviewSplitTitle;

  /// No description provided for @attendanceOverviewSplitSumHint.
  ///
  /// In en, this message translates to:
  /// **'sum = 100%'**
  String get attendanceOverviewSplitSumHint;

  /// No description provided for @attendanceOverviewSplitPresence.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendanceOverviewSplitPresence;

  /// No description provided for @attendanceOverviewSplitJustified.
  ///
  /// In en, this message translates to:
  /// **'Justified absences'**
  String get attendanceOverviewSplitJustified;

  /// No description provided for @attendanceOverviewSplitUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Unjustified absences'**
  String get attendanceOverviewSplitUnjustified;

  /// No description provided for @attendanceOverviewSplitA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Present {presence}%, justified {justified}%, unjustified {unjustified}%'**
  String attendanceOverviewSplitA11yLabel(
    String presence,
    String justified,
    String unjustified,
  );

  /// No description provided for @attendanceOverviewEvolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate trend'**
  String get attendanceOverviewEvolutionTitle;

  /// No description provided for @attendanceOverviewEvolutionHintMonth.
  ///
  /// In en, this message translates to:
  /// **'by month'**
  String get attendanceOverviewEvolutionHintMonth;

  /// No description provided for @attendanceOverviewEvolutionHintWeek.
  ///
  /// In en, this message translates to:
  /// **'by week'**
  String get attendanceOverviewEvolutionHintWeek;

  /// No description provided for @attendanceOverviewEvolutionHintDay.
  ///
  /// In en, this message translates to:
  /// **'by day'**
  String get attendanceOverviewEvolutionHintDay;

  /// No description provided for @attendanceOverviewEvolutionTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {rate}%'**
  String attendanceOverviewEvolutionTarget(String rate);

  /// No description provided for @attendanceOverviewReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Absence reasons'**
  String get attendanceOverviewReasonsTitle;

  /// No description provided for @attendanceOverviewReasonsHint.
  ///
  /// In en, this message translates to:
  /// **'school'**
  String get attendanceOverviewReasonsHint;

  /// No description provided for @attendanceOverviewReasonsCenterLabel.
  ///
  /// In en, this message translates to:
  /// **'absences'**
  String get attendanceOverviewReasonsCenterLabel;

  /// No description provided for @attendanceOverviewReasonUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Unjustified'**
  String get attendanceOverviewReasonUnjustified;

  /// No description provided for @attendanceOverviewReasonUnjustifiedNote.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN/null'**
  String get attendanceOverviewReasonUnjustifiedNote;

  /// No description provided for @attendanceOverviewWeekdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Absences by day'**
  String get attendanceOverviewWeekdayTitle;

  /// No description provided for @attendanceOverviewWeekdayHint.
  ///
  /// In en, this message translates to:
  /// **'Mon → Fri'**
  String get attendanceOverviewWeekdayHint;

  /// No description provided for @attendanceWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get attendanceWeekdayMon;

  /// No description provided for @attendanceWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get attendanceWeekdayTue;

  /// No description provided for @attendanceWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get attendanceWeekdayWed;

  /// No description provided for @attendanceWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get attendanceWeekdayThu;

  /// No description provided for @attendanceWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get attendanceWeekdayFri;

  /// No description provided for @attendanceOverviewTopAbsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Most absent classes'**
  String get attendanceOverviewTopAbsentTitle;

  /// No description provided for @attendanceOverviewTopAbsentHint.
  ///
  /// In en, this message translates to:
  /// **'top 5'**
  String get attendanceOverviewTopAbsentHint;

  /// No description provided for @attendanceOverviewByClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance by class'**
  String get attendanceOverviewByClassTitle;

  /// No description provided for @attendanceOverviewColClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get attendanceOverviewColClass;

  /// No description provided for @attendanceOverviewColLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get attendanceOverviewColLevel;

  /// No description provided for @attendanceOverviewColPresence.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceOverviewColPresence;

  /// No description provided for @attendanceOverviewColJustified.
  ///
  /// In en, this message translates to:
  /// **'Justified'**
  String get attendanceOverviewColJustified;

  /// No description provided for @attendanceOverviewColUnjustified.
  ///
  /// In en, this message translates to:
  /// **'Unjustified'**
  String get attendanceOverviewColUnjustified;

  /// No description provided for @attendanceOverviewColDistribution.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get attendanceOverviewColDistribution;

  /// No description provided for @attendanceOverviewEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No attendance data'**
  String get attendanceOverviewEmptyTitle;

  /// No description provided for @attendanceOverviewEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No attendance has been recorded for this window. Statistics will appear as soon as the first attendance is taken.'**
  String get attendanceOverviewEmptyDescription;

  /// No description provided for @attendanceOverviewEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Take attendance'**
  String get attendanceOverviewEmptyAction;

  /// No description provided for @attendanceOverviewLoadingA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading the attendance dashboard'**
  String get attendanceOverviewLoadingA11yLabel;

  /// No description provided for @disciplinaryFolderBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Discipline list'**
  String get disciplinaryFolderBreadcrumb;

  /// No description provided for @dossierTabsA11yLabel.
  ///
  /// In en, this message translates to:
  /// **'Student folder tabs'**
  String get dossierTabsA11yLabel;

  /// No description provided for @dossierTabDisciplineLabel.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get dossierTabDisciplineLabel;

  /// No description provided for @dossierTabDisciplineDescription.
  ///
  /// In en, this message translates to:
  /// **'Cases, sanctions & follow-up'**
  String get dossierTabDisciplineDescription;

  /// No description provided for @dossierTabPresenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get dossierTabPresenceLabel;

  /// No description provided for @dossierTabPresenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Absences & lateness'**
  String get dossierTabPresenceDescription;

  /// No description provided for @dossierOpenCasesChip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open case} other{{count} open cases}}'**
  String dossierOpenCasesChip(int count);

  /// No description provided for @dossierNoOpenCases.
  ///
  /// In en, this message translates to:
  /// **'No open case'**
  String get dossierNoOpenCases;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @scheduleErrorNoTeacher.
  ///
  /// In en, this message translates to:
  /// **'No teacher is linked to your account.'**
  String get scheduleErrorNoTeacher;

  /// No description provided for @scheduleErrorConflict.
  ///
  /// In en, this message translates to:
  /// **'This time slot is already taken (teacher or class).'**
  String get scheduleErrorConflict;

  /// No description provided for @scheduleErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading the timetable.'**
  String get scheduleErrorGeneric;

  /// No description provided for @scheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No session scheduled.'**
  String get scheduleEmpty;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
