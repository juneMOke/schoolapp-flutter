import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';

/// Les chiffres du serveur, et **d'où ils viennent**.
///
/// Le tableau de bord est consultatif : hors ligne, il montre la dernière photo
/// connue plutôt qu'une erreur — mais il doit la DATER, sans quoi des chiffres
/// d'hier se liraient comme ceux d'aujourd'hui.
class BoutiqueStatsSnapshot extends Equatable {
  final BoutiqueStats stats;

  /// Quand le serveur a répondu. `null` : réponse fraîche, à l'instant.
  final DateTime? cachedAt;

  const BoutiqueStatsSnapshot({required this.stats, this.cachedAt});

  bool get isFromCache => cachedAt != null;

  @override
  List<Object?> get props => [stats, cachedAt];
}
