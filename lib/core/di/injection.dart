import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
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
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/repositories/enrollment_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
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

  getIt.registerLazySingleton<EnrollmentRemoteDataSource>(
    () => EnrollmentRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<EnrollmentRepository>(
    () => EnrollmentRepositoryImpl(
      remoteDataSource: getIt<EnrollmentRemoteDataSource>(),
    ),
  );

  getIt.registerFactory<GetEnrollmentSummaryListByStatusUseCase>(
    () => GetEnrollmentSummaryListByStatusUseCase(getIt<EnrollmentRepository>()),
  );

  getIt.registerFactory<GetEnrollmentDetailUseCase>(
    () => GetEnrollmentDetailUseCase(getIt<EnrollmentRepository>()),
  );

  getIt.registerFactory<
    SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
  >(
    () =>
        SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase(
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
    ),
  );
}
