import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Un segment de [HrBar] : un compte, et sa couleur.
class HrBarSegment {
  final int count;
  final Color color;

  const HrBarSegment({required this.count, required this.color});
}

/// Une barre arrondie sur sa piste : un segment (« Par catégorie ») ou
/// plusieurs bout à bout (« Parité »), chacun valant `count / scale` de la
/// largeur. La piste reste visible : elle donne l'échelle, et c'est elle qu'on
/// lit quand une valeur est nulle.
///
/// Des poids entiers (`flex`) plutôt que des fractions : la somme des parts
/// retombe exactement sur la largeur, sans le pixel de trop qu'un arrondi de
/// flottants ferait déborder.
///
/// Purement décorative : la ligne qui la porte dit ses chiffres en texte.
class HrBar extends StatelessWidget {
  final List<HrBarSegment> segments;

  /// Le compte qui remplit la barre (le total, ou le plus fort).
  final int scale;
  final double height;

  const HrBar({
    super.key,
    required this.segments,
    required this.scale,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final filled = segments.fold<int>(0, (sum, s) => sum + s.count);
    final rest = scale - filled;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.brPill,
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: AppColors.surfaceAlt,
            child: Row(
              children: [
                for (final segment in segments)
                  if (segment.count > 0)
                    Expanded(
                      flex: segment.count,
                      child: ColoredBox(color: segment.color),
                    ),
                if (rest > 0) Spacer(flex: rest),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
