import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

// La sur-couche d'encaissement est passée en offline-first : l'écriture transite
// par [FinanceOfflineBloc] (RecordLocalPayment → outbox) et le succès allume la
// pastille via [SyncStatusCubit.notifyLocalWrite]. On pilote les états offline
// à la main via un StreamController.
class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

final _request = PaymentsCreateRequested(
  studentId: 's1',
  academicYearId: 'y1',
  amounts: MoneyBag.of(const [Money(700000, 'CDF')]),
  payerFirstName: 'Paul',
  payerLastName: 'Mukendi',
  payerMiddleName: null,
  allocations: const [
    CreatePaymentAllocationInput(
      studentChargeId: 'c1',
      feeCode: 'TUITION',
      studentChargeLabel: 'Frais',
      amountInCents: 700000,
      currency: 'CDF',
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockFinanceOfflineBloc bloc;
  late _MockSyncStatusCubit syncCubit;
  late StreamController<FinanceOfflineState> states;

  setUp(() {
    bloc = _MockFinanceOfflineBloc();
    states = StreamController<FinanceOfflineState>.broadcast();
    whenListen(
      bloc,
      states.stream,
      initialState: const FinanceOfflineInitial(),
    );

    syncCubit = _MockSyncStatusCubit();
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    when(() => syncCubit.notifyLocalWrite()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await states.close();
  });

  Future<FacturationCollectOutcome?> open(
    WidgetTester tester, {
    List<FacturationConfirmAllocationGroup>? allocations,
  }) async {
    FacturationCollectOutcome? outcome;
    await tester.pumpWidget(
      // Le cubit de synchro est fourni AU-DESSUS de MaterialApp (comme à la
      // racine en prod) pour que la modale, poussée sur le root navigator, le
      // trouve via context.read.
      BlocProvider<SyncStatusCubit>.value(
        value: syncCubit,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  outcome = await showFacturationCreatePaymentConfirmDialog(
                    context,
                    financeOfflineBloc: bloc,
                    totalLabel: '7 000 CDF',
                    studentName: 'Kabeya Junior',
                    payerName: 'Mukendi Paul',
                    payerPhone: '+243816939060',
                    request: _request,
                    allocations:
                        allocations ??
                        const [
                          // Une nature d'une seule tranche : pas d'enfant, la
                          // ligne EST la tranche (GE-5).
                          FacturationConfirmAllocationGroup(
                            label: 'Frais de scolarité',
                            amount: '7 000 CDF',
                          ),
                        ],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return outcome;
  }

  testWidgets('étape 1 : indicateur, titre, phrase, répartition, actions', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Confirmation'), findsWidgets); // indicateur + eyebrow
    expect(find.text('Résultat'), findsOneWidget); // pastille étape 2
    expect(find.text('Encaisser 7 000 CDF ?'), findsOneWidget);
    expect(find.textContaining('Kabeya Junior'), findsOneWidget);
    expect(find.text('Frais de scolarité'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Confirmer'), findsOneWidget);
  });

  testWidgets('GE-5 : les tranches sont listées SOUS le nom de leur nature', (
    tester,
  ) async {
    // Le caissier valide une répartition. Ne montrer que « Minerval
    // 120 000 » lui ferait signer une ventilation qu'il n'a pas vue — et
    // c'est elle, pas le total, qui figurera sur la note de perception.
    await open(
      tester,
      allocations: const [
        FacturationConfirmAllocationGroup(
          label: 'Minerval · 3 tranches',
          amount: '120 000 FC',
          items: [
            FacturationConfirmAllocationItem(
              label: 'Minerval — 1/3 (T1)',
              amount: '50 000 FC',
            ),
            FacturationConfirmAllocationItem(
              label: 'Minerval — 2/3 (T2)',
              amount: '50 000 FC',
            ),
            FacturationConfirmAllocationItem(
              label: 'Minerval — 3/3 (T3)',
              amount: '20 000 FC',
            ),
          ],
        ),
      ],
    );

    expect(find.text('Minerval · 3 tranches'), findsOneWidget);
    expect(find.text('120 000 FC'), findsWidgets);
    expect(find.text('Minerval — 1/3 (T1)'), findsOneWidget);
    expect(find.text('Minerval — 2/3 (T2)'), findsOneWidget);
    expect(find.text('Minerval — 3/3 (T3)'), findsOneWidget);
    expect(find.text('20 000 FC'), findsOneWidget);
  });

  testWidgets('une nature d\'une seule tranche ne se redouble pas', (
    tester,
  ) async {
    await open(
      tester,
      allocations: const [
        FacturationConfirmAllocationGroup(
          label: 'Frais d\'examen (OM2)',
          amount: '30 000 FC',
        ),
      ],
    );

    expect(find.text('Frais d\'examen (OM2)'), findsOneWidget);
    expect(find.text('30 000 FC'), findsWidgets);
  });

  testWidgets('« Modifier » ferme la modale', (tester) async {
    await open(tester);
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('Encaisser 7 000 CDF ?'), findsNothing);
  });

  testWidgets('échec offline → écran erreur (enregistrement local)', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Confirmer'));
    await tester.pump(); // phase processing (setState local)
    states.add(const FinanceOfflineError('boom'));
    await tester.pump(); // applique l'échec
    await tester.pump();

    expect(find.text('Échec de l\'encaissement'), findsOneWidget);
    expect(find.text('Échec de l\'enregistrement local'), findsOneWidget);
    expect(find.textContaining('Code incident'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('« Confirmer » → succès pending-sync : reçu + note + pastille', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Confirmer'));
    await tester.pump(); // phase processing
    states.add(const FinanceOfflinePaymentPendingSync('pay-42'));
    await tester.pump(); // applique le succès
    await tester.pump(const Duration(milliseconds: 600)); // halo/anim

    // Le succès pending-sync a rafraîchi la pastille globale (preuve que
    // _confirm() a dispatché RecordLocalPayment puis reçu l'état pending-sync).
    verify(() => syncCubit.notifyLocalWrite()).called(1);

    expect(find.text('Paiement enregistré'), findsOneWidget);
    expect(
      find.text('Paiement enregistré — en attente de synchronisation'),
      findsOneWidget,
    );
    expect(find.textContaining('Reçu n°'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
  });

  // B-9 — cette modale n'a aucun champ, mais elle s'ouvre PAR-DESSUS la saisie
  // d'encaissement : c'est celle du lot pour qui le clavier a le plus de
  // chances d'être déjà levé. `Dialog` ajoute alors les `viewInsets` à son
  // `insetPadding`, et il ne reste qu'une poignée de dp pour un bandeau
  // d'étapes et un pied à deux actions.
  testWidgets('téléphone en PAYSAGE, clavier déjà levé : rien ne déborde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(731, 411);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await open(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloDialogBody), findsOneWidget);
  });

  /// Le dernier écran avant d'engager l'argent doit montrer le numéro tel
  /// qu'il partira : c'est le seul endroit où le guichetier peut encore relire
  /// ce qu'il a tapé, et le versement est append-only — rien ne se corrige
  /// après. Hors de la phrase récapitulative, sur sa propre ligne : noyé
  /// dedans, il ne se relirait pas.
  testWidgets('l\'étape de confirmation montre le numéro du payeur', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('+243816939060'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
  });
}
