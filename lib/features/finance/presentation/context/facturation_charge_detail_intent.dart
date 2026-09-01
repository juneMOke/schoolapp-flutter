import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

class FacturationChargeDetailIntent extends Equatable {
  final String chargeId;
  final String studentId;
  final String academicYearId;
  // Student display fields
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;
  // Charge detail fields
  final String feeCode;

  /// Libellé de la créance et code de sa ligne de grille — de quoi la NOMMER,
  /// et pas seulement dire de quelle nature elle est (v39).
  ///
  /// ⚠️ **Vides quand la popin s'ouvre par la route** (`fromRouteContext` sans
  /// `extra` → [FacturationChargeDetailIntent.invalid]) : la désignation retombe
  /// alors sur la nature localisée, comme le reste de la popin retombe sur
  /// « contexte indisponible ». Jamais de parenthèse vide.
  final String chargeLabel;
  final String? feeTariffCode;
  final double expectedAmountInCents;
  final double amountPaidInCents;
  final String currency;
  final StudentChargeStatus chargeStatus;

  const FacturationChargeDetailIntent({
    required this.chargeId,
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
    required this.feeCode,
    this.chargeLabel = '',
    this.feeTariffCode,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.chargeStatus,
  });

  const FacturationChargeDetailIntent.invalid({
    required String chargeId,
    required String studentId,
    required String academicYearId,
  }) : this(
         chargeId: chargeId,
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
         feeCode: '',
         chargeLabel: '',
         feeTariffCode: null,
         expectedAmountInCents: 0,
         amountPaidInCents: 0,
         currency: '',
         chargeStatus: StudentChargeStatus.due,
       );

  /// Sait-on **de qui** est cet argent, et de **quelle** ligne ?
  ///
  /// Identité + identifiant de la ligne, jamais la classe : voir la docstring de
  /// `FacturationDetailIntent.hasStudentIdentity`. Une fiche ouverte depuis une
  /// recherche **par identité** n'a pas de classe à transmettre — le résumé
  /// d'élève n'en porte pas — et l'exiger ici referait, dans cette modale, la
  /// panne que la fiche vient de perdre : « contexte indisponible » par-dessus
  /// une ligne parfaitement identifiée.
  bool get hasDisplayContext =>
      chargeId.trim().isNotEmpty &&
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty;

  FacturationChargeDetailIntent withRouteParams({
    required String chargeId,
    required String studentId,
    required String academicYearId,
  }) => FacturationChargeDetailIntent(
    chargeId: chargeId,
    studentId: studentId,
    academicYearId: academicYearId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
    feeCode: feeCode,
    chargeLabel: chargeLabel,
    feeTariffCode: feeTariffCode,
    expectedAmountInCents: expectedAmountInCents,
    amountPaidInCents: amountPaidInCents,
    currency: currency,
    chargeStatus: chargeStatus,
  );

  static FacturationChargeDetailIntent fromRouteContext({
    required String chargeId,
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is FacturationChargeDetailIntent) {
      return extra.withRouteParams(
        chargeId: chargeId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }
    return FacturationChargeDetailIntent.invalid(
      chargeId: chargeId,
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    chargeId,
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
    feeCode,
    chargeLabel,
    feeTariffCode,
    expectedAmountInCents,
    amountPaidInCents,
    currency,
    chargeStatus,
  ];
}
