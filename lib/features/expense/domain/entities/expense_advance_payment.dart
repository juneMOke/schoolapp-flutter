import 'package:equatable/equatable.dart';

/// Ce que le décaissement d'une avance au personnel porte de plus qu'un
/// paiement ordinaire (B6, T13) : la paie de la première retenue, et la
/// preuve — reconnaissance de dette signée en espèces, référence sinon. Le
/// mode reste la source des fonds de la demande.
class ExpenseAdvancePayment extends Equatable {
  /// `YYYY-MM`.
  final String firstMonth;
  final bool debtAcknowledged;
  final String? reference;

  const ExpenseAdvancePayment({
    required this.firstMonth,
    this.debtAcknowledged = false,
    this.reference,
  });

  static const int minReferenceLength = 6;

  Map<String, dynamic> toJson() => {
    'firstMonth': firstMonth,
    'debtAcknowledged': debtAcknowledged,
    'reference': reference,
  };

  static ExpenseAdvancePayment? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final month = raw['firstMonth'];
    if (month is! String || month.length != 7) return null;
    final reference = raw['reference'];
    return ExpenseAdvancePayment(
      firstMonth: month,
      debtAcknowledged: raw['debtAcknowledged'] == true,
      reference: reference is String ? reference : null,
    );
  }

  @override
  List<Object?> get props => [firstMonth, debtAcknowledged, reference];
}
