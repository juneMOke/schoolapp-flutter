import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/confirm_enrollment_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';

/// BLoC offline-first du module Inscription : lectures locales instantanées +
/// confirmation local-first exposant l'état pending-sync.
class EnrollmentOfflineBloc
    extends Bloc<EnrollmentOfflineEvent, EnrollmentOfflineState> {
  final GetLocalEnrollmentsUseCase _getEnrollments;
  final SearchLocalEnrollmentsUseCase _search;
  final GetLocalEnrollmentDetailUseCase _getDetail;
  final ConfirmEnrollmentUseCase _confirm;

  EnrollmentOfflineBloc({
    required GetLocalEnrollmentsUseCase getEnrollments,
    required SearchLocalEnrollmentsUseCase search,
    required GetLocalEnrollmentDetailUseCase getDetail,
    required ConfirmEnrollmentUseCase confirm,
  }) : _getEnrollments = getEnrollments,
       _search = search,
       _getDetail = getDetail,
       _confirm = confirm,
       super(const EnrollmentOfflineInitial()) {
    on<LoadLocalEnrollments>(_onLoad);
    on<SearchLocalEnrollmentsByName>(_onSearch);
    on<LoadLocalEnrollmentDetail>(_onDetail);
    on<ConfirmLocalEnrollment>(_onConfirm);
  }

  Future<void> _onLoad(
    LoadLocalEnrollments event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentOfflineLoading());
    final result = await _getEnrollments(status: event.status);
    emit(
      result.fold(
        (f) => EnrollmentOfflineError(_map(f)),
        (items) => EnrollmentOfflineListLoaded(items),
      ),
    );
  }

  Future<void> _onSearch(
    SearchLocalEnrollmentsByName event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentOfflineLoading());
    final result = await _search.byName(event.query);
    emit(
      result.fold(
        (f) => EnrollmentOfflineError(_map(f)),
        (items) => EnrollmentOfflineListLoaded(items),
      ),
    );
  }

  Future<void> _onDetail(
    LoadLocalEnrollmentDetail event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentOfflineLoading());
    final result = await _getDetail(event.enrollmentId);
    emit(
      result.fold(
        (f) => EnrollmentOfflineError(_map(f)),
        (detail) => EnrollmentOfflineDetailLoaded(detail),
      ),
    );
  }

  Future<void> _onConfirm(
    ConfirmLocalEnrollment event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentOfflineConfirming());
    final result = await _confirm(event.draft);
    emit(
      result.fold(
        (f) => EnrollmentOfflineError(_map(f)),
        (id) => EnrollmentOfflineConfirmedPendingSync(id),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    NotFoundFailure() => 'Dossier introuvable en local.',
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
