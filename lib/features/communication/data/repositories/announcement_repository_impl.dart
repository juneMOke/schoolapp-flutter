import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_api.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementApi _api;

  const AnnouncementRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<Announcement>>> list({String? academicYearId}) =>
      guardOnline(() => _api.list(academicYearId: academicYearId));

  @override
  Future<Either<Failure, Announcement>> get(String id) =>
      guardOnline(() => _api.get(id));

  @override
  Future<Either<Failure, Announcement>> create({
    required String id,
    required AnnouncementContent content,
    String? academicYearId,
  }) => guardOnline(
    () => _api.create(id: id, content: content, academicYearId: academicYearId),
  );

  @override
  Future<Either<Failure, Announcement>> update(
    String id,
    AnnouncementContent content, {
    required int version,
  }) => guardOnline(() => _api.update(id, content, version: version));

  @override
  Future<Either<Failure, Announcement>> schedule(
    String id, {
    required DateTime scheduledAt,
    required int version,
  }) => guardOnline(
    () => _api.gesture(
      id,
      AnnouncementGesture.schedule,
      version: version,
      scheduledAt: scheduledAt,
    ),
  );

  @override
  Future<Either<Failure, Announcement>> unschedule(
    String id, {
    required int version,
  }) => _gesture(id, AnnouncementGesture.unschedule, version);

  @override
  Future<Either<Failure, Announcement>> send(
    String id, {
    required int version,
  }) => _gesture(id, AnnouncementGesture.send, version);

  @override
  Future<Either<Failure, Announcement>> cancel(
    String id, {
    required int version,
  }) => _gesture(id, AnnouncementGesture.cancel, version);

  Future<Either<Failure, Announcement>> _gesture(
    String id,
    AnnouncementGesture gesture,
    int version,
  ) => guardOnline(() => _api.gesture(id, gesture, version: version));
}
