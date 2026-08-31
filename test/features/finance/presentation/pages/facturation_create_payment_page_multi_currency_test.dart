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
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
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

/// Un versement peut mêler deux devises — c'est un **acte de guichet**, donc un
/// versement, un reçu, une notification. Imposer deux gestes au caissier serait
/// laisser le schéma dicter le métier.
///
/// Ce que la bascule a fermé : le total sommait les allocations toutes devises
/// confondues et retenait la première non vide. 425,00 $ + 90 000 FC — soit
/// 9 042 500 centimes — s'affichaient « 90 425,00 $ » sur le bandeau or, sur le
/// ticket imprimé, et partaient tels quels au serveur.
///
/// La garde qui refusait le mélange a existé le temps que le contrat porte
/// `amounts[]`. Ces tests-ci épinglent sa levée : la remettre passerait pour une
/// correction.
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
        providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
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

  testWidgets('deux devises cochées : l\'encaissement reste ouvert', (
    tester,
  ) async {
    await ouvrir(tester, [
      charge('1', 'SCOLARITE', 'USD', 42500),
      charge('2', 'ASSURANCE', 'CDF', 9000000),
    ]);
    await remplirPayeur(tester);
    await cocher(tester, 0);
    await cocher(tester, 1);

    expect(collectEnabled(tester), isTrue);
    // Plus de blocage, donc plus d'explication à donner.
    expect(find.textContaining('deux devises'), findsNothing);
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

  testWidgets('tout décocher referme l\'encaissement', (tester) async {
    // Rien à encaisser n'est pas un encaissement — le seul refus qui reste.
    await ouvrir(tester, [
      charge('1', 'SCOLARITE', 'USD', 42500),
      charge('2', 'ASSURANCE', 'CDF', 9000000),
    ]);
    await remplirPayeur(tester);
    await cocher(tester, 0);
    await cocher(tester, 1);
    expect(collectEnabled(tester), isTrue);

    await cocher(tester, 0);
    await cocher(tester, 1);

    expect(collectEnabled(tester), isFalse);
  });
}
