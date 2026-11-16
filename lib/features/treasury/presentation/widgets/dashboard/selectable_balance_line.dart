import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/treasury_balance_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La courbe d'une caisse et le point qu'on a touché (R7).
///
/// À la souris, un clic ouvre le rapport de la tranche : le survol a déjà
/// montré son infobulle. Au doigt, il n'y a pas de survol — l'infobulle
/// disparaît avec le doigt, et ouvrir le rapport au premier appui empêchait
/// de lire un point sans lancer la visionneuse. Un appui choisit donc le
/// point : son solde reste affiché sous la courbe, avec « Ouvrir le
/// rapport ».
class SelectableBalanceLine extends StatefulWidget {
  final double height;
  final List<BalanceSlot> slots;
  final TreasuryCurrency currency;
  final int openingInCents;
  final Color lineColor;

  /// Ouvre le rapport d'une tranche ; `null` : les points ne s'ouvrent pas.
  final ValueChanged<int>? onOpenSlot;

  const SelectableBalanceLine({
    super.key,
    required this.height,
    required this.slots,
    required this.currency,
    required this.openingInCents,
    required this.lineColor,
    this.onOpenSlot,
  });

  @override
  State<SelectableBalanceLine> createState() => _SelectableBalanceLineState();
}

class _SelectableBalanceLineState extends State<SelectableBalanceLine> {
  int? _selected;

  @override
  void didUpdateWidget(SelectableBalanceLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Une autre période : le point choisi n'existe plus.
    if (oldWidget.slots.length != widget.slots.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.onOpenSlot;
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: TreasuryBalanceLine(
            currency: widget.currency,
            openingInCents: widget.openingInCents,
            lineColor: widget.lineColor,
            slots: widget.slots,
            onOpenSlot: open,
            onSelectSlot: open == null
                ? null
                : (index) => setState(() => _selected = index),
          ),
        ),
        if (open != null &&
            selected != null &&
            selected < widget.slots.length) ...[
          const SizedBox(height: AppSpacing.sm),
          _SelectedSlot(
            slot: widget.slots[selected],
            currency: widget.currency,
            onOpen: () => open(selected),
          ),
        ],
      ],
    );
  }
}

/// « Mer. 21 oct. · 3 450 000 FC » et « Ouvrir le rapport ».
class _SelectedSlot extends StatelessWidget {
  final BalanceSlot slot;
  final TreasuryCurrency currency;
  final VoidCallback onOpen;

  const _SelectedSlot({
    required this.slot,
    required this.currency,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final balance = slot.balanceInCents;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.treasuryNoteBg,
        border: Border.all(color: AppColors.treasuryNoteBorder),
        borderRadius: AppRadius.brMd,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${slot.label} · '),
                TextSpan(
                  text: balance == null
                      ? l10n.treasuryChartUpcoming
                      : TreasuryFormat.money(balance, currency),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (slot.partial)
                  TextSpan(text: ' · ${l10n.treasuryInProgress}'),
              ],
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.treasuryNoteText,
            ),
          ),
          EteeloButton.ghost(
            label: l10n.treasuryChartOpenReport,
            icon: Icons.description_outlined,
            onPressed: onOpen,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
