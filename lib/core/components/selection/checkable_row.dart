import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Une ligne qu'on coche au doigt : la case ET son libellé répondent à
/// l'appui. Au guichet, la case seule (20 à 24 dp) se visait à l'ongle.
///
/// La case garde son propre geste ; le reste de la ligne bascule [value].
/// Les deux se lisent d'un seul tenant au lecteur d'écran.
class CheckableRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  const CheckableRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Matériau transparent : l'encre se peindrait sinon SOUS le fond opaque
    // de la carte qui porte la ligne, et l'appui ne se verrait pas.
    // Hors du parcours clavier : la case reste l'arrêt de tabulation, sans
    // second arrêt invisible pour le même geste.
    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          canRequestFocus: false,
          onTap: () => onChanged(!value),
          borderRadius: AppRadius.brSm,
          child: child,
        ),
      ),
    );
  }
}
