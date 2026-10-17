import 'package:flutter/widgets.dart';

/// Un tableau ne s'écrase pas : sous [minWidth], il garde cette largeur et
/// défile horizontalement (la barre de défilement est celle du thème sur
/// bureau et navigateur, le doigt sur la tablette). Au-delà, il prend toute
/// la largeur reçue.
///
/// Le [child] doit tenir dans une largeur bornée — ses `Expanded` se
/// partagent alors [minWidth] au lieu de colonnes de quelques dp.
class EteeloMinWidthScroll extends StatelessWidget {
  final double minWidth;
  final Widget child;

  const EteeloMinWidthScroll({
    super.key,
    required this.minWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= minWidth) return child;
      final sized = SizedBox(width: minWidth, child: child);
      // Déjà dans un défilement horizontal : la largeur suffit.
      if (!constraints.hasBoundedWidth) return sized;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: sized,
      );
    },
  );
}
