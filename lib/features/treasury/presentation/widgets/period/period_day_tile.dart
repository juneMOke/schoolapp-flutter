import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
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
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les colonnes du tableau « Jour par jour » (B7) : JOURNÉE (200) · une
/// colonne par caisse (280 au moins) · CLÔTURE (130, à droite).
abstract final class PeriodDayColumns {
  static const double day = 150;
  static const double register = 240;
  static const double closure = 150;

  static List<double?> widths(int registers) => [
    day,
    for (var i = 0; i < registers; i++) null,
    closure,
  ];

  static double minWidth(int registers) =>
      day + register * registers + closure + 2 * AppSpacing.sm;
}

/// Une journée du tableau « Jour par jour » (B7) : par caisse, entrées,
/// sorties et reste en montants **exacts** (jamais de format court), l'écart
/// s'il y en a, et l'état de la clôture. Toucher la ligne ouvre la journée.
EteeloColumnTableRow periodDayRow(
  BuildContext context, {
  required PeriodDayRow row,
  required List<CashRegister> registers,
  required bool isToday,
  required VoidCallback onOpen,
  bool selected = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  final cells = [
    for (final register in registers)
      if (row.cellOf(register.id) case final cell?) (register, cell),
  ];
  final status = _statusOf(cells.map((c) => c.$2));
  final hasGap = cells.any((c) => c.$2.gapInCents != 0);
  return EteeloColumnTableRow(
    widths: PeriodDayColumns.widths(registers.length),
    onTap: onOpen,
    // La journée ouverte à côté, sur un écran large.
    background: selected ? AppColors.treasuryOpeningSoft : null,
    cells: [
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.minTouchTarget - 2 * AppSpacing.sm,
        ),
        child: Wrap(
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
                ink: AppColors.surfaceRaised,
                fill: AppColors.terreCuite,
              ),
          ],
        ),
      ),
      for (final register in registers)
        switch (row.cellOf(register.id)) {
          final cell? => _Cell(register: register, cell: cell),
          // Caisse pas encore en service ce jour-là.
          null => const SizedBox.shrink(),
        },
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (hasGap)
                  _Tag(
                    label: l10n.treasuryGapTag,
                    ink: TreasuryTones.outflow.ink,
                  ),
                if (status != null) _statusTag(l10n, status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    ],
  );
}

/// L'état de la journée : clôturée si toutes ses caisses le sont, sinon
/// ouverte (aujourd'hui) ou non clôturée (jour passé).
ClosureStatus? _statusOf(Iterable<PeriodDayCell> cells) {
  if (cells.isEmpty) return null;
  if (cells.every((c) => c.status == ClosureStatus.closed)) {
    return ClosureStatus.closed;
  }
  return cells.any((c) => c.status == ClosureStatus.open)
      ? ClosureStatus.open
      : ClosureStatus.notClosed;
}

Widget _statusTag(AppLocalizations l10n, ClosureStatus status) =>
    switch (status) {
      ClosureStatus.closed => _Tag(
        label: l10n.treasuryStatusClosed,
        icon: Icons.lock_outline,
        ink: TreasuryTones.inflow.ink,
      ),
      ClosureStatus.open => _Tag(
        label: l10n.treasuryStatusOpen,
        icon: Icons.schedule,
        ink: TreasuryTones.pending.ink,
      ),
      ClosureStatus.notClosed => _Tag(
        label: l10n.treasuryNotClosed,
        icon: Icons.warning_amber_outlined,
        ink: TreasuryTones.pending.ink,
      ),
    };

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
            text: TreasuryFormat.signedMoney(cell.inflowsInCents, currency),
            style: const TextStyle(color: AppColors.treasuryCdfInk),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: TreasuryFormat.signedMoney(-cell.outflowsInCents, currency),
            style: const TextStyle(color: AppColors.treasuryOutflowInk),
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
    // La justification se lit sur la ligne : une infobulle ne s'ouvre pas au
    // doigt (la ligne entière ouvre la journée), et l'appui long ne se
    // devine pas.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line,
        Text(
          // Entière : c'est la seule place où elle se lit dans la période.
          l10n.treasuryCellJustification(justification),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color ink;
  final Color? fill;

  const _Tag({required this.label, required this.ink, this.icon, this.fill});

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: fill ?? ink.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: AppSpacing.md, color: ink),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
