import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';

/// Ce qui lit la page d'un jour : sur la tablette pour le professeur, en
/// ligne pour la direction.
abstract interface class JournalDayLoader {
  /// Aujourd'hui, à l'heure de l'école.
  DateTime today();

  Future<Either<Failure, JournalDay>> call(
    DateTime date, {
    required AcademicYear year,
  });
}
