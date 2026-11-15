import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/chart_label_density.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/balance_chart_painters.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une tranche de la courbe : son libellé d'axe, son solde (`null` : à venir)
/// et ce qui est entré et sorti.
class BalanceSlot {
  final String label;
  final int? balanceInCents;
  final int inflowsInCents;
  final int outflowsInCents;
  final bool partial;

  const BalanceSlot({
    required this.label,
    required this.inflowsInCents,
    required this.outflowsInCents,
    required this.partial,
    this.balanceInCents,
  });
}

/// La courbe du solde d'une caisse (A4). Propre à la trésorerie, parce que
/// trois choses y sont normatives et que la courbe partagée ne les porte pas :
///  - les tranches **à venir** gardent leur place sur l'axe, sans point
///    (R6 : la semaine montre lun.–sam. même à venir) ;
///  - la ligne d'ouverture reste **dans le cadre**, même quand le solde
///    plonge sous elle ;
///  - l'infobulle dit le montant **exact**, avec sa devise, les entrées et
///    les sorties de la tranche.
class TreasuryBalanceLine extends StatelessWidget {
  final List<BalanceSlot> slots;
  final TreasuryCurrency currency;
  final int openingInCents;
  final Color lineColor;

  /// Toucher un point ouvre le rapport de sa tranche (R7). `null` : rien.
  final ValueChanged<int>? onOpenSlot;

  const TreasuryBalanceLine({
    super.key,
    required this.slots,
    required this.currency,
    required this.openingInCents,
    required this.lineColor,
    this.onOpenSlot,
  });

