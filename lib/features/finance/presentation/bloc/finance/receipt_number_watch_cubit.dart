import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';

/// Attend le numéro DÉFINITIF du reçu d'un versement qui vient d'être écrit —
/// ou, pour un ticket d'annulation, l'annulation acquittée (lot B).
///
/// Un ticket ne sort plus qu'avec ce numéro (continuité des tickets RC,
/// lot D) : l'écran de succès s'affiche à l'écriture locale, avant l'accusé
/// du serveur. En ligne, l'accusé arrive en quelques secondes — on relit
/// donc le reçu à intervalle régulier, puis on renonce : le ticket attendra
/// dans « Tickets à imprimer ».
class ReceiptNumberWatchCubit extends Cubit<ReceiptNumberWatchState> {
  final PaymentReceiptResolver _resolver;
  final Duration _every;
  final Duration _giveUpAfter;

  Timer? _timer;

  ReceiptNumberWatchCubit(
    this._resolver, {
    Duration every = AppConstants.receiptNumberPollInterval,
    Duration giveUpAfter = AppConstants.receiptNumberWaitLimit,
  }) : _every = every,
       _giveUpAfter = giveUpAfter,
       super(const ReceiptNumberWatchState());

  /// [cancellation] : attendre aussi que le serveur ait acquitté
  /// l'annulation du versement — le ticket d'annulation l'affirme.
  Future<void> watch(String paymentId, {bool cancellation = false}) async {
    _timer?.cancel();
    emit(const ReceiptNumberWatchState(phase: ReceiptNumberPhase.waiting));
    // Fermé pendant la première lecture (écran refermé) : aucun minuteur ne
    // doit naître après coup.
    if (await _check(paymentId, cancellation) || isClosed) return;

    // Compté en relectures, pas à l'horloge : le délai est celui des
    // battements du minuteur, et il se rejoue tel quel en test.
    final attempts = _giveUpAfter.inMilliseconds ~/ _every.inMilliseconds;
    var reading = false;
    _timer = Timer.periodic(_every, (timer) async {
      // Une relecture à la fois : une lecture lente, rattrapée par la suivante,
      // pourrait sinon conclure « pas de numéro » APRÈS qu'une autre l'a trouvé.
      if (reading) return;
      reading = true;
      final found = await _check(paymentId, cancellation);
      reading = false;
      if (found || state.phase == ReceiptNumberPhase.numbered) {
        timer.cancel();
      } else if (timer.tick >= attempts) {
        timer.cancel();
        if (!isClosed) {
          emit(
            const ReceiptNumberWatchState(phase: ReceiptNumberPhase.deferred),
          );
        }
      }
    });
  }

  /// `true` quand le numéro est connu (et alors émis).
  Future<bool> _check(String paymentId, bool cancellation) async {
    final receipt = await _resolver.resolve(paymentId);
    final number = receipt.number?.trim();
    if (isClosed ||
        !receipt.isDefinitive ||
        number == null ||
        number.isEmpty ||
        (cancellation && !receipt.isPaymentCancelled)) {
      return false;
    }
    emit(
      ReceiptNumberWatchState(
        phase: ReceiptNumberPhase.numbered,
        number: number,
      ),
    );
    return true;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

enum ReceiptNumberPhase {
  /// Rien n'est encore demandé.
  idle,

  /// Le versement attend l'accusé du serveur.
  waiting,

  /// Le numéro définitif est connu : le ticket peut sortir.
  numbered,

  /// Pas d'accusé dans le délai (hors ligne, ou serveur lent) : le ticket
  /// sortira depuis « Tickets à imprimer ».
  deferred,
}

class ReceiptNumberWatchState extends Equatable {
  final ReceiptNumberPhase phase;
  final String? number;

  const ReceiptNumberWatchState({
    this.phase = ReceiptNumberPhase.idle,
    this.number,
  });

  @override
  List<Object?> get props => [phase, number];
}
