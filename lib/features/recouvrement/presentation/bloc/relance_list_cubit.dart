import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_list.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/usecases/emit_relance_list_usecase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

part 'relance_list_state.dart';

/// L'émission de la liste de relance — **une à la fois**.
///
/// Trois choses survivent à l'appui, et doivent être portées quelque part :
///
/// 1. **La préparation**, qui dure — le rendu prend plusieurs secondes, et le
///    corps met du temps à monter. La ligne se désarme, sans quoi deux appuis
///    lancent deux rendus et le second part en 429.
/// 2. **L'attente imposée par le serveur.** Il ne produit qu'un document long à
///    la fois, et le permis est **partagé** avec le rapport de caisse et le
///    registre d'inscriptions : le refus peut venir d'un collègue. Réarmer tout
///    de suite inviterait à reproduire exactement ce qui vient d'être refusé.
/// 3. **Le document lui-même**, qui doit traverser jusqu'au geste de
///    plateforme.
///
/// ## Le document est REMIS, puis oublié
///
/// [RelanceList] ne reste dans l'état que le temps que la vue le passe au
/// spouleur, après quoi [acknowledge] le retire. Le serveur **n'archive pas**
/// cette pièce : redemander la même liste en produit une autre, sous un autre
/// numéro. Un document qui séjournerait dans l'état se ferait fatalement
/// re-présenter un jour comme « la » liste, alors qu'il n'en est qu'un tirage.
class RelanceListCubit extends Cubit<RelanceListState> {
  final EmitRelanceListUseCase _emitRelanceList;
  final CountPendingPaymentsUseCase _countPendingPayments;

  Timer? _cooldownTimer;

  RelanceListCubit({
    required EmitRelanceListUseCase emitRelanceList,
    required CountPendingPaymentsUseCase countPendingPayments,
  }) : _emitRelanceList = emitRelanceList,
       _countPendingPayments = countPendingPayments,
       super(const RelanceListState());

  /// Émet la liste d'un périmètre, sur les lignes **déjà filtrées** par
  /// l'écran.
  ///
  /// Ne fait rien si un rendu est en cours ou si l'attente d'un 429 court
  /// encore : c'est la garde qui rend le « un à la fois » vrai même quand
  /// l'interface laisse passer un second appui.
  Future<void> emit_({
    required RelanceScope scope,
    required List<String> feeCodes,
    required RecouvrementCriterion criterion,
    required List<LocalRecoveryLine> lines,
    int? thresholdInCents,
    String? thresholdCurrency,
  }) async {
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: RelanceListStatus.preparing,
        document: null,
        failure: null,
        retryAfter: null,
      ),
    );

    // Compté ICI, au plus près de l'envoi : entre le clic et la requête, la
    // file peut se vider. Un échec de comptage n'empêche pas d'éditer — la
    // mention disparaît, elle ne ment pas.
    final pendingWrites = (await _countPendingPayments()).fold(
      (_) => null,
      (count) => count > 0 ? count : null,
    );

    final result = await _emitRelanceList(
      scope: scope,
      feeCodes: feeCodes,
      criterion: criterion,
      lines: lines,
      // L'heure de l'appareil, et c'est assumé : le document imprime AUSSI la
      // date d'émission du serveur, et les deux ne se confondent pas.
      arretedAt: DateTime.now(),
      thresholdInCents: thresholdInCents,
      thresholdCurrency: thresholdCurrency,
      pendingWrites: pendingWrites,
    );

    result.fold(
      (failure) {
        // ⚠️ **Le 429 n'est pas un échec, c'est un tour de file.** Il porte son
        // propre état : la ligne reste désarmée le temps annoncé, et le message
        // dit d'attendre plutôt que de réessayer.
        if (failure is TooManyRequestsFailure) {
          final wait =
              failure.retryAfter ?? AppConstants.financeTillReportRetryFallback;
          emit(
            state.copyWith(
              status: RelanceListStatus.cooldown,
              failure: failure,
              retryAfter: wait,
              document: null,
            ),
          );
          _startCooldown(wait);
          return;
        }
        emit(
          state.copyWith(
            status: RelanceListStatus.idle,
            failure: failure,
            document: null,
            retryAfter: null,
          ),
        );
      },
      (document) => emit(
        state.copyWith(
          status: RelanceListStatus.idle,
          document: document,
          failure: null,
          retryAfter: null,
        ),
      ),
    );
  }

  /// La vue a remis le document (ou dit l'échec) : l'état se vide.
  ///
  /// Sans ça, le même document serait re-remis à chaque reconstruction de la
  /// vue, et le même message rejoué à chaque retour sur l'écran.
  void acknowledge() {
    if (state.document == null && state.failure == null) return;
    emit(state.clearDelivery());
  }

  void _startCooldown(Duration wait) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(wait, () {
      if (isClosed) return;
      emit(state.copyWith(status: RelanceListStatus.idle));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
