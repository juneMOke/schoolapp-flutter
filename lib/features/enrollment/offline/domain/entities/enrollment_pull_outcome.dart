/// Bilan d'un pull Inscription (référentiel, cohorte N-1, préinscriptions,
/// snapshots hydratants, delta descendant) — miroir léger de
/// `ClassroomSyncOutcome`, partagé par les cinq ressources.
class EnrollmentPullOutcome {
  /// Lignes locales écrites (0 si [notModified]).
  final int upserted;

  /// Rien de plus récent côté serveur (304, ou 200 sans effet local).
  final bool notModified;

  /// Epoch ms local de la synchro (fraîcheur ADR-002).
  final int syncedAt;

  /// Jeton opaque re-présenté au prochain pull en `cursor` (ADR-008/009). Pour
  /// référentiel/cohorte (always-200) c'est un simple marqueur de fraîcheur
  /// (`serverTime`) ; pour préinscriptions/delta/snapshots c'est le curseur
  /// keyset (`nextWatermark` en fin de cycle, ou `nextCursor` si interrompu).
  final String? cursor;

  /// Horloge **serveur** (epoch ms, `serverTime`) de la dernière page
  /// appliquée — `null` sur un cycle `notModified`.
  final int? serverTimeMs;

  const EnrollmentPullOutcome({
    required this.upserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
    this.serverTimeMs,
  });

  const EnrollmentPullOutcome.notModifiedAt(int syncedAt, String? cursor)
    : this(upserted: 0, notModified: true, syncedAt: syncedAt, cursor: cursor);
}
