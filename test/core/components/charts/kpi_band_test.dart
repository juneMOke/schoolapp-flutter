import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

void main() {
  testWidgets('KpiBand renders all KPI labels', (tester) async {
    const cards = [
      KpiCardData(
        label: 'Total',
        value: 120,
        accent: AppColors.enrollmentStatsAccent,
        accentSoft: AppColors.enrollmentStatsAccentSoft,
        icon: Icons.people,
      ),
      KpiCardData(
        label: 'First',
        value: 40,
        accent: AppColors.enrollmentStatsFirst,
        accentSoft: AppColors.enrollmentStatsFirstSoft,
        icon: Icons.person_add,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KpiBand(cards: cards),
        ),
      ),
    );

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });
}
