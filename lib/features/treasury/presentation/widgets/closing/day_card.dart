import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_day_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/day_movements_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card_figures.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card_footer.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_card_header.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/movement_row.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/movements_list.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une caisse sur la journée affichée (B3) : l'ouverture, les entrées et les
/// sorties (dépliables), le reste, et le pied — clôturer, ou ce qui l'en
/// empêche, ou la clôture et son écart.
class DayCard extends StatefulWidget {
  final CashDaySummary summary;
  final DateTime date;
  final bool isToday;
  final ClosingBlock? block;
  final int pendingSyncCount;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final Future<void> Function(CashMovement movement, bool alreadyCounted)?
  onAnswer;

  const DayCard({
    super.key,
    required this.summary,
    required this.date,
    required this.isToday,
    required this.block,
    this.pendingSyncCount = 0,
    this.onClose,
    this.onReopen,
    this.onAnswer,
  });

  /// La largeur sous laquelle le registre déplié passe sur deux lignes :
  /// [MovementColumns.wideMin], plus le rembourrage de la carte et le filet
  /// (1 dp par côté) de la liste.
  static const double ledgerColumnsMinWidth =
      MovementColumns.wideMin + 2 * _padding + 2;

  static const double _padding = AppSpacing.lg;

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  /// Une seule liste ouverte par carte.
  MovementDirection? _open;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final open = _open;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: TreasuryTones.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayCardHeader(
              summary: summary,
              date: widget.date,
              isToday: widget.isToday,
            ),
            Padding(
              padding: const EdgeInsets.all(DayCard._padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DayCardFigures(
                    summary: summary,
                    open: open,
                    onToggle: (direction) => setState(
                      () => _open = _open == direction ? null : direction,
                    ),
                  ),
                  if (open != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    BlocProvider(
                      // La journée relue (clôture, écart, réouverture) change
                      // le résumé : la liste dépliée se relit avec lui, sinon
                      // son total ne tomberait plus sur la case.
                      key: ValueKey((open, summary)),
                      create: (_) => DayMovementsCubit(
                        GetIt.instance<TreasuryDayRepository>(),
                        date: widget.date,
                        registerId: summary.register.id,
                        direction: open,
                      )..load(),
                      child: Builder(
                        builder: (context) => MovementsList(
                          currency: summary.register.currency,
                          direction: open,
                          onAnswer: widget.onAnswer == null
                              ? null
                              : (movement, already) async {
                                  await widget.onAnswer!(movement, already);
                                  if (context.mounted) {
                                    await context
                                        .read<DayMovementsCubit>()
                                        .load();
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _Remaining(summary: summary, isToday: widget.isToday),
                  const SizedBox(height: AppSpacing.md),
                  DayCardFooter(
                    summary: summary,
                    block: widget.block,
                    pendingSyncCount: widget.pendingSyncCount,
                    onClose: widget.onClose,
                    onReopen: widget.onReopen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le reste (B3) : attendu tant que la caisse est ouverte, déclaré quand elle
/// est clôturée avec un écart.
class _Remaining extends StatelessWidget {
  final CashDaySummary summary;
  final bool isToday;

  const _Remaining({required this.summary, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = summary.register.currency;
    final tone = TreasuryTones.currency(currency);
    final closure = summary.closure;
    final withGap = closure != null && closure.locksRegister && closure.hasGap;
    final title = withGap
        ? l10n.treasuryRemainingDeclared
        : summary.isClosed || !isToday
        ? l10n.treasuryRemaining
        : l10n.treasuryRemainingExpected;
    final hint = withGap
        ? l10n.treasuryExpectedShort(
            TreasuryFormat.money(closure.expectedInCents, currency),
          )
        : l10n.treasuryRemainingHint;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(
          AppDimensions.treasuryRemainingRadius,
        ),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.labelCaps.copyWith(color: tone.ink),
                ),
                Text(
                  hint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                TreasuryFormat.money(summary.closingBalanceInCents, currency),
                softWrap: false,
                style: AppTextStyles.moneyTabular.copyWith(
                  color: withGap ? TreasuryTones.outflow.ink : tone.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: AppDimensions.treasuryRemainingAmountSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
