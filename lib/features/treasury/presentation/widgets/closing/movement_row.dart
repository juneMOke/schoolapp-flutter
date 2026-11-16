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
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les colonnes du détail des mouvements, comme celles du tableau des
/// entrées du rapport : HEURE · N° REÇU · ÉLÈVE · FRAIS · MONTANT.
abstract final class MovementColumns {
  /// Au-delà de cette largeur, les colonnes ; en deçà, deux lignes.
  static const double wideMin = 520;
  static const double reference = 128;

  /// « Frais de scolarité — Kabongo Mwamba · 6e A » → (« Frais de
  /// scolarité », « Kabongo Mwamba · 6e A ») ; sans « — », le libellé seul.
  /// Le libellé est écrit par le serveur avec ce séparateur.
  static (String, String?) split(String label) {
    final at = label.indexOf(' — ');
    if (at < 0) return (label, null);
    return (label.substring(0, at), label.substring(at + 3));
  }
}

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

  /// En colonnes (carte large), ou sur deux lignes.
  final bool wide;

  const MovementRow({
    super.key,
    required this.movement,
    required this.currency,
    this.onAnswer,
    this.wide = false,
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
        ? TreasuryTones.inflow.ink
        : TreasuryTones.outflow.ink;
    final extras = <Widget>[
      for (final tag in [
        if (m.source == MovementSource.bankDeposit)
          l10n.treasurySourceBankDeposit,
        if (m.source == MovementSource.closingGap) l10n.treasurySourceGap,
        if (m.nature == MovementNature.cancellation)
          l10n.treasuryNatureCancellation,
        if (m.nature == MovementNature.afterClosureOffset)
          l10n.treasuryNatureOffset,
      ])
        _Tag(label: tag),
      if (m.afterClosure)
        _Tag(label: l10n.treasuryAfterClosureLabel(m.businessDay), warn: true),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: m.afterClosure ? TreasuryTones.pending.soft : null,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.wide)
            _wideRow(m, ink, extras)
          else
            _narrowRow(m, ink, extras),
          if (m.afterClosure) _afterClosure(l10n, m),
        ],
      ),
    );
  }

  /// Large : HEURE · N° REÇU · ÉLÈVE · FRAIS · MONTANT, comme le tableau des
  /// entrées du rapport.
  Widget _wideRow(CashMovement m, Color ink, List<Widget> extras) {
    final (motif, who) = MovementColumns.split(m.label);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimensions.treasuryMovesTimeColumn,
          child: Text(
            TreasuryFormat.time(m.occurredAt),
            style: AppTextStyles.codeMuted,
          ),
        ),
        SizedBox(
          width: MovementColumns.reference,
          child: Text(
            m.reference ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.codeMuted,
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              who ?? motif,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (who != null)
                Text(
                  motif,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (extras.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: extras,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _amount(m, ink),
      ],
    );
  }

  /// Étroit : l'heure, le n° et le montant, puis l'élève, puis les frais.
  Widget _narrowRow(CashMovement m, Color ink, List<Widget> extras) {
    final (motif, who) = MovementColumns.split(m.label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: AppDimensions.treasuryMovesTimeColumn,
              child: Text(
                TreasuryFormat.time(m.occurredAt),
                style: AppTextStyles.codeMuted,
              ),
            ),
            Expanded(
              child: Text(
                m.reference ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.codeMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _amount(m, ink),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.treasuryMovesTimeColumn,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                who ?? motif,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (who != null)
                Text(
                  motif,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (extras.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: extras,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amount(CashMovement m, Color ink) => Text(
    TreasuryFormat.signedMoney(m.signedInCents, widget.currency),
    softWrap: false,
    style: AppTextStyles.moneyTabular.copyWith(
      color: ink,
      fontWeight: FontWeight.w700,
    ),
  );

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
