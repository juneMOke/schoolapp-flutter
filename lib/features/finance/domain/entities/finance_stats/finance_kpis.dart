import 'package:equatable/equatable.dart';

class FinanceKpis extends Equatable {
  final int collected;
  final int expected;
  final int outstanding;
  final int collectionRate;

  const FinanceKpis({
    required this.collected,
    required this.expected,
    required this.outstanding,
    required this.collectionRate,
  });

  @override
  List<Object?> get props => [collected, expected, outstanding, collectionRate];
}
