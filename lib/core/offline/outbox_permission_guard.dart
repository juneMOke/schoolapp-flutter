/// Garde de permission de la file d'écritures (ADR-014 §13.3, A1).
///
/// Un droit retiré ne doit plus détruire les écritures en attente. Deux
/// mécanismes, complémentaires :
///
/// 1. **La pré-garde** ([OutboxWriteAccess]) : quand l'ensemble de droits est
///    connu et ne contient pas celui qu'une entrée exige, le moteur la retient
///    sans appel réseau.
/// 2. **La sonde** ([OutboxPermissionProbe]) : le serveur recharge les droits à
///    chaque requête sans invalider le jeton. La première écriture partie après
///    un retrait prend donc un 403 **avant** que la tablette ne connaisse ses
///    nouveaux droits. La sonde observe ce 403 au niveau HTTP, pendant le
///    dispatch d'une entrée, et le moteur retient l'entrée au lieu de la
///    laisser passer en `SYNC_ERROR`.
///
/// Un refus de permission (`@PreAuthorize`) arrive **sans** `detailCode` ; un
/// refus métier (`MONTH_CLOSURE_FORBIDDEN`, `PAYROLL_GESTURE_FORBIDDEN`…) en
/// porte un, et reste terminal. Le refus d'auteur (`SyncAttributionGuard`) n'en
/// porte pas non plus, mais le moteur l'écarte avant tout envoi : s'il passait
/// quand même, l'entrée attendrait au lieu d'être perdue — l'erreur va du côté
/// où rien ne se détruit.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Motif posé sur une entrée retenue faute de droit. Il s'affiche tel quel dans
/// la feuille de synchronisation (`SyncHeldTile`), comme les autres retenues.
const String kOutboxAwaitingPermissionReason =
    'Droit retiré pour ce compte — l\'écriture est conservée et repartira '
    'quand le droit sera rétabli';

/// Un handler d'outbox qui déclare le droit qu'exige l'envoi d'une entrée.
///
/// Par entrée et non par type : un même type d'agrégat porte parfois des gestes
/// d'autorités différentes (approuver une dépense exige `expense.decide`, la
/// payer `expense.pay`). La valeur vient du registre de
/// `module_access_registry.dart`, la source qui masque aussi les boutons —
/// jamais une seconde politique.
abstract interface class OutboxWriteAccess {
  /// Le droit qu'exige l'envoi de [entry], ou `null` si l'entrée ne se garde
  /// pas (payload illisible : le handler le dira lui-même au dispatch).
  ModuleAccess? writeAccessFor(OutboxEntry entry);
}

/// La pré-garde refuse-t-elle [access] avec les droits [held] ?
///
/// **Ensemble inconnu (`null`) → jamais.** Comme le pull (ADR-014 §13.2) : la
/// synchronisation reste ouverte tant que les droits ne sont pas connus, le
/// serveur restant la seule frontière réelle — et la sonde rattrape son refus.
bool outboxWriteDenied(ModuleAccess? access, Iterable<String>? held) {
  if (access == null || held == null) return false;
  return !canAccess(
    requires: access.requires,
    permissions: held,
    requiresAll: access.requiresAll,
  );
}

/// [e] est-il un refus de **droit** — 403 sans `detailCode` ?
///
/// À tester par un handler **avant** d'appliquer un effet local de refus, pour
/// renvoyer `OutboxDispatchResult.permissionDenied()` à la place : la sonde du
/// moteur retient l'entrée, mais elle ne peut pas défaire ce que le handler a
/// déjà écrit en base.
bool isOutboxPermissionDenial(DioException e) =>
    OutboxPermissionProbe.isPermissionDenial(e.response);

/// Ce que la sonde a vu pendant le dispatch d'une entrée.
class OutboxPermissionProbe {
  static final Object _zoneKey = Object();

  bool _denied = false;

  /// Un 403 de permission a été reçu pendant le dispatch.
  bool get denied => _denied;

  /// Exécute [body] sous cette sonde. Les requêtes HTTP émises par [body], même
  /// après plusieurs `await`, héritent de la zone et y signalent leurs refus.
  Future<T> watch<T>(Future<T> Function() body) =>
      runZoned(body, zoneValues: {_zoneKey: this});

  /// Signale [response] à la sonde de la zone courante, s'il y en a une. Hors
  /// d'un dispatch d'outbox (pull, écran en ligne), ne fait rien.
  static void observe(Response<dynamic>? response) {
    final probe = Zone.current[_zoneKey];
    if (probe is OutboxPermissionProbe && isPermissionDenial(response)) {
      probe._denied = true;
    }
  }

  /// Un 403 sans `detailCode` : le serveur refuse le droit, pas le geste.
  static bool isPermissionDenial(Response<dynamic>? response) =>
      response?.statusCode == 403 &&
      ApiErrorParser.detailCodeOf(response) == null;
}

/// Branche [OutboxPermissionProbe] sur la chaîne Dio.
///
/// À poser **en tête** de la chaîne : les intercepteurs suivants peuvent
/// rejeter avec une autre erreur, et la sonde doit lire la réponse d'origine.
/// Ne modifie jamais la requête ni la réponse.
class OutboxPermissionProbeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Un client qui accepte tous les statuts reçoit le 403 en réponse.
    OutboxPermissionProbe.observe(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    OutboxPermissionProbe.observe(err.response);
    handler.next(err);
  }
}