  /// Marge de l'axe des montants : 74, 52 sur téléphone (spec A4).
  static double axisReservedOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.phoneNarrowMax
      ? 52
      : 74;
  static const double _bottomReserved = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final known = [
      for (final (i, s) in slots.indexed)
        if (s.balanceInCents != null)
          FlSpot(i.toDouble(), s.balanceInCents! / 100),
    ];
    final opening = openingInCents / 100;
    final values = [opening, for (final s in known) s.y];
    final top = values.reduce((a, b) => a > b ? a : b);
    final bottom = values.reduce((a, b) => a < b ? a : b);
    // Jamais sous zéro, et une marge au-dessus pour que le dernier point ne
    // touche pas le bord (spec : + 14 %).
    // Trois graduations (min, milieu, max) sur des multiples de l'intervalle :
    // fl_chart cale sa grille sur zéro, et des bornes hors multiple
    // ajoutaient une quatrième graduation collée au maximum.
    // Trois graduations : min, milieu, max de la plage, plus 14 % de marge
    // de part et d'autre, jamais sous zéro (spec A4).
    final span = top - bottom == 0 ? (top.abs() + 1) : top - bottom;
    final minY = (bottom - span * 0.14).clamp(0.0, double.infinity);
    final maxY = top + span * 0.14;
    final interval = (maxY - minY) / 2;
    // fl_chart cale ses graduations sur les multiples de l'intervalle à
    // partir de zéro : on trace donc au-dessus du minimum (0 = min), et les
    // libellés rajoutent ce minimum. Trois graduations exactes : min, milieu,
    // max.
    final plotted = [for (final spot in known) FlSpot(spot.x, spot.y - minY)];
    final axisReserved = axisReservedOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = chartLabelStep(
          count: slots.length,
          width: constraints.maxWidth - axisReserved,
          minSpacing: AppDimensions.chartAxisLabelMinSpacing,
        );
        final lastKnown = known.isEmpty ? -1 : known.last.x.toInt();
        final chart = LineChart(
          LineChartData(
            // Un solde négatif (le serveur ne refuse jamais un fait d'argent)
            // ne déborde pas sur les libellés.
            clipData: const FlClipData.all(),
            minX: 0,
            maxX: (slots.length - 1).clamp(1, 1 << 30).toDouble(),
            minY: 0,
            maxY: maxY - minY,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.treasuryChartGrid,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: opening - minY,
                  color: AppColors.treasuryOpeningLine.withValues(alpha: 0.7),
                  strokeWidth: 1.2,
                  dashArray: const [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.treasuryOpeningLine,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (_) =>
                        '${l10n.treasuryOpening} ${axisLabel(opening)}',
                  ),
                ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: axisReserved,
                  interval: interval,
                  // L'axe seul abrège les francs (3 450 k) ; l'infobulle
                  // dit l'exact.
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Text(
                      axisLabel(value + minY),
                      textAlign: TextAlign.end,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.treasuryChartAxisInk,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _bottomReserved,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= slots.length || value != i) {
                      return const SizedBox.shrink();
                    }
                    if (i != lastKnown && i % step != 0) {
                      return const SizedBox.shrink();
                    }
                    final future = slots[i].balanceInCents == null;
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        slots[i].label,
                        style: AppTypography.labelMedium.copyWith(
                          color: i == lastKnown
                              ? AppColors.terreCuite
                              : future
                              ? AppColors.treasuryChartFutureInk
                              : AppColors.treasuryChartAxisInk,
                          fontWeight: i == lastKnown
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchCallback: (event, response) {
                final open = onOpenSlot;
                final spot = response?.lineBarSpots?.firstOrNull;
                if (open == null || spot == null || event is! FlTapUpEvent) {
                  return;
                }
                open(spot.x.toInt());
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.bleuProfond,
                getTooltipItems: (touched) => [
                  for (final spot in touched) _tooltip(l10n, spot.x.toInt()),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: plotted,
                color: lineColor,
                barWidth: 3,
                isStrokeJoinRound: true,
                dotData: FlDotData(
                  getDotPainter: (spot, _, _, _) => spot.x.toInt() == lastKnown
                      ? FlDotCirclePainter(
                          radius: 6,
                          color: AppColors.terreCuite,
                          strokeColor: AppColors.surfaceRaised,
                          strokeWidth: 2.5,
                        )
                      : FlDotCirclePainter(
                          radius: 4.5,
                          color: AppColors.surfaceRaised,
                          strokeColor: lineColor,
                          strokeWidth: 2.5,
                        ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.2),
                      lineColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        // Les tranches à venir, hachurées, et l'anneau du dernier point
        // connu, peints sous la courbe dans le repère du tracé.
        return CustomPaint(
          painter: TreasuryChartBackdrop(
            count: slots.length,
            lastKnown: lastKnown,
            left: axisReserved,
            bottom: _bottomReserved,
          ),
          foregroundPainter: lastKnown < 0
              ? null
              : TreasuryChartRing(
                  x: lastKnown,
                  y: known.last.y - minY,
                  count: slots.length,
                  minY: 0,
                  maxY: maxY - minY,
                  left: axisReserved,
                  bottom: _bottomReserved,
                ),
          child: chart,
        );
      },
    );
  }

  /// Un libellé d'axe : l'unité entière ; en milliers pour les francs
  /// (« 3 450 k »).
  String axisLabel(double value) {
    final units = value.round();
    final thousands = currency == TreasuryCurrency.cdf;
    final shown = thousands ? (units / 1000).round() : units;
    final digits = shown.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => MoneyFormat.nbsp,
    );
    return '${shown < 0 ? '−' : ''}$digits${thousands ? ' k' : ''}';
  }

  LineTooltipItem _tooltip(AppLocalizations l10n, int index) {
    final slot = slots[index];
    final balance = slot.balanceInCents;
    final head = AppTypography.labelSmall.copyWith(
      color: AppColors.orDoux,
      fontWeight: FontWeight.w600,
    );
    if (balance == null) {
      return LineTooltipItem(
        '${slot.label}\n${l10n.treasuryChartUpcoming}',
        head,
      );
    }
    return LineTooltipItem(
      '${slot.label}\n',
      head,
      textAlign: TextAlign.left,
      children: [
        TextSpan(
          text:
              '${TreasuryFormat.money(balance, currency)}'
              '${slot.partial ? ' · ${l10n.treasuryInProgress}' : ''}\n',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.surfaceRaised,
          ),
        ),
        TextSpan(
          text:
              '${TreasuryFormat.signedMoney(slot.inflowsInCents, currency)}  '
              '${TreasuryFormat.signedMoney(-slot.outflowsInCents, currency)}',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.surfaceRaised,
          ),
        ),
      ],
    );
  }
}
