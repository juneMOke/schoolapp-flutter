import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/device/desktop_platform.dart';

/// Le dernier pointeur dont s'est servi l'utilisateur : la souris, ou le doigt
/// (ou le stylet).
///
/// Une consigne qui dit « cliquez » ou « touchez » suit la main réelle, pas
/// la plateforme : un PC tactile, un iPad au trackpad ou la version web
/// ouverte sur un téléphone démentent `kIsWeb` comme
/// `defaultTargetPlatform`. Avant tout geste, la plateforme tranche
/// ([expectsPhysicalKeyboard]).
///
/// Posé une fois sous `MaterialApp` ; sans lui (tests d'écran), la plateforme
/// seule répond.
class PointerKindScope extends StatefulWidget {
  final Widget child;

  const PointerKindScope({super.key, required this.child});

  /// Vrai quand la dernière main était une souris. Le widget qui le lit se
  /// reconstruit quand la main change.
  static bool usesMouseOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PointerKindInherited>();
    final kind = scope?.kind;
    if (kind == null) return expectsPhysicalKeyboard;
    return kind == PointerDeviceKind.mouse;
  }

  /// La même réponse, sans abonnement : pour un geste qui ouvre quelque
  /// chose (un sélecteur de date) et lit la main à cet instant. Elle lit
  /// l'état lui-même : l'appui qui ouvre le sélecteur vient de changer la
  /// main, et le widget hérité ne la portera qu'au prochain frame.
  static bool usesMouseNow(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<_PointerKindInherited>();
    final kind = scope?.state._kind;
    if (kind == null) return expectsPhysicalKeyboard;
    return kind == PointerDeviceKind.mouse;
  }

  @override
  State<PointerKindScope> createState() => _PointerKindScopeState();
}

class _PointerKindScopeState extends State<PointerKindScope> {
  PointerDeviceKind? _kind;

  void _seen(PointerEvent event) {
    // Le trackpad n'émet ici que ses gestes de défilement : il ne dit rien
    // de la main qui appuie (un clic du trackpad arrive en souris).
    final kind = switch (event.kind) {
      PointerDeviceKind.mouse => PointerDeviceKind.mouse,
      PointerDeviceKind.touch ||
      PointerDeviceKind.stylus ||
      PointerDeviceKind.invertedStylus => PointerDeviceKind.touch,
      PointerDeviceKind.trackpad || PointerDeviceKind.unknown => null,
    };
    if (kind == null || kind == _kind) return;
    setState(() => _kind = kind);
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _seen,
    // Une souris se signale avant de cliquer : la consigne est juste dès le
    // premier survol.
    onPointerHover: _seen,
    child: _PointerKindInherited(state: this, kind: _kind, child: widget.child),
  );
}

class _PointerKindInherited extends InheritedWidget {
  final _PointerKindScopeState state;
  final PointerDeviceKind? kind;

  const _PointerKindInherited({
    required this.state,
    required this.kind,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PointerKindInherited oldWidget) =>
      kind != oldWidget.kind;
}
