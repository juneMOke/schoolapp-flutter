/// Bilan d'un pull keyset du grand-livre (créances / paiements) — miroir du
/// `EnrollmentPullOutcome` de l'Inscription. Diagnostic seulement : le pull
/// peuple le cache local, il n'alimente jamais l'affichage directement (ADR-003).
class FinancePullOutcome {
  /// Lignes locales écrites (0 si [notModified]).
  final int upserted;

  /// Rien de plus récent côté serveur (304, ou cycle sans effet local).
  final bool notModified;

  /// Epoch ms local de la synchro (fraîcheur ADR-002).
  final int syncedAt;

  /// Jeton opaque mémorisé pour le prochain pull (ADR-008/009), **préfixé** de
  /// sa nature : `c…` = curseur de progression (cycle interrompu, on reprend
  /// là), `w…` = watermark de fin de cycle (départ du prochain, Δ appliqué).
  final String? cursor;

  /// Horloge **serveur** (epoch ms, `serverTime`) de la dernière page
  /// appliquée — `null` sur un cycle `notModified`.
  final int? serverTimeMs;

  const FinancePullOutcome({
    required this.upserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const FinancePullOutcome.notModifiedAt(int syncedAt, String? cursor)
    : this(upserted: 0, notModified: true, syncedAt: syncedAt, cursor: cursor);
}
