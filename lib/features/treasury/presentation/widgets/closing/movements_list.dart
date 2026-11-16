import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/day_movements_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/movement_row.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les entrées ou les sorties d'une caisse sur une journée (B4), dans l'ordre
/// des heures. Au-delà de 5 lignes : les 5 premières, « Afficher les N
/// autres », et une recherche sur le libellé et la référence.
class MovementsList extends StatefulWidget {
  final TreasuryCurrency currency;
  final MovementDirection direction;

  /// Répondre à une ligne arrivée après une clôture ; `null` si la réponse
  /// n'est pas offerte (jour passé, pas le droit, hors ligne).
  final Future<void> Function(CashMovement movement, bool alreadyCounted)?
  onAnswer;

  const MovementsList({
    super.key,
    required this.currency,
    required this.direction,
    this.onAnswer,
  });

  @override
  State<MovementsList> createState() => _MovementsListState();
}

class _MovementsListState extends State<MovementsList> {
  static const int _visible = 5;
  final _query = TextEditingController();
  var _all = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool get _inflows => widget.direction == MovementDirection.inflow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = _inflows ? TreasuryTones.inflow : TreasuryTones.outflow;
    return BlocBuilder<DayMovementsCubit, DayMovementsState>(
      builder: (context, state) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: tone.border),
        ),
        child: Padding(
          padding:
              state.status == DayMovementsStatus.ready && state.items.isNotEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.all(AppSpacing.md),
          child: switch (state.status) {
            DayMovementsStatus.loading => EteeloListSkeleton(
              rowCount: 3,
              pillCount: 0,
              showAvatar: false,
              semanticsLabel: l10n.treasuryMovesLoading,
            ),
            DayMovementsStatus.failure => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.treasuryMovesLoadFailed(
                    l10n.treasuryFailureReason(state.failure!),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                EteeloButton.ghost(
                  label: l10n.treasuryRetry,
                  icon: Icons.refresh,
                  onPressed: context.read<DayMovementsCubit>().load,
                  fullWidth: false,
                ),
              ],
            ),
            _ when state.items.isEmpty => Text(
              _inflows ? l10n.treasuryMovesEmptyIn : l10n.treasuryMovesEmptyOut,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            _ => _list(context, state, tone),
          },
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    DayMovementsState state,
    TreasuryTone tone,
  ) {
    final ink = tone.ink;
    final l10n = AppLocalizations.of(context)!;
    final items = state.items;
    final query = _query.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : [
            for (final m in items)
              if (m.label.toLowerCase().contains(query) ||
                  (m.reference ?? '').toLowerCase().contains(query))
                m,
          ];
    final searchable = items.length > _visible;
    final shown = _all || query.isNotEmpty
        ? filtered
        : filtered.take(_visible).toList();
    final hidden = filtered.length - shown.length;
    final total = items.fold<int>(0, (sum, m) => sum + m.signedInCents);
    final head = AppTypography.labelCaps.copyWith(color: ink);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= MovementColumns.wideMin;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête : HEURE · ENTRÉE (ou SORTIE) · MONTANT, au ton du sens.
            Container(
              color: tone.soft,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppDimensions.treasuryMovesTimeColumn,
                    child: Text(
                      l10n.treasuryMovesTime.toUpperCase(),
                      style: head,
                    ),
                  ),
                  if (wide) ...[
                    SizedBox(
                      width: MovementColumns.reference,
                      child: Text(
                        (_inflows
                                ? l10n.treasuryMovesReceipt
                                : l10n.treasuryMovesPiece)
                            .toUpperCase(),
                        style: head,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        (_inflows
                                ? l10n.treasuryMovesStudent
                                : l10n.treasuryMovesLabel)
                            .toUpperCase(),
                        style: head,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        (_inflows
                                ? l10n.treasuryMovesFee
                                : l10n.treasuryMovesDetail)
                            .toUpperCase(),
                        style: head,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        (_inflows
                                ? l10n.treasuryMovesIn
                                : l10n.treasuryMovesOut)
                            .toUpperCase(),
                        style: head,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.treasuryMovesAmount.toUpperCase(), style: head),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (searchable) ...[
                    const SizedBox(height: AppSpacing.sm),
                    EteeloTextInput(
                      controller: _query,
                      label: _inflows
                          ? l10n.treasuryMovesSearchIn
                          : l10n.treasuryMovesSearchOut,
                      hideLabel: true,
                      placeholder: _inflows
                          ? l10n.treasuryMovesSearchIn
                          : l10n.treasuryMovesSearchOut,
                      capitalization: EteeloTextCapitalization.none,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (filtered.isEmpty)
                    Text(
                      l10n.treasuryMovesNoResult(_query.text.trim()),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  for (final movement in shown)
                    MovementRow(
                      wide: wide,
                      movement: movement,
                      currency: widget.currency,
                      // Une ligne défaite par une autre (annulée) n'attend plus rien :
                      // le serveur refuserait la réponse (NOT_AFTER_CLOSURE).
                      onAnswer: state.awaitsAnswer(movement)
                          ? widget.onAnswer
                          : null,
                    ),
                  if (hidden > 0 || (_all && searchable && query.isEmpty))
                    EteeloButton.ghost(
                      label: _all
                          ? l10n.treasuryMovesShowLess
                          : l10n.treasuryMovesShowMore(hidden),
                      icon: _all ? Icons.expand_less : Icons.expand_more,
                      onPressed: () => setState(() => _all = !_all),
                    ),
                ],
              ),
            ),
            // Pied : filet 2 du ton, fond clair, le compte et le total signé.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: tone.soft,
                border: Border(top: BorderSide(color: ink, width: 2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.treasuryMovesCount(items.length),
                      style: AppTypography.labelMedium.copyWith(color: ink),
                    ),
                  ),
                  Text(
                    TreasuryFormat.signedMoney(total, widget.currency),
                    softWrap: false,
                    style: AppTextStyles.moneyTabular.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
