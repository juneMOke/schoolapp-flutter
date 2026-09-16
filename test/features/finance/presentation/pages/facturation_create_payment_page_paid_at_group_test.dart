import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
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

/// LA BRANCHE QUI CACHAIT LE DÉFAUT.
///
/// Changer la date re-dérive les montants convertis. Pour une NATURE, ce rejeu
/// passe par `_onGroupTenderEdited`, qui recascade sur toutes les tranches — et
/// rien n'interdisait de l'atteindre alors que le caissier venait précisément de
/// ventiler à la main.
///
/// L'état coupable : `groupIsSource == false` (les tranches commandent) mais
/// `tenderIsSource == true` (le comptoir de la nature se croit encore source).
/// Il était **stable et invisible** — le champ qui aurait pu le défaire
/// disparaît de l'écran dès que la nature rend la main.
///
/// Ce test reconstitue ce parcours. Sans la remise à zéro de `tenderIsSource`
/// dans `_handOverToTranches`, il échoue : la ventilation saisie à la main est
/// remplacée par la cascade, et l'argent change de créance sans un mot.
final _tauxAncien = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 1666670000,
  effectiveFrom: DateTime.utc(2026, 1, 1),
  divergenceBandBp: 200,
);
final _tauxRecent = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2000000000,
  effectiveFrom: DateTime.utc(2026, 9, 15),
  divergenceBandBp: 200,
);

final _maintenant = DateTime.utc(2026, 9, 16, 8);

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

  /// Trois tranches d'un même minerval — c'est ce qui en fait une NATURE
  /// repliable, et non trois lignes nues.
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

  Future<void> ouvrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
            now: _maintenant,
            rates: [_tauxAncien, _tauxRecent],
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Kevin',
              lastName: 'Makela',
              surname: 'Mbuyi',
              levelName: '5e A',
              levelGroupName: 'Primaire',
              studentCharges: tranches(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder ligneDeNature() =>
      find.byType(FacturationCreatePaymentChargeGroupLine);

  Future<void> tapoter(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
    await tester.tap(cible);
    await tester.pumpAndSettle();
  }

  Future<void> cocherLaNature(WidgetTester tester) => tapoter(
    tester,
    find.descendant(of: ligneDeNature(), matching: find.byType(Checkbox)),
  );

  Future<void> reglerEnFrancs(WidgetTester tester) => tapoter(
    tester,
    find.descendant(
      of: ligneDeNature(),
      matching: find.widgetWithText(ChoiceChip, 'FC'),
    ),
  );

  Future<void> taperLeComptoirDeLaNature(
    WidgetTester tester,
    String montant,
  ) async {
    final champ = find.widgetWithText(TextField, 'Reçu en caisse').first;
    await tester.ensureVisible(champ);
    await tester.pumpAndSettle();
    await tester.enterText(champ, montant);
    await tester.pumpAndSettle();
  }

  Future<void> detaillerLesTranches(WidgetTester tester) =>
      tapoter(tester, find.text('Détailler les tranches'));

  Finder champImputeDeTranche(int index) => find
      .descendant(
        of: find.byType(FacturationCreatePaymentChargeAllocationLine).at(index),
        matching: find.byType(TextField),
      )
      .first;

  Future<void> taperLImputeDeTranche(
    WidgetTester tester,
    int index,
    String montant,
  ) async {
    final champ = champImputeDeTranche(index);
    await tester.ensureVisible(champ);
    await tester.pumpAndSettle();
    await tester.enterText(champ, montant);
    await tester.pumpAndSettle();
  }

  String valeur(WidgetTester tester, Finder champ) =>
      tester.widget<TextField>(champ).controller?.text ?? '';

  Future<void> choisirDate(WidgetTester tester, DateTime jour) async {
    tester.widget<EteeloDateInput>(find.byType(EteeloDateInput)).onChanged!(
      jour,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'changer la date NE DÉTRUIT PAS une ventilation saisie à la main',
    (tester) async {
      await ouvrir(tester);

      // 1. La nature commande : la cascade répartit 150 $ sur les 3 tranches.
      await cocherLaNature(tester);
      // 2. Le parent règle en francs — conversion au niveau de la NATURE.
      await reglerEnFrancs(tester);
      // 3. Il pose des billets : le comptoir de la nature devient la source.
      await taperLeComptoirDeLaNature(tester, '200000');
      // 4. Le caissier déplie et corrige UNE tranche : les tranches reprennent
      //    la main, et la nature cesse d'être l'unité de règlement.
      await detaillerLesTranches(tester);
      await taperLImputeDeTranche(tester, 0, '10');

      expect(valeur(tester, champImputeDeTranche(0)), '10');

      // 5. Il s'aperçoit qu'il encaisse pour un autre jour.
      await choisirDate(tester, DateTime(2026, 9, 12));

      // La ventilation tient. Sans la remise à zéro de `tenderIsSource` dans
      // `_handOverToTranches`, la cascade de la nature l'aurait réécrite — et
      // l'argent aurait changé de créance sans que rien ne l'annonce.
      expect(valeur(tester, champImputeDeTranche(0)), '10');
    },
  );

  testWidgets(
    'quand la NATURE commande encore, la date re-dérive bien son comptoir',
    (tester) async {
      // La contre-épreuve : la branche corrigée ne doit pas avoir éteint la
      // re-dérivation légitime, celle où la nature EST restée l'unité de
      // règlement.
      await ouvrir(tester);

      await cocherLaNature(tester);
      await reglerEnFrancs(tester);

      // 150 $ au taux du 15 (2 000,00) ⇒ 300 000 FC au comptoir — sans
      // décimales : le champ n'en pose pas quand il n'y en a pas.
      final au16 = valeur(
        tester,
        find.widgetWithText(TextField, 'Reçu en caisse').first,
      );
      expect(au16, '300000');

      await choisirDate(tester, DateTime(2026, 9, 12));

      // Reculé au 12, c'est le taux d'avant (1 666,67) qui vaut.
      final au12 = valeur(
        tester,
        find.widgetWithText(TextField, 'Reçu en caisse').first,
      );
      expect(au12, isNot(au16));
      expect(au12, '250000.50');
    },
  );
}
