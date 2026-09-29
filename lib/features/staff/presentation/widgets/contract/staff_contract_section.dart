import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/contract/staff_contract_period_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bloc « Statut du contrat & rémunération » de la page agent.
///
/// La frise (statut et dates) se lit sous `hr.staff.read` ; les montants
/// n'apparaissent que si le compte les reçoit (`hr.pay.read`) ; poser et
/// corriger sont des gestes à part (`hr.pay.write`), jamais une modification
/// de la fiche.
class StaffContractSection extends StatelessWidget {
  /// La frise affichée, la plus récente d'abord.
  final List<StaffContractPeriod> timeline;

  /// La période en vigueur aujourd'hui, ou `null` (contrat à poser).
  final StaffContractPeriod? current;

  /// Les périodes avec montants, par identifiant — vide sans `hr.pay.read`.
  final Map<String, StaffContract> details;

  /// `null` quand le compte ne peut pas poser de contrat.
  final VoidCallback? onAdd;

  /// `null` quand le compte ne peut pas corriger.
  final ValueChanged<StaffContract>? onCorrect;

  const StaffContractSection({
    super.key,
    required this.timeline,
    required this.current,
    required this.details,
    this.onAdd,
    this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final add = onAdd;
    return StaffFormBlock(
      title: l10n.staffBlockContract,
      subtitle: l10n.staffBlockContractHint,
      icon: Icons.handshake_outlined,
      color: StaffStepStyle.of(2).color,
      children: [
        if (timeline.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.staffContractNoneYet,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        for (final period in timeline)
          StaffContractPeriodTile(
            period: period,
            detail: details[period.contractId],
            isCurrent: period.contractId == current?.contractId,
            onCorrect: onCorrect,
          ),
        if (add != null)
          Align(
            alignment: Alignment.centerLeft,
            child: EteeloButton.secondary(
              label: l10n.staffContractAdd,
              icon: Icons.add,
              onPressed: add,
              fullWidth: false,
            ),
          ),
      ],
    );
  }
}
