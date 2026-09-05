import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_pull_repository.dart';

/// [PullHandler] du registre des disparitions.
///
/// ## Pourquoi c'est un flux de socle
///
/// Tout profil détient localement quelque chose qui peut être supprimé : le
/// professeur ses cours, le caissier ses créances, le secrétariat ses
/// inscriptions. Le garder derrière une permission laisserait aveugle exactement
/// le profil qui ne l'a pas — et une tablette aveugle aux disparitions est le
/// défaut que ce flux existe à corriger. Le serveur l'a tranché dans le même
/// sens : c'est le second flux, avec le référentiel d'école, à descendre sans
/// garde d'autorisation.
///
/// D'où [isBaseline] à `true`. Le laisser à `false` avec une exigence vide
/// serait pire que faux : `canAccess` refuse sur exigence vide, délibérément, et
/// le flux cesserait de descendre pour tout le parc — au pire moment, celui où
/// le plan est illisible et où plus rien d'autre ne rattrape.
class TombstonePullHandler implements PullHandler {
  final TombstonePullRepository _repository;

  const TombstonePullHandler(this._repository);

  @override
  String get resource => TombstonePullRepository.resource;

  /// Aucune : le flux est servi sans garde. La liste reste déclarée — un handler
  /// neuf doit dire son exigence — mais c'est [isBaseline] qui gouverne.
  @override
  List<Perm> get requiredPermissions => const [];

  @override
  bool get isBaseline => true;

  @override
  Future<PullOutcome> pull() async {
    final outcome = await _repository.sync();
    if (outcome.error != null) {
      return PullOutcome.error(outcome.error!);
    }
    if (outcome.notModified) {
      return const PullOutcome.notModified();
    }
    // `upserted` reste à zéro : ce flux n'écrit aucune ligne, il en retire.
    // Compter les retraits dans `upserted` ferait afficher « 12 lignes reçues »
    // à un cycle qui vient d'en effacer douze.
    return PullOutcome.updated(removed: outcome.removed);
  }
}
