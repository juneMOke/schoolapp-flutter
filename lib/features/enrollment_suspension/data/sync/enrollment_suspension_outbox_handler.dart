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
import 'package:school_app_flutter/features/enrollment_suspension/data/enrollment_suspension_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_api.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_period_dto.dart';

/// Handler d'outbox de l'agrégat `ENROLLMENT_SUSPENSION` — désactiver ou
/// réactiver un élève.
///
/// **Ordre par inscription** : une réactivation n'a de sens qu'après la
/// désactivation qu'elle ferme ; un geste attend (`blocked`) tant qu'un geste
/// plus ancien de la même inscription est en file.
///
/// **Dépend de l'inscription** : tant que le dossier n'est pas accusé, le geste
/// attend — localement par la sonde, au serveur par le 409
/// `ENROLLMENT_NOT_YET_SYNCED`. Un 422 est terminal : l'effet local est
/// défait.
class EnrollmentSuspensionOutboxHandler implements OutboxSyncHandler {
  final EnrollmentSuspensionApi _api;
  final EnrollmentSuspensionSyncDao _sync;
  final OutboxDao _outbox;
  final OutboxDependencyGate _dependency;
  final EnrollmentSuspensionChangeBus _bus;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const EnrollmentSuspensionOutboxHandler({
    required EnrollmentSuspensionApi api,
    required EnrollmentSuspensionSyncDao sync,
    required OutboxDao outbox,
    required OutboxDependencyGate dependency,
    required EnrollmentSuspensionChangeBus bus,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _sync = sync,
       _outbox = outbox,
       _dependency = dependency,
       _bus = bus,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  static const String enrollmentNotYetSynced = 'ENROLLMENT_NOT_YET_SYNCED';

  @override
  String get aggregateType => EnrollmentSuspensionWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final SuspensionGesture? gesture;
    try {
      gesture = SuspensionGesture.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (gesture == null) {
      return const OutboxDispatchResult.failed(
        'Geste de désactivation incomplet',
      );
    }
    final hold =
        outboxForeignSchoolHold(entry, _currentUser.schoolId) ??
        OutboxDispatchResult.blockForeignAuthor(
          gesture.authorId,
          _currentUser.uid,
        );
    if (hold != null) return hold;

    // La ligne a disparu (tombe, période d'une autre tablette) : rien à dire.
    if (!await _sync.holds(gesture)) return const OutboxDispatchResult.acked();

    if (await _outbox.hasOlderPending(
      entryId: entry.id,
      aggregateId: gesture.enrollmentId,
      types: {aggregateType},
    )) {
      return const OutboxDispatchResult.blocked(
        'Un geste plus ancien de cet élève attend',
      );
    }
    // Un dossier refusé se corrige et repart : le geste l'attend aussi.
    final dependency = await _dependency(
      gesture.studentId,
      gesture.academicYearId,
    );
    if (dependency != OutboxDependencyState.ready) {
      return const OutboxDispatchResult.blocked(
        'Inscription pas encore accusée',
      );
    }

    final SuspensionGestureAckDto ack;
    try {
      ack = await _api.push(_extras, gesture);
    } on DioException catch (e) {
      return _onFailure(gesture, OutboxPushFailure.of(e));
    } on FormatException catch (e) {
      return OutboxDispatchResult.retry(e.message);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }

    await _sync.applyAck(
      gesture,
      ack,
      schoolId: entry.schoolId ?? _currentUser.schoolId ?? '',
      nowMs: _now(),
    );
    _bus.emit({gesture.enrollmentId});
    return const OutboxDispatchResult.acked();
  }

  Future<OutboxDispatchResult> _onFailure(
    SuspensionGesture gesture,
    OutboxPushFailure failure,
  ) async {
    if (failure.awaits(enrollmentNotYetSynced)) {
      return OutboxDispatchResult.blocked(failure.reason);
    }
    if (failure.isTransient) return OutboxDispatchResult.retry(failure.reason);
    await _sync.undoRefused(
      gesture,
      code: failure.storedCode,
      reason: failure.reason,
      nowMs: _now(),
    );
    _bus.emit({gesture.enrollmentId});
    // L'inscription purgée au serveur : le geste n'a plus d'objet.
    if (failure.isGone) return const OutboxDispatchResult.acked();
    return OutboxDispatchResult.failed(failure.reason);
  }
}
