import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
// Réutilise les enums de statut/erreur du BLoC online (calque de style, DRY).
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';

/// État unique offline-first du module Classe (CF2/CF3/CF4).
///
/// Calqué sur [ClassroomState] (online) : un seul état porteur, muté par
/// `copyWith`, exposant en parallèle les classes, le roster et la réassignation
/// — car l'écran d'organisation affiche ces trois zones simultanément.
///
/// La réassignation (CF4 Option A) est ONLINE : PAS d'état pending-sync. Ses
/// trois issues sont distinguées via [reassignStatus] + [reassignRePullFailed] :
///  - `failure`               → déplacement serveur KO (Left) ;
///  - `success` + `false`     → déplacement + re-pull local OK (Right(true)) ;
///  - `success` + `true`      → déplacement OK mais re-pull local KO, à retenter
///                              plus tard (Right(false), succès partiel).
class ClassroomOfflineState extends Equatable {
  // ── Classes (CF3) ──
  final ClassroomStatus classroomsStatus;
  final List<OfflineClassroom> classrooms;
  final ClassroomErrorType classroomsErrorType;

  // ── Roster d'une classe (CF3) ──
  final ClassroomStatus rosterStatus;
  final List<ClassroomMember> roster;
  final ClassroomErrorType rosterErrorType;

  // ── Pull delta (CF2) ──
  final ClassroomStatus syncStatus;

  /// Horodatage epoch ms de la dernière synchro (fraîcheur ADR-002), dérivé du
  /// `syncedAt` du bilan de pull.
  final int? freshness;

  // ── Réassignation ONLINE (CF4) ──
  final ClassroomStatus reassignStatus;
  final ClassroomErrorType reassignErrorType;
  final String reassigningMemberId;

  /// `true` uniquement après un succès partiel (Right(false)) : le déplacement
  /// serveur est acquis mais le re-pull local a échoué (à retenter).
  final bool reassignRePullFailed;

  const ClassroomOfflineState({
    this.classroomsStatus = ClassroomStatus.initial,
    this.classrooms = const [],
    this.classroomsErrorType = ClassroomErrorType.none,
    this.rosterStatus = ClassroomStatus.initial,
    this.roster = const [],
    this.rosterErrorType = ClassroomErrorType.none,
    this.syncStatus = ClassroomStatus.initial,
    this.freshness,
    this.reassignStatus = ClassroomStatus.initial,
    this.reassignErrorType = ClassroomErrorType.none,
    this.reassigningMemberId = '',
    this.reassignRePullFailed = false,
  });

  ClassroomOfflineState copyWith({
    ClassroomStatus? classroomsStatus,
    List<OfflineClassroom>? classrooms,
    ClassroomErrorType? classroomsErrorType,
    ClassroomStatus? rosterStatus,
    List<ClassroomMember>? roster,
    ClassroomErrorType? rosterErrorType,
    ClassroomStatus? syncStatus,
    Object? freshness = _undefined,
    ClassroomStatus? reassignStatus,
    ClassroomErrorType? reassignErrorType,
    String? reassigningMemberId,
    bool? reassignRePullFailed,
  }) => ClassroomOfflineState(
    classroomsStatus: classroomsStatus ?? this.classroomsStatus,
    classrooms: classrooms ?? this.classrooms,
    classroomsErrorType: classroomsErrorType ?? this.classroomsErrorType,
    rosterStatus: rosterStatus ?? this.rosterStatus,
    roster: roster ?? this.roster,
    rosterErrorType: rosterErrorType ?? this.rosterErrorType,
    syncStatus: syncStatus ?? this.syncStatus,
    freshness: identical(freshness, _undefined)
        ? this.freshness
        : freshness as int?,
    reassignStatus: reassignStatus ?? this.reassignStatus,
    reassignErrorType: reassignErrorType ?? this.reassignErrorType,
    reassigningMemberId: reassigningMemberId ?? this.reassigningMemberId,
    reassignRePullFailed: reassignRePullFailed ?? this.reassignRePullFailed,
  );

  @override
  List<Object?> get props => [
    classroomsStatus,
    classrooms,
    classroomsErrorType,
    rosterStatus,
    roster,
    rosterErrorType,
    syncStatus,
    freshness,
    reassignStatus,
    reassignErrorType,
    reassigningMemberId,
    reassignRePullFailed,
  ];
}

const _undefined = Object();
