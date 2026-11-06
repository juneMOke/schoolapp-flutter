import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_push_failure.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_api.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';

/// Descente des ressources qu'une correction accusée a changées au serveur :
/// l'inscription, ses créances (et leurs pierres tombales), son membre de
/// classe.
typedef LevelCorrectionRefresh = Future<void> Function();

/// Handler d'outbox de l'agrégat `ENROLLMENT_LEVEL_CORRECTION`.
///
/// **Ordre par inscription** : un geste attend (`blocked`) tant qu'un geste
/// plus ancien de la même inscription est en file.
///
/// **Dépend de l'inscription** : tant que le dossier n'est pas accusé, le geste
/// attend — localement par la sonde, au serveur par le 409
/// `ENROLLMENT_NOT_YET_SYNCED`, seul 409 du contrat. Un 422 est terminal : la
/// ligne garde son code, et rien n'est à défaire, le geste n'ayant rien changé
/// localement.
///
/// **Après l'accusé**, la tablette n'a pas encore les nouvelles créances : le
/// handler lance la descente ([LevelCorrectionRefresh]) sans l'attendre. D'ici
/// là, l'inscription locale porte encore l'ancien niveau, et la garde du guichet
/// (E3) continue de bloquer l'encaissement.
class LevelCorrectionOutboxHandler implements OutboxSyncHandler {
  final LevelCorrectionApi _api;
  final LevelCorrectionSyncDao _sync;
  final OutboxDao _outbox;
  final OutboxDependencyGate _dependency;
  final LevelCorrectionChangeBus _bus;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final LevelCorrectionRefresh _refresh;
  final Clock _now;

  const LevelCorrectionOutboxHandler({
    required LevelCorrectionApi api,
    required LevelCorrectionSyncDao sync,
    required OutboxDao outbox,
    required OutboxDependencyGate dependency,
    required LevelCorrectionChangeBus bus,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    required LevelCorrectionRefresh refresh,
    Clock now = systemClock,
  }) : _api = api,
       _sync = sync,
       _outbox = outbox,
       _dependency = dependency,
       _bus = bus,
       _currentUser = currentUser,
       _extras = extras,
       _refresh = refresh,
       _now = now;

  static const String enrollmentNotYetSynced = 'ENROLLMENT_NOT_YET_SYNCED';

  @override
  String get aggregateType => LevelCorrectionWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final LevelCorrectionGesture? gesture;
    try {
      gesture = LevelCorrectionGesture.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (gesture == null) {
      return const OutboxDispatchResult.failed(
        'Correction de niveau incomplète',
      );
    }
    final hold =
        outboxForeignSchoolHold(entry, _currentUser.schoolId) ??
        OutboxDispatchResult.blockForeignAuthor(
          gesture.authorId,
          _currentUser.uid,
        );
    if (hold != null) return hold;

    // La ligne a disparu, ou le geste est déjà jugé : rien à envoyer.
    if (!await _sync.holds(gesture.id)) {
      return const OutboxDispatchResult.acked();
    }

    if (await _outbox.hasOlderPending(
      entryId: entry.id,
      aggregateId: gesture.enrollmentId,
      types: {aggregateType},
    )) {
      return const OutboxDispatchResult.blocked(
        'Un geste plus ancien de cet élève attend',
      );
    }
    final dependency = await _dependency(
      gesture.studentId,
      gesture.academicYearId,
    );
    if (dependency != OutboxDependencyState.ready) {
      return const OutboxDispatchResult.blocked(
        'Inscription pas encore accusée',
      );
    }

    try {
      await _api.push(_extras, gesture);
    } on DioException catch (e) {
      return _onFailure(gesture, OutboxPushFailure.of(e));
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }

    await _sync.markApplied(gesture.id, nowMs: _now());
    _bus.emit({gesture.enrollmentId});
    unawaited(_refresh().catchError((_) {}));
    return const OutboxDispatchResult.acked();
  }

  Future<OutboxDispatchResult> _onFailure(
    LevelCorrectionGesture gesture,
    OutboxPushFailure failure,
  ) async {
    if (failure.awaits(enrollmentNotYetSynced)) {
      return OutboxDispatchResult.blocked(failure.reason);
    }
    if (failure.isTransient) return OutboxDispatchResult.retry(failure.reason);
    if (failure.isGone) {
      await _sync.drop(gesture.id);
      _bus.emit({gesture.enrollmentId});
      return const OutboxDispatchResult.acked();
    }
    await _sync.markRefused(
      gesture.id,
      code: failure.storedCode,
      reason: failure.reason,
      nowMs: _now(),
    );
    _bus.emit({gesture.enrollmentId});
    return OutboxDispatchResult.failed(failure.reason);
  }
}
