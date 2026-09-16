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

/// TESTS DE CARACTÉRISATION — lot R0, le taux corrigé à la main.
///
/// Deux chemins que la mesure de couverture a trouvés nus, et qui portent tous
/// deux de l'argent :
///
/// - `_rateMicrosOf` (545-553) — la LECTURE du taux corrigé. C'est tout
///   l'arbitrage A4 : le caissier peut imposer son taux, et le guichet doit
///   compter avec celui-là.
/// - `_closeUntouchedRateEditors` (355-360) — au changement de date, une boîte
///   ouverte mais intacte affiche le taux de l'ANCIEN jour pendant que les
///   montants repartent du référentiel du nouveau. Elle doit se refermer.
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

  StudentCharge charge() => const StudentCharge(
    id: 'sc-1',
    studentId: 'stu-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 'tar-1',
    feeCode: 'MINERVAL',
    label: 'Minerval',
    expectedAmountInCents: 3000,
    amountPaidInCents: 0,
    currency: 'USD',
    status: StudentChargeStatus.due,
  );

  Future<void> ouvrir(WidgetTester tester) async {
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
            rates: [_tauxAncien, _tauxRecent],
            now: _maintenant,
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Kevin',
              lastName: 'Makela',
              surname: 'Mbuyi',
              levelName: '5e A',
              levelGroupName: 'Primaire',
              studentCharges: [charge()],
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

  Finder ligne() =>
      find.byType(FacturationCreatePaymentChargeAllocationLine).first;

  Finder champsDeLigne() =>
      find.descendant(of: ligne(), matching: find.byType(TextField));

  String comptoir(WidgetTester tester) =>
      tester.widget<TextField>(champsDeLigne().last).controller?.text ?? '';

  Future<void> cocher(WidgetTester tester) => tapoter(
    tester,
    find.descendant(of: ligne(), matching: find.byType(InkWell)).first,
  );

  Future<void> reglerEnFrancs(WidgetTester tester) =>
      tapoter(tester, find.descendant(of: ligne(), matching: find.text('FC')));

  /// La boîte de taux : fermée elle montre « Modifier », ouverte elle montre le
  /// champ « Taux appliqué ».
  Finder boutonModifier() => find.widgetWithText(TextButton, 'Modifier');
  Finder champDuTaux() => find.widgetWithText(TextField, 'Taux appliqué');

  Future<void> choisirDate(WidgetTester tester, DateTime jour) async {
    tester.widget<EteeloDateInput>(find.byType(EteeloDateInput)).onChanged!(
      jour,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('le taux corrigé à la main commande les montants', (
    tester,
  ) async {
    await ouvrir(tester);
    await cocher(tester);
    await reglerEnFrancs(tester);

    // Au taux du référentiel pour le 16 (2 000,00) : 30 $ valent 60 000 FC.
    final auReferentiel = comptoir(tester);
    expect(auReferentiel, '60000');

    await tapoter(tester, boutonModifier());
    expect(champDuTaux(), findsOneWidget);

    await tester.enterText(champDuTaux(), '2500');
    await tester.pumpAndSettle();

    // Le champ porte bien ce que le caissier a tapé. Assertion volontairement
    // conservée : elle sépare « la saisie n'atteint pas le champ » de « la
    // saisie est lue mais pas appliquée », deux pannes qui se ressemblent de
    // l'extérieur et se corrigent à des endroits opposés.
    expect(tester.widget<TextField>(champDuTaux()).controller?.text, '2500');

    // Discriminateur sans dépendance au formatage : `divergesFor` ne lit QUE
    // `overriddenRates`. 2 500 contre 2 000 fait 25 % d'écart, très au-delà de
    // la bande de 200 points de base — l'avertissement doit donc paraître dès
    // que la correction est entrée dans le règlement.
    expect(
      find.textContaining('s\'écarte de celui de l\'école'),
      findsOneWidget,
    );

    // ⚠️ COMPORTEMENT ACTUEL, épinglé tel quel : le champ comptoir ne bouge
    // PAS. Son texte n'est écrit que par `_reflectTender`, appelé depuis un
    // geste ; le contrôleur de taux, lui, n'écoute qu'un `setState` nu. Ce qui
    // partira en base suit déjà le taux corrigé, mais ce que le caissier lit
    // est resté au taux d'avant.
    //
    // C'est la divergence « affiché ≠ soumis ». Préexistante, hors périmètre de
    // R0 — on la fixe ici pour qu'elle ne puisse pas empirer en silence pendant
    // le chantier, et pour qu'on la voie quand on décidera de la traiter.
    expect(comptoir(tester), auReferentiel);

    // 🔴 ÉCART TROUVÉ PAR R0, épinglé tel quel — ce n'est PAS le comportement
    // souhaitable, c'est celui d'aujourd'hui.
    //
    // Même après un geste qui re-dérive la ligne, le comptaffiché reste au taux
    // du référentiel. Or les trois faits ci-dessus sont établis : le champ porte
    // la correction, `overriddenRates` la contient (l'avertissement de
    // divergence ne s'affiche QUE par elle), et `rateFor` la consulte. Ce qui
    // partira en base via `tendersFor` suit donc le taux corrigé — pas ce que le
    // caissier lit.
    //
    // Divergence « affiché ≠ soumis », préexistante et hors périmètre de R0. Ce
    // test la CLOUE : le jour où elle sera traitée, il échouera, et c'est
    // exactement ce qu'on lui demande.
    await tester.enterText(champsDeLigne().first, '30');
    await tester.pumpAndSettle();

    expect(comptoir(tester), auReferentiel);
  });

  testWidgets(
    'une boîte ouverte mais INTACTE se referme au changement de date',
    (tester) async {
      await ouvrir(tester);
      await cocher(tester);
      await reglerEnFrancs(tester);

      await tapoter(tester, boutonModifier());
      // Ouverte et amorcée au taux du 16 — mais le caissier n'y touche pas.
      expect(champDuTaux(), findsOneWidget);

      await choisirDate(tester, DateTime(2026, 9, 12));

      // Refermée : sinon elle afficherait le taux du 16 pendant que le comptoir
      // compte à celui du 12.
      expect(champDuTaux(), findsNothing);
      expect(boutonModifier(), findsOneWidget);
      // Et les montants ont bien suivi le référentiel du 12 (1 666,67).
      expect(comptoir(tester), '50000.10');
    },
  );

  testWidgets('un taux VRAIMENT corrigé survit au changement de date (A4)', (
    tester,
  ) async {
    await ouvrir(tester);
    await cocher(tester);
    await reglerEnFrancs(tester);

    await tapoter(tester, boutonModifier());
    await tester.enterText(champDuTaux(), '2500');
    await tester.pumpAndSettle();
    await choisirDate(tester, DateTime(2026, 9, 12));

    // La correction est une intention du caissier, pas une valeur dérivée de la
    // date : elle survit, et la boîte reste ouverte.
    //
    // ⚠️ On l'assère sur le CHAMP et sur la DIVERGENCE, jamais sur le comptoir :
    // celui-ci ne reflète pas la correction (cf. l'écart épinglé au test
    // précédent), il ne prouverait donc rien ici.
    expect(champDuTaux(), findsOneWidget);
    expect(tester.widget<TextField>(champDuTaux()).controller?.text, '2500');
    expect(
      find.textContaining('s\'écarte de celui de l\'école'),
      findsOneWidget,
    );
  });
}
