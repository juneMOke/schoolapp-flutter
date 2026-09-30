import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_contract_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_state.dart';

/// Les contrats d'un agent : les relire, en poser, en corriger.
///
/// Chaque geste écrit sur la tablette et part en file ; la frise de la fiche,
/// elle, est relue par son propre cubit.
class StaffContractsCubit extends Cubit<StaffContractsState> {
  final LoadStaffContractsUseCase _load;
  final AddStaffContractUseCase _add;
  final CorrectStaffContractUseCase _correct;

  StaffContractsCubit({
    required LoadStaffContractsUseCase load,
    required AddStaffContractUseCase add,
    required CorrectStaffContractUseCase correct,
  }) : _load = load,
       _add = add,
       _correct = correct,
       super(const StaffContractsState());

  /// Relit les périodes de [staffMemberId]. Un échec de lecture laisse les
  /// montants cachés : la frise, portée par la fiche, reste lisible.
  Future<void> load(String staffMemberId) async {
    final result = await _load(staffMemberId);
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(contracts: const [])),
      (contracts) => emit(state.copyWith(contracts: contracts)),
    );
  }

  /// Pose une période ; rend `true` si elle est écrite.
  Future<bool> add(String staffMemberId, StaffContractDraft draft) =>
      _write(staffMemberId, () => _add(staffMemberId, draft));

  /// Corrige [original] — avec [replacement], ou sans (doublon).
  Future<bool> correct(
    StaffContract original, {
    required String reason,
    StaffContractDraft? replacement,
  }) => _write(
    original.staffMemberId,
    () => _correct(original, reason: reason, replacement: replacement),
  );

  Future<bool> _write(
    String staffMemberId,
    Future<Either<Failure, Unit>> Function() write,
  ) async {
    if (state.writing) return false;
    emit(state.copyWith(writing: true));
    final result = await write();
    if (isClosed) return false;
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          writing: false,
          outcome: StaffContractOutcome.failed,
          failure: failure,
        ),
      );
      return false;
    }
    await load(staffMemberId);
    if (isClosed) return false;
    emit(state.copyWith(writing: false, outcome: StaffContractOutcome.saved));
    return true;
  }
}
