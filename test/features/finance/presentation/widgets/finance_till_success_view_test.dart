import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

TillCurrencyBlock _block(
  String currency, {
  int fees = 100000,
  int boutique = 23450,
  List<TillBucket>? buckets,
}) => TillCurrencyBlock(
  currency: currency,
  summary: TillSummary(total: fees + boutique, fees: fees, boutique: boutique),
  buckets:
      buckets ??
      [
        TillBucket(
          key: '2026-05-15',
          total: fees + boutique,
          fees: fees,
          boutique: boutique,
          isCurrent: true,
        ),
      ],
);

/// Ce que les versements ont éteint, dans la devise d'une créance.
TillImputation _imputation(String currency, int total) => TillImputation(
  currency: currency,
  total: total,
  byFeeCode: [
    TillFeeCodeAmount(code: 'TUITION', label: 'Minerval', amount: total),
  ],
);

FinanceTill _till(
  List<TillCurrencyBlock> blocks, {
  List<TillImputation>? impute,
  String period = 'day',
  DateTime? start,
  DateTime? end,
  String timeZone = 'Africa/Kinshasa',
}) => FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: period,
    periodStart: start ?? DateTime.utc(2026, 5, 15),
    periodEnd: end ?? DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18, 4),
  ),
  timeZone: timeZone,
  encaisse: blocks,
  // Le cas courant : l'école n'encaisse que dans la devise de ses créances, et
  // chaque bloc reçu a son pendant imputé. Les tests qui éprouvent la bascule
  // de devise passent leur propre liste.
  impute:
      impute ??
      [
        for (final block in blocks)
          if (block.summary.fees > 0)
            _imputation(block.currency, block.summary.fees),
      ],
);

