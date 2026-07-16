import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final DateTime paidAt;

  /// Paiement de CE poste pas encore remonté au serveur (FRONT §3). Faux pour
  /// les paiements synchronisés (ce poste ou l'autre poste, arrivés par pull).
  final bool isPendingSync;

  const Payment({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    required this.paidAt,
    this.isPendingSync = false,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    paidAt,
    isPendingSync,
  ];
}
