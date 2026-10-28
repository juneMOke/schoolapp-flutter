import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Prêts & avances » : qui rembourse, ce qui reste dû, ce que le mois
/// retient — servis par le serveur à l'instant du calcul. Le détail se gère
/// dans Avances & prêts.
class PayrollDashboardAdvancesCard extends StatefulWidget {
  final List<PayrollDashboardAdvance> advances;
  final VoidCallback onManage;

  const PayrollDashboardAdvancesCard({
    super.key,
    required this.advances,
    required this.onManage,
  });

  @override
  State<PayrollDashboardAdvancesCard> createState() => _AdvancesCardState();
}

class _AdvancesCardState extends State<PayrollDashboardAdvancesCard> {
  static const _filters = [
    PayrollAdvanceFilter.ongoing,
    PayrollAdvanceFilter.settled,
    PayrollAdvanceFilter.all,
  ];
  PayrollAdvanceFilter _filter = PayrollAdvanceFilter.ongoing;

  /// Une carte, pas un registre.
  static const int _maxRows = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final advances = widget.advances;
    final ongoing = advances.where((a) => a.phase.isOngoing).toList();
    final visible = [
      for (final advance in advances)
        if (switch (_filter) {
          PayrollAdvanceFilter.ongoing => advance.phase.isOngoing,
          PayrollAdvanceFilter.settled =>
            advance.phase == PayrollAdvancePhase.settled,
          _ => true,
        })
          advance,
    ];
    final due = PayrollLabels.perCurrency(
      ongoing.map((a) => (a.remainingInCents, a.currency)),
    ).join(' · ');
    return EteeloStatsCard(
      title: l10n.payrollDashAdvancesTitle,
      subtitle: ongoing.isEmpty
          ? null
          : l10n.payrollDashAdvancesSubtitle(
              {for (final a in ongoing) a.staffMemberId}.length,
              due,
            ),
      icon: Icons.handshake_outlined,
      tone: DashboardSense.attente,
      toneStrength: DashboardTones.forceDe(DashboardSense.attente),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollDashManage,
          icon: Icons.arrow_forward,
          onPressed: widget.onManage,
          fullWidth: false,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegmentedTabFilter<PayrollAdvanceFilter>(
              semanticsLabel: l10n.payrollDashAdvancesTitle,
              style: SegmentedTabFilterStyle.window,
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
              options: [
                for (final filter in _filters)
                  SegmentedTabOption(
                    value: filter,
                    label: switch (filter) {
                      PayrollAdvanceFilter.ongoing =>
                        l10n.payrollDashFilterOngoing,
                      PayrollAdvanceFilter.settled =>
                        l10n.payrollDashFilterSettled,
                      _ => l10n.payrollAdvancesFilterAll,
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.payrollDashAdvancesEmpty,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            for (final advance in visible.take(_maxRows)) ...[
              const Divider(height: 1, color: AppColors.border),
              _AdvanceRow(advance: advance),
            ],
            if (visible.length > _maxRows)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.payrollDashMore(visible.length - _maxRows),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne : qui et pourquoi à gauche, le reste dû en gros à droite, puis
/// la barre du remboursé et ce que le mois retient.
class _AdvanceRow extends StatelessWidget {
  final PayrollDashboardAdvance advance;

  const _AdvanceRow({required this.advance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, advance.currency);
    final repaid = advance.repaidShare;
    final settled = advance.phase == PayrollAdvancePhase.settled;
    final taken = advance.takenThisMonthInCents;
    final details = [
      advance.isLoan
          ? l10n.payrollAgentAdvanceLoan(advance.installments)
          : l10n.payrollAgentAdvanceSingle,
      if (advance.reason case final reason?) PayrollLabels.reason(l10n, reason),
      // « le 18 oct. 2026 » : sans le jour de la semaine, qui n'apprend rien.
      if (DateTime.tryParse(advance.grantedOn) case final granted?)
        l10n.payrollDashGrantedOn(granted),
    ].join(' · ');
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advance.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge,
                    ),
                    Text(details, style: muted),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(advance.remainingInCents),
                    style: AppTypography.titleSmall.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    l10n.payrollDashLeftOf(money(advance.amountInCents)),
                    style: muted,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // La barre prend la largeur ; ce que le mois retient se lit au
          // bout, sans jamais lui prendre plus que la moitié.
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.brPill,
                    child: LinearProgressIndicator(
                      value: repaid,
                      minHeight: AppDimensions.payrollProgressHeight,
                      backgroundColor: AppColors.surfaceRaised,
                      color: repaid >= 1
                          ? DashboardSense.encaisse
                          : DashboardSense.attente,
                      semanticsLabel: l10n.payrollDashRepaidA11y(
                        (repaid * 100).round(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth / 2,
                  ),
                  child: Text(
                    taken > 0
                        ? l10n.payrollDashTakenThisMonth(money(taken))
                        : settled
                        ? l10n.payrollDashStatusSettled
                        : l10n.payrollDashNothingThisMonth,
                    textAlign: TextAlign.end,
                    style: taken > 0
                        ? muted.copyWith(color: PayrollTone.submitted.ink)
                        : muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
