import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// Crée un créneau de sonnerie (une ligne de la grille).
class CreateTimeSlotUseCase {
  final ScheduleRepository _repository;

  const CreateTimeSlotUseCase(this._repository);

  Future<Either<Failure, TimeSlot>> call(CreateTimeSlotRequest request) =>
      _repository.createTimeSlot(request);
}
