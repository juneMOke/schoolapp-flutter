import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_natures_for_year_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

class RecoveryCatalogState extends Equatable {
  final RecoveryLoadStatus status;

  /// Les natures facturées de l'année et leurs devises, dans l'ordre de
  /// l'école — le choix des frais (A, O1).
  final List<FeeNature> natures;

  /// Les classes de l'année — le choix du périmètre.
  final List<OfflineClassroom> classrooms;
  final Failure? failure;

  const RecoveryCatalogState({
    this.status = RecoveryLoadStatus.initial,
    this.natures = const [],
    this.classrooms = const [],
    this.failure,
  });

  @override
  List<Object?> get props => [status, natures, classrooms, failure];
}

/// Ce que la carte de périmètre propose (A) — lu **sur l'appareil**, pour que
/// la page sache quoi demander au serveur, même avant sa première réponse.
class RecoveryCatalogCubit extends Cubit<RecoveryCatalogState> {
  final GetFeeNaturesForYearUseCase _getNatures;
  final GetOfflineClassroomsUseCase _getClassrooms;

  RecoveryCatalogCubit({
    required GetFeeNaturesForYearUseCase getNatures,
    required GetOfflineClassroomsUseCase getClassrooms,
  }) : _getNatures = getNatures,
       _getClassrooms = getClassrooms,
       super(const RecoveryCatalogState());

  Future<void> load(String academicYearId) async {
    emit(const RecoveryCatalogState(status: RecoveryLoadStatus.loading));
    final natures = await _getNatures(academicYearId: academicYearId);
    final classrooms = await _getClassrooms(academicYearId: academicYearId);
    if (isClosed) return;
    natures.fold(
      (failure) => emit(
        RecoveryCatalogState(
          status: RecoveryLoadStatus.failure,
          failure: failure,
        ),
      ),
      (list) => emit(
        RecoveryCatalogState(
          status: RecoveryLoadStatus.success,
          natures: [
            for (final n in list)
              FeeNature(feeCode: n.feeCode, currencies: n.currencies),
          ],
          // Sans classes locales, le périmètre se réduit à l'établissement et
          // aux cycles : ce n'est pas une panne.
          classrooms: classrooms.fold((_) => const [], (c) => c),
        ),
      ),
    );
  }
}
