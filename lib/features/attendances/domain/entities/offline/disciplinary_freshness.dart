import 'package:equatable/equatable.dart';

/// Fraîcheur de la lecture locale des cas disciplinaires (ADR-002 « Mon poste »
/// vs « École »). `bootstrapComplete` = un cycle de pull a ramené toute l'année
/// (les cas serveur sont visibles) ; sinon la vue ne montre que les écritures du
/// poste. `syncedAt` = dernière synchro (epoch ms), pour un repère de fraîcheur.
class DisciplinaryFreshness extends Equatable {
  final bool bootstrapComplete;
  final int? syncedAt;

  const DisciplinaryFreshness({required this.bootstrapComplete, this.syncedAt});

  static const DisciplinaryFreshness localOnly = DisciplinaryFreshness(
    bootstrapComplete: false,
  );

  @override
  List<Object?> get props => [bootstrapComplete, syncedAt];
}
