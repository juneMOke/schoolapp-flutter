import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Agrandit la zone d'appui de [child] à [AppDimensions.minTouchTarget]
/// (48 dp) sans changer ce qu'on voit : le visuel reste centré à sa taille.
///
/// À poser SOUS le détecteur (`InkWell`, `PopupMenuButton`…) : c'est la boîte
/// qu'il enveloppe qui fixe la surface touchable.
class TouchTarget extends StatelessWidget {
  final Widget child;

  const TouchTarget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.minTouchTarget,
        minHeight: AppDimensions.minTouchTarget,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
