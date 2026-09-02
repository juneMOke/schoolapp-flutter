import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
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

/// LA CONTRE-ÉPREUVE de l'encaissement groupé (GE-7).
///
/// Tout le chantier repose sur une affirmation : **la requête qui part d'une
/// saisie groupée est identique à celle qu'aurait produite une saisie tranche
/// par tranche**. Elle est vraie par construction — le groupe pilote les mêmes
/// entrées — et les tests d'unité la rendent plausible. Ce fichier la prouve sur
/// la requête elle-même, qui est la seule chose que le serveur verra.
///
/// C'est le genre d'affirmation qui se révèle fausse six mois plus tard, sur un
/// cas de bord, quand un `fee_tariff_id` manque et que le serveur répond
/// `AMBIGUOUS_FEE_CODE` — un refus **terminal**, qu'aucune attente ne corrige.
void main() {
  late _MockFinanceOfflineBloc offline;

  setUpAll(() {
    registerFallbackValue(const LoadLocalCharges('stu-1'));
  });

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

  /// Trois tranches d'un même minerval, échéances croissantes.
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
        expectedAmountInCents: 50000,
        amountPaidInCents: 0,
        currency: 'CDF',
        status: StudentChargeStatus.due,
      ),
  ];

  Future<void> ouvrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
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

  /// Le versement écrit en local — ce que le serveur recevra.
  RecordLocalPayment captureDraft() {
    final events = verify(() => offline.add(captureAny())).captured;
    final drafts = events.whereType<RecordLocalPayment>().toList();
    expect(
      drafts,
      hasLength(1),
      reason: 'un seul versement par acte de guichet',
    );
    return drafts.single;
  }

  /// Le champ « Montant réglé » de la NATURE.
  ///
  /// Ciblé par son intitulé, jamais par `TextField.first` : le premier champ de
  /// la page est celui du payeur, et un montant tapé là s'en va nulle part —
  /// l'écran garde alors la valeur d'avant et le test lit un chiffre juste pour
  /// une raison fausse.
  Finder champDuGroupe() =>
      find.widgetWithText(TextField, 'Montant réglé').first;

  Future<void> encaisser(WidgetTester tester) async {
    final cta = find.byWidgetPredicate(
      (w) =>
          w is EteeloButton &&
          w.icon == Icons.account_balance_wallet_outlined &&
          w.onPressed != null,
    );
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    // `pump`, jamais `pumpAndSettle` : la popin entre en traitement et son
    // indicateur tourne tant que le bloc n'a pas acquitté — ce qu'un bloc mocké
    // ne fera jamais. L'écriture, elle, est dispatchée de façon synchrone : un
    // seul battement suffit à l'observer.
    await tester.pump();
  }

  /// Ce qu'on attend sur le fil, quel que soit le CHEMIN de saisie.
  void attendreLaVentilation(RecordLocalPayment recorded) {
    final allocations = recorded.draft.allocations;

    expect(allocations, hasLength(3));
    // Une imputation PAR CRÉANCE, chacune avec SA ligne de grille : c'est ce
    // qui rend la ventilation légale depuis la V94 du serveur.
    expect(allocations.map((a) => a.studentChargeId).toList(), [
      'sc-1',
      'sc-2',
      'sc-3',
    ]);
    expect(
      allocations.map((a) => a.feeTariffId).toList(),
      ['tar-1', 'tar-2', 'tar-3'],
      reason: 'un fee_tariff_id manquant ⇒ AMBIGUOUS_FEE_CODE, terminal',
    );
    // La cascade : les deux premières soldées, le reste sur la troisième.
    expect(allocations.map((a) => a.amountInCents).toList(), [
      50000,
      50000,
      20000,
    ]);
    expect(allocations.every((a) => a.currency == 'CDF'), isTrue);
    // L'invariant du lot, sur la requête : la somme retombe sur le montant tapé.
    expect(allocations.fold<int>(0, (sum, a) => sum + a.amountInCents), 120000);
  }

  testWidgets('saisie GROUPÉE : une nature, un montant, trois imputations', (
    tester,
  ) async {
    await ouvrir(tester);

    // Le caissier coche la nature, puis corrige à ce que le parent règle.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.enterText(champDuGroupe(), '1200');
    await tester.pumpAndSettle();

    await encaisser(tester);

    attendreLaVentilation(captureDraft());
  });

  testWidgets('saisie TRANCHE PAR TRANCHE : la MÊME requête, au centime près', (
    tester,
  ) async {
    // Le cœur de la contre-épreuve. Si les deux chemins divergeaient, le
    // groupement cesserait d'être une affordance de saisie pour devenir une
    // seconde façon d'écrire de l'argent.
    await ouvrir(tester);

    await tester.tap(find.text('Détailler les tranches'));
    await tester.pumpAndSettle();

    final lignes = find.byType(FacturationCreatePaymentChargeAllocationLine);
    expect(lignes, findsNWidgets(3));

    for (final (index, montant) in ['500', '500', '200'].indexed) {
      final coche = find
          .descendant(of: lignes.at(index), matching: find.byType(InkWell))
          .first;
      await tester.ensureVisible(coche);
      await tester.pumpAndSettle();
      await tester.tap(coche);
      await tester.pumpAndSettle();

      final champ = find
          .descendant(of: lignes.at(index), matching: find.byType(TextField))
          .first;
      await tester.enterText(champ, montant);
      await tester.pumpAndSettle();
    }

    await encaisser(tester);

    attendreLaVentilation(captureDraft());
  });

  testWidgets(
    'une nature partiellement réglée n\'envoie PAS d\'imputation vide',
    (tester) async {
      // La cascade laisse à zéro les tranches qu'elle n'atteint pas ; elles ne
      // doivent pas partir. Un versement porteur d'imputations vides serait
      // refusé, et le refus arriverait après que l'argent soit dans le tiroir.
      await ouvrir(tester);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.enterText(champDuGroupe(), '300');
      await tester.pumpAndSettle();

      await encaisser(tester);

      final allocations = captureDraft().draft.allocations;
      expect(allocations, hasLength(1));
      expect(allocations.single.studentChargeId, 'sc-1');
      expect(allocations.single.amountInCents, 30000);
    },
  );

  testWidgets('« Tout solder » sur la nature solde ses trois tranches', (
    tester,
  ) async {
    await ouvrir(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await encaisser(tester);

    final allocations = captureDraft().draft.allocations;
    expect(allocations.map((a) => a.amountInCents).toList(), [
      50000,
      50000,
      50000,
    ]);
  });
}
