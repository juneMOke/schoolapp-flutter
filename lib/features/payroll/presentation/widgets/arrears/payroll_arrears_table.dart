import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_tiles.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre des arriérés : un agent par ligne, ses mois dus (le plus
/// ancien d'abord), le total dû, l'ancienneté — rouge à trois mois. Toucher
/// une ligne ouvre la fiche de l'agent.
class PayrollArrearsTable extends StatelessWidget {
  final PayrollSnapshot snapshot;
  final List<PayrollArrearsAgent> agents;
  final String currentMonth;
  final ValueChanged<PayrollArrearsAgent> onOpen;

  const PayrollArrearsTable({
    super.key,
    required this.snapshot,
    required this.agents,
    required this.currentMonth,
    required this.onOpen,
  });

  static const int _lateAfterMonths = 3;

  static const List<double?> _widths = [
    null,
    AppDimensions.payrollColArrearsMonths,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColSchedule,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: AppDimensions.payrollArrearsMinWidth,
      frozenFirstColumn: true,
      widths: _widths,
      endAligned: const {2},
      headers: [
        l10n.payrollColAgent,
        l10n.payrollArrearsColMonths,
        l10n.payrollArrearsColDue,
        l10n.payrollArrearsColAge,
      ],
      rowCount: agents.length,
      row: (context, index) => _row(context, agents[index]),
    );
  }

  Widget _row(BuildContext context, PayrollArrearsAgent agent) {
    final l10n = AppLocalizations.of(context)!;
    final member = snapshot.member(agent.staffMemberId);
    final age = PayrollArrearsTiles.monthsBetween(
      agent.oldestMonth,
      currentMonth,
    );
    final late = age >= _lateAfterMonths;
    return EteeloColumnTableRow(
      widths: _widths,
      onTap: () => onOpen(agent),
      cells: [
        Row(
          children: [
            if (member != null)
              StaffAvatar(
                member: member,
                sync: member.syncState,
                size: AppDimensions.presenceMarkIconButtonSize,
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member?.fullName ?? agent.staffMemberId,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge,
                  ),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (final origin in agent.origins)
                        PayrollArrearOriginTag(origin: origin),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final arrear in agent.months)
              Tooltip(
                message: arrear.reason ?? '',
                child: _Chip(
                  label:
                      '${PayrollLabels.month(context, arrear.month)} · '
                      '${PayrollLabels.money(arrear.dueInCents, arrear.currency)}',
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final currency in agent.currencies)
              Text(
                PayrollLabels.money(agent.dueIn(currency), currency),
                textAlign: TextAlign.end,
                style: EteeloColumnTableRow.figures(strong: true),
              ),
            if (agent.prioritized)
              Text(
                l10n.payrollArrearsPriority,
                style: AppTypography.bodySmall.copyWith(
                  color: PayrollTone.alert.ink,
                ),
              ),
          ],
        ),
        Text(
          l10n.payrollArrearsSince(
            PayrollLabels.month(context, agent.oldestMonth),
            age,
          ),
          style: AppTypography.bodySmall.copyWith(
            color: late ? PayrollTone.alert.ink : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: PayrollTone.submitted.soft,
      borderRadius: BorderRadius.circular(AppSpacing.md),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: PayrollTone.submitted.ink,
        ),
      ),
    ),
  );
}

/// L'origine d'un arriéré : différé décidé, non payé, acompte partiel.
class PayrollArrearOriginTag extends StatelessWidget {
  final PayrollArrearOrigin origin;

  const PayrollArrearOriginTag({super.key, required this.origin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = switch (origin) {
      PayrollArrearOrigin.deferred => (
        l10n.payrollArrearsOriginDeferred,
        PayrollTone.submitted,
      ),
      PayrollArrearOrigin.unpaid => (
        l10n.payrollArrearsOriginUnpaid,
        PayrollTone.alert,
      ),
      PayrollArrearOrigin.partial => (
        l10n.payrollArrearsOriginPartial,
        PayrollTone.draft,
      ),
    };
    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(color: tone.ink),
    );
  }
}
