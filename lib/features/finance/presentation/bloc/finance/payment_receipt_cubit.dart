import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';

/// Numéro de pièce du reçu d'un paiement, pour la ligne « Reçu n° » du détail.
///
/// Volontairement minuscule et sans état d'erreur : c'est une information
/// d'affichage. Quand elle manque, la ligne reste neutre — le reste du détail
/// (montant, payeur, imputations) n'a pas à en souffrir.
class PaymentReceiptCubit extends Cubit<PaymentReceiptState> {
  final PaymentReceiptResolver _resolver;

  PaymentReceiptCubit(this._resolver) : super(const PaymentReceiptState());

  Future<void> load(String paymentId) async {
    final receipt = await _resolver.resolve(paymentId);
    if (isClosed) return;

    emit(
      PaymentReceiptState(
        loaded: true,
        number: receipt.number,
        // Affirmation POSITIVE, jamais déduite d'une négation : le numéro ne
        // fait foi que scellé par le serveur. Tant que l'encaissement n'est pas
        // acquitté, `number` vaut `PROV-…` — et tout statut inconnu retombe ici
        // du bon côté (non définitif).
        isDefinitive: receipt.isDefinitive,
        cached: receipt.cacheEntry,
        documentId: receipt.documentId,
        paymentCancelled: receipt.isPaymentCancelled,
      ),
    );
  }
}

class PaymentReceiptState extends Equatable {
  final bool loaded;
  final String? number;

  /// Ce que le cache des pièces sait du reçu, `null` s'il n'en sait rien.
  ///
  /// Trouvée par l'identifiant du reçu, elle porte son annulation même quand
  /// le PDF n'a jamais été téléchargé sur cette tablette.
  final EditiqueCacheEntry? cached;

  /// Identifiant serveur du reçu (`payments.receipt_id`). Il suffit à le
  /// restituer : un reçu qu'il désigne ne s'émet jamais une seconde fois.
  final String? documentId;

  /// Le serveur a annulé le versement lui-même.
  final bool paymentCancelled;

  /// Le numéro porté par [number] est scellé côté serveur. `false` par défaut :
  /// tant qu'on ne sait pas, on ne prétend pas.
  final bool isDefinitive;

  const PaymentReceiptState({
    this.loaded = false,
    this.number,
    this.isDefinitive = false,
    this.cached,
    this.documentId,
    this.paymentCancelled = false,
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
  List<Object?> get props => [
    loaded,
    number,
    isDefinitive,
    cached,
    documentId,
    paymentCancelled,
  ];
}
