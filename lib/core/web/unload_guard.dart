import 'package:school_app_flutter/core/web/unload_guard_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/unload_guard_web.dart'
    as impl;

/// Les raisons actives de retenir l'onglet, une par demandeur.
final Set<Object> _sources = {};

/// Fait demander confirmation au navigateur avant de fermer ou de recharger
/// l'onglet, tant qu'au moins un demandeur l'exige : un envoi qui attend dans
/// l'outbox, une saisie qui n'est pas enregistrée. No-op hors du web (cf.
/// import conditionnel).
///
/// [source] distingue les demandeurs : l'outbox qui se vide ne doit pas lever
/// la garde d'un formulaire encore ouvert.
void setUnloadGuard(bool active, {Object source = _outbox}) {
  final changed = active ? _sources.add(source) : _sources.remove(source);
  if (changed) impl.setUnloadGuard(_sources.isNotEmpty);
}

const Object _outbox = Object();
