import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// La sur-couche d'encaissement est passée en offline-first : l'écriture transite
// par [FinanceOfflineBloc] (RecordLocalPayment → outbox) et le succès allume la
// pastille via [SyncStatusCubit.notifyLocalWrite]. On pilote les états offline
// à la main via un StreamController.
class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatus>
    implements SyncStatusCubit {}

const _request = PaymentsCreateRequested(
  studentId: 's1',
  academicYearId: 'y1',
  amountInCents: 700000,
  currency: 'CDF',
  payerFirstName: 'Paul',
  payerLastName: 'Mukendi',
  payerMiddleName: null,
  allocations: [
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
      const Stream<SyncStatus>.empty(),
      initialState: SyncStatus.synced,
    );
    when(() => syncCubit.notifyLocalWrite()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await states.close();
  });

  Future<FacturationCollectOutcome?> open(WidgetTester tester) async {
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
                    request: _request,
                    allocations: const [
                      FacturationConfirmAllocationItem(
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
}
