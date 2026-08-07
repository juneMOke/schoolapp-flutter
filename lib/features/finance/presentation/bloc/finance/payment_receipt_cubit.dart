import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/find_cached_document_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payment_receipt_document_use_case.dart';

/// Numéro de pièce du reçu d'un paiement, pour la ligne « Reçu n° » du détail.
///
/// Volontairement minuscule et sans état d'erreur : c'est une information
/// d'affichage. Quand elle manque, la ligne reste neutre — le reste du détail
/// (montant, payeur, imputations) n'a pas à en souffrir.
class PaymentReceiptCubit extends Cubit<PaymentReceiptState> {
  final GetPaymentReceiptDocumentUseCase _getPaymentReceiptDocumentUseCase;
  final FindCachedDocumentUseCase _findCachedDocument;

  PaymentReceiptCubit(
    this._getPaymentReceiptDocumentUseCase,
    this._findCachedDocument,
  ) : super(const PaymentReceiptState());

  Future<void> load(String paymentId) async {
    final document = await _getPaymentReceiptDocumentUseCase(paymentId);
    if (isClosed) return;

    final isDefinitive = document?.isDefinitive ?? false;
    final number = document?.number;
    // La copie locale ne se cherche que sous un numéro DÉFINITIF : un `PROV-…`
    // ne désigne rien côté serveur et n'a jamais pu être mis en cache.
    final cached = (isDefinitive && number != null)
        ? await _findCachedDocument(documentNumber: number)
        : null;
    if (isClosed) return;

    emit(
      PaymentReceiptState(
        loaded: true,
        number: number,
        // Affirmation POSITIVE, jamais déduite d'une négation : le numéro ne
        // fait foi que sur un statut `DEFINITIVE` scellé par l'ACK. Tant que
        // l'encaissement n'est pas acquitté, `number` vaut `PROV-…` — et tout
        // statut inconnu retombe ici du bon côté (non définitif).
        isDefinitive: isDefinitive,
        cached: cached,
      ),
    );
  }
}

class PaymentReceiptState extends Equatable {
  final bool loaded;
  final String? number;

  /// Copie scellée du reçu détenue par cette tablette, `null` sinon.
  ///
  /// C'est elle qui décide du geste : ressortir la copie — ce qui fonctionne
  /// hors ligne — plutôt que redemander la pièce au serveur.
  final EditiqueCacheEntry? cached;

  /// Le numéro porté par [number] est scellé côté serveur. `false` par défaut :
  /// tant qu'on ne sait pas, on ne prétend pas.
  final bool isDefinitive;

  const PaymentReceiptState({
    this.loaded = false,
    this.number,
    this.isDefinitive = false,
    this.cached,
  });

  /// Vrai quand un numéro **définitif** est connu et affichable tel quel.
  bool get hasDefinitiveNumber =>
      isDefinitive && (number?.trim().isNotEmpty ?? false);

  /// Vrai quand un numéro PROVISOIRE est effectivement connu localement.
  ///
  /// Affirmation positive, et c'est essentiel : `!isDefinitive` serait vrai
  /// aussi quand aucune ligne locale n'existe — cas NORMAL d'un paiement
  /// encaissé sur un AUTRE poste et descendu par pull. Un versement pourtant
  /// synchronisé serait alors annoncé « en attente de synchronisation ».
  bool get hasProvisionalNumber =>
      loaded && !isDefinitive && (number?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [loaded, number, isDefinitive, cached];
}
