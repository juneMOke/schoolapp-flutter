import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/depot_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un élève face au devoir : son état de remise et, s'il a rendu, sa copie.
class DepotEleveRow extends StatelessWidget {
  final CopieRendue eleve;

  /// La copie s'ouvre-t-elle maintenant (en ligne, ou déjà téléchargée) ?
  final bool canOpen;
  final VoidCallback onOpen;

  const DepotEleveRow({
    super.key,
    required this.eleve,
    required this.canOpen,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final etat = eleve.etat;
    final tone = DepotLabels.tone(etat);
    final depositedAt = eleve.depot?.depositedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eleve.name, style: AppTypography.bodyMedium),
              if (depositedAt != null)
                Text(
                  l10n.depotDeposeLe(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(depositedAt.toLocal()),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tone.soft,
                  border: Border.all(color: tone.border),
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  DepotLabels.etat(l10n, etat),
                  style: AppTypography.labelSmall.copyWith(color: tone.ink),
                ),
              ),
              if (eleve.depot != null) ...[
                const SizedBox(width: AppSpacing.sm),
                EteeloButton.ghost(
                  label: canOpen
                      ? l10n.depotOuvrir
                      : l10n.depotEnLigneSeulement,
                  icon: Icons.description_outlined,
                  onPressed: canOpen ? onOpen : null,
                  fullWidth: false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
