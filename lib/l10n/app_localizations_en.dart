// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get schoolApp => 'ETEELO TECH';

  @override
  String get logout => 'Logout';

  @override
  String welcome(String name) {
    return 'Welcome$name!';
  }

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get receiveOtp => 'Receive an OTP code';

  @override
  String get enterEmailToReceiveOtp => 'Enter your email to receive a verification code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpValidation => 'OTP Validation';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String codeSentTo(String email) {
    return 'Code sent to $email';
  }

  @override
  String get otpCodeLabel => 'OTP Code';

  @override
  String get validateCode => 'Validate code';

  @override
  String get otpMustBeSixDigits => 'OTP code must contain 6 digits';

  @override
  String get newPassword => 'New password';

  @override
  String get chooseNewPassword => 'Choose a new password';

  @override
  String account(String email) {
    return 'Account: $email';
  }

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get validateAndLogin => 'Validate and Login';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get menuInscriptions => 'Registrations';

  @override
  String get menuFinances => 'Finances';

  @override
  String get menuClasses => 'Classes';

  @override
  String get menuDisciplines => 'Disciplines';

  @override
  String get subMenuDashboard => 'Dashboard';

  @override
  String get subMenuPreRegistrations => 'Pre-Registrations';

  @override
  String get subMenuReRegistrations => 'Re-Registrations';

  @override
  String get subMenuFirstRegistration => 'First Registration';

  @override
  String get subMenuBilling => 'Billing';

  @override
  String get subMenuOrganization => 'Organization';

  @override
  String get subMenuClassesList => 'Classes List';

  @override
  String get subMenuAttendance => 'Attendance';

  @override
  String get subMenuDisciplinesList => 'Disciplines List';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get pageUnderConstruction => 'This page is under development';

  @override
  String get preRegistrations => 'Pre-Registrations';

  @override
  String get searchStudents => 'Search Students';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get surname => 'Surname';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get viewDetails => 'View Details';

  @override
  String get editEnrollment => 'Edit';

  @override
  String get exportData => 'Export';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get loadingStudents => 'Loading students...';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusValidated => 'Validated';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get enrollmentCode => 'Enrollment Code';

  @override
  String get gender => 'Gender';

  @override
  String get actions => 'Actions';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get address => 'Address';

  @override
  String get previousYear => 'Previous Year';

  @override
  String get targetYear => 'Target Year';

  @override
  String get guardianInformation => 'Guardian Information';

  @override
  String get schoolFees => 'School Fees';

  @override
  String get summary => 'Summary';

  @override
  String get next => 'Continue';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get personalInfoSubtitle => 'Editable personal information';

  @override
  String get firstNameHelp => 'The student\'s official first name.';

  @override
  String get lastNameHelp => 'The student\'s family name.';

  @override
  String get surnameHelp => 'The middle name or other common name.';

  @override
  String get dateOfBirthHelp => 'Use the selector to choose the date of birth.';

  @override
  String get birthPlace => 'Place of birth';

  @override
  String get birthPlaceHelp => 'City or locality of birth.';

  @override
  String get nationality => 'Nationality';

  @override
  String get nationalityHelp => 'The student\'s main nationality.';

  @override
  String get genderHelp => 'Gender recorded in the administrative file.';

  @override
  String get selectDateOfBirthHelpText => 'Select a date of birth';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String enterFieldHint(String label) {
    return 'Enter $label';
  }

  @override
  String get dateHint => 'dd/mm/yyyy';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get city => 'City';

  @override
  String get cityHelp => 'Student\'s city of residence.';

  @override
  String get district => 'District';

  @override
  String get districtHelp => 'District or borough.';

  @override
  String get municipality => 'Municipality';

  @override
  String get municipalityHelp => 'Municipality of residence.';

  @override
  String get neighborhood => 'Neighborhood';

  @override
  String get neighborhoodHelp => 'Neighborhood or street of residence.';

  @override
  String get fullAddress => 'Full address';

  @override
  String get fullAddressHelp => 'Full residential address.';

  @override
  String get academicYearLabel => 'Academic year';

  @override
  String get academicYearLabelHelp => 'Reference academic year.';

  @override
  String get schoolLabel => 'School';

  @override
  String get schoolLabelHelp => 'Name of the previous school.';

  @override
  String get schoolCycle => 'Cycle';

  @override
  String get schoolCycleHelp => 'Previous teaching cycle.';

  @override
  String get schoolLevelLabel => 'Level';

  @override
  String get schoolLevelLabelHelp => 'Previous study level.';

  @override
  String get averageLabel => 'Average';

  @override
  String get averageLabelHelp => 'Annual average obtained.';

  @override
  String get rankingLabel => 'Ranking';

  @override
  String get rankingLabelHelp => 'Class ranking.';

  @override
  String get yearValidated => 'Year validated';

  @override
  String get yearNotValidated => 'Not validated';

  @override
  String get currentAcademicYearLabel => 'Academic year';

  @override
  String get currentAcademicYearHelp => 'Target academic year.';

  @override
  String get targetCycleLabel => 'Target cycle';

  @override
  String get targetCycleLabelHelp => 'Target cycle for this enrollment.';

  @override
  String get targetLevelLabel => 'Target level';

  @override
  String get targetLevelLabelHelp => 'Target level for this enrollment.';

  @override
  String get optionLabel => 'Option';

  @override
  String get optionLabelHelp => 'Desired option or specialization.';

  @override
  String get toDefine => 'To be defined';

  @override
  String get primaryGuardian => 'Primary Guardian';

  @override
  String guardianNumber(int number) {
    return 'Guardian $number';
  }

  @override
  String get noGuardianInfo => 'No guardian information available';

  @override
  String get identificationNumberLabel => 'Identification number';

  @override
  String get identificationNumberHelp => 'Official identification number.';

  @override
  String get phoneNumberLabel => 'Phone';

  @override
  String get phoneNumberHelp => 'Guardian\'s phone number.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailLabelHelp => 'Guardian\'s email address.';

  @override
  String get relationshipFather => 'Father';

  @override
  String get relationshipMother => 'Mother';

  @override
  String get relationshipGuardian => 'Guardian';

  @override
  String get relationshipUncle => 'Uncle';

  @override
  String get relationshipAunt => 'Aunt';

  @override
  String get relationshipGrandparent => 'Grandparent';

  @override
  String get relationshipOther => 'Other';

  @override
  String get stepPersonalInfoSubtitle => 'General student information';

  @override
  String get stepAddressSubtitle => 'Location and full address';

  @override
  String get stepAcademicSubtitle => 'Academic history and goals';

  @override
  String get stepGuardianSubtitle => 'Legal guardians and contacts';

  @override
  String get stepSummarySubtitle => 'Final enrollment summary';

  @override
  String stepIndicator(int current, int total) {
    return 'Step $current / $total';
  }

  @override
  String get stepForwardHint => 'Click Continue to advance step by step.';

  @override
  String get validatePersonalInfoHint => 'Please complete the personal information.';

  @override
  String get validateAddressHint => 'Please complete the student\'s address.';

  @override
  String get validateAcademicInfoHint => 'Please complete the academic information.';

  @override
  String get validateGuardianInfoHint => 'Please check the guardian information.';

  @override
  String get enrollmentReadyForValidation => 'File ready for final validation.';

  @override
  String get personalInfoSaveHintBeforeContinue => 'Please save your changes before continuing.';

  @override
  String get personalInfoValidationReasonsTitle => 'Please correct the following fields:';

  @override
  String requiredFieldError(String field) {
    return 'The $field field is required.';
  }

  @override
  String get savePersonalInfo => 'Save';

  @override
  String get savingPersonalInfo => 'Saving...';

  @override
  String get personalInfoSaveSuccess => 'Personal information updated successfully.';

  @override
  String personalInfoSaveError(String message) {
    return 'Update failed: $message';
  }

  @override
  String get bootstrapContextUnavailableTitle => 'Enrollment context unavailable';

  @override
  String get bootstrapContextUnavailableMessage => 'Bootstrap data (academic year / school) is missing. Please sign out and sign in again to reload the configuration.';

  @override
  String get signOutAction => 'Sign out';
}
