import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';

/// Ce qu'une déclaration met dans la file d'envoi (v3, F37) : la partie
/// `declaration` du multipart, plus ce qu'il faut pour relire la photo et
/// régler le fil à l'accusé. Les octets n'y sont **jamais** : ils restent
/// dans le magasin chiffré, relus au moment de l'envoi.
class ExpenseDeclarationPayload {
  final ExpenseInputDto expense;

  /// L'heure du décaissement, ISO-8601 UTC, telle que l'agent l'a dite —
  /// le serveur la borne lui-même à maintenant.
  final String disbursedAt;

  /// L'uuid du message `DECLARATION` : la clé d'idempotence, et le message
  /// qui ordonne la suite des gestes (F38).
  final String messageId;

  /// La note libre sur l'accord reçu ; vide permis.
  final String messageBody;
  final String authorId;

  /// Le type de la photo, reconnu à la capture.
  final String voucherContentType;

  /// L'uuid5 du message `VISA` d'office, quand le poste l'a écrit d'avance
  /// (F41) ; `null` sinon.
  final String? visaMessageId;

  const ExpenseDeclarationPayload({
    required this.expense,
    required this.disbursedAt,
    required this.messageId,
    required this.messageBody,
    required this.authorId,
    required this.voucherContentType,
    this.visaMessageId,
  });

  /// La partie `declaration` du multipart, telle que le contrat la décrit.
  Map<String, dynamic> toWireJson() => {
    'expense': expense.toJson(),
    'disbursedAt': disbursedAt,
    'message': {'id': messageId, 'body': messageBody},
    'authorId': authorId,
  };

  /// La forme rangée dans l'outbox : la partie envoyée, plus le reste.
  Map<String, dynamic> toJson() => {
    ...toWireJson(),
    'voucherContentType': voucherContentType,
    'visaMessageId': ?visaMessageId,
  };

  factory ExpenseDeclarationPayload.fromJson(Map<String, dynamic> j) {
    final message = j['message'] as Map<String, dynamic>;
    return ExpenseDeclarationPayload(
      expense: ExpenseInputDto.fromJson(j['expense'] as Map<String, dynamic>),
      disbursedAt: j['disbursedAt'] as String,
      messageId: message['id'] as String,
      messageBody: (message['body'] as String?) ?? '',
      authorId: j['authorId'] as String,
      voucherContentType: j['voucherContentType'] as String,
      visaMessageId: j['visaMessageId'] as String?,
    );
  }
}
