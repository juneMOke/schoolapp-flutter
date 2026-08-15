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

  /// Vrai si le dernier cycle de **lecture** n'a pas tout ramené (ADR-015 F1).
  ///
  /// Porté à part de [status] et non déduit de lui, pour la même raison que
  /// [hasHeldWork] : quatre conditions plus urgentes (hors-ligne, flush,
  /// reconnexion, conflit) masquent [SyncStatus.partiallySynced] sur la
  /// pastille. Déduire la dégradation du statut affiché la rendrait invisible
  /// dans la feuille précisément quand elle se cumule à autre chose.
  final bool hasIncompleteRead;

  /// Sous-ensemble de [hasIncompleteRead] : la lecture a échoué sur au moins
  /// une ressource, et **un nouvel essai peut aboutir**.
  ///
  /// Distingué parce qu'un droit manquant, lui, se reproduira à l'identique à
  /// chaque cycle : offrir une reprise dans ce cas serait promettre un geste
  /// qui ne lève rien.
  final bool hasRetriableRead;

  const SyncStatusState({
    required this.status,
    this.lastSyncAtMs,
    this.hasHeldWork = false,
    this.hasIncompleteRead = false,
    this.hasRetriableRead = false,
  });

  SyncStatusState copyWith({
    SyncStatus? status,
    int? lastSyncAtMs,
    bool? hasHeldWork,
    bool? hasIncompleteRead,
    bool? hasRetriableRead,
  }) => SyncStatusState(
    status: status ?? this.status,
    lastSyncAtMs: lastSyncAtMs ?? this.lastSyncAtMs,
    hasHeldWork: hasHeldWork ?? this.hasHeldWork,
    hasIncompleteRead: hasIncompleteRead ?? this.hasIncompleteRead,
    hasRetriableRead: hasRetriableRead ?? this.hasRetriableRead,
  );

  @override
  List<Object?> get props => [
    status,
    lastSyncAtMs,
    hasHeldWork,
    hasIncompleteRead,
    hasRetriableRead,
  ];
}
