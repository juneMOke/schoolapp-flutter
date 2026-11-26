import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_outcome.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_dialog.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_mode_switch.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _fuel = ExpenseType(
  id: 't-fuel',
  code: 'CARBURANT',
  label: 'Carburant',
  shortLabel: 'Carburant',
  icon: 'fuel',
  colorHex: '#D9A24E',
  softColorHex: '#FBF3E3',
  defaultCurrency: 'USD',
  sortOrder: 0,
  active: true,
);

final _today = DateTime(2026, 11, 25);

final _photo = CapturedDocument(
  // Un PNG d'un pixel, décodable.
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
    'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
  mimeType: DocumentMimeType.png,
  source: DocumentCaptureSource.scan,
  sha256Hex: 'abc',
  capturedAt: DateTime.utc(2026, 11, 25),
);

/// DEP-20 — le bon de sortie : déclarer, ou demander pour autorisation.
void main() {
  late ExpenseFormOutcome? outcome;
  late int captures;

  Future<void> open(
    WidgetTester tester, {
    bool canDeclare = true,
    bool visaOnDeclare = false,
    Size size = const Size(1280, 1600),
    double textScale = 1,
  }) async {
    outcome = null;
    captures = 0;
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  outcome = await showExpenseFormDialog(
                    context,
                    seed: ExpenseFormSeed.blank(
                      types: const [_fuel],
                      today: _today,
                    ),
                    types: const [_fuel],
                    rate: null,
                    today: _today,
                    recordedByName: 'La caissière',
                    captureVoucher: canDeclare
                        ? (_) async {
                            captures++;
                            return _photo;
                          }
                        : null,
                    visaOnDeclare: visaOnDeclare,
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.byWidgetPredicate((w) => w is EteeloTextInput && w.label == label),
    matching: find.byType(TextField),
  );

  Future<void> fillContent(WidgetTester tester) async {
    await tester.enterText(field('Intitulé de la dépense'), 'Carburant groupe');
    await tester.enterText(field('Montant'), '45');
    await tester.pump();
  }

  Future<void> chooseDeclaration(WidgetTester tester) async {
    await tester.tap(find.text('Déjà payée'));
    await tester.pumpAndSettle();
  }

  testWidgets('sans le droit de déclarer : le formulaire de la v2', (
    tester,
  ) async {
    await open(tester, canDeclare: false);

    expect(find.byType(ExpenseModeSwitch), findsNothing);
    expect(find.byType(EteeloDateInput), findsOneWidget);
  });

  testWidgets('par défaut : pour autorisation, une demande', (tester) async {
    await open(tester);
    expect(find.byType(ExpenseModeSwitch), findsOneWidget);
    await fillContent(tester);

    await tester.tap(find.text('Enregistrer la dépense').last);
    await tester.pumpAndSettle();

    expect(outcome, isA<ExpenseFormRequest>());
  });

  testWidgets('déclarer sans photo : la modale reste, et le dit', (
    tester,
  ) async {
    await open(tester);
    await chooseDeclaration(tester);
    await fillContent(tester);

    await tester.tap(find.text('Déclarer').last);
    await tester.pumpAndSettle();

    expect(outcome, isNull);
    expect(
      find.text('La photo du bon est obligatoire pour déclarer.'),
      findsOneWidget,
    );
  });

  testWidgets('déclarer avec photo : une déclaration, visée d’office', (
    tester,
  ) async {
    await open(tester, visaOnDeclare: true);
    await chooseDeclaration(tester);
    await fillContent(tester);
    await tester.tap(find.text('Ajouter la photo du bon'));
    await tester.pumpAndSettle();
    expect(captures, 1);
    expect(find.text('Remplacer la photo'), findsOneWidget);

    await tester.tap(find.text('Déclarer').last);
    await tester.pumpAndSettle();

    final declared = (outcome! as ExpenseFormDeclaration).draft;
    expect(declared.amountInCents, 4500);
    expect(declared.voucherContentType, 'image/png');
    expect(declared.visaOnDeclare, isTrue);
    expect(declared.disbursedAt.isAfter(DateTime.now().toUtc()), isFalse);
  });

  testWidgets(
    'en déclaration, pas de seconde date ni d’encart « ne débite rien »',
    (tester) async {
      await open(tester);
      await chooseDeclaration(tester);

      expect(
        find.byWidgetPredicate(
          (w) => w is EteeloDateInput && w.label == 'Payée le',
        ),
        findsOneWidget,
      );
      expect(find.byType(EteeloDateInput), findsOneWidget);
    },
  );

  testWidgets('téléphone 360×740, texte ×1,3 : rien ne déborde', (
    tester,
  ) async {
    await open(tester, size: const Size(360, 740), textScale: 1.3);
    await chooseDeclaration(tester);
    await tester.tap(find.text('Ajouter la photo du bon'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
