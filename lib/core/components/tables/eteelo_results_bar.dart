import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// La barre de résultats d'une collection, entre ses filtres et sa table :
/// ce que la machine répond (« 24 agents · 6 à pointer »), dans la terre
/// cuite des écrans de liste ([ListingTones.barreFond]), et l'action qui
/// porte sur ces résultats ([trailing]).
class EteeloResultsBar extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const EteeloResultsBar({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ListingTones.barreFond,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: ListingTones.barreBord),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: ListingTones.inkResultat,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
