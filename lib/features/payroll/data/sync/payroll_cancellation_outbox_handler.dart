import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_cancellation_store.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Pousse une annulation ; rend le corps de l'accusé.
typedef PayrollCancellationSender =
    Future<dynamic> Function(
      Map<String, dynamic> extras,
      Map<String, dynamic> body,
    );

/// L'annulation d'un fait de paie — une avance ou un versement : le même
/// handler, paramétré par sa table et sa route.
///
/// - Le fait n'est **pas encore accusé** : l'annulation attend (`blocked`).
/// - Le fait a été **refusé** : il n'existe pas pour le serveur ; l'annulation
///   se clôt sur la tablette sans rien envoyer.
class PayrollCancellationOutboxHandler
    extends PayrollOutboxHandler<PayrollCancellationRequestDto> {
  @override
  final String aggregateType;
  final PayrollCancellationStore _store;
  final PayrollCancellationSender _sendCancellation;
  final String Function() _nowIso;

  PayrollCancellationOutboxHandler._({
    required this.aggregateType,
    required PayrollCancellationStore store,
    required PayrollCancellationSender sender,
    required super.outbox,
    required super.currentUser,
    required super.extras,
    String Function()? nowIso,
  }) : _store = store,
       _sendCancellation = sender,
       _nowIso = nowIso ?? (() => DateTime.now().toUtc().toIso8601String());

  /// `SALARY_ADVANCE_CANCELLATION`.
  factory PayrollCancellationOutboxHandler.advance({
    required PayrollCancellationStore store,
    required PayrollCancellationSender sender,
    required OutboxDao outbox,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    String Function()? nowIso,
  }) => PayrollCancellationOutboxHandler._(
    aggregateType: PayrollOutbox.advanceCancellation,
    store: store,
    sender: sender,
    outbox: outbox,
    currentUser: currentUser,
    extras: extras,
    nowIso: nowIso,
  );

  /// `PAYROLL_DISBURSEMENT_CANCELLATION` — attend aussi, sur la même ligne,
  /// ce qui a été posé avant elle.
  factory PayrollCancellationOutboxHandler.disbursement({
    required PayrollCancellationStore store,
    required PayrollCancellationSender sender,
    required OutboxDao outbox,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    String Function()? nowIso,
  }) => PayrollCancellationOutboxHandler._(
    aggregateType: PayrollOutbox.disbursementCancellation,
    store: store,
    sender: sender,
    outbox: outbox,
    currentUser: currentUser,
    extras: extras,
    nowIso: nowIso,
  );

  @override
  Set<String> get waitsFor =>
      aggregateType == PayrollOutbox.disbursementCancellation
      ? const {
          PayrollOutbox.disbursement,
          PayrollOutbox.disbursementCancellation,
        }
      : const {};

  @override
  PayrollCancellationRequestDto? parse(Object? raw) =>
      PayrollCancellationRequestDto.tryParse(raw);

  @override
  Future<OutboxDispatchResult?> hold(
    PayrollCancellationRequestDto request,
    String schoolId,
  ) async {
    final target = await _store.targetOf(request.cancellationId);
    if (target == null || target.state == RecordSyncState.failed) {
      await _store.settle(
        request.cancellationId,
        failed: false,
        cancelledAt: _nowIso(),
      );
      return const OutboxDispatchResult.acked();
    }
    if (target.state == RecordSyncState.pending) {
      return const OutboxDispatchResult.blocked(
        'Le fait annulé attend son propre envoi',
      );
    }
    return null;
  }

  @override
  Future<void> send(
    PayrollCancellationRequestDto request,
    String schoolId,
  ) async {
    final response = await _sendCancellation(extras, request.toJson());
    await _store.settle(
      request.cancellationId,
      failed: false,
      cancelledAt:
          (response is Map ? response.instant('cancelledAt') : null) ??
          _nowIso(),
    );
  }

  @override
  Future<bool> reject(
    PayrollCancellationRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) async {
    await _store.settle(
      request.cancellationId,
      failed: true,
      reason: failure.reason,
    );
    return true;
  }
}
