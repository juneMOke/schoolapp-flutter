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
  String get reRegistrationSearchHint => 'Enter either First name, Last name and Surname, or the target cycle/level to start the search.';

  @override
  String get reRegistrationAcademicInfoHelp => 'Select the target cycle and level to filter results.';

  @override
  String get reRegistrationSearchNoOptions => 'No cycle/level is available for this search.';

  @override
  String get reRegistrationSearchNeedCriteria => 'Provide either First name, Last name and Surname, or Cycle/Level.';

  @override
  String get reRegistrationSearchReady => 'Valid criteria, you can run the search.';

  @override
  String get reRegistrationSearchInvitationTitle => 'Start a re-registration search';

  @override
  String get reRegistrationSearchInvitationMessage => 'Fill the form above then click Search to display enrollment files.';

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
  String get enrollmentNoResultsDescription => 'No student matches your search criteria.';

  @override
  String get loadingStudents => 'Loading students...';

  @override
  String enrollmentResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: '0 result',
    );
    return '$_temp0';
  }

  @override
  String enrollmentPageFooter(int pageCount, int totalCount) {
    String _temp0 = intl.Intl.pluralLogic(
      pageCount,
      locale: localeName,
      other: 'results',
      one: 'result',
    );
    return '$pageCount $_temp0 of $totalCount';
  }

  @override
  String enrollmentPageIndicator(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusValidated => 'Validated';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get enrollmentCode => 'Enrollment Code';

  @override
  String get enrollmentDetailTitle => 'Enrollment file';

  @override
  String get enrollmentUnknownStudent => 'Student not specified';

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
  String get guardianAddAction => 'Add guardian/contact';

  @override
  String get guardianSaveAction => 'Save';

  @override
  String get guardianRelationshipLabel => 'Relationship';

  @override
  String get guardianDeleteAction => 'Remove this guardian';

  @override
  String get guardianDeleteConfirmTitle => 'Confirm removal';

  @override
  String get guardianDeleteConfirmMessage => 'Do you really want to remove this guardian? This action cannot be undone.';

  @override
  String get guardianDeleteConfirmAction => 'Remove';

  @override
  String get guardianUnlinkSuccess => 'Guardian removed successfully.';

  @override
  String guardianUnlinkError(String message) {
    return 'Failed to remove guardian: $message';
  }

  @override
  String get schoolFees => 'School Fees';

  @override
  String get summary => 'Summary';

  @override
  String get next => 'Continue';

  @override
  String get previous => 'Previous';

  @override
  String get nextPage => 'Next page';

  @override
  String get previousPage => 'Previous page';

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
  String get addressComplementary => 'Additional address';

  @override
  String get addressComplementaryHelp => 'Add street, avenue and number when needed.';

  @override
  String get addressComplementaryPlaceholder => 'Ex: 10, Avenue La source';

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
  String get stepAcademicPreviousSubtitle => 'Previous year academic history';

  @override
  String get stepAcademicTargetSubtitle => 'Target year academic objectives';

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
  String get completedEnrollmentRedirecting => 'This enrollment is already completed. Redirecting to First Registration.';

  @override
  String get validateEnrollment => 'Validate enrollment';

  @override
  String get validatingEnrollment => 'Validating...';

  @override
  String get goToFirstRegistration => 'Go to First Registration';

  @override
  String get enrollmentStatusUpdateSuccess => 'Status updated successfully.';

  @override
  String enrollmentStatusUpdateError(String message) {
    return 'Failed to update status: $message';
  }

  @override
  String get personalInfoSaveHintBeforeContinue => 'Please save your changes before continuing.';

  @override
  String get personalInfoValidationReasonsTitle => 'Please correct the following fields:';

  @override
  String requiredFieldError(String field) {
    return 'The $field field is required.';
  }

  @override
  String invalidNumberFieldError(String field) {
    return 'The $field field must contain a valid number.';
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
  String get saveAddress => 'Save address';

  @override
  String get savingAddress => 'Saving address...';

  @override
  String get saveAcademicInfo => 'Save academic info';

  @override
  String get savingAcademicInfo => 'Saving...';

  @override
  String get saveGuardianInfo => 'Save guardian';

  @override
  String get savingGuardianInfo => 'Saving guardian...';

  @override
  String get academicInfoValidationReasonsTitle => 'Please correct the following academic fields:';

  @override
  String get academicInfoSaveHintBeforeContinue => 'Please save academic changes before continuing.';

  @override
  String get academicInfoSaveSuccess => 'Academic information updated successfully.';

  @override
  String academicInfoSaveError(String message) {
    return 'Academic info update failed: $message';
  }

  @override
  String get addressValidationReasonsTitle => 'Please correct the following address fields:';

  @override
  String get addressNoCityAvailable => 'No city is available in the catalog.';

  @override
  String get addressSelectCityFirst => 'Select a city first.';

  @override
  String get addressNoDistrictAvailable => 'No district is available for this city.';

  @override
  String get addressSelectDistrictFirst => 'Select a district first.';

  @override
  String get addressNoMunicipalityAvailable => 'No municipality is available for this district.';

  @override
  String get addressSelectMunicipalityFirst => 'Select a municipality first.';

  @override
  String get addressNoNeighborhoodAvailable => 'No neighborhood is available for this municipality.';

  @override
  String get addressSaveHintBeforeContinue => 'Please save address changes before continuing.';

  @override
  String get addressSaveSuccess => 'Address updated successfully.';

  @override
  String addressSaveError(String message) {
    return 'Address update failed: $message';
  }

  @override
  String get enrollmentStatusFilterLabel => 'Status';

  @override
  String get enrollmentStatusInProgress => 'In Progress';

  @override
  String get enrollmentStatusAdminCompleted => 'Admin Completed';

  @override
  String get enrollmentStatusFinancialCompleted => 'Financial Completed';

  @override
  String get enrollmentStatusCompleted => 'Completed';

  @override
  String get enrollmentStatusValidated => 'Validated';

  @override
  String get enrollmentStatusRejected => 'Rejected';

  @override
  String get enrollmentStatusCancelled => 'Cancelled';

  @override
  String get enrollmentReadOnlyTitle => 'View-only mode';

  @override
  String get enrollmentReadOnlyMessage => 'This enrollment is finalized (COMPLETED). Information is displayed in read-only mode.';

  @override
  String get enrollmentEditableTitle => 'Edit mode';

  @override
  String get enrollmentEditableMessage => 'This enrollment is in progress (IN_PROGRESS). Information can be updated.';

  @override
  String get studentChargesStepTitle => 'Student charges';

  @override
  String get studentChargesStepSubtitle => 'Financial charges applied to the student';

  @override
  String get studentChargesLoading => 'Loading student charges...';

  @override
  String get studentChargesRetry => 'Retry';

  @override
  String get studentChargesEmpty => 'No charges are available for this student.';

  @override
  String get studentChargesUnavailable => 'Student charges cannot be loaded without a student or target level.';

  @override
  String get studentChargesAmountColumn => 'Amount';

  @override
  String get studentChargesAmountPaidLabel => 'Paid amount';

  @override
  String get studentChargesSaveAction => 'Save charges';

  @override
  String get studentChargesSavingAction => 'Saving charges...';

  @override
  String get studentChargesSaveSuccess => 'Charges saved successfully.';

  @override
  String get studentChargesSaveHintBeforeContinue => 'Please save charge changes before continuing.';

  @override
  String get studentChargesNetworkError => 'Unable to load charges. Please check your internet connection.';

  @override
  String get studentChargesNotFound => 'No charges were found for this student.';

  @override
  String get studentChargesValidationError => 'The requested charge data is invalid.';

  @override
  String get studentChargesUnauthorizedError => 'You are not allowed to access these charges.';

  @override
  String get studentChargesInvalidCredentialsError => 'Your credentials do not allow access to these charges.';

  @override
  String get studentChargesServerError => 'The server is currently unavailable.';

  @override
  String get studentChargesStorageError => 'A local error prevents charges from being displayed.';

  @override
  String get studentChargesAuthError => 'An authentication error prevents charges from loading.';

  @override
  String get studentChargesUnknownError => 'An unexpected error occurred while loading charges.';

  @override
  String get studentChargeStatusDue => 'Due';

  @override
  String get studentChargeStatusPartial => 'Partial';

  @override
  String get studentChargeStatusPaid => 'Paid';

  @override
  String get facturationPageHeaderTitle => 'Student Billing';

  @override
  String get facturationPageHeaderSubtitle => 'Search a student by name or class level to view and manage their school fees.';

  @override
  String get facturationPageHeaderChipByName => 'Search by name';

  @override
  String get facturationPageHeaderChipByLevel => 'Filter by level';

  @override
  String get facturationPageHeaderChipViewCharges => 'View charges';

  @override
  String get facturationSearchTitle => 'Search Students';

  @override
  String get facturationSearchHint => 'Enter First name, Last name, Surname and/or Cycle/Level to filter results.';

  @override
  String get facturationSearchInvitationTitle => 'Start a billing search';

  @override
  String get facturationSearchInvitationMessage => 'Select a level or enter a student name then click Search to display records.';

  @override
  String get facturationViewChargesLabel => 'View charges';

  @override
  String get facturationActionsColumnLabel => 'Actions';

  @override
  String get facturationNoResultsDescription => 'No student matches these criteria. Update the form and try again.';

  @override
  String get facturationDetailBackLabel => 'Back to billing';

  @override
  String get facturationDetailContextErrorTitle => 'Detail context unavailable';

  @override
  String get facturationDetailContextErrorMessage => 'Required context for this detail view is missing. Go back to billing list and open the detail again.';

  @override
  String get facturationDetailUnknownValue => '-';

  @override
  String get facturationDetailStudentSectionTitle => 'Student information';

  @override
  String get facturationDetailStudentLastName => 'Last name';

  @override
  String get facturationDetailStudentFirstName => 'First name';

  @override
  String get facturationDetailStudentSurname => 'Surname';

  @override
  String get facturationDetailStudentLevelGroup => 'Level group';

  @override
  String get facturationDetailStudentLevel => 'Level';

  @override
  String get facturationDetailInfoTitle => 'Billing detail';

  @override
  String get facturationDetailInfoSubtitle => 'Review recent payments and student charge status for the selected academic year.';

  @override
  String get facturationDetailInfoChipPayments => 'Payments';

  @override
  String get facturationDetailInfoChipCharges => 'Charges';

  @override
  String get facturationDetailPaymentsSectionTitle => 'Recent payments';

  @override
  String get facturationDetailPaymentsSectionSubtitle => 'Payment history recorded for this student.';

  @override
  String get facturationDetailCollectPaymentAction => 'Collect payment';

  @override
  String get facturationDetailPaymentsRetry => 'Retry';

  @override
  String get facturationDetailPaymentsEmpty => 'No payment has been recorded for this student.';

  @override
  String get facturationDetailPaymentPayerColumn => 'Payer details';

  @override
  String get facturationDetailPaymentPaidAtColumn => 'Paid at';

  @override
  String get facturationDetailPaymentAmountColumn => 'Amount';

  @override
  String get facturationDetailPaymentActionsColumn => 'Actions';

  @override
  String get facturationDetailViewPaymentLabel => 'View payment detail';

  @override
  String get facturationPaymentDetailHeroTitle => 'Payment detail';

  @override
  String get facturationPaymentDetailHeroSubtitle => 'Review this payment information and the breakdown of allocated amounts.';

  @override
  String get facturationPaymentInfoSectionTitle => 'Payment information';

  @override
  String get facturationPaymentPayerLabel => 'Payer';

  @override
  String get facturationPaymentAmountLabel => 'Total paid amount';

  @override
  String get facturationPaymentPaidAtLabel => 'Paid at';

  @override
  String get facturationPaymentAllocationsSectionTitle => 'Payment allocations';

  @override
  String get facturationPaymentAllocationsSectionSubtitle => 'List of charges covered by this payment.';

  @override
  String get facturationPaymentAllocationsTotalLabel => 'Allocated total';

  @override
  String get facturationPaymentAllocationsEmpty => 'No allocation was found for this payment.';

  @override
  String get facturationPaymentAllocationsConsistencyOk => 'Allocation sum is consistent with the total paid amount.';

  @override
  String get facturationPaymentAllocationsConsistencyWarning => 'Inconsistency detected: allocation sum does not match the total paid amount.';

  @override
  String get facturationPaymentAllocationsNetworkError => 'Unable to load payment allocations. Please check your internet connection.';

  @override
  String get facturationPaymentAllocationsNotFound => 'No allocation found for this payment.';

  @override
  String get facturationPaymentAllocationsValidationError => 'Requested allocation data is invalid.';

  @override
  String get facturationPaymentAllocationsUnauthorizedError => 'You are not allowed to access allocations for this payment.';

  @override
  String get facturationPaymentAllocationsInvalidCredentialsError => 'Your credentials do not allow access to allocations for this payment.';

  @override
  String get facturationPaymentAllocationsServerError => 'The server is currently unavailable.';

  @override
  String get facturationPaymentAllocationsStorageError => 'A local error prevents allocations from being displayed.';

  @override
  String get facturationPaymentAllocationsAuthError => 'An authentication error prevents allocations from loading.';

  @override
  String get facturationPaymentAllocationsUnknownError => 'An unexpected error occurred while loading allocations.';

  @override
  String get facturationDetailChargesSectionTitle => 'Student charges';

  @override
  String get facturationDetailChargesSectionSubtitle => 'Breakdown of expected, paid and remaining amounts.';

  @override
  String get facturationDetailChargesRetry => 'Retry';

  @override
  String get facturationDetailChargesEmpty => 'No charge was found for this student.';

  @override
  String get facturationDetailChargeLabelColumn => 'Label';

  @override
  String get facturationDetailChargeExpectedAmountColumn => 'Expected amount';

  @override
  String get facturationDetailChargePaidAmountColumn => 'Paid amount';

  @override
  String get facturationDetailChargeRemainingAmountColumn => 'Remaining amount';

  @override
  String get facturationDetailChargeStatusColumn => 'Status';

  @override
  String get facturationPaymentsNetworkError => 'Unable to load payments. Please check your internet connection.';

  @override
  String get facturationPaymentsNotFound => 'No payment was found for this student.';

  @override
  String get facturationPaymentsValidationError => 'Requested payment data is invalid.';

  @override
  String get facturationPaymentsUnauthorizedError => 'You are not allowed to access these payments.';

  @override
  String get facturationPaymentsInvalidCredentialsError => 'Your credentials do not allow access to these payments.';

  @override
  String get facturationPaymentsServerError => 'The server is currently unavailable.';

  @override
  String get facturationPaymentsStorageError => 'A local error prevents payments from being displayed.';

  @override
  String get facturationPaymentsAuthError => 'An authentication error prevents payments from loading.';

  @override
  String get facturationPaymentsUnknownError => 'An unexpected error occurred while loading payments.';

  @override
  String get facturationPrintReceiptLabel => 'Print receipt';

  @override
  String get facturationPrintReceiptSubtitle => 'Generate and download the receipt for this payment';

  @override
  String get facturationPrintStatementsLabel => 'Print statements';

  @override
  String get facturationPrintStatementsSubtitle => 'Generate and download the billing statements for this student';

  @override
  String get facturationChargeDetailBackLabel => 'Back to billing detail';

  @override
  String get facturationChargeDetailHeroTitle => 'Charge detail';

  @override
  String get facturationChargeDetailHeroSubtitle => 'Review this charge status and the payments allocated to it.';

  @override
  String get facturationChargeDetailInfoSectionTitle => 'Charge information';

  @override
  String get facturationChargeDetailExpectedAmountLabel => 'Expected amount';

  @override
  String get facturationChargeDetailPaidAmountLabel => 'Paid amount';

  @override
  String get facturationChargeDetailRemainingAmountLabel => 'Remaining amount';

  @override
  String get facturationChargeDetailStatusLabel => 'Status';

  @override
  String get facturationChargeDetailAllocationsSectionTitle => 'Allocations for this charge';

  @override
  String get facturationChargeDetailAllocationsSectionSubtitle => 'Breakdown of payments allocated to this charge.';

  @override
  String get facturationChargeDetailAllocationsTotalLabel => 'Allocated total';

  @override
  String get facturationChargeDetailAllocationsEmpty => 'No allocation was found for this charge.';

  @override
  String get facturationChargeDetailAllocationsRetry => 'Retry';

  @override
  String get facturationChargeDetailAllocationsNetworkError => 'Unable to load allocations. Please check your internet connection.';

  @override
  String get facturationChargeDetailAllocationsNotFound => 'No allocation found for this charge.';

  @override
  String get facturationChargeDetailAllocationsValidationError => 'Requested allocation data is invalid.';

  @override
  String get facturationChargeDetailAllocationsUnauthorizedError => 'You are not allowed to access allocations for this charge.';

  @override
  String get facturationChargeDetailAllocationsInvalidCredentialsError => 'Your credentials do not allow access to allocations for this charge.';

  @override
  String get facturationChargeDetailAllocationsServerError => 'The server is currently unavailable.';

  @override
  String get facturationChargeDetailAllocationsStorageError => 'A local error prevents allocations from being displayed.';

  @override
  String get facturationChargeDetailAllocationsAuthError => 'An authentication error prevents allocations from loading.';

  @override
  String get facturationChargeDetailAllocationsUnknownError => 'An unexpected error occurred while loading allocations.';

  @override
  String get facturationChargeDetailContextErrorTitle => 'Charge detail context unavailable';

  @override
  String get facturationChargeDetailContextErrorMessage => 'Required context for this charge detail view is missing. Go back and open the detail again.';

  @override
  String get facturationCreatePaymentBackLabel => 'Back to billing detail';

  @override
  String get facturationCreatePaymentHeroTitle => 'New payment';

  @override
  String get facturationCreatePaymentHeroSubtitle => 'Fill in the payer information and allocations to record a payment.';

  @override
  String get facturationCreatePaymentPayerSectionTitle => 'Payer information';

  @override
  String get facturationCreatePaymentPayerLastNameLabel => 'Last name';

  @override
  String get facturationCreatePaymentPayerLastNameHint => 'Enter last name';

  @override
  String get facturationCreatePaymentPayerFirstNameLabel => 'First name';

  @override
  String get facturationCreatePaymentPayerFirstNameHint => 'Enter first name';

  @override
  String get facturationCreatePaymentPayerMiddleNameLabel => 'Surname (optional)';

  @override
  String get facturationCreatePaymentPayerMiddleNameHint => 'Enter surname';

  @override
  String get facturationCreatePaymentPayerFieldRequired => 'This field is required';

  @override
  String get facturationCreatePaymentAllocationSectionTitle => 'Payment allocations';

  @override
  String get facturationCreatePaymentAllocationSectionSubtitle => 'Associate an amount to one or more student charges.';

  @override
  String get facturationCreatePaymentAddAllocationLabel => 'Add allocation';

  @override
  String get facturationCreatePaymentAllChargesPaid => 'All student charges are already paid.';

  @override
  String get facturationCreatePaymentChargesUnavailable => 'No charges available. Go back to the list and try again.';

  @override
  String get facturationCreatePaymentChargeDropdownHint => 'Select a charge';

  @override
  String get facturationCreatePaymentAmountLabel => 'Amount to pay';

  @override
  String get facturationCreatePaymentAmountHint => 'E.g.: 5000';

  @override
  String get facturationCreatePaymentAmountRequired => 'Amount is required';

  @override
  String get facturationCreatePaymentAmountInvalid => 'Please enter a valid number';

  @override
  String get facturationCreatePaymentAmountExceedsRemaining => 'Amount cannot exceed remaining balance';

  @override
  String get facturationCreatePaymentAmountMustBePositive => 'Amount must be greater than zero';

  @override
  String get facturationCreatePaymentBeforeLabel => 'Before payment';

  @override
  String get facturationCreatePaymentAfterLabel => 'After payment';

  @override
  String get facturationCreatePaymentSubmitLabel => 'Validate payment';

  @override
  String get facturationCreatePaymentNoAllocations => 'Add at least one allocation to validate the payment.';

  @override
  String get facturationCreatePaymentConfirmTitle => 'Confirm payment';

  @override
  String get facturationCreatePaymentConfirmMessage => 'This operation is irreversible. Do you confirm recording this payment?';

  @override
  String get facturationCreatePaymentConfirmCancel => 'Cancel';

  @override
  String get facturationCreatePaymentConfirmValidate => 'Confirm';

  @override
  String get facturationCreatePaymentSuccessMessage => 'Payment successfully recorded.';

  @override
  String get facturationCreatePaymentExpectedLabel => 'Expected';

  @override
  String get facturationCreatePaymentPaidLabel => 'Already paid';

  @override
  String get facturationCreatePaymentRemainingLabel => 'Remaining';

  @override
  String get facturationCreatePaymentStatusLabel => 'Status';

  @override
  String get facturationCreatePaymentNetworkError => 'Check your connection and try again.';

  @override
  String get facturationCreatePaymentNotFoundError => 'The requested resource was not found.';

  @override
  String get facturationCreatePaymentValidationError => 'Submitted data is invalid. Please review the form.';

  @override
  String get facturationCreatePaymentUnauthorizedError => 'You are not authorized to perform this operation.';

  @override
  String get facturationCreatePaymentInvalidCredentialsError => 'Your credentials do not allow recording this payment.';

  @override
  String get facturationCreatePaymentServerError => 'Server is unavailable. Please try again later.';

  @override
  String get facturationCreatePaymentStorageError => 'A storage error occurred.';

  @override
  String get facturationCreatePaymentAuthError => 'An authentication error occurred.';

  @override
  String get facturationCreatePaymentUnknownError => 'An unexpected error occurred.';

  @override
  String get facturationCreatePaymentNoChargesAvailable => 'No unpaid charges available for this student.';

  @override
  String get bootstrapContextUnavailableTitle => 'Enrollment context unavailable';

  @override
  String get bootstrapContextUnavailableMessage => 'Bootstrap data (academic year / school) is missing. Please sign out and sign in again to reload the configuration.';

  @override
  String get signOutAction => 'Sign out';
}
