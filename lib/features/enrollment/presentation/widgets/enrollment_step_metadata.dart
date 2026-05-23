import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

typedef EnrollmentStepLabelBuilder = String Function(
  AppLocalizations l10n, {
  required bool savingNow,
  required bool isEnrollmentAlreadyCompleted,
});

class EnrollmentStepMetadata {
  final EnrollmentWizardStep step;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) subtitle;
  final EnrollmentStepLabelBuilder saveLabel;

  const EnrollmentStepMetadata({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.saveLabel,
  });
}

class EnrollmentStepMetadataRegistry {
  const EnrollmentStepMetadataRegistry._();

  static List<EnrollmentStepMetadata> build() {
    return <EnrollmentStepMetadata>[
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.personalInfo,
        title: (l10n) => l10n.personalInformation,
        subtitle: (l10n) => l10n.stepPersonalInfoSubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            savingNow ? l10n.savingPersonalInfo : l10n.savePersonalInfo,
      ),
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.address,
        title: (l10n) => l10n.address,
        subtitle: (l10n) => l10n.stepAddressSubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            savingNow ? l10n.savingAddress : l10n.saveAddress,
      ),
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.previousAcademic,
        title: (l10n) => l10n.previousYear,
        subtitle: (l10n) => l10n.stepAcademicPreviousSubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            savingNow ? l10n.savingAcademicInfo : l10n.saveAcademicInfo,
      ),
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.targetAcademic,
        title: (l10n) => l10n.targetYear,
        subtitle: (l10n) => l10n.stepAcademicTargetSubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            savingNow ? l10n.savingAcademicInfo : l10n.saveAcademicInfo,
      ),
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.studentCharges,
        title: (l10n) => l10n.studentChargesStepTitle,
        subtitle: (l10n) => l10n.studentChargesStepSubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            savingNow
                ? l10n.studentChargesSavingAction
                : l10n.studentChargesSaveAction,
      ),
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.guardian,
        title: (l10n) => l10n.guardianInformation,
        subtitle: (l10n) => l10n.stepGuardianSubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            savingNow ? l10n.savingGuardianInfo : l10n.saveGuardianInfo,
      ),
      EnrollmentStepMetadata(
        step: EnrollmentWizardStep.summary,
        title: (l10n) => l10n.summary,
        subtitle: (l10n) => l10n.stepSummarySubtitle,
        saveLabel: (l10n, {required savingNow, required isEnrollmentAlreadyCompleted}) =>
            isEnrollmentAlreadyCompleted
                ? l10n.goToFirstRegistration
                : (savingNow ? l10n.validatingEnrollment : l10n.validateEnrollment),
      ),
    ];
  }

  static List<String> titles(AppLocalizations l10n) =>
      build().map((metadata) => metadata.title(l10n)).toList(growable: false);

  static List<String> subtitles(AppLocalizations l10n) =>
      build().map((metadata) => metadata.subtitle(l10n)).toList(growable: false);
}
