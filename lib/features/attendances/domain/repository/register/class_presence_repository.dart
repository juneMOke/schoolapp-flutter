import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';

/// Une journée d'appel : la classe, l'année et le jour `YYYY-MM-DD`.
typedef ClassDayKey = ({String classroomId, String academicYearId, String day});

/// Un mois d'appel : la classe, l'année et le mois `YYYY-MM`.
typedef ClassMonthKey = ({
  String classroomId,
  String academicYearId,
  String month,
});

/// L'appel d'une classe (Présences des élèves v2) : lecture 100 % locale,
/// brouillon local, envoi de l'appel entier à la validation.
abstract class ClassPresenceRepository {
  /// L'appel d'un jour : la classe entière, ses marques (brouillon ou appel
  /// validé), l'état de l'envoi, l'horaire et la clôture du mois.
  Future<Either<Failure, ClassPresenceDay>> loadDay(ClassDayKey key);

  /// Écrit des marques dans le brouillon ; une marque « à pointer » retire la
  /// ligne. Rien ne part.
  Future<Either<Failure, Unit>> saveMarks(
    ClassDayKey key,
    Map<String, PresenceMark<AbsenceReason>> marks,
  );

  /// Valide l'appel : la classe entière (tous pointés) devient la session
  /// envoyée ; le brouillon est vidé.
  Future<Either<Failure, Unit>> validateDay(
    ClassDayKey key,
    List<ClassPresenceLine> lines,
  );

  /// Rouvre un appel validé : ses marques reviennent au brouillon. Rien ne
  /// part avant la revalidation.
  Future<Either<Failure, Unit>> reopenDay(
    ClassDayKey key,
    List<ClassPresenceLine> lines,
  );

  /// Remet en file l'envoi refusé d'un appel validé.
  Future<Either<Failure, Unit>> retryDay(ClassDayKey key);

  /// Les appels validés d'un mois, la clôture et l'état de leur envoi.
  Future<Either<Failure, ClassPresenceMonth>> loadMonth(ClassMonthKey key);
}
