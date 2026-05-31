import 'package:equatable/equatable.dart';

class LevelDistributionItem extends Equatable {
  final String levelId;
  final String levelCode;
  final int total;

  const LevelDistributionItem({
    required this.levelId,
    required this.levelCode,
    required this.total,
  });

  @override
  List<Object?> get props => [levelId, levelCode, total];
}
