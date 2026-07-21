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

  const SyncStatusState({required this.status, this.lastSyncAtMs});

  SyncStatusState copyWith({SyncStatus? status, int? lastSyncAtMs}) =>
      SyncStatusState(
        status: status ?? this.status,
        lastSyncAtMs: lastSyncAtMs ?? this.lastSyncAtMs,
      );

  @override
  List<Object?> get props => [status, lastSyncAtMs];
}
