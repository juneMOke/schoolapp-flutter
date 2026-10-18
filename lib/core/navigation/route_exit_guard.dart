import 'dart:async';

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
  static FutureOr<bool> onExit(BuildContext context, GoRouterState state) =>
      _mounted.isEmpty ? true : _mounted.last._decide();

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

  Future<bool> _decide() async {
    if (_released) return true;
    if (widget.isBusy()) return false;
    if (!widget.hasUnsavedWork()) return true;
    // Une question à la fois : Précédent tapé deux fois ne superpose pas
    // deux popins.
    if (_asking) return false;
    _asking = true;
    try {
      final leave = await widget.confirmExit();
      if (leave) _release();
      return leave;
    } finally {
      _asking = false;
    }
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
