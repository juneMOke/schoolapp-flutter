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
  String get bootstrapOfflineBanner => 'Offline mode — cached data';

  @override
  String get splashErrorTitle => 'Connection failed';

  @override
  String get splashErrorMessage =>
      'Unable to load the application data. Check your connection, then try again.';

  @override
  String get splashErrorRetry => 'Retry';

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
  String get classesOrganisationTransferSuccess =>
      'Transfer completed successfully.';

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
  String get classesListFirstNameOptionalLabel => 'First name (optional)';

  @override
  String get classesListLastNameOptionalLabel => 'Last name (optional)';

  @override
  String get classesListSurnameOptionalLabel => 'Surname (optional)';

  @override
  String get classesListInitialEmptyTitle => 'No search in progress';

  @override
  String get classesListInitialEmptyMessage =>
      'Fill in at least one criterion to display students.';

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
  String get accueilBannerContextTail =>
      'Here is the essential view of your school today.';

  @override
  String get accueilModulesEyebrow => 'Your modules';

  @override
  String get accueilModulesTitle => 'Where would you like to go?';

  @override
  String get accueilModulesIntro =>
      'Four modules cover the administrative life of the school. Everything stays accessible from the side menu.';

  @override
  String get accueilModuleInscriptionsDescription =>
      'New enrolments, re-enrolments and pre-enrolments for your students.';

  @override
  String get accueilModuleFinancesDescription =>
      'Revenue, invoicing and tracking of school fee collection.';

  @override
  String get accueilModuleClassesDescription =>
      'Class composition and student lists by cycle.';

  @override
  String get accueilModuleDisciplinesDescription =>
      'Daily attendance, disciplinary records and student follow-up.';

  @override
  String accueilModuleCardSemantics(String module) {
    return '$module — open the dashboard';
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
  String get searchFormSubtitlePreRegistration =>
      'Online requests received, pending validation';

  @override
  String get reRegistrationSearchHint =>
      'Find a student or a class from the previous year to re-enroll';

  @override
  String get reRegistrationSearchHelpPill =>
      'Find a specific student (last name + middle name + first name) or a whole class from the previous year (cycle + level) to re-enroll for the new year. You can also combine both.';

  @override
  String get reRegistrationSearchTitle => 'Search a student';

  @override
  String get reRegistrationSearchByNameGroup => 'By name';

  @override
  String get reRegistrationSearchByLevelGroup => 'By cycle / level';

  @override
  String get reRegistrationSearchOrSeparator => 'OR';

  @override
  String get reRegistrationSearchActiveModeLabel => 'Active search by:';

  @override
  String get reRegistrationSearchModeNameBadge => 'Name';

  @override
  String get reRegistrationSearchModeLevelBadge => 'Cycle / level';

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
  String get enrollmentDetailLoadErrorFallback =>
      'An error occurred while loading enrollment details.';

  @override
  String get enrollmentDetailRetryAction => 'Retry';

  @override
  String get enrollmentDetailNotFoundTitle => 'Details not found';

  @override
  String get enrollmentDetailNotFoundMessage =>
      'This enrollment file does not exist or is no longer available.';

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
  String get enrollmentStatusUpdateSuccess => 'Status updated successfully.';

  @override
  String enrollmentStatusUpdateError(String message) {
    return 'Failed to update status: $message';
  }

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
  String get enrollmentReadOnlyMessage =>
      'Student already enrolled — record can be viewed but not edited. Browse the steps to review the information.';

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
  String get facturationEmptyTitle => 'No student found';

  @override
  String get facturationSearchHelpBanner =>
      'Search for a specific student (last name + middle name + first name) or a whole class (cycle + level). You can also combine both to refine.';

  @override
  String get facturationSearchByStudentGroup => 'By student';

  @override
  String get facturationSearchByClassGroup => 'By class';

  @override
  String get facturationSearchOrSeparator => 'OR';

  @override
  String get facturationSearchActiveModeLabel => 'Active search by:';

  @override
  String get facturationSearchModeStudentBadge => 'Student';

  @override
  String get facturationSearchModeClassBadge => 'Class';

  @override
  String get facturationSearchCycleLabel => 'Cycle';

  @override
  String get facturationSearchLevelLabel => 'Level';

  @override
  String get facturationSearchLevelPlaceholder => 'Pick a cycle first';

  @override
  String facturationBalanceDuePill(String amount) {
    return '$amount due';
  }

  @override
  String get facturationBalanceUpToDatePill => 'Up to date';

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
  String get facturationPaymentReceiptLabel => 'Receipt no.';

  @override
  String get facturationPaymentStudentLabel => 'Student';

  @override
  String get facturationPaymentDownloadReceiptLabel => 'Download receipt';

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
  String get attendanceMarkAllPresentAction => 'All present';

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
  String get absenceReasonUnknown => 'Unknown';

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
  String get disciplinaryAttendanceHistoryComingSoon =>
      'Attendance history will be delivered in a future feature.';

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
  String get statusSyncing => 'Syncing…';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusPendingUpload => 'Pending upload';

  @override
  String get statusSyncConflict => 'Conflict';

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
  String get enrollmentStatsSectionLevelEvolution => 'Evolution by level';

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
  String get financeStatsKpiCollected => 'Total collected';

  @override
  String get financeStatsKpiExpected => 'Total expected';

  @override
  String get financeStatsKpiOutstanding => 'Outstanding';

  @override
  String get financeStatsKpiCollectionRate => 'Collection rate';

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
  String get financeStatsErrorTitle => 'Loading error';

  @override
  String get financeStatsRetry => 'Retry';

  @override
  String get financeStatsRetryHint => 'Reload finance statistics';

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
    int rate,
  ) {
    return 'Type $code, collected $collected, expected $expected, rate $rate%';
  }

  @override
  String financeStatsErrorA11yLabel(String message) {
    return 'Finance statistics loading error: $message';
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
}
