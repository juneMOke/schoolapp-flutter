import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Le contenu d'une page, centré en haut et plafonné à [maxWidth] : sur un
/// écran large, les lignes ne s'étirent pas jusqu'aux bords.
///
/// [heightFactor] à 1 quand le parent impose une contrainte lâche de toute la
/// hauteur (barre du bas) : le bloc garde alors sa hauteur propre.
class ContentMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double? heightFactor;

  const ContentMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = AppDimensions.detailContentMaxWidth,
    this.heightFactor,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: heightFactor,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
