import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_natures_for_year_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/data/control/fee_control_export_api.dart';
import 'package:school_app_flutter/features/recouvrement/data/control/fee_control_export_repository_impl.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_api.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_cache_dao.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_repository_impl.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/fee_control_export_repository.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_catalog_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_student_sheet_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Recouvrement v2 ▸ Tableau de bord : calculé par le serveur, la dernière
/// photo datée hors ligne. Ordre : source → dépôt → cubits (en factory).
void registerRecouvrementV2(GetIt getIt) {
  getIt.registerLazySingleton<RecoveryDashboardApi>(
    () => RecoveryDashboardApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
  );
  getIt.registerLazySingleton<RecoveryDashboardCacheDao>(
    () => RecoveryDashboardCacheDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<RecoveryDashboardRepository>(
    () => RecoveryDashboardRepositoryImpl(
      api: getIt<RecoveryDashboardApi>(),
      cache: getIt<RecoveryDashboardCacheDao>(),
      currentUser: getIt<CurrentUserContext>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );
  getIt.registerFactory<RecoveryDashboardCubit>(
    () => RecoveryDashboardCubit(
      repository: getIt<RecoveryDashboardRepository>(),
      countPending: getIt<CountPendingPaymentsUseCase>(),
    ),
  );
  registerRecouvrementV2Sheet(getIt);
  getIt.registerLazySingleton<FeeControlExportRepository>(
    () => FeeControlExportRepositoryImpl(
      api: FeeControlExportApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
      countPending: getIt<CountPendingPaymentsUseCase>(),
    ),
  );
  getIt.registerFactory<RecoveryCatalogCubit>(
    () => RecoveryCatalogCubit(
      getNatures: getIt<GetFeeNaturesForYearUseCase>(),
      getClassrooms: getIt<GetOfflineClassroomsUseCase>(),
    ),
  );
  getIt.registerFactory<RecoveryStudentsCubit>(
    () => RecoveryStudentsCubit(
      repository: getIt<RecoveryDashboardRepository>(),
      countPending: getIt<CountPendingPaymentsUseCase>(),
    ),
  );
}

/// La fiche d'un élève ouverte depuis le tableau de bord (O4), lue sur
/// l'appareil.
void registerRecouvrementV2Sheet(GetIt getIt) {
  getIt.registerFactory<RecoveryStudentSheetCubit>(
    () => RecoveryStudentSheetCubit(
      search: getIt<SearchLocalEnrollmentsUseCase>(),
      getNatures: getIt<GetFeeNaturesForYearUseCase>(),
      getPositions: getIt<GetRecoveryPositionsUseCase>(),
    ),
  );
}
