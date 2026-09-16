import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
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

/// Deux points sur la même paire, de part et d'autre du 15 septembre.
///
/// C'est ce qui permet de prouver A4 **sur l'argent** plutôt que sur un
/// libellé : à 1 666,67 le comptoir compte 50 000,10 FC pour 30 \$, à 2 000,00
/// il en compte 60 000,00. Si la date choisie ne pilotait pas la résolution du
/// taux, les deux chiffres seraient identiques.
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

/// Un mardi ordinaire : 09 h 00 à Kinshasa, donc 08 h 00 UTC.
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
    WidgetTester tester, {
    List<StudentCharge> charges = const [],
    List<ExchangeRate> rates = const [],
    DateTime? now,
    DateTime? earliestPaidAt,
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
            now: now ?? _maintenant,
            earliestPaidAt: earliestPaidAt,
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

  EteeloDateInput champDate(WidgetTester tester) =>
      tester.widget<EteeloDateInput>(find.byType(EteeloDateInput));

  Future<void> choisirDate(WidgetTester tester, DateTime jour) async {
    // On appelle le rappel du champ plutôt que de piloter le calendrier natif :
    // ce qu'on éprouve ici est le câblage de la page, pas `showDatePicker`, qui
    // a ses propres tests dans le socle.
    champDate(tester).onChanged!(jour);
    await tester.pumpAndSettle();
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

  Future<void> choisirDevise(
    WidgetTester tester,
    int index,
    String symbole,
  ) async {
    final ligne = find
        .byType(FacturationCreatePaymentChargeAllocationLine)
        .at(index);
    final segment = find.descendant(of: ligne, matching: find.text(symbole));
    await tester.ensureVisible(segment.first);
    await tester.pumpAndSettle();
    await tester.tap(segment.first);
    await tester.pumpAndSettle();
  }

  String comptoir(WidgetTester tester, int index) {
    final champs = find.descendant(
      of: find.byType(FacturationCreatePaymentChargeAllocationLine).at(index),
      matching: find.byType(TextField),
    );
    return tester.widget<TextField>(champs.last).controller?.text ?? '';
  }

  group('la date par défaut', () {
    testWidgets('est aujourd\'hui, et le champ porte son libellé', (
      tester,
    ) async {
      await ouvrir(tester);

      expect(find.text('Date du paiement'), findsOneWidget);
      expect(champDate(tester).value, DateTime(2026, 9, 16));
    });

    testWidgets('est celle de l\'ÉCOLE, pas celle de la tablette', (
      tester,
    ) async {
      // 23 h 30 UTC le 16, c'est déjà 00 h 30 le 17 à Kinshasa. Un poste laissé
      // en UTC daterait du 16 un versement que la caisse comptera le 17.
      await ouvrir(tester, now: DateTime.utc(2026, 9, 16, 23, 30));

      expect(champDate(tester).value, DateTime(2026, 9, 17));
    });
  });

  group('les bornes du sélecteur', () {
    testWidgets(
      's\'arrêtent à aujourd\'hui : une date future ne s\'offre pas',
      (tester) async {
        await ouvrir(tester);

        expect(champDate(tester).lastDate, DateTime(2026, 9, 16));
      },
    );

    testWidgets('remontent à la rentrée quand le référentiel la connaît', (
      tester,
    ) async {
      await ouvrir(tester, earliestPaidAt: DateTime(2026, 9, 1));

      expect(champDate(tester).firstDate, DateTime(2026, 9, 1));
    });

    testWidgets('retombent DEUX ans en arrière quand la rentrée est inconnue', (
      tester,
    ) async {
      // Deux ans, et non un : « rentrée inconnue » couvre aussi le versement
      // porté par l'année précédente — le cas même du rattrapage. Une fenêtre
      // d'un an lui amputerait le début de son année.
      await ouvrir(tester);

      expect(champDate(tester).firstDate, DateTime(2024, 9, 16));
    });

    testWidgets('ne se croisent jamais, même si la rentrée est à venir', (
      tester,
    ) async {
      // Référentiel en avance d'une année : une borne basse postérieure à la
      // borne haute fait lever `showDatePicker`.
      await ouvrir(tester, earliestPaidAt: DateTime(2027, 9, 1));

      final champ = champDate(tester);
      expect(champ.firstDate, DateTime(2026, 9, 16));
      expect(champ.firstDate!.isAfter(champ.lastDate!), isFalse);
    });
  });

  group('changer la date', () {
    testWidgets('met à jour le champ', (tester) async {
      await ouvrir(tester);

      await choisirDate(tester, DateTime(2026, 9, 12));

      expect(champDate(tester).value, DateTime(2026, 9, 12));
    });

    testWidgets('ne retient que le jour, jamais l\'heure du sélecteur', (
      tester,
    ) async {
      await ouvrir(tester);

      await choisirDate(tester, DateTime(2026, 9, 12, 7, 45, 3));

      expect(champDate(tester).value, DateTime(2026, 9, 12));
    });

    testWidgets('déplace le taux proposé sur celui du jour désigné (A4)', (
      tester,
    ) async {
      await ouvrir(
        tester,
        charges: [charge('1', 'USD', 3000)],
        rates: [_tauxAncien, _tauxRecent],
      );
      await cocher(tester, 0);
      await choisirDevise(tester, 0, 'FC');

      // Daté du 16 : le taux du 15 s'applique — 30 $ valent 60 000 FC tout
      // rond (le champ ne pose pas de décimales quand il n'y en a pas).
      final au16 = comptoir(tester, 0);
      expect(au16, '60000');

      await choisirDate(tester, DateTime(2026, 9, 12));

      // Reculé au 12 : c'est le taux d'avant qui vaut — 50 000,10 FC.
      // Sans ce lien, le serveur jugerait divergent un versement que personne
      // n'a mal converti.
      final au12 = comptoir(tester, 0);
      expect(au12, '50000.10');
      // La preuve tient même si l'écriture des nombres change un jour : ce qui
      // compte est que le montant ait BOUGÉ, et seule la date a bougé.
      expect(au12, isNot(au16));
    });
  });

  group('le fuseau de l\'école', () {
    test('compose un instant qui se relit au bon jour à Kinshasa', () {
      // Garde-fou du câblage : la page ne stocke qu'un jour, et c'est
      // `SchoolTime` qui lui rend une heure au moment d'écrire.
      final instant = SchoolTime.composeInstant(
        day: DateTime(2026, 9, 12),
        now: _maintenant,
      );

      expect(instant, DateTime.utc(2026, 9, 12, 8));
      expect(SchoolTime.wallClock(instant).day, 12);
    });
  });
}
