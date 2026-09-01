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
  String get loginEyebrow => 'Management area';

  @override
  String get loginSubtitle => 'Access your school\'s dashboard.';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginSubmitting => 'Signing in…';

  @override
  String get loginSignature => 'eteyelo · the school, in Lingala';

  @override
  String get loginBrandTitle => 'The Congolese school, now digital.';

  @override
  String get loginBrandTitleCondensed => 'The school, now digital.';

  @override
  String get loginBrandTitleHighlight => 'digital';

  @override
  String get loginBrandSubtitle =>
      'Registrations, finances, classes and attendance — one app, on every screen.';

  @override
  String get loginEmailRequired => 'Email address is required.';

  @override
  String get loginEmailInvalid => 'Invalid email format.';

  @override
  String get loginPasswordRequired => 'Password is required.';

  @override
  String get loginErrorInvalidCredentials =>
      'Incorrect email or password. Check your credentials and try again.';

  @override
  String get loginErrorNetwork => 'No connection. Check your network.';

  @override
  String get loginErrorAccountDisabled =>
      'Account disabled. Contact your school administrator.';

  @override
  String get loginErrorServer => 'Server error. Please try again shortly.';

  @override
  String loginErrorRateLimited(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s';
  }

  @override
  String get loginContactAdmin => 'Contact the administrator';

  @override
  String get loginErrorOfflineFirstLogin =>
      'No connection, and this account has never signed in on this tablet. A first online sign-in is required.';

  @override
  String get loginErrorOfflineWindowExpired =>
      'Offline work period expired. Sign in online as soon as the network is back.';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String get schoolApp => 'ETEELO CONNECT';

  @override
  String get splashBrandPrimary => 'ETEELO';

  @override
  String get splashBrandSecondary => 'CONNECT';

  @override
  String get splashTagline => 'Simplify your school management';

  @override
  String get splashSemanticsLabel => 'ETEELO CONNECT — splash screen';

  @override
  String get sessionOfflineBanner => 'Offline session — verified locally';

  @override
  String get sessionWarningBanner => 'Session needs refresh — reconnect soon';

  @override
  String get sessionReadOnlyBanner =>
      'Read-only — online reconnection required';

  @override
  String get splashErrorTitle => 'Connection failed';

  @override
  String get splashErrorMessage =>
      'Unable to load the application data. Check your connection, then try again.';

  @override
  String get splashErrorRetry => 'Retry';

  @override
  String get accueilUnknownRightsTitle => 'Rights not known';

  @override
  String get accueilUnknownRightsMessage =>
      'Your rights are not known on this device yet. Sign in online to retrieve them.';

  @override
  String get accueilNoAccessTitle => 'No module available';

  @override
  String get accueilNoAccessMessage =>
      'Your account has access to no module. Contact your school administrator to have your rights adjusted.';

  @override
  String get accueilNoAccessOfflineMessage =>
      'Your session was opened offline and no rights are known for this account. Sign in online as soon as the network is available.';

  @override
  String get splashForbiddenTitle => 'Access not allowed';

  @override
  String get splashForbiddenMessage =>
      'Your account does not have the rights needed to open the application. Contact your school administrator.';

  @override
  String get splashNotProvisionedTitle => 'School not set up yet';

  @override
  String get splashNotProvisionedMessage =>
      'This school has no open academic year yet. Setup declares the year, the classes and the fees, then brings the school into service.';

  @override
  String get splashNotProvisionedAction => 'Set up the school';

  @override
  String get splashNotProvisionedWaitMessage =>
      'This school has no open academic year yet. Only school management can set it up — check with them before retrying.';

  @override
  String get configurationTitle => 'Setup';

  @override
  String get configurationSubtitle => 'Bringing the school into service';

  @override
  String configurationStepCounter(int current, int total) {
    return 'Step $current / $total';
  }

  @override
  String get configurationExitTooltip => 'Leave setup';

  @override
  String get configurationStepSchool => 'School';

  @override
  String get configurationStepAcademicYear => 'Year';

  @override
  String get configurationStepStructure => 'Structure';

  @override
  String get configurationStepFees => 'Fees';

  @override
  String get configurationStepActivation => 'Activation';

  @override
  String configurationStepSemantics(int current, int total, String title) {
    return 'Step $current of $total, $title';
  }

  @override
  String get configurationBack => 'Back';

  @override
  String get configurationSave => 'Save';

  @override
  String get configurationContinue => 'Continue';

  @override
  String get configurationSaving => 'Saving…';

  @override
  String get configurationSaved => 'Saved';

  @override
  String get configurationDraftSaved => 'Draft saved';

  @override
  String get configurationSaveBarDefaultHint =>
      'Fill in the required fields to continue';

  @override
  String get configurationSchoolSectionTitle => 'School identity';

  @override
  String get configurationSchoolSectionSubtitle =>
      'This information appears on certificates, receipts and report cards.';

  @override
  String get configurationSchoolName => 'School name';

  @override
  String get configurationSchoolCountry => 'Country';

  @override
  String get configurationSchoolCity => 'City';

  @override
  String get configurationSchoolDistrict => 'District';

  @override
  String get configurationSchoolMunicipality => 'Municipality';

  @override
  String get configurationSchoolMunicipalityPlaceholder =>
      'Pick a district first';

  @override
  String get configurationSchoolAddress => 'Address';

  @override
  String get configurationSchoolPhone => 'School phone';

  @override
  String get configurationSchoolEmail => 'School email';

  @override
  String configurationSchoolMissingHint(String fields) {
    return 'Still needed: $fields';
  }

  @override
  String get configurationSchoolReadOnlyNote =>
      'Country and city are fixed: the application is deployed in Kinshasa.';

  @override
  String get configurationYearSectionTitle => 'Academic year';

  @override
  String get configurationYearSectionSubtitle =>
      'A first year is proposed from today\'s date — adjust the dates if needed.';

  @override
  String get configurationYearProposed => 'Proposed automatically';

  @override
  String get configurationYearEdited => 'Edited';

  @override
  String get configurationYearRestore => 'Restore the proposal';

  @override
  String get configurationYearStart => 'First day of class';

  @override
  String get configurationYearEnd => 'End of year';

  @override
  String get configurationYearDuration => 'Length';

  @override
  String configurationYearDurationValue(int months) {
    return '≈ $months months';
  }

  @override
  String get configurationYearRangeError => 'The end must follow the start';

  @override
  String get configurationYearPeriodsNote =>
      'Terms and semesters are set later, in Results.';

  @override
  String get configurationStructureTitle => 'Cycles, levels and classes';

  @override
  String configurationTotalCycles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cycles',
      one: 'cycle',
    );
    return '$_temp0';
  }

  @override
  String configurationTotalLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'levels',
      one: 'level',
    );
    return '$_temp0';
  }

  @override
  String configurationTotalClassrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'classes',
      one: 'class',
    );
    return '$_temp0';
  }

  @override
  String configurationTotalCourses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'courses',
      one: 'course',
    );
    return '$_temp0';
  }

  @override
  String get configurationCycleClassroomsPerLevel => 'Classes per level';

  @override
  String get configurationCycleNotOffered => 'Not offered';

  @override
  String configurationCycleSummary(int open, int total, int classrooms) {
    String _temp0 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms class',
    );
    return '$open / $total · $_temp0';
  }

  @override
  String get configurationLevelNotOffered => 'Level not offered this year';

  @override
  String get configurationLevelNoGrid =>
      'No official grid — these classes will have no courses.';

  @override
  String configurationSectionsServed(String level) {
    return 'Grids served on $level';
  }

  @override
  String configurationSectionCourses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '$count course',
    );
    return '$_temp0';
  }

  @override
  String configurationStructureHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes will be created for the year',
      one: '$count class will be created for the year',
    );
    return '$_temp0';
  }

  @override
  String get configurationStructureEmptyHint => 'Tick at least one level';

  @override
  String get configurationStructureEmptyTitle => 'No level selected';

  @override
  String get configurationStructureEmptyMessage =>
      'A school needs at least one class to open enrolments. Restore the default proposal, or tick the levels you are opening.';

  @override
  String get configurationStructureRestore => 'Restore the proposal';

  @override
  String get configurationFeesTitle => 'School fees';

  @override
  String get configurationFeeNew => 'New fee';

  @override
  String get configurationFeeFormTitle => 'New fee';

  @override
  String get configurationFeeFormEditTitle => 'Edit fee';

  @override
  String get configurationFeeType => 'Fee type';

  @override
  String configurationFeeTypeOthers(int count) {
    return 'Other types ($count)';
  }

  @override
  String get configurationFeeLabel => 'Label shown to parents';

  @override
  String get configurationFeeAmount => 'Amount';

  @override
  String get configurationFeeCurrency => 'Currency';

  @override
  String get configurationFeeDueAt => 'Due date';

  @override
  String get configurationFeeScope => 'Applies to';

  @override
  String get configurationFeeScopeAll => 'All opened levels';

  @override
  String get configurationFeeScopeSome => 'Selected levels';

  @override
  String configurationFeeScopeAllHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open levels',
      one: '$count open level',
    );
    return 'Will apply to $_temp0';
  }

  @override
  String configurationFeeScopeCount(int selected, int total) {
    return '$selected / $total selected';
  }

  @override
  String get configurationFeeScopeWholeCycle => 'Whole cycle';

  @override
  String get configurationFeeAdd => 'Add the fee';

  @override
  String get configurationFeeUpdate => 'Update';

  @override
  String get configurationFeeCancel => 'Cancel';

  @override
  String configurationFeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fees defined',
      one: '$count fee defined',
      zero: 'No fee defined',
    );
    return '$_temp0';
  }

  @override
  String configurationFeeCatalogTotal(String total) {
    return 'Catalogue total: $total';
  }

  @override
  String get configurationFeePerStudent => 'per student';

  @override
  String configurationFeeLevelsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count levels',
      one: '$count level',
    );
    return '$_temp0';
  }

  @override
  String configurationFeeDueLabel(String date) {
    return 'due $date';
  }

  @override
  String configurationFeeDeleted(String label) {
    return 'Fee \"$label\" deleted';
  }

  @override
  String configurationFeeSaved(String label) {
    return 'Fee \"$label\" saved';
  }

  @override
  String get configurationFeesEmptyTitle => 'No fees yet';

  @override
  String get configurationFeesEmptyMessage =>
      'Add at least one fee — registration, tuition, canteen — so billing can generate collection notes.';

  @override
  String get configurationFeesEmptyAction => 'Create the first fee';

  @override
  String get configurationFeesEmptyHint => 'Add at least one fee to continue';

  @override
  String get configurationFeesDraftHint => 'Finish the fee you are editing';

  @override
  String configurationFeesValidHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fees will be attached to the open levels',
      one: '$count fee will be attached to the open levels',
    );
    return '$_temp0';
  }

  @override
  String get configurationSummaryTitle => 'Summary';

  @override
  String get configurationSummaryEdit => 'Edit';

  @override
  String get configurationSummarySchool => 'School';

  @override
  String get configurationSummaryYear => 'Academic year';

  @override
  String configurationSummaryStructure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '$count class',
    );
    return 'Structure · $_temp0';
  }

  @override
  String get configurationSummaryFees => 'School fees';

  @override
  String get configurationSummaryMissing => 'to be filled in';

  @override
  String configurationSummaryCycleLine(int levels, int classrooms) {
    String _temp0 = intl.Intl.pluralLogic(
      levels,
      locale: localeName,
      other: '$levels levels',
      one: '$levels level',
    );
    String _temp1 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms class',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get configurationSummaryNoGrid => 'no official grid';

  @override
  String get configurationCheckSchool => 'School identity complete';

  @override
  String get configurationCheckYear => 'Academic year dated';

  @override
  String configurationCheckClassrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes ready to open',
      one: '$count class ready to open',
      zero: 'No class to open',
    );
    return '$_temp0';
  }

  @override
  String configurationCheckFees(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fees attached to levels',
      one: '$count fee attached to levels',
      zero: 'No fee attached to levels',
    );
    return '$_temp0';
  }

  @override
  String get configurationActivate => 'Bring the school into service';

  @override
  String get configurationActivating => 'Activating…';

  @override
  String get configurationActivateBlocked =>
      'Complete the amber items to activate.';

  @override
  String get configurationActivateFailed => 'Activation failed — try again.';

  @override
  String configurationActivatedTitle(String school) {
    return '$school is in service';
  }

  @override
  String configurationActivatedMessage(String year, int classrooms, int fees) {
    String _temp0 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms class',
    );
    String _temp1 = intl.Intl.pluralLogic(
      fees,
      locale: localeName,
      other: '$fees fees',
      one: '$fees fee',
    );
    return 'The $year year is open with $_temp0 and $_temp1. You can enrol your first students.';
  }

  @override
  String get configurationGoHome => 'Go to the dashboard';

  @override
  String get configurationReviewSetup => 'Review the setup';

  @override
  String get configurationWarningsTitle => 'Worth knowing before activating';

  @override
  String get menuConfiguration => 'Setup';

  @override
  String get subMenuConfigurationSchool => 'School settings';

  @override
  String get configurationSettingsTitle => 'School setup';

  @override
  String configurationSettingsInService(String school) {
    return '$school · in service';
  }

  @override
  String configurationSettingsSummary(String year, int classrooms, int levels) {
    String _temp0 = intl.Intl.pluralLogic(
      classrooms,
      locale: localeName,
      other: '$classrooms classes',
      one: '$classrooms class',
    );
    String _temp1 = intl.Intl.pluralLogic(
      levels,
      locale: localeName,
      other: '$levels levels',
      one: '$levels level',
    );
    return '$year year · $_temp0 · $_temp1';
  }

  @override
  String get configurationSettingsNextYear => 'Prepare next year';

  @override
  String get configurationSettingsNextYearTooltip =>
      'Not available yet: the wizard cannot be replayed, as the server would refuse an already open year. A dedicated action is still to be delivered.';

  @override
  String get configurationSettingsTabIdentity => 'School identity';

  @override
  String get configurationSettingsTabStructure => 'Cycles, levels and classes';

  @override
  String get configurationSettingsTabFees => 'School fees';

  @override
  String get configurationSettingsReadOnly => 'read-only';

  @override
  String get configurationSettingsStructureReadOnlyNote =>
      'The structure can no longer be changed once the school is in service. The server cannot yet cleanly refuse deleting a populated level: wiring it here would risk breaking ongoing enrolments.';

  @override
  String get configurationSettingsSaved => 'Changes saved';

  @override
  String get configurationSettingsSave => 'Save';

  @override
  String get configurationSettingsNoYear => 'No open year';

  @override
  String configurationSettingsTariffsForLevel(String level) {
    return 'Tariffs for $level';
  }

  @override
  String get configurationSettingsTariffOne =>
      'Here a tariff carries a single level: each row is edited on its own.';

  @override
  String get configurationTariffAdd => 'Add a tariff';

  @override
  String get configurationTariffEdit => 'Edit tariff';

  @override
  String get configurationTariffNew => 'New tariff';

  @override
  String get configurationTariffDelete => 'Delete tariff';

  @override
  String configurationTariffDeleteConfirm(String label) {
    return 'Delete \"$label\"? Charges already generated are not affected.';
  }

  @override
  String get configurationTariffSaved => 'Tariff saved';

  @override
  String get configurationTariffDeleted => 'Tariff deleted';

  @override
  String get configurationTariffNone => 'No tariff on this level';

  @override
  String get configurationFeeTypesUnavailableTitle => 'Fee types unavailable';

  @override
  String get configurationFeeTypesUnavailableMessage =>
      'The fee type reference was not loaded. Reload it to enter the school fees.';

  @override
  String get configurationLoadingA11yLabel => 'Loading the step data';

  @override
  String get configurationErrorNetworkTitle => 'Connection lost';

  @override
  String get configurationErrorNetworkMessage =>
      'The setup was not sent. Check your connection, then try again.';

  @override
  String get configurationErrorSessionTitle => 'Your session has expired';

  @override
  String get configurationErrorSessionMessage =>
      'Sign in again to pick up where you left off. Your entries are kept.';

  @override
  String get configurationErrorForbiddenTitle => 'Access denied';

  @override
  String get configurationErrorForbiddenMessage =>
      'Only the school owner can set up the school. Contact your school administrator.';

  @override
  String get configurationErrorServerTitle => 'The server could not save';

  @override
  String get configurationErrorServerMessage =>
      'Something broke. Try again, and quote the code below to support if it persists.';

  @override
  String get configurationErrorRateTitle => 'Too many requests';

  @override
  String get configurationErrorRateMessage =>
      'The server is asking for a pause. Wait a few moments before carrying on.';

  @override
  String get configurationErrorYearExistsTitle =>
      'This academic year already exists';

  @override
  String get configurationErrorYearExistsMessage =>
      'Setup is a bootstrapping gesture: it does not add a year to a school that already has one. Go back to the year step to declare a different one.';

  @override
  String get configurationErrorYearExistsAction => 'Back to the year';

  @override
  String get configurationErrorRetry => 'Try again';

  @override
  String get configurationErrorSignIn => 'Sign in again';

  @override
  String get configurationErrorContact => 'Contact the administrator';

  @override
  String get configurationErrorIncident => 'Incident code';

  @override
  String get configurationErrorReloadCatalog => 'Reload the referential';

  @override
  String splashVersion(String version, String build) {
    return 'v$version (build $build)';
  }

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
  String get enterEmailToReceiveOtp =>
      'Enter your email to receive a verification code.';

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
  String get resetEyebrow => 'Password reset';

  @override
  String get resetBrandTitle => 'Recover your access securely.';

  @override
  String get resetBrandTitleCondensed => 'Account access recovery.';

  @override
  String get resetBrandTitleHighlight => 'access';

  @override
  String get resetBrandSubtitle => 'Reset your password safely.';

  @override
  String resetStepIndicator(int step, int total, String label) {
    return 'Step $step of $total · $label';
  }

  @override
  String get resetStepLabelEmail => 'Email';

  @override
  String get resetStepLabelCode => 'Code';

  @override
  String get resetStepLabelPassword => 'New password';

  @override
  String get resetBackToLogin => 'Back';

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
  String get subMenuFeeControl => 'Fee control';

  @override
  String get menuBoutique => 'Shop';

  @override
  String get subMenuBoutiquePurchases => 'Purchases';

  @override
  String get subMenuBoutiqueHistory => 'History';

  @override
  String get subMenuOrganization => 'Class\ncomposition';

  @override
  String get classesOrganisationHeroTitle => 'Class composition';

  @override
  String get classesOrganisationHeroSubtitle =>
      'Distribute students from one level into sub-classes (e.g. Grade 1 A, Grade 1 B, Grade 1 C) and view the student list for each sub-class.';

  @override
  String get classesOrganisationSearchTitle =>
      'Level selection for class distribution';

  @override
  String classesOrganisationHeaderEyebrow(String schoolYear) {
    return 'Class composition · Year $schoolYear';
  }

  @override
  String get classesOrganisationLevelPlaceholder => 'Choose a cycle first';

  @override
  String get classesOrganisationSearchHint =>
      'Select the cycle and level to organize, then run the search to view the current distribution or prepare sub-class distribution.';

  @override
  String get classesOrganisationClassroomFieldLabel => 'Classroom';

  @override
  String get classesOrganisationDistributionLabel => 'Distribution criterion';

  @override
  String get classesOrganisationDistributionByGender => 'Distribute by gender';

  @override
  String get classesOrganisationDistributionByPercentage =>
      'Distribute by average';

  @override
  String get classesOrganisationDistributeByGenderAction =>
      'Start gender-based distribution';

  @override
  String get classesOrganisationDistributeOfflineHint =>
      'You seem to be offline. A connection is required to start the distribution.';

  @override
  String get classesOrganisationDistributeLoadErrorHint =>
      'Unable to compute the headcount to distribute right now. Please try again later.';

  @override
  String get classesDistributionResultEyebrow => 'Gender distribution';

  @override
  String get classesDistributionProcessingTitle => 'Distribution in progress…';

  @override
  String get classesDistributionSuccessTitle => 'Distribution complete';

  @override
  String get classesDistributionSuccessSubtitle =>
      'Students were evenly distributed by gender.';

  @override
  String get classesDistributionRecapTitle => 'Headcount per class';

  @override
  String classesDistributionClassHeadcount(int count) {
    return '$count students';
  }

  @override
  String get classesDistributionErrorTitle => 'Distribution failed';

  @override
  String get classesDistributionErrorMessage =>
      'The classes were left intact. You can try again.';

  @override
  String get classesDistributionRetry => 'Retry';

  @override
  String get classesDistributionClose => 'Close';

  @override
  String get classesDistributionKpiHeadcount => 'Headcount';

  @override
  String get classesDistributionKpiClasses => 'Classes';

  @override
  String get classesDistributionKpiBoys => 'Boys';

  @override
  String get classesDistributionKpiGirls => 'Girls';

  @override
  String get classesDistributionViewGrid => 'Grid';

  @override
  String get classesDistributionViewList => 'List';

  @override
  String classesDistributionClassLabel(String code) {
    return 'Class $code';
  }

  @override
  String classesDistributionClassCapacity(int count, int capacity) {
    return '$count students · capacity $capacity';
  }

  @override
  String get classesDistributionCapacityFull => 'full';

  @override
  String get classesOrganisationDistributionSuccess =>
      'Distribution completed successfully.';

  @override
  String get classesOrganisationSplitInfo =>
      'Split mode enabled: classroom grid with members and stats.';

  @override
  String get classesOrganisationNonSplitInfo =>
      'Non-split mode enabled: student list for the selected level.';

  @override
  String get classesOrganisationLoadingTitle => 'Loading classes…';

  @override
  String get classesOrganisationEmptyTitle => 'No student to distribute';

  @override
  String get classesOrganisationEmptyInvite =>
      'Enroll students in this level to start the distribution.';

  @override
  String get classesOrganisationOverviewErrorTitle => 'Unable to load';

  @override
  String get classesOrganisationTransferDialogTitle => 'Transfer student';

  @override
  String get classesReassignCurrentClassState => 'Current class';

  @override
  String get classesReassignUnassignedState => 'Unassigned';

  @override
  String get classesReassignCurrentBadge => 'Current';

  @override
  String get classesReassignFullBadge => 'Full';

  @override
  String classesReassignOptionStats(int eff, int cap, int boys, int girls) {
    return '$eff/$cap · B $boys · G $girls';
  }

  @override
  String get classesOrganisationTransferAction => 'Transfer';

  @override
  String get classesOrganisationTransferInProgress => 'Transfer in progress...';

  @override
  String get classesOrganisationTransferQueued =>
      'Transfer saved — pending synchronization.';

  @override
  String get classesOrganisationTransferPendingBadge => 'Pending';

  @override
  String get classesOrganisationTransferNoTarget =>
      'No destination classroom is available.';

  @override
  String get classesOrganisationSelectCycleAndLevelTitle =>
      'Select a cycle and a level';

  @override
  String get classesOrganisationSelectCycleAndLevelSubtitle =>
      'Start by selecting a cycle, then a level to display class composition.';

  @override
  String get classesOrganisationSelectLevelTitle => 'Select a level';

  @override
  String classesOrganisationSelectLevelSubtitle(String cycleName) {
    return 'Now select a level in the $cycleName cycle.';
  }

  @override
  String get classesOrganisationPendingTitle => 'Level not distributed yet';

  @override
  String classesOrganisationPendingMessage(int count, String levelName) {
    return '$count students in $levelName aren\'\'t assigned to any class. Automatic distribution balances the classes by gender.';
  }

  @override
  String classesOrganisationPendingStudentsToDistribute(int count) {
    return '$count students to distribute';
  }

  @override
  String classesOrganisationGenderBoysPill(int count) {
    return 'B · $count';
  }

  @override
  String classesOrganisationGenderGirlsPill(int count) {
    return 'G · $count';
  }

  @override
  String get classesOrganisationUnassignedTitle => 'Unassigned students';

  @override
  String get classesOrganisationUnassignedSubtitle =>
      'New arrivals, cancelled transfers…';

  @override
  String get classesOrganisationUnassignedBadge => 'To assign';

  @override
  String get classesOrganisationNoMembers => 'No student in this classroom.';

  @override
  String get classesOrganisationAssignAction => 'Assign';

  @override
  String get classesOrganisationAssignDialogTitle => 'Assign the student';

  @override
  String get classesOrganisationAssignSuccess =>
      'Student assigned to the class.';

  @override
  String get classesOrganisationAssignRejected =>
      'Assignment refused: this student already has a class, or their enrolment is not on this level. Refresh the list.';

  @override
  String get classesOrganisationAssignNotFound =>
      'Class or enrolment not found. Refresh the list.';

  @override
  String classesOrganisationLoadingClassroomsCount(int count) {
    return 'Loading members for $count classrooms...';
  }

  @override
  String get classesOrganisationStudentDetailSoon =>
      'Student details will be available in the next batch.';

  @override
  String get classesOrganisationErrorNetwork =>
      'Check your internet connection.';

  @override
  String get classesOrganisationErrorNotFound =>
      'No data found for these criteria.';

  @override
  String get classesOrganisationErrorValidation =>
      'Some entered information is invalid.';

  @override
  String get classesOrganisationErrorUnauthorized =>
      'Access is not authorized.';

  @override
  String get classesOrganisationErrorInvalidCredentials =>
      'Invalid credentials.';

  @override
  String get classesOrganisationErrorServer => 'Server error, try again later.';

  @override
  String get classesOrganisationErrorStorage => 'Local storage error.';

  @override
  String get classesOrganisationErrorAuth =>
      'Session is not valid, please sign in again.';

  @override
  String get classesOrganisationErrorUnknown => 'An error occurred.';

  @override
  String get classesListSearchTitle => 'Search form';

  @override
  String get classesListSearchHint => '';

  @override
  String get classesListClassroomOptionalLabel => 'Classroom (optional)';

  @override
  String get classesListClassroomPlaceholder => 'Pick a level first';

  @override
  String get classesListClassroomNonePlaceholder =>
      'No classroom for this level';

  @override
  String get classesListSearchLevelPlaceholder => 'Pick a cycle';

  @override
  String get classesListLevelColumnLabel => 'Level';

  @override
  String get classesListLevelUnknown => '—';

  @override
  String get classesListInitialEmptyTitle => 'No search in progress';

  @override
  String get classesListInitialEmptyMessage =>
      'Pick a level, or fill in a student\'s full identity, to display results.';

  @override
  String get classesListNoMatchTitle => 'No student matches the criteria';

  @override
  String get classesListNoMatchMessage =>
      'Try broadening your filters or adjusting your search.';

  @override
  String classesListResultsSummary(int count, String criteria) {
    return '$count students found — $criteria';
  }

  @override
  String classesListResultsSummaryWithoutCriteria(int count) {
    return '$count students found';
  }

  @override
  String get classesListClassroomChipLabel => 'Classroom';

  @override
  String get classesListLoadingClassroomMembers =>
      'Loading classroom members...';

  @override
  String get classesListClassroomEmptyMessage =>
      'No student is currently assigned to this classroom.';

  @override
  String get classesListClassroomFilteredEmptyMessage =>
      'No student in this classroom matches the entered filters.';

  @override
  String get classesListStudentDetailSoon =>
      'Student details will be available in a future release.';

  @override
  String get classesListExportSuccess => 'Export copied to clipboard.';

  @override
  String get classesListExportFailed =>
      'Unable to prepare the export right now.';

  @override
  String get classesListExportNothingToExport =>
      'There is no data to export for this search.';

  @override
  String get classesListExportPdf => 'Export as PDF';

  @override
  String get subMenuClassesList => 'Class lists';

  @override
  String get subMenuAttendance => 'Attendance';

  @override
  String get subMenuDisciplinesList => 'Disciplines List';

  @override
  String get menuCourses => 'Courses';

  @override
  String get subMenuMyCourses => 'My courses';

  @override
  String get subMenuTimetable => 'Timetable';

  @override
  String myCoursesCount(int classCount, int courseCount) {
    String _temp0 = intl.Intl.pluralLogic(
      classCount,
      locale: localeName,
      other: '$classCount classes',
      one: '1 class',
      zero: '0 classes',
    );
    String _temp1 = intl.Intl.pluralLogic(
      courseCount,
      locale: localeName,
      other: '$courseCount courses',
      one: '1 course',
      zero: '0 courses',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String myCoursesUnsyncedClassroomNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses hidden — classroom not synchronised',
      one: '1 course hidden — classroom not synchronised',
    );
    return '$_temp0';
  }

  @override
  String get myCoursesUnsyncedClassroomName => 'Unsynced class';

  @override
  String myCoursesDegradedClassroomNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count courses shown without their class — the class sync has not completed yet',
      one:
          '1 course shown without its class — the class sync has not completed yet',
    );
    return '$_temp0';
  }

  @override
  String get myCoursesExpandAll => 'Expand all';

  @override
  String get myCoursesCollapseAll => 'Collapse all';

  @override
  String myCoursesClassCourseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '1 course',
      zero: '0 courses',
    );
    return '$_temp0';
  }

  @override
  String myCoursesStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
      zero: 'No students',
    );
    return '$_temp0';
  }

  @override
  String get myCoursesLoadingA11yLabel => 'Loading your courses';

  @override
  String get myCoursesEmptyTitle => 'No course assigned';

  @override
  String get myCoursesEmptyDescription =>
      'No course is linked to you yet. The courses you teach will appear here, grouped by class.';

  @override
  String get myCoursesErrorNetworkTitle => 'No connection';

  @override
  String get myCoursesErrorNetworkMessage =>
      'You appear to be offline. Check your internet connection, then try again.';

  @override
  String get myCoursesErrorUnauthorizedTitle => 'Session expired';

  @override
  String get myCoursesErrorUnauthorizedMessage =>
      'Your session has expired. Sign in again to view your courses.';

  @override
  String get myCoursesErrorForbiddenTitle => 'Access denied';

  @override
  String get myCoursesErrorForbiddenMessage =>
      'You do not have the required permissions to view these courses.';

  @override
  String get myCoursesErrorServerTitle => 'Server error';

  @override
  String get myCoursesErrorServerMessage =>
      'Something went wrong on our side. Please try again in a moment.';

  @override
  String get myCoursesErrorUnknownTitle => 'Unable to load';

  @override
  String get myCoursesErrorUnknownMessage =>
      'An unexpected error occurred while loading your courses.';

  @override
  String get myCoursesErrorRetry => 'Try again';

  @override
  String get myCoursesErrorReconnect => 'Sign in again';

  @override
  String get myCoursesErrorContactAdmin => 'Contact the administrator';

  @override
  String myCoursesErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get courseDetailBackToCourses => 'My courses';

  @override
  String courseDetailEvaluationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count evaluations',
      one: '1 evaluation',
      zero: 'No evaluation',
    );
    return '$_temp0';
  }

  @override
  String courseDetailToGrade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to grade',
      one: '1 to grade',
      zero: '0 to grade',
    );
    return '$_temp0';
  }

  @override
  String get courseDetailNextEvalEyebrow => 'Next evaluation';

  @override
  String courseDetailEvalMetaShort(String date, String max) {
    return '$date · /$max pts';
  }

  @override
  String courseDetailEvalMeta(String date, String max, int poids) {
    return '$date · /$max pts · weight $poids';
  }

  @override
  String courseDetailSemesterLabel(int ordre) {
    return 'Semester $ordre';
  }

  @override
  String courseDetailTrimesterLabel(int ordre) {
    return 'Term $ordre';
  }

  @override
  String courseDetailPeriodLabel(int ordre) {
    return 'Period $ordre';
  }

  @override
  String get courseDetailExamLabel => 'Exam';

  @override
  String get courseDetailStatutClosed => 'Closed';

  @override
  String get courseDetailStatutCurrent => 'In progress';

  @override
  String get courseDetailStatutUpcoming => 'Upcoming';

  @override
  String courseDetailBucketNotes(int saisies, int total, int evals) {
    String _temp0 = intl.Intl.pluralLogic(
      evals,
      locale: localeName,
      other: '$evals evals.',
      one: '1 eval.',
      zero: '0 eval.',
    );
    return '$saisies/$total marks · $_temp0';
  }

  @override
  String get courseDetailBucketNoEval => 'No evaluation';

  @override
  String get courseDetailExamToPlan => 'To be scheduled';

  @override
  String courseDetailNoteGlobaleTitle(String label) {
    return 'Overall mark — $label';
  }

  @override
  String get courseDetailProvisional => 'provisional';

  @override
  String get courseDetailClassAverageLabel => 'Class average';

  @override
  String courseDetailAbove50(int count, int total) {
    return '$count/$total students ≥ 50%';
  }

  @override
  String get courseDetailNoAverage => 'No average yet';

  @override
  String get courseDetailByStudent => 'By student';

  @override
  String get courseDetailBadgeGraded => 'Graded';

  @override
  String courseDetailBadgeInProgress(int saisies, int total) {
    return 'In progress · $saisies/$total';
  }

  @override
  String get courseDetailBadgeUpcoming => 'Upcoming';

  @override
  String courseDetailEvalExpected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students expected',
      one: '1 student expected',
      zero: '0 students expected',
    );
    return '$_temp0';
  }

  @override
  String courseDetailReleveTitle(String label) {
    return 'Overall marks — $label';
  }

  @override
  String get courseDetailReleveKpiAverage => 'Average';

  @override
  String get courseDetailReleveKpiAbove50 => '≥ 50%';

  @override
  String get courseDetailReleveKpiEvals => 'Evals';

  @override
  String get courseDetailSortRanking => 'Ranking';

  @override
  String get courseDetailSortAlpha => 'Alphabetical';

  @override
  String get courseDetailReleveMethod =>
      'Overall mark = points earned ÷ maximum, weighted by coefficient.';

  @override
  String get courseDetailReleveEmpty => 'No marks entered';

  @override
  String get courseDetailLoadingA11yLabel => 'Loading course';

  @override
  String get courseDetailEmptyTitle => 'No evaluation';

  @override
  String get courseDetailEmptyDescription =>
      'This course has no evaluation yet.';

  @override
  String get courseDetailBucketEmptyUpcoming =>
      'Upcoming selection — no evaluation scheduled yet.';

  @override
  String get courseDetailBucketEmptyNone =>
      'No evaluation attached to this selection.';

  @override
  String get courseDetailErrorNetworkMessage =>
      'You appear to be offline. Check your connection, then try again.';

  @override
  String get courseDetailErrorUnauthorizedMessage =>
      'Your session has expired. Sign in again to view this course.';

  @override
  String get courseDetailErrorForbiddenMessage =>
      'You do not have the required permissions to view this course.';

  @override
  String get courseDetailErrorServerMessage =>
      'Something went wrong on our side. Try again in a moment.';

  @override
  String get courseDetailErrorUnknownMessage =>
      'An unexpected error occurred while loading the course.';

  @override
  String get courseDetailErrorNotFoundTitle => 'Course not found';

  @override
  String get courseDetailErrorNotFoundMessage =>
      'This course no longer exists or is not accessible.';

  @override
  String get evalTypeInterro => 'Quiz';

  @override
  String get evalTypeDevoir => 'Assignment';

  @override
  String get evalTypeExamen => 'Exam';

  @override
  String get evalCreateTitle => 'New evaluation';

  @override
  String get evalCreateFieldSemestre => 'Semester';

  @override
  String get evalCreateFieldTrimestre => 'Term';

  @override
  String get evalCreateFieldSousPeriode => 'Period';

  @override
  String get evalCreateExamPlaceholder => 'Term exam';

  @override
  String get evalCreateFieldDate => 'Date';

  @override
  String get evalCreateFieldDateHint => 'dd/mm/yyyy';

  @override
  String get evalCreateFieldMax => 'Maximum';

  @override
  String get evalCreateFieldPoids => 'Weight';

  @override
  String get evalCreateFieldChapitres => 'Related chapters';

  @override
  String get evalCreateChapitresEmpty =>
      'No chapters available for this course';

  @override
  String get evalCreateCancel => 'Cancel';

  @override
  String get evalCreateSubmit => 'Create evaluation';

  @override
  String evalCreateHint(int count, String classroom) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count students in $classroom will be added',
      one: 'The student in $classroom will be added',
      zero: 'No student in $classroom will be added',
    );
    return '$_temp0 with the “Pending” status.';
  }

  @override
  String get evalCreateSuccessToast => 'Evaluation created';

  @override
  String get evalCreateErrorToast =>
      'Creating the evaluation failed. Please try again.';

  @override
  String get evalCreateClosedPeriodError =>
      'Closed period: you can\'t add an evaluation to it.';

  @override
  String get evalCreateMaxReachedError => 'Entry cap reached for this date.';

  @override
  String get evalRejectionPeriodClosed => 'Rejected: closed period';

  @override
  String get evalRejectionExamNotAllowed => 'Rejected: exam not allowed';

  @override
  String get evalRejectionMaxReached => 'Rejected: cap reached';

  @override
  String get evalRejectionGeneric => 'Rejected by the server';

  @override
  String get noteRejectionUnknownEvaluation =>
      'Evaluation unknown to the server';

  @override
  String get noteRejectionPeriodeClose => 'Closed period';

  @override
  String get noteRejectionInvalid => 'Invalid grade';

  @override
  String get noteRejectionContextUnavailable => 'Context unavailable';

  @override
  String get noteRejectionGeneric => 'Rejected by the server';

  @override
  String get evalDetailBack => 'Back to course';

  @override
  String get evalBadgeComplete => 'Closed';

  @override
  String evalBadgePartial(int done, int total) {
    return 'Grading · $done/$total';
  }

  @override
  String get evalBadgeUpcoming => 'Upcoming';

  @override
  String evalChipMax(String max) {
    return 'Maximum: $max pts';
  }

  @override
  String evalChipPoids(int poids) {
    return 'Weight: $poids';
  }

  @override
  String get evalModeTable => 'Table';

  @override
  String get evalModeFocus => 'Focus';

  @override
  String evalCountNotee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count graded',
      one: '$count graded',
      zero: '$count graded',
    );
    return '$_temp0';
  }

  @override
  String evalCountEnAttente(int count) {
    return '$count pending';
  }

  @override
  String evalCountAbsJust(int count) {
    return '$count exc. abs.';
  }

  @override
  String evalCountAbsNonJust(int count) {
    return '$count unexc. abs.';
  }

  @override
  String get evalStatutNotee => 'Graded';

  @override
  String get evalStatutEnAttente => 'Pending';

  @override
  String get evalStatutAbsJust => 'Exc. abs.';

  @override
  String get evalStatutAbsNonJust => 'Unexc. abs.';

  @override
  String evalNoteMaxError(String max) {
    return 'max $max';
  }

  @override
  String get evalAbsenceJustifieTooltip => 'Excused absence';

  @override
  String get evalAbsenceNonJustifieTooltip => 'Unexcused absence';

  @override
  String get evalFocusClear => 'Clear · pending';

  @override
  String get evalFocusPrevious => 'Previous';

  @override
  String get evalFocusNext => 'Next';

  @override
  String get evalFocusLast => 'Last student';

  @override
  String evalFocusPosition(int index, int total) {
    return 'Student $index / $total';
  }

  @override
  String evalSaveCounter(int done, int total) {
    return '$done / $total entered';
  }

  @override
  String evalSaveErrorsAlert(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grades above the maximum',
      one: '1 grade above the maximum',
      zero: '0 grades above the maximum',
    );
    return '$_temp0';
  }

  @override
  String get evalSaveButton => 'Save grades';

  @override
  String get evalSaveButtonSaving => 'Saving…';

  @override
  String evalSaveSuccessToast(int notees, int enAttente) {
    String _temp0 = intl.Intl.pluralLogic(
      notees,
      locale: localeName,
      other: '$notees graded',
      one: '$notees graded',
      zero: '$notees graded',
    );
    return 'Grades saved — $_temp0 · $enAttente pending';
  }

  @override
  String get evalSaveErrorToast => 'Saving failed. Your entries are kept.';

  @override
  String get evalSaisieEmptyTitle => 'No students';

  @override
  String get evalSaisieEmptyDescription =>
      'No students are enrolled in this class.';

  @override
  String get evalSaisieLoadingA11y => 'Loading grade entry';

  @override
  String get evalSaisieErrorNetworkMessage =>
      'You appear to be offline. Check your connection, then try again.';

  @override
  String get evalSaisieErrorUnauthorizedMessage =>
      'Your session has expired. Sign in again to enter grades.';

  @override
  String get evalSaisieErrorForbiddenMessage =>
      'You don\'t have the required permissions to enter these grades.';

  @override
  String get evalSaisieErrorServerMessage =>
      'Something went wrong on our side. Try again in a moment.';

  @override
  String get evalSaisieErrorUnknownMessage =>
      'An unexpected error occurred while loading grade entry.';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String accueilBannerGreeting(String firstName) {
    return 'Hello, $firstName';
  }

  @override
  String get accueilBannerGreetingGeneric => 'Hello';

  @override
  String accueilBannerSchoolLocation(String school, String locality) {
    return '$school · $locality';
  }

  @override
  String accueilBannerSchoolYear(String year) {
    return 'School year $year';
  }

  @override
  String get accueilModulesEyebrow => 'Your modules';

  @override
  String get accueilModulesTitle => 'Where would you like to go?';

  @override
  String get accueilModulesIntro =>
      'These modules cover the life of the school — each card opens its dashboard or its pages.';

  @override
  String get accueilModuleInscriptionsDescription =>
      'New enrolments, re-enrolments and pre-enrolments for your students.';

  @override
  String get accueilModuleFinancesDescription =>
      'Revenue, invoicing and tracking of school fee collection.';

  @override
  String get accueilModuleBoutiqueDescription =>
      'Cash sales of school items, and the counter\'s collection history.';

  @override
  String get accueilModuleClassesDescription =>
      'Class composition and student lists by cycle.';

  @override
  String get accueilModuleCoursDescription =>
      'Weekly timetable and follow-up of your courses.';

  @override
  String get accueilModuleResultatsDescription =>
      'Percentages by period, for a whole class or a single student.';

  @override
  String get accueilModuleDisciplinesDescription =>
      'Daily attendance, disciplinary records and student follow-up.';

  @override
  String get accueilModuleConfigurationDescription =>
      'School identity, cycles and levels, and the school fee schedule.';

  @override
  String accueilModulePageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String accueilModuleCardSemantics(String module, String page) {
    return '$module — open $page';
  }

  @override
  String accueilSubModuleSemantics(String module, String page) {
    return '$page — $module module';
  }

  @override
  String get accueilSignature => 'eteyelo · l\'école en lingala';

  @override
  String get homeTopBarPendingSubtitle => 'Pending files follow-up';

  @override
  String get homeTopBarNotificationsTooltip => 'Notifications';

  @override
  String get homeUserMenuTooltip => 'User menu';

  @override
  String get homeSidebarCollapseTooltip => 'Collapse menu';

  @override
  String get homeSidebarExpandTooltip => 'Expand menu';

  @override
  String get homeOpenNavigationDrawerTooltip => 'Open menu';

  @override
  String get homeSidebarFooterLabel => 'School dashboard';

  @override
  String get homeSidebarNavigationLabel => 'Main navigation';

  @override
  String get pageUnderConstruction => 'This page is under development';

  @override
  String get preRegistrations => 'Pre-Registrations';

  @override
  String get searchStudents => 'Search Students';

  @override
  String get searchFormSubtitleFirstRegistration =>
      'Filter the enrollments list';

  @override
  String get reRegistrationSearchHint =>
      'Find a student or a class from the previous year to re-enroll';

  @override
  String get reRegistrationSearchTitle => 'Search a student';

  @override
  String get reRegistrationSearchLevelPlaceholder => 'Choose a cycle first';

  @override
  String get reRegistrationAcademicInfoHelp =>
      'Select the target cycle and level to filter results.';

  @override
  String get reRegistrationSearchNoOptions =>
      'No cycle/level is available for this search.';

  @override
  String get reRegistrationSearchNeedCriteria =>
      'Provide either First name, Last name and Surname, or Cycle/Level.';

  @override
  String get reRegistrationSearchReady =>
      'Valid criteria, you can run the search.';

  @override
  String get reRegistrationSearchInvitationTitle =>
      'Start a re-registration search';

  @override
  String get reRegistrationSearchInvitationMessage =>
      'Fill the form above then click Search to display enrollment files.';

  @override
  String get preRegistrationSearchHint =>
      'Find a pre-registration by student or by desired cycle/level';

  @override
  String get preRegistrationSearchTitle => 'Search a pre-registration';

  @override
  String get preRegistrationSearchLevelPlaceholder => 'Choose a cycle first';

  @override
  String get preRegistrationSearchInvitationTitle =>
      'Start a pre-registration search';

  @override
  String get preRegistrationSearchInvitationMessage =>
      'Fill the form above then click Search to display requests.';

  @override
  String get firstRegistrationSearchLevelPlaceholder => 'Choose a cycle';

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
  String get searchModeSwitchLabel => 'Search by';

  @override
  String get searchModeSemantics => 'Search mode';

  @override
  String get searchModeByClass => 'By class';

  @override
  String get searchModeByIdentity => 'By identity';

  @override
  String get searchModeClassHint =>
      'Pick a cycle then a level to list the whole class; a name, even partial, narrows that list. To find a student without knowing their class, switch to “By identity”.';

  @override
  String get searchModeIdentityHint =>
      'One name is enough: last name, middle name or first name. To list a whole class, switch to “By class”.';

  @override
  String get searchRefineByNameLabel => 'Refine by last name (optional)';

  @override
  String get searchRefineByNamePlaceholder =>
      'Student\'s last name, even partial';

  @override
  String get viewDetails => 'View details';

  @override
  String get editEnrollment => 'Edit';

  @override
  String get exportData => 'Export';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get enrollmentNoResultsDescription =>
      'No student matches your search criteria.';

  @override
  String get enrollmentEmptyTitle => 'No results';

  @override
  String get enrollmentEmptyDescription =>
      'No enrollment matches these criteria. Adjust your search, or create the record if the student is not yet registered.';

  @override
  String get enrollmentEmptyWithoutFilterDescription => 'No enrollment yet.';

  @override
  String get enrollmentEmptyCreateAction => 'Enroll a new student';

  @override
  String get enrollmentErrorRetry => 'Retry';

  @override
  String get enrollmentErrorReconnect => 'Sign in again';

  @override
  String get enrollmentErrorContactAdmin => 'Contact administrator';

  @override
  String get enrollmentErrorNetworkTitle => 'No connection';

  @override
  String get enrollmentErrorNetworkMessage =>
      'You appear to be offline. Check your internet connection, then retry.';

  @override
  String get enrollmentErrorUnauthorizedTitle => 'Session expired';

  @override
  String get enrollmentErrorUnauthorizedMessage =>
      'Your session expired. Sign in again to continue.';

  @override
  String get enrollmentErrorForbiddenTitle => 'Access denied';

  @override
  String get enrollmentErrorForbiddenMessage =>
      'You do not have the required permissions to view this list.';

  @override
  String get enrollmentErrorServerTitle => 'Server error';

  @override
  String get enrollmentErrorServerMessage =>
      'An error occurred on our side. Please try again in a moment.';

  @override
  String enrollmentErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get enrollmentErrorUnknownTitle => 'Unable to load';

  @override
  String get enrollmentErrorUnknownMessage =>
      'An unexpected error occurred while loading results.';

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
  String paginationPageIndicator(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String paginationResultsCount(int count) {
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
  String paginationRange(int start, int end, int total, String unit) {
    return '$start–$end of $total $unit';
  }

  @override
  String get paginationNavigationLabel => 'Pagination';

  @override
  String get unitStudents => 'students';

  @override
  String enrollmentResultCardOpenLabel(String name, String status) {
    return 'Open $name\'s record, status $status';
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
  String get firstRegistrationNewEnrollmentAction => 'New enrollment';

  @override
  String get enrollmentDetailLoadingTitle => 'Loading enrollment file';

  @override
  String get enrollmentDetailLoadingMessage =>
      'Please wait while enrollment details are being loaded.';

  @override
  String get enrollmentDetailLoadErrorTitle => 'Unable to load enrollment file';

  @override
  String get enrollmentDetailRetryAction => 'Retry';

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
  String get guardianMarkAsPrimary => 'Set as primary guardian';

  @override
  String get guardianPrimaryRequiredHint =>
      'At least one primary guardian is required';

  @override
  String get guardianPrincipalBadge => 'Primary';

  @override
  String get guardianToggleCard => 'Open or close guardian card';

  @override
  String get guardianIncompleteHint => 'Incomplete profile';

  @override
  String get guardianEmailOptionalInline => '(optional)';

  @override
  String get guardianDeleteAction => 'Remove this guardian';

  @override
  String get guardianDeleteConfirmTitle => 'Confirm removal';

  @override
  String get guardianDeleteConfirmMessage =>
      'Do you really want to remove this guardian? This action cannot be undone.';

  @override
  String get guardianDeleteConfirmAction => 'Remove';

  @override
  String get guardianUnlinkSuccess => 'Guardian removed successfully.';

  @override
  String guardianUnlinkError(String message) {
    return 'Failed to remove guardian: $message';
  }

  @override
  String get guardianSearchDialogTitle => 'Search for an existing parent';

  @override
  String get guardianSearchDialogEyebrow => 'Guardians';

  @override
  String get guardianSearchModeSemantics => 'Search mode';

  @override
  String get guardianSearchModeByPhone => 'By number';

  @override
  String get guardianSearchModeByIdentity => 'By identity';

  @override
  String get guardianSearchPhoneHint =>
      'The number is enough, even partial: \"8169\" brings up every matching guardian.';

  @override
  String get guardianSearchIdentityHint =>
      'Last name and first name are required. The middle name narrows the search when known.';

  @override
  String get guardianSearchResultsPlaceholder =>
      'Matching guardians will appear here.';

  @override
  String get guardianSearchEmptyTitle => 'No guardian found';

  @override
  String get guardianSearchEmptyDescription =>
      'No guardian matches these criteria. Check your input or add them as a new guardian.';

  @override
  String get guardianSearchAlreadyAddedError =>
      'This guardian has already been added to this enrollment.';

  @override
  String get guardianSearchIdentityLockedHint =>
      'Details from an existing record — not editable here.';

  @override
  String get guardianSearchErrorRetry => 'Retry';

  @override
  String get guardianLinkExistingBannerTitle =>
      'Is this guardian already on file?';

  @override
  String get guardianLinkExistingBannerDescription =>
      'Find their record instead of typing it again: it will replace what this card holds.';

  @override
  String get guardianLinkExistingAction => 'Search for a record';

  @override
  String get guardianPhoneConflictDialogEyebrow => 'Guardians';

  @override
  String get guardianPhoneConflictDialogTitle =>
      'This number is already in use';

  @override
  String guardianPhoneConflictDialogMessage(String phoneNumber) {
    return '$phoneNumber already belongs to an existing record. Link it to the student, or correct the number you entered.';
  }

  @override
  String get guardianPhoneConflictUseAction => 'Use this record';

  @override
  String get guardianPhoneConflictFixPhoneAction => 'Correct the number';

  @override
  String get guardianPhoneConflictNotFoundTitle => 'Record not found';

  @override
  String get guardianPhoneConflictNotFoundDescription =>
      'No record carrying this number could be found. Correct the number you entered.';

  @override
  String get guardianPhoneDuplicateInFormError =>
      'This number is already entered for another guardian in this file.';

  @override
  String get guardianLinkTargetGoneError =>
      'This guardian is no longer in the file: the record was not linked.';

  @override
  String get schoolFees => 'School Fees';

  @override
  String get summary => 'Summary';

  @override
  String get summaryYes => 'Yes';

  @override
  String get summaryNo => 'No';

  @override
  String get summaryChargesTotalDue => 'Total due';

  @override
  String get summaryChargesUnavailable => 'Amounts are unavailable for now.';

  @override
  String get summaryValidationNoticeTitle => 'Before validation';

  @override
  String get summaryValidationNoticeBody =>
      'You certify that the information is accurate. The file will move to validated status and a receipt can be generated.';

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
  String get firstNameExample => 'Claudine';

  @override
  String get lastNameExample => 'Furah';

  @override
  String get surnameExample => 'Sifiwe';

  @override
  String get selectPlaceholderChoose => 'Choose';

  @override
  String get requiredSemanticSuffix => 'required';

  @override
  String get selectSearchPlaceholder => 'Search…';

  @override
  String get selectSearchClear => 'Clear search';

  @override
  String get selectNoOptionMatches => 'No option matches';

  @override
  String get selectNoOptionAvailable => 'No option available';

  @override
  String get selectOpenPanelSemantic => 'Open the option list';

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
  String get addressComplementaryHelp =>
      'Add street, avenue and number when needed.';

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
  String get yearValidatedHelp =>
      'Indicates whether the student validated the previous school year.';

  @override
  String get yearNotValidated => 'Not validated';

  @override
  String get yearValidationUnknown => 'Not specified';

  @override
  String get guardianEmergencyContactLabel => 'Emergency contact';

  @override
  String get guardianEmergencyContactBadge => 'Emergency';

  @override
  String get guardianEmergencyContactHint =>
      'One guardian per pupil: designating one clears the previous designation.';

  @override
  String get guardianEmergencyContactAmbiguous =>
      'Only one guardian can be the emergency contact for this pupil.';

  @override
  String get guardianEmergencyContactSaved => 'Emergency contact updated.';

  @override
  String get guardianEmergencyContactCleared => 'Emergency contact cleared.';

  @override
  String get guardianEmergencyContactRetry => 'Retry';

  @override
  String get guardianEmergencyContactFailed =>
      'Setting the emergency contact failed.';

  @override
  String get medicalNotesLabel => 'Health information';

  @override
  String get medicalNotesHelp =>
      'Allergies, ongoing treatment, what to do. Optional.';

  @override
  String get medicalNotesSectionTitle => 'Health';

  @override
  String get formerStudentLabel => 'Former pupil of this school';

  @override
  String get formerStudentHelp =>
      'Tick if the child has already been enrolled in this school, even before the app.';

  @override
  String get formerStudentLockedHelp =>
      'Re-enrolment: the child comes from last year\'s file in this school.';

  @override
  String get previousSchoolOptionalHint =>
      'Optional — leave blank if the child has not been to school yet.';

  @override
  String get averageOutOfRangeError => 'The average must be between 0 and 100.';

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
  String get targetLevelAutoBadge => 'Auto';

  @override
  String get targetLevelAutoBadgeHelp =>
      'Class automatically computed from last year\'s class. Change the cycle or level to override it.';

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
  String get phoneNumberCountryCodeLabel => 'Country dialling code';

  @override
  String phoneNumberInvalidError(int expectedDigits) {
    return 'Invalid phone number ($expectedDigits digits expected after the dialling code).';
  }

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
  String get stepAddressTitle => 'Student\'s address';

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
  String get wizardStepShortPersonal => 'Identity';

  @override
  String get wizardStepShortAddress => 'Address';

  @override
  String get wizardStepShortPrevious => 'Prev. year';

  @override
  String get wizardStepShortTarget => 'Target year';

  @override
  String get wizardStepShortCharges => 'Fees';

  @override
  String get wizardStepShortGuardian => 'Guardians';

  @override
  String get wizardStepShortSummary => 'Summary';

  @override
  String stepIndicator(int current, int total) {
    return 'Step $current / $total';
  }

  @override
  String wizardStepNumberShort(int number) {
    return 'Step $number';
  }

  @override
  String get stepForwardHint => 'Click Continue to advance step by step.';

  @override
  String get journeyModeNew => 'New';

  @override
  String get journeyModeEdit => 'Edit';

  @override
  String get journeyModeView => 'View';

  @override
  String get journeyCloseAction => 'Close';

  @override
  String get wizardExitConfirmTitle => 'Leave the enrollment?';

  @override
  String get wizardExitConfirmMessage =>
      'An enrollment is in progress. Unsaved changes on the current step will be lost; steps already saved remain available as a draft.';

  @override
  String get wizardExitConfirmAction => 'Leave';

  @override
  String get wizardExitStayAction => 'Keep editing';

  @override
  String get enrollmentFinalizeConfirmTitle => 'Validate the enrollment?';

  @override
  String get enrollmentFinalizeConfirmMessage =>
      'This action confirms the file and queues it for synchronization. Review the summary before validating.';

  @override
  String get enrollmentFinalizeProcessingTitle => 'Validating enrollment…';

  @override
  String get enrollmentFinalizeSuccessTitle => 'Enrollment validated';

  @override
  String get enrollmentFinalizeErrorTitle => 'Validation failed';

  @override
  String get enrollmentFinalizeRetryAction => 'Retry';

  @override
  String get enrollmentFinalizeCloseAction => 'Close';

  @override
  String get enrollmentFinalizeContinueAction => 'Continue';

  @override
  String get stepSaveStateIdle => 'No input yet';

  @override
  String get stepSaveStateIncomplete => 'Incomplete fields';

  @override
  String get stepSaveStatePending => 'Unsaved changes';

  @override
  String get stepSaveStateSaving => 'Saving...';

  @override
  String get stepSaveStateSaved => 'Step saved';

  @override
  String get validatePersonalInfoHint =>
      'Please complete the personal information.';

  @override
  String get validateAddressHint => 'Please complete the student\'s address.';

  @override
  String get validateAcademicInfoHint =>
      'Please complete the academic information.';

  @override
  String get validateGuardianInfoHint =>
      'Please check the guardian information.';

  @override
  String get enrollmentReadyForValidation => 'File ready for final validation.';

  @override
  String get completedEnrollmentRedirecting =>
      'This enrollment is already completed. Redirecting to First Registration.';

  @override
  String get validateEnrollment => 'Validate enrollment';

  @override
  String get validatingEnrollment => 'Validating...';

  @override
  String get goToFirstRegistration => 'Go to First Registration';

  @override
  String get personalInfoSaveHintBeforeContinue =>
      'Please save your changes before continuing.';

  @override
  String get personalInfoValidationReasonsTitle =>
      'Please correct the following fields:';

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
  String get personalInfoSaveSuccess =>
      'Personal information updated successfully.';

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
  String get academicInfoValidationReasonsTitle =>
      'Please correct the following academic fields:';

  @override
  String get academicInfoSaveHintBeforeContinue =>
      'Please save academic changes before continuing.';

  @override
  String get academicInfoSaveSuccess =>
      'Academic information updated successfully.';

  @override
  String academicInfoSaveError(String message) {
    return 'Academic info update failed: $message';
  }

  @override
  String get addressValidationReasonsTitle =>
      'Please correct the following address fields:';

  @override
  String get addressNoCityAvailable => 'No city is available in the catalog.';

  @override
  String get addressSelectCityFirst => 'Select a city first.';

  @override
  String get addressNoDistrictAvailable =>
      'No district is available for this city.';

  @override
  String get addressSelectDistrictFirst => 'Select a district first.';

  @override
  String get addressNoMunicipalityAvailable =>
      'No municipality is available for this district.';

  @override
  String get addressSelectMunicipalityFirst => 'Select a municipality first.';

  @override
  String get addressNoNeighborhoodAvailable =>
      'No neighborhood is available for this municipality.';

  @override
  String get addressSaveHintBeforeContinue =>
      'Please save address changes before continuing.';

  @override
  String get addressSaveSuccess => 'Address updated successfully.';

  @override
  String addressSaveError(String message) {
    return 'Address update failed: $message';
  }

  @override
  String get enrollmentStudentColumnLabel => 'Student';

  @override
  String get enrollmentStatusFilterLabel => 'Status';

  @override
  String get enrollmentStatusFilterAll => 'All statuses';

  @override
  String get enrollmentStatusInProgress => 'In Progress';

  @override
  String get enrollmentDraftBadge => 'Draft';

  @override
  String get enrollmentTypeReEnrollment => 'Re-enrollment';

  @override
  String get enrollmentReenrollmentCandidateBadge => 'To re-enroll';

  @override
  String get enrollmentReRegisteredBadge => 'Re-enrolled';

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
  String get enrollmentReadOnlyMessage =>
      'Student already enrolled — record can be viewed but not edited. Browse the steps to review the information.';

  @override
  String get enrollmentReeditAction => 'Edit';

  @override
  String get enrollmentReeditReadOnlyMessage =>
      'Completed record. You may correct it: saving will move it back to in progress and queue it for sending.';

  @override
  String get enrollmentReeditExitTitle => 'Correction not validated';

  @override
  String get enrollmentReeditExitMessage =>
      'This record is being corrected and has not been validated. Until it is, the pupil no longer appears in billing.';

  @override
  String get enrollmentReeditExitConfirm => 'Leave anyway';

  @override
  String get enrollmentReeditExitResume => 'Resume correction';

  @override
  String get enrollmentEditableTitle => 'Edit mode';

  @override
  String get enrollmentEditableMessage =>
      'This enrollment is in progress (IN_PROGRESS). Information can be updated.';

  @override
  String get studentChargesStepTitle => 'Student charges';

  @override
  String get studentChargesStepSubtitle =>
      'Financial charges applied to the student';

  @override
  String get studentChargesLoading => 'Loading student charges...';

  @override
  String get studentChargesRetry => 'Retry';

  @override
  String get studentChargesEmpty =>
      'No charges are available for this student.';

  @override
  String get studentChargesFeeGridUnavailable =>
      'The fee grid is not available on this device for this year. Synchronise before continuing.';

  @override
  String get studentChargesTariffsWithheld =>
      'Fees cannot be computed: your account has no access to the fee grid. Ask an authorised account to synchronise this device.';

  @override
  String get studentChargesUnavailable =>
      'Student charges cannot be loaded without a student or target level.';

  @override
  String get studentChargesAmountColumn => 'Amount';

  @override
  String get studentChargesLabelColumn => 'Charge label';

  @override
  String get studentChargesActionsColumn => 'Actions';

  @override
  String get studentChargesAmountPaidLabel => 'Paid amount';

  @override
  String get studentChargesSaveAction => 'Save charges';

  @override
  String get studentChargesSavingAction => 'Saving charges...';

  @override
  String get studentChargesSaveSuccess => 'Charges saved successfully.';

  @override
  String get studentChargesSaveHintBeforeContinue =>
      'Please save charge changes before continuing.';

  @override
  String get enrollmentReductionsSectionTitle => 'Reductions';

  @override
  String get studentChargesTotalLabel => 'Total';

  @override
  String get studentChargesHelperText =>
      'Amounts can be updated later from the student\'s profile.';

  @override
  String get studentChargesNetworkError =>
      'Unable to load charges. Please check your internet connection.';

  @override
  String get studentChargesNotFound =>
      'No charges were found for this student.';

  @override
  String get studentChargesValidationError =>
      'The requested charge data is invalid.';

  @override
  String get studentChargesUnauthorizedError =>
      'You are not allowed to access these charges.';

  @override
  String get studentChargesInvalidCredentialsError =>
      'Your credentials do not allow access to these charges.';

  @override
  String get studentChargesServerError =>
      'The server is currently unavailable.';

  @override
  String get studentChargesStorageError =>
      'A local error prevents charges from being displayed.';

  @override
  String get studentChargesAuthError =>
      'An authentication error prevents charges from loading.';

  @override
  String get studentChargesUnknownError =>
      'An unexpected error occurred while loading charges.';

  @override
  String get studentChargeStatusDue => 'To settle';

  @override
  String get studentChargeStatusPartial => 'Partial';

  @override
  String get studentChargeStatusPaid => 'Paid';

  @override
  String get studentChargeFeeCodeTuition => 'Tuition';

  @override
  String get studentChargeFeeCodeRegistration => 'Registration';

  @override
  String get studentChargeFeeCodeEnrollment => 'Enrollment';

  @override
  String get studentChargeFeeCodeApplication => 'Application';

  @override
  String get studentChargeFeeCodeAdmission => 'Admission';

  @override
  String get studentChargeFeeCodeCanteen => 'Canteen';

  @override
  String get studentChargeFeeCodeTransport => 'Transport';

  @override
  String get studentChargeFeeCodeBoarding => 'Boarding';

  @override
  String get studentChargeFeeCodeBooks => 'Books & Materials';

  @override
  String get studentChargeFeeCodeUniform => 'Uniform';

  @override
  String get studentChargeFeeCodeExamination => 'Examination';

  @override
  String get studentChargeFeeCodeLabFee => 'Laboratory Fee';

  @override
  String get studentChargeFeeCodeActivity => 'Activity Fee';

  @override
  String get studentChargeFeeCodeSports => 'Sports Fee';

  @override
  String get studentChargeFeeCodeLibrary => 'Library Fee';

  @override
  String get studentChargeFeeCodeTechnology => 'Technology / IT Fee';

  @override
  String get studentChargeFeeCodeDevelopment =>
      'Development / Infrastructure Fee';

  @override
  String get studentChargeFeeCodeInsurance => 'Insurance';

  @override
  String get studentChargeFeeCodeSecurityDeposit => 'Security Deposit';

  @override
  String get studentChargeFeeCodeProcessingFee => 'Processing Fee';

  @override
  String get studentChargeFeeCodeLatePaymentFee => 'Late Payment Fee';

  @override
  String get studentChargeFeeCodeRefund => 'Refund';

  @override
  String get studentChargeFeeCodeOther => 'Other';

  @override
  String studentChargeDueAtLabel(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Due: $dateString';
  }

  @override
  String chargeDesignationWithTariffCode(String label, String code) {
    return '$label ($code)';
  }

  @override
  String get studentChargeFeeCodeFallback => 'School fee';

  @override
  String get facturationSearchTitle => 'Search Students';

  @override
  String get facturationSearchHint =>
      'Enter First name, Last name, Surname and/or Cycle/Level to filter results.';

  @override
  String get facturationSearchInvitationTitle => 'No search in progress';

  @override
  String get facturationSearchInvitationMessage =>
      'Enter a name or level above to display matching students.';

  @override
  String get facturationViewChargesLabel => 'View charges';

  @override
  String get facturationActionsColumnLabel => 'Actions';

  @override
  String get facturationNoResultsDescription =>
      'No student matches these criteria. Update the form and try again.';

  @override
  String get facturationEmptyEnrollmentWithheld =>
      'The student list belongs to the Enrolment module, which this profile cannot access: no student can be shown here, whatever the criteria. Your administrator can grant that access.';

  @override
  String get facturationEmptyTitle => 'No student found';

  @override
  String get facturationSearchHelpBanner =>
      'Search a whole class (cycle + level), or one specific student (one name is enough).';

  @override
  String get facturationSearchCycleLabel => 'Cycle';

  @override
  String get facturationSearchLevelLabel => 'Level';

  @override
  String get facturationSearchLevelPlaceholder => 'Pick a cycle first';

  @override
  String get feeControlSearchTitle => 'Control a fee';

  @override
  String get feeControlSearchHelpBanner =>
      'Pick the class, then the fee to control. The payment status applies to that fee only.';

  @override
  String get feeControlSearchClassGroupTitle => 'Class and fee';

  @override
  String get feeControlSearchStudentGroupTitle => 'Narrow by student';

  @override
  String get feeControlSearchStudentGroupHint => 'Optional';

  @override
  String get feeControlSearchCycleLabel => 'Cycle';

  @override
  String get feeControlSearchLevelLabel => 'Level';

  @override
  String get feeControlSearchLevelPlaceholder => 'Pick a cycle first';

  @override
  String get feeControlClassroomLabel => 'Class';

  @override
  String get feeControlClassroomPlaceholder => 'Pick a level first';

  @override
  String get feeControlClassroomAll => 'All classes of the level';

  @override
  String get feeControlClassroomEmptyForLevel =>
      'No class has been composed for this level: the control covers the whole level.';

  @override
  String get feeControlClassroomWithheld =>
      'Classes belong to a module this profile cannot access: the control covers the whole level.';

  @override
  String get feeControlFeeLabel => 'Fee';

  @override
  String get feeControlFeePlaceholder => 'Pick a level first';

  @override
  String get feeControlFeeEmptyForLevel => 'No fee is defined for this level.';

  @override
  String get feeControlFeeGridMissing =>
      'The fee schedule has not reached this device yet. Sync to control a fee.';

  @override
  String get feeControlFeeGridWithheld =>
      'The fee schedule belongs to a module this profile cannot access: it will not reach this device, however often you sync. Your administrator can grant that access.';

  @override
  String get feeControlFeeLoadFailed =>
      'The fees for this level could not be read on this device. Try again; if it keeps failing, close and reopen the app.';

  @override
  String get feeControlFeeLoadRetry => 'Try again';

  @override
  String feeControlFeeTrancheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count instalments',
      one: '$count instalment',
    );
    return '$_temp0';
  }

  @override
  String get feeControlPaymentStatusLabel => 'Payment status';

  @override
  String get feeControlPaymentStatusAll => 'All';

  @override
  String get feeControlViewDetailLabel => 'Open the financial record';

  @override
  String get feeControlSummaryA11yLabel => 'Fee control summary';

  @override
  String get feeControlSummaryStudents => 'Students concerned';

  @override
  String get feeControlInvitationTitle => 'No control under way';

  @override
  String get feeControlInvitationMessage =>
      'Pick a class then a fee above to see who has settled it.';

  @override
  String get feeControlEmptyTitle => 'No student found';

  @override
  String get feeControlNoResultsDescription =>
      'No student matches these criteria. Adjust the form and search again.';

  @override
  String get feeControlEmptyEnrollmentWithheld =>
      'Students belong to the Enrolment module, which this profile cannot access: the control cannot cover anyone, whatever the criteria. Your administrator can grant that access.';

  @override
  String get feeControlEmptyClassroomWithheld =>
      'Class composition belongs to a module this profile cannot access: checking by class is not possible. Search again without a class filter to cover the whole level.';

  @override
  String get feeControlEmptyRosterMissing =>
      'This class\'s student list has not reached this device yet. Sync, then run the control again.';

  @override
  String get feeControlEmptyNoLocalEnrollment =>
      'No student in this class has a local enrollment record for this year. Sync enrollments, then run the control again.';

  @override
  String get feeControlNoChargeDescription =>
      'No student in this class carries this fee: it has not been generated for them yet, or it does not apply to this level.';

  @override
  String get feeControlEmptyNoEnrollmentForLevel =>
      'No student enrolled at this level on this device. If enrolments were entered elsewhere, sync and run the control again.';

  @override
  String get feeControlNoChargeForLevelDescription =>
      'No student at this level carries this fee: it has not been generated for them yet, or it does not apply to them.';

  @override
  String feeControlCriteriaFee(String label) {
    return 'Fee: $label';
  }

  @override
  String feeControlCriteriaClassroom(String label) {
    return 'Class: $label';
  }

  @override
  String feeControlCriteriaStatus(String label) {
    return 'Status: $label';
  }

  @override
  String facturationBalanceDuePill(String amount) {
    return '$amount due';
  }

  @override
  String get facturationBalanceDueMultiCurrencyPill => 'Balance due';

  @override
  String get facturationBalanceUpToDatePill => 'Up to date';

  @override
  String get financePendingSyncBadge => 'Pending sync';

  @override
  String facturationFreshnessAt(String time) {
    return 'Ledger up to date at $time';
  }

  @override
  String get facturationFreshnessNever => 'Ledger not synced';

  @override
  String facturationChargeLineRemainingSuffix(String amount) {
    return '$amount remaining';
  }

  @override
  String facturationPaymentRecordedToast(String amount) {
    return 'Payment of $amount recorded';
  }

  @override
  String get facturationChargeStatementCopied =>
      'Statement copied to clipboard';

  @override
  String get facturationChargeStatementEmpty =>
      'No payment to export for this fee.';

  @override
  String get facturationCsvHeaderFee => 'Fee';

  @override
  String get facturationCsvHeaderImputedAmount => 'Imputed amount (USD)';

  @override
  String get facturationDetailBackLabel => 'Back to billing';

  @override
  String get facturationDetailContextErrorTitle => 'Detail context unavailable';

  @override
  String get facturationDetailContextErrorMessage =>
      'Required context for this detail view is missing. Go back to billing list and open the detail again.';

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
  String get facturationDetailInfoTitle => 'Financial record';

  @override
  String get facturationDetailEyebrow => 'Billing';

  @override
  String get facturationDetailInfoSubtitle =>
      'Review recent payments and student charge status for this student.';

  @override
  String get facturationDetailHeaderKpiTotalDue => 'Total due';

  @override
  String get facturationDetailHeaderKpiAlreadyPaid => 'Already paid';

  @override
  String get facturationDetailHeaderKpiRemaining => 'Remaining due';

  @override
  String get facturationDetailInfoChipPayments => 'Payments';

  @override
  String get facturationDetailInfoChipCharges => 'Charges';

  @override
  String get facturationDetailPaymentsSectionTitle => 'Payments';

  @override
  String get facturationDetailPaymentsSectionSubtitle =>
      'Recorded payment history for this student.';

  @override
  String facturationDetailPaymentsRecordedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments recorded',
      one: '1 payment recorded',
      zero: 'No payment recorded',
    );
    return '$_temp0';
  }

  @override
  String facturationDetailPaymentsRecordedWithTotal(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments · $total',
      one: '1 payment · $total',
      zero: 'No payment recorded',
    );
    return '$_temp0';
  }

  @override
  String get facturationPaymentMethodCash => 'Cash';

  @override
  String get facturationDetailCollectPaymentAction => 'Collect payment';

  @override
  String get facturationDetailPaymentsRetry => 'Retry';

  @override
  String get facturationDetailPaymentsEmpty =>
      'No payment has been recorded for this student.';

  @override
  String get facturationDetailPaymentsWithheldSubtitle =>
      'Tracked by the cash desk.';

  @override
  String get facturationDetailPaymentsWithheld =>
      'Payment detail belongs to the cash desk: it is not shown for this profile. The already-paid total at the top of the record is still accurate.';

  @override
  String get facturationDetailPaymentPayerColumn => 'Payer';

  @override
  String get facturationDetailPaymentPaidAtColumn => 'Date';

  @override
  String get facturationDetailPaymentAmountColumn => 'Amount';

  @override
  String get facturationDetailPaymentActionsColumn => 'Actions';

  @override
  String get facturationDetailViewPaymentLabel => 'View payment detail';

  @override
  String get facturationDetailViewChargeLabel => 'View charge detail';

  @override
  String get facturationPaymentDetailHeroTitle => 'Payment detail';

  @override
  String get facturationPaymentDetailHeroSubtitle =>
      'Review this payment information and the breakdown of allocated amounts.';

  @override
  String get facturationPaymentInfoSectionTitle => 'Payment information';

  @override
  String get facturationPaymentPayerLabel => 'Payer';

  @override
  String get facturationPaymentAmountLabel => 'Total paid amount';

  @override
  String get facturationPaymentPaidAtLabel => 'Paid at';

  @override
  String get facturationPaymentAmountPaidLabel => 'Amount paid';

  @override
  String get facturationPaymentMethodLabel => 'Payment method';

  @override
  String get facturationPaymentCollectedByLabel => 'Collected by';

  @override
  String get facturationPaymentTicketNotPrinted => 'Ticket not printed';

  @override
  String get facturationPaymentPrintTicketAction => 'Print now';

  @override
  String get facturationPaymentReceiptLabel => 'Receipt no.';

  @override
  String get facturationPaymentStudentLabel => 'Student';

  @override
  String get facturationPaymentDownloadReceiptLabel => 'Download receipt';

  @override
  String get facturationPaymentReceiptForbiddenHint =>
      'You are not allowed to issue this document.';

  @override
  String get facturationPaymentReceiptPendingSyncHint =>
      'The receipt will be available once the payment has been synchronised.';

  @override
  String get facturationPaymentReceiptNumberPending =>
      'Awaiting synchronisation';

  @override
  String get facturationPaymentCloseLabel => 'Close';

  @override
  String get facturationPaymentAllocationsSectionTitle => 'Breakdown by fee';

  @override
  String get facturationPaymentAllocationsSectionSubtitle =>
      'List of charges covered by this payment.';

  @override
  String get facturationPaymentAllocationsTotalLabel => 'Allocated total';

  @override
  String get facturationPaymentAllocationsEmpty =>
      'No allocation was found for this payment.';

  @override
  String get facturationPaymentAllocationsConsistencyOk =>
      'Allocation sum is consistent with the total paid amount.';

  @override
  String get facturationPaymentAllocationsConsistencyWarning =>
      'Inconsistency detected: allocation sum does not match the total paid amount.';

  @override
  String get facturationPaymentAllocationsNetworkError =>
      'Unable to load payment allocations. Please check your internet connection.';

  @override
  String get facturationPaymentAllocationsNotFound =>
      'No allocation found for this payment.';

  @override
  String get facturationPaymentAllocationsValidationError =>
      'Requested allocation data is invalid.';

  @override
  String get facturationPaymentAllocationsUnauthorizedError =>
      'You are not allowed to access allocations for this payment.';

  @override
  String get facturationPaymentAllocationsInvalidCredentialsError =>
      'Your credentials do not allow access to allocations for this payment.';

  @override
  String get facturationPaymentAllocationsServerError =>
      'The server is currently unavailable.';

  @override
  String get facturationPaymentAllocationsStorageError =>
      'A local error prevents allocations from being displayed.';

  @override
  String get facturationPaymentAllocationsAuthError =>
      'An authentication error prevents allocations from loading.';

  @override
  String get facturationPaymentAllocationsUnknownError =>
      'An unexpected error occurred while loading allocations.';

  @override
  String get facturationDetailChargesSectionTitle => 'Charges';

  @override
  String get facturationDetailChargesSectionSubtitle =>
      'Breakdown of expected, paid and remaining amounts.';

  @override
  String facturationDetailChargesSummary(
    num totalCount,
    Object partialCount,
    Object dueCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      totalCount,
      locale: localeName,
      other: '$totalCount charges',
      one: '1 charge',
      zero: '0 charge',
    );
    return '$_temp0 · $partialCount partial, $dueCount to settle';
  }

  @override
  String get facturationDetailChargesRetry => 'Retry';

  @override
  String get facturationDetailChargesEmpty =>
      'No charge was found for this student.';

  @override
  String get facturationDetailChargeLabelColumn => 'Label';

  @override
  String get facturationDetailChargeExpectedAmountColumn => 'Expected';

  @override
  String get facturationDetailChargePaidAmountColumn => 'Paid';

  @override
  String get facturationDetailChargeRemainingAmountColumn => 'Remaining';

  @override
  String get facturationDetailChargeStatusColumn => 'Status';

  @override
  String get facturationDetailChargeTotalsLabel => 'Totals';

  @override
  String get facturationPaymentsNetworkError =>
      'Unable to load payments. Please check your internet connection.';

  @override
  String get facturationPaymentsNotFound =>
      'No payment was found for this student.';

  @override
  String get facturationPaymentsValidationError =>
      'Requested payment data is invalid.';

  @override
  String get facturationPaymentsUnauthorizedError =>
      'You are not allowed to access these payments.';

  @override
  String get facturationPaymentsInvalidCredentialsError =>
      'Your credentials do not allow access to these payments.';

  @override
  String get facturationPaymentsServerError =>
      'The server is currently unavailable.';

  @override
  String get facturationPaymentsStorageError =>
      'A local error prevents payments from being displayed.';

  @override
  String get facturationPaymentsAuthError =>
      'An authentication error prevents payments from loading.';

  @override
  String get facturationPaymentsUnknownError =>
      'An unexpected error occurred while loading payments.';

  @override
  String get facturationPrintReceiptLabel => 'Print receipt';

  @override
  String get facturationPrintReceiptSubtitle =>
      'Generate and download the receipt for this payment';

  @override
  String get facturationPaymentDownloadPdfLabel => 'Download PDF';

  @override
  String get facturationPrintStatementsLabel => 'Print statements';

  @override
  String get facturationPrintStatementsSubtitle =>
      'Generate and download the billing statements for this student';

  @override
  String get facturationChargeDetailBackLabel => 'Back to billing detail';

  @override
  String get facturationChargeDetailHeroTitle => 'Fee details';

  @override
  String get facturationChargeDetailHeroSubtitle =>
      'Review this charge status and the payments allocated to it.';

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
  String get facturationChargeDetailAllocationsSectionTitle =>
      'Applied payments';

  @override
  String get facturationChargeDetailAllocationsSectionSubtitle =>
      'Breakdown of payments allocated to this charge.';

  @override
  String get facturationChargeDetailAllocationLabelColumn => 'Allocation';

  @override
  String get facturationChargeDetailAllocationsTotalLabel => 'Allocated total';

  @override
  String get facturationChargeDetailAllocationsEmpty =>
      'No allocation was found for this charge.';

  @override
  String get facturationChargeDetailAllocationsWithheld =>
      'Payment allocation belongs to the cash desk: it is not detailed for this profile. The already-paid amount above is still accurate.';

  @override
  String get facturationChargeDetailAllocationsRetry => 'Retry';

  @override
  String get facturationChargeDetailAllocationsNetworkError =>
      'Unable to load allocations. Please check your internet connection.';

  @override
  String get facturationChargeDetailAllocationsNotFound =>
      'No allocation found for this charge.';

  @override
  String get facturationChargeDetailAllocationsValidationError =>
      'Requested allocation data is invalid.';

  @override
  String get facturationChargeDetailAllocationsUnauthorizedError =>
      'You are not allowed to access allocations for this charge.';

  @override
  String get facturationChargeDetailAllocationsInvalidCredentialsError =>
      'Your credentials do not allow access to allocations for this charge.';

  @override
  String get facturationChargeDetailAllocationsServerError =>
      'The server is currently unavailable.';

  @override
  String get facturationChargeDetailAllocationsStorageError =>
      'A local error prevents allocations from being displayed.';

  @override
  String get facturationChargeDetailAllocationsAuthError =>
      'An authentication error prevents allocations from loading.';

  @override
  String get facturationChargeDetailAllocationsUnknownError =>
      'An unexpected error occurred while loading allocations.';

  @override
  String get facturationChargeDetailContextErrorTitle =>
      'Charge detail context unavailable';

  @override
  String get facturationChargeDetailContextErrorMessage =>
      'Required context for this charge detail view is missing. Go back and open the detail again.';

  @override
  String get facturationCreatePaymentBackLabel => 'Back to billing detail';

  @override
  String get facturationCreatePaymentHeroTitle => 'New payment';

  @override
  String get facturationCreatePaymentHeroSubtitle =>
      'Fill in the payer information and allocations to record a payment.';

  @override
  String get facturationCreatePaymentPayerSectionTitle => 'Payer information';

  @override
  String get facturationCreatePaymentEyebrow => 'Payment collection';

  @override
  String get facturationCreatePaymentContextErrorTitle =>
      'Collection unavailable';

  @override
  String get facturationCreatePaymentContextErrorMessage =>
      'The information required for this collection is missing. Go back to the student file and start the collection again.';

  @override
  String get facturationCreatePaymentPayerLastNameLabel => 'Last name';

  @override
  String get facturationCreatePaymentPayerLastNameHint => 'Enter last name';

  @override
  String get facturationCreatePaymentPayerFirstNameLabel => 'First name';

  @override
  String get facturationCreatePaymentPayerFirstNameHint => 'Enter first name';

  @override
  String get facturationCreatePaymentPayerMiddleNameLabel =>
      'Surname (optional)';

  @override
  String get facturationCreatePaymentPayerMiddleNameHint => 'Enter surname';

  @override
  String get facturationCreatePaymentPayerFieldRequired =>
      'This field is required';

  @override
  String get facturationCreatePaymentPayerPhoneLabel => 'Payer\'s phone number';

  @override
  String get facturationCreatePaymentPayerPickAction => 'Choose a payer';

  @override
  String get facturationCreatePaymentPayerPickHelp =>
      'Reuse a payer who has already been to the desk, or enter one below.';

  @override
  String get facturationPayerSearchDialogEyebrow => 'Collection';

  @override
  String get facturationPayerSearchDialogTitle => 'Choose a payer';

  @override
  String get facturationPayerSearchModeSemantics => 'Search mode';

  @override
  String get facturationPayerSearchModeByPhone => 'By phone number';

  @override
  String get facturationPayerSearchModeByIdentity => 'By name';

  @override
  String get facturationPayerSearchPhoneHint =>
      'A partial number is enough: “8169” brings up every matching payer.';

  @override
  String get facturationPayerSearchIdentityHint =>
      'A single word is enough — last, middle or first name. Accents are ignored.';

  @override
  String get facturationPayerSearchAction => 'Search';

  @override
  String get facturationPayerSearchSuggestionsTitle =>
      'Already known for this student';

  @override
  String get facturationPayerSearchResultsTitle => 'Results';

  @override
  String get facturationPayerSearchResultsPlaceholder =>
      'Matching payers will appear here.';

  @override
  String get facturationPayerSearchEmptyTitle => 'No payer found';

  @override
  String get facturationPayerSearchEmptyDescription =>
      'No payer matches these criteria. Check what you typed, or close this window to enter the payer by hand.';

  @override
  String get facturationPayerSearchErrorRetry => 'Retry';

  @override
  String get facturationPayerSearchOriginGuardian =>
      'Student\'s guardian — has never paid yet';

  @override
  String facturationPayerSearchPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String facturationPayerSearchLastPaidAt(String date) {
    return 'last one on $date';
  }

  @override
  String get facturationPayerSearchUnknownPhone => 'Phone number unknown';

  @override
  String facturationPayerSearchSelectSemantics(String name) {
    return 'Choose $name as the payer';
  }

  @override
  String get facturationCreatePaymentDetailsSectionTitle => 'Payment details';

  @override
  String get facturationCreatePaymentDetailsSectionSubtitle =>
      'Enter the received amount, currency and payment date.';

  @override
  String get facturationCreatePaymentReceivedAmountLabel => 'Amount received';

  @override
  String get facturationCreatePaymentReceivedAmountHint => 'E.g.: 200';

  @override
  String get facturationCreatePaymentCurrencyLabel => 'Currency';

  @override
  String get facturationCreatePaymentCurrencyReadOnlyHint =>
      'Multiple currencies detected: read-only value.';

  @override
  String get facturationCreatePaymentCurrencyUnavailable =>
      'Currency unavailable';

  @override
  String get facturationCreatePaymentDateLabel => 'Payment date';

  @override
  String get facturationCreatePaymentAllocationSectionTitle =>
      'Payment allocations';

  @override
  String get facturationCreatePaymentAllocationSectionSubtitle =>
      'Associate an amount to one or more student charges.';

  @override
  String get facturationCreatePaymentAddAllocationLabel => 'Add allocation';

  @override
  String get facturationCreatePaymentAllChargesPaid =>
      'All student charges are already paid.';

  @override
  String get facturationCreatePaymentChargesUnavailable =>
      'No charges available. Go back to the list and try again.';

  @override
  String get facturationCollectPreflightMessage => 'Checking recent payments…';

  @override
  String get facturationCreatePaymentChargeDropdownHint => 'Select a charge';

  @override
  String get facturationCreatePaymentAmountLabel => 'Amount to pay';

  @override
  String get facturationCreatePaymentAmountHint => 'E.g.: 5000';

  @override
  String get facturationCreatePaymentAmountRequired => 'Amount is required';

  @override
  String get facturationCreatePaymentAmountInvalid =>
      'Please enter a valid number';

  @override
  String get facturationCreatePaymentAmountExceedsRemaining =>
      'Amount cannot exceed remaining balance';

  @override
  String get facturationCreatePaymentAmountMustBePositive =>
      'Amount must be greater than zero';

  @override
  String get facturationCreatePaymentBeforeLabel => 'Before payment';

  @override
  String get facturationCreatePaymentAfterLabel => 'After payment';

  @override
  String get facturationCreatePaymentRemoveAllocationConfirmTitle =>
      'Confirm removal';

  @override
  String facturationCreatePaymentRemoveAllocationConfirmMessage(
    int allocationIndex,
  ) {
    return 'Do you really want to remove allocation #$allocationIndex? This action cannot be undone.';
  }

  @override
  String get facturationCreatePaymentRemoveAllocationConfirmAction => 'Remove';

  @override
  String get facturationCreatePaymentSubmitLabel => 'Validate payment';

  @override
  String get facturationCreatePaymentNoAllocations =>
      'Add at least one allocation to validate the payment.';

  @override
  String get facturationCreatePaymentConfirmTitle => 'Confirm payment';

  @override
  String get facturationCreatePaymentConfirmMessage =>
      'This operation is irreversible. Do you confirm recording this payment?';

  @override
  String get facturationCreatePaymentConfirmCancel => 'Cancel';

  @override
  String get facturationCreatePaymentConfirmValidate => 'Confirm';

  @override
  String get facturationCreatePaymentCloseConfirmTitle =>
      'Close this collection?';

  @override
  String get facturationCreatePaymentCloseConfirmMessage =>
      'The information you entered will be lost if you close now.';

  @override
  String get facturationCreatePaymentCloseConfirmAction => 'Close';

  @override
  String get facturationCreatePaymentCloseConfirmCancel => 'Keep editing';

  @override
  String get facturationCreatePaymentSuccessMessage =>
      'Payment successfully recorded.';

  @override
  String get facturationCreatePaymentExpectedLabel => 'Expected';

  @override
  String get facturationCreatePaymentPaidLabel => 'Already paid';

  @override
  String get facturationCreatePaymentRemainingLabel => 'Remaining';

  @override
  String get facturationCreatePaymentStatusLabel => 'Status';

  @override
  String get facturationCreatePaymentChargeImpactTitle => 'Impact on charge';

  @override
  String facturationCreatePaymentChargeRemainingHelper(String remainingAmount) {
    return 'Remaining on this charge: $remainingAmount';
  }

  @override
  String get facturationCreatePaymentPayAllAction => 'Pay all';

  @override
  String get facturationCreatePaymentDistributionTrackerIdle =>
      'Enter at least one allocation to compute total payments.';

  @override
  String facturationCreatePaymentFooterTotalPayments(String allocatedAmount) {
    return 'Total payments: $allocatedAmount';
  }

  @override
  String get facturationCreatePaymentNetworkError =>
      'Check your connection and try again.';

  @override
  String get facturationCreatePaymentNotFoundError =>
      'The requested resource was not found.';

  @override
  String get facturationCreatePaymentValidationError =>
      'Submitted data is invalid. Please review the form.';

  @override
  String get facturationCreatePaymentUnauthorizedError =>
      'You are not authorized to perform this operation.';

  @override
  String get facturationCreatePaymentInvalidCredentialsError =>
      'Your credentials do not allow recording this payment.';

  @override
  String get facturationCreatePaymentServerError =>
      'Server is unavailable. Please try again later.';

  @override
  String get facturationCreatePaymentStorageError =>
      'A storage error occurred.';

  @override
  String get facturationCreatePaymentAuthError =>
      'An authentication error occurred.';

  @override
  String get facturationCreatePaymentUnknownError =>
      'An unexpected error occurred.';

  @override
  String get facturationCreatePaymentNoChargesAvailable =>
      'No unpaid charges available for this student.';

  @override
  String get facturationCreatePaymentChargesToSettleTitle => 'Fees to settle';

  @override
  String get facturationCreatePaymentChargesToSettleSubtitle =>
      'Check the fees to settle and adjust the amounts.';

  @override
  String get facturationCreatePaymentAllFeesSettled =>
      'All fees are already settled.';

  @override
  String facturationCreatePaymentChargeDue(String amount) {
    return 'Due $amount';
  }

  @override
  String facturationCreatePaymentChargePaid(String amount) {
    return 'Already paid $amount';
  }

  @override
  String facturationCreatePaymentChargeRemaining(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get facturationCreatePaymentAmountToSettleLabel => 'Amount to settle';

  @override
  String get facturationCreatePaymentSettleAllAction => 'Settle all';

  @override
  String facturationCreatePaymentAmountClampedWarning(String amount) {
    return 'Amount capped to the remaining balance ($amount).';
  }

  @override
  String facturationCreatePaymentRemainingAfter(String amount) {
    return 'Remaining after: $amount';
  }

  @override
  String get facturationCreatePaymentSettledChip => 'Settled';

  @override
  String get facturationCreatePaymentTotalToCollect => 'Total to collect';

  @override
  String facturationCreatePaymentCollectAmountAction(String amount) {
    return 'Collect $amount';
  }

  @override
  String facturationCreatePaymentConfirmCollectTitle(String amount) {
    return 'Collect $amount?';
  }

  @override
  String facturationCreatePaymentConfirmSentence(
    String amount,
    String student,
    String payer,
  ) {
    return 'You are about to collect $amount for $student, paid by $payer.';
  }

  @override
  String get facturationCreatePaymentConfirmDistributionTitle => 'Breakdown';

  @override
  String get facturationCollectStepConfirm => 'Confirmation';

  @override
  String get facturationCollectStepResult => 'Result';

  @override
  String get facturationCollectSimulateFailure => 'Simulate a failure';

  @override
  String get facturationCollectProcessing => 'Recording the payment…';

  @override
  String get facturationCollectSuccessTitle => 'Payment recorded';

  @override
  String facturationCollectReceiptChip(String code) {
    return 'Receipt no. $code';
  }

  @override
  String get facturationCollectErrorTitle => 'Collection failed';

  @override
  String get facturationCollectErrorNoDebit => 'No amount was debited.';

  @override
  String facturationCollectIncidentChip(String code) {
    return 'Incident code: $code';
  }

  @override
  String get facturationCollectEditAction => 'Edit';

  @override
  String get facturationCollectRetryAction => 'Retry';

  @override
  String get attendanceHeroTitle => 'Attendance';

  @override
  String get attendanceHeroSubtitle =>
      'View class attendance by date for reliable daily tracking.';

  @override
  String get attendanceHeroChipClass => 'Class-based search';

  @override
  String get attendanceHeroChipDate => 'Date filter';

  @override
  String get attendanceSearchTitle => 'Attendance Search';

  @override
  String get attendanceSearchHint =>
      'Select cycle, level, class and date to display attendance records.';

  @override
  String get attendanceDateLabel => 'Date';

  @override
  String get attendanceCycleLabel => 'Cycle';

  @override
  String get attendanceLevelLabel => 'Level';

  @override
  String get attendanceClassLabel => 'Class';

  @override
  String get attendanceShowClassAction => 'Show class';

  @override
  String get attendanceInvitationMessage =>
      'Run a search to display attendance for the selected class.';

  @override
  String get attendanceSelectClassTitle => 'Select a class';

  @override
  String get attendanceEmptySelectionMessage =>
      'Select a cycle, a level, and then a class to load the attendance list.';

  @override
  String get attendanceLoadingMessage => 'Loading attendance records...';

  @override
  String get attendanceEmptyStudentsTitle => 'No students in this class';

  @override
  String get attendanceEmptyStudentsDescription =>
      'This class has no students yet. Add students from the class Composition to take attendance.';

  @override
  String get attendanceEmptyOpenComposition => 'Open Composition';

  @override
  String get attendanceExportAction => 'Export';

  @override
  String get attendanceExportTooltip => 'Prepare result export';

  @override
  String get attendanceExportSoon => 'Export will be available soon.';

  @override
  String get attendanceSaveAction => 'Save';

  @override
  String get attendanceSavingAction => 'Saving...';

  @override
  String get attendanceSaveTooltip => 'Save all entered changes';

  @override
  String get attendanceSaveValidationHint =>
      'Fix absent rows without a reason before saving.';

  @override
  String get attendanceSaveSuccess =>
      'Attendance records were saved successfully.';

  @override
  String get attendanceValidateCallAction => 'Validate attendance';

  @override
  String get attendancePendingChanges => 'Pending changes';

  @override
  String get attendancePendingInvalidChanges => 'Fixes required';

  @override
  String get attendanceRowModifiedLabel => 'Modified';

  @override
  String get attendanceUnsavedChangesTitle => 'Unsaved changes';

  @override
  String get attendanceUnsavedChangesMessage =>
      'A new search will discard unsaved changes. Do you want to continue?';

  @override
  String get attendanceDateTooltip => 'Choose the attendance date';

  @override
  String get attendanceStatusInProgress => 'Attendance in progress';

  @override
  String get attendanceStatusReady => 'Ready to validate';

  @override
  String get attendancePresentCount => 'Present';

  @override
  String get attendanceJustifiedCount => 'Justified';

  @override
  String get attendanceUnjustifiedCount => 'Unjustified';

  @override
  String get attendancePendingCount => 'Pending reason';

  @override
  String get attendanceAbsentCount => 'Absent';

  @override
  String get attendanceTotalCountCompact => 'Total';

  @override
  String get attendanceDefaultPresenceHelper =>
      'All students are marked present by default. Tap Absent to report an exception.';

  @override
  String get attendanceReadyToValidate =>
      'No absence is missing a reason. You can validate attendance.';

  @override
  String attendanceMissingReasonsStatus(int count) {
    return '$count absence(s) without reason - complete required';
  }

  @override
  String get attendanceAllPresentConfirmTitle => 'Confirm attendance';

  @override
  String attendanceAllPresentConfirmMessage(int count) {
    return 'Do you confirm that all $count students are present?';
  }

  @override
  String get attendanceTotalCount => 'Total students';

  @override
  String get attendanceGirlsCount => 'Girls';

  @override
  String get attendanceBoysCount => 'Boys';

  @override
  String attendanceCriteriaSummary(String classroomName, String formattedDate) {
    return 'Class: $classroomName · Date: $formattedDate';
  }

  @override
  String get attendanceTableLastName => 'Last name';

  @override
  String get attendanceTableMiddleName => 'Middle name';

  @override
  String get attendanceTableFirstName => 'First name';

  @override
  String get attendanceTablePresent => 'Present';

  @override
  String get attendanceTableAbsenceReason => 'Reason';

  @override
  String get attendanceTableAbsenceReasonNote => 'Note';

  @override
  String get attendancePresenceStatusLabel => 'Attendance status';

  @override
  String get attendancePresentValue => 'Present';

  @override
  String get attendanceAbsentValue => 'Absent';

  @override
  String get attendanceReadOnlyHint => 'Read-only informational status';

  @override
  String get attendanceReasonRequiredError =>
      'Please select a reason for this absence.';

  @override
  String get attendanceReasonRequiredHint => 'Reason required for an absence.';

  @override
  String get attendanceMotifRequisLabel => 'Reason required';

  @override
  String get attendanceReasonDisabledHint =>
      'Reason is required only when the student is absent.';

  @override
  String get attendanceNoteDisabledHint =>
      'Note is optional only when the student is absent.';

  @override
  String get attendanceNotePlaceholder => 'Add details if needed';

  @override
  String get attendanceNoMiddleName => 'Not provided';

  @override
  String get attendanceNoAbsenceReason => 'No reason';

  @override
  String get attendanceNoAbsenceNote => 'No note';

  @override
  String get attendanceErrorNetwork =>
      'Check your internet connection and try again.';

  @override
  String get attendanceErrorNotFound => 'No attendance resource was found.';

  @override
  String get attendanceErrorValidation => 'Submitted data is invalid.';

  @override
  String get attendanceErrorUnauthorized =>
      'You are not authorized to access this resource.';

  @override
  String get attendanceErrorInvalidCredentials =>
      'Your credentials do not allow access to attendance.';

  @override
  String get attendanceErrorServer =>
      'Server is unavailable. Please try again later.';

  @override
  String get attendanceErrorStorage => 'A local storage error occurred.';

  @override
  String get attendanceErrorAuth => 'An authentication error occurred.';

  @override
  String get attendanceErrorUnknown => 'An unexpected error occurred.';

  @override
  String get attendanceErrorForbidden =>
      'You do not have the required permissions to view attendance.';

  @override
  String get attendanceErrorRetry => 'Retry';

  @override
  String get attendanceErrorReconnect => 'Sign in again';

  @override
  String get attendanceErrorContactAdmin => 'Contact the administrator';

  @override
  String get attendanceErrorNetworkTitle => 'No connection';

  @override
  String get attendanceErrorNetworkMessage =>
      'You appear to be offline. Check your internet connection, then try again.';

  @override
  String get attendanceErrorUnauthorizedTitle => 'Session expired';

  @override
  String get attendanceErrorUnauthorizedMessage =>
      'Your session has expired. Sign in again to resume attendance.';

  @override
  String get attendanceErrorForbiddenTitle => 'Access denied';

  @override
  String get attendanceErrorForbiddenMessage =>
      'You do not have the required permissions to view this class\'s attendance.';

  @override
  String get attendanceErrorServerTitle => 'Server error';

  @override
  String get attendanceErrorServerMessage =>
      'Something went wrong on our end. Try again in a moment.';

  @override
  String attendanceErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get attendanceErrorUnknownTitle => 'Unable to load';

  @override
  String get attendanceErrorUnknownMessage =>
      'An unexpected error occurred while loading attendance.';

  @override
  String get attendanceSaveCallAction => 'Save attendance';

  @override
  String get attendancePastCallAmendLocked =>
      'This call is already recorded and the day is over: correcting it is for the discipline office, not for whoever takes the call.';

  @override
  String get attendanceFocusPrevious => 'Previous';

  @override
  String get attendanceFocusNext => 'Next';

  @override
  String get attendanceModeList => 'List';

  @override
  String get attendanceModeFocus => 'Focus';

  @override
  String attendancePendingReasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reasons to fill in',
      one: '1 reason to fill in',
    );
    return '$_temp0';
  }

  @override
  String get attendanceUnsupportedReasonBlocked =>
      'An absence carries a reason this version of the app does not know. Pick one to be able to save — otherwise it would be overwritten with nobody noticing.';

  @override
  String get attendanceMarkAllPresentAction => 'All present';

  @override
  String get attendanceCallNotTakenTitle => 'Attendance not taken';

  @override
  String get attendanceCallNotTakenMessage =>
      'No attendance has been recorded for this day yet. Save to record it.';

  @override
  String get attendanceSaveOverlayEyebrow => 'Attendance';

  @override
  String get attendanceSaveProcessingTitle => 'Saving attendance…';

  @override
  String get attendanceSaveSuccessTitle => 'Attendance saved!';

  @override
  String get attendanceSaveSuccessSubtitle =>
      'Class attendance records have been saved.';

  @override
  String get attendanceSaveErrorTitle => 'Save failed';

  @override
  String get attendanceSaveErrorMessage =>
      'Your entries are preserved. Check your connection and try again.';

  @override
  String get attendanceSaveRetryAction => 'Retry';

  @override
  String get attendanceSaveCloseAction => 'Done';

  @override
  String get absenceReasonSickness => 'Sickness';

  @override
  String get absenceReasonFamilyEmergency => 'Family emergency';

  @override
  String get absenceReasonPersonal => 'Personal';

  @override
  String get absenceReasonUnknown => 'Not justified';

  @override
  String get absenceReasonVacation => 'Vacation';

  @override
  String get absenceReasonUnderGraduateLeave => 'Study leave';

  @override
  String get absenceReasonMarriageLeave => 'Marriage leave';

  @override
  String get absenceReasonParentalLeave => 'Parental leave';

  @override
  String get absenceReasonWorkLeave => 'Work leave';

  @override
  String get absenceReasonUnjustified => 'Unjustified absence';

  @override
  String get absenceReasonOther => 'Other';

  @override
  String get absenceReasonUnsupported => 'Unrecognised reason';

  @override
  String get bootstrapContextUnavailableTitle =>
      'Enrollment context unavailable';

  @override
  String get bootstrapContextUnavailableMessage =>
      'Bootstrap data (academic year / school) is missing. Please sign out and sign in again to reload the configuration.';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get disciplinaryDetailBackLabel => 'Back to disciplines';

  @override
  String get disciplinaryFollowUpTitle => 'Disciplinary follow-up';

  @override
  String get disciplinaryHeroTitle => 'Disciplinary case file detail';

  @override
  String get disciplinaryHeroChipCases => 'Disciplinary cases';

  @override
  String get disciplinaryDetailContextErrorTitle =>
      'Detail context unavailable';

  @override
  String get disciplinaryDetailContextErrorMessage =>
      'Required context for this detail view is missing. Go back to the list and open the detail again.';

  @override
  String get disciplinaryTabCasesLabel => 'Disciplinary cases';

  @override
  String get disciplinaryTabAttendanceHistoryLabel => 'Attendance history';

  @override
  String get presenceStatusPresent => 'Present';

  @override
  String get presenceStatusJustified => 'Justified absence';

  @override
  String get presenceStatusUnjustified => 'Unjustified absence';

  @override
  String get presenceSummaryTitle => 'Attendance summary';

  @override
  String presenceSummaryA11yLabel(int rate) {
    return 'Attendance summary, rate $rate%';
  }

  @override
  String get presenceKpiRate => 'Attendance rate';

  @override
  String presenceRateValue(int rate) {
    return '$rate%';
  }

  @override
  String presenceSchoolDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count school days',
      one: '1 school day',
      zero: '0 school days',
    );
    return '$_temp0';
  }

  @override
  String get presenceDistributionA11yLabel => 'Distribution of days by status';

  @override
  String presencePresentOutOfTotal(int present, int total) {
    return '$present days present out of $total';
  }

  @override
  String get presenceAbsenceListTitle => 'Absences detail';

  @override
  String presenceAbsenceDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get presencePerfectTitle => 'Perfect attendance';

  @override
  String get presencePerfectMessage => 'No absence on this period.';

  @override
  String get presenceLoadingA11yLabel => 'Loading attendance summary…';

  @override
  String get presencePeriodWeek => 'Week';

  @override
  String get presencePeriodMonth => 'Month';

  @override
  String get presencePeriodYear => 'Year';

  @override
  String get presencePeriodFilterA11yLabel => 'Attendance period';

  @override
  String get presenceEmptyTitle => 'No school days';

  @override
  String get presenceEmptyMessage =>
      'No school days on this period. Pick another period to view attendance.';

  @override
  String presenceRangeYear(String name) {
    return 'School year $name';
  }

  @override
  String presenceRangeMonth(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String presenceRangeWeek(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Week of $dateString';
  }

  @override
  String get presenceOfflineSyncPendingTitle => 'Sync in progress';

  @override
  String get presenceOfflineSyncPendingMessage =>
      'Local attendance data isn\'t complete enough yet to compute a reliable statistic. Try again in a moment.';

  @override
  String get disciplinaryUnknownValue => '-';

  @override
  String get disciplinaryCaseCreateAction => 'New case';

  @override
  String get disciplinaryCaseCreateCtaSubtitle =>
      'Document a new disciplinary incident for this student.';

  @override
  String disciplinaryCasesSummary(int total, int open) {
    return '$total recorded cases - $open open';
  }

  @override
  String get disciplinaryCasesTableTitleColumn => 'Title';

  @override
  String get disciplinaryCasesTableStatusColumn => 'Status';

  @override
  String get disciplinaryCasesTableActionColumn => 'Actions';

  @override
  String get disciplinaryCasesDateUnavailable => 'Date unavailable';

  @override
  String get disciplinaryCaseViewLabel => 'View case';

  @override
  String get disciplinaryCasesLoadingMessage => 'Loading disciplinary cases...';

  @override
  String get disciplinaryCasesEmptyMessage =>
      'No disciplinary cases for this student.';

  @override
  String get disciplinaryCaseViewDialogTitle => 'Disciplinary case detail';

  @override
  String get disciplinaryCaseViewDialogSectionTitle => 'Case information';

  @override
  String get disciplinaryCaseViewDialogTitleField => 'Title';

  @override
  String get disciplinaryCaseViewDialogStatusField => 'Status';

  @override
  String get disciplinaryCaseViewDialogContentField => 'Content';

  @override
  String get disciplinaryCaseViewDialogLoadingMessage =>
      'Loading case detail...';

  @override
  String get disciplinaryCaseViewDialogErrorMessage =>
      'Unable to load case detail';

  @override
  String get disciplinaryCaseCreateDialogTitle => 'Create disciplinary case';

  @override
  String get disciplinaryCaseCreateDialogTitleField => 'Case title';

  @override
  String get disciplinaryCaseCreateDialogTitleHint =>
      'Give a brief case description';

  @override
  String get disciplinaryCaseCreateDialogContentField => 'Content';

  @override
  String get disciplinaryCaseCreateDialogContentHint =>
      'Disciplinary case details';

  @override
  String get disciplinaryCaseCreateDialogCaseDateField => 'Case date';

  @override
  String get disciplinaryCaseCreateDialogCaseDateHint => 'Select date';

  @override
  String get disciplinaryCaseCreateDialogSubmitAction => 'Create case';

  @override
  String get disciplinaryCaseCreateDialogCreatingMessage => 'Creating...';

  @override
  String get disciplinaryCaseCreateDialogSuccessMessage =>
      'Disciplinary case created successfully.';

  @override
  String get disciplinaryCaseCreateDialogRequiredFieldError =>
      'This field is required.';

  @override
  String get disciplinaryCasesNetworkError =>
      'Check your internet connection and try again.';

  @override
  String get disciplinaryCasesNotFound => 'No disciplinary cases found.';

  @override
  String get disciplinaryCasesValidationError => 'Requested data is invalid.';

  @override
  String get disciplinaryCasesUnauthorizedError =>
      'You are not authorized to access these cases.';

  @override
  String get disciplinaryCasesInvalidCredentialsError =>
      'Your credentials do not allow access to cases.';

  @override
  String get disciplinaryCasesServerError =>
      'Server is unavailable. Please try again later.';

  @override
  String get disciplinaryCasesStorageError => 'A local storage error occurred.';

  @override
  String get disciplinaryCasesAuthError =>
      'An authentication error prevents loading cases.';

  @override
  String get disciplinaryCasesUnknownError => 'An unexpected error occurred.';

  @override
  String get disciplinaryCaseStatusOpen => 'Open';

  @override
  String get disciplinaryCaseStatusInProgress => 'In progress';

  @override
  String get disciplinaryCaseStatusClosed => 'Closed';

  @override
  String get disciplinaryCaseStatusUnknown => 'Unknown';

  @override
  String get disciplinarySeverityMinor => 'Minor';

  @override
  String get disciplinarySeverityMajor => 'Major';

  @override
  String get disciplinarySeveritySerious => 'Serious';

  @override
  String get disciplinarySeverityUnknown => 'Unspecified';

  @override
  String get disciplinaryCategoryDisruptiveBehavior => 'Disruptive behavior';

  @override
  String get disciplinaryCategoryLateness => 'Lateness';

  @override
  String get disciplinaryCategoryRepeatedLateness => 'Repeated lateness';

  @override
  String get disciplinaryCategoryUnjustifiedAbsence => 'Unjustified absence';

  @override
  String get disciplinaryCategoryInsolence => 'Insolence';

  @override
  String get disciplinaryCategoryCheating => 'Cheating';

  @override
  String get disciplinaryCategoryFighting => 'Fighting';

  @override
  String get disciplinaryCategoryDressCodeViolation => 'Dress code violation';

  @override
  String get disciplinaryCategoryTalkingInClass => 'Talking in class';

  @override
  String get disciplinaryCategoryUnknown => 'Other';

  @override
  String get disciplinarySanctionOralWarning => 'Oral warning';

  @override
  String get disciplinarySanctionWrittenWarning => 'Written warning';

  @override
  String get disciplinarySanctionDetention => 'Detention';

  @override
  String get disciplinarySanctionParentsSummoned => 'Parents summoned';

  @override
  String get disciplinarySanctionTemporaryExclusion => 'Temporary exclusion';

  @override
  String get disciplinarySanctionDisciplinaryCouncil => 'Disciplinary council';

  @override
  String get disciplinarySanctionPermanentExclusion => 'Permanent exclusion';

  @override
  String get disciplinarySanctionUnknown => 'No sanction';

  @override
  String disciplinaryCaseSeverityChip(String severity) {
    return 'Severity $severity';
  }

  @override
  String get disciplinaryAdvanceTakeCharge => 'Take charge';

  @override
  String get disciplinaryAdvanceClose => 'Close';

  @override
  String get disciplinaryStatusOfflinePending => 'In progress';

  @override
  String get disciplinaryStatusOfflineResolved => 'Resolved';

  @override
  String get disciplinaryStatusOfflineDismissed => 'Dismissed';

  @override
  String get disciplinaryAdvanceResolve => 'Resolve';

  @override
  String get disciplinaryAdvanceDismiss => 'Dismiss';

  @override
  String get disciplinaryCaseResolvedLabel => 'Case resolved';

  @override
  String get disciplinaryCaseDismissedLabel => 'Dismissed';

  @override
  String get disciplinaryCaseClosedLabel => 'Case closed';

  @override
  String disciplinaryCommentsCountBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: '0 comments',
    );
    return '$_temp0';
  }

  @override
  String get disciplinaryCommentsDialogTitle => 'Comments';

  @override
  String get disciplinaryCommentsEmpty => 'No comments yet.';

  @override
  String get disciplinaryCommentAddHint => 'Add a comment…';

  @override
  String get disciplinaryCommentAddAction => 'Add';

  @override
  String get disciplinaryCommentsCloseAction => 'Close';

  @override
  String get disciplinaryFreshnessSynced => 'Up to date';

  @override
  String get disciplinaryFreshnessLocal => 'This device only';

  @override
  String disciplinaryCasesCountPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cases',
      one: '1 case',
      zero: '0 case',
    );
    return '$_temp0';
  }

  @override
  String disciplinaryCasesOpenPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
      zero: '0 open',
    );
    return '$_temp0';
  }

  @override
  String disciplinaryCasesGravePill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serious',
      one: '1 serious',
      zero: '0 serious',
    );
    return '$_temp0';
  }

  @override
  String get disciplinaryCasesEmptyTitle => 'No discipline case';

  @override
  String get disciplinaryCasesEmptyDescription =>
      'No incident recorded for this student. All good.';

  @override
  String get disciplinaryFieldCategory => 'Category';

  @override
  String get disciplinaryFieldSeverity => 'Severity';

  @override
  String get disciplinaryFieldSanction => 'Sanction';

  @override
  String get disciplinaryStatusAtCreationLabel => 'Status at creation';

  @override
  String get disciplinaryStatusAtCreationHint =>
      'The case will be created as Open. You will then advance it from the record.';

  @override
  String get disciplinaryErrorNetworkTitle => 'No connection';

  @override
  String get disciplinaryErrorUnauthorizedTitle => 'Session expired';

  @override
  String get disciplinaryErrorForbiddenTitle => 'Access denied';

  @override
  String get disciplinaryErrorServerTitle => 'Server error';

  @override
  String get disciplinaryErrorUnknownTitle => 'Unable to load';

  @override
  String get disciplinaryErrorRetry => 'Retry';

  @override
  String get disciplinaryErrorReconnect => 'Sign in again';

  @override
  String get disciplinaryErrorContactAdmin => 'Contact the administrator';

  @override
  String get enrollmentStatusPreRegistered => 'Pre-registered';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusPresent => 'Present';

  @override
  String get statusAbsentJustified => 'Justified';

  @override
  String get statusAbsentUnjustified => 'Absent';

  @override
  String get statusSynced => 'Up to date';

  @override
  String get statusPartiallySynced => 'Partly up to date';

  @override
  String get statusSyncing => 'Syncing…';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusPendingUpload => 'Pending upload';

  @override
  String get statusSyncConflict => 'Conflict';

  @override
  String get statusAuthRequired => 'Sign-in required';

  @override
  String get syncLastSyncJustNow => 'Just now';

  @override
  String syncLastSyncMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
      zero: '0 min ago',
    );
    return '$_temp0';
  }

  @override
  String syncLastSyncHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '1 h ago',
      zero: '0 h ago',
    );
    return '$_temp0';
  }

  @override
  String syncLastSyncDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
      zero: '0 days ago',
    );
    return '$_temp0';
  }

  @override
  String get syncRowSynced => 'Synced with the server';

  @override
  String get syncRowPending => 'Waiting to be synced';

  @override
  String get syncRowError =>
      'Rejected by the server — will not retry on its own';

  @override
  String get syncErrorsTitle => 'Failed writes';

  @override
  String get syncErrorsSubtitle =>
      'These records were rejected by the server. They will not be sent again on their own.';

  @override
  String get syncErrorsRetry => 'Retry';

  @override
  String get syncErrorsRetryAll => 'Retry all';

  @override
  String get syncErrorsEmptyLabel => 'No failed writes';

  @override
  String get syncErrorsEmptyDescription =>
      'Everything entered has been sent or is waiting its turn.';

  @override
  String get syncErrorsLoadFailedTitle => 'List unavailable';

  @override
  String get syncErrorsLoadFailedMessage =>
      'Could not read the local send queue.';

  @override
  String get syncErrorsNotReplayable =>
      'This attendance record cannot be resent as is: the absence list may have changed since. Reopen the day and validate it again.';

  @override
  String get syncErrorsClose => 'Close';

  @override
  String syncErrorsQueuedAt(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString at $timeString';
  }

  @override
  String get syncAggregateEnrollment => 'Enrollment';

  @override
  String get syncAggregatePayment => 'Payment';

  @override
  String get syncAggregateAttendance => 'Attendance';

  @override
  String get syncAggregateDisciplinaryCase => 'Disciplinary case';

  @override
  String get syncAggregateNotesBatch => 'Grade batch';

  @override
  String get syncAggregateEvaluation => 'Assessment';

  @override
  String get syncAggregateClassroomTransfer => 'Class transfer';

  @override
  String get offlineQueuedGeneric => 'Saved — pending synchronization';

  @override
  String get offlinePaymentQueued => 'Payment saved — pending synchronization';

  @override
  String get offlineEnrollmentQueued =>
      'Enrollment saved — pending synchronization';

  @override
  String get offlineAttendanceQueued =>
      'Attendance saved — pending synchronization';

  @override
  String get offlineDisciplinaryCaseQueued =>
      'Disciplinary case saved — pending synchronization';

  @override
  String get offlineDisciplinaryCaseUpdatedQueued =>
      'Case updated — pending synchronization';

  @override
  String get offlineWriteError => 'Local save failed';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get componentGalleryTitle => 'Component gallery';

  @override
  String get enrollmentStatsDashboardTitle => 'Enrollment Dashboard';

  @override
  String get enrollmentStatsPeriodYear => 'Year';

  @override
  String get enrollmentStatsPeriodMonth => 'Month';

  @override
  String get enrollmentStatsPeriodWeek => 'Week';

  @override
  String get enrollmentStatsKpiTotal => 'Total';

  @override
  String get enrollmentStatsKpiFirst => 'First enrollments';

  @override
  String get enrollmentStatsKpiRe => 'Re-enrollments';

  @override
  String get enrollmentStatsKpiPre => 'Pre-enrollments';

  @override
  String get enrollmentStatsKpiInProgress => 'In progress';

  @override
  String get enrollmentStatsSectionEvolution => 'Evolution';

  @override
  String get enrollmentStatsSectionCycle => 'By cycle';

  @override
  String get enrollmentStatsSectionGender => 'By gender';

  @override
  String get enrollmentStatsSectionEvolutionEnrollments =>
      'Enrollment evolution';

  @override
  String get enrollmentStatsSectionLevelDistribution =>
      'Enrollment distribution by class';

  @override
  String get enrollmentStatsSectionGenderEvolution => 'Evolution by gender';

  @override
  String get enrollmentStatsGenderMale => 'Boys';

  @override
  String get enrollmentStatsGenderFemale => 'Girls';

  @override
  String get enrollmentStatsGenderOther => 'Other';

  @override
  String get enrollmentStatsNoData => 'No data available for this period';

  @override
  String get enrollmentStatsLoadingError => 'Unable to load statistics';

  @override
  String get enrollmentStatsRetry => 'Retry';

  @override
  String get enrollmentStatsStudents => 'students';

  @override
  String enrollmentStatsPercent(int percent) {
    return '$percent %';
  }

  @override
  String get enrollmentStatsPeriodWeekCurrent => 'This week';

  @override
  String get enrollmentStatsPeriodMonthCurrent => 'This month';

  @override
  String get enrollmentStatsPeriodYearCurrent => 'This year';

  @override
  String get enrollmentStatsSchoolYearUnavailable => 'School year unavailable';

  @override
  String enrollmentStatsHeaderA11yLabel(String schoolYear) {
    return 'Enrollment dashboard, school year $schoolYear';
  }

  @override
  String enrollmentStatsPeriodFilterA11yLabel(String selectedPeriod) {
    return 'Enrollment statistics time filter, active period: $selectedPeriod';
  }

  @override
  String enrollmentStatsContextSchoolYear(String schoolYear) {
    return 'Overview - School year $schoolYear';
  }

  @override
  String get classesStatsDashboardTitle => 'Classes Overview - School year';

  @override
  String get classesStatsSchoolYearUnavailable => 'School year unavailable';

  @override
  String classesStatsHeaderA11yLabel(String schoolYear) {
    return 'Classes dashboard, school year $schoolYear';
  }

  @override
  String get classesStatsKpiTotalStudents => 'TOTAL STUDENTS';

  @override
  String get classesStatsKpiActiveGirls => 'TOTAL GIRLS';

  @override
  String get classesStatsKpiActiveBoys => 'BOYS';

  @override
  String get classesStatsKpiInactiveStudents => 'TOTAL INACTIVE STUDENTS';

  @override
  String get classesStatsSectionCycleDistribution =>
      'Active students distribution by cycle';

  @override
  String classesStatsSectionLevelDistribution(String cycleCode) {
    return 'Levels distribution - $cycleCode';
  }

  @override
  String get classesStatsSectionClassroomDetail => 'Classrooms detail';

  @override
  String get classesStatsDetailColumnClassroom => 'Classroom';

  @override
  String get classesStatsDetailColumnCycle => 'Cycle';

  @override
  String get classesStatsDetailColumnLevel => 'Level';

  @override
  String get classesStatsDetailColumnTotal => 'Total';

  @override
  String get classesStatsDetailColumnGirls => 'Girls';

  @override
  String get classesStatsDetailColumnBoys => 'Boys';

  @override
  String get classesStatsNoData => 'No data available for this period';

  @override
  String get classesStatsKpiBandA11yLabel =>
      'Classes key performance indicators band';

  @override
  String get classesStatsCycleChartA11yLabel =>
      'Chart of active students distribution by cycle';

  @override
  String classesStatsLevelChartA11yLabel(String cycleCode) {
    return 'Chart of active students distribution by level for cycle $cycleCode';
  }

  @override
  String get classesStatsDetailA11yLabel =>
      'Detailed classrooms table with gender breakdown';

  @override
  String get classesStatsLoadingA11yLabel => 'Loading classes statistics';

  @override
  String get classesStatsErrorTitle => 'Loading error';

  @override
  String get classesStatsRetry => 'Retry';

  @override
  String get classesStatsRetryHint => 'Retry loading classes statistics';

  @override
  String classesStatsErrorA11yLabel(String message) {
    return 'Classes statistics loading error: $message';
  }

  @override
  String get classesStatsNetworkError =>
      'Unable to load classes statistics. Check your internet connection.';

  @override
  String get classesStatsNotFoundError => 'No classes statistics available.';

  @override
  String get classesStatsValidationError =>
      'The requested parameters are invalid.';

  @override
  String get classesStatsUnauthorizedError =>
      'You are not authorized to view these statistics.';

  @override
  String get classesStatsInvalidCredentialsError =>
      'Invalid session, please sign in again.';

  @override
  String get classesStatsServerError => 'The server is currently unavailable.';

  @override
  String get classesStatsStorageError =>
      'A local error prevents displaying statistics.';

  @override
  String get classesStatsAuthError =>
      'An authentication error prevents loading statistics.';

  @override
  String get classesStatsUnknownError =>
      'An unexpected error occurred while loading statistics.';

  @override
  String get financeStatsDashboardTitle => 'Overview - School year';

  @override
  String get financeStatsSchoolYearUnavailable => 'School year unavailable';

  @override
  String financeStatsContextSchoolYear(String schoolYear) {
    return 'Overview - School year $schoolYear';
  }

  @override
  String get financeStatsPeriodWeekCurrent => 'This week';

  @override
  String get financeStatsPeriodMonthCurrent => 'This month';

  @override
  String get financeStatsPeriodYearCurrent => 'This year';

  @override
  String financeStatsCurrencyHeading(String currency) {
    return 'In $currency';
  }

  @override
  String get financeStatsNoMovementLabel => 'No movement in this period';

  @override
  String get financeStatsNoMovementDescription =>
      'Nothing collected and nothing billed in this window. Widen the period to look further back.';

  @override
  String get financeStatsKpiCollected => 'Total collected';

  @override
  String get financeStatsKpiExpected => 'Total expected';

  @override
  String get financeStatsKpiOutstanding => 'Outstanding';

  @override
  String get financeStatsKpiCollectionRate => 'Collection rate';

  @override
  String financeStatsKpiRateForCurrency(int rate, String currency) {
    return '$rate% · $currency';
  }

  @override
  String get financeStatsSectionEvolution => 'Collection evolution';

  @override
  String get financeStatsLegendCurrentPeriod => 'Current period';

  @override
  String get financeStatsLegendOtherPeriods => 'Other periods';

  @override
  String get financeStatsSectionFeeTypeDistribution =>
      'Distribution by fee type';

  @override
  String financeStatsFeeTypeCollected(String amount) {
    return 'Collected: $amount';
  }

  @override
  String financeStatsFeeTypeExpected(String amount) {
    return 'Expected: $amount';
  }

  @override
  String financeStatsFeeTypeRate(int rate) {
    return 'Rate: $rate%';
  }

  @override
  String get financeStatsNoData => 'No data available for this period';

  @override
  String get financeStatsNoDataHint =>
      'Try another period to display more insights.';

  @override
  String get financeStatsRetry => 'Retry';

  @override
  String get financeStatsLoadingA11yLabel => 'Finance statistics are loading';

  @override
  String financeStatsHeaderA11yLabel(String schoolYear) {
    return 'Finance dashboard, school year $schoolYear';
  }

  @override
  String financeStatsPeriodFilterA11yLabel(String selectedPeriod) {
    return 'Finance statistics time filter, active period: $selectedPeriod';
  }

  @override
  String get financeStatsKpiBandA11yLabel =>
      'Financial key performance indicators band';

  @override
  String get financeStatsEvolutionChartA11yLabel =>
      'Collection amount evolution chart';

  @override
  String get financeStatsFeeTypeSectionA11yLabel =>
      'Distribution of amounts by fee type';

  @override
  String financeStatsFeeTypeItemA11yLabel(
    String code,
    String collected,
    String expected,
    String outstanding,
    int rate,
  ) {
    return 'Type $code, collected $collected, expected $expected, outstanding $outstanding, rate $rate%';
  }

  @override
  String get financeStatsEmptyA11yLabel =>
      'No finance data available for this period';

  @override
  String get financeStatsNetworkError =>
      'Unable to load finance statistics. Check your internet connection.';

  @override
  String get financeStatsNotFoundError => 'No finance statistics available.';

  @override
  String get financeStatsValidationError =>
      'The requested parameters are invalid.';

  @override
  String get financeStatsUnauthorizedError =>
      'You are not authorized to view these statistics.';

  @override
  String get financeStatsInvalidCredentialsError =>
      'Invalid session, please sign in again.';

  @override
  String get financeStatsServerError => 'The server is currently unavailable.';

  @override
  String get financeStatsStorageError =>
      'A local error prevents displaying statistics.';

  @override
  String get financeStatsAuthError =>
      'An authentication error prevents loading statistics.';

  @override
  String get financeStatsUnknownError =>
      'An unexpected error occurred while loading statistics.';

  @override
  String get financeStatsErrorNetworkTitle => 'No connection';

  @override
  String get financeStatsErrorUnauthorizedTitle => 'Session expired';

  @override
  String get financeStatsErrorForbiddenTitle => 'Access denied';

  @override
  String get financeStatsErrorServerTitle => 'Could not load';

  @override
  String get financeStatsErrorReconnect => 'Sign in again';

  @override
  String financeStatsErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get financeDashboardTabsA11yLabel => 'Finance dashboard tabs';

  @override
  String get financeDashboardTabRecoveryLabel => 'Recovery';

  @override
  String get financeDashboardTabRecoveryDescription =>
      'What is still to be collected this year';

  @override
  String get financeDashboardTabTillLabel => 'Till';

  @override
  String get financeDashboardTabTillDescription => 'What went into the drawer';

  @override
  String get financeTillKpiTotal => 'Till total';

  @override
  String get financeTillKpiFees => 'School fees';

  @override
  String get financeTillKpiBoutique => 'Boutique sales';

  @override
  String get financeTillKpiBandA11yLabel => 'Till indicators, by currency';

  @override
  String financeStatsFeeTypeOutstanding(String amount) {
    return 'Outstanding: $amount';
  }

  @override
  String get financeStatsRateNotApplicable => 'Not applicable';

  @override
  String financeStatsRateNotApplicableForCurrency(String currency) {
    return 'Not applicable · $currency';
  }

  @override
  String get financeStatsFeeTypeRateNotApplicable => 'Rate: not applicable';

  @override
  String get financeStatsCurrencyNoMovement => 'No movement in this currency';

  @override
  String get financeStatsCurrencyNoMovementRecovery =>
      'Nothing was billed or collected this school year.';

  @override
  String get financeTillPeriodDayCurrent => 'Today';

  @override
  String financeTillWindow(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String financeTillWindowDay(String date) {
    return 'Day of $date';
  }

  @override
  String financeTillTimeZoneHint(String zone) {
    return 'Day in the school\'s time zone · $zone';
  }

  @override
  String get financeTillSectionBuckets => 'Cash-in over time';

  @override
  String get financeTillSectionFeeCodes => 'Collected fees by type';

  @override
  String get financeTillBucketsChartA11yLabel => 'Cash-in chart, by interval';

  @override
  String get financeTillFeeCodeSectionA11yLabel =>
      'Collected fees broken down by type';

  @override
  String financeTillFeeCodeAmountA11yLabel(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String financeTillFreshnessNotice(String relative) {
    return 'As of the last sync · $relative';
  }

  @override
  String get financeTillFreshnessNever => 'Never synced';

  @override
  String get financeStatsCurrencyNoMovementTill =>
      'Nothing went into the drawer over this window.';

  @override
  String get enrollmentResults => 'Results';

  @override
  String get sort => 'Sort';

  @override
  String get switchToTableView => 'Switch to table view';

  @override
  String get switchToGridView => 'Switch to grid view';

  @override
  String get enrollmentViewTable => 'Table';

  @override
  String get enrollmentViewGrid => 'Grid';

  @override
  String get enrollmentResultsA11yLabel => 'Enrollment results';

  @override
  String get dataTableSortAscending => 'Ascending sort';

  @override
  String get dataTableSortDescending => 'Descending sort';

  @override
  String get dataTableSortNone => 'No sort';

  @override
  String openDetailsForStudent(String studentName) {
    return 'Open student file for $studentName';
  }

  @override
  String removeFilterNamed(String filter) {
    return 'Remove filter $filter';
  }

  @override
  String get attendanceOverviewEyebrow => 'Discipline · Attendance';

  @override
  String get attendanceOverviewTitle => 'Dashboard';

  @override
  String get attendanceOverviewContextSchoolYear => 'School year';

  @override
  String get attendanceOverviewContextWindow => 'Window';

  @override
  String get attendanceOverviewContextGeneratedAt => 'Generated on';

  @override
  String get attendanceOverviewContextA11yLabel =>
      'Attendance statistics context';

  @override
  String get attendanceOverviewKpiPresence => 'Attendance rate';

  @override
  String get attendanceOverviewKpiJustified => 'Justified absences';

  @override
  String get attendanceOverviewKpiUnjustified => 'Unjustified absences';

  @override
  String get attendanceOverviewKpiRecordedDays => 'Recorded days';

  @override
  String attendanceOverviewRateValue(String rate) {
    return '$rate%';
  }

  @override
  String attendanceOverviewStudentDays(String count) {
    return '$count student-days';
  }

  @override
  String get attendanceOverviewKpiBandA11yLabel => 'Key attendance indicators';

  @override
  String get attendanceOverviewSplitTitle => 'Attendance / absence breakdown';

  @override
  String get attendanceOverviewSplitSumHint => 'sum = 100%';

  @override
  String get attendanceOverviewSplitPresence => 'Present';

  @override
  String get attendanceOverviewSplitJustified => 'Justified absences';

  @override
  String get attendanceOverviewSplitUnjustified => 'Unjustified absences';

  @override
  String attendanceOverviewSplitA11yLabel(
    String presence,
    String justified,
    String unjustified,
  ) {
    return 'Present $presence%, justified $justified%, unjustified $unjustified%';
  }

  @override
  String get attendanceOverviewEvolutionTitle => 'Attendance rate trend';

  @override
  String get attendanceOverviewEvolutionHintMonth => 'by month';

  @override
  String get attendanceOverviewEvolutionHintWeek => 'by week';

  @override
  String get attendanceOverviewEvolutionHintDay => 'by day';

  @override
  String attendanceOverviewEvolutionTarget(String rate) {
    return 'Target $rate%';
  }

  @override
  String get attendanceOverviewReasonsTitle => 'Absence reasons';

  @override
  String get attendanceOverviewReasonsHint => 'school';

  @override
  String get attendanceOverviewReasonsCenterLabel => 'absences';

  @override
  String get attendanceOverviewReasonUnjustified => 'Unjustified';

  @override
  String get attendanceOverviewReasonUnjustifiedNote => 'UNKNOWN/null';

  @override
  String get attendanceOverviewWeekdayTitle => 'Absences by day';

  @override
  String get attendanceOverviewWeekdayHint => 'Mon → Fri';

  @override
  String get attendanceWeekdayMon => 'Mon';

  @override
  String get attendanceWeekdayTue => 'Tue';

  @override
  String get attendanceWeekdayWed => 'Wed';

  @override
  String get attendanceWeekdayThu => 'Thu';

  @override
  String get attendanceWeekdayFri => 'Fri';

  @override
  String get attendanceOverviewTopAbsentTitle => 'Most absent classes';

  @override
  String get attendanceOverviewTopAbsentHint => 'top 5';

  @override
  String get attendanceOverviewByClassTitle => 'Attendance by class';

  @override
  String get attendanceOverviewColClass => 'Class';

  @override
  String get attendanceOverviewColLevel => 'Level';

  @override
  String get attendanceOverviewColPresence => 'Attendance';

  @override
  String get attendanceOverviewColJustified => 'Justified';

  @override
  String get attendanceOverviewColUnjustified => 'Unjustified';

  @override
  String get attendanceOverviewColDistribution => 'Breakdown';

  @override
  String get attendanceOverviewEmptyTitle => 'No attendance data';

  @override
  String get attendanceOverviewEmptyDescription =>
      'No attendance has been recorded for this window. Statistics will appear as soon as the first attendance is taken.';

  @override
  String get attendanceOverviewEmptyAction => 'Take attendance';

  @override
  String get attendanceOverviewLoadingA11yLabel =>
      'Loading the attendance dashboard';

  @override
  String get dossierTabsA11yLabel => 'Student folder tabs';

  @override
  String get dossierTabDisciplineLabel => 'Discipline';

  @override
  String get dossierTabDisciplineDescription => 'Cases, sanctions & follow-up';

  @override
  String get dossierTabPresenceLabel => 'Attendance';

  @override
  String get dossierTabPresenceDescription => 'Absences & lateness';

  @override
  String dossierOpenCasesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open cases',
      one: '1 open case',
      zero: '0 open case',
    );
    return '$_temp0';
  }

  @override
  String get dossierNoOpenCases => 'No open case';

  @override
  String get genderOther => 'Other';

  @override
  String get scheduleErrorNoTeacher => 'No teacher is linked to your account.';

  @override
  String get scheduleErrorConflict =>
      'This time slot is already taken (teacher or class).';

  @override
  String get scheduleErrorGeneric =>
      'An error occurred while loading the timetable.';

  @override
  String get scheduleEmpty => 'No session scheduled.';

  @override
  String get scheduleEyebrow => 'Courses';

  @override
  String get scheduleTitle => 'My timetable';

  @override
  String get scheduleViewWeek => 'Week';

  @override
  String get scheduleViewDay => 'Day';

  @override
  String get scheduleViewToggleSemantics => 'Switch between Week and Day view';

  @override
  String get scheduleWeekTitle => 'Typical week';

  @override
  String scheduleLoadSummary(int count, double hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '$count session',
      zero: '$count sessions',
    );
    return '$_temp0 · $hoursString h of class';
  }

  @override
  String get scheduleToday => 'today';

  @override
  String get scheduleTodaySemantics => 'Today';

  @override
  String get scheduleBreak => 'Break';

  @override
  String get scheduleLoadingSemantics => 'Loading the timetable';

  @override
  String get scheduleEmptyDescription =>
      'No slot is scheduled for you this week. The timetable is managed by the academic office.';

  @override
  String get scheduleEmptyDayTitle => 'No class this day';

  @override
  String scheduleEmptyDayDescription(String day) {
    return 'No session is scheduled on $day.';
  }

  @override
  String get scheduleWeekdayLongMon => 'Monday';

  @override
  String get scheduleWeekdayLongTue => 'Tuesday';

  @override
  String get scheduleWeekdayLongWed => 'Wednesday';

  @override
  String get scheduleWeekdayLongThu => 'Thursday';

  @override
  String get scheduleWeekdayLongFri => 'Friday';

  @override
  String get scheduleWeekdayLongSat => 'Saturday';

  @override
  String get scheduleWeekdayShortMon => 'Mon';

  @override
  String get scheduleWeekdayShortTue => 'Tue';

  @override
  String get scheduleWeekdayShortWed => 'Wed';

  @override
  String get scheduleWeekdayShortThu => 'Thu';

  @override
  String get scheduleWeekdayShortFri => 'Fri';

  @override
  String get scheduleWeekdayShortSat => 'Sat';

  @override
  String get scheduleErrorNetworkTitle => 'Connection lost';

  @override
  String get scheduleErrorNetworkMessage =>
      'We couldn\'t reach the server. Check your connection and try again.';

  @override
  String get scheduleErrorUnauthorizedTitle => 'Session expired';

  @override
  String get scheduleErrorUnauthorizedMessage =>
      'Your session has expired. Reconnect to view the timetable.';

  @override
  String get scheduleErrorForbiddenTitle => 'Access denied';

  @override
  String get scheduleErrorForbiddenMessage =>
      'You don\'t have permission to view this timetable. Contact your administrator.';

  @override
  String get scheduleErrorServerTitle => 'Server error';

  @override
  String get scheduleErrorServerMessage =>
      'Something went wrong on the server. Try again in a moment.';

  @override
  String get scheduleErrorUnknownTitle => 'Something went wrong';

  @override
  String get scheduleErrorUnknownMessage =>
      'The timetable can\'t be loaded right now. Try again.';

  @override
  String get scheduleErrorRetry => 'Retry';

  @override
  String get scheduleErrorReconnect => 'Reconnect';

  @override
  String get scheduleErrorContactAdmin => 'Contact administrator';

  @override
  String scheduleErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get menuResultats => 'Results';

  @override
  String get subMenuResultatsClasse => 'Results by class';

  @override
  String get resultatsSearchEyebrow => 'Results';

  @override
  String get resultatsSearchTitle => 'Search results';

  @override
  String get resultatsSearchModeSemantics => 'Search mode';

  @override
  String get resultatsSearchByClass => 'By class';

  @override
  String get resultatsSearchByStudent => 'By student';

  @override
  String get resultatsSearchActionClasse => 'Show results';

  @override
  String get resultatsSearchActionEleve => 'Find the student';

  @override
  String get resultatsFieldLastName => 'Last name';

  @override
  String get resultatsFieldMiddleName => 'Middle name';

  @override
  String get resultatsFieldFirstName => 'First name(s)';

  @override
  String get resultatsFieldClassroom => 'Class';

  @override
  String get resultatsDecoupageTrimestres => 'Terms';

  @override
  String get resultatsDecoupageSemestres => 'Semesters';

  @override
  String get resultatsDecoupagePeriodes => 'Periods';

  @override
  String resultatsPeriodShortTrimestre(int ordre) {
    return 'T$ordre';
  }

  @override
  String resultatsPeriodShortSemestre(int ordre) {
    return 'S$ordre';
  }

  @override
  String resultatsPeriodShortGeneric(int ordre) {
    return 'P$ordre';
  }

  @override
  String resultatsPeriodLongTrimestre(int ordre) {
    return 'Term $ordre';
  }

  @override
  String resultatsPeriodLongSemestre(int ordre) {
    return 'Semester $ordre';
  }

  @override
  String resultatsPeriodLongGeneric(int ordre) {
    return 'Period $ordre';
  }

  @override
  String resultatsSubPeriodColumn(int ordre) {
    return 'P$ordre';
  }

  @override
  String get resultatsPeriodsError => 'Unable to load periods.';

  @override
  String get resultatsPeriodsEmpty => 'No period available.';

  @override
  String get resultatsGenderMale => 'Boy';

  @override
  String get resultatsGenderFemale => 'Girl';

  @override
  String get resultatsGenderOther => 'Other';

  @override
  String get resultatsDash => '—';

  @override
  String resultatsPercentValue(int value) {
    return '$value%';
  }

  @override
  String resultatsNoteOverMax(String note, String max) {
    return '$note/$max';
  }

  @override
  String resultatsPlaceValue(int place, int total) {
    return '$place / $total';
  }

  @override
  String resultatsDeltaPts(String value) {
    return '$value pts';
  }

  @override
  String get resultatsColumnRank => '#';

  @override
  String get resultatsColumnEleve => 'Student';

  @override
  String resultatsColumnMoyenne(String period) {
    return 'Average $period';
  }

  @override
  String get resultatsNonClasseBadge => 'Unranked';

  @override
  String resultatsSummaryAverageCaption(String period) {
    return 'Average · $period';
  }

  @override
  String resultatsSummaryReussites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passing',
      one: '1 passing',
      zero: '0 passing',
    );
    return '$_temp0';
  }

  @override
  String resultatsSummaryEchecs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failing',
      one: '1 failing',
      zero: '0 failing',
    );
    return '$_temp0';
  }

  @override
  String resultatsSummaryNonClasses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unranked',
      one: '1 unranked',
      zero: '0 unranked',
    );
    return '$_temp0';
  }

  @override
  String resultatsSummaryFootnote(int effectif, int seuil) {
    return '$effectif students · pass threshold $seuil%';
  }

  @override
  String resultatsEleveResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students found',
      one: '1 student found',
      zero: '0 students found',
    );
    return '$_temp0';
  }

  @override
  String resultatsFocusClassroom(String classroom) {
    return 'Class $classroom';
  }

  @override
  String get resultatsFocusBack => 'Back to class view';

  @override
  String get resultatsFocusAnnualAverage => 'Annual average';

  @override
  String resultatsFocusRankOf(int count) {
    return 'of $count ranked';
  }

  @override
  String get resultatsFocusNoBulletin =>
      'Student unranked for this period: no detailed report.';

  @override
  String get resultatsProgressionTitle => 'Progress over the year';

  @override
  String resultatsProgressionPointLabel(int index) {
    return 'P$index';
  }

  @override
  String get resultatsStrengthsTitle => 'Strengths';

  @override
  String get resultatsWeaknessesTitle => 'To improve';

  @override
  String get resultatsOfficialBulletinTitle => 'Official report card';

  @override
  String get resultatsOfficialBulletinSubtitle =>
      'Domains & subjects, coursework + exam marks, maxima, rank — printable national template.';

  @override
  String get resultatsComingSoon => 'Coming soon';

  @override
  String resultatsBulletinTitle(String period) {
    return 'Report by domain · $period';
  }

  @override
  String get resultatsBulletinLegend => 'mark / maximum';

  @override
  String get resultatsBulletinSubtotal => 'Subtotal';

  @override
  String get resultatsBulletinTotal => 'Totals obtained';

  @override
  String get resultatsSynthesePercent => 'Percentage';

  @override
  String get resultatsSynthesePlace => 'Rank';

  @override
  String get resultatsSyntheseApplication => 'Application';

  @override
  String get resultatsSyntheseConduite => 'Conduct';

  @override
  String get resultatsIdleTitle => 'Choose a class or a student';

  @override
  String get resultatsIdleDescription =>
      'Select a cycle, a level and a class, then a period to display the results.';

  @override
  String get resultatsLoadingSemantics => 'Loading results';

  @override
  String get resultatsEmptyClasse => 'No students to display for this class.';

  @override
  String get resultatsEmptyClasseTitle => 'No results for this class';

  @override
  String get resultatsEmptyEleveTitle => 'No students found';

  @override
  String get resultatsEmptyEleveDescription =>
      'Check the spelling of the last, middle or first name, or broaden your search.';

  @override
  String get resultatsEmptyAdjustAction => 'Adjust search';

  @override
  String get resultatsErrorRetry => 'Try again';

  @override
  String get resultatsErrorReconnect => 'Sign in again';

  @override
  String get resultatsErrorContactAdmin => 'Contact the administrator';

  @override
  String resultatsErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get resultatsErrorNetworkTitle => 'Connection lost';

  @override
  String get resultatsErrorNetworkMessage =>
      'Check your internet connection and try again.';

  @override
  String get resultatsErrorUnauthorizedTitle => 'Session expired';

  @override
  String get resultatsErrorUnauthorizedMessage =>
      'Your session has expired. Sign in again to continue.';

  @override
  String get resultatsErrorForbiddenTitle => 'Access denied';

  @override
  String get resultatsErrorForbiddenMessage =>
      'You don\'t have the required permissions to view these results.';

  @override
  String get resultatsErrorServerTitle => 'Server error';

  @override
  String get resultatsErrorServerMessage =>
      'Something went wrong on our side. Please try again shortly.';

  @override
  String get resultatsErrorUnknownTitle => 'Something went wrong';

  @override
  String get resultatsErrorUnknownMessage =>
      'An unexpected problem occurred. Please try again.';

  @override
  String get syncErrorsOtherAccountTitle => 'Waiting for another account';

  @override
  String syncErrorsOtherAccountNamed(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count writes waiting for $name',
      one: '$count write waiting for $name',
    );
    return '$_temp0';
  }

  @override
  String syncErrorsOtherAccountAnonymous(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count writes waiting for another account',
      one: '$count write waiting for another account',
    );
    return '$_temp0';
  }

  @override
  String syncErrorsOtherAccountOldest(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'oldest from $dateString';
  }

  @override
  String get syncErrorsOtherAccountHint =>
      'They will be sent when that account signs back in on this tablet.';

  @override
  String syncErrorsForeignEntry(String name) {
    return 'Written by $name — it has to be retried from their own session.';
  }

  @override
  String get syncErrorsForeignEntryAnonymous =>
      'Written by another account — it has to be retried from that session.';

  @override
  String get syncSheetStatusTitle => 'Sync status';

  @override
  String get syncSheetStatusSubtitle =>
      'What this tablet has not received, and the writes the server refused — those will not go back on their own.';

  @override
  String get syncIncompleteReadTitle => 'Some data is not coming down';

  @override
  String get syncIncompleteReadDescription =>
      'The last update did not bring everything back. Some screens may therefore look empty without really being so. Nothing you have entered is lost. If this persists, your administrator can check your account\'s access rights.';

  @override
  String get syncIncompleteReadRetriableDescription =>
      'The last update stopped before bringing everything back. Some screens may therefore look empty without really being so. Nothing you have entered is lost.';

  @override
  String get syncIncompleteReadRetry => 'Try again';

  @override
  String get syncErrorsHeldTitle => 'Waiting';

  @override
  String get syncErrorsHeldSubtitle =>
      'These writes are kept and will be sent as soon as their condition clears.';

  @override
  String get editiqueViewerReceiptTitle => 'Payment receipt';

  @override
  String get editiqueViewerLoadingTitle => 'Preparing the document…';

  @override
  String get editiqueViewerLoadingMessage =>
      'The server is producing the document. This may take a few seconds.';

  @override
  String get editiqueViewerPrintLabel => 'Print';

  @override
  String get editiqueViewerShareLabel => 'Share';

  @override
  String get editiqueViewerCloseLabel => 'Close';

  @override
  String get editiqueViewerActionFailed =>
      'This action could not be completed on this device.';

  @override
  String editiqueViewerDocumentNumberLabel(String number) {
    return 'Document no. $number';
  }

  @override
  String get editiqueErrorNetworkTitle => 'No connection';

  @override
  String get editiqueErrorNetworkMessage =>
      'The document is produced by the server. Reconnect and try again — nothing was issued.';

  @override
  String get editiqueErrorUncertainTitle => 'Undetermined outcome';

  @override
  String get editiqueErrorUncertainMessage =>
      'The server did not answer in time. The document may have been issued: check before generating a new one.';

  @override
  String get editiqueErrorSessionExpiredTitle => 'Session expired';

  @override
  String get editiqueErrorSessionExpiredMessage =>
      'Sign in again to resume issuing the document.';

  @override
  String get editiqueErrorForbiddenTitle => 'Access denied';

  @override
  String get editiqueErrorForbiddenMessage =>
      'You do not have the rights required to issue this document.';

  @override
  String get editiqueErrorNotFoundTitle => 'Document unavailable';

  @override
  String get editiqueErrorNotFoundMessage =>
      'The server cannot find the elements required for this document.';

  @override
  String get editiqueErrorInvalidTitle => 'Cannot be issued';

  @override
  String get editiqueErrorInvalidMessage =>
      'The server rejected the request. Check the file before trying again.';

  @override
  String get editiqueErrorServerTitle => 'Server error';

  @override
  String get editiqueErrorServerMessage =>
      'The document could not be produced. Try again shortly.';

  @override
  String get editiqueErrorRetryLabel => 'Try again';

  @override
  String get editiqueErrorReconnectLabel => 'Sign in again';

  @override
  String get editiqueViewerStatementTitle => 'Account statement';

  @override
  String get editiqueViewerAttestationTitle => 'Enrolment certificate';

  @override
  String get editiqueViewerNotePerceptionTitle => 'Fee notice';

  @override
  String get editiqueViewerClearanceTitle => 'Financial clearance';

  @override
  String editiqueErrorServerDetailLabel(String detail) {
    return 'Reason returned by the server: $detail';
  }

  @override
  String get facturationDetailStatementLabel => 'Account statement';

  @override
  String get facturationDetailStatementNoChargesHint =>
      'No fee for the year: the statement cannot be produced.';

  @override
  String get facturationDetailStatementPendingSyncHint =>
      'Student not synced yet: the statement will be available after the next sync.';

  @override
  String get facturationDetailStatementOfflineHint =>
      'Offline: the statement is produced by the server.';

  @override
  String get facturationDetailStatementConfirmTitle =>
      'Generate an account statement?';

  @override
  String get facturationDetailStatementConfirmMessage =>
      'The server will produce a new numbered document, dated now. Statements already handed out remain valid — they are not replaced.';

  @override
  String get facturationDetailStatementConfirmAction => 'Generate';

  @override
  String get facturationDetailStatementConfirmCancel => 'Cancel';

  @override
  String get menuDocuments => 'Documents';

  @override
  String get subMenuDocumentsStudent => 'Student documents';

  @override
  String get documentsSearchTitle => 'Student documents';

  @override
  String get documentsSearchHelpBanner =>
      'Search for one student, or a whole class, then open their document catalogue.';

  @override
  String get documentsSearchCycleLabel => 'Cycle';

  @override
  String get documentsSearchLevelLabel => 'Level';

  @override
  String get documentsSearchLevelPlaceholder => 'Pick a cycle first';

  @override
  String get documentsSearchInvitationTitle =>
      'Find the student, open their documents';

  @override
  String get documentsSearchInvitationMessage =>
      'Enrolment certificate, fee notice, payment receipt, account statement and financial clearance: the documents issuable for a student.';

  @override
  String get documentsEmptyTitle => 'No student found';

  @override
  String get documentsNoResultsDescription =>
      'No student enrolled this year matches these criteria.';

  @override
  String get documentsOpenCatalogLabel => 'Open documents';

  @override
  String get documentsCatalogEyebrow => 'Documents';

  @override
  String get documentsCatalogUnknownStudent => 'Student';

  @override
  String get documentsGroupScolariteTitle => 'Schooling';

  @override
  String get documentsGroupScolariteSubtitle => 'Enrolment file';

  @override
  String get documentsGroupFinancesTitle => 'Finance';

  @override
  String get documentsGroupFinancesSubtitle =>
      'Fee notices, receipts and settlement certificates';

  @override
  String get documentsNatureArchivedLabel => 'Archived';

  @override
  String get documentsNatureTimestampedLabel => 'Timestamped';

  @override
  String get documentsHintAttestation =>
      'Archived document: asking again serves exactly the same file, under the same number.';

  @override
  String get documentsHintNotePerception =>
      'Immutable accounting document, issued once per student and per year.';

  @override
  String get documentsHintReceipt =>
      'One receipt per payment. It is issued from Billing, when the cash is taken in.';

  @override
  String get documentsHintStatement =>
      'Snapshot of the account at the time of the request: every issue produces a new numbered document.';

  @override
  String get documentsHintClearance =>
      'Certifies the student is settled as of the request date. Not archived, renumbered on every issue.';

  @override
  String get documentsActionEmitLabel => 'Issue';

  @override
  String get documentsActionConsultLabel => 'View';

  @override
  String get documentsActionGenerateLabel => 'Generate now';

  @override
  String get documentsActionBusyLabel => 'Generating…';

  @override
  String get documentsActionFailedNotice =>
      'Generation failed. The document was not produced.';

  @override
  String get documentsBlockedPendingSyncNotice =>
      'Student not synced yet: the document will be available after the next sync.';

  @override
  String get documentsBlockedEnrollmentPendingSyncNotice =>
      'Enrolment not synced yet: the certificate will be available after the next sync.';

  @override
  String get documentsBlockedMissingEnrollmentNotice =>
      'Enrolment not reachable from this link: reopen the student from the list.';

  @override
  String get documentsBlockedOfflineNotice =>
      'Offline: this document is produced by the server.';

  @override
  String documentsConfirmGenerateTitle(String document) {
    return 'Generate: $document?';
  }

  @override
  String get documentsConfirmGenerateMessage =>
      'The server will produce a new numbered document, dated now. Documents already handed out remain valid — they are not replaced.';

  @override
  String get documentsConfirmClearanceWarning =>
      'The clearance is issued whatever the balance: a student who is not settled will receive a document marked “NOT SETTLED”.';

  @override
  String get documentsConfirmGenerateAction => 'Generate';

  @override
  String get documentsConfirmGenerateCancel => 'Cancel';

  @override
  String documentsLastIssueSubtitle(String date, String reference) {
    return 'Last issued $date · ref. $reference';
  }

  @override
  String documentsCancelledNotice(String date) {
    return 'Document cancelled by the school on $date.';
  }

  @override
  String documentsCancelledWithReasonNotice(String date, String reason) {
    return 'Document cancelled by the school on $date — $reason';
  }

  @override
  String facturationReceiptCancelledNotice(String date) {
    return 'Receipt cancelled by the school on $date.';
  }

  @override
  String facturationReceiptCancelledWithReasonNotice(
    String date,
    String reason,
  ) {
    return 'Receipt cancelled by the school on $date — $reason';
  }

  @override
  String get ticketDocumentTitle => 'Collection ticket';

  @override
  String get ticketProvisionalBanner => 'Provisional';

  @override
  String get ticketReferenceLabel => 'Ref.';

  @override
  String get ticketCashierLabel => 'Cashier:';

  @override
  String get ticketStudentLabel => 'Student:';

  @override
  String get ticketMatriculationLabel => 'Student no.:';

  @override
  String get ticketClassroomLabel => 'Class:';

  @override
  String get ticketAmountReceivedLabel => 'Amount received';

  @override
  String get ticketAllocationsLabel => 'Breakdown';

  @override
  String get ticketRateLabel => 'Rate';

  @override
  String get ticketDerivedAmountPrefix => 'i.e.';

  @override
  String get ticketAdvanceLabel => 'Advance (unallocated)';

  @override
  String get ticketBalanceLabel => 'Balance';

  @override
  String get ticketBalanceReservation => 'subject to synchronisation';

  @override
  String get ticketKeepNotice =>
      'Keep this ticket until you receive your final receipt.';

  @override
  String get ticketPrintLabel => 'Print collection ticket';

  @override
  String get ticketPrintFailed =>
      'Printing unavailable: the ticket could not be produced.';

  @override
  String get ticketRefusedUnknownStudent =>
      'Printing refused: this tablet does not know the student\'s name. The payment is recorded — print again after the next sync.';

  @override
  String get ticketCutNotice => 'Cut along the frame.';

  @override
  String get ticketPrinterPickerTitle => 'Choose the printer';

  @override
  String get ticketPrinterUnnamed => 'Unnamed printer';

  @override
  String get ticketPrinterProblemPermission =>
      'Nearby devices permission denied — printing as PDF instead.';

  @override
  String get ticketPrinterProblemBluetoothOff =>
      'Bluetooth is off — printing as PDF instead.';

  @override
  String get ticketPrinterProblemNoPrinter =>
      'No paired printer — printing as PDF instead.';

  @override
  String get ticketPrinterProblemUnreachable =>
      'Printer unreachable, off or out of range — printing as PDF instead.';

  @override
  String get paymentAnomalyBannerTitle => 'Overpayment to arbitrate';

  @override
  String get paymentAnomalyBannerFallback =>
      'A payment exceeds the amount still due.';

  @override
  String get paymentAnomalyAcknowledgeLabel => 'Handled';

  @override
  String paymentAnomalyOthersPending(int count) {
    return '$count more pending';
  }

  @override
  String get documentsBlockedEnrollmentUnreadableNotice =>
      'Enrolment not readable on this tablet: the certificate is unavailable here.';

  @override
  String get boutiqueEyebrow => 'Shop ▸ Purchases';

  @override
  String get boutiqueTitle => 'Till';

  @override
  String get boutiqueSubtitle =>
      'Cash sale of school items. No debt, no balance.';

  @override
  String get boutiqueSearchPlaceholder => 'Search an item or a code…';

  @override
  String get boutiqueFilterAll => 'All';

  @override
  String get boutiqueFamilyUniforme => 'Uniform';

  @override
  String get boutiqueFamilyFournitures => 'Supplies';

  @override
  String get boutiqueFamilyActivites => 'Activities';

  @override
  String get boutiqueFamilyActes => 'Administrative';

  @override
  String boutiqueArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String boutiqueInCartBadge(int count) {
    return '$count in cart';
  }

  @override
  String get boutiqueLevelBadge => 'by level';

  @override
  String boutiquePriceRange(String min, String max) {
    return '$min – $max';
  }

  @override
  String get boutiqueGridReminder =>
      'Prices always come from the catalogue grid. At the till you pick a student or a level — never an amount.';

  @override
  String get boutiqueCartTitle => 'Cart';

  @override
  String get boutiqueCartEmpty => 'Cart is empty. Tap an item to add it.';

  @override
  String get boutiqueCartClear => 'Empty the cart';

  @override
  String get boutiqueTotalLabel => 'Total to collect';

  @override
  String get boutiqueCollectAction => 'Collect in cash';

  @override
  String get boutiquePriceUnresolved => 'Price unresolved';

  @override
  String get boutiqueLevelRequired => 'Level required…';

  @override
  String get boutiqueBeneficiaryPlaceholder => 'Recipient';

  @override
  String get boutiqueSizeLabel => 'Size';

  @override
  String boutiqueLineMeta(String unitPrice, int quantity) {
    return '$unitPrice × $quantity';
  }

  @override
  String get boutiquePayerSection => 'Payer';

  @override
  String get boutiquePayerKnownBadge => 'Known payer';

  @override
  String get boutiquePayerPhoneLabel => 'Phone';

  @override
  String get boutiquePayerLastNameLabel => 'Last name';

  @override
  String get boutiquePayerMiddleNameLabel => 'Middle name';

  @override
  String get boutiquePayerFirstNameLabel => 'First name';

  @override
  String get boutiquePayerReceiptNotice =>
      'The receipt is in the payer\'s name; recipients are attached to each line.';

  @override
  String get boutiquePayerUnknownNotice =>
      'Unknown number — this payer will be added to the directory with the sale.';

  @override
  String get boutiqueBlockersPrefix => 'Still missing:';

  @override
  String get boutiqueBlockerEmptyCart => 'Cart is empty';

  @override
  String get boutiqueBlockerLastName => 'Last name';

  @override
  String get boutiqueBlockerMiddleName => 'Middle name';

  @override
  String get boutiqueBlockerFirstName => 'First name';

  @override
  String get boutiqueBlockerPhone => 'Payer\'s phone';

  @override
  String get boutiqueBlockerPhoneIncomplete => 'Incomplete phone';

  @override
  String boutiqueBlockerLinesWithoutLevel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines without a level',
      one: '1 line without a level',
    );
    return '$_temp0';
  }

  @override
  String get boutiqueBlockerMixedCurrency => 'Mixed currencies';

  @override
  String get boutiqueEmptyCatalogTitle => 'No item in the catalogue';

  @override
  String get boutiqueEmptyCatalogMessage =>
      'The shop has no item yet. Create one in the catalogue to be able to make a sale.';

  @override
  String get boutiqueWithheldCatalogTitle => 'Catalogue not shared';

  @override
  String get boutiqueWithheldCatalogMessage =>
      'Your account is not allowed to read the shop catalogue. Ask the head office for it: without it, nothing can be sold from this till.';

  @override
  String get boutiqueNoMatchTitle => 'No matching item';

  @override
  String boutiqueNoMatchMessage(String query, String family) {
    return 'Nothing for “$query” in “$family”. Broaden the search.';
  }

  @override
  String boutiqueNoMatchMessageAll(String query) {
    return 'Nothing for “$query”. Broaden the search.';
  }

  @override
  String get boutiqueResetFilters => 'Reset filters';

  @override
  String boutiqueUnsellableNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items in this catalogue cannot be sold from this version of the app.',
      one:
          '1 item in this catalogue cannot be sold from this version of the app.',
    );
    return '$_temp0';
  }

  @override
  String get boutiqueErrorNetworkTitle => 'No connection';

  @override
  String get boutiqueErrorNetwork =>
      'The catalogue could not be read. The cart in progress is kept: a network drop never loses a sale being composed.';

  @override
  String get boutiqueErrorUnauthorizedTitle => 'Session expired';

  @override
  String get boutiqueErrorUnauthorized =>
      'Sign in again to resume the till. The cart is kept.';

  @override
  String get boutiqueErrorForbiddenTitle => 'Access denied';

  @override
  String get boutiqueErrorForbidden =>
      'Your account lacks the rights to run the shop till. Contact the head office.';

  @override
  String get boutiqueErrorServerTitle => 'Catalogue unreadable';

  @override
  String get boutiqueErrorServer =>
      'The local catalogue could not be read. Try again; if it does not come back, a sync will rebuild it.';

  @override
  String get boutiqueErrorRetry => 'Try again';

  @override
  String get boutiqueErrorReconnect => 'Sign in again';

  @override
  String boutiqueErrorIncidentCode(String code) {
    return 'Incident code: $code';
  }

  @override
  String get boutiqueBeneficiaryEyebrow => 'Line recipient';

  @override
  String get boutiqueBeneficiaryTitle => 'Pick a student';

  @override
  String get boutiqueBeneficiaryHint =>
      'The student\'s level resolves the price automatically — you never enter an amount.';

  @override
  String get boutiqueBeneficiarySearchLabel =>
      'Last name, middle name or first name';

  @override
  String get boutiqueBeneficiarySearchPlaceholder => 'e.g. Dylan Ndombo';

  @override
  String get boutiqueBeneficiaryTooShort =>
      'Type at least 2 letters, or switch to “By level”.';

  @override
  String boutiqueBeneficiaryNoResult(String query) {
    return 'No student matches “$query”. Check the spelling or search by level.';
  }

  @override
  String get boutiqueBeneficiaryPickLevel =>
      'Pick a level to list its students.';

  @override
  String get boutiqueBeneficiaryLevelEmpty =>
      'No student enrolled at this level.';

  @override
  String get boutiqueBeneficiaryNotSynced =>
      'Enrolment not synced yet — sell by level, without a recipient: the price is the same.';

  @override
  String get boutiqueBeneficiaryNoLevel =>
      'This enrolment carries no level — sell by level, without a recipient.';

  @override
  String get boutiqueBeneficiaryLoadFailed =>
      'The student list could not be read.';

  @override
  String boutiquePayerDirectoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return 'Already in the directory · $_temp0';
  }

  @override
  String get boutiquePayerUse => 'Use';

  @override
  String get boutiqueConfirmEyebrow => 'Cash collection';

  @override
  String get boutiqueConfirmTitle => 'Confirm the sale';

  @override
  String get boutiqueConfirmPayer => 'Payer';

  @override
  String get boutiqueConfirmPhone => 'Phone';

  @override
  String get boutiqueConfirmArticles => 'Items';

  @override
  String get boutiqueConfirmMethod => 'Method';

  @override
  String get boutiqueConfirmMethodCash => 'Cash';

  @override
  String get boutiqueConfirmAmountReceived => 'Amount received';

  @override
  String get boutiqueConfirmNotice =>
      'The total is paid in one go: no partial payment, no shop debt.';

  @override
  String get boutiqueConfirmNewPayerPrefix =>
      'This payer is new: their number and identity join the directory with the sale.';

  @override
  String get boutiqueConfirmOfflineSuffix =>
      'Offline: a provisional ticket is printed, and the final receipt will be sealed on sync.';

  @override
  String get boutiqueConfirmCancel => 'Cancel';

  @override
  String boutiqueConfirmAction(String total) {
    return 'Collect $total';
  }

  @override
  String boutiqueSaleRecorded(String total) {
    return 'Sale collected · $total';
  }

  @override
  String get boutiqueSaleFailed =>
      'The sale could not be recorded. Nothing was collected — try again.';

  @override
  String get editiqueViewerSaleReceiptTitle => 'Sale receipt';

  @override
  String get documentsHintSaleReceipt =>
      'Receipt for a shop sale. It concerns neither tuition nor school fees, and is found from the till — not from a student\'s file.';

  @override
  String get boutiqueTicketTitle => 'Sale receipt — Shop';

  @override
  String get boutiqueTicketProvisionalBanner => 'Provisional document';

  @override
  String get boutiqueTicketProvisionalNotice => 'Final receipt sealed on sync.';

  @override
  String get boutiqueTicketSealedNotice => 'Sealed receipt — valid discharge';

  @override
  String get boutiqueTicketPayerLabel => 'PAYER:';

  @override
  String get boutiqueTicketPhoneLabel => 'Tel.';

  @override
  String get boutiqueTicketCashierLabel => 'Cashier:';

  @override
  String get boutiqueTicketTotalLabel => 'TOTAL';

  @override
  String get boutiqueTicketCashReceivedLabel => 'Cash received';

  @override
  String get boutiqueTicketRemainingLabel => 'Remaining';

  @override
  String get boutiqueTicketBeneficiaryPrefix => 'for';

  @override
  String get boutiqueTicketSizePrefix => 'Sz.';

  @override
  String get boutiqueTicketUnitSuffix => '/ea';

  @override
  String get boutiqueTicketNoRefundNotice =>
      'No refund once the item is handed over.';

  @override
  String boutiqueReceiptBannerTitle(String total) {
    return 'Sale collected · $total';
  }

  @override
  String boutiqueReceiptBannerProvisional(String reference) {
    return '$reference · provisional, will be sealed on sync';
  }

  @override
  String boutiqueReceiptBannerSealed(String reference) {
    return '$reference · sealed';
  }

  @override
  String get boutiqueReceiptPrint => 'Print';

  @override
  String get boutiqueReceiptNewSale => 'New sale';

  @override
  String get boutiqueReceiptPrintFailed =>
      'The ticket could not be printed. The sale is recorded — you can try again.';

  @override
  String get boutiqueReceiptPrinted => 'Ticket printed.';

  @override
  String get boutiqueOpenCart => 'View the cart';

  @override
  String boutiqueOpenCartWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'View the cart, $_temp0';
  }

  @override
  String get boutiqueCartPageEyebrow => 'Shop ▸ Cart';

  @override
  String get boutiqueBackToCatalog => 'Back to catalogue';

  @override
  String get boutiqueAddToCart => 'Add to cart';

  @override
  String boutiqueAddOneMore(String article) {
    return 'Add one $article';
  }

  @override
  String boutiqueRemoveOne(String article) {
    return 'Remove one $article';
  }

  @override
  String get boutiqueSuccessTitle => 'Sale collected';

  @override
  String boutiqueSuccessMessage(String total) {
    return 'The customer paid $total in cash. Hand them their ticket.';
  }

  @override
  String get boutiqueSuccessDone => 'Done';

  @override
  String get boutiqueHistoryEyebrow => 'Shop ▸ History';

  @override
  String get boutiqueHistoryTitle => 'Sales history';

  @override
  String get boutiqueHistoryPeriodDay => 'Today';

  @override
  String get boutiqueHistoryPeriodWeek => 'This week';

  @override
  String get boutiqueHistoryPeriodMonth => 'This month';

  @override
  String get boutiqueHistoryPeriodYear => 'This year';

  @override
  String boutiqueHistorySaleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0';
  }

  @override
  String boutiqueHistoryArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String boutiqueHistoryPendingNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales have not reached the server yet.',
      one: '1 sale has not reached the server yet.',
    );
    return '$_temp0';
  }

  @override
  String get boutiqueHistoryPendingBadge => 'Pending';

  @override
  String get boutiqueHistoryEmptyTitle => 'No sale in this period';

  @override
  String get boutiqueHistoryEmptyMessage =>
      'Nothing was collected at the counter. Widen the period, or open the shop to collect.';

  @override
  String get boutiqueHistoryPayerUnknown => 'Payer not recorded';

  @override
  String get boutiqueHistoryTotalLabel => 'Total collected';

  @override
  String boutiqueHistorySaleTime(String time, String reference) {
    return '$time · $reference';
  }

  @override
  String get boutiqueHistoryProvisional => 'provisional ticket';

  @override
  String get boutiqueHistoryErrorServerTitle => 'History unreadable';

  @override
  String get boutiqueHistoryErrorServer =>
      'The local till could not be read. Try again; no sale is lost — they are written to the database, only reading them back failed.';

  @override
  String get boutiqueHistoryErrorNetwork =>
      'History is read locally and does not need the network. Try again; if it does not come back, the local database is at fault.';

  @override
  String get boutiqueClearEyebrow => 'Shop ▸ Cart';

  @override
  String get boutiqueClearTitle => 'Empty the cart?';

  @override
  String get boutiqueClearMessage =>
      'The composed lines and the payer\'s identity will be cleared. Nothing has been collected yet — so there is nothing to reverse on the money side.';

  @override
  String boutiqueClearLinesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 in the cart';
  }

  @override
  String boutiqueClearPayerSummary(String payer) {
    return 'Payer entered: $payer';
  }

  @override
  String get boutiqueClearCancel => 'Keep the cart';

  @override
  String get boutiqueClearConfirm => 'Empty';

  @override
  String get boutiqueSuccessEyebrow => 'Shop ▸ Collection';

  @override
  String get boutiqueSaleDetailEyebrow => 'Shop ▸ Sale';

  @override
  String get boutiqueSaleDetailTitle => 'Sale details';

  @override
  String get boutiqueSaleDetailBack => 'Back to history';

  @override
  String get boutiqueSaleDetailPayer => 'Payer';

  @override
  String get boutiqueSaleDetailPhone => 'Phone';

  @override
  String get boutiqueSaleDetailSoldAt => 'Collected on';

  @override
  String get boutiqueSaleDetailCollectedBy => 'Collected by';

  @override
  String get boutiqueSaleDetailCollectedByUnknown => 'Cashier not recorded';

  @override
  String get boutiqueSaleDetailReceipt => 'Receipt';

  @override
  String get boutiqueSaleDetailLines => 'Items sold';

  @override
  String boutiqueSaleDetailBeneficiary(String name) {
    return 'for $name';
  }

  @override
  String boutiqueSaleDetailSizePrefix(String size) {
    return 'Size $size';
  }

  @override
  String get boutiqueSaleDetailPrintTicket => 'Print the ticket';

  @override
  String get boutiqueSaleDetailReprintTicket => 'Reprint the ticket';

  @override
  String boutiqueSaleDetailTicketPrintedAt(String date) {
    return 'Ticket printed on $date';
  }

  @override
  String get boutiqueSaleDetailTicketNeverPrinted =>
      'Ticket never printed from this tablet.';

  @override
  String get boutiqueSaleDetailOpenReceipt => 'Open the sealed receipt';

  @override
  String get boutiqueSaleDetailReceiptPending =>
      'The receipt will be sealed at synchronisation. The ticket stands in the meantime.';

  @override
  String get boutiqueSaleDetailReceiptTitle => 'Sale receipt';

  @override
  String get boutiqueSaleDetailNotFoundTitle => 'Sale not found';

  @override
  String get boutiqueSaleDetailNotFound =>
      'This sale is no longer in this school\'s local database. Nothing is lost server-side if it had already been sent.';

  @override
  String get boutiqueSaleDetailPendingNotice =>
      'This sale has not reached the server yet. It will be sent at the next synchronisation, with no action needed.';
}
