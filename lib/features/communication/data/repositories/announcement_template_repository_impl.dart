import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_template_api.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';

class AnnouncementTemplateRepositoryImpl
    implements AnnouncementTemplateRepository {
  final AnnouncementTemplateApi _api;

  const AnnouncementTemplateRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<AnnouncementTemplate>>> list() =>
      guardOnline(_api.list);

  @override
  Future<Either<Failure, AnnouncementTemplate>> create({
    required AnnouncementCategory category,
    required String title,
    required String body,
  }) => guardOnline(
    () => _api.create(category: category, title: title, body: body),
  );

  @override
  Future<Either<Failure, AnnouncementTemplate>> update(
    AnnouncementTemplate template,
  ) => guardOnline(() => _api.update(template));

  @override
  Future<Either<Failure, Unit>> delete(String id) => guardOnline(() async {
    await _api.delete(id);
    return unit;
  });
}
