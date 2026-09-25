import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';

/// Le payload d'outbox d'un **geste du circuit**, et son corps de requête.
///
/// Un geste = une entrée, identifiée par l'uuid de son message (F21, Q3).
/// **L'inverse du contenu, délibérément** : le contenu s'écrase (LWW), un
/// geste jamais — approuver puis annuler puis refuser, ce sont trois faits, et
/// le serveur ne recevra jamais « l'état final » parce qu'il ne saurait pas
/// l'atteindre.
///
/// ⚠️ **Le geste voyage dans le CHEMIN**, pas dans un champ du corps : chaque
/// route a sa propre garde côté serveur, et une route unique ferait dépendre
/// l'autorisation d'une valeur postée.
///
/// Le back a adopté cette enveloppe telle quelle pour les sept routes
/// (2026-09-25). **L'`openApi.yaml` fera foi à la livraison** — d'où une seule
/// fonction de sérialisation, pour qu'un renommage soit une ligne.
class ExpenseGesturePayload {
  final String expenseId;
  final ExpenseGesture gesture;

  /// L'uuid du message que ce geste écrit — **la clé d'idempotence**, côté
  /// poste comme côté serveur.
  final String messageId;

  /// Le corps du message : motif d'un refus, texte d'un commentaire, vide
  /// pour un geste qui se suffit.
  final String body;

  /// L'instant du geste, ISO-8601 UTC. Le serveur le borne
  /// (`ClientClockGuard`) puis le tronque à la microseconde.
  final String decidedAt;

  /// **Seulement pour « corriger et renvoyer »** (F32, offre du back
  /// acceptée) : l'horloge du contenu que le renvoi croit en place. Tant que
  /// la copie serveur est plus ancienne, il refuse en 409 rejouable — et
  /// l'invariant « le renvoi ne part qu'après l'accusé du contenu » cesse
  /// d'être une discipline du poste pour devenir une garantie.
  final String? expectedClientUpdatedAt;

  final String? authorId;

  const ExpenseGesturePayload({
    required this.expenseId,
    required this.gesture,
    required this.messageId,
    required this.body,
    required this.decidedAt,
    this.expectedClientUpdatedAt,
    this.authorId,
  });

  /// La route du geste, identifiant compris.
  String get endpoint => switch (gesture) {
    ExpenseGesture.approve ||
    ExpenseGesture.refuse => AppConstants.syncExpenseDecisionEndpoint,
    ExpenseGesture.pay => AppConstants.syncExpensePaymentEndpoint,
    ExpenseGesture.reopen => AppConstants.syncExpenseReopenEndpoint,
    ExpenseGesture.retract => AppConstants.syncExpenseRetractionEndpoint,
    ExpenseGesture.resubmit => AppConstants.syncExpenseResubmitEndpoint,
    ExpenseGesture.remind => AppConstants.syncExpenseReminderEndpoint,
    ExpenseGesture.comment => AppConstants.syncExpenseMessagesEndpoint,
  };

  /// Le corps de la requête.
  ///
  /// Le motif d'un refus voyage **une seule fois**, dans `message.body` : le
  /// serveur le recopie lui-même dans `decisionReason` (tranché le
  /// 2026-09-25), pour que la situation courante se lise sans dérouler
  /// l'historique (§14).
  Map<String, dynamic> toWireJson() => {
    if (gesture == ExpenseGesture.approve) 'action': 'APPROVE',
    if (gesture == ExpenseGesture.refuse) 'action': 'REFUSE',
    'decidedAt': decidedAt,
    'message': {'id': messageId, 'body': body},
    'expectedClientUpdatedAt': ?expectedClientUpdatedAt,
    kOutboxAuthorIdKey: ?authorId,
  };

  /// Ce que l'outbox range — le corps, plus ce qui voyage dans le chemin.
  Map<String, dynamic> toJson() => {
    'expenseId': expenseId,
    'gesture': gesture.name,
    'messageId': messageId,
    'body': body,
    'decidedAt': decidedAt,
    'expectedClientUpdatedAt': ?expectedClientUpdatedAt,
    kOutboxAuthorIdKey: ?authorId,
  };

  /// Relecture **stricte** du payload : un payload qui ne se relit pas ne se
  /// répare pas en le rejouant.
  ///
  /// Le geste est relu par son nom Dart, et un nom inconnu lève : une entrée
  /// écrite par une version plus récente de l'application ne doit pas partir
  /// sur la mauvaise route.
  factory ExpenseGesturePayload.fromJson(Map<String, dynamic> j) =>
      ExpenseGesturePayload(
        expenseId: j['expenseId'] as String,
        gesture: ExpenseGesture.values.byName(j['gesture'] as String),
        messageId: j['messageId'] as String,
        body: j['body'] as String,
        decidedAt: j['decidedAt'] as String,
        expectedClientUpdatedAt: j['expectedClientUpdatedAt'] as String?,
        authorId: j[kOutboxAuthorIdKey] as String?,
      );
}
