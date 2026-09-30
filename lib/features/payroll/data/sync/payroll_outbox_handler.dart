import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_gate.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_outbox_dispatch.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';

/// Le squelette des envois de la paie : relire la requête figée, attendre ce
/// qui doit partir avant elle, pousser, et ranger l'issue. Chaque handler
/// n'écrit que sa requête, sa garde, son accusé et son refus.
abstract class PayrollOutboxHandler<R> implements OutboxSyncHandler {
  final OutboxDao _outbox;
  final CurrentUserContext _currentUser;

  /// La fiche d'agent dont dépend l'envoi ; `null` : aucune garde.
  final StaffMemberGate? _members;

  /// Les options Dio de la requête (auth exigée).
  final Map<String, dynamic> extras;

  PayrollOutboxHandler({
    required OutboxDao outbox,
    required CurrentUserContext currentUser,
    required this.extras,
    StaffMemberGate? members,
  }) : _outbox = outbox,
       _currentUser = currentUser,
       _members = members;

  /// L'agent dont la fiche doit être au serveur avant cet envoi ; `null` :
  /// l'envoi ne dépend d'aucune fiche.
  String? staffMemberOf(R request) => null;

  /// La requête figée, ou `null` : illisible, elle ne se répare pas en la
  /// rejouant.
  R? parse(Object? raw);

  /// Les types d'entrées plus anciennes, du même agrégat, que celle-ci doit
  /// laisser partir d'abord. Vide : aucune.
  Set<String> get waitsFor => const {};

  /// Les types d'entrées plus anciennes, **de tout agrégat**, que [request]
  /// doit laisser partir d'abord. Vide : aucune.
  Set<String> waitsForAnyOf(R request) => const {};

  /// Une garde propre au handler, après celle de l'ordre ; `null` = partir.
  Future<OutboxDispatchResult?> hold(R request, String schoolId) async => null;

  Future<void> send(R request, String schoolId);

  /// Range le refus ; rend `false` quand une saisie plus récente l'a remplacé
  /// (l'entrée repart alors avec elle).
  Future<bool> reject(R request, StaffPushFailure failure, String schoolId);

  /// Une fiche parente jamais accusée : l'envoi attend ; refusée, il échoue à
  /// son tour, en la nommant — un fait d'argent part alors « à régulariser ».
  Future<OutboxDispatchResult?> _parentHold(R request, String schoolId) async {
    final memberId = staffMemberOf(request);
    final members = _members;
    if (memberId == null || members == null) return null;
    final parent = await members.of(memberId);
    switch (parent.state) {
      case StaffParentState.unsent:
        return const OutboxDispatchResult.blocked('Fiche pas encore accusée');
      case StaffParentState.refused:
        final reason =
            'Fiche de ${parent.name ?? memberId} refusée : '
            'elle n\'arrivera jamais au serveur';
        await reject(
          request,
          StaffPushFailure.local(StaffMemberGate.parentRefusedCode, reason),
          schoolId,
        );
        return OutboxDispatchResult.failed(reason);
      case StaffParentState.missing:
      case StaffParentState.acknowledged:
        return null;
    }
  }

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final request = StaffOutboxDispatch.decode(entry.payload, parse);
    if (request == null) {
      return OutboxDispatchResult.failed('Payload $aggregateType illisible');
    }
    final foreign = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (foreign != null) return foreign;
    final schoolId = entry.schoolId ?? _currentUser.schoolId ?? '';
    final parent = await _parentHold(request, schoolId);
    if (parent != null) return parent;
    if (waitsFor.isNotEmpty &&
        await _outbox.hasOlderPending(
          entryId: entry.id,
          aggregateId: entry.aggregateId,
          types: waitsFor,
        )) {
      return const OutboxDispatchResult.blocked(
        'Une écriture plus ancienne de la paie attend',
      );
    }
    if (await _outbox.hasOlderPending(
      entryId: entry.id,
      aggregateId: null,
      types: waitsForAnyOf(request),
    )) {
      return const OutboxDispatchResult.blocked(
        'Une écriture dont dépend le calcul attend',
      );
    }
    final held = await hold(request, schoolId);
    if (held != null) return held;
    return StaffOutboxDispatch.push(
      send: () => send(request, schoolId),
      reject: (failure) => reject(request, failure, schoolId),
    );
  }
}
