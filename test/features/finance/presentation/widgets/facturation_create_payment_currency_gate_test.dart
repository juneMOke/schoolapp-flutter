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
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockPaymentsBloc extends MockBloc<PaymentsEvent, PaymentsState>
    implements PaymentsBloc {}

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
      throw UnimplementedError('hors périmètre de cette modale');
}

/// Un versement ne peut pas mêler deux devises — **pour l'instant**.
///
/// Le contrat de push porte encore un montant scalaire (D2 n'est pas livré), et
/// le payload est reconstruit depuis la table au moment de l'envoi. Un versement
/// mixte partirait donc avec un total unique, que le serveur refuserait en
/// `ALLOCATION_SUM_MISMATCH` — désormais vérifié devise par devise. Le paiement
/// basculerait en `SYNC_ERROR` : argent physiquement reçu, reçu déjà imprimé,
/// bloqué hors du grand-livre.
///
/// Avant cette garde, rien n'empêchait le guichet de composer un tel versement,
/// et le bandeau annonçait « 9 042 500 USD » pour 425,00 $ + 90 000 FC.
void main() {
  late _MockPaymentsBloc payments;
  late _MockFinanceOfflineBloc offline;

  setUp(() {
    payments = _MockPaymentsBloc();
    offline = _MockFinanceOfflineBloc();
    when(() => payments.state).thenReturn(const PaymentsState());
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

  StudentCharge charge(String id, String feeCode, String currency, int cents) =>
      StudentCharge(
        id: id,
        studentId: 'stu-1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        schoolLevelGroupId: 'grp-1',
        feeTariffId: 'tar-$id',
        feeCode: feeCode,
        label: '$feeCode $id',
        expectedAmountInCents: cents.toDouble(),
        amountPaidInCents: 0,
        currency: currency,
        status: StudentChargeStatus.due,
      );

  Future<void> ouvrir(WidgetTester tester, List<StudentCharge> charges) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PaymentsBloc>.value(value: payments),
          BlocProvider<FinanceOfflineBloc>.value(value: offline),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentDialogView(
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Daniel',
              lastName: 'Kabongo',
              surname: 'Mwamba',
              levelName: '6e A',
              levelGroupName: 'Secondaire',
              studentCharges: charges,
            ),
            onPaymentCreated: () {},
          ),
        ),
      ),
    );
    await tester.pump();
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
    await tester.enterText(champParLibelle('Nom'), 'Kabongo');
    await tester.enterText(champParLibelle('Prénom'), 'Joseph');
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

  /// Coche la ligne d'indice [index].
  ///
  /// On descend depuis LA ligne visée, et `.first` porte sur le résultat du
  /// `descendant` : une ligne contient plusieurs `InkWell` (la case, puis
  /// « Tout solder »), donc un `.at(index)` posé sur le `matching` désignerait
  /// le second bouton de la PREMIÈRE ligne — et le test prouverait autre chose
  /// que ce qu'il annonce.
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

  testWidgets('une seule devise : l\'encaissement passe, comme avant', (
    tester,
  ) async {
    await ouvrir(tester, [
      charge('1', 'SCOLARITE', 'USD', 42500),
      charge('2', 'INSCRIPTION', 'USD', 1500),
    ]);
    await remplirPayeur(tester);
    await cocher(tester, 0);
    await cocher(tester, 1);

    expect(collectEnabled(tester), isTrue);
    // Une seule devise → un seul montant, et il porte son abréviation.
    expect(find.textContaining('440,00'), findsWidgets);
  });

  testWidgets('deux devises cochées : le CTA se ferme et s\'explique', (
    tester,
  ) async {
    await ouvrir(tester, [
      charge('1', 'SCOLARITE', 'USD', 42500),
      charge('2', 'ASSURANCE', 'CDF', 9000000),
    ]);
    await remplirPayeur(tester);
    await cocher(tester, 0);
    await cocher(tester, 1);

    expect(collectEnabled(tester), isFalse);
    // Un bouton gris sans explication se règle par un appel au support.
    expect(find.textContaining('deux devises'), findsOneWidget);
  });

  testWidgets('les deux montants s\'affichent côte à côte, jamais sommés', (
    tester,
  ) async {
    await ouvrir(tester, [
      charge('1', 'SCOLARITE', 'USD', 42500),
      charge('2', 'ASSURANCE', 'CDF', 9000000),
    ]);
    await remplirPayeur(tester);
    await cocher(tester, 0);
    await cocher(tester, 1);

    // Le total affichait « 90 425,00 $ » : 42 500 + 9 000 000 centimes sommés
    // sans égard à l'unité, étiquetés avec la première devise venue. C'est le
    // chiffre même que le back cite comme symptôme.
    // 42 500 + 9 000 000 centimes sommés sans égard à l'unité font 9 042 500,
    // soit « 90 425 » quelle que soit l'étiquette qu'on leur colle. Le nombre
    // seul est donc la bonne sonde : il ne peut apparaître que si quelqu'un a
    // additionné deux devises.
    expect(find.textContaining('90\u00A0425'), findsNothing);
    expect(find.textContaining('425,00'), findsWidgets);
    expect(find.textContaining('90\u00A0000'), findsWidgets);
  });

  testWidgets('décocher la seconde devise rouvre l\'encaissement', (
    tester,
  ) async {
    await ouvrir(tester, [
      charge('1', 'SCOLARITE', 'USD', 42500),
      charge('2', 'ASSURANCE', 'CDF', 9000000),
    ]);
    await remplirPayeur(tester);
    await cocher(tester, 0);
    await cocher(tester, 1);
    expect(collectEnabled(tester), isFalse);

    await cocher(tester, 1);

    expect(collectEnabled(tester), isTrue);
    expect(find.textContaining('deux devises'), findsNothing);
  });
}
