import 'package:equatable/equatable.dart';

sealed class TimetableEvent extends Equatable {
  const TimetableEvent();
}

/// Demande l'emploi du temps de l'enseignant connecté pour [academicYearId].
///
/// L'[academicYearId] est fourni par l'appelant (ex. depuis l'année courante du
/// `BootstrapBloc`) — le module `schedule` ne dépend pas directement du
/// bootstrap.
class TimetableRequested extends TimetableEvent {
  final String academicYearId;

  const TimetableRequested({required this.academicYearId});

  @override
  List<Object?> get props => [academicYearId];
}

/// Demande la grille d'emploi du temps d'une classe (conseil pédagogique).
class ClassroomGridRequested extends TimetableEvent {
  final String classroomId;
  final String academicYearId;

  const ClassroomGridRequested({
    required this.classroomId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, academicYearId];
}
