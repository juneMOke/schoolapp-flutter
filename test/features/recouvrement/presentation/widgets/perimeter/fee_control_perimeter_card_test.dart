import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_perimeter_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de périmètre : de quels frais on parle, pour quelle classe, et
/// quelle situation on cherche.
///
/// Le harnais monte `AppTheme.light` — sans lui, un bouton inline sans
/// `minimumSize` passerait inaperçu (cf. la modale de liste d'appel).
const tGroup = 'grp-1';
const tLevel = 'lvl-1';

const tOptions = [
  SearchLevelOption(
    schoolLevelGroupId: tGroup,
    schoolLevelId: tLevel,
    label: 'Primaire - 1ère année',
  ),
];

const tTariffs = [
  LocalFeeTariff(
    id: 't-1',
    feeCode: 'TUITION',
    label: 'Scolarité',
    amountInCents: 22000,
    currency: 'USD',
  ),
  LocalFeeTariff(
    id: 't-2',
    feeCode: 'REGISTRATION',
    label: 'Inscription',
    amountInCents: 4500000,
    currency: 'CDF',
  ),
];

const tClassroom = OfflineClassroom(
  id: 'cls-1',
  academicYearId: 'ay-1',
  schoolLevelId: tLevel,
  name: '1ère A',
  totalCount: 0,
  femaleCount: 0,
  maleCount: 0,
);

void main() {
  late List<FeeControlSearchRequest> emitted;

  setUp(() => emitted = <FeeControlSearchRequest>[]);

  Future<void> pumpCard(
    WidgetTester tester, {
    List<LocalFeeTariff> tariffs = tTariffs,
    FeeControlIntent? initial,
  }) async {
    tester.view.physicalSize = const Size(1180, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FeeControlPerimeterCard(
              initial: initial,
              options: tOptions,
              tariffs: tariffs,
              classrooms: const [tClassroom],
              isTariffsLoading: false,
              isClassroomsLoading: false,
              feeGridMissing: false,
              tariffsFailed: false,
              isLoading: false,
              onLevelSelected: (_, _) {},
              onSearch: emitted.add,
              onClear: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('les frais sont des pastilles, avec le symbole de leur devise', (
    tester,
  ) async {
    await pumpCard(
      tester,
      initial: const FeeControlIntent(
        schoolLevelGroupId: tGroup,
        schoolLevelId: tLevel,
        feeCode: 'TUITION',
      ),
    );

    expect(find.text('Frais contrôlés'), findsOneWidget);
    // Le symbole rend la conséquence du clic lisible AVANT le clic.
    expect(find.text('\$'), findsOneWidget);
    expect(find.text('FC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cocher un second frais ne remplace pas le premier', (
    tester,
  ) async {
    await pumpCard(
      tester,
      initial: const FeeControlIntent(
        schoolLevelGroupId: tGroup,
        schoolLevelId: tLevel,
        feeCode: 'TUITION',
      ),
    );

    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();

    // L'ordre est celui de la GRILLE, jamais celui des clics.
    expect(emitted.single.feeCodes, ['TUITION', 'REGISTRATION']);
  });

  testWidgets('la dernière pastille ne se décoche pas', (tester) async {
    await pumpCard(
      tester,
      initial: const FeeControlIntent(
        schoolLevelGroupId: tGroup,
        schoolLevelId: tLevel,
        feeCode: 'TUITION',
      ),
    );

    await tester.tap(find.text('Scolarité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();

    expect(emitted.single.feeCodes, ['TUITION']);
  });

  testWidgets('« A payé au moins… » ouvre un montant plancher en mono-devise', (
    tester,
  ) async {
    await pumpCard(
      tester,
      initial: const FeeControlIntent(
        schoolLevelGroupId: tGroup,
        schoolLevelId: tLevel,
        feeCode: 'TUITION',
      ),
    );

    expect(find.byType(CurrencyField), findsNothing);
    await tester.tap(find.text('A payé au moins…'));
    await tester.pumpAndSettle();

    expect(find.byType(CurrencyField), findsOneWidget);
    await tester.enterText(find.byType(CurrencyField), '120');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();

    final request = emitted.single;
    expect(request.statusFilter, FeeControlPaymentFilter.threshold);
    expect(request.threshold?.amountInCents, 12000);
    expect(request.threshold?.currency, 'USD');
  });

  testWidgets(
    'sélection mixte : le plancher cède la place à l\'avertissement',
    (tester) async {
      await pumpCard(
        tester,
        initial: const FeeControlIntent(
          schoolLevelGroupId: tGroup,
          schoolLevelId: tLevel,
          feeCode: 'TUITION',
        ),
      );

      await tester.tap(find.text('Inscription'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A payé au moins…'));
      await tester.pumpAndSettle();

      expect(find.byType(CurrencyField), findsNothing);
      expect(find.textContaining('Ne gardez qu\'une devise'), findsOneWidget);

      // Le segment reste sélectionnable : ce n'est pas une faute de l'avoir
      // choisi. Simplement, aucun plancher ne part.
      await tester.tap(find.text('Rechercher'));
      await tester.pumpAndSettle();
      expect(emitted.single.statusFilter, FeeControlPaymentFilter.threshold);
      expect(emitted.single.threshold, isNull);
    },
  );

  testWidgets('sans frais retenu, on ne cherche pas', (tester) async {
    await pumpCard(tester);

    final button = tester.widget<EteeloButton>(
      find.widgetWithText(EteeloButton, 'Rechercher'),
    );
    expect(button.onPressed, isNull);
  });
}
