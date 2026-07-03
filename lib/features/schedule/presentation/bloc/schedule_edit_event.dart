import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';

sealed class ScheduleEditEvent extends Equatable {
  const ScheduleEditEvent();
}

/// Soumission de la création d'un créneau de sonnerie.
class TimeSlotCreated extends ScheduleEditEvent {
  final CreateTimeSlotRequest request;

  const TimeSlotCreated({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Soumission du placement d'un cours à l'emploi du temps.
class SessionCreated extends ScheduleEditEvent {
  final CreateSessionRequest request;

  const SessionCreated({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Soumission du retrait d'une séance.
class SessionDeleted extends ScheduleEditEvent {
  final String sessionId;

  const SessionDeleted({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Réinitialise l'état d'écriture (après succès/échec, ex. fermeture du
/// formulaire) pour repartir sur [ScheduleEditStatus.initial].
class ScheduleEditReset extends ScheduleEditEvent {
  const ScheduleEditReset();

  @override
  List<Object?> get props => [];
}
