import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/core/di/request_options_extra.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/binary_safe_log_interceptor.dart';
import 'package:school_app_flutter/core/network/dio_client.dart';
import 'package:school_app_flutter/features/attendances/data/remote/attendance_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/attendance_stats_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/disciplinary_case_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/attendance_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/attendance_stats_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/disciplinary_case_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_stats_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/create_disciplinary_case_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_overview_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_disciplinary_case_detail_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_disciplinary_case_list_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/load_daily_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/course_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/course_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_cours_notation_detail_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_my_courses_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/saisir_note_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/evaluation_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_bloc.dart';
import 'package:school_app_flutter/features/resultats/data/datasources/resultats_remote_data_source.dart';
import 'package:school_app_flutter/features/resultats/data/repositories/resultats_repository_impl.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_periodes_scolaires_usecase.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultat_focus_usecase.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultats_classe_usecase.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/search_roster_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_bloc.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_offline_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_session_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_time_slot_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/delete_session_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_classroom_grid_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_my_timetable_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_edit_bloc.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_bloc.dart';
import 'package:school_app_flutter/features/academic_year/data/datasources/enrollment_academic_info_remote_data_source.dart';
import 'package:school_app_flutter/features/academic_year/data/repositories/academic_year_context_repository_impl.dart';
import 'package:school_app_flutter/features/school/data/repositories/school_repository_impl.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/features/academic_year/data/repositories/enrollment_academic_info_repository_impl.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/enrollment_academic_info_repository.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/update_enrollment_academic_info_use_case.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/enrollment_academic_info_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/forgot_password_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/repositories/forgot_password_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/storage/shared_document_cache.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/password_verifier_service.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/data/interceptors/server_contact_interceptor.dart';
import 'package:school_app_flutter/features/auth/data/interceptors/auth_refresh_interceptor.dart';
import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresh_reauthenticator.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresher.dart';
import 'package:school_app_flutter/features/auth/domain/session_revocation_bus.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:school_app_flutter/features/auth/domain/repositories/forgot_password_repository.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/generate_otp_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/login_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/logout_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/validate_otp_use_case.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/classes/data/datasources/classroom_remote_data_source.dart';
import 'package:school_app_flutter/features/classes/data/repositories/classroom_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/distribute_students_to_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_members_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_level_distribution_overview_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_stats_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_bloc.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';
import 'package:school_app_flutter/features/documents/data/repositories/editique_repository_impl.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
// Import debug — la mémoire d'imprimante du banc, sous kDebugMode.
import 'package:school_app_flutter/dev/ticket_bench_printer_store.dart';
import 'package:school_app_flutter/features/documents/data/printing/permission_handler_thermal_permission.dart';
import 'package:school_app_flutter/features/documents/data/printing/print_bluetooth_thermal_channel.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_adapter.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_channel.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/restitute_document_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_account_statement_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_enrollment_attestation_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_financial_clearance_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_note_perception_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_stats_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_preview_by_student_id_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_stats_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_academic_info_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/features/finance/data/datasources/finance_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/datasources/payments_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/datasources/student_charges_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:school_app_flutter/features/finance/data/repositories/payments_repository_impl.dart';
import 'package:school_app_flutter/features/finance/data/repositories/student_charges_repository_impl.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/create_payment_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_fee_tariffs_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_finance_stats_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_from_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payments_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/update_student_charge_expected_amount_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/initialize_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/student/data/datasources/parent_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/datasources/student_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/repositories/parent_repository_impl.dart';
import 'package:school_app_flutter/features/student/data/repositories/student_repository_impl.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_repository.dart';
import 'package:school_app_flutter/features/student/domain/usecases/create_parent_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/unlink_parent_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_parent_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_academic_info_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_address_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_personal_info_use_case.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/parent_bloc.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';

final GetIt getIt = GetIt.instance;

/// Nom d'instance du `Dio` **nu** (sans intercepteur d'auth/refresh) : partagé
/// par le refresher et par le rejeu de requête, pour éviter toute ré-entrance.
const String _bareDioInstanceName = 'bareDio';

