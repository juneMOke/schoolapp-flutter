import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// L'encaissement est devenu une PAGE : ce qui était garanti par une popin —
/// on n'en sort pas par mégarde, et la fiche n'est rafraîchie qu'après un vrai
/// encaissement — doit maintenant tenir sur une route.
///
/// Deux propriétés y répondent, et elles sont testées ici parce qu'aucune autre
/// suite ne voit la page dans une pile de navigation :
/// - la flèche de retour passe par la confirmation de perte de saisie ;
/// - la page ne rend `true` (le signal de rafraîchissement de la fiche) qu'au
///   terme d'un encaissement réellement écrit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockFinanceOfflineBloc offline;
  late _MockSyncStatusCubit syncCubit;
  late StreamController<FinanceOfflineState> states;

  setUp(() {
    offline = _MockFinanceOfflineBloc();
    states = StreamController<FinanceOfflineState>.broadcast();
    whenListen(
      offline,
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

  tearDown(() async => states.close());

  const charge = StudentCharge(
    id: 'c-1',
    studentId: 'stu-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 'tar-1',
    feeCode: 'SCOLARITE',
    label: 'Scolarité',
    expectedAmountInCents: 42500,
    amountPaidInCents: 0,
    currency: 'USD',
    status: StudentChargeStatus.due,
  );

  /// Résultat rendu par la page au retour — c'est lui que la fiche lit pour
  /// décider si elle relit ses listes.
  bool? resultat;
  bool sorti = false;

  Future<void> ouvrir(WidgetTester tester) async {
    resultat = null;
    sorti = false;
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      // La pastille de synchro vit au-dessus de `MaterialApp`, comme à la
      // racine en prod : la popin de confirmation, poussée sur le navigateur
      // racine, la lit par `context.read`.
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
                  resultat = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<FinanceOfflineBloc>.value(
                        value: offline,
                        child: const FacturationCreatePaymentView(
                          intent: FacturationCreatePaymentIntent(
                            studentId: 'stu-1',
                            academicYearId: 'ay-1',
                            firstName: 'Daniel',
                            lastName: 'Kabongo',
                            surname: 'Mwamba',
                            levelName: '6e A',
                            levelGroupName: 'Secondaire',
                            studentCharges: [charge],
                          ),
                        ),
                      ),
                    ),
                  );
                  sorti = true;
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Finder champParLibelle(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

  Future<void> remplirPayeur(WidgetTester tester) async {
    await tester.enterText(champParLibelle('Nom'), 'Kabongo');
    await tester.enterText(champParLibelle('Prénom'), 'Joseph');
    await tester.enterText(
      find.descendant(
        of: find.byType(EteeloPhoneInput),
        matching: find.byType(TextField),
      ),
      '816939060',
    );
    await tester.pump();
  }

  Future<void> cocherLaPremiereLigne(WidgetTester tester) async {
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

  Finder leCta() => find.byWidgetPredicate(
    (widget) =>
        widget is EteeloButton &&
        widget.icon == Icons.account_balance_wallet_outlined,
  );

  Future<void> revenir(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('la flèche de retour ne quitte pas : elle demande d\'abord si '
      'la saisie peut être perdue', (tester) async {
    await ouvrir(tester);
    await remplirPayeur(tester);

    await revenir(tester);

    expect(find.text('Fermer l\'encaissement ?'), findsOneWidget);
    // Refuser rend la main à la saisie, telle qu'elle était.
    await tester.tap(find.text('Continuer la saisie'));
    await tester.pumpAndSettle();

    expect(find.text('Fermer l\'encaissement ?'), findsNothing);
    expect(champParLibelle('Nom'), findsOneWidget);
    expect(sorti, isFalse);
  });

  testWidgets('confirmer la sortie quitte la page SANS demander de '
      'rafraîchissement', (tester) async {
    await ouvrir(tester);
    await remplirPayeur(tester);

    await revenir(tester);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(find.byType(FacturationCreatePaymentView), findsNothing);
    expect(sorti, isTrue);
    // `null`, pas `true` : rien n'a été encaissé, la fiche n'a rien à relire.
    expect(resultat, isNull);
  });

  testWidgets('encaissement écrit : la page se retire en rendant le signal de '
      'rafraîchissement', (tester) async {
    await ouvrir(tester);
    await remplirPayeur(tester);
    await cocherLaPremiereLigne(tester);

    await tester.tap(leCta());
    await tester.pumpAndSettle();
    expect(find.text('Confirmer'), findsOneWidget);

    await tester.tap(find.text('Confirmer'));
    await tester.pump();
    // Le paiement est écrit en local puis mis en file : c'est cet état-là que
    // la popin résultat attend, et rien d'autre.
    states.add(const FinanceOfflinePaymentPendingSync('pay-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(find.byType(FacturationCreatePaymentView), findsNothing);
    // Sortie DIRECTE : après un encaissement, la confirmation de perte de
    // saisie n'a plus lieu d'être.
    expect(find.text('Fermer l\'encaissement ?'), findsNothing);
    expect(resultat, isTrue);
  });
}
