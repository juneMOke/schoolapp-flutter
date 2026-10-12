import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_api.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_audience_api.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_template_api.dart';
import 'package:school_app_flutter/features/communication/data/repositories/announcement_audience_repository_impl.dart';
import 'package:school_app_flutter/features/communication/data/repositories/announcement_repository_impl.dart';
import 'package:school_app_flutter/features/communication/data/repositories/announcement_template_repository_impl.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';

/// Les communiqués aux parents — **en ligne seulement** : ni table locale, ni
/// outbox, ni flux `/sync`. Rangé avec les branches parce que c'est le seul
/// point d'extension que les modules éditent pour la DI.
void registerCommunication(GetIt getIt) {
  Map<String, dynamic> extras() => getIt<Map<String, dynamic>>();

  getIt
    ..registerLazySingleton<AnnouncementRepository>(
      () => AnnouncementRepositoryImpl(AnnouncementApi(getIt<Dio>(), extras())),
    )
    ..registerLazySingleton<AnnouncementAudienceRepository>(
      () => AnnouncementAudienceRepositoryImpl(
        AnnouncementAudienceApi(getIt<Dio>(), extras()),
      ),
    )
    ..registerLazySingleton<AnnouncementTemplateRepository>(
      () => AnnouncementTemplateRepositoryImpl(
        AnnouncementTemplateApi(getIt<Dio>(), extras()),
      ),
    );
}
