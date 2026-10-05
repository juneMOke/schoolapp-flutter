import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';

/// L'annulation d'un fait de paie telle qu'elle est mise en file puis
/// poussée — `FactCancellationRequest` du serveur, la même pour l'avance et
/// le versement : `{ cancellationId, targetId, reason, clientRecordedAt,
/// authorId }`.
class PayrollCancellationRequestDto {
  final String cancellationId;

  /// L'avance ou le versement annulé.
  final String targetId;
  final String reason;
  final String clientRecordedAt;
  final String authorId;

  const PayrollCancellationRequestDto({
    required this.cancellationId,
    required this.targetId,
    required this.reason,
    required this.clientRecordedAt,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
    'cancellationId': cancellationId,
    'targetId': targetId,
    'reason': reason,
    'clientRecordedAt': clientRecordedAt,
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollCancellationRequestDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('cancellationId');
    final target = raw.text('targetId');
    final reason = raw.text('reason');
    final at = raw.instant('clientRecordedAt');
    final author = raw.text(kOutboxAuthorIdKey);
    if (id == null ||
        target == null ||
        reason == null ||
        at == null ||
        author == null) {
      return null;
    }
    return PayrollCancellationRequestDto(
      cancellationId: id,
      targetId: target,
      reason: reason,
      clientRecordedAt: at,
      authorId: author,
    );
  }
}
