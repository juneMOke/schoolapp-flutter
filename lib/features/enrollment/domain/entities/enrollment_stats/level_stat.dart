import 'package:equatable/equatable.dart';

class LevelStat extends Equatable {
  final String code;
  final int value;

  const LevelStat({required this.code, required this.value});

  @override
  List<Object?> get props => [code, value];
}
