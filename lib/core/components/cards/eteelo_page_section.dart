import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Une section de page sur un fin fond : une surface à peine teintée, un
/// filet de bord, un rayon commun. Les cartes blanches qu'elle porte s'y
/// détachent, et la page se lit en trois plans — la page, la section, le
/// contenu — au lieu de blocs qui flottent chacun à sa façon.
class EteeloPageSection extends StatelessWidget {
  final Widget child;

  const EteeloPageSection({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: AppRadius.brCard,
      border: Border.all(color: AppColors.border),
    ),
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}
