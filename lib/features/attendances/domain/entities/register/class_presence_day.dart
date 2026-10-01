import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';

/// L'appel d'une classe pour un jour, tel que la tablette le connaît.
///
/// Trois états, lus de la base :
/// - **à faire** : aucune session, les marques posées vivent dans le
///   brouillon (jamais envoyé) ;
/// - **validé** : une session existe — c'est l'appel envoyé (ou en partance) ;
/// - **rouvert** : une session existe, mais elle a été rouverte sur cette
///   tablette ; le brouillon porte les marques en cours de correction.
class ClassPresenceDay extends Equatable {
  final String classroomId;
  final String academicYearId;

  /// `YYYY-MM-DD`.
  final String day;

  /// Toute la classe, par numéro d'ordre.
  final List<ClassPresenceLine> lines;
  final bool hasSession;
  final bool reopened;

  /// L'auteur nommé par le serveur ; `null` tant qu'il ne l'a pas dit.
  final String? takenBy;

  /// Le dernier envoi de l'appel (epoch ms) — la validation, ou une
  /// justification ajoutée après coup.
  final int? lastSentAt;

  /// Où en est l'envoi de l'appel validé.
  final RecordSyncState sync;

  /// Pourquoi le serveur a refusé l'appel ; `null` sinon.
  final String? refusal;

  final bool monthClosed;
  final PresenceSchedule schedule;

  const ClassPresenceDay({
    required this.classroomId,
    required this.academicYearId,
    required this.day,
    required this.lines,
    required this.hasSession,
    required this.reopened,
    required this.schedule,
    this.takenBy,
    this.lastSentAt,
    this.sync = RecordSyncState.synced,
    this.refusal,
    this.monthClosed = false,
  });

  /// L'appel est validé : la journée est verrouillée.
  bool get validated => hasSession && !reopened;

  @override
  List<Object?> get props => [
    classroomId,
    academicYearId,
    day,
    lines,
    hasSession,
    reopened,
    takenBy,
    lastSentAt,
    sync,
    refusal,
    monthClosed,
    schedule,
  ];
}
