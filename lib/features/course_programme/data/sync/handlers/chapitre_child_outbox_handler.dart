import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_failure.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';

/// Ce qu'un geste sur un enfant du chapitre (note, ressource) a besoin de
/// savoir de son payload.
class ChildGesture {
  final ProgrammePushOp op;
  final String id;
  final String chapitreId;

  const ChildGesture({
    required this.op,
    required this.id,
    required this.chapitreId,
  });
}

/// Le déroulé commun des gestes sur un enfant de chapitre :
///
/// 1. chapitre parti de la tablette : le geste n'a plus d'objet (`acked`) ;
/// 2. ajout dont le chapitre n'est pas encore connu du serveur : il l'attend
///    (`blocked`), sans réseau — le 409 `CHAPITRE_NOT_YET_SYNCED` n'est que le
///    filet d'une course ;
/// 3. accusé : ajout synchronisé, retrait effacé ;
/// 4. 403 `COURS_NOT_OWNED` : le cours quitte la tablette ; objet disparu
///    côté serveur : la ligne part ; refus d'un ajout : « à corriger ».
abstract class ChapitreChildOutboxHandler<P> implements OutboxSyncHandler {
  final ProgrammeSyncDao dao;
  final CoursEvictor _evictCours;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> extras;
  final Clock now;

  ChapitreChildOutboxHandler({
    required this.dao,
    required CoursEvictor evictCours,
    required CurrentUserContext currentUser,
    required this.extras,
    this.now = systemClock,
  }) : _evictCours = evictCours,
       _currentUser = currentUser;

  /// La table locale de l'enfant.
  String get table;

  P? parse(Object? json);

  ChildGesture gestureOf(P payload);

  /// Envoie l'ajout ; rend un échec local terminal à ranger, ou `null`.
  /// [entry] porte l'auteur à recopier dans le corps ([withOutboxAuthor]).
  Future<OutboxDispatchResult?> sendSave(P payload, OutboxEntry entry);

  Future<void> sendDelete(P payload, OutboxEntry entry);

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final P? payload;
    try {
      payload = parse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (payload == null) {
      return const OutboxDispatchResult.failed('Payload incomplet');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    final gesture = gestureOf(payload);
    final state = await dao.chapitreState(gesture.chapitreId);
    if (state == ChapitreServerState.gone) {
      return const OutboxDispatchResult.acked();
    }
    final saving = gesture.op == ProgrammePushOp.save;
    if (state == ChapitreServerState.unknown) {
      // Un ajout attend son chapitre ; un retrait n'a rien à retirer : tant
      // que le chapitre est inconnu, aucun ajout n'a pu partir.
      return saving
          ? const OutboxDispatchResult.blocked('Chapitre pas encore accusé')
          : const OutboxDispatchResult.acked();
    }

    try {
      if (saving) {
        final local = await sendSave(payload, entry);
        if (local != null) return local;
        await dao.markChildSynced(table, gesture.id, now());
      } else {
        await sendDelete(payload, entry);
        await dao.removeChild(table, gesture.id);
      }
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _onFailure(gesture, ProgrammePushFailure.of(e));
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<OutboxDispatchResult> _onFailure(
    ChildGesture gesture,
    ProgrammePushFailure failure,
  ) async {
    if (failure.coursNotOwned) {
      final coursId = await dao.coursOf(gesture.chapitreId);
      if (coursId != null) await _evictCours(coursId);
      return const OutboxDispatchResult.acked();
    }
    if (failure.awaitsChapitre) {
      return OutboxDispatchResult.blocked(failure.reason);
    }
    final saving = gesture.op == ProgrammePushOp.save;
    if (saving ? failure.isGone : failure.isGoneForDelete) {
      // Retrait : déjà fait. Ajout : son chapitre a été supprimé ailleurs.
      await dao.removeChild(table, gesture.id);
      return const OutboxDispatchResult.acked();
    }
    if (failure.isTransient) return OutboxDispatchResult.retry(failure.reason);
    if (saving) {
      await dao.markChildRejected(table, gesture.id, failure.storedCode, now());
    } else {
      await dao.restoreChild(table, gesture.id, failure.storedCode, now());
    }
    return OutboxDispatchResult.failed(failure.reason);
  }
}
