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

  // ── Personal info step ───────────────────────────────────────

  String get personalInfoSubtitle;
  String get firstNameHelp;
  String get lastNameHelp;
  String get surnameHelp;
  String get dateOfBirthHelp;
  String get birthPlace;
  String get birthPlaceHelp;
  String get nationality;
  String get nationalityHelp;
  String get genderHelp;
  String get selectDateOfBirthHelpText;
  String get cancel;
  String get confirm;
  String enterFieldHint(String label);
  String get dateHint;
  String get genderMale;
  String get genderFemale;

  // ── Address step ─────────────────────────────────────────────
  String get city;
  String get cityHelp;
  String get district;
  String get districtHelp;
  String get municipality;
  String get municipalityHelp;
  String get neighborhood;
  String get neighborhoodHelp;
  String get fullAddress;
  String get fullAddressHelp;

  // ── Academic info step ───────────────────────────────────────
  String get academicYearLabel;
  String get academicYearLabelHelp;
  String get schoolLabel;
  String get schoolLabelHelp;
  String get schoolCycle;
  String get schoolCycleHelp;
  String get schoolLevelLabel;
  String get schoolLevelLabelHelp;
  String get averageLabel;
  String get averageLabelHelp;
  String get rankingLabel;
  String get rankingLabelHelp;
  String get yearValidated;
  String get yearNotValidated;
  String get currentAcademicYearLabel;
  String get currentAcademicYearHelp;
  String get targetCycleLabel;
  String get targetCycleLabelHelp;
  String get targetLevelLabel;
  String get targetLevelLabelHelp;
  String get optionLabel;
  String get optionLabelHelp;
  String get toDefine;

  // ── Guardian info step ───────────────────────────────────────
  String get primaryGuardian;
  String guardianNumber(int number);
  String get noGuardianInfo;
  String get identificationNumberLabel;
  String get identificationNumberHelp;
  String get phoneNumberLabel;
  String get phoneNumberHelp;
  String get emailLabel;
  String get emailLabelHelp;
  String get relationshipFather;
  String get relationshipMother;
  String get relationshipGuardian;
  String get relationshipUncle;
  String get relationshipAunt;
  String get relationshipGrandparent;
  String get relationshipOther;

  // ── Enrollment stepper ───────────────────────────────────────
  String get stepPersonalInfoSubtitle;
  String get stepAddressSubtitle;
  String get stepAcademicSubtitle;
  String get stepGuardianSubtitle;
  String get stepSummarySubtitle;
  String stepIndicator(int current, int total);
  String get stepForwardHint;
  String get validatePersonalInfoHint;
  String get validateAddressHint;
  String get validateAcademicInfoHint;
  String get validateGuardianInfoHint;
  String get enrollmentReadyForValidation;
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
