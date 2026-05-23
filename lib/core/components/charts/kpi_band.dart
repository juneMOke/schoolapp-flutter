import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Bande horizontale de cartes KPI — scrollable sur mobile, wrap sur desktop.
class KpiBand extends StatelessWidget {
  final List<KpiCardData> cards;

  const KpiBand({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.homeMobileMax;
        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: KpiCard(data: cards[i])),
                if (i < cards.length - 1)
                  const SizedBox(width: AppDimensions.spacingM),
              ],
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                SizedBox(
                  width: AppDimensions.enrollmentStatsKpiCardMobileWidth,
                  child: KpiCard(data: cards[i]),
                ),
                if (i < cards.length - 1)
                  const SizedBox(width: AppDimensions.spacingS),
              ],
            ],
          ),
        );
      },
    );
  }
}