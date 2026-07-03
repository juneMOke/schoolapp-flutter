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
    );
    String _temp1 = intl.Intl.pluralLogic(
      courseCount,
      locale: localeName,
      other: '$courseCount courses',
      one: '1 course',
    );
    return '$_temp0 · $_temp1';
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
  String get evalCreateChapitresComingSoon => 'Coming soon';

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
    );
    return '$_temp0 with the “Pending” status.';
  }

  @override
  String get evalCreateSuccessToast => 'Evaluation created';

  @override
  String get evalCreateErrorToast =>
      'Creating the evaluation failed. Please try again.';

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
  String get disciplinaryCaseClosedLabel => 'Case closed';

  @override
  String disciplinaryCasesCountPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cases',
      one: '1 case',
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
  String get disciplinaryFolderBreadcrumb => 'Discipline list';

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
}
