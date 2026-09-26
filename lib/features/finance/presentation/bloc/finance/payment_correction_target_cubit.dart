import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_target.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payment_correction_targets_use_case.dart';

class PaymentCorrectionTargetState extends Equatable {
  final String query;
  final List<PaymentCorrectionTarget> results;

  /// L'élève retenu, `null` tant que le versement reste sur celui d'origine.
  final PaymentCorrectionTarget? target;

  /// Ses créances de l'année, `null` tant qu'elles ne sont pas lues.
  final List<StudentCharge>? targetCharges;

  /// La lecture de ses créances a échoué : on reste sur l'élève d'origine.
  final bool loadFailed;

  const PaymentCorrectionTargetState({
    this.query = '',
    this.results = const [],
    this.target,
    this.targetCharges,
    this.loadFailed = false,
  });

  @override
  List<Object?> get props => [
    query,
    results,
    target,
    targetCharges,
    loadFailed,
  ];
}

/// Changer d'élève (D1) : chercher parmi les inscrits de l'année, retenir un
/// élève, lire ses créances. Lecture 100 % locale.
class PaymentCorrectionTargetCubit extends Cubit<PaymentCorrectionTargetState> {
  final SearchPaymentCorrectionTargetsUseCase _search;
  final GetStudentChargesByAcademicYearUseCase _charges;

  PaymentCorrectionTargetCubit(this._search, this._charges)
    : super(const PaymentCorrectionTargetState());

  Future<void> search({
    required String query,
    required String academicYearId,
    required String excludeStudentId,
  }) async {
    final result = await _search(
      query: query,
      academicYearId: academicYearId,
      excludeStudentId: excludeStudentId,
    );
    if (isClosed) return;
    emit(
      PaymentCorrectionTargetState(
        query: query,
        results: result.fold((_) => const [], (found) => found),
        target: state.target,
        targetCharges: state.targetCharges,
      ),
    );
  }

  Future<void> select(
    PaymentCorrectionTarget target, {
    required String academicYearId,
  }) async {
    final result = await _charges(
      GetStudentChargesByAcademicYearParams(
        studentId: target.studentId,
        academicYearId: academicYearId,
      ),
    );
    if (isClosed) return;
    emit(
      result.fold(
        (_) => PaymentCorrectionTargetState(
          query: state.query,
          results: state.results,
          loadFailed: true,
        ),
        (charges) => PaymentCorrectionTargetState(
          target: target,
          targetCharges: charges,
        ),
      ),
    );
  }

  /// « Rétablir » : le versement revient sur l'élève d'origine.
  void reset() => emit(const PaymentCorrectionTargetState());
}