Future<void> configureDependencies({
  EnvConfig? envConfig,
  Database? offlineDatabase,
}) async {
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ── Socle offline (base chiffrée + outbox + moteur de synchro) ──────────────
  // Ouvre la base SQLCipher et enregistre DAOs/moteur/connectivité. Doit
  // précéder les features (qui liront le cache / écriront dans l'outbox).
  // `offlineDatabase` permet aux tests d'injecter une base ffi en mémoire.
  await registerOfflineCore(getIt, database: offlineDatabase);

  final resolvedEnvConfig = envConfig ?? EnvConfig.fromDartDefines();
  getIt.registerLazySingleton<EnvConfig>(() => resolvedEnvConfig);

  // Dio **nu** (aucun intercepteur d'auth/refresh) : sert au refresh token et
  // au rejeu de la requête d'origine, sans ré-entrance (ADR-010 §7.2).
  getIt.registerLazySingleton<Dio>(
    () => createDioClient(getIt<EnvConfig>()),
    instanceName: _bareDioInstanceName,
  );

  // Rotation du refresh token : instance **unique**. Le single-flight n'a de
  // sens que partagé — l'intercepteur 401, le mint proactif et la
  // ré-authentification de la boucle de synchro doivent coalescer sur le même
  // appel `/auth/refresh`, sinon une rafale de flush émet autant de rotations
  // concurrentes que de requêtes (et le serveur révoque le jeton présenté à
  // chaque rotation : toutes échouent sauf une).
  getIt.registerLazySingleton<TokenRefresher>(
    () => TokenRefresher(
      bareDio: getIt<Dio>(instanceName: _bareDioInstanceName),
      tokenStorage: getIt<TokenStorageService>(),
      sessionManager: getIt<AuthSessionManager>(),
      revocationBus: getIt<SessionRevocationBus>(),
    ),
  );

  // Ré-authentification silencieuse au retour réseau : consommée par la boucle
  // de synchro (`core/offline`) AVANT tout appel authentifié.
  getIt.registerLazySingleton<SessionReauthenticator>(
    () => TokenRefreshReauthenticator(
      tokenStorage: getIt<TokenStorageService>(),
      refresher: getIt<TokenRefresher>(),
    ),
  );

  getIt.registerLazySingleton<Dio>(() {
    final envConfig = getIt<EnvConfig>();
    final dio = createDioClient(envConfig);
    final bareDio = getIt<Dio>(instanceName: _bareDioInstanceName);
    final refresher = getIt<TokenRefresher>();

    if (envConfig.enableVerboseNetworkLogging) {
      // `BinarySafeLogInterceptor` et non `LogInterceptor` : les routes
      // d'éditique rendent des PDF, et `Uint8List.toString()` déverserait des
      // dizaines de milliers d'entiers sur une seule ligne de console.
      dio.interceptors.add(BinarySafeLogInterceptor());
    }

    // Refresh transparent AVANT le mapping d'erreurs : sur 401 authentifié,
    // refresh + rejeu ; sinon laisse le 401 suivre vers le mapping ci-dessous.
    dio.interceptors.add(
      AuthRefreshInterceptor(refresher: refresher, retryDio: bareDio),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] ?? false;
          if (requiresAuth) {
            final tokenStorage = getIt<TokenStorageService>();
            var session = await tokenStorage.readAuthSession();
            if (session == null || session.accessToken.isEmpty) {
              // Mint PROACTIF (V1.1, revue adversariale) : après une
              // déconsignation, l'access est vide. Ne pas compter sur un 401
              // « header absent » du serveur — certaines configs Spring
              // répondent 403, que les handlers d'outbox classent TERMINAL
              // (SYNC_ERROR immédiat, argent compris). Single-flight : les
              // rafales d'un flush ne mintent qu'une fois ; sans refresh
              // token, `refresh()` retourne null sans effet.
              final minted = await refresher.refresh();
              if (minted != null) {
                session = await tokenStorage.readAuthSession();
              }
            }
            if (session != null && session.accessToken.isNotEmpty) {
              options.headers['Authorization'] =
                  'Bearer ${session.accessToken}';
              // Trace l'identité du JWT attaché : le ServerContactInterceptor
              // ne doit créditer un contact serveur qu'à l'utilisateur sous le
              // JWT duquel la requête est réellement partie (ADR-010, filtre
              // d'identité — une réponse tardive d'un autre compte ne doit ni
              // ré-ancrer la fraîcheur ni alimenter la révocation).
              options.extra[ServerContactInterceptor.authUidExtra] =
                  session.user.id;
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: const InvalidCredentialsFailure('Invalid credentials'),
                type: e.type,
              ),
            );
          } else if (e.response?.statusCode == 403) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: const UnauthorizedFailure('Access forbidden'),
                type: e.type,
              ),
            );
          } else if (e.response?.statusCode == 404) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: const NotFoundFailure('Resource not found'),
                type: e.type,
              ),
            );
          } else if (e.response?.statusCode == 409) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: const ConflictFailure('Conflict — stale version'),
                type: e.type,
              ),
            );
          } else if (e.response?.statusCode == 400 ||
              e.response?.statusCode == 422) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: const ValidationFailure('Invalid request data'),
                type: e.type,
              ),
            );
          } else if (e.response?.statusCode != null &&
              e.response!.statusCode! >= 500) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                error: const ServerFailure('Server error'),
                type: e.type,
              ),
            );
          }
          return handler.next(e);
        },
      ),
    );

    // Observateur de contact serveur (ADR-010 §7.3) : capte `X-User-Version` +
    // header `Date` sur chaque réponse authentifiée pour alimenter l'ancre
    // temporelle et la révocation offline. Ne wipe ni ne rejette jamais.
    dio.interceptors.add(ServerContactInterceptor(getIt<AuthSessionManager>()));

    return dio;
  });

  getIt.registerLazySingleton<Map<String, dynamic>>(
    () => RequestOptionsExtra.auth(),
  );

  getIt.registerLazySingleton<TokenStorageService>(
    () => TokenStorageService(getIt<FlutterSecureStorage>()),
  );

  // Session offline (ADR-010) : vérificateur Argon2id + manager central
  // (auth_local + secure storage + fraîcheur/révocation/wipe) + bus de révocation.
  getIt.registerLazySingleton<PasswordVerifierService>(
    () => const PasswordVerifierService(),
  );
  getIt.registerLazySingleton<SessionRevocationBus>(
    () => SessionRevocationBus(),
  );
  getIt.registerLazySingleton<AuthSessionManager>(
    () => AuthSessionManager(
      tokenStorage: getIt<TokenStorageService>(),
      authLocalDao: getIt<AuthLocalDao>(),
      verifier: getIt<PasswordVerifierService>(),
      revocationBus: getIt<SessionRevocationBus>(),
      currentUser: getIt<CurrentUserContext>(),
      currentPermissions: getIt<CurrentPermissions>(),
      sharedDocumentCache: getIt<SharedDocumentCache>(),
    ),
  );

  getIt.registerLazySingleton<SharedDocumentCache>(
    () => const SharedDocumentCache(),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ForgotPasswordRemoteDataSource>(
    () => ForgotPasswordRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<TokenStorageService>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      sessionManager: getIt<AuthSessionManager>(),
    ),
  );

  getIt.registerLazySingleton<ForgotPasswordRepository>(
    () => ForgotPasswordRepositoryImpl(
      remoteDataSource: getIt<ForgotPasswordRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );

  getIt.registerFactory<GenerateOtpUseCase>(
    () => GenerateOtpUseCase(getIt<ForgotPasswordRepository>()),
  );

  getIt.registerFactory<ValidateOtpUseCase>(
    () => ValidateOtpUseCase(getIt<ForgotPasswordRepository>()),
  );

  getIt.registerFactory<ResetPasswordUseCase>(
    () => ResetPasswordUseCase(getIt<AuthRepository>()),
  );

  getIt.registerFactory<CheckAuthStatusUseCase>(
    () => CheckAuthStatusUseCase(getIt<AuthRepository>()),
  );

  getIt.registerFactory<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      checkAuthStatusUseCase: getIt<CheckAuthStatusUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
      repository: getIt<AuthRepository>(),
      sessionManager: getIt<AuthSessionManager>(),
      revocationBus: getIt<SessionRevocationBus>(),
    ),
  );

  getIt.registerFactory<ForgotPasswordBloc>(
    () => ForgotPasswordBloc(
      generateOtpUseCase: getIt<GenerateOtpUseCase>(),
      validateOtpUseCase: getIt<ValidateOtpUseCase>(),
    ),
  );

  getIt.registerLazySingleton<EnrollmentRemoteDataSource>(
    () => EnrollmentRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<EnrollmentRepository>(
    () => EnrollmentRepositoryImpl(
      remoteDataSource: getIt<EnrollmentRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerLazySingleton<EnrollmentStatsRepository>(
    () => EnrollmentStatsRepositoryImpl(
      remoteDataSource: getIt<EnrollmentRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<GetEnrollmentSummaryListByStatusUseCase>(
    () =>
        GetEnrollmentSummaryListByStatusUseCase(getIt<EnrollmentRepository>()),
  );

  getIt.registerFactory<GetEnrollmentDetailUseCase>(
    () => GetEnrollmentDetailUseCase(getIt<EnrollmentRepository>()),
  );

  getIt.registerFactory<GetEnrollmentPreviewByStudentIdUseCase>(
    () => GetEnrollmentPreviewByStudentIdUseCase(getIt<EnrollmentRepository>()),
  );

  getIt.registerFactory<
    SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
  >(
    () => SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase(
      getIt<EnrollmentRepository>(),
    ),
  );

  getIt.registerFactory<
    SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
  >(
    () =>
        SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase(
          getIt<EnrollmentRepository>(),
        ),
  );

  getIt.registerFactory<
    SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
  >(
    () => SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase(
      getIt<EnrollmentRepository>(),
    ),
  );

  getIt.registerFactory<SearchEnrollmentSummaryByAcademicInfoUseCase>(
    () => SearchEnrollmentSummaryByAcademicInfoUseCase(
      getIt<EnrollmentRepository>(),
    ),
  );

  getIt.registerFactory<GetEnrollmentStatsUseCase>(
    () => GetEnrollmentStatsUseCase(getIt<EnrollmentStatsRepository>()),
  );

  getIt.registerFactory<EnrollmentBloc>(
    () => EnrollmentBloc(
      getEnrollmentSummariesUseCase:
          getIt<GetEnrollmentSummaryListByStatusUseCase>(),
      getEnrollmentDetailUseCase: getIt<GetEnrollmentDetailUseCase>(),
      getEnrollmentPreviewByStudentIdUseCase:
          getIt<GetEnrollmentPreviewByStudentIdUseCase>(),
      searchByStudentNameUseCase:
          getIt<
            SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
          >(),
      searchByStudentNamesAndDateOfBirthUseCase:
          getIt<
            SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
          >(),
      searchByDateOfBirthUseCase:
          getIt<
            SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
          >(),
      searchByAcademicInfoUseCase:
          getIt<SearchEnrollmentSummaryByAcademicInfoUseCase>(),
    ),
  );

  getIt.registerFactory<EnrollmentStatsBloc>(
    () => EnrollmentStatsBloc(
      getEnrollmentStatsUseCase: getIt<GetEnrollmentStatsUseCase>(),
    ),
  );

  // ── Classes ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ClassroomRemoteDataSource>(
    () => ClassroomRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ClassroomRepository>(
    () => ClassroomRepositoryImpl(
      remoteDataSource: getIt<ClassroomRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<GetClassroomsUseCase>(
    () => GetClassroomsUseCase(getIt<ClassroomRepository>()),
  );

  getIt.registerFactory<GetClassroomMembersUseCase>(
    () => GetClassroomMembersUseCase(getIt<ClassroomRepository>()),
  );

  getIt.registerFactory<DistributeStudentsToClassroomsUseCase>(
    // offlineRepository résolu paresseusement (registerOfflineModules) : repull
    // local du miroir des classes après une répartition serveur réussie.
    () => DistributeStudentsToClassroomsUseCase(
      repository: getIt<ClassroomRepository>(),
      offlineRepository: getIt<ClassroomOfflineRepository>(),
    ),
  );

  getIt.registerFactory<GetLevelDistributionOverviewUseCase>(
    () => GetLevelDistributionOverviewUseCase(getIt<ClassroomRepository>()),
  );

  getIt.registerFactory<GetClassroomStatsUseCase>(
    () => GetClassroomStatsUseCase(getIt<ClassroomRepository>()),
  );

  getIt.registerFactory<ClassroomBloc>(
    () => ClassroomBloc(
      getClassroomsUseCase: getIt<GetClassroomsUseCase>(),
      getClassroomMembersUseCase: getIt<GetClassroomMembersUseCase>(),
      // Roster consultation offline-first (CF3) : lecture locale
      // (ref_classroom_members). GetClassroomMembersUseCase reste utilisé par le
      // handler batch (organisation). Résolu paresseusement (registerOfflineModules).
      getOfflineRosterUseCase: getIt<GetOfflineRosterUseCase>(),
      distributeStudentsToClassroomsUseCase:
          getIt<DistributeStudentsToClassroomsUseCase>(),
      getLevelDistributionOverviewUseCase:
          getIt<GetLevelDistributionOverviewUseCase>(),
    ),
  );

  getIt.registerFactory<ClassroomStatsBloc>(
    () => ClassroomStatsBloc(
      getClassroomStatsUseCase: getIt<GetClassroomStatsUseCase>(),
    ),
  );

  // ── Student ───────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(
      remoteDataSource: getIt<StudentRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<UpdateStudentPersonalInfoUseCase>(
    () => UpdateStudentPersonalInfoUseCase(getIt<StudentRepository>()),
  );

  getIt.registerFactory<UpdateStudentAddressUseCase>(
    () => UpdateStudentAddressUseCase(getIt<StudentRepository>()),
  );

  getIt.registerLazySingleton<UpdateStudentAcademicInfoUseCase>(
    () => UpdateStudentAcademicInfoUseCase(getIt<StudentRepository>()),
  );
  getIt.registerFactory<StudentBloc>(
    () => StudentBloc(
      updatePersonalInfoUseCase: getIt<UpdateStudentPersonalInfoUseCase>(),
      updateAddressUseCase: getIt<UpdateStudentAddressUseCase>(),
      updateAcademicInfoUseCase: getIt<UpdateStudentAcademicInfoUseCase>(),
    ),
  );

  // ── Parent ───────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ParentRemoteDataSource>(
    () => ParentRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ParentRepository>(
    () =>
        ParentRepositoryImpl(
              remoteDataSource: getIt<ParentRemoteDataSource>(),
              requiredAuth: getIt<Map<String, dynamic>>(),
            )
            as ParentRepository,
  );

  getIt.registerFactory<UpdateParentUseCase>(
    () => UpdateParentUseCase(getIt<ParentRepository>()),
  );

  getIt.registerFactory<CreateParentUseCase>(
    () => CreateParentUseCase(getIt<ParentRepository>()),
  );

  getIt.registerFactory<UnlinkParentUseCase>(
    () => UnlinkParentUseCase(getIt<ParentRepository>()),
  );

  getIt.registerFactory<ParentBloc>(
    () => ParentBloc(
      updateParentUseCase: getIt<UpdateParentUseCase>(),
      createParentUseCase: getIt<CreateParentUseCase>(),
      unlinkParentUseCase: getIt<UnlinkParentUseCase>(),
    ),
  );

  // ── Enrollment Academic Info ───────────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentAcademicInfoRemoteDataSource>(
    () => EnrollmentAcademicInfoRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<EnrollmentAcademicInfoRepository>(
    () => EnrollmentAcademicInfoRepositoryImpl(
      remoteDataSource: getIt<EnrollmentAcademicInfoRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<UpdateEnrollmentAcademicInfoUseCase>(
    () => UpdateEnrollmentAcademicInfoUseCase(
      getIt<EnrollmentAcademicInfoRepository>(),
    ),
  );

  getIt.registerFactory<EnrollmentAcademicInfoBloc>(
    () => EnrollmentAcademicInfoBloc(
      updateUseCase: getIt<UpdateEnrollmentAcademicInfoUseCase>(),
    ),
  );

  // ── Finance ───────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<FinanceRemoteDataSource>(
    () => FinanceRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(
      remoteDataSource: getIt<FinanceRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerLazySingleton<StudentChargesRemoteDataSource>(
    () => StudentChargesRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<PaymentsRemoteDataSource>(
    () => PaymentsRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<StudentChargesRepository>(
    () => StudentChargesRepositoryImpl(
      remoteDataSource: getIt<StudentChargesRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerLazySingleton<PaymentsRepository>(
    () => PaymentsRepositoryImpl(
      remoteDataSource: getIt<PaymentsRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<GetFeeTariffsUseCase>(
    () => GetFeeTariffsUseCase(getIt<FinanceRepository>()),
  );

  getIt.registerFactory<GetFinanceStatsUseCase>(
    () => GetFinanceStatsUseCase(getIt<FinanceRepository>()),
  );

  getIt.registerFactory<GetStudentChargesUseCase>(
    () => GetStudentChargesUseCase(getIt<StudentChargesRepository>()),
  );

  getIt.registerFactory<GetStudentChargesByAcademicYearUseCase>(
    () => GetStudentChargesByAcademicYearUseCase(
      getIt<StudentChargesRepository>(),
    ),
  );

  getIt.registerFactory<GetPaymentAllocationsFromStudentChargesUseCase>(
    () => GetPaymentAllocationsFromStudentChargesUseCase(
      getIt<StudentChargesRepository>(),
    ),
  );

  getIt.registerFactory<GetPaymentsUseCase>(
    () => GetPaymentsUseCase(getIt<PaymentsRepository>()),
  );

  getIt.registerFactory<CreatePaymentUseCase>(
    () => CreatePaymentUseCase(getIt<PaymentsRepository>()),
  );

  getIt.registerFactory<GetPaymentAllocationsUseCase>(
    () => GetPaymentAllocationsUseCase(getIt<PaymentsRepository>()),
  );

  getIt.registerFactory<UpdateStudentChargeExpectedAmountUseCase>(
    () => UpdateStudentChargeExpectedAmountUseCase(
      getIt<StudentChargesRepository>(),
    ),
  );

  getIt.registerFactory<FinanceBloc>(
    () => FinanceBloc(getFeeTariffsUseCase: getIt<GetFeeTariffsUseCase>()),
  );

  getIt.registerFactory<FinanceStatsBloc>(
    () => FinanceStatsBloc(
      getFinanceStatsUseCase: getIt<GetFinanceStatsUseCase>(),
    ),
  );

  getIt.registerFactory<StudentChargesBloc>(
    () => StudentChargesBloc(
      getStudentChargesUseCase: getIt<GetStudentChargesUseCase>(),
      getStudentChargesByAcademicYearUseCase:
          getIt<GetStudentChargesByAcademicYearUseCase>(),
      getPaymentAllocationsFromStudentChargesUseCase:
          getIt<GetPaymentAllocationsFromStudentChargesUseCase>(),
      updateStudentChargeExpectedAmountUseCase:
          getIt<UpdateStudentChargeExpectedAmountUseCase>(),
      // FF5 (module offline) : génération des créances provisoires à l'étape
      // Frais du wizard — résolu paresseusement, enregistré par
      // registerOfflineModules avant toute création de bloc.
      initializeChargesUseCase: getIt<InitializeChargesUseCase>(),
    ),
  );

  getIt.registerFactory<PaymentsBloc>(
    () => PaymentsBloc(
      getPaymentsUseCase: getIt<GetPaymentsUseCase>(),
      createPaymentUseCase: getIt<CreatePaymentUseCase>(),
      getPaymentAllocationsUseCase: getIt<GetPaymentAllocationsUseCase>(),
    ),
  );

  // ── Documents (éditique) ──────────────────────────────────────────────────
  // Socle d'émission des pièces PDF. Aucune présentation à ce stade : les
  // consommateurs (détail Facturation, détail Inscription, module Documents)
  // viendront dans un lot suivant.
  getIt.registerLazySingleton<EditiqueRemoteDataSource>(
    () => EditiqueRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<EditiqueRepository>(
    () => EditiqueRepositoryImpl(
      remoteDataSource: getIt<EditiqueRemoteDataSource>(),
      connectivityService: getIt<ConnectivityService>(),
      requiredAuth: RequestOptionsExtra.auth(),
      // Enregistré plus bas, par le registrar offline Documents : la résolution
      // est paresseuse, donc l'ordre ne pose pas de problème. C'est ce cache
      // qui rend une pièce consultable hors ligne — et ce repository est le
      // seul à l'alimenter tant que le pull de métadonnées n'existe pas.
      cache: getIt<EditiqueDocumentCache>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  getIt.registerFactory<EmitEnrollmentAttestationUseCase>(
    () => EmitEnrollmentAttestationUseCase(getIt<EditiqueRepository>()),
  );

  getIt.registerFactory<EmitNotePerceptionUseCase>(
    () => EmitNotePerceptionUseCase(getIt<EditiqueRepository>()),
  );

  getIt.registerFactory<EmitPaymentReceiptUseCase>(
    () => EmitPaymentReceiptUseCase(getIt<EditiqueRepository>()),
  );

  getIt.registerFactory<EmitAccountStatementUseCase>(
    () => EmitAccountStatementUseCase(getIt<EditiqueRepository>()),
  );

  getIt.registerFactory<EmitFinancialClearanceUseCase>(
    () => EmitFinancialClearanceUseCase(getIt<EditiqueRepository>()),
  );

  getIt.registerFactory<RestituteDocumentUseCase>(
    () => RestituteDocumentUseCase(getIt<EditiqueRepository>()),
  );

  getIt.registerFactory<EditiqueDocumentBloc>(
    () => EditiqueDocumentBloc(
      emitEnrollmentAttestationUseCase:
          getIt<EmitEnrollmentAttestationUseCase>(),
      emitNotePerceptionUseCase: getIt<EmitNotePerceptionUseCase>(),
      emitPaymentReceiptUseCase: getIt<EmitPaymentReceiptUseCase>(),
      emitAccountStatementUseCase: getIt<EmitAccountStatementUseCase>(),
      emitFinancialClearanceUseCase: getIt<EmitFinancialClearanceUseCase>(),
      restituteDocumentUseCase: getIt<RestituteDocumentUseCase>(),
    ),
  );

  // ── Impression thermique du ticket provisoire (ADR-012 L2.4) ──────────────
  // Tout est paresseux et rien n'est touché à l'enregistrement : construire ces
  // objets ne réveille aucun adaptateur Bluetooth et ne lit aucune permission.
  // Le premier contact avec la plateforme est l'appui sur « Imprimer ».
  getIt.registerLazySingleton<ThermalPrinterChannel>(
    () => const PrintBluetoothThermalChannel(),
  );
  getIt.registerLazySingleton<ThermalPrinterPermission>(
    () => const PermissionHandlerThermalPermission(),
  );
  // L'adaptateur consulte la permission pour CONSTATER `BLUETOOTH_SCAN`, que le
  // canal natif ne sait pas voir. Sans elle, il déclarerait tout prêt et
  // l'impression échouerait en désignant la mauvaise cause.
  getIt.registerLazySingleton<ThermalPrinterPort>(
    () => ThermalPrinterAdapter(
      getIt<ThermalPrinterChannel>(),
      getIt<ThermalPrinterPermission>(),
    ),
  );
  // Mémoire d'imprimante du banc de calage, jamais de la production : le ticket
  // demande l'imprimante à chaque impression. Enregistrée sous `kDebugMode`
  // comme les routes qu'elle sert, donc absente du build release.
  if (kDebugMode) {
    getIt.registerLazySingleton<TicketBenchPrinterStore>(
      () => TicketBenchPrinterStore(getIt<FlutterSecureStorage>()),
    );
  }

  // ── Attendance ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: getIt<AttendanceRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<GetAttendanceUseCase>(
    () => GetAttendanceUseCase(getIt<AttendanceRepository>()),
  );

  getIt.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(
      // Lecture offline-first (Phase 2) : l'appel du jour vient du cache local
      // (LoadDailyAttendanceUseCase). L'écriture est dispatchée séparément vers
      // AttendanceOfflineBloc (overlay) — l'ancien chemin online
      // (UpdateAttendanceUseCase) a été retiré. GetAttendanceUseCase reste
      // enregistré mais dormant (lecture online conservée, non branchée).
      loadDailyAttendance: getIt<LoadDailyAttendanceUseCase>(),
    ),
  );

  // ── Attendance stats (tableau de bord présence école-wide) ──────────────────
  getIt.registerLazySingleton<AttendanceStatsRemoteDataSource>(
    () => AttendanceStatsRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<AttendanceStatsRepository>(
    () => AttendanceStatsRepositoryImpl(
      remoteDataSource: getIt<AttendanceStatsRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<GetAttendanceOverviewUseCase>(
    () => GetAttendanceOverviewUseCase(getIt<AttendanceStatsRepository>()),
  );

  getIt.registerFactory<AttendanceOverviewBloc>(
    () => AttendanceOverviewBloc(
      getAttendanceOverviewUseCase: getIt<GetAttendanceOverviewUseCase>(),
    ),
  );

  getIt.registerLazySingleton<DisciplinaryCaseRemoteDataSource>(
    () => DisciplinaryCaseRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<DisciplinaryCaseRepository>(
    () => DisciplinaryCaseRepositoryImpl(
      remoteDataSource: getIt<DisciplinaryCaseRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerFactory<GetDisciplinaryCaseListUseCase>(
    () => GetDisciplinaryCaseListUseCase(getIt<DisciplinaryCaseRepository>()),
  );

  getIt.registerFactory<GetDisciplinaryCaseDetailUseCase>(
    () => GetDisciplinaryCaseDetailUseCase(getIt<DisciplinaryCaseRepository>()),
  );

  getIt.registerFactory<CreateDisciplinaryCaseUseCase>(
    () => CreateDisciplinaryCaseUseCase(getIt<DisciplinaryCaseRepository>()),
  );

  getIt.registerFactory<DisciplinaryCaseBloc>(
    () => DisciplinaryCaseBloc(
      getDisciplinaryCaseListUseCase: getIt<GetDisciplinaryCaseListUseCase>(),
      getDisciplinaryCaseDetailUseCase:
          getIt<GetDisciplinaryCaseDetailUseCase>(),
      createDisciplinaryCaseUseCase: getIt<CreateDisciplinaryCaseUseCase>(),
    ),
  );

  // ── Academics (cours de l'enseignant connecté) ──────────────────────────────
  getIt.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSource(getIt<Dio>()),
  );

  // Online concret (conservé pour la délégation détail/création par l'impl
  // offline tant que NF-7b (c)/(d) ne sont pas faits).
  getIt.registerLazySingleton<CourseRepositoryImpl>(
    () => CourseRepositoryImpl(
      remoteDataSource: getIt<CourseRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  // OFFLINE-FIRST (NF-7b a) : getMyCourses lu en LOCAL ; détail/création encore
  // délégués online. Impl offline enregistrée dans registerAcademicsOffline.
  getIt.registerLazySingleton<CourseRepository>(
    () => getIt<CourseOfflineRepositoryImpl>(),
  );

  getIt.registerFactory<GetMyCoursesUseCase>(
    () => GetMyCoursesUseCase(getIt<CourseRepository>()),
  );

  getIt.registerFactory<GetCoursNotationDetailUseCase>(
    () => GetCoursNotationDetailUseCase(getIt<CourseRepository>()),
  );

  getIt.registerFactory<CreateEvaluationUseCase>(
    () => CreateEvaluationUseCase(getIt<CourseRepository>()),
  );

  getIt.registerFactory<CourseBloc>(
    () => CourseBloc(getMyCoursesUseCase: getIt<GetMyCoursesUseCase>()),
  );

  getIt.registerFactory<CoursNotationBloc>(
    () => CoursNotationBloc(
      getCoursNotationDetailUseCase: getIt<GetCoursNotationDetailUseCase>(),
    ),
  );

  getIt.registerFactory<CreateEvaluationBloc>(
    () => CreateEvaluationBloc(
      createEvaluationUseCase: getIt<CreateEvaluationUseCase>(),
    ),
  );

  // ── Academics — Notation : saisie des notes (grille + saisie par élève) ─────
  // OFFLINE-FIRST (NF-7b) : la grille se lit en LOCAL (notes locales + roster) et
  // la saisie passe par l'outbox (régime C). L'impl offline est enregistrée dans
  // `registerAcademicsOffline` ; résolue en lazy → dispo au 1er accès. L'impl
  // online `NotationRepositoryImpl` reste en code (dormante, non enregistrée).
  getIt.registerLazySingleton<NotationRepository>(
    () => getIt<NotationOfflineRepositoryImpl>(),
  );

  getIt.registerFactory<GetNotesElevesUseCase>(
    () => GetNotesElevesUseCase(getIt<NotationRepository>()),
  );

  getIt.registerFactory<SaisirNoteUseCase>(
    () => SaisirNoteUseCase(getIt<NotationRepository>()),
  );

  getIt.registerFactory<SaisieNotesBloc>(
    () => SaisieNotesBloc(
      getNotesElevesUseCase: getIt<GetNotesElevesUseCase>(),
      saisirNoteUseCase: getIt<SaisirNoteUseCase>(),
    ),
  );

  // ── Academics — Notation : consultation des notes par élève (lecture seule) ─
  // Réutilise GetNotesElevesUseCase (même endpoint que la grille de saisie) ;
  // l'en-tête Evaluation est fourni par l'écran appelant, pas rechargé ici.
  getIt.registerFactory<EvaluationNotesBloc>(
    () => EvaluationNotesBloc(
      getNotesElevesUseCase: getIt<GetNotesElevesUseCase>(),
    ),
  );

  // ── Schedule (emploi du temps — endpoints authentifiés) ─────────────────────
  getIt.registerLazySingleton<ScheduleRemoteDataSource>(
    () => ScheduleRemoteDataSource(getIt<Dio>()),
  );

  // Online concret (conservé pour la délégation grille/écritures admin par
  // l'impl offline).
  getIt.registerLazySingleton<ScheduleRepositoryImpl>(
    () => ScheduleRepositoryImpl(
      remoteDataSource: getIt<ScheduleRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  // OFFLINE-FIRST (NF-7b b) : getMyTimetable composé en LOCAL ; grille admin +
  // écritures encore online. Impl offline dans registerAcademicsOffline.
  getIt.registerLazySingleton<ScheduleRepository>(
    () => getIt<ScheduleOfflineRepositoryImpl>(),
  );

  getIt.registerFactory<GetMyTimetableUseCase>(
    () => GetMyTimetableUseCase(getIt<ScheduleRepository>()),
  );

  getIt.registerFactory<GetClassroomGridUseCase>(
    () => GetClassroomGridUseCase(getIt<ScheduleRepository>()),
  );

  getIt.registerFactory<CreateTimeSlotUseCase>(
    () => CreateTimeSlotUseCase(getIt<ScheduleRepository>()),
  );

  getIt.registerFactory<CreateSessionUseCase>(
    () => CreateSessionUseCase(getIt<ScheduleRepository>()),
  );

  getIt.registerFactory<DeleteSessionUseCase>(
    () => DeleteSessionUseCase(getIt<ScheduleRepository>()),
  );

  getIt.registerFactory<TimetableBloc>(
    () => TimetableBloc(
      getMyTimetable: getIt<GetMyTimetableUseCase>(),
      getClassroomGrid: getIt<GetClassroomGridUseCase>(),
    ),
  );

  getIt.registerFactory<ScheduleEditBloc>(
    () => ScheduleEditBloc(
      createTimeSlot: getIt<CreateTimeSlotUseCase>(),
      createSession: getIt<CreateSessionUseCase>(),
      deleteSession: getIt<DeleteSessionUseCase>(),
    ),
  );

  // ── Résultats par classe (lecture seule — endpoints authentifiés) ───────────
  getIt.registerLazySingleton<ResultatsRemoteDataSource>(
    () => ResultatsRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ResultatsRepository>(
    () => ResultatsRepositoryImpl(
      remoteDataSource: getIt<ResultatsRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerFactory<GetResultatsClasseUseCase>(
    () => GetResultatsClasseUseCase(getIt<ResultatsRepository>()),
  );

  getIt.registerFactory<GetResultatFocusUseCase>(
    () => GetResultatFocusUseCase(getIt<ResultatsRepository>()),
  );

  getIt.registerFactory<SearchRosterUseCase>(
    () => SearchRosterUseCase(getIt<ResultatsRepository>()),
  );

  getIt.registerFactory<GetPeriodesScolairesUseCase>(
    () => GetPeriodesScolairesUseCase(getIt<ResultatsRepository>()),
  );

  getIt.registerFactory<ResultatsClasseBloc>(
    () => ResultatsClasseBloc(
      getResultatsClasse: getIt<GetResultatsClasseUseCase>(),
    ),
  );

  getIt.registerFactory<ResultatFocusBloc>(
    () => ResultatFocusBloc(getResultatFocus: getIt<GetResultatFocusUseCase>()),
  );

  getIt.registerFactory<EleveSearchBloc>(
    () => EleveSearchBloc(searchRoster: getIt<SearchRosterUseCase>()),
  );

  getIt.registerFactory<PeriodesScolairesBloc>(
    () => PeriodesScolairesBloc(
      getPeriodesScolaires: getIt<GetPeriodesScolairesUseCase>(),
    ),
  );

  // ── Modules offline (branches A/B) ──────────────────────────────────────────
  // Enregistre les DataSources locales, repositories offline-first, handlers
  // d'outbox et BLoCs de chaque branche. Point d'extension additif.
  registerOfflineModules(getIt);

  // ── Contexte académique (remplace le module `bootstrap`) ────────────────────
  // Lecture 100% locale du référentiel Inscription déjà pullé
  // (`ref_academic_years`/`ref_school_level_groups`/`ref_school_levels`),
  // scopée à l'école courante. Dépend de `registerOfflineModules` ci-dessus
  // (résolution paresseuse : l'ordre textuel importe peu, mais logiquement
  // c'est un point d'extension du socle offline).
  getIt.registerLazySingleton<AcademicYearContextRepository>(
    () => AcademicYearContextRepositoryImpl(
      referentialDao: getIt<EnrollmentReferentialDao>(),
      pullRepository: getIt<EnrollmentPullRepository>(),
      connectivity: getIt<ConnectivityService>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  getIt.registerFactory<AcademicYearContextBloc>(
    () => AcademicYearContextBloc(
      repository: getIt<AcademicYearContextRepository>(),
    ),
  );

  getIt.registerFactory<AcademicYearPreviousContextBloc>(
    () => AcademicYearPreviousContextBloc(
      repository: getIt<AcademicYearContextRepository>(),
    ),
  );

  // ── Identité de l'établissement ─────────────────────────────────────────────
  // Lecture locale de `ref_school` (même DAO référentiel que le contexte
  // académique), scopée à l'école de la session. Aucun pull propre.
  getIt.registerLazySingleton<SchoolRepository>(
    () => SchoolRepositoryImpl(
      referentialDao: getIt<EnrollmentReferentialDao>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  // Exception assumée à la règle « BLoC en registerFactory » : instance unique
  // app-lifetime, comme `SyncStatusCubit`. L'identité de l'école est la même
  // pour tout l'arbre et se recharge sur les transitions de session (main.dart).
  getIt.registerLazySingleton<SchoolIdentityCubit>(
    () => SchoolIdentityCubit(repository: getIt<SchoolRepository>()),
  );
}
