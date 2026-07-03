import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Corps JSON du POST de placement d'un cours à l'emploi du temps.
///
/// [day] est sérialisé en valeur wire (`MON`..`SAT`) ; [toJson] omet `room`
/// lorsqu'il est nul (champ optionnel côté contrat).
class CreateSessionRequestModel {
  final String coursId;
  final String academicYearId;

  /// Valeur wire majuscule (`MON`..`SAT`).
  final String day;
  final String timeSlotId;
  final String? room;

  const CreateSessionRequestModel({
    required this.coursId,
    required this.academicYearId,
    required this.day,
    required this.timeSlotId,
    this.room,
  });

  factory CreateSessionRequestModel.fromDomain(CreateSessionRequest request) =>
      CreateSessionRequestModel(
        coursId: request.coursId,
        academicYearId: request.academicYearId,
        day: request.day.wire,
        timeSlotId: request.timeSlotId,
        room: request.room,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'coursId': coursId,
      'academicYearId': academicYearId,
      'day': day,
      'timeSlotId': timeSlotId,
    };
    if (room != null) json['room'] = room;
    return json;
  }
}
