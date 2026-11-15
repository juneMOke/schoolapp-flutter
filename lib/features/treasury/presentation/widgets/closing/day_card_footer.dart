import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied d'une carte du jour : « Clôturer la caisse » (ou ce qui l'en
/// empêche), ou la clôture enregistrée et, s'il y en a un, son écart avec sa
/// justification (R16).
class DayCardFooter extends StatelessWidget {
  final CashDaySummary summary;
  final ClosingBlock? block;
  final int pendingSyncCount;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;

  const DayCardFooter({
    super.key,
    required this.summary,
    required this.block,
    required this.pendingSyncCount,
    this.onClose,
    this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final closure = summary.closure;
    if (closure != null && closure.locksRegister) {
      return _Closed(closure: closure, onReopen: onReopen);
    }
    final l10n = AppLocalizations.of(context)!;
    final reason = switch (block) {
      null => null,
      ClosingBlock.notToday || ClosingBlock.closed => null,
      ClosingBlock.sunday => l10n.treasuryCloseSunday,
      ClosingBlock.noRight => l10n.treasuryReadOnlyCashier,
      ClosingBlock.offline => l10n.treasuryCloseOffline,
      ClosingBlock.pendingSync => l10n.treasuryClosePending(pendingSyncCount),
      // Le serveur compte celles de toutes les journées jusqu'à aujourd'hui :
      // on dit où y répondre.
      ClosingBlock.pendingAfterClosure =>
        '${l10n.treasuryCloseAfterClosurePending(summary.pendingAfterClosureCount)} '
            '${l10n.treasuryCloseAfterClosureWhere}',
    };
    // Un jour passé non clôturé : la pastille « Non clôturée » suffit.
    if (block == ClosingBlock.notToday) return const SizedBox.shrink();
    final close = block == null ? onClose : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (block != ClosingBlock.noRight)
          Text(
            l10n.treasuryCloseHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        if (reason != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _Note(
            text: reason,
            icon: block == ClosingBlock.noRight
                ? Icons.visibility_outlined
                : Icons.info_outline,
            ink: block == ClosingBlock.noRight
                ? AppColors.textSecondary
                : AppColors.financeCrossedAccent,
          ),
        ],
        if (block != ClosingBlock.noRight) ...[
          const SizedBox(height: AppSpacing.sm),
          EteeloButton.primary(
            label: l10n.treasuryCloseButton,
            icon: Icons.lock_outline,
            onPressed: close,
          ),
        ],
      ],
    );
  }
}

class _Closed extends StatelessWidget {
  final CashClosure closure;
  final VoidCallback? onReopen;

  const _Closed({required this.closure, this.onReopen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = TreasuryFormat.time(closure.closedAt);
    final by = closure.closedByCashier
        ? l10n.treasuryClosedBy(time, closure.closedByName)
        : l10n.treasuryClosedByPromoter(time, closure.closedByName);
    final reopen = onReopen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Note(
          text:
              '$by · ${closure.hasGap ? l10n.treasuryClosedWithGap : l10n.treasuryClosedMatched}',
          icon: Icons.lock_outline,
          ink: AppColors.treasuryCdfInk,
        ),
        if (closure.hasGap) ...[
          const SizedBox(height: AppSpacing.sm),
          _GapNote(closure: closure),
        ],
        if (reopen != null) ...[
          const SizedBox(height: AppSpacing.sm),
          EteeloButton.secondary(
            label: l10n.treasuryReopenButton,
            icon: Icons.lock_open_outlined,
            onPressed: reopen,
          ),
        ],
      ],
    );
  }
}

/// L'écart de clôture, tel qu'il reste lisible sur toute journée consultée
/// (R16) : montant signé, manquant ou excédent, attendu et déclaré, la
/// justification citée et son auteur.
class _GapNote extends StatelessWidget {
  final CashClosure closure;

  const _GapNote({required this.closure});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = closure.currency;
    final missing = closure.gapInCents < 0;
    final justification = closure.justification;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.treasuryGapTitle(TreasuryFormat.signedMoney(closure.gapInCents, currency))} · '
            '${missing ? l10n.treasuryGapMissing : l10n.treasuryGapSurplus}',
            style: AppTypography.titleSmall.copyWith(color: AppColors.error),
          ),
          Text(
            l10n.treasuryExpectedDeclared(
              TreasuryFormat.money(closure.expectedInCents, currency),
              TreasuryFormat.money(closure.declaredInCents, currency),
            ),
            style: AppTypography.bodySmall,
          ),
          if (justification != null && justification.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.error, width: 3),
                ),
              ),
              child: Text(
                '« $justification »',
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.treasuryGapAuthor(
              closure.closedByName,
              TreasuryFormat.time(closure.closedAt),
            ),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color ink;

  const _Note({required this.text, required this.icon, required this.ink});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: ink.withValues(alpha: 0.08),
      border: Border.all(color: ink.withValues(alpha: 0.2)),
      borderRadius: AppRadius.brMd,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.lg, color: ink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: ink),
          ),
        ),
      ],
    ),
  );
}
