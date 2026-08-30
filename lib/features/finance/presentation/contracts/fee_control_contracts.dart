import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';

/// Filtre de statut de paiement du Contrôle des frais.
///
/// Les trois états utiles se déduisent des montants et coïncident exactement
/// avec [StudentChargeStatus] : soldé = `paid`, partiel = `partial`, aucun =
/// `due`. On ne redéclare donc pas un quatrième vocabulaire de statut — seul
/// [all] est propre au filtre.
enum FeeControlPaymentFilter { all, settled, partial, none }

extension FeeControlPaymentFilterX on FeeControlPaymentFilter {
  /// Statut visé, ou `null` pour « Tous ».
  StudentChargeStatus? get targetStatus => switch (this) {
    FeeControlPaymentFilter.all => null,
    FeeControlPaymentFilter.settled => StudentChargeStatus.paid,
    FeeControlPaymentFilter.partial => StudentChargeStatus.partial,
    FeeControlPaymentFilter.none => StudentChargeStatus.due,
  };
}

/// Une ligne de résultat : l'élève et sa position sur le frais contrôlé.
class FeeControlRow extends Equatable {
  final EnrollmentSummary summary;
  final LocalFeeChargeAggregate aggregate;

  const FeeControlRow({required this.summary, required this.aggregate});

  /// Statut dérivé **des montants** (payé composé), jamais de la colonne
  /// `status` du grand-livre — celle-ci est un miroir serveur et ferait
  /// réapparaître « dû » un poste soldé hors-ligne (FRONT §6/§8).
  ///
  /// Le calcul vit dans l'agrégat depuis qu'il porte une position par devise :
  /// soldé seulement si TOUTES le sont.
  StudentChargeStatus get status => aggregate.status;

  bool matches(FeeControlPaymentFilter filter) {
    final target = filter.targetStatus;
    return target == null || status == target;
  }

  @override
  List<Object?> get props => [summary, aggregate];
}

/// Critères émis par le formulaire de recherche (sans l'année, que la page
/// tient du contexte académique).
class FeeControlSearchRequest extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;

  /// Classe visée, ou `null` pour « toutes les classes du niveau ». Facultatif :
  /// un niveau dont les classes ne sont pas encore composées doit rester
  /// contrôlable.
  final String? classroomId;

  final String feeCode;

  final FeeControlPaymentFilter statusFilter;
  final String firstName;
  final String lastName;
  final String surname;

  const FeeControlSearchRequest({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.classroomId,
    required this.feeCode,
    required this.statusFilter,
    required this.firstName,
    required this.lastName,
    required this.surname,
  });

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    classroomId,
    feeCode,
    statusFilter,
    firstName,
    lastName,
    surname,
  ];
}

/// Photo immuable de la dernière recherche jouée — sert à la rejouer
/// (pagination, réessai) et à reconstituer les puces de critères.
class FeeControlQuery extends Equatable {
  final String academicYearId;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  /// Classe visée, ou `null` pour tout le niveau.
  final String? classroomId;

  final String feeCode;
  final FeeControlPaymentFilter statusFilter;
  final String firstName;
  final String lastName;
  final String surname;
  final int page;
  final int size;

  const FeeControlQuery({
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.classroomId,
    required this.feeCode,
    required this.statusFilter,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.page,
    required this.size,
  });

  FeeControlQuery copyWithPage(int page) => FeeControlQuery(
    academicYearId: academicYearId,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    classroomId: classroomId,
    feeCode: feeCode,
    statusFilter: statusFilter,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    page: page,
    size: size,
  );

  @override
  List<Object?> get props => [
    academicYearId,
    schoolLevelGroupId,
    schoolLevelId,
    classroomId,
    feeCode,
    statusFilter,
    firstName,
    lastName,
    surname,
    page,
    size,
  ];
}
