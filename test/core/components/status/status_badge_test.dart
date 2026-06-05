import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, StatusBadge badge) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: badge)),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('filled utilise blancCasse sur un fond sombre', (tester) async {
    await pumpBadge(
      tester,
      StatusBadge.enrollmentCompleted(
        label: 'Complété',
        style: StatusBadgeStyle.filled,
      ),
    );

    final decoration = decorationOf(tester);
    final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
    final text = tester.widget<Text>(find.text('Complété'));

    expect(decoration.color, AppColors.success);
    expect(decoration.borderRadius, AppRadius.brPill);
    expect(decoration.border!.top.color, AppColors.success);
    expect(icon.color, AppColors.blancCasse);
    expect(text.style!.color, AppColors.blancCasse);
  });

  testWidgets('filled utilise noirChaud sur un fond clair', (tester) async {
    await pumpBadge(
      tester,
      StatusBadge.enrollmentFinancialCompleted(
        label: 'Complété (Financier)',
        style: StatusBadgeStyle.filled,
      ),
    );

    final decoration = decorationOf(tester);
    final icon = tester.widget<Icon>(find.byIcon(Icons.payments));
    final text = tester.widget<Text>(find.text('Complété (Financier)'));

    expect(decoration.color, AppColors.orDoux);
    expect(icon.color, AppColors.noirChaud);
    expect(text.style!.color, AppColors.noirChaud);
  });

  testWidgets(
    'filled bascule sur la variante neutre si le contraste est insuffisant',
    (tester) async {
      await pumpBadge(
        tester,
        StatusBadge.enrollmentCancelled(
          label: 'Annulé',
          style: StatusBadgeStyle.filled,
        ),
      );

      final decoration = decorationOf(tester);
      final icon = tester.widget<Icon>(find.byIcon(Icons.cancel));
      final text = tester.widget<Text>(find.text('Annulé'));

      expect(decoration.color, AppColors.surfaceAlt);
      expect(decoration.border!.top.color, AppColors.border);
      expect(icon.color, AppColors.textPrimary);
      expect(text.style!.color, AppColors.textPrimary);
    },
  );
}
