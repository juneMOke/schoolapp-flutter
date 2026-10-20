import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Grand écran : la liste à gauche, la fiche choisie à droite, chacune son
/// défilement — passer d'un élément au suivant ne fait plus d'aller-retour de
/// page, et la liste garde sa position.
///
/// La page décide quand la largeur le permet (elle mesure ce qu'elle reçoit)
/// et pousse la fiche en page entière en deçà.
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget detail;

  /// Largeur de la colonne de liste ; la fiche prend le reste.
  final double masterWidth;

  /// Referme la fiche ouverte — Échap, comme au bureau. `null` quand rien
  /// n'est ouvert.
  final VoidCallback? onCloseDetail;

  const MasterDetailLayout({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth = AppDimensions.masterListWidth,
    this.onCloseDetail,
  });

  @override
  Widget build(BuildContext context) {
    final close = onCloseDetail;
    final row = _row();
    if (close == null) return row;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: row,
    );
  }

  Widget _row() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: masterWidth,
          child: SingleChildScrollView(child: master),
        ),
        const SizedBox(width: AppDimensions.spacingL),
        Expanded(child: detail),
      ],
    );
  }
}
