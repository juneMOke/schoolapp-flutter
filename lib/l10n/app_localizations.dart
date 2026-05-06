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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
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

  /// No description provided for @schoolApp.
  ///
  /// In en, this message translates to:
  /// **'ETEELO TECH'**
  String get schoolApp;

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
  /// **'Organization'**
  String get subMenuOrganization;

  /// No description provided for @classesOrganisationHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes organization'**
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

  /// No description provided for @classesOrganisationDistributionAction.
  ///
  /// In en, this message translates to:
  /// **'Distribute'**
  String get classesOrganisationDistributionAction;

  /// No description provided for @classesOrganisationDistributionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm distribution'**
  String get classesOrganisationDistributionConfirmTitle;

  /// No description provided for @classesOrganisationDistributionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to distribute students for this level?'**
  String get classesOrganisationDistributionConfirmMessage;

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

  /// No description provided for @classesOrganisationNoClassrooms.
  ///
  /// In en, this message translates to:
  /// **'No classroom is available for this level.'**
  String get classesOrganisationNoClassrooms;

  /// No description provided for @classesOrganisationClassroomStats.
  ///
  /// In en, this message translates to:
  /// **'{total} students - Girls: {girls} - Boys: {boys}'**
  String classesOrganisationClassroomStats(int total, int girls, int boys);

  /// No description provided for @classesOrganisationTransferDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer student'**
  String get classesOrganisationTransferDialogTitle;

  /// No description provided for @classesOrganisationTransferDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose the destination classroom for {studentName}.'**
  String classesOrganisationTransferDialogMessage(String studentName);

  /// No description provided for @classesOrganisationTransferTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination classroom'**
  String get classesOrganisationTransferTargetLabel;

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

  /// No description provided for @classesListHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes and students list'**
  String get classesListHeroTitle;

  /// No description provided for @classesListHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quickly search students by cycle, level or classroom, then export the displayed results.'**
  String get classesListHeroSubtitle;

  /// No description provided for @classesListHeroFilterChip.
  ///
  /// In en, this message translates to:
  /// **'Multi-criteria search by identity and level.'**
  String get classesListHeroFilterChip;

  /// No description provided for @classesListHeroClassroomChip.
  ///
  /// In en, this message translates to:
  /// **'Optional classroom filtering for the current school year.'**
  String get classesListHeroClassroomChip;

  /// No description provided for @classesListSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search form'**
  String get classesListSearchTitle;

  /// No description provided for @classesListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Start by selecting a cycle and a level, then optionally refine with a classroom or the three name fields.'**
  String get classesListSearchHint;

  /// No description provided for @classesListSearchValidationLevelRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a cycle and a level to start the search.'**
  String get classesListSearchValidationLevelRequired;

  /// No description provided for @classesListSearchValidationNamesIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in first name, last name and surname to enable name-based filtering.'**
  String get classesListSearchValidationNamesIncomplete;

  /// No description provided for @classesListSearchReady.
  ///
  /// In en, this message translates to:
  /// **'Valid criteria, you can run the search.'**
  String get classesListSearchReady;

  /// No description provided for @classesListClassroomHelpSelectCycle.
  ///
  /// In en, this message translates to:
  /// **'Select a cycle before choosing a classroom.'**
  String get classesListClassroomHelpSelectCycle;

  /// No description provided for @classesListClassroomHelpSelectLevel.
  ///
  /// In en, this message translates to:
  /// **'Please select a level to choose a classroom.'**
  String get classesListClassroomHelpSelectLevel;

  /// No description provided for @classesListClassroomHelpLevelNotSplit.
  ///
  /// In en, this message translates to:
  /// **'Students in this level are not split into classrooms yet. Use the organization menu first.'**
  String get classesListClassroomHelpLevelNotSplit;

  /// No description provided for @classesListClassroomHelpOptional.
  ///
  /// In en, this message translates to:
  /// **'Classroom selection is optional: leave it empty to search the whole level.'**
  String get classesListClassroomHelpOptional;

  /// No description provided for @classesListInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a search in the Classes module'**
  String get classesListInvitationTitle;

  /// No description provided for @classesListInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Fill the filters above, then click Search to display students.'**
  String get classesListInvitationMessage;

  /// No description provided for @classesListResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get classesListResultsTitle;

  /// No description provided for @classesListResultsLevelMode.
  ///
  /// In en, this message translates to:
  /// **'Level results: {levelLabel}'**
  String classesListResultsLevelMode(String levelLabel);

  /// No description provided for @classesListResultsClassroomMode.
  ///
  /// In en, this message translates to:
  /// **'Classroom results: {classroomName}'**
  String classesListResultsClassroomMode(String classroomName);

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

  /// Classes list sub-menu title
  ///
  /// In en, this message translates to:
  /// **'Classes List'**
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

  /// No description provided for @reRegistrationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter either First name, Last name and Surname, or the target cycle/level to start the search.'**
  String get reRegistrationSearchHint;

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
  /// **'View Details'**
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

  /// No description provided for @enrollmentPageFooter.
  ///
  /// In en, this message translates to:
  /// **'{pageCount} {pageCount, plural, =1{result} other{results}} of {totalCount}'**
  String enrollmentPageFooter(int pageCount, int totalCount);

  /// No description provided for @enrollmentPageIndicator.
  ///
  /// In en, this message translates to:
  /// **'Page {current} / {total}'**
  String enrollmentPageIndicator(int current, int total);

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

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

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

  /// No description provided for @stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} / {total}'**
  String stepIndicator(int current, int total);

  /// No description provided for @stepForwardHint.
  ///
  /// In en, this message translates to:
  /// **'Click Continue to advance step by step.'**
  String get stepForwardHint;

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
  /// **'This enrollment is finalized (COMPLETED). Information is displayed in read-only mode.'**
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
  /// **'Due'**
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

  /// No description provided for @facturationPageHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Billing'**
  String get facturationPageHeaderTitle;

  /// No description provided for @facturationPageHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search a student by name or class level to view and manage their school fees.'**
  String get facturationPageHeaderSubtitle;

  /// No description provided for @facturationPageHeaderChipByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get facturationPageHeaderChipByName;

  /// No description provided for @facturationPageHeaderChipByLevel.
  ///
  /// In en, this message translates to:
  /// **'Filter by level'**
  String get facturationPageHeaderChipByLevel;

  /// No description provided for @facturationPageHeaderChipViewCharges.
  ///
  /// In en, this message translates to:
  /// **'View charges'**
  String get facturationPageHeaderChipViewCharges;

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
  /// **'Start a billing search'**
  String get facturationSearchInvitationTitle;

  /// No description provided for @facturationSearchInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a level or enter a student name then click Search to display records.'**
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
  /// **'Billing detail'**
  String get facturationDetailInfoTitle;

  /// No description provided for @facturationDetailInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review recent payments and student charge status for the selected academic year.'**
  String get facturationDetailInfoSubtitle;

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
  /// **'Recent payments'**
  String get facturationDetailPaymentsSectionTitle;

  /// No description provided for @facturationDetailPaymentsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history recorded for this student.'**
  String get facturationDetailPaymentsSectionSubtitle;

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
  /// **'Payer details'**
  String get facturationDetailPaymentPayerColumn;

  /// No description provided for @facturationDetailPaymentPaidAtColumn.
  ///
  /// In en, this message translates to:
  /// **'Paid at'**
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

  /// No description provided for @facturationPaymentAllocationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment allocations'**
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
  /// **'Student charges'**
  String get facturationDetailChargesSectionTitle;

  /// No description provided for @facturationDetailChargesSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown of expected, paid and remaining amounts.'**
  String get facturationDetailChargesSectionSubtitle;

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
  /// **'Expected amount'**
  String get facturationDetailChargeExpectedAmountColumn;

  /// No description provided for @facturationDetailChargePaidAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Paid amount'**
  String get facturationDetailChargePaidAmountColumn;

  /// No description provided for @facturationDetailChargeRemainingAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get facturationDetailChargeRemainingAmountColumn;

  /// No description provided for @facturationDetailChargeStatusColumn.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get facturationDetailChargeStatusColumn;

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
  /// **'Charge detail'**
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
  /// **'Allocations for this charge'**
  String get facturationChargeDetailAllocationsSectionTitle;

  /// No description provided for @facturationChargeDetailAllocationsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breakdown of payments allocated to this charge.'**
  String get facturationChargeDetailAllocationsSectionSubtitle;

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

  /// No description provided for @attendanceInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Run a search to display attendance for the selected class.'**
  String get attendanceInvitationMessage;

  /// No description provided for @attendanceLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading attendance records...'**
  String get attendanceLoadingMessage;

  /// No description provided for @attendanceEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No attendance found for these filters.'**
  String get attendanceEmptyMessage;

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

  /// No description provided for @disciplinaryCaseStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get disciplinaryCaseStatusUnknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
