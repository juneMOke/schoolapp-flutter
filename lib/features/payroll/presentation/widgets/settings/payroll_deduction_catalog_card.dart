import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_deduction_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

export 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_deduction_table.dart'
    show PayrollDeductionCatalogActions;

/// RH · Paie ▸ Configuration — la carte des rubriques de l'école. Hors de la
/// barre d'enregistrement : chaque geste s'écrit seul. [actions] nul : l'économe
/// consulte.
class PayrollDeductionCatalogCard extends StatelessWidget {
  final List<PayrollDeductionType> catalog;
  final PayrollDeductionCatalogActions? actions;

  /// Les devises réglées par l'école : le plafond se juge devise par devise.
  final List<String> currencies;

  const PayrollDeductionCatalogCard({
    super.key,
    required this.catalog,
    required this.actions,
    required this.currencies,
  });

  /// Chaque devise a atteint son plafond : plus rien à créer.
  bool _full(List<PayrollDeductionType> active) => currencies.every(
    (currency) =>
        active.where((type) => type.appliesTo(currency)).length >=
        PayrollDeductionType.maxActive,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = catalog.where((type) => !type.archived).toList();
    final archived = catalog.where((type) => type.archived).toList();
    final actions = this.actions;
    final full = _full(active);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: BiToneSectionCard(
        title: l10n.payrollDeductionsTitle,
        subtitle: l10n.payrollDeductionsSubtitle,
        icon: Icons.playlist_remove_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (active.isEmpty)
              Text(
                l10n.payrollDeductionsEmpty,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (active.isNotEmpty)
              PayrollDeductionTable(types: active, actions: actions),
            if (actions != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: EteeloButton.secondary(
                  label: l10n.payrollDeductionsAdd,
                  icon: Icons.add,
                  onPressed: full ? null : actions.onAdd,
                  fullWidth: false,
                ),
              ),
              if (full) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.payrollRuleDeductionTypeLimit,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.payrollDeductionsArchivedTitle,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PayrollDeductionTable(types: archived, actions: actions),
            ],
          ],
        ),
      ),
    );
  }
}
