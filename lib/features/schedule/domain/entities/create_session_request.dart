import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Corps de placement d'un cours à l'emploi du temps (POST /sessions).
///
/// Le backend refuse (HTTP 409) un double-booking enseignant **ou** classe
/// (même jour + même créneau déjà pris) et (HTTP 400) un cours sans enseignant
/// affecté ; ces cas sont surfacés distinctement par le BLoC d'écriture.
class CreateSessionRequest extends Equatable {
  final String coursId;
  final String academicYearId;
  final Weekday day;
  final String timeSlotId;

  /// Salle de cours, optionnelle (max. 64 caractères côté backend).
  final String? room;

  const CreateSessionRequest({
    required this.coursId,
    required this.academicYearId,
    required this.day,
    required this.timeSlotId,
    this.room,
  });

  @override
  List<Object?> get props => [coursId, academicYearId, day, timeSlotId, room];
}
