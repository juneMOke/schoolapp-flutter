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
