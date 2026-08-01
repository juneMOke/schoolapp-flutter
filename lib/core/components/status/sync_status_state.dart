import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';

/// État complet piloté par [SyncStatusCubit] : le [status] affiché par
/// [SyncIndicator] + la date de dernière synchro réussie.
class SyncStatusState extends Equatable {
  final SyncStatus status;

  /// Epoch ms **heure serveur** (`page.serverTime`, jamais l'horloge device)
  /// de la dernière page de pull ayant ramené des données. `null` = jamais
  /// synchronisé (première install, ou uniquement des cycles sans nouveauté
  /// jusqu'ici). Persisté (survit au redémarrage) — un simple changement de
  /// [status] ne le régresse jamais.
  final int? lastSyncAtMs;

  /// Vrai si la file contient des écritures que le moteur RETIENT (attente
  /// d'une dépendance, ou écriture d'un autre compte de la tablette).
  ///
  /// Sert uniquement à rendre la feuille ATTEIGNABLE. Sans ce drapeau, elle ne
  /// s'ouvre que sur `syncConflict` : une file entièrement retenue affiche « à
  /// envoyer », n'est pas cliquable, et l'explication de l'attente — pourtant
  /// écrite en base — n'est visible nulle part.
  final bool hasHeldWork;

  const SyncStatusState({
    required this.status,
    this.lastSyncAtMs,
    this.hasHeldWork = false,
  });

  SyncStatusState copyWith({
    SyncStatus? status,
    int? lastSyncAtMs,
    bool? hasHeldWork,
  }) => SyncStatusState(
    status: status ?? this.status,
    lastSyncAtMs: lastSyncAtMs ?? this.lastSyncAtMs,
    hasHeldWork: hasHeldWork ?? this.hasHeldWork,
  );

  @override
  List<Object?> get props => [status, lastSyncAtMs, hasHeldWork];
}
