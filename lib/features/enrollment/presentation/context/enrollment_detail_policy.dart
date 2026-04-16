import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

enum EnrollmentWizardStep {
  personalInfo,
  address,
  previousAcademic,
  targetAcademic,
  guardian,
  summary,
}

extension EnrollmentWizardStepX on EnrollmentWizardStep {
  int get index => switch (this) {
    EnrollmentWizardStep.personalInfo => 0,
    EnrollmentWizardStep.address => 1,
    EnrollmentWizardStep.previousAcademic => 2,
    EnrollmentWizardStep.targetAcademic => 3,
    EnrollmentWizardStep.guardian => 4,
    EnrollmentWizardStep.summary => 5,
  };

  static EnrollmentWizardStep fromIndex(int index) {
    return switch (index) {
      0 => EnrollmentWizardStep.personalInfo,
      1 => EnrollmentWizardStep.address,
      2 => EnrollmentWizardStep.previousAcademic,
      3 => EnrollmentWizardStep.targetAcademic,
      4 => EnrollmentWizardStep.guardian,
      _ => EnrollmentWizardStep.summary,
    };
  }
}

abstract class EnrollmentDetailPolicy {
  const EnrollmentDetailPolicy();

  void requestLoad(EnrollmentBloc bloc, EnrollmentDetailIntent intent);

  EnrollmentLoadStatus loadStatus(EnrollmentState state);

  EnrollmentDetail? detail(EnrollmentState state);

  bool isStepEditable(EnrollmentWizardStep step);

  bool canSaveStep(EnrollmentWizardStep step) {
    return isStepEditable(step) && step != EnrollmentWizardStep.summary;
  }

  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => false;

  bool requiresPreviousYearBootstrap(EnrollmentDetailIntent intent) => false;
}

class EnrollmentDetailPolicyResolver {
  const EnrollmentDetailPolicyResolver._();

  static EnrollmentDetailPolicy fromOrigin(EnrollmentDetailOrigin origin) {
    return switch (origin) {
      EnrollmentDetailOrigin.preRegistration =>
        const PreRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.reRegistration =>
        const ReRegistrationDetailPolicy(),
      EnrollmentDetailOrigin.firstRegistration =>
        const FirstRegistrationDetailPolicy(),
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
  void requestLoad(EnrollmentBloc bloc, EnrollmentDetailIntent intent) {
    bloc.add(EnrollmentDetailRequested(enrollmentId: intent.enrollmentId));
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) =>
      step != EnrollmentWizardStep.summary;

  @override
  bool requiresCurrentYearBootstrap(EnrollmentDetailIntent intent) => true;
}

class ReRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const ReRegistrationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.preview;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.previewStatus;

  @override
  void requestLoad(EnrollmentBloc bloc, EnrollmentDetailIntent intent) {
    final studentId = intent.studentId;
    if (studentId == null || studentId.isEmpty) {
      bloc.add(EnrollmentDetailRequested(enrollmentId: intent.enrollmentId));
      return;
    }
    bloc.add(EnrollmentPreviewByStudentIdRequested(studentId: studentId));
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
}

class FirstRegistrationDetailPolicy extends EnrollmentDetailPolicy {
  const FirstRegistrationDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(EnrollmentBloc bloc, EnrollmentDetailIntent intent) {
    bloc.add(EnrollmentDetailRequested(enrollmentId: intent.enrollmentId));
  }

  @override
  bool isStepEditable(EnrollmentWizardStep step) {
    return false;
  }
}
