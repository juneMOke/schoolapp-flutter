import 'package:equatable/equatable.dart';

class FeeTypeItem extends Equatable {
  final String code;
  final int collected;
  final int expected;
  final int collectionRate;

  const FeeTypeItem({
    required this.code,
    required this.collected,
    required this.expected,
    required this.collectionRate,
  });

  @override
  List<Object?> get props => [code, collected, expected, collectionRate];
}
