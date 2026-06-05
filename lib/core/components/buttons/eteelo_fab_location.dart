import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Variante de [FloatingActionButtonLocation.endFloat] avec marge configurable.
///
/// Le calcul de base est delegue a `endFloat` pour conserver le comportement
/// Flutter (safe areas, snackbars, bottom sheets), puis un ajustement est
/// applique pour respecter une marge de bord differente.
class EndFloatEdgeOffsetFabLocation extends FloatingActionButtonLocation {
  static const double _defaultEndFloatMargin = 16.0;

  final double edgeOffset;

  const EndFloatEdgeOffsetFabLocation({
    this.edgeOffset = AppDimensions.fabEdgeOffset,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base = FloatingActionButtonLocation.endFloat.getOffset(
      scaffoldGeometry,
    );
    final delta = edgeOffset - _defaultEndFloatMargin;
    if (delta == 0) {
      return base;
    }

    final isLtr = scaffoldGeometry.textDirection == TextDirection.ltr;
    final dx = isLtr ? -delta : delta;
    final dy = -delta;
    return Offset(base.dx + dx, base.dy + dy);
  }
}
