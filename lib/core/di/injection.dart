import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/di/request_options_extra.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/data/datasources/enrollment_academic_info_remote_data_source.dart';
import 'package:school_app_flutter/features/academic_year/data/repositories/enrollment_academic_info_repository_impl.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/enrollment_academic_info_repository.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/update_enrollment_academic_info_use_case.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/enrollment_academic_info_bloc.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/datasources/forgot_password_remote_data_source.dart';
import 'package:school_app_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/repositories/forgot_password_repository_impl.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
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
import 'package:school_app_flutter/features/bootstrap/data/datasources/bootstrap_local_data_source.dart';
import 'package:school_app_flutter/features/bootstrap/data/datasources/bootstrap_remote_data_source.dart';
import 'package:school_app_flutter/features/bootstrap/data/repositories/bootstrap_local_repository_impl.dart';
import 'package:school_app_flutter/features/bootstrap/data/repositories/bootstrap_remote_repository_impl.dart';
import 'package:school_app_flutter/features/bootstrap/data/services/bootstrap_local_migration_service.dart';
import 'package:school_app_flutter/features/bootstrap/data/services/bootstrap_storage_service.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_remote_repository.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/clear_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/save_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_academic_info_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/student/data/datasources/parent_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/datasources/student_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/repositories/parent_repository_impl.dart';
import 'package:school_app_flutter/features/student/data/repositories/student_repository_impl.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_repository.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_parent_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_academic_info_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_address_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_personal_info_use_case.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/parent_bloc.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  await Hive.initFlutter();
  final bootstrapBox = await Hive.openBox<String>('bootstrap_box');

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<Box<String>>(
    () => bootstrapBox,
    instanceName: 'bootstrapBox',
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] ?? false;
          if (requiresAuth) {
            final tokenStorage = getIt<TokenStorageService>();
            final session = await tokenStorage.readAuthSession();
            if (session != null && session.accessToken.isNotEmpty) {
              options.headers['Authorization'] =
                  'Bearer ${session.accessToken}';
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

    return dio;
  });

  getIt.registerLazySingleton<Map<String, dynamic>>(
    () => RequestOptionsExtra.auth(),
  );

  getIt.registerLazySingleton<TokenStorageService>(
    () => TokenStorageService(getIt<FlutterSecureStorage>()),
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
    ),
  );

  getIt.registerFactory<ForgotPasswordBloc>(
    () => ForgotPasswordBloc(
      generateOtpUseCase: getIt<GenerateOtpUseCase>(),
      validateOtpUseCase: getIt<ValidateOtpUseCase>(),
    ),
  );

  getIt.registerLazySingleton<BootstrapStorageService>(
    () => BootstrapStorageService(
      getIt<Box<String>>(instanceName: 'bootstrapBox'),
    ),
  );

  getIt.registerLazySingleton<BootstrapLocalMigrationService>(
    () => BootstrapLocalMigrationService(
      legacyStorage: getIt<FlutterSecureStorage>(),
      bootstrapBox: getIt<Box<String>>(instanceName: 'bootstrapBox'),
    ),
  );

  await getIt<BootstrapLocalMigrationService>().migrateIfNeeded();

  getIt.registerLazySingleton<BootstrapRemoteDataSource>(
    () => BootstrapRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<BootstrapLocalDataSource>(
    () => BootstrapLocalDataSourceImpl(getIt<BootstrapStorageService>()),
  );

  getIt.registerLazySingleton<BootstrapRemoteRepository>(
    () => BootstrapRemoteRepositoryImpl(
      remoteDataSource: getIt<BootstrapRemoteDataSource>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerLazySingleton<BootstrapLocalRepository>(
    () => BootstrapLocalRepositoryImpl(
      localDataSource: getIt<BootstrapLocalDataSource>(),
    ),
  );

  getIt.registerFactory<GetRemoteBootstrapUseCase>(
    () => GetRemoteBootstrapUseCase(getIt<BootstrapRemoteRepository>()),
  );

  getIt.registerFactory<GetLocalBootstrapUseCase>(
    () => GetLocalBootstrapUseCase(getIt<BootstrapLocalRepository>()),
  );

  getIt.registerFactory<SaveLocalBootstrapUseCase>(
    () => SaveLocalBootstrapUseCase(getIt<BootstrapLocalRepository>()),
  );

  getIt.registerFactory<ClearLocalBootstrapUseCase>(
    () => ClearLocalBootstrapUseCase(getIt<BootstrapLocalRepository>()),
  );

  getIt.registerFactory<BootstrapBloc>(
    () => BootstrapBloc(
      getRemoteBootstrapUseCase: getIt<GetRemoteBootstrapUseCase>(),
      getLocalBootstrapUseCase: getIt<GetLocalBootstrapUseCase>(),
      saveLocalBootstrapUseCase: getIt<SaveLocalBootstrapUseCase>(),
      clearLocalBootstrapUseCase: getIt<ClearLocalBootstrapUseCase>(),
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

  getIt.registerFactory<GetEnrollmentSummaryListByStatusUseCase>(
    () =>
        GetEnrollmentSummaryListByStatusUseCase(getIt<EnrollmentRepository>()),
  );

  getIt.registerFactory<GetEnrollmentDetailUseCase>(
    () => GetEnrollmentDetailUseCase(getIt<EnrollmentRepository>()),
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

  getIt.registerFactory<EnrollmentBloc>(
    () => EnrollmentBloc(
      getEnrollmentSummariesUseCase:
          getIt<GetEnrollmentSummaryListByStatusUseCase>(),
      getEnrollmentDetailUseCase: getIt<GetEnrollmentDetailUseCase>(),
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

  getIt.registerFactory<ParentBloc>(
    () => ParentBloc(updateParentUseCase: getIt<UpdateParentUseCase>()),
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
}
