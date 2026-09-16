import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
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
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

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

/// LA CONTRE-ÉPREUVE de la date d'encaissement.
///
/// Les autres tests prouvent chacun un maillon : que le champ affiche le bon
/// jour, que le mapper convertit bien un jour en instant. Aucun ne prouve le
/// seul fait qui compte — **que la date désignée au guichet soit celle qui part
/// en base**. Un `DateTime.now()` oublié au site de la requête les laisserait
/// tous verts.
///
/// C'est le genre d'affirmation qu'on croit tenue par construction, et qui se
/// révèle fausse le jour où un versement rattrapé se retrouve daté d'aujourd'hui
/// dans une caisse déjà arrêtée.
final _maintenant = DateTime.utc(2026, 9, 16, 8);

void main() {
  late _MockFinanceOfflineBloc offline;
  late _MockSyncStatusCubit syncCubit;

  setUpAll(() {
    registerFallbackValue(const LoadLocalCharges('stu-1'));
  });

  setUp(() {
    offline = _MockFinanceOfflineBloc();
    when(() => offline.state).thenReturn(const FinanceOfflineInitial());

    syncCubit = _MockSyncStatusCubit();
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    when(() => syncCubit.notifyLocalWrite()).thenAnswer((_) async {});

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
    feeCode: 'TUITION',
    label: 'Minerval',
    expectedAmountInCents: 300000,
    amountPaidInCents: 0,
    currency: 'CDF',
    status: StudentChargeStatus.due,
  );

  Future<void> ouvrir(WidgetTester tester, {DateTime? now}) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: syncCubit,
        child: MultiBlocProvider(
          providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FacturationCreatePaymentView(
              now: now ?? _maintenant,
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
      ),
    );
    await tester.pumpAndSettle();
  }

  EteeloDateInput champDate(WidgetTester tester) =>
      tester.widget<EteeloDateInput>(find.byType(EteeloDateInput));

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

  Future<void> cocher(WidgetTester tester) async {
    final coche = find
        .descendant(
          of: find.byType(FacturationCreatePaymentChargeAllocationLine).first,
          matching: find.byType(InkWell),
        )
        .first;
    await tester.ensureVisible(coche);
    await tester.pumpAndSettle();
    await tester.tap(coche);
    await tester.pumpAndSettle();
  }

  Future<void> choisirDate(WidgetTester tester, DateTime jour) async {
    champDate(tester).onChanged!(jour);
    await tester.pumpAndSettle();
  }

  /// Ouvre la popin de confirmation — sans valider.
  Future<void> ouvrirConfirmation(WidgetTester tester) async {
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
  }

  Future<void> encaisser(WidgetTester tester) async {
    await ouvrirConfirmation(tester);
    await tester.tap(find.text('Confirmer'));
    // `pump`, jamais `pumpAndSettle` : la popin entre en traitement et son
    // indicateur tourne tant que le bloc mocké n'acquitte pas.
    await tester.pump();
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

  testWidgets('la date désignée est CELLE QUI PART en base', (tester) async {
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);
    await choisirDate(tester, DateTime(2026, 9, 12));

    await encaisser(tester);

    // ⚠️ On assère le JOUR, pas l'instant complet. L'heure vient de l'horloge
    // RÉELLE : la popin appelle le mapper sans horloge injectée, et c'est voulu
    // — A1 dit « le jour choisi, à l'heure du geste ». La composition exacte est
    // épinglée à la microseconde par `school_time_test` et le test du mapper ;
    // ici, ce qui doit être prouvé est que le jour désigné arrive jusqu'en base.
    expect(captureDraft().draft.paidAt, startsWith('2026-09-12T'));
  });

  testWidgets('sans rien changer, c\'est aujourd\'hui qui part', (
    tester,
  ) async {
    // Non-régression A1 : le chemin par défaut doit rendre exactement ce que
    // produisait l'horodatage automatique.
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);

    await encaisser(tester);

    expect(captureDraft().draft.paidAt, startsWith('2026-09-16T'));
  });

  testWidgets('le récapitulatif montre la date qui part', (tester) async {
    // Le dernier écran avant d'engager l'argent est le seul endroit où une
    // erreur de jour se rattrape encore — encore faut-il qu'il la montre, et
    // qu'il la lise sur la requête et non sur une copie.
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);
    await choisirDate(tester, DateTime(2026, 9, 12));

    await ouvrirConfirmation(tester);

    expect(find.textContaining('12/09/2026'), findsOneWidget);
  });

  testWidgets('la date est GELÉE pendant un encaissement en vol', (
    tester,
  ) async {
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);

    await ouvrirConfirmation(tester);

    // ⚠️ On assère `readOnly`, jamais en appelant `onChanged` : le rappel
    // court-circuiterait `_pickDate`, où vit RÉELLEMENT le gel
    // (`if (!_interactive) return;`). Un test écrit avec `onChanged` serait vert
    // sur un gel cassé.
    //
    // Et surtout pas `onChanged == null` : la section enveloppe toujours le
    // rappel dans une closure, donc ce champ n'est jamais nul — l'assertion
    // passerait pour une raison fausse.
    expect(champDate(tester).readOnly, isTrue);
  });

  testWidgets('re-confirmer le même jour ne change rien', (tester) async {
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);

    // Le sélecteur rappelle `onChanged` dès qu'on valide, même sans avoir
    // bougé : sans garde d'égalité, tout le recalcul serait rejoué.
    await choisirDate(tester, DateTime(2026, 9, 16));
    await encaisser(tester);

    expect(captureDraft().draft.paidAt, startsWith('2026-09-16T'));
  });

  testWidgets('le jour par défaut SUIT l\'horloge, il n\'est pas figé', (
    tester,
  ) async {
    // Une tablette laissée allumée toute la nuit : la page ne doit pas dater de
    // la veille ce qu'elle encaisse le lendemain.
    await ouvrir(tester, now: DateTime.utc(2026, 9, 16, 23, 30));

    // 23 h 30 UTC = 00 h 30 le 17 à Kinshasa.
    expect(champDate(tester).value, DateTime(2026, 9, 17));
    expect(SchoolTime.today(DateTime.utc(2026, 9, 16, 23, 30)).day, 17);
  });
}
