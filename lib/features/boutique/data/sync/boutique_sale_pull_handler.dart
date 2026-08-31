import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_pull_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_pull_repository.dart';

/// [PullHandler] des ventes boutique, enregistré sur le `PullCoordinator`.
///
/// **Self-sufficient** : le jeton vit dans `sync_meta` via le repository, le
/// périmètre (école) est porté par le JWT. Ne lève pas — un `Left` du
/// repository devient un [PullOutcome.error].
///
/// `boutique.sale.read` et rien d'autre : lire la caisse n'est pas lire le
/// catalogue, et un compte qui n'a que la vente doit pouvoir compter son
/// tiroir.
class BoutiqueSalePullHandler implements PullHandler {
  final BoutiquePullRepository _repository;

  const BoutiqueSalePullHandler(this._repository);

  @override
  String get resource => kBoutiqueSalesResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.boutiqueSaleRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncSales();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
