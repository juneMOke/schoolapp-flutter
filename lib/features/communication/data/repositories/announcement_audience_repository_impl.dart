import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_audience_api.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';

class AnnouncementAudienceRepositoryImpl
    implements AnnouncementAudienceRepository {
  final AnnouncementAudienceApi _api;

  const AnnouncementAudienceRepositoryImpl(this._api);

  @override
  Future<Either<Failure, AnnouncementReach>> reach(
    AnnouncementAudience audience,
  ) => guardOnline(() => _api.reach(audience));

  @override
  Future<Either<Failure, List<AudienceStudent>>> searchStudents(String query) =>
      guardOnline(() => _api.searchStudents(query));
}
