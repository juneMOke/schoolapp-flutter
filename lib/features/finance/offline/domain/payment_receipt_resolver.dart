import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// D'où vient le numéro d'un reçu, et donc ce qu'il vaut.
enum PaymentReceiptStatus {
  /// Scellé par le serveur : il fait foi.
  definitive,

  /// `PROV-…` de ce poste : l'encaissement n'est pas encore acquitté.
  provisional,

  /// Aucun numéro connu de cette tablette.
  unknown,
}

/// Le reçu d'un versement, tel que cette tablette peut le connaître.
class PaymentReceiptReference extends Equatable {
  /// Numéro affichable, `null` quand [status] vaut
  /// [PaymentReceiptStatus.unknown]. Jamais l'identifiant technique du
  /// versement : le repli court se demande à [shortFallback].
  final String? number;

  final PaymentReceiptStatus status;

  /// Identifiant serveur de la pièce (`payments.receipt_id`). Il désigne le
  /// reçu même quand son numéro est inconnu, et suffit à le restituer.
  final String? documentId;

  /// Ce que le cache des pièces sait de ce reçu, `null` s'il n'en sait rien.
  ///
  /// Brute, sans le filtre de `FindCachedDocumentUseCase` : une pièce apprise
  /// par le pull, sans octets, porte quand même son numéro et son annulation.
  final EditiqueCacheEntry? cacheEntry;

  /// `payments.cancelled_at` : le serveur a annulé le VERSEMENT lui-même.
  final int? paymentCancelledAt;

  const PaymentReceiptReference({
    this.number,
    this.status = PaymentReceiptStatus.unknown,
    this.documentId,
    this.cacheEntry,
    this.paymentCancelledAt,
  });

  bool get isDefinitive => status == PaymentReceiptStatus.definitive;

  bool get isReceiptCancelled => cacheEntry?.isCancelled ?? false;

  bool get isPaymentCancelled => paymentCancelledAt != null;

  /// Le reçu ou le versement a été annulé : plus aucun papier ne doit
  /// l'attester.
  bool get isCancelled => isReceiptCancelled || isPaymentCancelled;

  /// Repli quand aucun numéro n'est connu : les huit premiers caractères du
  /// versement, en majuscules — le suffixe des `PROV-…` que le guichet connaît
  /// déjà. Un ticket reste ainsi rapprochable sans imprimer un UUID entier.
  static String shortFallback(String paymentId) {
    final compact = paymentId.replaceAll('-', '').trim();
    final head = compact.length > 8 ? compact.substring(0, 8) : compact;
    return head.toUpperCase();
  }

  @override
  List<Object?> get props => [
    number,
    status,
    documentId,
    cacheEntry,
    paymentCancelledAt,
  ];
}

/// Le seul endroit où se décide le reçu d'un versement (T0, lot R1).
///
/// Ordre de résolution : la ligne RC locale scellée, puis le cache des pièces
/// par `payments.receipt_id`, puis le `PROV-…` local, puis rien.
///
/// Ne remonte jamais d'erreur : ne pas savoir revient à rendre
/// [PaymentReceiptStatus.unknown].
abstract interface class PaymentReceiptResolver {
  Future<PaymentReceiptReference> resolve(String paymentId);
}
