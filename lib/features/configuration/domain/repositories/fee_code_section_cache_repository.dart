import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';

/// Descendre les **titres de sections** sur la tablette, et les y garder.
///
/// Séparé de `ProvisioningRepository` délibérément : celui-ci est
/// structurellement **en ligne** et garde ses catalogues en mémoire de session
/// (D-9). Lui greffer une base ferait porter deux régimes de fraîcheur à une
/// même classe — et c'est justement la confusion des deux qui rendait le titre
/// d'une nature dépendant du chemin parcouru dans l'application.
///
/// Ce que ce cache n'est **pas** : une source d'écriture. Aucune écriture ne le
/// lit, et le `code` qui part sur le fil vient toujours de la créance ou de la
/// grille. C'est ce qui le distingue du catalogue que D-9 refuse de persister —
/// là-bas, une valeur vieillie alimenterait une activation et sa divergence
/// n'apparaîtrait qu'en 422.
abstract class FeeCodeSectionCacheRepository {
  /// Tire le catalogue **complet** et remplace le cache local de l'école —
  /// **une fois par session**, au premier écran qui a besoin de nommer.
  ///
  /// Rend le nombre de titres retenus, ou `0` si la session avait déjà tiré.
  ///
  /// ⚠️ **Ce n'est délibérément PAS un `PullHandler`.** `/finance/fee-codes`
  /// n'est pas un flux de synchro : il n'appartient pas à l'énumération
  /// serveur, donc il n'a pas de clé de plan. Sous un plan valide,
  /// `PullCoordinator` saute tout handler hors plan — le catalogue ne
  /// descendrait jamais, en silence, avec une pastille verte. Lui inventer une
  /// clé serait pire : c'est exactement le défaut que `sync_plan_keys.dart`
  /// existe à prévenir.
  ///
  /// Une fois par session, et pas à chaque montage : un titre de section ne
  /// change pas dans la journée, et l'écran qui le renomme met le cache à jour
  /// lui-même via [cacheFeeCodeSections].
  Future<Either<Failure, int>> ensureFeeSectionTitles();

  /// Écrit dans le cache un catalogue **qu'on vient de recevoir**, sans rappeler
  /// le serveur.
  ///
  /// Sert l'écran de nommage : `POST /finance/fee-codes` rend le catalogue à
  /// jour, et attendre le prochain cycle de pull ferait afficher l'ancien titre
  /// en Facturation alors que la direction vient de le changer sous ses yeux.
  Future<Either<Failure, Unit>> cacheFeeCodeSections(
    List<FeeCodeOption> sections,
  );
}
