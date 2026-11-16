import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Passer à la journée (ou la période) voisine sans viser les flèches ‹ › :
///
/// - au doigt, glisser : vers la gauche, la suivante ; vers la droite, la
///   précédente. La souris n'y est pas — glisser dessus sélectionne du texte ;
/// - au clavier, ← et → (pas pendant une saisie : la flèche y déplace le
///   curseur). Un bouton au focus du clavier ne fait pas bouger le focus en
///   même temps : la flèche est prise par l'écran et s'arrête là.
class TreasuryStepGestures extends StatelessWidget {
  /// La journée (ou période) précédente, puis la suivante ; `null` à la
  /// borne.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget child;

  const TreasuryStepGestures({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  /// La route seule a le focus (rien dans l'écran) : la touche est prise au
  /// clavier matériel. Sinon le nœud de l'écran la reçoit en remontant.
  static bool get _routeFocused {
    final focus = FocusManager.instance.primaryFocus;
    return focus == null || focus is FocusScopeNode;
  }

  /// ← → depuis l'intérieur de l'écran (un bouton au focus du clavier) :
  /// pris ici et arrêtés, ils ne déplacent pas le focus en plus.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (isEditingText) return KeyEventResult.ignored;
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => onPrevious,
      LogicalKeyboardKey.arrowRight => onNext,
      _ => null,
    };
    if (step == null) return KeyEventResult.ignored;
    step();
    return KeyEventResult.handled;
  }

  void _ended(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < AppDimensions.treasurySwipeMinVelocity) return;
    (velocity < 0 ? onNext : onPrevious)?.call();
  }

  @override
  Widget build(BuildContext context) => RouteKeyShortcut(
    activators: const [SingleActivator(LogicalKeyboardKey.arrowLeft)],
    ignoreWhileTyping: true,
    isEnabled: () => onPrevious != null && _routeFocused,
    onPressed: () => onPrevious?.call(),
    child: RouteKeyShortcut(
      activators: const [SingleActivator(LogicalKeyboardKey.arrowRight)],
      ignoreWhileTyping: true,
      isEnabled: () => onNext != null && _routeFocused,
      onPressed: () => onNext?.call(),
      child: Focus(
        // L'écran prend le focus à l'ouverture : les flèches lui arrivent
        // sans passer par le déplacement de focus de l'application.
        autofocus: true,
        canRequestFocus: true,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          supportedDevices: const {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
          },
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _ended,
          child: child,
        ),
      ),
    ),
  );
}
