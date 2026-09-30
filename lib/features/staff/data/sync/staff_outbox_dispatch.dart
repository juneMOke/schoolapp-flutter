import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

/// Le squelette partagé des envois RH : décoder le payload figé, pousser, et
/// classer l'issue. Chaque handler n'écrit que ce qui lui est propre — ses
/// gardes d'ordre, son accusé et son refus.
abstract final class StaffOutboxDispatch {
  /// Le payload relu par [parse] ; `null` s'il est illisible ou incomplet —
  /// un payload qui ne se relit pas ne se répare pas en le rejouant.
  static T? decode<T>(String payload, T? Function(Object? raw) parse) {
    try {
      return parse(jsonDecode(payload));
    } catch (_) {
      return null;
    }
  }

  /// Pousse par [send] et classe l'issue :
  /// - 409 d'attente (`*_NOT_YET_SYNCED`) → `blocked`, sans tentative ;
  /// - transport, 5xx, 401/408/429, 409 ordinaire → `retry` ;
  /// - 410 → [onTombstone] puis acquitté, quand le handler sait l'effacer ;
  /// - refus déterministe → [reject], qui rend `false` quand une saisie plus
  ///   récente a remplacé celle envoyée (l'entrée repart alors avec elle).
  ///
  /// Un échec **local** après un envoi peut-être accusé se rejoue : l'envoi
  /// est idempotent, le serveur rendra le même état.
  static Future<OutboxDispatchResult> push({
    required Future<void> Function() send,
    required Future<bool> Function(StaffPushFailure failure) reject,
    Future<void> Function()? onTombstone,
  }) async {
    try {
      await send();
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = StaffPushFailure.of(e);
      if (failure.isDependencyWait) {
        return OutboxDispatchResult.blocked(failure.reason);
      }
      if (failure.isTombstoned && onTombstone != null) {
        await onTombstone();
        return const OutboxDispatchResult.acked();
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      return await reject(failure)
          ? OutboxDispatchResult.failed(failure.reason)
          : OutboxDispatchResult.retry(failure.reason);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
