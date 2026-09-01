import 'package:equatable/equatable.dart';

enum StudentChargeStatus { due, partial, paid }

extension StudentChargeStatusX on StudentChargeStatus {
  static StudentChargeStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'DUE':
        return StudentChargeStatus.due;
      case 'PARTIAL':
        return StudentChargeStatus.partial;
      case 'PAID':
        return StudentChargeStatus.paid;
      default:
        return StudentChargeStatus.due;
    }
  }
}

class StudentCharge extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final String schoolLevelId;
  final String schoolLevelGroupId;
  final String feeTariffId;

  /// Code de la ligne de grille payée — « T2 », « OM2 » — ce qui distingue deux
  /// tranches d'un même frais (v39).
  ///
  /// ⚠️ **Nullable, là où [feeTariffId] est aplati en chaîne vide.** Le pont
  /// local→online replie l'absence de tarif sur `''` parce que c'est la forme
  /// qu'attendent les écrans de lecture ; le code, lui, garde `null`, parce que
  /// la seule chose qu'un écran en fasse est de décider s'il l'affiche. Une
  /// chaîne vide y ajouterait un troisième cas à distinguer, pour rien.
  ///
  /// Nul quand la créance n'a pas de tarif (*ad hoc*), quand la grille n'est pas
  /// sur cet appareil, ou sur le chemin online pur — le serveur ne sert le code
  /// que sur le tarif.
  final String? feeTariffCode;

  final String feeCode;
  final String label;
  final double expectedAmountInCents;
  final double amountPaidInCents; // miroir serveur (autoritaire)

  /// Déjà payé par CE poste, pas encore remonté (composé au read côté offline,
  /// FRONT §5). Nul (0) sur le chemin online pur → comportement inchangé.
  final double amountPaidPendingInCents;

  /// Créance locale d'un nouvel élève, jamais poussée (FRONT §5.2). Faux online.
  final bool isProvisional;
  final String currency;
  final StudentChargeStatus status;
  final String? dueAt; // yyyy-MM-dd | null

  const StudentCharge({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
    required this.feeTariffId,
    this.feeTariffCode,
    required this.feeCode,
    required this.label,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    this.amountPaidPendingInCents = 0,
    this.isProvisional = false,
    required this.currency,
    required this.status,
    this.dueAt,
  });

  /// Déjà payé TOTAL affiché : miroir serveur + encaissements de ce poste non
  /// remontés (FRONT §5 « paid_total »).
  double get paidTotalInCents => amountPaidInCents + amountPaidPendingInCents;

  /// Reste à payer composé (FRONT §5) : `max(0, expected - paid_total)`. C'est
  /// LA seule vérité locale pour filtrer/borner, jamais `status` (FRONT §6/§8).
  double get remainingInCents {
    final remaining = expectedAmountInCents - paidTotalInCents;
    return remaining < 0 ? 0 : remaining;
  }

  StudentCharge copyWith({
    String? id,
    String? studentId,
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    String? feeTariffId,
    String? feeTariffCode,
    String? feeCode,
    String? label,
    double? expectedAmountInCents,
    double? amountPaidInCents,
    double? amountPaidPendingInCents,
    bool? isProvisional,
    String? currency,
    StudentChargeStatus? status,
    String? dueAt,
  }) {
    return StudentCharge(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      academicYearId: academicYearId ?? this.academicYearId,
      schoolLevelId: schoolLevelId ?? this.schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId ?? this.schoolLevelGroupId,
      feeTariffId: feeTariffId ?? this.feeTariffId,
      feeTariffCode: feeTariffCode ?? this.feeTariffCode,
      feeCode: feeCode ?? this.feeCode,
      label: label ?? this.label,
      expectedAmountInCents:
          expectedAmountInCents ?? this.expectedAmountInCents,
      amountPaidInCents: amountPaidInCents ?? this.amountPaidInCents,
      amountPaidPendingInCents:
          amountPaidPendingInCents ?? this.amountPaidPendingInCents,
      isProvisional: isProvisional ?? this.isProvisional,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    feeTariffId,
    feeTariffCode,
    feeCode,
    label,
    expectedAmountInCents,
    amountPaidInCents,
    amountPaidPendingInCents,
    isProvisional,
    currency,
    status,
    dueAt,
  ];
}
