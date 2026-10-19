import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/student/data/local/student_identity_dao.dart';
import 'package:school_app_flutter/features/student/data/repositories/student_identity_repository_impl.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_identity_repository.dart';
import 'package:school_app_flutter/features/student/domain/usecases/find_student_identity_use_case.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_identity_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// L'identité d'un élève relue en base locale, pour les fiches rouvertes par
/// leur adresse (Facturation, dossier disciplinaire).
void registerStudentIdentity(GetIt getIt) {
  getIt.registerLazySingleton<StudentIdentityDao>(
    () => StudentIdentityDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StudentIdentityRepository>(
    () => StudentIdentityRepositoryImpl(getIt<StudentIdentityDao>()),
  );
  getIt.registerFactory<FindStudentIdentityUseCase>(
    () => FindStudentIdentityUseCase(getIt<StudentIdentityRepository>()),
  );
  getIt.registerFactory<StudentIdentityCubit>(
    () => StudentIdentityCubit(getIt<FindStudentIdentityUseCase>()),
  );
}
