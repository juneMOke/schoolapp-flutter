import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

/// Mappe une [Failure] vers le type d'erreur d'affichage [AttendanceErrorType].
///
/// Factorise ici pour etre partage par les BLoCs du module qui utilisent ce
/// type ([AttendanceBloc], [StudentAttendanceSummaryBloc]) et garantir une
/// convention unique — evitant que le bug du 403 ne se reintroduise.
///
/// Convention (cf. interceptor Dio) : HTTP 401 -> [InvalidCredentialsFailure]
/// -> 401 (session expiree) ; HTTP 403 -> [UnauthorizedFailure] -> 403
/// (acces refuse).
AttendanceErrorType mapFailureToAttendanceErrorType(Failure failure) =>
    switch (failure) {
      NetworkFailure() => AttendanceErrorType.network,
      NotFoundFailure() => AttendanceErrorType.notFound,
      ValidationFailure() => AttendanceErrorType.validation,
      UnauthorizedFailure() => AttendanceErrorType.forbidden,
      InvalidCredentialsFailure() => AttendanceErrorType.invalidCredentials,
      ServerFailure() => AttendanceErrorType.server,
      StorageFailure() => AttendanceErrorType.storage,
      AuthFailure() => AttendanceErrorType.auth,
      _ => AttendanceErrorType.unknown,
    };
