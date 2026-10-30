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

  Future<void> ouvrir(WidgetTester tester) async {
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
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('aucun champ de date à l\'encaissement', (tester) async {
    // Lot C de la continuité des tickets : un versement est daté du jour de sa
    // saisie. Un champ de date, même en lecture seule, laisserait croire qu'on
    // peut encaisser pour un autre jour.
    await ouvrir(tester);

    expect(find.byType(EteeloDateInput), findsNothing);
  });

  testWidgets('sans rien changer, c\'est aujourd\'hui qui part', (
    tester,
  ) async {
    // Non-régression A1 : le chemin par défaut doit rendre exactement ce que
    // produisait l'horodatage automatique — donc `_maintenant`, à l'instant près
    // et non au jour près.
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);

    await encaisser(tester);

    expect(captureDraft().draft.paidAt, _maintenant.toIso8601String());
  });

  testWidgets('le récapitulatif montre la date qui part', (tester) async {
    // Le dernier écran avant d'engager l'argent est le seul endroit où une
    // erreur de jour se rattrape encore — encore faut-il qu'il la montre, et
    // qu'il la lise sur la requête et non sur une copie.
    await ouvrir(tester);
    await cocher(tester);
    await remplirPayeur(tester);
    await tester.pumpAndSettle();

    await ouvrirConfirmation(tester);

    expect(find.textContaining('16 sept. 2026'), findsOneWidget);
  });
}
