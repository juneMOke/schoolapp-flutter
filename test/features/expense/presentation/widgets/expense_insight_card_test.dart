import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_insight_card.dart';

void main() {
  // Le tour gris et le filet d'accent sont de deux couleurs. Réunis sur une
  // seule `Border` sous un rayon, Flutter lève au `paint()` : « A borderRadius
  // can only be given on borders with uniform colors ».
  testWidgets('se peint sans erreur : tour, filet d\'accent et rayon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseInsightCard(
            icon: Icons.schedule,
            accent: AppColors.feeStatusPartial,
            accentSoft: AppColors.feeStatusPartialSoft,
            title: 'Reste à régler',
            body: '2 dépenses non réglées',
            actionLabel: 'Ouvrir le registre',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Reste à régler'), findsOneWidget);
  });
}
