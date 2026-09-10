import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_report.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_till_receipts_report_usecase.dart';

part 'finance_till_report_state.dart';

/// Le téléchargement du rapport d'encaissements — **un à la fois**.
///
/// ## Pourquoi ce n'est pas une simple méthode dans le widget
///
/// Trois états survivent à l'appui et doivent être portés quelque part :
///
/// 1. **La préparation**, qui dure — plusieurs secondes sur une grosse fenêtre.
///    Le bouton se désarme pendant ce temps, sans quoi deux appuis lancent deux
///    rendus et le second part en 429.
/// 2. **L'attente imposée par le serveur.** Il ne produit qu'un rapport à la
///    fois : un 429 n'est pas une panne mais un « pas maintenant », avec un
///    délai. Réarmer le bouton tout de suite inviterait à reproduire
///    exactement ce que le serveur vient de refuser.
/// 3. **Le document lui-même**, qui doit traverser jusqu'au geste de
///    plateforme.
///
/// ## Le document est REMIS, puis oublié
///
/// [TillReport] ne reste dans l'état que le temps que la vue le passe au
/// spouleur, après quoi [acknowledge] le retire. Ce n'est pas de la prudence
/// de mémoire : le serveur **n'archive pas** cette pièce, et redemander le même
/// rapport en produit un autre, sous un autre numéro. Un document qui
/// séjournerait dans l'état se ferait fatalement re-présenter un jour comme
/// « le » rapport, alors qu'il n'en est qu'un tirage.
class FinanceTillReportCubit extends Cubit<FinanceTillReportState> {
  final GetTillReceiptsReportUseCase _getTillReceiptsReportUseCase;

  Timer? _cooldownTimer;

  FinanceTillReportCubit({
    required GetTillReceiptsReportUseCase getTillReceiptsReportUseCase,
  }) : _getTillReceiptsReportUseCase = getTillReceiptsReportUseCase,
       super(const FinanceTillReportState());

  /// Demande le rapport de la fenêtre affichée — **toutes caisses**.
  ///
  /// Ne fait rien si un rendu est déjà en cours ou si l'attente d'un 429 court
  /// encore : c'est la garde qui rend le « un à la fois » vrai même quand
  /// l'interface laisse passer un second appui.
  Future<void> download({required TillWindow window}) async {
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: FinanceTillReportStatus.preparing,
        report: null,
        failure: null,
        retryAfter: null,
      ),
    );

    final result = await _getTillReceiptsReportUseCase(window: window);

    result.fold(
      (failure) {
        // ⚠️ **Le 429 n'est pas un échec, c'est un tour de file.** Il porte son
        // propre état : le bouton reste désarmé le temps annoncé, et le message
        // dit d'attendre plutôt que de réessayer.
        if (failure is TooManyRequestsFailure) {
          final wait =
              failure.retryAfter ?? AppConstants.financeTillReportRetryFallback;
          emit(
            state.copyWith(
              status: FinanceTillReportStatus.cooldown,
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
            status: FinanceTillReportStatus.idle,
            failure: failure,
            report: null,
            retryAfter: null,
          ),
        );
      },
      (report) => emit(
        state.copyWith(
          status: FinanceTillReportStatus.idle,
          report: report,
          failure: null,
          retryAfter: null,
        ),
      ),
    );
  }

  /// La vue a remis le document (ou dit l'échec) : l'état se vide.
  ///
  /// Sans ça, le même document serait re-remis à chaque reconstruction de la
  /// vue, et le même message rejoué à chaque retour sur l'onglet.
  void acknowledge() {
    if (state.report == null && state.failure == null) return;
    emit(state.clearDelivery());
  }

  void _startCooldown(Duration wait) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(wait, () {
      if (isClosed) return;
      emit(state.copyWith(status: FinanceTillReportStatus.idle));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
