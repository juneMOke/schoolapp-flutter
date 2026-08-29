import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/find_boutique_payer_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';

part 'boutique_event.dart';
part 'boutique_state.dart';

/// L'écran de caisse : le catalogue en lecture, le panier en composition.
///
/// **Toutes les règles d'argent vivent dans [BoutiqueCart]**, pas ici. Ce bloc
/// ne fait que router des gestes vers un panier immuable et publier le résultat
/// — ce qui rend les règles exerçables sans monter d'écran, et empêche qu'un
/// second chemin les réinvente.
class BoutiqueBloc extends Bloc<BoutiqueEvent, BoutiqueState> {
  final GetBoutiqueCatalogUseCase _getCatalog;
  final FindBoutiquePayerUseCase _findPayer;
  final RecordBoutiqueSaleUseCase _recordSale;
  final IdGenerator _ids;

  BoutiqueBloc({
    required GetBoutiqueCatalogUseCase getCatalog,
    required FindBoutiquePayerUseCase findPayer,
    required RecordBoutiqueSaleUseCase recordSale,
    required IdGenerator ids,
  }) : _getCatalog = getCatalog,
       _findPayer = findPayer,
       _recordSale = recordSale,
       _ids = ids,
       super(const BoutiqueState()) {
    on<BoutiqueCatalogRequested>(_onCatalogRequested);
    on<BoutiqueQueryChanged>(_onQueryChanged);
    on<BoutiqueFamilyFilterChanged>(_onFamilyFilterChanged);
    on<BoutiqueFiltersReset>(_onFiltersReset);
    on<BoutiqueArticleAdded>(_onArticleAdded);
    on<BoutiqueLineRemoved>(_onLineRemoved);
    on<BoutiqueLineQuantityChanged>(_onLineQuantityChanged);
    on<BoutiqueLineBeneficiaryAssigned>(_onBeneficiaryAssigned);
    on<BoutiqueLineBeneficiaryCleared>(_onBeneficiaryCleared);
    on<BoutiqueLineLevelChanged>(_onLevelChanged);
    on<BoutiqueLineSizeChanged>(_onSizeChanged);
    on<BoutiquePayerChanged>(_onPayerChanged);
    on<BoutiquePayerFromDirectoryUsed>(_onPayerFromDirectoryUsed);
    on<BoutiqueCartCleared>(_onCartCleared);
    on<BoutiqueSaleSubmitted>(_onSaleSubmitted);
    on<BoutiqueNewSaleStarted>(_onNewSaleStarted);
  }

  Future<void> _onCatalogRequested(
    BoutiqueCatalogRequested event,
    Emitter<BoutiqueState> emit,
  ) async {
    emit(state.copyWith(status: BoutiqueStatus.loading, clearFailure: true));
    final result = await _getCatalog(event.academicYearId);
    result.fold(
      (failure) => emit(
        state.copyWith(status: BoutiqueStatus.failure, failure: failure),
      ),
      // Le panier n'est PAS touché : le catalogue se recharge sous une vente en
      // composition sans la faire perdre.
      (catalog) => emit(
        state.copyWith(
          status: BoutiqueStatus.ready,
          catalog: catalog,
          clearFailure: true,
        ),
      ),
    );
  }

  void _onQueryChanged(
    BoutiqueQueryChanged event,
    Emitter<BoutiqueState> emit,
  ) => emit(state.copyWith(query: event.query));

  void _onFamilyFilterChanged(
    BoutiqueFamilyFilterChanged event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    event.family == null
        ? state.copyWith(clearFamilyFilter: true)
        : state.copyWith(familyFilter: event.family),
  );

  void _onFiltersReset(
    BoutiqueFiltersReset event,
    Emitter<BoutiqueState> emit,
  ) => emit(state.copyWith(query: '', clearFamilyFilter: true));

  void _onArticleAdded(
    BoutiqueArticleAdded event,
    Emitter<BoutiqueState> emit,
  ) {
    // Un article que ce client ne sait pas tarifer n'entre pas au panier : il y
    // porterait un prix nul que rien ne pourrait résoudre.
    if (!event.article.isSellable) return;
    emit(
      state.copyWith(
        cart: state.cart.addArticle(event.article, keyOf: _ids.newId),
      ),
    );
  }

  void _onLineRemoved(BoutiqueLineRemoved event, Emitter<BoutiqueState> emit) =>
      emit(state.copyWith(cart: state.cart.removeLine(event.lineKey)));

  void _onLineQuantityChanged(
    BoutiqueLineQuantityChanged event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    state.copyWith(cart: state.cart.setQuantity(event.lineKey, event.quantity)),
  );

  void _onBeneficiaryAssigned(
    BoutiqueLineBeneficiaryAssigned event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    state.copyWith(
      cart: state.cart.setBeneficiary(event.lineKey, event.beneficiary),
    ),
  );

