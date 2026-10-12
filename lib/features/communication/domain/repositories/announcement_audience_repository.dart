import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';

/// Ce que le serveur sait des destinataires, et la tablette non : les
/// tuteurs, leurs numéros, les créances échues.
abstract class AnnouncementAudienceRepository {
  /// La portée de [audience] à l'instant, et l'activation de WhatsApp.
  Future<Either<Failure, AnnouncementReach>> reach(
    AnnouncementAudience audience,
  );

  /// Huit élèves actifs au plus dont le nom ou la classe contient [query]
  /// (deux caractères au moins).
  Future<Either<Failure, List<AudienceStudent>>> searchStudents(String query);
}
