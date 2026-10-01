import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Ce que montrent la carte et la ligne d'un registre, pour un agent comme
/// pour un élève : qui, son statut du jour, ses heures, sa justification et
/// où en est l'envoi. Chaque module la construit depuis sa propre ligne.
class PresenceRowView extends Equatable {
  /// Identifiant de la personne : clé de la carte et teinte de l'avatar.
  final String personId;
  final String firstName;
  final String lastName;

  /// La ligne de tête (« Nom Post-nom »).
  final String title;

  /// La ligne d'appoint (« Prénom · Fonction », « Prénom · N° 14 · 6e A »).
  final String subtitle;

  final PresenceStatus status;
  final ClockTime? arrival;
  final ClockTime? departure;

  /// Minutes comptées depuis le début des cours ; 0 hors retard.
  final int lateMinutes;

  /// Le motif posé, en toutes lettres ; `null` = pas de justification.
  final String? justificationLabel;

  final RecordSyncState sync;

  /// Pourquoi l'envoi a été refusé ; `null` tant qu'il ne l'est pas. Seule une
  /// ligne refusée propose « Réessayer ».
  final String? refusal;

  /// « Justifier » est proposé. Sinon, un motif déjà posé se lit sans se
  /// toucher, et rien ne s'affiche à sa place.
  final bool canJustify;

  const PresenceRowView({
    required this.personId,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.subtitle,
    required this.status,
    this.arrival,
    this.departure,
    this.lateMinutes = 0,
    this.justificationLabel,
    this.sync = RecordSyncState.synced,
    this.refusal,
    this.canJustify = true,
  });

  bool get isJustified => justificationLabel != null;

  @override
  List<Object?> get props => [
    personId,
    firstName,
    lastName,
    title,
    subtitle,
    status,
    arrival,
    departure,
    lateMinutes,
    justificationLabel,
    sync,
    refusal,
    canJustify,
  ];
}

/// Les gestes sur la personne d'une ligne, **partagés** par la carte de la
/// grille et la ligne de la liste. Chaque module les relie à son état ; un
/// geste refusé (droits, jour figé) s'annonce au lieu d'écrire.
abstract interface class PresenceRowActions {
  /// Un toucher sur la carte : présent › en retard › absent › présent.
  void cycle();

  /// Un choix direct (vue liste) ; retoucher le statut actif l'efface.
  void choose(PresenceStatus status);

  /// Remet « à pointer ».
  void clear();

  /// Renvoie une ligne refusée.
  void retry();

  Future<void> editArrival();

  Future<void> justify();
}
