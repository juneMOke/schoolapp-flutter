import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Un frais facturé dans l'année, nommé par le titre de l'école, avec la ou
/// les devises dans lesquelles l'année le facture.
class RecoveryFee extends Equatable {
  final String code;
  final String label;
  final List<String> currencies;
  final int sortOrder;

  const RecoveryFee({
    required this.code,
    required this.label,
    required this.currencies,
    required this.sortOrder,
  });

  @override
  List<Object?> get props => [code, label, currencies, sortOrder];
}

/// Attendu, perçu (brut), reste (planché par créance) et taux d'une devise.
class RecoveryFigures extends Equatable {
  final String currency;
  final int dueInCents;
  final int paidInCents;
  final int outstandingInCents;

  /// `null` quand le dû vaut 0.
  final int? ratePercent;

  const RecoveryFigures({
    required this.currency,
    required this.dueInCents,
    required this.paidInCents,
    required this.outstandingInCents,
    this.ratePercent,
  });

  Money get due => Money(dueInCents, currency);
  Money get paid => Money(paidInCents, currency);
  Money get outstanding => Money(outstandingInCents, currency);

  @override
  List<Object?> get props => [
    currency,
    dueInCents,
    paidInCents,
    outstandingInCents,
    ratePercent,
  ];
}

/// Rien payé · partiel · soldé.
class RecoverySituationCounts extends Equatable {
  final int noPayment;
  final int partial;
  final int settled;

  const RecoverySituationCounts({
    required this.noPayment,
    required this.partial,
    required this.settled,
  });

  static const zero = RecoverySituationCounts(
    noPayment: 0,
    partial: 0,
    settled: 0,
  );

  int get total => noPayment + partial + settled;

  int of(StudentChargeStatus status) => switch (status) {
    StudentChargeStatus.due => noPayment,
    StudentChargeStatus.partial => partial,
    StudentChargeStatus.paid => settled,
  };

  @override
  List<Object?> get props => [noPayment, partial, settled];
}

/// Bloc C : une ligne par (frais, devise).
class RecoveryFeeRate extends Equatable {
  final String feeCode;
  final String label;
  final RecoveryFigures figures;
  final int billedStudents;

  const RecoveryFeeRate({
    required this.feeCode,
    required this.label,
    required this.figures,
    required this.billedStudents,
  });

  @override
  List<Object?> get props => [feeCode, label, figures, billedStudents];
}

/// Une classe sur un frais (bloc D, fiche de classe O2).
class RecoveryClassFeeRow extends Equatable {
  /// `null` pour « Non affectés ».
  final String? classroomId;
  final String classroomName;
  final String? cycleName;
  final int billedStudents;
  final int settledStudents;
  final int noPaymentStudents;
  final Money due;
  final Money outstanding;
  final int? ratePercent;

  const RecoveryClassFeeRow({
    required this.classroomId,
    required this.classroomName,
    this.cycleName,
    required this.billedStudents,
    required this.settledStudents,
    required this.noPaymentStudents,
    required this.due,
    required this.outstanding,
    this.ratePercent,
  });

  bool get isUnassigned => classroomId == null;

  @override
  List<Object?> get props => [
    classroomId,
    classroomName,
    cycleName,
    billedStudents,
    settledStudents,
    noPaymentStudents,
    due,
    outstanding,
    ratePercent,
  ];
}

/// Bloc D pour un (frais, devise) : les classes du meilleur taux au moins bon.
class RecoveryClassRanking extends Equatable {
  final String feeCode;
  final String currency;
  final List<RecoveryClassFeeRow> ranked;
  final RecoveryClassFeeRow? unassigned;

  const RecoveryClassRanking({
    required this.feeCode,
    required this.currency,
    required this.ranked,
    this.unassigned,
  });

  /// Les 4 premières et les 4 dernières ; la moitié de chaque côté sous 8
  /// (R7). Une classe n'apparaît jamais des deux côtés.
  ({List<RecoveryClassFeeRow> top, List<RecoveryClassFeeRow> bottom}) split({
    int side = 4,
  }) {
    final n = ranked.length;
    final perSide = n >= side * 2 ? side : n ~/ 2;
    final top = ranked.take(n < side * 2 ? n - perSide : perSide).toList();
    final bottom = ranked.reversed.take(perSide).toList();
    return (top: top, bottom: bottom);
  }

