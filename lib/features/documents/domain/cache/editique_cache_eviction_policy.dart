import 'package:school_app_flutter/core/constants/app_constants.dart';

/// Ce qu'une entrée de cache coûte, et rien d'autre.
///
/// Le classement LRU est porté par l'**ordre de la liste** remise à la
/// politique, pas par une date embarquée ici : le tri est un travail de la base
/// (index `idx_editique_cache_lru`), la décision un travail de code pur.
class EditiqueCacheFootprint {
  final String id;
  final int sizeBytes;

  const EditiqueCacheFootprint({required this.id, required this.sizeBytes});
}

/// Décide **ce qu'on évince** quand le cache éditique dépasse son budget.
///
/// Pure : aucune entrée-sortie, aucune horloge, aucun accès base. C'est ce qui
/// permet d'éprouver la politique — seuil, cible, égalités, entrées aberrantes
/// — avant qu'un seul octet n'existe sur le disque (lot L3.2, « testable à
/// vide »).
///
/// ## Pourquoi une cible sous le seuil
///
/// Redescendre exactement au budget ferait rebalayer à l'écriture suivante :
/// chaque nouvelle pièce repasserait au-dessus, déclencherait un balayage,
/// évincerait une pièce, et ainsi de suite. La politique vise donc
/// [AppConstants.editiqueCacheEvictionTargetRatio] du budget, ce qui laisse de
/// quoi encaisser plusieurs centaines d'émissions entre deux balayages.
///
/// ## Ce que l'éviction ne fait jamais
///
/// Perdre une donnée. Seules les pièces **archivées** par le serveur entrent
/// dans ce cache (`AI`/`NP`/`RC`/`BU`, invariant tenu par un `CHECK` SQL) :
/// une pièce évincée reste re-téléchargeable à l'identique sous le même numéro.
/// C'est exactement ce qui rend le LRU acceptable là où une purge calendaire
/// ne l'était pas — et ce qui interdit d'y ranger un relevé ou un quitus, que
/// le serveur ne conserve pas.
class EditiqueCacheEvictionPolicy {
  /// Seuil de déclenchement, en octets.
  final int budgetBytes;

  /// Part du budget visée après balayage. Bornée à `]0, 1]` par [targetBytes] —
  /// une valeur aberrante ne doit pas vider le cache.
  final double targetRatio;

  const EditiqueCacheEvictionPolicy({
    this.budgetBytes = AppConstants.editiqueCacheBudgetBytes,
    this.targetRatio = AppConstants.editiqueCacheEvictionTargetRatio,
  });

  /// Poids visé après balayage.
  int get targetBytes {
    if (budgetBytes <= 0) return 0;
    final ratio = targetRatio.clamp(0.0, 1.0);
    return (budgetBytes * ratio).floor();
  }

  /// Poids total d'un ensemble d'entrées.
  ///
  /// Les tailles négatives sont ramenées à zéro : une ligne aberrante ne doit
  /// pas **créditer** le budget, ce qui masquerait un dépassement réel.
  static int totalSizeOf(Iterable<EditiqueCacheFootprint> entries) {
    var total = 0;
    for (final entry in entries) {
      total += entry.sizeBytes > 0 ? entry.sizeBytes : 0;
    }
    return total;
  }

  /// Vrai si le poids courant impose un balayage.
  bool needsSweep(int totalSizeBytes) => totalSizeBytes > budgetBytes;

  /// Identifiants à évincer, dans l'ordre d'éviction.
  ///
  /// [leastRecentlyUsedFirst] doit être trié du plus ancien accès au plus
  /// récent — c'est le contrat entre la base et cette politique. La liste rendue
  /// est vide tant que le budget n'est pas dépassé : sous le seuil, on n'évince
  /// **rien**, même d'un octet.
  ///
  /// Le parcours est borné par la liste elle-même : un ensemble d'entrées de
  /// taille nulle ne peut pas faire boucler le balayage, il rend simplement
  /// toutes les entrées.
  List<String> selectVictims(
    List<EditiqueCacheFootprint> leastRecentlyUsedFirst,
  ) {
    var remaining = totalSizeOf(leastRecentlyUsedFirst);
    if (!needsSweep(remaining)) return const [];

    final target = targetBytes;
    final victims = <String>[];
    for (final entry in leastRecentlyUsedFirst) {
      if (remaining <= target) break;
      victims.add(entry.id);
      remaining -= entry.sizeBytes > 0 ? entry.sizeBytes : 0;
    }
    return List.unmodifiable(victims);
  }
}
