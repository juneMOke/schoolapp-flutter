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