  @override
  List<Object?> get props => [feeCode, currency, ranked, unassigned];
}

/// Bloc E : élèves en ordre selon chaque règle, avant de la choisir (A8).
class RecoveryRuleCounts extends Equatable {
  final int somePayment;
  final int fullySettled;

  /// `null` sans montant ou en mixte.
  final int? atLeast;

  const RecoveryRuleCounts({
    required this.somePayment,
    required this.fullySettled,
    this.atLeast,
  });

  @override
  List<Object?> get props => [somePayment, fullySettled, atLeast];
}

/// Une classe de la simulation (F).
class RecoverySimulationRow extends Equatable {
  final String? classroomId;
  final String classroomName;
  final String? cycleName;
  final int headcount;
  final int billedStudents;
  final int targetedStudents;
  final int remainingHeadcount;
  final List<Money> lostCollected;
  final List<Money> abandonedOutstanding;

  const RecoverySimulationRow({
    required this.classroomId,
    required this.classroomName,
    this.cycleName,
    required this.headcount,
    required this.billedStudents,
    required this.targetedStudents,
    required this.remainingHeadcount,
    this.lostCollected = const [],
    this.abandonedOutstanding = const [],
  });

  bool get isUnassigned => classroomId == null;

  @override
  List<Object?> get props => [
    classroomId,
    classroomName,
    cycleName,
    headcount,
    billedStudents,
    targetedStudents,
    remainingHeadcount,
    lostCollected,
    abandonedOutstanding,
  ];
}

class RecoverySimulation extends Equatable {
  final List<RecoverySimulationRow> rows;
  final int headcount;
  final int targetedStudents;
  final int remainingHeadcount;
  final List<Money> lostCollected;
  final List<Money> abandonedOutstanding;

  const RecoverySimulation({
    required this.rows,
    required this.headcount,
    required this.targetedStudents,
    required this.remainingHeadcount,
    this.lostCollected = const [],
    this.abandonedOutstanding = const [],
  });

  @override
  List<Object?> get props => [
    rows,
    headcount,
    targetedStudents,
    remainingHeadcount,
    lostCollected,
    abandonedOutstanding,
  ];
}

/// Le tableau de bord entier, sauf la liste nominative — une seule lecture du
/// serveur, à l'instant [situationAt].
class RecoveryDashboard extends Equatable {
  final DateTime situationAt;
  final String academicYear;
  final int pendingWrites;
  final String? perimeterLabel;
  final List<RecoveryFee> fees;
  final List<String> currencies;
  final bool atLeastAvailable;
  final int studentCount;
  final List<RecoveryFigures> keyFigures;
  final RecoverySituationCounts situations;
  final List<RecoveryFeeRate> feeRates;
  final List<RecoveryClassRanking> classRankings;
  final RecoveryRuleCounts ruleCounts;
  final RecoverySimulation simulation;

  /// Posé quand la réponse vient du cache hors ligne : l'heure où le serveur
  /// l'avait donnée.
  final DateTime? cachedAt;

  const RecoveryDashboard({
    required this.situationAt,
    required this.academicYear,
    required this.pendingWrites,
    this.perimeterLabel,
    required this.fees,
    required this.currencies,
    required this.atLeastAvailable,
    required this.studentCount,
    required this.keyFigures,
    required this.situations,
    required this.feeRates,
    required this.classRankings,
    required this.ruleCounts,
    required this.simulation,
    this.cachedAt,
  });

  bool get isMixed => currencies.length > 1;

  RecoveryDashboard cached(DateTime at) => RecoveryDashboard(
    situationAt: situationAt,
    academicYear: academicYear,
    pendingWrites: pendingWrites,
    perimeterLabel: perimeterLabel,
    fees: fees,
    currencies: currencies,
    atLeastAvailable: atLeastAvailable,
    studentCount: studentCount,
    keyFigures: keyFigures,
    situations: situations,
    feeRates: feeRates,
    classRankings: classRankings,
    ruleCounts: ruleCounts,
    simulation: simulation,
    cachedAt: at,
  );

  @override
  List<Object?> get props => [
    situationAt,
    academicYear,
    pendingWrites,
    perimeterLabel,
    fees,
    currencies,
    atLeastAvailable,
    studentCount,
    keyFigures,
    situations,
    feeRates,
    classRankings,
    ruleCounts,
    simulation,
    cachedAt,
  ];
}
