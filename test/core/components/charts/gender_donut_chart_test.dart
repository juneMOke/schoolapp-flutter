import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/donut_chart_section.dart';
import 'package:school_app_flutter/core/components/charts/gender_donut_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

void main() {
  testWidgets('GenderDonutChart uses wrap legend on compact width', (
    tester,
  ) async {
    const sections = [
      DonutChartSection(
        label: 'Garcons',
        count: 24,
        percent: 60,
        color: AppColors.enrollmentStatsMale,
      ),
      DonutChartSection(
        label: 'Filles',
        count: 16,
        percent: 40,
        color: AppColors.enrollmentStatsFemale,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: GenderDonutChart(
              sections: sections,
              total: 40,
              centerLabel: 'eleves',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(Tooltip), findsWidgets);
  });
}
