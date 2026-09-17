import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_group_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

class _FakePayerRepo implements FinanceOfflineRepository {
  @override
  Future<Either<Failure, List<LocalPayerIdentity>>> getPayerSuggestions(
    String studentId, {
    int limit = 8,
  }) async => const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('hors périmètre de cette page');
}

/// TESTS DE CARACTÉRISATION — lot R0 du chantier de refonte.
///
/// Ils n'ajoutent aucun comportement : ils **épinglent celui d'aujourd'hui**,
/// sur les chemins que la mesure de couverture a trouvés nus et qui vont
/// déménager en R3/R4/R5.
///
/// Ce que la mesure disait (couverture de la page à `e67ba6c2`, 399/480) :
///
/// - `_onSettleAll` (411-418) — intégralement nu ;
/// - `_onGroupSettleAll` (452-457) — intégralement nu ;
/// - `_onGroupToggle` (441) — la branche « décocher » nue ;
/// - `_lineOf` (578-589) — la branche d'ÉCRÊTAGE nue, celle qui refuse
///   d'imputer au-delà du restant et fabrique la monnaie à rendre.
///
/// ⚠️ **Les assertions évitent de parier sur l'écriture des nombres.** Deux
/// échecs du lot précédent venaient d'une attente sur le rendu (`60000` contre
/// `60000.00`), pas d'un défaut. On capture donc la valeur que l'écran pose
/// lui-même, puis on prouve qu'elle revient.
final _usdVersCdf = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 1666670000,
  effectiveFrom: DateTime.utc(2026, 1, 1),
  divergenceBandBp: 200,
);

