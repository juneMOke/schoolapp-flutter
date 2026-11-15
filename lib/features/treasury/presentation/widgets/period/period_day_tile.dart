import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une journée du tableau « Jour par jour » (B7) : par caisse, entrées,
/// sorties et reste en montants **exacts** (jamais de format court), l'écart
/// s'il y en a, et l'état de la clôture. Toucher la ligne ouvre la journée.
class PeriodDayTile extends StatelessWidget {
  final PeriodDayRow row;
  final List<CashRegister> registers;
  final bool isToday;
  final VoidCallback onOpen;

  const PeriodDayTile({
    super.key,
    required this.row,
    required this.registers,
    required this.isToday,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cells = [
      for (final register in registers)
        if (row.cellOf(register.id) case final cell?) (register, cell),
    ];
    final status = _statusOf(cells.map((c) => c.$2));
    final hasGap = cells.any((c) => c.$2.gapInCents != 0);
    return Material(
      color: AppColors.surfaceRaised,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            capitalizeFirst(l10n.treasuryDayShort(row.day)),
                            style: AppTypography.titleSmall,
                          ),
                          if (isToday)
                            _Tag(
                              label: l10n.treasuryToday,
                              ink: AppColors.terreCuite,
                            ),
                          // L'état et l'écart suivent le titre et passent à
                          // la ligne avec lui : une colonne à droite privait
                          // le titre de sa place sur téléphone.
                          if (hasGap)
                            _Tag(
                              label: l10n.treasuryGapTag,
                              ink: AppColors.error,
                            ),
                          if (status != null) _statusTag(l10n, status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final (register, cell) in cells)
                            _Cell(register: register, cell: cell),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// L'état de la journée : clôturée si toutes ses caisses le sont, sinon
  /// ouverte (aujourd'hui) ou non clôturée (jour passé).
  static ClosureStatus? _statusOf(Iterable<PeriodDayCell> cells) {
    if (cells.isEmpty) return null;
    if (cells.every((c) => c.status == ClosureStatus.closed)) {
      return ClosureStatus.closed;
    }
    return cells.any((c) => c.status == ClosureStatus.open)
        ? ClosureStatus.open
        : ClosureStatus.notClosed;
  }

  static Widget _statusTag(AppLocalizations l10n, ClosureStatus status) =>
      switch (status) {
        ClosureStatus.closed => _Tag(
          label: l10n.treasuryStatusClosed,
          icon: Icons.lock_outline,
          ink: AppColors.success,
        ),
        ClosureStatus.open => _Tag(
          label: l10n.treasuryStatusOpen,
          icon: Icons.schedule,
          ink: AppColors.financeCrossedAccent,
        ),
        ClosureStatus.notClosed => _Tag(
          label: l10n.treasuryNotClosed,
          icon: Icons.warning_amber_outlined,
          ink: AppColors.financeCrossedAccent,
        ),
      };
}

class _Cell extends StatelessWidget {
  final CashRegister register;
  final PeriodDayCell cell;

  const _Cell({required this.register, required this.cell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = register.currency;
    final gap = cell.gapInCents;
    final justification = cell.justification;
    final line = Text.rich(
      TextSpan(
        style: AppTextStyles.moneyTabular,
        children: [
          TextSpan(
            text: '${register.name} · ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: TreasuryFormat.signedMoney(cell.inflowsInCents, currency),
            style: const TextStyle(color: AppColors.success),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: TreasuryFormat.signedMoney(-cell.outflowsInCents, currency),
            style: const TextStyle(color: AppColors.error),
          ),
          TextSpan(
            text:
                '  = ${TreasuryFormat.money(cell.closingBalanceInCents, currency)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (gap != 0)
            TextSpan(
              text:
                  '  ${l10n.treasuryCellGap(TreasuryFormat.signedMoney(gap, currency))}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
    if (gap == 0 || justification == null) return line;
    return Tooltip(message: justification, child: line);
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color ink;

  const _Tag({required this.label, required this.ink, this.icon});

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: AppSpacing.md, color: ink),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
