import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/helpers/owner_scoped_value.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_api.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_audience_api.dart';
import 'package:school_app_flutter/features/communication/data/online/announcement_template_api.dart';
import 'package:school_app_flutter/features/communication/data/repositories/announcement_audience_repository_impl.dart';
import 'package:school_app_flutter/features/communication/data/repositories/announcement_repository_impl.dart';
import 'package:school_app_flutter/features/communication/data/repositories/announcement_template_repository_impl.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_factory.dart';
import 'package:uuid/uuid.dart';

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

  getIt.registerFactory(
    () => AnnouncementWriter(getIt<AnnouncementRepository>()),
  );

  // ── Écrans : cubits en fabrique, jamais singleton ──
  getIt
    // Les filtres de la liste survivent à la navigation pendant la session,
    // scopés au compte et à l'école.
    ..registerLazySingleton<OwnerScopedValue<AnnouncementFilters>>(
      () => OwnerScopedValue(
        const AnnouncementFilters(),
        owner: () {
          final user = getIt<CurrentUserContext>();
          return '${user.uid}@${user.schoolId}';
        },
      ),
    )
    // Chaque ouverture de l'éditeur tire un cubit neuf de cette fabrique.
    ..registerFactory(
      () => AnnouncementEditorFactory(
        writer: getIt<AnnouncementWriter>(),
        uuid: getIt<Uuid>(),
      ),
    )
    ..registerFactory(
      () => AnnouncementsCubit(
        repository: getIt<AnnouncementRepository>(),
        memory: getIt<OwnerScopedValue<AnnouncementFilters>>(),
      ),
    );
}
