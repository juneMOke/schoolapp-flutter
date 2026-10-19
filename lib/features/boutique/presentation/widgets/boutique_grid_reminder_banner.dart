import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le rappel des deux invariants, sous le catalogue.
///
/// **Il n'est pas décoratif** : c'est la formulation utilisateur de I-1 et I-2.
/// Le guichet doit savoir que le prix n'est pas négociable *avant* qu'une
/// famille le lui demande.
class BoutiqueGridReminderBanner extends StatelessWidget {
  const BoutiqueGridReminderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.vertSavane.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vertSavane.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.vertSavane,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.boutiqueGridReminder,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
