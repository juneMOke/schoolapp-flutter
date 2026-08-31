import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// Rend un [MoneyBag] : **une ligne par devise**, jamais une somme.
///
/// 425,00 $ et 90 000 FC s'écrivent l'un sous l'autre. Les additionner
/// donnerait un chiffre que personne ne peut vérifier, et l'écart d'échelle
/// entre les deux unités est de ×2 800 — l'erreur ne se verrait même pas.
///
/// En mono-devise, le rendu est **exactement** celui d'un `Text` unique : c'est
/// ce qui permet de remplacer les totaux existants sans rien changer à l'écran
/// tant qu'une seule devise circule.
class MoneyBagText extends StatelessWidget {
  final MoneyBag bag;
  final TextStyle? style;

  /// Ce qui s'affiche quand le sac est **vide**.
  ///
  /// Vide ne veut pas dire zéro : sans aucune créance, on ne sait pas dans
  /// quelle unité l'élève ne doit rien. Un « 0 » nu répondrait à une question
  /// qui ne se pose pas.
  final String emptyLabel;

  /// Alignement des lignes entre elles. À droite pour un total en fin de
  /// tableau, à gauche pour une valeur en tête de carte.
  final CrossAxisAlignment crossAxisAlignment;

  final TextAlign? textAlign;

  const MoneyBagText({
    super.key,
    required this.bag,
    this.style,
    this.emptyLabel = '—',
    this.crossAxisAlignment = CrossAxisAlignment.end,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    if (bag.isEmpty) {
      return Text(emptyLabel, style: style, textAlign: textAlign);
    }

    final sole = bag.soleEntry;
    if (sole != null) {
      return Text(MoneyFormat.format(sole), style: style, textAlign: textAlign);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (final amount in bag.entries) ...[
          if (amount != bag.entries.first)
            const SizedBox(height: AppDimensions.spacingXS),
          Text(MoneyFormat.format(amount), style: style, textAlign: textAlign),
        ],
      ],
    );
  }
}
