import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/chart_label_density.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/helpers/number_formatter_helper.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
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

  const TreasuryBalanceLine({
    super.key,
    required this.slots,
    required this.currency,
    required this.openingInCents,
    required this.lineColor,
  });

  static const double _axisReserved = 52;

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
    final rawMin = bottom <= 0 ? 0.0 : bottom * 0.86;
    final rawMax = (top * 1.14).clamp(1.0, double.infinity);
    final interval = _niceStep((rawMax - rawMin) / 2);
    final minY = (rawMin / interval).floorToDouble() * interval;
    final maxY = minY + 2 * interval >= rawMax
        ? minY + 2 * interval
        : (rawMax / interval).ceilToDouble() * interval;
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = chartLabelStep(
          count: slots.length,
          width: constraints.maxWidth - _axisReserved,
          minSpacing: AppDimensions.chartAxisLabelMinSpacing,
        );
        final lastKnown = known.isEmpty ? -1 : known.last.x.toInt();
        return LineChart(
          LineChartData(
            // Un solde négatif (le serveur ne refuse jamais un fait d'argent)
            // ne déborde pas sur les libellés.
            clipData: const FlClipData.all(),
            minX: 0,
            maxX: (slots.length - 1).clamp(1, 1 << 30).toDouble(),
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: opening,
                  color: AppColors.terreCuite.withValues(alpha: 0.7),
                  strokeWidth: 1.2,
                  dashArray: const [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.terreCuite,
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (_) => l10n.treasuryOpening,
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
                  reservedSize: _axisReserved,
                  interval: interval,
                  // L'axe seul abrège (3 450 k) ; l'infobulle dit l'exact.
                  getTitlesWidget: (value, meta) => Text(
                    NumberFormatterHelper.formatYAxisLabel(value),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
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
                    return Text(
                      slots[i].label,
                      style: AppTypography.labelSmall.copyWith(
                        color: i == lastKnown
                            ? AppColors.terreCuite
                            : future
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        fontWeight: i == lastKnown
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.bleuProfond,
                getTooltipItems: (touched) => [
                  for (final spot in touched) _tooltip(l10n, spot.x.toInt()),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: known,
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
      },
    );
  }

  /// Un pas « rond » (1, 2 ou 5 × 10ⁿ) au moins égal à [raw].
  static double _niceStep(double raw) {
    if (raw <= 1) return 1;
    var magnitude = 1.0;
    while (magnitude * 10 <= raw) {
      magnitude *= 10;
    }
    for (final m in const [1.0, 2.0, 5.0, 10.0]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10 * magnitude;
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
