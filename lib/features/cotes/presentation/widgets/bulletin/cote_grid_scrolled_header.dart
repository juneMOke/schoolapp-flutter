import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Les titres des notes quand elles défilent : décalés comme les notes, entre
/// les mêmes filets.
class CoteGridScrolledHeader extends StatelessWidget {
  /// La largeur de toutes les notes, celle du défileur.
  final double width;
  final ScrollController horizontal;
  final Widget child;

  const CoteGridScrolledHeader({
    super.key,
    required this.width,
    required this.horizontal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(color: AppColors.borderStrong),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: width,
          maxWidth: width,
          child: Flow(delegate: _FollowNotes(horizontal), children: [child]),
        ),
      ),
    );
  }
}

/// Le décalage se lit à la peinture, après la mise en page du défileur :
/// plus large, il ramène son décalage sans prévenir, et une lecture faite à
/// la construction gardait l'ancien.
class _FollowNotes extends FlowDelegate {
  final ScrollController horizontal;

  _FollowNotes(this.horizontal) : super(repaint: horizontal);

  @override
  void paintChildren(FlowPaintingContext context) {
    final dx = horizontal.hasClients ? -horizontal.offset : 0.0;
    context.paintChild(0, transform: Matrix4.translationValues(dx, 0, 0));
  }

  // Chaque reconstruction (largeur, forme de la grille) repeint : le
  // décalage a pu changer sans notification.
  @override
  bool shouldRepaint(_FollowNotes oldDelegate) => true;
}
