import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_closure_models.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart'
    show kAttendanceAggregateType;

/// Type d'agrégat d'outbox d'une clôture de mois de l'appel.
const String kAttendanceClosureAggregateType = 'ATTENDANCE_CLOSURE';

/// Pousse la clôture d'un mois (`POST /sync/attendance-closures`).
///
/// **Ordre.** Une clôture attend les appels mis en file AVANT elle : partie
/// la première, elle ferait refuser ces appels en `MONTH_CLOSED` — des
/// journées entières perdues pour un ordre d'envoi. Elle n'attend jamais un
/// appel plus récent (la file ne peut donc pas s'interbloquer), et un appel
/// refusé ne la retient plus.
///
/// - 200 (rejeu, mois déjà clos ailleurs compris) → la clôture du serveur ;
/// - 422 (`MONTH_NOT_ENDED`, `MONTH_OUTSIDE_ACADEMIC_YEAR`…) → refus définitif,
///   le mois n'est plus figé et la raison s'affiche ;
/// - 403 → attente propre si le geste est d'un autre compte, refus sinon ;
/// - réseau, 5xx, 401 → nouvel essai.
class AttendanceClosureOutboxHandler implements OutboxSyncHandler {
  final AttendanceClosureApi api;
  final AttendanceClosureLocalDataSource closures;
  final OutboxDao outbox;
  final Map<String, dynamic> requiredAuth;
  final CurrentUserContext? currentUser;

  const AttendanceClosureOutboxHandler({
    required this.api,
    required this.closures,
    required this.outbox,
    required this.requiredAuth,
    this.currentUser,
  });

  @override
  String get aggregateType => kAttendanceClosureAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    late final AttendanceClosureRequestModel closure;
    try {
      closure = AttendanceClosureRequestModel.fromJsonString(entry.payload);
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid closure payload');
    }
    if (closure.authorId == null) {
      return _refuse(
        closure,
        'Clôture enregistrée sans auteur connu : reconnectez-vous, puis '
        'clôturez le mois à nouveau.',
      );
    }
    if (await outbox.hasOlderPending(
      entryId: entry.id,
      aggregateId: null,
      types: const {kAttendanceAggregateType},
    )) {
      return const OutboxDispatchResult.blocked(
        'Clôture en attente : des appels saisis avant elle partent d\'abord.',
      );
    }
    try {
      final response = await api.submitClosure(requiredAuth, closure);
      await closures.applyAck(closure.gestureId, response);
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) {
        final uid = currentUser?.uid;
        if (uid != null && closure.authorId != uid) {
          return const OutboxDispatchResult.blocked(
            'Saisie d\'un autre utilisateur — repartira à sa reconnexion',
          );
        }
        return _refuse(closure, _reason(e) ?? 'Clôture non autorisée.');
      }
      final failure = e.error;
      if (failure is ValidationFailure || failure is NotFoundFailure) {
        return _refuse(closure, _reason(e) ?? 'Clôture refusée.');
      }
      return OutboxDispatchResult.retry(
        failure is Failure ? failure.message : e.message,
      );
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<OutboxDispatchResult> _refuse(
    AttendanceClosureRequestModel closure,
    String reason,
  ) async {
    await closures.markRefused(closure.gestureId, reason);
    return OutboxDispatchResult.failed(reason);
  }

  /// La raison du refus, dite en clair pour les codes du contrat.
  static String? _reason(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return null;
    final code = data['detailCode'] ?? data['code'];
    return switch (code) {
      'MONTH_NOT_ENDED' =>
        'Le mois n\'est pas terminé : il se clôture une fois fini.',
      'MONTH_OUTSIDE_ACADEMIC_YEAR' => 'Ce mois est hors de l\'année scolaire.',
      _ => data['message'] is String ? data['message'] as String : null,
    };
  }
}
