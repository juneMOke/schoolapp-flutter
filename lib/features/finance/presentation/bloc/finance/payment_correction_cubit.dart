import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/correct_payment_use_case.dart';

enum PaymentCorrectionPhase { idle, submitting, succeeded, failed }

class PaymentCorrectionState extends Equatable {
  final PaymentCorrectionPhase phase;
  final PaymentCorrectionOutcome? outcome;

  /// Le refus LOCAL (motif incomplet, versement déjà annulé…). Le geste ne
  /// dépend pas du réseau : un échec ici n'est jamais une panne de synchro.
  final Failure? failure;

  const PaymentCorrectionState({
    this.phase = PaymentCorrectionPhase.idle,
    this.outcome,
    this.failure,
  });

  bool get isSubmitting => phase == PaymentCorrectionPhase.submitting;

  @override
  List<Object?> get props => [phase, outcome, failure];
}

/// Le geste « Annuler » / « Corriger » : une écriture locale, jamais une
/// attente réseau. Le résultat est toujours un succès local ou un refus de
/// saisie ; la synchronisation se lit ensuite sur la ligne du versement.
class PaymentCorrectionCubit extends Cubit<PaymentCorrectionState> {
  final CorrectPaymentUseCase _correct;

  PaymentCorrectionCubit(this._correct) : super(const PaymentCorrectionState());

  Future<void> submit(PaymentCorrectionDraft draft) async {
    if (state.isSubmitting) return;
    emit(
      const PaymentCorrectionState(phase: PaymentCorrectionPhase.submitting),
    );
    final result = await _correct(draft);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => PaymentCorrectionState(
          phase: PaymentCorrectionPhase.failed,
          failure: failure,
        ),
        (outcome) => PaymentCorrectionState(
          phase: PaymentCorrectionPhase.succeeded,
          outcome: outcome,
        ),
      ),
    );
  }
}
