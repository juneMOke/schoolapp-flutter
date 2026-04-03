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

  /// No description provided for @loadingStudents.
  ///
  /// In en, this message translates to:
  /// **'Loading students...'**
  String get loadingStudents;

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
