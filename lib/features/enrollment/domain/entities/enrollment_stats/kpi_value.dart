import 'package:equatable/equatable.dart';

class KpiValue extends Equatable {
  final int value;
  final int? percentOfTotal;

  const KpiValue({required this.value, this.percentOfTotal});

  @override
  List<Object?> get props => [value, percentOfTotal];
}
