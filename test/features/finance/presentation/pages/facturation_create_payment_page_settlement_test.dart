import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
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

/// Le guichet quand le parent règle dans une autre monnaie.
///
/// Ce que ces tests tiennent : **le cas courant ne coûte rien** (aucun taux
/// paramétré ⇒ l'écran d'avant, à l'identique), et dès qu'un taux existe, le
/// caissier voit ce qu'il doit compter — sans jamais perdre de vue ce que le
/// versement éteint.
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

  Future<void> ouvrir(
    WidgetTester tester,
    List<StudentCharge> charges, {
    List<ExchangeRate> rates = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
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
    await tester.pump();
  }

  Future<void> cocher(WidgetTester tester, int index) async {
    final ligne = find
        .byType(FacturationCreatePaymentChargeAllocationLine)
        .at(index);
    final coche = find
        .descendant(of: ligne, matching: find.byType(InkWell))
        .first;
    await tester.ensureVisible(coche);
    await tester.pumpAndSettle();
    await tester.tap(coche);
    await tester.pumpAndSettle();
  }

  bool collectEnabled(WidgetTester tester) {
    final buttons = tester
        .widgetList<EteeloButton>(find.byType(EteeloButton))
        .where((b) => b.icon == Icons.account_balance_wallet_outlined);
    expect(buttons, hasLength(1));
    return buttons.single.onPressed != null;
  }

  Finder champParLibelle(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

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

  Finder ligne(int index) =>
      find.byType(FacturationCreatePaymentChargeAllocationLine).at(index);

  /// Les deux champs d'une ligne : l'imputé d'abord, le comptoir ensuite.
  Finder champsDeLigne(int index) =>
      find.descendant(of: ligne(index), matching: find.byType(TextField));

  String valeurDuChamp(WidgetTester tester, Finder champ) =>
      tester.widget<TextField>(champ).controller?.text ?? '';

  /// « Le parent règle en… » se demande SUR le frais : c'est là que le segment
  /// vit, et il y a donc un segment par ligne cochée.
  Future<void> choisirDevise(
    WidgetTester tester,
    int index,
    String symbole,
  ) async {
    final segment = find.descendant(
      of: ligne(index),
      matching: find.text(symbole),
    );
    await tester.ensureVisible(segment.first);
    await tester.pumpAndSettle();
    await tester.tap(segment.first);
    await tester.pumpAndSettle();
  }

  testWidgets('sans taux paramétré, l’écran est celui d’avant', (tester) async {
    // La V2 est invisible aux écoles qui n'encaissent que dans la devise de
    // leurs frais — c'est ce qui la rend acceptable au guichet.
    await ouvrir(tester, [charge('1', 'USD', 3000)]);
    await cocher(tester, 0);

    expect(find.text('LE PARENT RÈGLE EN'), findsNothing);
    expect(champsDeLigne(0), findsOneWidget);
    expect(find.text('Total à encaisser'), findsOneWidget);
    // Mais l'écran DIT ce qui manque : sans cette ligne, rien ne distingue
    // « cette école n'encaisse qu'en une monnaie » de « la fonction est
    // cassée » — et c'est exactement ce qu'on a cru voir.
    expect(find.textContaining('Aucun taux paramétré'), findsOneWidget);
  });

  testWidgets('tant qu’aucun frais n’est coché, on ne dit rien du tout', (
    tester,
  ) async {
    // Une mention sur un formulaire vide serait du bruit : il n'y a pas encore
    // de question à poser.
    await ouvrir(tester, [charge('1', 'USD', 3000)]);
    expect(find.textContaining('Aucun taux paramétré'), findsNothing);
  });

  testWidgets('cocher un frais pose la question sur CE frais', (tester) async {
    await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
    await cocher(tester, 0);

    expect(find.text('LE PARENT RÈGLE EN'), findsOneWidget);
    // Un seul champ tant qu'on règle dans la devise de la créance.
    expect(champsDeLigne(0), findsOneWidget);
  });

  testWidgets(
    'avec un taux, l’écran ne prétend JAMAIS qu’aucun n’est paramétré',
    (tester) async {
      // Le message le plus trompeur possible : il désigne le paramétrage alors
      // que le taux vient d'arriver et que la bascule est là, sur la ligne. Il
      // s'affichait dès qu'un frais était coché, parce qu'il se mesurait sur les
      // conversions EN COURS et non sur les taux disponibles.
      await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
      await cocher(tester, 0);

      expect(find.textContaining('Aucun taux paramétré'), findsNothing);
    },
  );

  testWidgets(
    'un frais dont la devise n’a aucun taux sortant : là, on le dit',
    (tester) async {
      // Le référentiel porte USD→CDF ; une créance en francs n'a donc rien à
      // proposer, et le guichet doit savoir ce qui lui manque.
      await ouvrir(tester, [charge('1', 'CDF', 9000000)], rates: [_usdVersCdf]);
      await cocher(tester, 0);

      expect(find.textContaining('Aucun taux paramétré'), findsOneWidget);
    },
  );

  testWidgets('tant qu’aucun frais n’est coché, il n’y a rien à demander', (
    tester,
  ) async {
    await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
    expect(find.text('LE PARENT RÈGLE EN'), findsNothing);
  });

  testWidgets(
    'régler en francs ouvre le second champ, rempli par la conversion',
    (tester) async {
      await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
      await cocher(tester, 0);
      await choisirDevise(tester, 0, 'FC');

      // Deux champs : ce qu'on impute, et ce qu'on compte au comptoir.
      expect(champsDeLigne(0), findsNWidgets(2));
      expect(find.text('Reçu en caisse'), findsOneWidget);
      // 30,00 $ à 1 666,67 : le comptoir doit compter 50 000,10 FC.
      expect(valeurDuChamp(tester, champsDeLigne(0).last), '50000.10');
      // Et le taux se lit sur la ligne qu'il concerne.
      expect(find.textContaining('666,67'), findsWidgets);
    },
  );

  testWidgets('taper l’imputé remplit le comptoir', (tester) async {
    await ouvrir(tester, [charge('1', 'USD', 6000)], rates: [_usdVersCdf]);
    await cocher(tester, 0);
    await choisirDevise(tester, 0, 'FC');

    await tester.enterText(champsDeLigne(0).first, '20');
    await tester.pumpAndSettle();

    expect(valeurDuChamp(tester, champsDeLigne(0).last), '33333.40');
  });

  testWidgets(
    'taper le comptoir remplit l’imputé — vers le BAS, et la monnaie repart',
    (tester) async {
      await ouvrir(tester, [charge('1', 'USD', 6000)], rates: [_usdVersCdf]);
      await cocher(tester, 0);
      await choisirDevise(tester, 0, 'FC');

      // Le parent pose 50 000 FC. À 1 666,67, cela éteint 29,99 \$ et non 30,00
      // : imputer davantage éteindrait ce que personne n'a posé.
      await tester.enterText(champsDeLigne(0).last, '50000');
      await tester.pumpAndSettle();

      expect(valeurDuChamp(tester, champsDeLigne(0).first), '29.99');
      expect(find.textContaining('Monnaie à rendre'), findsOneWidget);
    },
  );

  testWidgets('le champ que le caissier tape n’est jamais réécrit', (
    tester,
  ) async {
    // Le piège de deux champs couplés : recalculer les deux à chaque frappe
    // ferait bouger le montant sous les doigts, et le caissier ne saurait plus
    // ce qu'il a tapé.
    await ouvrir(tester, [charge('1', 'USD', 6000)], rates: [_usdVersCdf]);
    await cocher(tester, 0);
    await choisirDevise(tester, 0, 'FC');

    await tester.enterText(champsDeLigne(0).last, '50000');
    await tester.pumpAndSettle();

    expect(valeurDuChamp(tester, champsDeLigne(0).last), '50000');
  });

  testWidgets('la barre annonce le perçu, et l’imputé passe dessous', (
    tester,
  ) async {
    await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
    await cocher(tester, 0);
    await choisirDevise(tester, 0, 'FC');

    // Le caissier compte des billets : c'est ce chiffre-là qui est en tête.
    expect(find.text('À percevoir'), findsOneWidget);
    expect(find.text('Total à encaisser'), findsNothing);
    // Et ce que le versement éteint reste lisible, en second.
    expect(find.textContaining('impute'), findsOneWidget);
    expect(find.textContaining('30,00'), findsWidgets);
  });

  testWidgets('revenir à la devise du frais referme le second champ', (
    tester,
  ) async {
    await ouvrir(tester, [charge('1', 'USD', 3000)], rates: [_usdVersCdf]);
    await cocher(tester, 0);
    await choisirDevise(tester, 0, 'FC');
    await choisirDevise(tester, 0, r'$');

    expect(champsDeLigne(0), findsOneWidget);
    expect(find.text('Total à encaisser'), findsOneWidget);
    // L'imputation ne bouge pas : elle est ce que le caissier a décidé
    // d'éteindre, pas une conséquence des billets sortis.
    expect(valeurDuChamp(tester, champsDeLigne(0).first), '30');
  });

  testWidgets(
    'deux frais, deux monnaies : chacun garde la sienne et le tiroir les '
    'compte séparément',
    (tester) async {
      await ouvrir(
        tester,
        [charge('1', 'USD', 3000), charge('2', 'USD', 2000)],
        rates: [_usdVersCdf],
      );
      await cocher(tester, 0);
      await cocher(tester, 1);
      await choisirDevise(tester, 0, 'FC');

      // Le premier convertit, le second non : deux lignes, deux régimes.
      expect(champsDeLigne(0), findsNWidgets(2));
      expect(champsDeLigne(1), findsOneWidget);
      // Le tiroir ne somme pas deux monnaies : il les pose côte à côte. Le
      // franc s'affiche sans décimale — 50 000,10 se lit « 50 000 FC ».
      expect(find.textContaining('50\u00A0000'), findsWidgets);
      expect(find.textContaining('20,00'), findsWidgets);
    },
  );

  testWidgets(
    'quoi que le caissier tape, le couple perçu/imputé reste encaissable',
    (tester) async {
      // L'ancien écran éteignait le CTA sur un « montant compté » hors
      // tolérance. Ce cas n'existe plus : les deux champs se déduisent l'un de
      // l'autre, et l'écart d'arrondi part en monnaie rendue au lieu de casser
      // l'invariant.
      await ouvrir(tester, [charge('1', 'USD', 6000)], rates: [_usdVersCdf]);
      await remplirPayeur(tester);
      await cocher(tester, 0);
      await choisirDevise(tester, 0, 'FC');

      await tester.enterText(champsDeLigne(0).last, '50000');
      await tester.pumpAndSettle();
      expect(collectEnabled(tester), isTrue);

      await tester.enterText(champsDeLigne(0).last, '12345');
      await tester.pumpAndSettle();
      expect(collectEnabled(tester), isTrue);
    },
  );

  testWidgets('un versement mixte laisse chaque frais dans son unité', (
    tester,
  ) async {
    await ouvrir(
      tester,
      [charge('1', 'USD', 3000), charge('2', 'CDF', 9000000)],
      rates: [_usdVersCdf],
    );
    await cocher(tester, 0);
    await cocher(tester, 1);
    await choisirDevise(tester, 0, 'FC');

    // Seule la créance en dollars a quelque chose à convertir : celle en francs
    // est déjà dans la monnaie du comptoir, et n'offre donc aucun choix.
    expect(champsDeLigne(0), findsNWidgets(2));
    expect(champsDeLigne(1), findsOneWidget);
    expect(
      find.descendant(of: ligne(1), matching: find.text('LE PARENT RÈGLE EN')),
      findsNothing,
    );
  });
}
