part of 'student_charges_bloc.dart';

sealed class StudentChargesEvent extends Equatable {
  const StudentChargesEvent();
}

/// Lecture du grand-livre d'un élève, **bornée à une année**.
///
/// ⚠️ [academicYearId] est REQUIS, et ce n'est pas du zèle. Sans borne, la
/// lecture remonte les créances de TOUTES les années : un réinscrit voyait son
/// minerval N-1 sous celui de N, additionné dans le pied de page de l'étape
/// « Frais ». Un défaut à chaîne vide aurait laissé chaque nouvel appelant
/// rejouer ce défaut en silence — ici le compilateur les nomme.
///
/// La chaîne vide reste acceptée et signifie « pas de borne » : un dossier sans
/// année cible n'en a pas à donner, et le comportement dégradé vaut mieux qu'un
/// écran vide. Elle se passe alors explicitement, jamais par omission.
///
/// Une créance à `academic_year_id` NULL appartient à TOUTES les années et
/// survit donc à la borne (`LocalStudentCharge.belongsToYear`).
class StudentChargesRequested extends StudentChargesEvent {
  final String studentId;
  final String levelId;
  final String academicYearId;

  const StudentChargesRequested({
    required this.studentId,
    required this.levelId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, levelId, academicYearId];
}

/// Étape Frais du wizard en flux BROUILLON local : génère d'abord les créances
/// provisoires depuis la grille locale `ref_fee_tariffs` (FF5, idempotent par
/// élève+année), puis lit le grand-livre comme [StudentChargesRequested].
class DraftStudentChargesRequested extends StudentChargesEvent {
  final String studentId;
  final String levelId;
  final String academicYearId;
  final String? schoolLevelGroupId;

  const DraftStudentChargesRequested({
    required this.studentId,
    required this.levelId,
    required this.academicYearId,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [
    studentId,
    levelId,
    academicYearId,
    schoolLevelGroupId,
  ];
}

class StudentChargesByAcademicYearRequested extends StudentChargesEvent {
  final String studentId;
  final String academicYearId;

  /// Relecture **silencieuse** déclenchée par un cycle de synchro abouti : pas
  /// de passage en `loading` (l'écran garde ses lignes, aucun skeleton ne
  /// revient) et un échec ne détruit pas l'affichage déjà servi. Les états
  /// étant `Equatable`, une relecture qui ne change rien n'émet même pas.
  final bool silent;

  const StudentChargesByAcademicYearRequested({
    required this.studentId,
    required this.academicYearId,
    this.silent = false,
  });

  @override
  List<Object?> get props => [studentId, academicYearId, silent];
}

class StudentChargePaymentAllocationsRequested extends StudentChargesEvent {
  final String chargeId;

  const StudentChargePaymentAllocationsRequested({required this.chargeId});

  @override
  List<Object?> get props => [chargeId];
}

class StudentChargesDraftSaved extends StudentChargesEvent {
  final List<StudentCharge> studentCharges;

  const StudentChargesDraftSaved({required this.studentCharges});

  @override
  List<Object?> get props => [studentCharges];
}

class StudentChargeExpectedAmountUpdateRequested extends StudentChargesEvent {
  final String studentChargeId;
  final String studentId;
  final double expectedAmountInCents;

  const StudentChargeExpectedAmountUpdateRequested({
    required this.studentChargeId,
    required this.studentId,
    required this.expectedAmountInCents,
  });

  @override
  List<Object?> get props => [
    studentChargeId,
    studentId,
    expectedAmountInCents,
  ];
}
