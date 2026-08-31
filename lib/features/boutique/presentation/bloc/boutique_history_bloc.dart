import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_history_use_case.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

part 'boutique_history_event.dart';
part 'boutique_history_state.dart';

/// L'historique de caisse : une fenêtre, les ventes qu'elle contient, leur
/// total.
class BoutiqueHistoryBloc
    extends Bloc<BoutiqueHistoryEvent, BoutiqueHistoryState> {
  final GetBoutiqueSalesHistoryUseCase _getHistory;

  BoutiqueHistoryBloc({required GetBoutiqueSalesHistoryUseCase getHistory})
    : _getHistory = getHistory,
      super(const BoutiqueHistoryState()) {
    on<BoutiqueHistoryRequested>(_onRequested);
    on<BoutiqueHistoryPeriodChanged>(_onPeriodChanged);
  }

  Future<void> _onRequested(
    BoutiqueHistoryRequested event,
    Emitter<BoutiqueHistoryState> emit,
  ) => _load(emit, academicYearId: event.academicYearId, period: state.period);

  Future<void> _onPeriodChanged(
    BoutiqueHistoryPeriodChanged event,
    Emitter<BoutiqueHistoryState> emit,
  ) {
    // La fenêtre est posée AVANT la lecture : le sélecteur doit suivre le doigt
    // sans attendre la base, sans quoi un tapotement rapide laisserait l'écran
    // marquer une fenêtre et en afficher une autre.
    emit(state.copyWith(period: event.period));
    return _load(
      emit,
      academicYearId: event.academicYearId,
      period: event.period,
    );
  }

  Future<void> _load(
    Emitter<BoutiqueHistoryState> emit, {
    required String academicYearId,
    required SalesHistoryPeriod period,
  }) async {
    emit(state.copyWith(status: HistoryStatus.loading, clearFailure: true));
    final result = await _getHistory(
      academicYearId: academicYearId,
      period: period,
    );
    result.fold(
      (failure) =>
          emit(state.copyWith(status: HistoryStatus.failure, failure: failure)),
      (sales) => emit(
        state.copyWith(
          status: HistoryStatus.ready,
          sales: sales,
          clearFailure: true,
        ),
      ),
    );
  }
}
