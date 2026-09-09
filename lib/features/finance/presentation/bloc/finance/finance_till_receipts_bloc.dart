import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipt.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_till_receipts_usecase.dart';

part 'finance_till_receipts_event.dart';
part 'finance_till_receipts_state.dart';

/// La table des reçus — **un second appel, subordonné au premier**.
///
/// ## Pourquoi un BLoC à part
///
/// Trois raisons, et aucune n'est de confort :
///
/// 1. **Une seconde permission.** Le serveur exige `finance.payment.read` en
///    plus de `finance.stats.read`. Un utilisateur qui n'a que le pilotage
///    reçoit 200 sur les agrégats et **403 ici**. Deux réponses différentes ne
///    peuvent pas vivre dans un état commun — et surtout, l'échec de l'une ne
///    doit pas effacer l'autre.
/// 2. **Une pagination**, qui n'a aucun sens pour les agrégats.
/// 3. **Une portée différente** : depuis que la table porte « Paiements », elle
///    couvre **toutes les caisses** de la fenêtre, là où les cartes qui
///    l'entourent en détaillent une seule. C'est le seul bloc de l'écran que la
///    bascule de devise ne rejoue pas.
///
/// ## Ce que ce BLoC ne décide PAS
///
/// Ni **quand** charger, ni **quelle fenêtre**. C'est le bloc des agrégats qui
/// fait autorité ; celui-ci reçoit la fenêtre et se contente de la servir. La page ne construit ce sous-arbre que
/// dans sa branche `success` : si les agrégats échouent, ce BLoC n'est pas dans
/// l'arbre du tout, et la règle « l'erreur remplace tout le contenu » est tenue
/// par la structure plutôt que par une condition qu'un widget pourrait oublier.
class FinanceTillReceiptsBloc
    extends Bloc<FinanceTillReceiptsEvent, FinanceTillReceiptsState> {
  final GetTillReceiptsUseCase _getTillReceiptsUseCase;

  FinanceTillReceiptsBloc({
    required GetTillReceiptsUseCase getTillReceiptsUseCase,
  }) : _getTillReceiptsUseCase = getTillReceiptsUseCase,
       super(const FinanceTillReceiptsState()) {
    on<FinanceTillReceiptsRequested>(_onRequested);
    on<FinanceTillReceiptsPageChanged>(_onPageChanged);
  }

  /// Changer de fenêtre **remet la pagination à zéro**.
  ///
  /// Rester page 3 en changeant de fenêtre afficherait une page vide d'une
  /// liste qui, elle, a des lignes — et le lecteur conclurait que la période
  /// n'a rien reçu.
  Future<void> _onRequested(
    FinanceTillReceiptsRequested event,
    Emitter<FinanceTillReceiptsState> emit,
  ) async {
    // **Ne redemande pas ce qu'on sert déjà.** L'onglet déclenche depuis deux
    // endroits — son montage et l'écouteur des agrégats — parce qu'un écouteur
    // seul rate l'état qu'il trouve. Les deux peuvent coïncider ; le second ne
    // doit pas relancer un appel identique, ni faire clignoter une table déjà
    // remplie.
    //
    // Un échec, lui, se rejoue : c'est le geste de « Réessayer ».
    if (event.window == state.window &&
        (state.status == FinanceTillReceiptsStatus.loading ||
            state.status == FinanceTillReceiptsStatus.success ||
            state.status == FinanceTillReceiptsStatus.empty)) {
      return;
    }

    await _load(emit, window: event.window, page: 0);
  }

  Future<void> _onPageChanged(
    FinanceTillReceiptsPageChanged event,
    Emitter<FinanceTillReceiptsState> emit,
  ) async {
    // Rien à tourner tant que rien n'a été servi : la barre de pagination ne
    // se monte qu'avec des lignes, mais l'événement, lui, resterait recevable.
    if (state.status == FinanceTillReceiptsStatus.initial) return;
    await _load(emit, window: state.window, page: event.page);
  }

  Future<void> _load(
    Emitter<FinanceTillReceiptsState> emit, {
    required TillWindow window,
    required int page,
  }) async {
    emit(
      state.copyWith(
        status: FinanceTillReceiptsStatus.loading,
        window: window,
        page: page,
        failure: null,
      ),
    );

    final result = await _getTillReceiptsUseCase(window: window, page: page);

    result.fold(
      // L'échec emporte les lignes — mais **pas les cartes**, qui vivent dans
      // l'autre BLoC. Une page de noms périmée sous un message d'erreur serait
      // au mieux troublante, au pire fausse.
      (failure) => emit(
        state.copyWith(
          status: FinanceTillReceiptsStatus.error,
          receipts: const [],
          failure: failure,
        ),
      ),
      (paged) => emit(
        state.copyWith(
          status: paged.content.isEmpty
              ? FinanceTillReceiptsStatus.empty
              : FinanceTillReceiptsStatus.success,
          receipts: paged.content,
          page: paged.page,
          totalElements: paged.totalElements,
          totalPages: paged.totalPages,
          withoutReceiptNumber: paged.withoutReceiptNumber,
          failure: null,
        ),
      ),
    );
  }
}
