import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_projector.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_natures_for_year_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

class RecoveryStudentSheetState extends Equatable {
  final RecoveryLoadStatus status;
  final FeeControlRow? row;
  final Failure? failure;

  const RecoveryStudentSheetState({
    this.status = RecoveryLoadStatus.initial,
    this.row,
    this.failure,
  });

  @override
  List<Object?> get props => [status, row, failure];
}

/// La fiche d'un élève ouverte depuis le tableau de bord (O4) : **tous** ses
/// frais de l'année, lus sur l'appareil — la même ligne que le contrôle des
/// frais montre pour lui, donc les mêmes chiffres.
class RecoveryStudentSheetCubit extends Cubit<RecoveryStudentSheetState> {
  final SearchLocalEnrollmentsUseCase _search;
  final GetFeeNaturesForYearUseCase _getNatures;
  final GetRecoveryPositionsUseCase _getPositions;

  RecoveryStudentSheetCubit({
    required SearchLocalEnrollmentsUseCase search,
    required GetFeeNaturesForYearUseCase getNatures,
    required GetRecoveryPositionsUseCase getPositions,
  }) : _search = search,
       _getNatures = getNatures,
       _getPositions = getPositions,
       super(const RecoveryStudentSheetState());

  Future<void> load(String academicYearId, String studentId) async {
    emit(const RecoveryStudentSheetState(status: RecoveryLoadStatus.loading));
    final natures = await _getNatures(academicYearId: academicYearId);
    final feeCodes = natures.fold(
      (_) => const <String>[],
      (list) => [for (final n in list) n.feeCode],
    );
    final enrolled = await _search.currentYearEnrolled(
      academicYearId: academicYearId,
    );
    final positions = await _getPositions(
      academicYearId: academicYearId,
      feeCodes: feeCodes,
    );
    if (isClosed) return;
    final failure = [
      natures.fold((f) => f, (_) => null),
      enrolled.fold((f) => f, (_) => null),
      positions.fold((f) => f, (_) => null),
    ].whereType<Failure>().firstOrNull;
    if (failure != null) {
      emit(
        RecoveryStudentSheetState(
          status: RecoveryLoadStatus.failure,
          failure: failure,
        ),
      );
      return;
    }
    final items = enrolled.fold(
      (_) => const [],
      (list) => [
        for (final i in list)
          if (i.studentId == studentId) i,
      ],
    );
    final join = FeeControlProjector.join(
      summaries: EnrollmentLocalListProjector.project([...items]),
      lines: positions.fold((_) => const [], (l) => l),
      filter: FeeControlPaymentFilter.all,
    );
    final row = join.charged.firstOrNull;
    emit(
      RecoveryStudentSheetState(
        status: row == null
            ? RecoveryLoadStatus.failure
            : RecoveryLoadStatus.success,
        row: row,
        failure: row == null
            ? const NotFoundFailure('Élève absent de cet appareil.')
            : null,
      ),
    );
  }
}
