import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_report.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_use_case.dart';

part 'boutique_sales_report_state.dart';

/// Le téléchargement du rapport des ventes — **un à la fois**, comme le
/// registre des inscriptions et le rapport de caisse : préparation qui dure,
/// attente imposée par un 429, document remis puis oublié (la pièce n'est pas
/// archivée, la redemander en produit une autre).
class BoutiqueSalesReportCubit extends Cubit<BoutiqueSalesReportState> {
  final GetBoutiqueSalesReportUseCase _getReport;

  Timer? _cooldownTimer;

  BoutiqueSalesReportCubit({required GetBoutiqueSalesReportUseCase getReport})
    : _getReport = getReport,
      super(const BoutiqueSalesReportState());

  /// Demande le rapport de [query] — la question qui a produit la liste
  /// affichée, filtre compris, toutes pages.
  Future<void> download(SalesQuery query) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        status: BoutiqueSalesReportStatus.preparing,
        report: null,
        failure: null,
        retryAfter: null,
      ),
    );

    final result = await _getReport(query);
    // Le rendu prend plusieurs secondes : l'écran a pu être quitté.
    if (isClosed) return;

    result.fold(
      (failure) {
        // ⚠️ Le 429 n'est pas un échec, c'est un tour de file : le bouton
        // reste désarmé le temps annoncé.
        if (failure is TooManyRequestsFailure) {
          final wait =
              failure.retryAfter ??
              AppConstants.boutiqueSalesReportRetryFallback;
          emit(
            state.copyWith(
              status: BoutiqueSalesReportStatus.cooldown,
              failure: failure,
              retryAfter: wait,
              report: null,
            ),
          );
          _startCooldown(wait);
          return;
        }
        emit(
          state.copyWith(
            status: BoutiqueSalesReportStatus.idle,
            failure: failure,
            report: null,
            retryAfter: null,
          ),
        );
      },
      (report) => emit(
        state.copyWith(
          status: BoutiqueSalesReportStatus.idle,
          report: report,
          failure: null,
          retryAfter: null,
        ),
      ),
    );
  }

  /// La vue a remis le document (ou dit l'échec) : l'état se vide.
  void acknowledge() {
    if (!state.hasDelivery) return;
    emit(state.clearDelivery());
  }

  void _startCooldown(Duration wait) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(wait, () {
      if (isClosed) return;
      emit(state.copyWith(status: BoutiqueSalesReportStatus.idle));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
