import 'package:equatable/equatable.dart';

/// Ce qui figure sur la copie (spec S5). Programme, points, consignes et durée
/// cochés par défaut ; les réponses non — cochées, la copie devient un
/// corrigé.
class CopieOptions extends Equatable {
  final bool programme;
  final bool points;
  final bool consignes;
  final bool duree;
  final bool reponses;

  const CopieOptions({
    this.programme = true,
    this.points = true,
    this.consignes = true,
    this.duree = true,
    this.reponses = false,
  });

  CopieOptions copyWith({
    bool? programme,
    bool? points,
    bool? consignes,
    bool? duree,
    bool? reponses,
  }) => CopieOptions(
    programme: programme ?? this.programme,
    points: points ?? this.points,
    consignes: consignes ?? this.consignes,
    duree: duree ?? this.duree,
    reponses: reponses ?? this.reponses,
  );

  @override
  List<Object?> get props => [programme, points, consignes, duree, reponses];
}
