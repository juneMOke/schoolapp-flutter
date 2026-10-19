import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/web/unload_guard.dart';

/// Protège une page de saisie contre les sorties qui ne passent pas par ses
/// boutons : **Précédent / Suivant du navigateur**, un lien, une adresse
/// tapée — et, sur le web, la fermeture ou le rechargement de l'onglet.
///
/// Sur le web, Précédent ne « dépile » pas : il change l'adresse, et GoRouter
/// remplace les pages sans consulter `PopScope`. Seul [GoRoute.onExit] est
/// consulté ; la route protégée déclare donc `onExit: RouteExitGuard.onExit`,
/// et la page répond par ce widget :
///
/// - [isBusy] : une écriture est en vol — on reste, sans question (quitter
///   au milieu d'un encaissement laisserait un geste à l'issue inconnue) ;
/// - [hasUnsavedWork] : une saisie serait perdue — [confirmExit] demande ;
/// - sinon la sortie est libre.
///
/// Les sorties décidées par la page elle-même (succès, sortie déjà confirmée)
/// appellent d'abord [release] : sans cela, `pop` consulterait aussi
/// `onExit` et la question serait posée deux fois.
class RouteExitGuard extends StatefulWidget {
  final bool Function() isBusy;
  final bool Function() hasUnsavedWork;
  final Future<bool> Function() confirmExit;
  final Widget child;

  const RouteExitGuard({
    super.key,
    this.isBusy = _never,
    required this.hasUnsavedWork,
    required this.confirmExit,
    required this.child,
  });

  static bool _never() => false;

  /// Les gardes montées, la plus récente en dernier : la page du dessus est
  /// celle qu'on quitte en premier.
  static final List<_RouteExitGuardState> _mounted = [];

  /// À poser sur la [GoRoute] de la page protégée.
  ///
  /// Consulte les gardes que cette sortie emporte : celle de la page quittée
  /// ([GoRouterState.pageKey]) et celles des pages poussées par-dessus sans
  /// route (`Navigator.push` : fiche d'un agent, puis son contrat). La plus
  /// haute qui a une saisie pose la question ; une réponse vaut pour toutes.
  static FutureOr<bool> onExit(BuildContext context, GoRouterState state) {
    final guards = [
      for (final guard in _mounted.reversed)
        if (!guard._released && guard._leftWith(state.pageKey)) guard,
    ];
    if (guards.isEmpty) return true;
    if (guards.any((guard) => guard.widget.isBusy())) return false;
    // Un rafraîchissement du routeur n'est pas une sortie demandée : il
    // recrée la page empilée (go_router #128122), ou applique une redirection
    // qui fait autorité (déconnexion, droit retiré). Aucune question.
    if (_routerRefreshing) return true;
    final dirty = guards.where((guard) => guard.widget.hasUnsavedWork());
    if (dirty.isEmpty) return _leave(guards);
    return dirty.first._confirm().then(
      (leave) => leave ? _leave(guards) : false,
    );
  }

  /// Sortie accordée : les gardes se lèvent, et les pages sans route se
  /// referment — sans quoi elles resteraient affichées au-dessus d'une
  /// coquille dont l'adresse a changé.
  static bool _leave(List<_RouteExitGuardState> guards) {
    for (final guard in guards) {
      guard
        .._release()
        .._closeIfPageless();
    }
    return true;
  }

  static bool _routerRefreshing = false;

  /// Notifie le routeur ([notify]) en signalant aux gardes que les sorties
  /// qui suivent viennent de ce rafraîchissement, jusqu'à l'image suivante.
  static void duringRouterRefresh(VoidCallback notify) {
    _routerRefreshing = true;
    try {
      notify();
    } finally {
      SchedulerBinding.instance
        ..addPostFrameCallback((_) => _routerRefreshing = false)
        ..ensureVisualUpdate();
    }
  }

  /// La page part d'elle-même : la prochaine sortie passe sans question.
  ///
  /// Appelé sous la garde, c'est elle qui est levée ; appelé depuis la page
  /// qui la construit (au-dessus d'elle), c'est la garde du dessus — celle de
  /// la page qu'on quitte.
  static void release(BuildContext context) =>
      (context.findAncestorStateOfType<_RouteExitGuardState>() ??
              _mounted.lastOrNull)
          ?._release();

  @override
  State<RouteExitGuard> createState() => _RouteExitGuardState();
}

class _RouteExitGuardState extends State<RouteExitGuard> {
  bool _released = false;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    RouteExitGuard._mounted.add(this);
  }

  @override
  void dispose() {
    RouteExitGuard._mounted.remove(this);
    setUnloadGuard(false, source: this);
    super.dispose();
  }

  void _release() {
    _released = true;
    setUnloadGuard(false, source: this);
  }

  /// La page de cette garde part avec la page [pageKey] : c'est elle, ou
  /// une page sans route poussée au-dessus.
  bool _leftWith(ValueKey<String> pageKey) {
    final settings = ModalRoute.of(context)?.settings;
    return settings is! Page || settings.key == pageKey;
  }

  /// Une question à la fois : Précédent tapé deux fois ne superpose pas deux
  /// popins.
  Future<bool> _confirm() async {
    if (_asking) return false;
    _asking = true;
    try {
      return await widget.confirmExit();
    } finally {
      _asking = false;
    }
  }

  void _closeIfPageless() {
    final route = ModalRoute.of(context);
    if (route == null || route.settings is Page || !route.isActive) return;
    route.navigator?.removeRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    // Relu à chaque rendu de la page : c'est elle qui se reconstruit quand la
    // saisie change.
    setUnloadGuard(
      !_released && (widget.isBusy() || widget.hasUnsavedWork()),
      source: this,
    );
    return widget.child;
  }
}
