import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';

/// Guette le **numéro définitif** du reçu d'une vente qui vient d'être écrite.
///
/// Pendant de `ReceiptNumberWatchCubit` (le versement) : le ticket de vente ne
/// sort qu'avec son `ETL-RV-…`, que l'ACK pose en base quelques secondes après
/// l'écriture. On relit donc la vente à intervalle régulier, puis on renonce au
/// bout du délai — le ticket s'imprimera alors depuis la fiche de la vente.
///
/// Relu en base et pas écouté sur le moteur de synchro : c'est la base que le
/// ticket lira, et un numéro qu'elle n'a pas encore n'imprimerait rien.
class SaleReceiptWatchCubit extends Cubit<SaleReceiptWatchState> {
  final GetBoutiqueSaleDetailUseCase _detail;
  final Duration _every;
  final Duration _giveUpAfter;

  /// Relance la synchro tant que le numéro manque. La marque « reçu manquant »
  /// naît PENDANT le flush qui applique l'ACK, et n'en fait donc pas partie :
  /// sans relance, elle attendrait le battement suivant (45 s), bien après que
  /// la modale a renoncé (30 s). Un flush déjà en cours se contente de rendre
  /// la main.
  final Future<void> Function()? _nudge;
  Timer? _timer;

  SaleReceiptWatchCubit(
    this._detail, {
    Duration every = AppConstants.receiptNumberPollInterval,
    Duration giveUpAfter = AppConstants.receiptNumberWaitLimit,
    Future<void> Function()? nudge,
  }) : _every = every,
       _giveUpAfter = giveUpAfter,
       _nudge = nudge,
       super(const SaleReceiptWatchState());

  /// Commence à guetter [sale]. Une vente déjà numérotée est rendue tout de
  /// suite, sans minuteur.
  Future<void> watch(RecordedSale sale) async {
    _timer?.cancel();
    if (_numberOf(sale) != null) {
      emit(SaleReceiptWatchState(phase: SaleReceiptPhase.numbered, sale: sale));
      return;
    }
    emit(SaleReceiptWatchState(phase: SaleReceiptPhase.waiting, sale: sale));
    // Fermé pendant la première lecture (écran refermé) : aucun minuteur ne
    // doit naître après coup.
    if (await _check(sale.id) || isClosed) return;
    // Compté en relectures, pas à l'horloge : le délai se rejoue tel quel en
    // test.
    final attempts = _giveUpAfter.inMilliseconds ~/ _every.inMilliseconds;
    var reading = false;
    _timer = Timer.periodic(_every, (timer) async {
      // Une relecture à la fois : une lecture lente, rattrapée par la suivante,
      // pourrait sinon conclure « pas de numéro » APRÈS qu'une autre l'a trouvé.
      if (reading) return;
      reading = true;
      final found = await _check(sale.id);
      reading = false;
      if (found || state.phase == SaleReceiptPhase.numbered) {
        timer.cancel();
      } else if (timer.tick >= attempts) {
        timer.cancel();
        if (!isClosed) {
          emit(
            SaleReceiptWatchState(
              phase: SaleReceiptPhase.deferred,
              sale: state.sale,
            ),
          );
        }
      }
    });
  }

  Future<bool> _check(String saleId) async {
    final read = await _detail(saleId);
    final sale = read.fold((_) => null, (detail) => detail.sale);
    if (isClosed || sale == null) return false;
    if (_numberOf(sale) == null) {
      _nudgeQuietly();
      return false;
    }
    emit(SaleReceiptWatchState(phase: SaleReceiptPhase.numbered, sale: sale));
    return true;
  }

  void _nudgeQuietly() {
    final nudge = _nudge;
    if (nudge == null) return;
    unawaited(nudge().catchError((Object _) {}));
  }

  static String? _numberOf(RecordedSale sale) {
    final number = sale.sale.receiptNumber?.trim() ?? '';
    return number.isEmpty ? null : number;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

enum SaleReceiptPhase {
  /// Rien n'est guetté.
  idle,

  /// La vente est écrite, son numéro pas encore là.
  waiting,

  /// Le numéro est là : le ticket peut sortir.
  numbered,

  /// Le délai est passé sans numéro : le ticket attendra la synchronisation.
  deferred,
}

class SaleReceiptWatchState extends Equatable {
  final SaleReceiptPhase phase;

  /// La vente telle que relue — celle qui porte le numéro une fois
  /// [SaleReceiptPhase.numbered], et donc celle qu'il faut imprimer.
  final RecordedSale? sale;

  const SaleReceiptWatchState({this.phase = SaleReceiptPhase.idle, this.sale});

  String? get receiptNumber => sale?.sale.receiptNumber?.trim();

  @override
  List<Object?> get props => [phase, sale];
}
