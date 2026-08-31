import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/student_address_parts.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

class StepFormState extends Equatable {
  final bool dirty;
  final bool valid;
  final bool saving;

  const StepFormState({
    this.dirty = false,
    this.valid = false,
    this.saving = false,
  });

  bool get canSave => dirty && valid && !saving;

  bool get canContinue => !dirty && valid && !saving;

  StepFormState copyWith({bool? dirty, bool? valid, bool? saving}) {
    return StepFormState(
      dirty: dirty ?? this.dirty,
      valid: valid ?? this.valid,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => <Object?>[dirty, valid, saving];
}

class EnrollmentStepperStateHelper {
  const EnrollmentStepperStateHelper._();

  static bool isPersonalInfoValid(StudentDetail student) {
    return student.firstName.trim().isNotEmpty &&
        student.lastName.trim().isNotEmpty &&
        student.surname.trim().isNotEmpty &&
        student.birthPlace.trim().isNotEmpty &&
        student.nationality.trim().isNotEmpty &&
        student.dateOfBirth.trim().isNotEmpty;
  }

  /// L'adresse complémentaire (rue, avenue, numéro) est **facultative**, et le
  /// champ `address` du dossier ne porte plus qu'elle. L'exiger ici revenait à
  /// ré-imposer une étape plus haut ce que le formulaire venait d'abandonner :
  /// l'état semé au dossier repasse par ici à chaque rechargement — il y en a
  /// un après chaque enregistrement — et refermait l'étape derrière l'usager,
  /// « Continuer » éteint et « Enregistrer » avec lui puisque plus rien
  /// n'était modifié. Aucune issue, sauf inventer une ligne d'adresse.
  ///
  /// Ce qui reste exigé, c'est le QUARTIER : porté par `neighborhood` depuis
  /// la scission des deux champs, et par le préfixe d'`address` pour les
  /// dossiers écrits avant elle — d'où la lecture partagée avec le formulaire.
  static bool isAddressValid(StudentDetail student) {
    return student.city.trim().isNotEmpty &&
        student.district.trim().isNotEmpty &&
        student.municipality.trim().isNotEmpty &&
        StudentAddressParts.of(student).neighborhood.isNotEmpty;
  }

  static bool isAcademicInfoValid(EnrollmentSchoolDetail enrollment) {
    return isAcademicPreviousInfoValid(enrollment) &&
        isAcademicTargetInfoValid(enrollment);
  }

  /// Le bloc « école précédente » est **entièrement facultatif** : un enfant
  /// qui entre en première année de maternelle n'a ni école, ni cycle, ni
  /// moyenne, ni rang à déclarer, et devait jusqu'ici en inventer pour
  /// franchir l'étape.
  ///
  /// Il ne reste donc **rien à exiger** ici. Ce qui subsiste — la cohérence de
  /// format d'une valeur effectivement saisie — est vérifié dans le formulaire,
  /// au contact du texte brut : une fois la valeur parsée en `double?`, une
  /// saisie illisible et une case vide sont devenues indiscernables.
  ///
  /// Conservée plutôt que supprimée : elle nomme une étape du parcours, et le
  /// registre des handlers l'appelle. La rendre `true` en bloc est le fait
  /// métier, pas un raccourci.
  static bool isAcademicPreviousInfoValid(EnrollmentSchoolDetail enrollment) =>
      true;

  static bool isAcademicTargetInfoValid(EnrollmentSchoolDetail enrollment) {
    return enrollment.academicYearId.trim().isNotEmpty &&
        enrollment.schoolLevelGroupId.trim().isNotEmpty &&
        enrollment.schoolLevelId.trim().isNotEmpty;
  }

  static bool isGuardianInfoValid(List<ParentSummary> parents) {
    return parents.isNotEmpty &&
        parents.every(
          (parent) =>
              parent.firstName.trim().isNotEmpty &&
              parent.lastName.trim().isNotEmpty &&
              parent.phoneNumber.trim().isNotEmpty &&
              (parent.email.trim().isEmpty ||
                  RegExp(
                    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                  ).hasMatch(parent.email.trim())),
        );
  }

  static bool isSaveEnabledStep(int step) => step >= 0 && step <= 6;

  // Le step 6 (récapitulatif) n'a pas d'état de formulaire local —
  // il est toujours "prêt à valider".
  static bool _isSummaryStep(int step) => step == 6;

  static StepFormState stateForStep(
    Map<int, StepFormState> stepStates,
    int step,
  ) {
    return stepStates[step] ?? const StepFormState();
  }

  static bool canContinueForStep({
    required int currentStep,
    required Map<int, StepFormState> stepStates,
  }) {
    final current = stateForStep(stepStates, currentStep);
    if (isSaveEnabledStep(currentStep)) {
      return current.canContinue;
    }
    if (stepStates.containsKey(currentStep)) {
      return current.valid && !current.saving;
    }
    return true;
  }

  static bool canSaveForStep({
    required int currentStep,
    required Map<int, StepFormState> stepStates,
  }) {
    if (!isSaveEnabledStep(currentStep)) {
      return false;
    }
    // Le step récapitulatif (5) est toujours actionnable.
    if (_isSummaryStep(currentStep)) {
      return true;
    }
    return stateForStep(stepStates, currentStep).canSave;
  }
}
