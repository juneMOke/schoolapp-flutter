import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_payments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_student_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/record_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';

/// BLoC offline-first du module Facturation : grand-livre local + encaissement
/// money-grade exposant l'état pending-sync.
class FinanceOfflineBloc
    extends Bloc<FinanceOfflineEvent, FinanceOfflineState> {
  final GetLocalStudentChargesUseCase _getCharges;
  final GetLocalPaymentsUseCase _getPayments;
  final RecordPaymentUseCase _recordPayment;

  FinanceOfflineBloc({
    required GetLocalStudentChargesUseCase getCharges,
    required GetLocalPaymentsUseCase getPayments,
    required RecordPaymentUseCase recordPayment,
  }) : _getCharges = getCharges,
       _getPayments = getPayments,
       _recordPayment = recordPayment,
       super(const FinanceOfflineInitial()) {
    on<LoadLocalCharges>(_onCharges);
    on<LoadLocalPayments>(_onPayments);
    on<RecordLocalPayment>(_onRecord);
  }

  Future<void> _onCharges(
    LoadLocalCharges event,
    Emitter<FinanceOfflineState> emit,
  ) async {
    emit(const FinanceOfflineLoading());
    final result = await _getCharges(event.studentId);
    emit(
      result.fold(
        (f) => FinanceOfflineError(_map(f)),
        (charges) => FinanceOfflineChargesLoaded(charges),
      ),
    );
  }

  Future<void> _onPayments(
    LoadLocalPayments event,
    Emitter<FinanceOfflineState> emit,
  ) async {
    emit(const FinanceOfflineLoading());
    final result = await _getPayments(event.studentId);
    emit(
      result.fold(
        (f) => FinanceOfflineError(_map(f)),
        (payments) => FinanceOfflinePaymentsLoaded(payments),
      ),
    );
  }

  Future<void> _onRecord(
    RecordLocalPayment event,
    Emitter<FinanceOfflineState> emit,
  ) async {
    emit(const FinanceOfflineRecording());
    final result = await _recordPayment(event.draft);
    emit(
      result.fold(
        (f) => FinanceOfflineError(_map(f)),
        (id) => FinanceOfflinePaymentPendingSync(id),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
