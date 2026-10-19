import 'package:flutter/widgets.dart';

/// Une rangée « contenu | action à droite » : le contenu prend toute la place
/// restante, l'action garde sa largeur naturelle, bornée à [maxTrailingShare]
/// de la rangée.
///
/// ⚠️ Un `Flexible` posé à côté d'un `Expanded` ne fait pas cela : les deux se
/// partagent la place libre à parts égales — le texte se bridait à la moitié
/// et le bouton décollait du bord, à toutes les largeurs. Ici, l'action n'a
/// pas de flex : elle ne prend que la place qu'il lui faut, et sur un
/// téléphone son libellé s'abrège à sa borne au lieu de déborder.
class LeadingTrailingRow extends StatelessWidget {
  final Widget leading;
  final Widget trailing;
  final double gap;
  final double maxTrailingShare;
  final CrossAxisAlignment crossAxisAlignment;

  const LeadingTrailingRow({
    super.key,
    required this.leading,
    required this.trailing,
    this.gap = 0,
    this.maxTrailingShare = 0.5,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(child: leading),
          SizedBox(width: gap),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * maxTrailingShare,
            ),
            child: trailing,
          ),
        ],
      ),
    );
  }
}
