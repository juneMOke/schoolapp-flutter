import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Glisser au doigt pour passer à la journée (ou la période) voisine :
/// vers la gauche, la suivante ; vers la droite, la précédente. Les flèches
/// ‹ › restent le geste de la souris et du clavier.
///
/// La souris n'y est pas : glisser dessus sélectionne du texte.
class TreasurySwipeNav extends StatelessWidget {
  /// La journée (ou période) précédente, puis la suivante ; `null` à la
  /// borne.
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Widget child;

  const TreasurySwipeNav({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  void _ended(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < AppDimensions.treasurySwipeMinVelocity) return;
    (velocity < 0 ? onNext : onPrevious)?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus},
    behavior: HitTestBehavior.translucent,
    onHorizontalDragEnd: _ended,
    child: child,
  );
}