void main() {
  late _MockFinanceOfflineBloc offline;

  setUp(() {
    offline = _MockFinanceOfflineBloc();
    when(() => offline.state).thenReturn(const FinanceOfflineInitial());
    final repo = _FakePayerRepo();
    getIt.registerFactory<PayerSearchBloc>(
      () => PayerSearchBloc(
        suggestions: GetPayerSuggestionsUseCase(repo),
        search: SearchPayersUseCase(repo),
      ),
    );
  });

  tearDown(() async => getIt.reset());

  StudentCharge charge(String id, String currency, int cents) => StudentCharge(
    id: id,
    studentId: 'stu-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 'tar-$id',
    feeCode: 'MINERVAL',
    label: 'Minerval $id',
    expectedAmountInCents: cents.toDouble(),
    amountPaidInCents: 0,
    currency: currency,
    status: StudentChargeStatus.due,
  );

  /// Trois tranches d'une même nature — c'est ce qui la rend repliable.
  List<StudentCharge> tranches() => [
    for (final (index, code) in ['T1', 'T2', 'T3'].indexed)
      StudentCharge(
        id: 'sc-${index + 1}',
        studentId: 'stu-1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        schoolLevelGroupId: 'grp-1',
        feeTariffId: 'tar-${index + 1}',
        feeTariffCode: code,
        feeCode: 'TUITION',
        label: 'Minerval — ${index + 1}/3',
        expectedAmountInCents: 5000,
        amountPaidInCents: 0,
        currency: 'USD',
        status: StudentChargeStatus.due,
      ),
  ];

  Future<void> ouvrir(
    WidgetTester tester,
    List<StudentCharge> charges, {
    List<ExchangeRate> rates = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
            rates: rates,
            now: DateTime.utc(2026, 9, 16, 8),
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Kevin',
              lastName: 'Makela',
              surname: 'Mbuyi',
              levelName: '5e A',
              levelGroupName: 'Primaire',
              studentCharges: charges,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapoter(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
    await tester.tap(cible);
    await tester.pumpAndSettle();
  }

  Future<void> saisir(WidgetTester tester, Finder champ, String texte) async {
    await tester.ensureVisible(champ);
    await tester.pumpAndSettle();
    await tester.enterText(champ, texte);
    await tester.pumpAndSettle();
  }

  String valeur(WidgetTester tester, Finder champ) =>
      tester.widget<TextField>(champ).controller?.text ?? '';

  // ── Une TRANCHE ────────────────────────────────────────────────────────────

  Finder ligneDeTranche(int index) =>
      find.byType(FacturationCreatePaymentChargeAllocationLine).at(index);

  Finder champsDeTranche(int index) => find.descendant(
    of: ligneDeTranche(index),
    matching: find.byType(TextField),
  );

  Future<void> cocherLaTranche(WidgetTester tester, int index) => tapoter(
    tester,
    find
        .descendant(of: ligneDeTranche(index), matching: find.byType(InkWell))
        .first,
  );

  /// ⚠️ `TextButton` : la nature porte le MÊME libellé sur un `OutlinedButton`.
  /// Viser le texte seul frapperait l'un en croyant frapper l'autre.
  Future<void> toutSolderLaTranche(WidgetTester tester, int index) => tapoter(
    tester,
    find.descendant(
      of: ligneDeTranche(index),
      matching: find.widgetWithText(TextButton, 'Tout solder'),
    ),
  );

  // ── Une NATURE ─────────────────────────────────────────────────────────────

  Finder ligneDeNature() =>
      find.byType(FacturationCreatePaymentChargeGroupLine);

  Finder champDeNature() =>
      find.widgetWithText(TextField, 'Montant réglé').first;

  Future<void> cocherLaNature(WidgetTester tester) => tapoter(
    tester,
    find.descendant(of: ligneDeNature(), matching: find.byType(Checkbox)),
  );

  Future<void> toutSolderLaNature(WidgetTester tester) => tapoter(
    tester,
    find.descendant(
      of: ligneDeNature(),
      matching: find.widgetWithText(OutlinedButton, 'Tout solder'),
    ),
  );

  /// La devise se choisit au niveau de la NATURE — une puce, pas le segment
  /// d'une tranche.
  Future<void> reglerLaNatureEnFrancs(WidgetTester tester) => tapoter(
    tester,
    find.descendant(
      of: ligneDeNature(),
      matching: find.widgetWithText(ChoiceChip, 'FC'),
    ),
  );

  Finder comptoirDeNature() =>
      find.widgetWithText(TextField, 'Reçu en caisse').first;

  Future<void> reglerEnFrancs(WidgetTester tester, int index) => tapoter(
    tester,
    find.descendant(of: ligneDeTranche(index), matching: find.text('FC')),
  );

  // ── Le payeur et le CTA ────────────────────────────────────────────────────

  Finder champParLibelle(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

  /// Le CTA n'est significatif qu'une fois le payeur valide : sans lui, il reste
  /// éteint quoi qu'on saisisse, et l'assertion ne distinguerait rien.
  Future<void> remplirPayeur(WidgetTester tester) async {
    await tester.enterText(champParLibelle('Nom'), 'Ngalula');
    await tester.enterText(champParLibelle('Prénom'), 'Sarah');
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(EteeloPhoneInput),
        matching: find.byType(TextField),
      ),
      '816939060',
    );
    await tester.pump();
  }

  bool collectActif(WidgetTester tester) {
    final boutons = tester
        .widgetList<EteeloButton>(find.byType(EteeloButton))
        .where((b) => b.icon == Icons.account_balance_wallet_outlined);
    expect(boutons, hasLength(1));
    return boutons.single.onPressed != null;
  }

  group('« Tout solder »', () {
    testWidgets('sur une tranche, ramène l\'imputé au restant', (tester) async {
      await ouvrir(tester, [charge('1', 'USD', 3000)]);
      await cocherLaTranche(tester, 0);

      // Ce que l'écran pose lui-même en cochant : la référence, sans parier sur
      // son écriture.
      final restant = valeur(tester, champsDeTranche(0).first);
      expect(restant, isNotEmpty);

      await saisir(tester, champsDeTranche(0).first, '10');
      expect(valeur(tester, champsDeTranche(0).first), '10');

      await toutSolderLaTranche(tester, 0);

      expect(valeur(tester, champsDeTranche(0).first), restant);
    });

    testWidgets('sur une nature, ramène le montant au plafond', (tester) async {
      await ouvrir(tester, tranches());
      await cocherLaNature(tester);

      final plafond = valeur(tester, champDeNature());
      expect(plafond, isNotEmpty);

      await saisir(tester, champDeNature(), '20');
      expect(valeur(tester, champDeNature()), '20');

      await toutSolderLaNature(tester);

      expect(valeur(tester, champDeNature()), plafond);
    });
  });

  group('décocher une nature', () {
    testWidgets('la vide : plus de champ, et plus rien à encaisser', (
      tester,
    ) async {
      // ⚠️ On ne peut PAS prouver le vidage en relisant le champ : il est masqué
      // quand la nature est décochée, et le re-cocher rappelle
      // `_onGroupToggle(true)`, qui réécrit le plafond — l'assertion passerait
      // ou échouerait pour une raison sans rapport avec `clear()`.
      //
      // La conséquence observable du vidage, c'est qu'il ne reste rien à
      // encaisser.
      await ouvrir(tester, tranches());
      await remplirPayeur(tester);
      await cocherLaNature(tester);
      await saisir(tester, champDeNature(), '7');

      expect(collectActif(tester), isTrue);

      await cocherLaNature(tester);

      expect(find.widgetWithText(TextField, 'Montant réglé'), findsNothing);
      expect(collectActif(tester), isFalse);
    });
  });

  group('écrêtage', () {
    testWidgets(
      'poser plus que le restant n\'impute pas au-delà, et rend la monnaie',
      (tester) async {
        // 30 $ dus, réglés en francs à 1 666,67. Le parent pose bien plus que
        // nécessaire : l'imputation ne doit pas dépasser le restant, et le
        // surplus repart avec lui.
        await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
        await cocherLaTranche(tester, 0);

        final restant = valeur(tester, champsDeTranche(0).first);

        await reglerEnFrancs(tester, 0);
        await saisir(tester, champsDeTranche(0).last, '999999');

        // L'imputé reste au restant — jamais au-delà.
        expect(valeur(tester, champsDeTranche(0).first), restant);
        // Et l'écran dit que du cash repart avec le parent.
        expect(find.textContaining('Monnaie à rendre'), findsOneWidget);
      },
    );

    testWidgets(
      'poser plus que le plafond d\'une NATURE ne l\'impute pas au-delà',
      (tester) async {
        // Dernière ligne de la famille B laissée nue par la première mesure de
        // R0 : la branche d'écrêtage de `_onGroupTenderEdited`. L'écrêtage de la
        // TRANCHE était couvert, celui de la NATURE ne l'était pas.
        //
        // Trois tranches de 50 $ : la nature plafonne à 150 $. Le parent pose
        // une somme en francs qui, convertie, dépasserait largement ce plafond
        // (999 999 FC à 1 666,67 valent ~600 $).
        await ouvrir(tester, tranches(), rates: [_usdVersCdf]);
        await cocherLaNature(tester);

        final plafond = valeur(tester, champDeNature());
        expect(plafond, isNotEmpty);

        await reglerLaNatureEnFrancs(tester);
        await saisir(tester, comptoirDeNature(), '999999');

        // L'imputation reste au plafond : le surplus repart avec le parent, il
        // ne fabrique pas un trop-perçu que personne n'a décidé.
        expect(valeur(tester, champDeNature()), plafond);
      },
    );
  });
}
