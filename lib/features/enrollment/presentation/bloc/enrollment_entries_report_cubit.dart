import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_report_use_case.dart';

part 'enrollment_entries_report_state.dart';

/// Le téléchargement du registre des inscrits — **un à la fois**.
///
/// Même patron que le rapport de la caisse, et pour les mêmes raisons : trois
/// états survivent à l'appui et doivent être portés quelque part.
///
/// 1. **La préparation**, qui dure — plusieurs secondes sur une année
///    entière. Le bouton se désarme pendant ce temps, sans quoi deux appuis
///    lancent deux rendus et le second part en 429.
/// 2. **L'attente imposée par le serveur.** Il ne compose qu'un document long
///    à la fois, et la file est partagée avec la caisse et la relance : un 429
///    n'est pas une panne mais un « pas maintenant », avec un délai.
/// 3. **Le document lui-même**, qui doit traverser jusqu'au spouleur.
///
/// ## Le document est REMIS, puis oublié
///
/// [EnrollmentEntriesReport] ne reste dans l'état que le temps que la vue le
/// passe au spouleur, après quoi [acknowledge] le retire. Le serveur
/// **n'archive pas** cette pièce : redemander le même registre en produit un
/// autre, sous un autre numéro. Un document qui séjournerait dans l'état se
/// ferait fatalement re-présenter un jour comme « le » registre, alors qu'il
/// n'en est qu'un tirage.
class EnrollmentEntriesReportCubit extends Cubit<EnrollmentEntriesReportState> {
  final GetEnrollmentEntriesReportUseCase _getReportUseCase;

  Timer? _cooldownTimer;

  EnrollmentEntriesReportCubit({
    required GetEnrollmentEntriesReportUseCase getReportUseCase,
  }) : _getReportUseCase = getReportUseCase,
       super(const EnrollmentEntriesReportState());

  /// Demande le registre de [window] — celle qui a produit la table.
  ///
  /// Ne fait rien si un rendu est en cours ou si l'attente d'un 429 court
  /// encore : c'est la garde qui rend le « un à la fois » vrai même quand
  /// l'interface laisse passer un second appui.
  Future<void> download({required EnrollmentStatsWindow window}) async {
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: EnrollmentEntriesReportStatus.preparing,
        report: null,
        failure: null,
        retryAfter: null,
      ),
    );

    final result = await _getReportUseCase(window: window);

    // Un rendu d'une année prend plusieurs secondes : l'utilisateur a pu
    // quitter le tableau de bord entre-temps, et le scope a fermé le cubit.
    if (isClosed) return;

    result.fold(
      (failure) {
        // ⚠️ **Le 429 n'est pas un échec, c'est un tour de file.** Le bouton
        // reste désarmé le temps annoncé, et le message dit d'attendre plutôt
        // que de réessayer.
        if (failure is TooManyRequestsFailure) {
          final wait =
              failure.retryAfter ??
              AppConstants.enrollmentEntriesReportRetryFallback;
          emit(
            state.copyWith(
              status: EnrollmentEntriesReportStatus.cooldown,
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
            status: EnrollmentEntriesReportStatus.idle,
            failure: failure,
            report: null,
            retryAfter: null,
          ),
        );
      },
      (report) => emit(
        state.copyWith(
          status: EnrollmentEntriesReportStatus.idle,
          report: report,
          failure: null,
          retryAfter: null,
        ),
      ),
    );
  }

  /// La vue a remis le document (ou dit l'échec) : l'état se vide.
  ///
  /// Sans ça, le même document serait re-remis à chaque reconstruction, et le
  /// même message rejoué à chaque retour sur l'écran.
  void acknowledge() {
    if (!state.hasDelivery) return;
    emit(state.clearDelivery());
  }

  void _startCooldown(Duration wait) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(wait, () {
      if (isClosed) return;
      emit(state.copyWith(status: EnrollmentEntriesReportStatus.idle));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
