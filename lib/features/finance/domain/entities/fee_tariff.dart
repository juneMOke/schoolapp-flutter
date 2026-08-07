import 'package:equatable/equatable.dart';

class FeeTariff extends Equatable {
  final String id;
  final String label;
  final double amount;
  final String currency;
  final String levelId;
  final String? dueAt; // yyyy-MM-dd | null
  const FeeTariff({
    required this.id,
    required this.label,
    required this.amount,
    required this.currency,
    required this.levelId,
    this.dueAt,
  });
  @override
  List<Object?> get props => [id, label, amount, currency, levelId, dueAt];
}
