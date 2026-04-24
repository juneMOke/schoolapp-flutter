import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';

class EnrollmentPersonalInfoPayload {
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String birthPlace;
  final String nationality;
  final String gender;

  const EnrollmentPersonalInfoPayload({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.birthPlace,
    required this.nationality,
    required this.gender,
  });
}

enum EnrollmentWizardStep {
  personalInfo,
  address,
  previousAcademic,
  targetAcademic,
  studentCharges,
  guardian,
  summary,
}

extension EnrollmentWizardStepX on EnrollmentWizardStep {
  int get index => switch (this) {
    EnrollmentWizardStep.personalInfo => 0,
    EnrollmentWizardStep.address => 1,
    EnrollmentWizardStep.previousAcademic => 2,
    EnrollmentWizardStep.targetAcademic => 3,
    EnrollmentWizardStep.studentCharges => 4,
    EnrollmentWizardStep.guardian => 5,
    EnrollmentWizardStep.summary => 6,
  };

  static EnrollmentWizardStep fromIndex(int index) {
    return switch (index) {
      0 => EnrollmentWizardStep.personalInfo,
      1 => EnrollmentWizardStep.address,
      2 => EnrollmentWizardStep.previousAcademic,
      3 => EnrollmentWizardStep.targetAcademic,
      4 => EnrollmentWizardStep.studentCharges,
      5 => EnrollmentWizardStep.guardian,
      _ => EnrollmentWizardStep.summary,
    };
  }
}

abstract class EnrollmentDetailPolicy {
  const EnrollmentDetailPolicy();

  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  });

  EnrollmentLoadStatus loadStatus(EnrollmentState state);

  EnrollmentDetail? detail(EnrollmentState state);

  bool isStepEditable(EnrollmentWizardStep step);

  bool canSaveStep(EnrollmentWizardStep step) {
    // Le step récapitulatif déclenche la validation du dossier :
    // il est toujours actionnable (l'enrollment ID est vérifié au dispatch).
    if (step == EnrollmentWizardStep.summary) return true;
    return isStepEditable(step);
  }

  EnrollmentDetailIntent resolveEffectiveIntent({
    required EnrollmentDetailIntent baseIntent,
    EnrollmentSummary? createdEnrollmentSummary,
  }) {
    return baseIntent;
  }

  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => false;

  bool requiresPreviousYearBootstrap(EnrollmentDetailIntent intent) => false;

  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  });
}

class EnrollmentDetailPolicyResolver {
  const EnrollmentDetailPolicyResolver._();

  static EnrollmentDetailPolicy fromIntent(EnrollmentDetailIntent intent) {
    return switch (intent.origin) {
      EnrollmentDetailOrigin.preRegistration =>
        const PreRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.reRegistration =>
        const ReRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.firstRegistration => FirstRegistrationDetailPolicy(
        status: intent.status,
      ),
      EnrollmentDetailOrigin.newFirstRegistration =>
        const NewFirstRegistrationDetailPolicy(),
    };
  }
}

class PreRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const PreRegistrationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {
    bloc.add(
      EnrollmentDetailRequested(
        enrollmentId: intent.enrollmentId,
        silent: silent,
      ),
    );
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) =>
      step != EnrollmentWizardStep.summary;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;

  @override
  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  }) {
    studentBloc.add(
      StudentPersonalInfoUpdateRequested(
        studentId: currentStudent.id,
        firstName: payload.firstName,
        lastName: payload.lastName,
        surname: payload.surname,
        dateOfBirth: payload.dateOfBirth,
        gender: payload.gender,
        birthPlace: payload.birthPlace,
        nationality: payload.nationality,
      ),
    );
  }
}

class ReRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const ReRegistrationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.preview;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.previewStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {
    final studentId = intent.studentId;
    if (studentId == null || studentId.isEmpty) {
      bloc.add(
        EnrollmentDetailRequested(
          enrollmentId: intent.enrollmentId,
          silent: silent,
        ),
      );
      return;
    }
    bloc.add(
      EnrollmentPreviewByStudentIdRequested(
        studentId: studentId,
        silent: silent,
      ),
    );
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) {
    // La règle initiale garde l'expérience existante; elle peut évoluer
    // sans modifier le stepper ni la page détail.
    return step != EnrollmentWizardStep.summary;
  }

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;

  @override
  bool requiresPreviousYearBootstrap(EnrollmentDetailIntent intent) => true;

  @override
  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  }) {
    studentBloc.add(
      StudentPersonalInfoUpdateRequested(
        studentId: currentStudent.id,
        firstName: payload.firstName,
        lastName: payload.lastName,
        surname: payload.surname,
        dateOfBirth: payload.dateOfBirth,
        gender: payload.gender,
        birthPlace: payload.birthPlace,
        nationality: payload.nationality,
      ),
    );
  }
}

class FirstRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  final String? status;

  const FirstRegistrationDetailPolicy({this.status});

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {
    bloc.add(
      EnrollmentDetailRequested(
        enrollmentId: intent.enrollmentId,
        silent: silent,
      ),
    );
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) {
    final normalizedStatus = status?.trim().toUpperCase();
    if (normalizedStatus != 'IN_PROGRESS') {
      return false;
    }

    return step != EnrollmentWizardStep.summary;
  }

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;

  @override
  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  }) {
    studentBloc.add(
      StudentPersonalInfoUpdateRequested(
        studentId: currentStudent.id,
        firstName: payload.firstName,
        lastName: payload.lastName,
        surname: payload.surname,
        dateOfBirth: payload.dateOfBirth,
        gender: payload.gender,
        birthPlace: payload.birthPlace,
        nationality: payload.nationality,
      ),
    );
  }
}

class NewFirstRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const NewFirstRegistrationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {
    if (intent.enrollmentId == 'new') {
      if (!silent) {
        bloc.add(const EnrollmentNewDetailInitialized());
      }
      return;
    }

    bloc.add(
      EnrollmentDetailRequested(
        enrollmentId: intent.enrollmentId,
        silent: silent,
      ),
    );
  }

  @override
  EnrollmentDetailIntent resolveEffectiveIntent({
    required EnrollmentDetailIntent baseIntent,
    EnrollmentSummary? createdEnrollmentSummary,
  }) {
    if (createdEnrollmentSummary == null) {
      return baseIntent;
    }

    return baseIntent.withEnrollmentId(createdEnrollmentSummary.enrollmentId);
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) =>
      step != EnrollmentWizardStep.summary;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;

  @override
  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  }) {
    enrollmentBloc.add(
      EnrollmentCreateRequested(
        firstName: payload.firstName,
        lastName: payload.lastName,
        surname: payload.surname,
        dateOfBirth: payload.dateOfBirth,
        birthPlace: payload.birthPlace,
        nationality: payload.nationality,
        gender: payload.gender,
      ),
    );
  }
}