  void _onBeneficiaryCleared(
    BoutiqueLineBeneficiaryCleared event,
    Emitter<BoutiqueState> emit,
  ) => emit(state.copyWith(cart: state.cart.clearBeneficiary(event.lineKey)));

  void _onLevelChanged(
    BoutiqueLineLevelChanged event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    state.copyWith(
      cart: state.cart.setDeclaredLevel(event.lineKey, event.schoolLevelId),
    ),
  );

  void _onSizeChanged(
    BoutiqueLineSizeChanged event,
    Emitter<BoutiqueState> emit,
  ) =>
      emit(state.copyWith(cart: state.cart.setSize(event.lineKey, event.size)));

  Future<void> _onPayerChanged(
    BoutiquePayerChanged event,
    Emitter<BoutiqueState> emit,
  ) async {
    final phoneChanged =
        event.payer.phoneNumber != state.cart.payer.phoneNumber;
    emit(
      state.copyWith(
        cart: state.cart.withPayer(event.payer),
        // La proposition appartient au numéro qui l'a produite : la garder
        // pendant qu'il change ferait offrir « Utiliser » sur un payeur qui
        // n'est plus celui du numéro affiché.
        clearPayerMatch: phoneChanged,
      ),
    );
    if (!phoneChanged) return;

    // On ne juge pas un numéro à moitié tapé : sous le seuil, aucune recherche
    // et aucun message.
    if (event.payer.phoneStatus != PayerPhoneStatus.usable) return;

    final match = await _findPayer(event.payer.phoneNumber);
    // Le numéro a pu changer pendant la lecture : appliquer un résultat périmé
    // proposerait le payeur d'un numéro que le guichet vient de corriger.
    if (state.cart.payer.phoneNumber != event.payer.phoneNumber) return;
    emit(
      match == null
          ? state.copyWith(clearPayerMatch: true)
          : state.copyWith(payerMatch: match),
    );
  }

  /// « Utiliser » : le payeur du répertoire remplit le bloc.
  ///
  /// Le téléphone est normalisé au passage — c'est la clé, et deux écritures du
  /// même numéro feraient deux payeurs à la prochaine recherche.
  void _onPayerFromDirectoryUsed(
    BoutiquePayerFromDirectoryUsed event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    state.copyWith(cart: state.cart.withPayer(event.payer.toCartPayer())),
  );

  void _onCartCleared(
    BoutiqueCartCleared event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    // La proposition du répertoire part avec le payeur : la laisser ferait
    // offrir « Utiliser » sur un bloc vidé, pour un numéro qui n'y est plus.
    state.copyWith(cart: state.cart.cleared(), clearPayerMatch: true),
  );

  /// Encaisse : écriture locale, push différé.
  ///
  /// **Le panier n'est PAS vidé à l'encaissement.** Il reste intact jusqu'à
  /// « Nouvelle vente », ce qui permet de réimprimer le ticket sans recomposer —
  /// et évite qu'un doigt malheureux efface la vente qu'on est en train de
  /// remettre.
  Future<void> _onSaleSubmitted(
    BoutiqueSaleSubmitted event,
    Emitter<BoutiqueState> emit,
  ) async {
    // Garde anti-double-envoi : deux appuis rapides sur « Encaisser » créeraient
    // deux ventes, avec deux uuid, donc deux fois l'argent dans les livres.
    if (state.isCollecting || state.recordedSale != null) return;
    if (!state.cart.canCollect) return;

    emit(state.copyWith(isCollecting: true, clearSaleFailure: true));
    final result = await _recordSale(
      cart: state.cart,
      academicYearId: event.academicYearId,
      cashierName: event.cashierName,
    );

    result.fold(
      // L'écriture est atomique : un échec n'a RIEN posé, et le guichet peut
      // réessayer sans risque de double vente. L'erreur reste dans la modale,
      // le panier intact — jamais un écran d'erreur pleine page sur une vente
      // déjà composée.
      (failure) =>
          emit(state.copyWith(isCollecting: false, saleFailure: failure)),
      (sale) => emit(
        state.copyWith(
          isCollecting: false,
          recordedSale: sale,
          clearSaleFailure: true,
        ),
      ),
    );
  }

  /// « Nouvelle vente » : vide le panier et le payeur, **garde l'écran en
  /// place**. Pas de retour à l'accueil — le guichet enchaîne.
  void _onNewSaleStarted(
    BoutiqueNewSaleStarted event,
    Emitter<BoutiqueState> emit,
  ) => emit(
    state.copyWith(
      cart: state.cart.cleared(),
      clearPayerMatch: true,
      clearRecordedSale: true,
      clearSaleFailure: true,
    ),
  );
}
