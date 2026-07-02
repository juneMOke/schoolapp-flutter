import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';

/// États de la surface d'écriture (conseil pédagogique / admin).
///
/// `submitting` correspond à l'appel réseau en cours (l'UI désactive le bouton
/// et bloque le double envoi).
enum ScheduleEditStatus { initial, submitting, success, failure }

/// Sentinelle pour distinguer « champ non fourni » de « remis à null » dans
/// [ScheduleEditState.copyWith] (convention projet pour les champs nullable).
const _undefined = Object();

class ScheduleEditState extends Equatable {
  final ScheduleEditStatus status;

  /// Créneau créé, renseigné uniquement après un [TimeSlotCreated] réussi.
  final TimeSlot? lastCreatedTimeSlot;

  /// Séance créée, renseignée uniquement après un [SessionCreated] réussi.
  final Session? lastCreatedSession;

  final ScheduleErrorType errorType;

  /// Message d'erreur remonté (corps backend si présent). Null hors échec.
  final String? errorMessage;

  const ScheduleEditState({
    this.status = ScheduleEditStatus.initial,
    this.lastCreatedTimeSlot,
    this.lastCreatedSession,
    this.errorType = ScheduleErrorType.none,
    this.errorMessage,
  });

  bool get isSubmitting => status == ScheduleEditStatus.submitting;

  ScheduleEditState copyWith({
    ScheduleEditStatus? status,
    Object? lastCreatedTimeSlot = _undefined,
    Object? lastCreatedSession = _undefined,
    ScheduleErrorType? errorType,
    Object? errorMessage = _undefined,
  }) => ScheduleEditState(
    status: status ?? this.status,
    lastCreatedTimeSlot: identical(lastCreatedTimeSlot, _undefined)
        ? this.lastCreatedTimeSlot
        : lastCreatedTimeSlot as TimeSlot?,
    lastCreatedSession: identical(lastCreatedSession, _undefined)
        ? this.lastCreatedSession
        : lastCreatedSession as Session?,
    errorType: errorType ?? this.errorType,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
  );

  @override
  List<Object?> get props => [
    status,
    lastCreatedTimeSlot,
    lastCreatedSession,
    errorType,
    errorMessage,
  ];
}
