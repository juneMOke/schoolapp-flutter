import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';

class RecoveryStudentsState extends Equatable {
  final RecoveryStudentsQuery? query;
  final RecoveryLoadStatus status;

  /// La dernière page reçue, gardée pendant la lecture de la suivante.
  final RecoveryStudentsPage? page;
  final Failure? failure;

  const RecoveryStudentsState({
    this.query,
    this.status = RecoveryLoadStatus.initial,
    this.page,
    this.failure,
  });

  @override
  List<Object?> get props => [query, status, page, failure];
}

/// Une page de la liste nominative — celle du bloc E, celle d'une fiche de
/// classe (O2) ou les élèves visés d'une classe de la simulation (O5) : une
/// instance par usage.
///
/// ⚠️ Deux droits (`finance.stats.read` **et** `finance.charge.read`) : un 403
/// ici n'éteint pas les chiffres, il ne dit que ce qui manque à la liste.
class RecoveryStudentsCubit extends Cubit<RecoveryStudentsState> {
  final RecoveryDashboardRepository _repository;
  final CountPendingPaymentsUseCase _countPending;
  var _generation = 0;

  RecoveryStudentsCubit({
    required RecoveryDashboardRepository repository,
    required CountPendingPaymentsUseCase countPending,
  }) : _repository = repository,
       _countPending = countPending,
       super(const RecoveryStudentsState());

  Future<void> load(String academicYearId, RecoveryStudentsQuery query) async {
    final generation = ++_generation;
    // L'ancienne page ne reste que pour une autre page de la MÊME liste :
    // sous un autre onglet ou une autre question, son titre, son compte et
    // ses exports mentiraient (R14).
    final kept = state.query?.copyWith(page: 0) == query.copyWith(page: 0)
        ? state.page
        : null;
    emit(
      RecoveryStudentsState(
        query: query,
        status: RecoveryLoadStatus.loading,
        page: kept,
      ),
    );
    final pending = (await _countPending()).fold((_) => 0, (n) => n);
    final result = await _repository.students(
      academicYearId,
      query,
      pendingWrites: pending,
    );
    if (isClosed || generation != _generation) return;
    emit(
      result.fold(
        (failure) => RecoveryStudentsState(
          query: query,
          status: RecoveryLoadStatus.failure,
          page: kept,
          failure: failure,
        ),
        (page) => RecoveryStudentsState(
          query: query,
          status: RecoveryLoadStatus.success,
          page: page,
        ),
      ),
    );
  }

  /// Le compte des encaissements en attente, pour les exports.
  Future<int> pendingWrites() async =>
      (await _countPending()).fold((_) => 0, (n) => n);
}
