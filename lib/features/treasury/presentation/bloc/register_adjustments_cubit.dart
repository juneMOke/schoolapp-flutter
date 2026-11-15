import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';

enum RegisterAdjustmentsStatus { loading, ready, failure }

class RegisterAdjustmentsState extends Equatable {
  final RegisterAdjustmentsStatus status;
  final List<CashAdjustment> items;
  final Failure? failure;

  const RegisterAdjustmentsState({
    this.status = RegisterAdjustmentsStatus.loading,
    this.items = const [],
    this.failure,
  });

  @override
  List<Object?> get props => [status, items, failure];
}

/// L'historique des ajustements d'une caisse, chargé quand on le déplie. Sa vie
/// est celle du dépliage : refermé, il n'occupe plus rien.
class RegisterAdjustmentsCubit extends Cubit<RegisterAdjustmentsState> {
  final CashRegistersRepository _repository;
  final String registerId;

  RegisterAdjustmentsCubit(this._repository, {required this.registerId})
    : super(const RegisterAdjustmentsState());

  Future<void> load() async {
    emit(const RegisterAdjustmentsState());
    final result = await _repository.adjustments(registerId);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => RegisterAdjustmentsState(
          status: RegisterAdjustmentsStatus.failure,
          failure: failure,
        ),
        (items) => RegisterAdjustmentsState(
          status: RegisterAdjustmentsStatus.ready,
          items: items,
        ),
      ),
    );
  }
}