/// Le tiroir, à l'écran.
///
/// Ce que la vue doit dire sans qu'on ait à le déduire : **de quelle fenêtre**
/// parle le total, **dans quel fuseau** elle se découpe, **de quand** datent
/// les chiffres, et ce qui distingue les frais des ventes boutique.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSyncStatusCubit syncCubit;

  setUp(() {
    syncCubit = _MockSyncStatusCubit();
    final syncState = SyncStatusState(
      status: SyncStatus.synced,
      lastSyncAtMs: DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
    );
    when(() => syncCubit.state).thenReturn(syncState);
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: syncState,
    );
  });

  Future<void> pump(WidgetTester tester, FinanceTill till) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: syncCubit,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinanceTillSuccessView(till: till),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la fenêtre et le fuseau se disent, ils ne se devinent pas', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD')]));

    expect(tester.takeException(), isNull);
    // Une journée : une seule date, pas un intervalle qui se replierait sur
    // lui-même.
    expect(find.textContaining('Journée du'), findsOneWidget);
    expect(
      find.text('Journée à l\'heure de l\'école · Africa/Kinshasa'),
      findsOneWidget,
    );
  });

  testWidgets('une fenêtre large annonce ses deux bornes', (tester) async {
    await pump(
      tester,
      _till(
        [_block('USD')],
        period: 'month',
        start: DateTime.utc(2026, 5),
        end: DateTime.utc(2026, 5, 31),
      ),
    );

    expect(find.textContaining('Du '), findsOneWidget);
    expect(find.textContaining('Journée du'), findsNothing);
  });

  testWidgets('un fuseau absent se tait', (tester) async {
    await pump(tester, _till([_block('USD')], timeZone: ''));

    expect(find.textContaining('heure de l\'école'), findsNothing);
  });

  testWidgets('le total date de la dernière synchro, et le dit', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD')]));

    // Encaissements et ventes boutique passent par la file d'écritures : le
    // serveur ne totalise que ce qui lui est parvenu, et c'est le seul écran
    // qu'on compare à des billets.
    expect(find.textContaining('Arrêté à la dernière synchro'), findsOneWidget);
    expect(find.textContaining('Il y a 1 h'), findsOneWidget);
  });

  testWidgets('jamais synchronisé : la ligne le dit au lieu de se taire', (
    tester,
  ) async {
    const never = SyncStatusState(status: SyncStatus.offline);
    when(() => syncCubit.state).thenReturn(never);
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: never,
    );

    await pump(tester, _till([_block('USD')]));

    expect(find.text('Jamais synchronisé'), findsOneWidget);
  });

  testWidgets('trois cartes, aucun taux : rien n’est dû ici', (tester) async {
    await pump(tester, _till([_block('USD')]));

    expect(find.byType(EteeloKpiCard), findsNWidgets(3));
    expect(find.text('Total du tiroir'), findsOneWidget);
    expect(find.text('Frais scolaires'), findsOneWidget);
    expect(find.text('Ventes boutique'), findsOneWidget);
    expect(find.text('Taux de recouvrement'), findsNothing);
    expect(find.text('Reste à recouvrer'), findsNothing);
  });

  testWidgets('la ventilation descend sous son propre titre', (tester) async {
    await pump(tester, _till([_block('USD')]));

    expect(find.text('Ce que ces versements ont éteint'), findsOneWidget);
    expect(find.text('Créances réglées en \$'), findsOneWidget);
    expect(find.text('Minerval'), findsOneWidget);
    // La part boutique n'a aucun poste : elle vit dans sa carte, entière.
    expect(find.text('Boutique'), findsNothing);
  });

  testWidgets(
    'les deux unités se nomment, et rien ne les additionne : un tiroir en '
    'francs qui solde des créances en dollars',
    (tester) async {
      await pump(
        tester,
        _till(
          [_block('CDF', fees: 11500000, boutique: 0)],
          impute: [_imputation('USD', 5000)],
        ),
      );

      // En haut, la devise reçue. En bas, celle des créances — et le titre le
      // dit, sans quoi les montants du bas se lisent dans la mauvaise unité.
      expect(find.text('Créances réglées en \$'), findsOneWidget);
      expect(
        find.text(
          'En devise de créance : ces montants ne s\'additionnent pas à ceux '
          'du tiroir.',
        ),
        findsOneWidget,
      );
      // Aucune ligne ne prétend faire la somme des deux.
      expect(find.text('Créances réglées en FC'), findsNothing);
    },
  );

  testWidgets(
    'des frais entrés sans aucune imputation : la lacune se voit, elle ne '
    's’escamote pas',
    (tester) async {
      await pump(tester, _till([_block('USD')], impute: const []));

      expect(find.text('Ce que ces versements ont éteint'), findsOneWidget);
      expect(
        find.text('Aucune donnée disponible pour cette période'),
        findsOneWidget,
      );
    },
  );

  testWidgets('une devise sans mouvement se dit, au lieu d’un axe plat', (
    tester,
  ) async {
    await pump(
      tester,
      _till([_block('CDF', fees: 0, boutique: 0), _block('USD')]),
    );

    expect(find.text('Aucun mouvement dans cette devise'), findsOneWidget);
    expect(
      find.text('Rien n\'est entré dans le tiroir sur cette période.'),
      findsOneWidget,
    );
    // La devise garde sa place dans la bande KPI : ses zéros y sont justes.
    expect(find.byType(EteeloKpiCard), findsNWidgets(3));
    // Un seul axe : celui de la devise qui a bougé.
    expect(find.byType(FinanceTillBucketsSection), findsOneWidget);
  });

  testWidgets('aucune devise : un état vide, pas un zéro', (tester) async {
    await pump(tester, _till(const []));

    expect(find.byType(EteeloEmptyResult), findsOneWidget);
    expect(find.byType(EteeloKpiCard), findsNothing);
    // La fenêtre reste annoncée : elle dit de quoi l'écran ne trouve rien.
    expect(find.textContaining('Journée du'), findsOneWidget);
  });

  group('libellé de barre', () {
    test('une clé journalière rend le jour, pas quatre caractères coupés', () {
      // Le formatteur du recouvrement, écrit pour l'axe mensuel, rendait
      // « 5-15 » : il coupait les quatre derniers caractères d'une chaîne qui
      // en compte dix.
      expect(shortBucketLabel('2026-05-15'), '15');
      expect(shortBucketLabel('2026-05-01'), '01');
    });

    test('une clé mensuelle rend le rang du mois', () {
      expect(shortBucketLabel('2026-05'), '05');
    });

    test('une clé inattendue se rend telle quelle', () {
      expect(shortBucketLabel('2026'), '2026');
    });
  });
}
