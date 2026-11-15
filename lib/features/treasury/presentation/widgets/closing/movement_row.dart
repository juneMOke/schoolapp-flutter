import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne du registre : heure, libellé (élidé), référence, étiquettes, et le
/// montant signé — qui ne s'élide jamais.
///
/// Une ligne arrivée après une clôture (R19) dit d'où elle vient et, tant
/// qu'elle attend, propose ses deux réponses.
class MovementRow extends StatefulWidget {
  final CashMovement movement;
  final TreasuryCurrency currency;
  final Future<void> Function(CashMovement movement, bool alreadyCounted)?
  onAnswer;

  const MovementRow({
    super.key,
    required this.movement,
    required this.currency,
    this.onAnswer,
  });

  @override
  State<MovementRow> createState() => _MovementRowState();
}

class _MovementRowState extends State<MovementRow> {
  var _answering = false;

  Future<void> _answer(bool alreadyCounted) async {
    final answer = widget.onAnswer;
    if (answer == null) return;
    setState(() => _answering = true);
    await answer(widget.movement, alreadyCounted);
    if (mounted) setState(() => _answering = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = widget.movement;
    final ink = m.direction == MovementDirection.inflow
        ? AppColors.success
        : AppColors.error;
    final tags = [
      if (m.source == MovementSource.bankDeposit)
        l10n.treasurySourceBankDeposit,
      if (m.source == MovementSource.closingGap) l10n.treasurySourceGap,
      if (m.nature == MovementNature.cancellation)
        l10n.treasuryNatureCancellation,
      if (m.nature == MovementNature.afterClosureOffset)
        l10n.treasuryNatureOffset,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: m.afterClosure ? AppColors.orDoux.withValues(alpha: 0.08) : null,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppDimensions.treasuryMovesTimeColumn,
                child: Text(
                  TreasuryFormat.time(m.occurredAt),
                  style: AppTextStyles.codeMuted,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (m.reference != null)
                          Text(m.reference!, style: AppTextStyles.codeMuted),
                        for (final tag in tags) _Tag(label: tag),
                        if (m.afterClosure)
                          _Tag(
                            label: l10n.treasuryAfterClosureLabel(
                              m.businessDay,
                            ),
                            warn: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                TreasuryFormat.signedMoney(m.signedInCents, widget.currency),
                softWrap: false,
                style: AppTextStyles.moneyTabular.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (m.afterClosure) _afterClosure(l10n, m),
        ],
      ),
    );
  }

  Widget _afterClosure(AppLocalizations l10n, CashMovement m) {
    final answered = m.alreadyCounted;
    if (answered != null) {
      return Padding(
        padding: const EdgeInsets.only(
          left: AppDimensions.treasuryMovesTimeColumn,
          top: AppSpacing.xs,
        ),
        child: Text(
          answered
              ? l10n.treasuryAfterClosureAnsweredAlready
              : l10n.treasuryAfterClosureAnsweredToday,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    if (widget.onAnswer == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.treasuryMovesTimeColumn,
        top: AppSpacing.xs,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          EteeloButton.secondary(
            label: l10n.treasuryAfterClosureAlready,
            isLoading: _answering,
            onPressed: _answering ? null : () => _answer(true),
            fullWidth: false,
          ),
          EteeloButton.secondary(
            label: l10n.treasuryAfterClosureToday,
            onPressed: _answering ? null : () => _answer(false),
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool warn;

  const _Tag({required this.label, this.warn = false});

  @override
  Widget build(BuildContext context) {
    final ink = warn ? AppColors.financeCrossedAccent : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.1),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: ink)),
    );
  }
}
