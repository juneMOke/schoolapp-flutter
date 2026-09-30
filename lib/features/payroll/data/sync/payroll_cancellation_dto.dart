import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';

/// L'annulation d'un fait de paie telle qu'elle est mise en file puis
/// poussée — `{ cancellationId, advanceId|disbursementId, reason }`. La même
/// forme pour l'avance et le versement : seule la clé de la cible change.
class PayrollCancellationRequestDto {
  /// `advanceId` ou `disbursementId`.
  final String targetKey;
  final String cancellationId;
  final String targetId;
  final String reason;
  final String authorId;

  const PayrollCancellationRequestDto({
    required this.targetKey,
    required this.cancellationId,
    required this.targetId,
    required this.reason,
    required this.authorId,
  });

  static const String advanceKey = 'advanceId';
  static const String disbursementKey = 'disbursementId';

  Map<String, dynamic> toJson() => {
    'cancellationId': cancellationId,
    targetKey: targetId,
    'reason': reason,
    kOutboxAuthorIdKey: authorId,
  };

  static PayrollCancellationRequestDto? tryParse(
    Object? raw, {
    required String targetKey,
  }) {
    if (raw is! Map) return null;
    final id = raw.text('cancellationId');
    final target = raw.text(targetKey);
    final reason = raw.text('reason');
    final author = raw.text(kOutboxAuthorIdKey);
    if (id == null || target == null || reason == null || author == null) {
      return null;
    }
    return PayrollCancellationRequestDto(
      targetKey: targetKey,
      cancellationId: id,
      targetId: target,
      reason: reason,
      authorId: author,
    );
  }
}
