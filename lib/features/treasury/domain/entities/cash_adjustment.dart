import 'package:equatable/equatable.dart';

/// Un ajustement du montant d'une caisse (R14) : un mouvement daté, numéroté,
/// signé et motivé. Le passé n'est jamais réécrit.
class CashAdjustment extends Equatable {
  final String id;

  /// `CF-AJ-2627-000001`.
  final String number;
  final String registerId;
  final DateTime cashDay;
  final DateTime adjustedAt;
  final int previousExpectedInCents;
  final int newAmountInCents;

  /// `newAmount − previousExpected`, jamais 0.
  final int deltaInCents;
  final String reason;
  final String createdByName;

  const CashAdjustment({
    required this.id,
    required this.number,
    required this.registerId,
    required this.cashDay,
    required this.adjustedAt,
    required this.previousExpectedInCents,
    required this.newAmountInCents,
    required this.deltaInCents,
    required this.reason,
    required this.createdByName,
  });

  @override
  List<Object?> get props => [
    id,
    number,
    registerId,
    cashDay,
    adjustedAt,
    previousExpectedInCents,
    newAmountInCents,
    deltaInCents,
    reason,
    createdByName,
  ];
}
