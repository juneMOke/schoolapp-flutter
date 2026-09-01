import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';

/// Place le panneau sous le champ, ou au-dessus quand le bas de l'écran (ou le
/// clavier) ne laisse plus la place. La largeur suit celle du champ : un
/// panneau plus étroit que son déclencheur tronquerait des libellés que le
/// champ, lui, affichait en entier.
class EteeloSelectPopoverLayout extends SingleChildLayoutDelegate {
  final Rect anchorRect;
  final EdgeInsets viewInsets;

  /// Plafond imposé par l'appelant (`menuMaxHeight`). Il ne peut que RÉDUIRE
  /// la hauteur disponible : la place réelle sous le champ reste la contrainte
  /// qui gagne, sinon le panneau sortirait de l'écran.
  final double? maxHeight;

  const EteeloSelectPopoverLayout({
    required this.anchorRect,
    required this.viewInsets,
    this.maxHeight,
  });

  static const double _margin = EteeloSelectConstants.panelScreenMargin;
  static const double _gap = EteeloSelectConstants.panelAnchorGap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = constraints.biggest;
    final usableWidth = math.max(available.width - 2 * _margin, 0.0);
    final width = anchorRect.width
        .clamp(
          math.min(EteeloSelectConstants.panelMinWidth, usableWidth),
          math.max(usableWidth, 1.0),
        )
        .toDouble();

    final bottomLimit = available.height - viewInsets.bottom - _margin;
    final spaceBelow = bottomLimit - anchorRect.bottom - _gap;
    final spaceAbove = anchorRect.top - _gap - _margin;
    final ceiling = math.min(
      EteeloSelectConstants.panelMaxHeight,
      maxHeight ?? EteeloSelectConstants.panelMaxHeight,
    );
    final panelHeight = math.min(
      ceiling,
      math.max(
        math.max(spaceBelow, spaceAbove),
        EteeloSelectConstants.optionMinHeight,
      ),
    );

    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: panelHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bottomLimit = size.height - viewInsets.bottom - _margin;
    final fitsBelow =
        anchorRect.bottom + _gap + childSize.height <= bottomLimit;
    final dy = fitsBelow
        ? anchorRect.bottom + _gap
        : math.max(_margin, anchorRect.top - _gap - childSize.height);
    final dx = anchorRect.left
        .clamp(
          _margin,
          math.max(_margin, size.width - childSize.width - _margin),
        )
        .toDouble();
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(EteeloSelectPopoverLayout oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      viewInsets != oldDelegate.viewInsets ||
      maxHeight != oldDelegate.maxHeight;
}
