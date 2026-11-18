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
/// **Ce qui est un refus de droit.** Un 403 au corps `code: FORBIDDEN`, et :
/// - sans `detailCode` : `@RequiresPermission` sur la route, ou un contrôle de
///   droit écrit dans le code (corriger un appel passé, remplacer un
///   versement) ;
/// - ou avec l'un des codes de [kOutboxPermissionRefusalCodes] : des contrôles
///   de droit que le serveur nomme (clore le mois du pointage, valider la paie,
///   déposer une avance).
///
/// Tout autre 403 porteur d'un code est un refus métier, et reste terminal.
/// Un 403 sans corps `FORBIDDEN` (page d'un proxy) n'est pas un refus de droit.
///
/// **Le refus d'auteur.** `SyncAttributionGuard` répond lui aussi 403 sans
/// `detailCode`. Le moteur écarte l'écriture d'un autre compte avant l'envoi,
/// mais une entrée **sans auteur**, ou un porteur sans `uid`, partent quand même
/// pour obtenir un refus visible (`outbox_author.dart`). Pour elles, le refus
/// n'est jamais lu comme un droit retiré : la sonde du dispatch est montée
/// « non attribuée », et [isOutboxPermissionDenial] rend `false` — sans quoi
/// l'entrée serait retenue pour toujours, sans personne pour la réclamer.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Motif posé sur une entrée retenue faute de droit. C'est un **code** : la
/// feuille de synchronisation (`SyncHeldTile`) l'affiche traduit, et la file le
/// reconnaît (`OutboxDao.wakePermissionHolds`, `hasOlderPending`).
const String kOutboxAwaitingPermissionReason = 'AWAITING_PERMISSION';

/// Codes de refus que le serveur pose sur un contrôle de **droit** fait dans
/// son code, et non sur la route. Recopiés du back (`HrErrorCodes`,
/// `PayrollErrorCodes`, `ExpenseErrorCodes`) : un code ajouté là-bas sans être
/// recopié ici redevient terminal.
const Set<String> kOutboxPermissionRefusalCodes = {
  // hr.attendance.manage pour clore le mois du pointage.
  'MONTH_CLOSURE_FORBIDDEN',
  // hr.attendance.reopen pour le rouvrir.
  'MONTH_REOPEN_FORBIDDEN',
  // hr.pay.manage pour valider, renvoyer ou rouvrir la paie.
  'PAYROLL_GESTURE_FORBIDDEN',
  // hr.pay.read pour déposer ou corriger une avance au personnel.
  'STAFF_ADVANCE_FORBIDDEN',
};

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

/// [e] est-il un refus de **droit** (voir l'en-tête du fichier) ?
///
/// À tester par un handler **avant** d'appliquer un effet local de refus, pour
/// renvoyer `OutboxDispatchResult.permissionDenied()` à la place : la sonde du
/// moteur retient l'entrée, mais elle ne peut pas défaire ce que le handler a
/// déjà écrit en base.
///
/// Dans le dispatch d'une entrée non attribuée, rend toujours `false` : le
/// refus peut être celui de l'auteur, et le handler garde son ancien sort.
bool isOutboxPermissionDenial(DioException e) {
  final probe = Zone.current[OutboxPermissionProbe._zoneKey];
  if (probe is OutboxPermissionProbe && !probe.attributed) return false;
  return OutboxPermissionProbe.isPermissionDenial(e.response);
}

/// Ce que la sonde a vu pendant le dispatch d'une entrée.
class OutboxPermissionProbe {
  static final Object _zoneKey = Object();

  /// L'entrée appartient au porteur courant. Faux : sans auteur, ou porteur
  /// sans `uid` — un 403 peut alors venir de `SyncAttributionGuard`.
  final bool attributed;

  OutboxPermissionProbe({this.attributed = true});

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
    if (probe is OutboxPermissionProbe &&
        probe.attributed &&
        isPermissionDenial(response)) {
      probe._denied = true;
    }
  }

  /// Le serveur refuse le droit, pas le geste (voir l'en-tête du fichier).
  static bool isPermissionDenial(Response<dynamic>? response) {
    if (response?.statusCode != 403) return false;
    if (ApiErrorParser.codeOf(response) != ApiErrorCode.forbidden) return false;
    final detailCode = ApiErrorParser.detailCodeOf(response);
    return detailCode == null ||
        kOutboxPermissionRefusalCodes.contains(detailCode);
  }
}

/// Branche [OutboxPermissionProbe] sur la chaîne Dio.
///
/// À poser **après** `AuthRefreshInterceptor` (il transmet par `next` l'échec
/// d'un rejeu après 401) et **avant** le mapping d'erreurs, qui remplace la
/// réponse d'origine. Ne modifie jamais la requête ni la réponse.
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
