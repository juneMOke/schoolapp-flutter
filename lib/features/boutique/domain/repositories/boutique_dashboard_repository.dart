import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_snapshot.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Les chiffres **serveur** du tableau de bord de la boutique.
///
/// Les agrégats se calculent côté serveur : le poste ne détient que ses propres
/// ventes et celles que le delta lui a descendues, jamais de quoi compter
/// l'école. Ce contrat-ci passe donc par le réseau — avec un repli **daté** sur
/// la dernière réponse quand le réseau manque, et seulement dans ce cas : un
/// 403 ne se masque pas derrière une photo.
///
/// Les lectures locales (tickets provisoires, dernières ventes) restent dans
/// `BoutiqueHistoryRepository`, qui ne touche jamais au réseau.
abstract class BoutiqueDashboardRepository {
  Future<Either<Failure, BoutiqueStatsSnapshot>> stats({
    required String academicYearId,
    required DashboardWindow window,
  });

  Future<Either<Failure, BoutiqueBeneficiariesPage>> beneficiaries(
    BeneficiariesQuery query,
  );
}
