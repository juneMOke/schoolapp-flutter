import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_cash_boxes.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_currency_selector.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_insights_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// La table des reçus vit dans son propre BLoC — c'est ce qui permet à un 403
/// nominatif de ne pas emporter les agrégats. Les tests de la vue la montent
/// donc à un état donné plutôt que d'appeler le réseau.
class _StubReceiptsBloc
    extends MockBloc<FinanceTillReceiptsEvent, FinanceTillReceiptsState>
    implements FinanceTillReceiptsBloc {}

TillCurrencyBlock _block(
  String currency, {
  int fees = 100000,
  int boutique = 23450,
  int receiptCount = 5,
  int? trendPercent,
  TillTrendUnavailableReason? trendUnavailableReason,
  List<TillBucket>? buckets,
  List<TillClassroomAmount>? byClassroom,
  int unassignedAmount = 0,
  TillBestBucket? bestBucket,
}) => TillCurrencyBlock(
  currency: currency,
  summary: TillSummary(
    total: fees + boutique,
    fees: fees,
    boutique: boutique,
    receiptCount: receiptCount,
    averageTicket: receiptCount == 0 ? 0 : (fees + boutique) ~/ receiptCount,
    trendPercent: trendPercent,
    trendUnavailableReason: trendUnavailableReason,
  ),
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
  byClassroom: byClassroom ?? const [],
  unassignedAmount: unassignedAmount,
  bestBucket: bestBucket,
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
  int? receiptsIssued,
  TillCrossed crossed = const TillCrossed(
    count: 0,
    amounts: [],
    rateMicros: [],
  ),
}) => FinanceTill(
  context: StatsContext(
    schoolYear: '2025-2026',
    period: period,
    periodStart: start ?? DateTime.utc(2026, 5, 15),
    periodEnd: end ?? DateTime.utc(2026, 5, 15),
    generatedAt: DateTime.utc(2026, 5, 15, 18, 4),
  ),
  timeZone: timeZone,
  crossed: crossed,
  encaisse: blocks,
  // Par défaut, aucun panier mixte : chaque reçu n'a alimenté qu'une caisse, et
  // le compteur global vaut la somme des compteurs. Les tests qui éprouvent
  // l'écart passent leur propre valeur.
  receiptsIssued:
      receiptsIssued ??
      blocks.fold<int>(0, (sum, block) => sum + block.summary.receiptCount),
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

  /// La devise détaillée, résolue comme le BLoC la résout — dollar par défaut.
  late List<String> selectedByTap;
  late List<TillWindow> windowsByTap;

  Future<void> pump(
    WidgetTester tester,
    FinanceTill till, {
    String? selectedCurrency,
    FinanceTillReceiptsState? receiptsState,
  }) async {
    selectedByTap = <String>[];
    windowsByTap = <TillWindow>[];
    final currency = resolveSelectedTillCurrency(
      selectedCurrency,
      till.encaisse,
    );
    final selected = till.encaisse
        .where((block) => block.currency == currency)
        .firstOrNull;

    final receipts =
        receiptsState ??
        FinanceTillReceiptsState(
          status: FinanceTillReceiptsStatus.empty,
          currency: currency,
        );
    final receiptsBloc = _StubReceiptsBloc();
    when(() => receiptsBloc.state).thenReturn(receipts);
    whenListen(
      receiptsBloc,
      const Stream<FinanceTillReceiptsState>.empty(),
      initialState: receipts,
    );

    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SyncStatusCubit>.value(value: syncCubit),
          BlocProvider<FinanceTillReceiptsBloc>.value(value: receiptsBloc),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinanceTillSuccessView(
                till: till,
                selectedBlock: selected,
                onCurrencySelected: selectedByTap.add,
                onWindowRequested: windowsByTap.add,
              ),
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

  testWidgets('une caisse par devise, plus le compteur — aucun taux ici', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD')]));

    expect(find.byType(FinanceTillCashBoxes), findsOneWidget);
    expect(find.text('Caisse dollars · Aujourd\'hui'), findsOneWidget);
    expect(find.text('Reçus émis'), findsOneWidget);
    // Rien n'est dû sur cet onglet : y lire un ratio ferait chercher un
    // recouvrement là où le caissier compte des billets.
    expect(find.text('Taux de recouvrement'), findsNothing);
    expect(find.text('Reste à recouvrer'), findsNothing);
  });

  testWidgets('les dollars restent à gauche même quand les francs mènent', (
    tester,
  ) async {
    await pump(
      tester,
      // L'ordre du serveur est alphabétique — CDF d'abord — et les francs
      // pèsent ici bien plus lourd. La position ne doit pas bouger pour autant.
      _till([
        _block('CDF', fees: 9000000, boutique: 0),
        _block('USD', fees: 100000, boutique: 23450),
      ]),
    );

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(FinanceTillCashBoxes),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .whereType<String>();

    expect(
      labels.firstWhere((label) => label.startsWith('Caisse')),
      'Caisse dollars · Aujourd\'hui',
      reason:
          'la position d’une caisse doit être stable d’un jour à l’autre : '
          'sinon le lecteur qui a mémorisé « le dollar est à gauche » lit un '
          'franc pour un dollar le premier jour où les francs passent devant',
    );
  });

  testWidgets('un reçu croisé fait diverger les compteurs, et la note le dit', (
    tester,
  ) async {
    await pump(
      tester,
      _till(
        [_block('CDF', receiptCount: 3), _block('USD', receiptCount: 5)],
        // 5 + 3 = 8 compteurs de caisse pour 7 reçus : un versement a été réglé
        // moitié en francs, moitié en dollars.
        receiptsIssued: 7,
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(
      find.text(
        'Un reçu réglé dans les deux devises compte dans chaque caisse, '
        'mais n\'est émis qu\'une fois.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sans panier mixte, la note d’écart ne s’affiche pas', (
    tester,
  ) async {
    await pump(
      tester,
      _till([_block('CDF', receiptCount: 3), _block('USD', receiptCount: 5)]),
    );

    expect(find.text('8'), findsOneWidget);
    expect(
      find.textContaining('compte dans chaque caisse'),
      findsNothing,
      reason:
          'les compteurs s’accordent : la phrase sèmerait un doute là où il '
          'n’y en a pas',
    );
  });

  testWidgets('une tendance non mesurée ne s’affiche pas du tout', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD'), _block('CDF', trendPercent: -7)]));

    expect(find.text('7 % vs période précédente'), findsOneWidget);
    expect(
      find.textContaining('vs période précédente'),
      findsOneWidget,
      reason:
          'le bloc USD n’a pas de tendance : « 0 % » annoncerait une '
          'stabilité que personne n’a observée',
    );
  });

  testWidgets('avant la rentrée, la tuile DIT pourquoi elle ne compare pas', (
    tester,
  ) async {
    await pump(
      tester,
      _till([
        _block(
          'USD',
          trendUnavailableReason: TillTrendUnavailableReason.beforeSchoolYear,
        ),
      ]),
    );

    expect(
      find.text('Pas de période comparable avant la rentrée'),
      findsOneWidget,
      reason:
          'sinon la tuile perd son delta tous les jours de septembre sans '
          'raison visible, et quelqu’un finit par ouvrir un ticket',
    );
    expect(find.textContaining('vs période précédente'), findsNothing);
  });

  testWidgets('une période précédente vide se tait, elle ne s’explique pas', (
    tester,
  ) async {
    await pump(
      tester,
      _till([
        _block(
          'USD',
          trendUnavailableReason:
              TillTrendUnavailableReason.previousPeriodEmpty,
        ),
      ]),
    );

    expect(
      find.textContaining('Pas de période comparable'),
      findsNothing,
      reason:
          'la période existe et n’a rien encaissé : c’est un fait de la '
          'période regardée, pas une limite de la mesure — l’absence se '
          'comprend d’elle-même',
    );
    expect(find.textContaining('vs période précédente'), findsNothing);
  });

  testWidgets('une tendance mesurée ignore toute cause d’indisponibilité', (
    tester,
  ) async {
    await pump(
      tester,
      _till([
        _block(
          'USD',
          trendPercent: 18,
          // Incohérent côté serveur, mais l'écran ne doit pas afficher les deux.
          trendUnavailableReason: TillTrendUnavailableReason.beforeSchoolYear,
        ),
      ]),
    );

    expect(find.text('18 % vs période précédente'), findsOneWidget);
    expect(find.textContaining('Pas de période comparable'), findsNothing);
  });

  testWidgets('une caisse sans reçu tait son ticket moyen', (tester) async {
    await pump(
      tester,
      _till([_block('USD', fees: 0, boutique: 0, receiptCount: 0)]),
    );

    expect(
      find.textContaining('ticket moyen'),
      findsNothing,
      reason: 'il n’y a rien à diviser — « ticket moyen 0 » serait une mesure',
    );
  });

  testWidgets('la ventilation suit « Par source », chacune nommant son unité', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD')]));

    // Deux lectures de la même somme, l'une sous l'autre : « d'où ça vient »
    // puis « ce que ça a éteint ».
    expect(find.text('Créances réglées en \$'), findsOneWidget);
    expect(find.text('Par source'), findsOneWidget);
    expect(find.text('Minerval'), findsOneWidget);
    // Et leur succession n'invite pas à additionner : la seconde dit son unité,
    // qui n'est pas celle de la première.
    expect(
      find.textContaining('En devise de créance, jamais converti'),
      findsOneWidget,
    );
  });

  /// La carte qui porte ce titre, prise par son cadre.
  Finder cardOf(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(FinanceStatsChartCard),
  );

  testWidgets('« Par source » tient toute la ligne, sans rien partager', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD')]));

    final source = tester.getRect(cardOf('Par source'));
    // Pleine largeur : celle d'une carte dont on sait qu'elle l'occupe déjà.
    expect(source.width, tester.getRect(cardOf('Par classe')).width);
    // Et rien à sa droite : les créances, qui partageaient sa ligne, sont
    // passées dessous — elles ne comptent pas dans la même unité qu'elle.
    expect(
      tester.getRect(cardOf('Créances réglées en \$')).top,
      greaterThanOrEqualTo(source.bottom),
    );
  });

  testWidgets('les deux devises de créance se lisent côte à côte', (
    tester,
  ) async {
    await pump(
      tester,
      _till(
        [_block('USD')],
        impute: [_imputation('USD', 5000), _imputation('CDF', 11500000)],
      ),
    );

    final usd = tester.getRect(cardOf('Créances réglées en \$'));
    final cdf = tester.getRect(cardOf('Créances réglées en FC'));

    // Empilées, comparer « ce que la journée a éteint ici et là » demandait de
    // faire défiler.
    expect(usd.top, cdf.top);
    expect(usd.right, lessThanOrEqualTo(cdf.left));
  });

  testWidgets('à l’étroit, elles retombent l’une sous l’autre', (tester) async {
    // ⚠️ La taille se pose APRÈS le pump, que le harnais fixe à 1280.
    await pump(
      tester,
      _till(
        [_block('USD')],
        impute: [_imputation('USD', 5000), _imputation('CDF', 11500000)],
      ),
    );
    await tester.binding.setSurfaceSize(const Size(600, 4000));
    await tester.pumpAndSettle();

    final usd = tester.getRect(cardOf('Créances réglées en \$'));
    final cdf = tester.getRect(cardOf('Créances réglées en FC'));

    // Une comparaison illisible ne vaut pas mieux qu'un empilement.
    expect(cdf.top, greaterThanOrEqualTo(usd.bottom));
    expect(usd.width, cdf.width);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
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

      // À gauche la devise des créances, à droite celle du tiroir — et la
      // carte de gauche le dit, sans quoi son voisinage la ferait lire dans la
      // mauvaise unité.
      expect(find.text('Créances réglées en \$'), findsOneWidget);
      expect(
        find.textContaining('En devise de créance, jamais converti'),
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

      // La carte de gauche ne s'escamote pas : la lacune y passerait pour une
      // journée sans frais.
      expect(
        find.text('Aucune donnée disponible pour cette période'),
        findsOneWidget,
      );
      expect(find.text('Par source'), findsOneWidget);
    },
  );

  testWidgets('les chiffres qu’on compare portent des largeurs fixes', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD'), _block('CDF')]));

    bool tabular(String startsWith) {
      final widget = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => (t.data ?? '').startsWith(startsWith));
      return (widget.style?.fontFeatures ?? const <FontFeature>[]).any(
        (f) => f.feature == 'tnum',
      );
    }

    // Deux tuiles côte à côte, deux sous-lignes de même forme : sans largeurs
    // fixes, « 5 reçus · ticket moyen 246,90 $ » et son voisin en francs ne se
    // comparent pas d'un coup d'œil — c'est pourtant le geste que la bande
    // invite à faire.
    expect(tabular('5 reçus'), isTrue);
    // Le total d'une carte d'imputation, et la colonne de parts sous les
    // barres.
    expect(tabular('Total imputé'), isTrue);
    expect(tabular('Minerval ·'), isTrue);
  });

  testWidgets('l’écran tient de la tablette au petit téléphone', (
    tester,
  ) async {
    // ⚠️ **La taille se pose APRÈS le pump.** Le harnais impose lui-même
    // 1280 : une taille posée avant est écrasée sans que rien ne le signale, et
    // la boucle rendait sept fois la même largeur en annonçant sept résultats.
    for (final width in [1280.0, 1024.0, 768.0, 600.0, 420.0, 360.0, 320.0]) {
      await pump(tester, _till([_block('USD'), _block('CDF')]));
      await tester.binding.setSurfaceSize(Size(width, 4000));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'débordement à ${width.toStringAsFixed(0)} dp',
      );
    }
    await tester.binding.setSurfaceSize(null);
  });

  group('vide global — aucune caisse n’a rien reçu', () {
    testWidgets('les tuiles restent à 0, le détail disparaît', (tester) async {
      await pump(
        tester,
        _till([
          _block('USD', fees: 0, boutique: 0, receiptCount: 0),
          _block('CDF', fees: 0, boutique: 0, receiptCount: 0),
        ]),
      );

      expect(find.text('Aucun encaissement · aujourd\'hui'), findsOneWidget);
      // « Le repère de lecture ne disparaît pas » : les deux tuiles restent,
      // à zéro, pour que le lecteur retrouve les devises de son école au
      // moment même où il se demande s'il regarde au bon endroit.
      expect(find.byType(FinanceTillCashBoxes), findsOneWidget);
      expect(find.text('Caisse dollars · Aujourd\'hui'), findsOneWidget);
      expect(find.text('Caisse francs · Aujourd\'hui'), findsOneWidget);
      // Blocs 4 → 9 masqués : il n'y a pas de caisse à détailler, et un
      // sélecteur proposerait de choisir entre deux riens.
      expect(find.byType(FinanceTillCurrencySelector), findsNothing);
      expect(find.byType(FinanceTillBucketsSection), findsNothing);
    });

    testWidgets('sans le moindre bloc, aucune tuile n’est inventée', (
      tester,
    ) async {
      await pump(tester, _till(const []));

      expect(find.text('Aucun encaissement · aujourd\'hui'), findsOneWidget);
      // On ne connaît même pas les devises de l'école : une tuile inventée
      // serait pire que pas de tuile.
      expect(find.byType(FinanceTillCashBoxes), findsNothing);
    });

    testWidgets('l’issue élargit la fenêtre, et le mois va vers l’année', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block('USD', fees: 0, boutique: 0, receiptCount: 0),
        ], period: 'day'),
      );
      expect(find.text('Voir ce mois'), findsOneWidget);

      await tester.tap(find.text('Voir ce mois'));
      await tester.pumpAndSettle();
      expect(windowsByTap.single.period, TillPeriod.month);
    });

    testWidgets('depuis le mois, l’élargissement offert est l’année', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block('USD', fees: 0, boutique: 0, receiptCount: 0),
        ], period: 'month'),
      );

      expect(find.text('Voir cette année'), findsOneWidget);
      await tester.tap(find.text('Voir cette année'));
      await tester.pumpAndSettle();
      expect(windowsByTap.single.period, TillPeriod.year);
    });

    testWidgets(
      'une plage libre n’est pas élargie — ses bornes sont un choix',
      (tester) async {
        await pump(
          tester,
          _till([
            _block('USD', fees: 0, boutique: 0, receiptCount: 0),
          ], period: 'custom'),
        );

        // Substituer « ce mois » jetterait les bornes que le lecteur vient de
        // choisir — et rien ne dit que sa plage est plus étroite qu'un mois.
        expect(find.text('Voir ce mois'), findsNothing);
        expect(find.text('Voir cette année'), findsNothing);
        // La règle « jamais sans issue » tient par la facturation.
        expect(find.text('Ouvrir la facturation'), findsOneWidget);
      },
    );

    testWidgets('un compteur global à 0 ne cache pas une caisse qui a reçu', (
      tester,
    ) async {
      // ⚠️ Le contrat porte un `receiptsIssued` toutes caisses. S'y fier ferait
      // dépendre l'affichage d'un agrégat : ici il vaut 0 alors que la caisse
      // dollars porte cinq reçus. Le vide se lit sur les BLOCS, qui sont ce
      // qu'on affiche — ce test-là ne peut donc pas cacher de données.
      await pump(tester, _till([_block('USD')], receiptsIssued: 0));

      expect(find.text('Aucun encaissement · aujourd\'hui'), findsNothing);
      expect(find.byType(FinanceTillCurrencySelector), findsOneWidget);
    });
  });

  group('vide de caisse — l’autre a travaillé', () {
    testWidgets('les tuiles ET le sélecteur restent, seul le détail change', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block('CDF', fees: 0, boutique: 0, receiptCount: 0),
          _block('USD'),
        ]),
        selectedCurrency: 'CDF',
      );

      expect(find.byType(FinanceTillCashBoxes), findsOneWidget);
      expect(find.byType(FinanceTillCurrencySelector), findsOneWidget);
      expect(find.byType(FinanceTillBucketsSection), findsNothing);
    });

    testWidgets('une caisse au total nul mais qui a des reçus a travaillé', (
      tester,
    ) async {
      // Encaisser puis rembourser le même montant laisse un total à zéro et
      // des reçus bien réels. « Aucun paiement n'a été tendu » serait faux —
      // c'est ce que disait le total, et c'est pourquoi on compte les reçus.
      await pump(
        tester,
        _till([
          _block('CDF', fees: 0, boutique: 0, receiptCount: 3),
          _block('USD'),
        ]),
        selectedCurrency: 'CDF',
      );

      expect(find.text('Caisse francs vide sur cette période'), findsNothing);
    });

    testWidgets('la bascule est directe et nomme la caisse qui a travaillé', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block('CDF', fees: 0, boutique: 0, receiptCount: 0),
          _block('USD'),
        ]),
        selectedCurrency: 'CDF',
      );

      await tester.tap(find.text('Voir la caisse dollars'));
      await tester.pumpAndSettle();

      expect(selectedByTap, ['USD']);
    });

    testWidgets(
      'plusieurs autres caisses se juxtaposent, jamais ne s’ajoutent',
      (tester) async {
        await pump(
          tester,
          _till([
            _block('CDF', fees: 0, boutique: 0, receiptCount: 0),
            _block('USD', fees: 100000, boutique: 0),
            _block('EUR', fees: 200000, boutique: 0),
          ]),
          selectedCurrency: 'CDF',
        );

        final text = find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .whereType<String>()
            .map((t) => t.replaceAll('\u00A0', ' '))
            .firstWhere((t) => t.contains('Les autres caisses'));

        // Les deux montants, côte à côte. Jamais 3 000 : les caisses ne
        // s'additionnent pas, et la phrase ne relâche pas la règle.
        expect(text, contains('1 000,00 \$'));
        expect(text, contains('2 000,00 €'));
        expect(text, isNot(contains('3 000')));
      },
    );
  });

  testWidgets('une devise sans mouvement se dit, au lieu d’un axe plat', (
    tester,
  ) async {
    await pump(
      tester,
      _till([
        _block('CDF', fees: 0, boutique: 0, receiptCount: 0),
        _block('USD'),
      ]),
      // C'est la caisse SÉLECTIONNÉE qui est creuse : le détail ne décrit
      // qu'elle, et c'est là que la phrase remplace un axe plat.
      selectedCurrency: 'CDF',
    );

    // ⚠️ **La phrase CHIFFRE l'autre caisse.** L'ancienne — « Aucun mouvement
    // dans cette devise » — constatait sans situer : elle se lisait comme un
    // écran en panne. Ce montant-ci dit « il ne s'est rien passé ICI », ce qui
    // n'est pas la même information.
    expect(find.text('Caisse francs vide sur cette période'), findsOneWidget);
    expect(find.textContaining("L'autre caisse a enregistré"), findsOneWidget);
    // Jamais d'écran vide sans issue : la bascule est offerte, et elle nomme
    // la caisse qui, elle, a travaillé.
    expect(find.text('Voir la caisse dollars'), findsOneWidget);
    // La devise garde sa tuile de caisse : ses zéros y sont justes, et l'autre
    // caisse reste lisible à côté.
    expect(find.byType(FinanceTillCashBoxes), findsOneWidget);
    expect(find.text('Caisse francs · Aujourd\'hui'), findsOneWidget);
    expect(find.text('Caisse dollars · Aujourd\'hui'), findsOneWidget);
    // Aucun axe : la caisse détaillée n'a rien à dessiner.
    expect(find.byType(FinanceTillBucketsSection), findsNothing);
  });

  testWidgets('le détail ne décrit qu’une caisse, celle qui est choisie', (
    tester,
  ) async {
    await pump(
      tester,
      _till([_block('CDF', fees: 9000000, boutique: 0), _block('USD')]),
    );

    // Deux tuiles, mais un seul axe : le dollar par défaut.
    expect(find.byType(FinanceTillBucketsSection), findsOneWidget);
    expect(
      find.text('Progression des encaissements · caisse dollars'),
      findsOneWidget,
    );
    expect(
      find.textContaining('caisse francs'),
      findsNothing,
      reason:
          'deux axes côte à côte inviteraient à comparer deux montants qui ne '
          'se comptent pas dans la même unité',
    );
  });

  testWidgets('le sélecteur porte le compteur de chaque caisse', (
    tester,
  ) async {
    await pump(
      tester,
      _till([
        _block('CDF', receiptCount: 0, fees: 0, boutique: 0),
        _block('USD', receiptCount: 17),
      ]),
    );

    // On voit AVANT de cliquer que l'autre caisse n'a rien encaissé.
    expect(find.text('Détail de la caisse'), findsOneWidget);
    expect(find.text('\$ dollars (17)'), findsOneWidget);
    expect(find.text('FC francs (0)'), findsOneWidget);
  });

  testWidgets('un segment à zéro reste cliquable, et remonte la bascule', (
    tester,
  ) async {
    await pump(
      tester,
      _till([
        _block('CDF', receiptCount: 0, fees: 0, boutique: 0),
        _block('USD', receiptCount: 17),
      ]),
    );

    await tester.tap(find.text('FC francs (0)'));
    await tester.pumpAndSettle();

    expect(
      selectedByTap,
      ['CDF'],
      reason:
          'le griser ferait disparaître l’information « rien n’est entré en '
          'francs aujourd’hui », qui est ce que le caissier vient vérifier',
    );
  });

  testWidgets('une seule caisse : pas de sélecteur, il n’offrirait aucun choix', (
    tester,
  ) async {
    await pump(tester, _till([_block('USD')]));

    expect(find.text('Détail de la caisse'), findsNothing);
    expect(find.textContaining('dollars ('), findsNothing);
    // Le graphique, lui, reste nommé : on doit savoir quelle caisse il dessine.
    expect(
      find.text('Progression des encaissements · caisse dollars'),
      findsOneWidget,
    );
  });

  testWidgets('sur la journée, l’écart série/fenêtre est écrit à côté du '
      'graphique', (tester) async {
    await pump(tester, _till([_block('USD')]));

    expect(
      find.textContaining('la série dessine les sept jours autour'),
      findsOneWidget,
      reason:
          'c’est la troisième fois que cet écart cherche à se faire passer '
          'pour un bug : il est écrit là où on le voit',
    );
  });

  testWidgets(
    'hors journée, la note d’écart disparaît — il n’y a plus d’écart',
    (tester) async {
      await pump(
        tester,
        _till(
          [_block('USD')],
          period: 'month',
          start: DateTime.utc(2026, 5),
          end: DateTime.utc(2026, 5, 31),
        ),
      );

      expect(find.textContaining('sept jours autour'), findsNothing);
    },
  );

  testWidgets('aucune devise : un état vide, pas un zéro', (tester) async {
    await pump(tester, _till(const []));

    expect(find.byType(EteeloEmptyResult), findsOneWidget);
    expect(find.byType(FinanceTillCashBoxes), findsNothing);
    // La fenêtre reste annoncée : elle dit de quoi l'écran ne trouve rien.
    expect(find.textContaining('Journée du'), findsOneWidget);
  });

  group('libellé de barre', () {
    test('une clé journalière rend le jour, pas quatre caractères coupés', () {
      // Le formatteur du recouvrement, écrit pour l'axe mensuel, rendait
      // « 5-15 » : il coupait les quatre derniers caractères d'une chaîne qui
      // en compte dix.
      expect(shortBucketLabel('2026-05-15'), '15/05');
      expect(shortBucketLabel('2026-05-01'), '01/05');
    });

    test('une clé mensuelle rend le mois et son millésime', () {
      // L'axe annuel enjambe deux années civiles : « 05 » seul ne dirait pas
      // laquelle.
      expect(shortBucketLabel('2026-05'), '05/26');
    });

    test('une clé inattendue se rend telle quelle', () {
      expect(shortBucketLabel('2026'), '2026');
    });

    test('⚠️ une tranche HEBDOMADAIRE ne se lit pas comme une journée', () {
      // Le serveur donne à une tranche de sept jours la date de son premier
      // jour : `2026-05-12`, exactement la forme d'une journée. Sans le grain
      // annoncé, l'étiquette « 12 » ferait lire sept jours d'encaissements
      // comme la seule journée du 12.
      expect(shortBucketLabel('2026-05-12', granularity: 'day'), '12/05');
      expect(shortBucketLabel('2026-05-12', granularity: 'week'), 'sem. 12/05');
      expect(
        shortBucketLabel('2026-05-12', granularity: 'week'),
        isNot(shortBucketLabel('2026-05-12', granularity: 'day')),
        reason:
            'deux grains, même clé : c’est le grain qui décide, pas la forme '
            'de la clé',
      );
    });

    test('le grain annoncé prime sur la forme de la clé', () {
      expect(shortBucketLabel('2026-05', granularity: 'month'), '05/26');
    });

    test('sans grain annoncé, la forme de la clé décide — l’ancien repli', () {
      // Un serveur qui ne sert pas encore `granularity` ne doit pas casser
      // l'axe : on retombe sur ce que le formatteur faisait avant lui.
      expect(shortBucketLabel('2026-05-15'), '15/05');
      expect(shortBucketLabel('2026-05'), '05/26');
    });
  });

  group('par source', () {
    testWidgets('les deux sources se lisent, dans un ordre fixe', (
      tester,
    ) async {
      await pump(tester, _till([_block('USD', fees: 325500, boutique: 86500)]));

      expect(find.text('Par source'), findsOneWidget);
      expect(find.text('Frais scolaires'), findsOneWidget);
      expect(find.text('Ventes boutique'), findsOneWidget);
    });

    testWidgets('une source à zéro garde sa ligne — l’absence est une '
        'information', (tester) async {
      await pump(tester, _till([_block('USD', fees: 412000, boutique: 0)]));

      expect(
        find.text('Ventes boutique'),
        findsOneWidget,
        reason:
            'une boutique qui n’a rien vendu ce jour-là doit se voir : la '
            'faire disparaître laisserait croire qu’elle n’existe pas',
      );
    });

    testWidgets('la note du statut non facturé n’apparaît qu’avec une vente', (
      tester,
    ) async {
      await pump(tester, _till([_block('USD', fees: 412000, boutique: 0)]));

      expect(
        find.textContaining('sans solder aucun frais'),
        findsNothing,
        reason:
            'expliquer le statut d’un montant nul commente une ligne que '
            'personne ne voit',
      );

      await pump(tester, _till([_block('USD', fees: 325500, boutique: 86500)]));

      expect(find.textContaining('sans solder aucun frais'), findsOneWidget);
    });
  });

  group('par classe', () {
    testWidgets('le palmarès annonce le nombre réellement affiché', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block(
            'USD',
            byClassroom: const [
              TillClassroomAmount(
                classroomId: 'c1',
                name: '1ère humanités',
                amount: 46000,
              ),
              TillClassroomAmount(
                classroomId: 'c2',
                name: '6ème primaire',
                amount: 34000,
              ),
            ],
          ),
        ]),
      );

      expect(find.text('Par classe'), findsOneWidget);
      // Deux classes, pas « top 8 » : une école de deux classes en montre deux.
      expect(
        find.text('Les 2 classes les plus contributrices à cette caisse'),
        findsOneWidget,
      );
      expect(find.text('1ère humanités'), findsOneWidget);
      expect(find.text('6ème primaire'), findsOneWidget);
    });

    testWidgets('le montant sans classe est annoncé, sinon le classement '
        'passe pour un bug', (tester) async {
      await pump(
        tester,
        _till([
          _block(
            'USD',
            fees: 100000,
            boutique: 23450,
            byClassroom: const [
              TillClassroomAmount(
                classroomId: 'c1',
                name: '1ère humanités',
                amount: 100000,
              ),
            ],
            unassignedAmount: 23450,
          ),
        ]),
      );

      expect(
        find.textContaining('sans désigner de classe'),
        findsOneWidget,
        reason:
            'la somme des lignes ne retombe pas sur le total de la caisse, et '
            'le lecteur cherche une erreur qui n’existe pas — une vente '
            'boutique n’a ni élève ni classe',
      );
    });

    testWidgets('rien d’inattribuable : aucune mention à faire', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block(
            'USD',
            boutique: 0,
            byClassroom: const [
              TillClassroomAmount(
                classroomId: 'c1',
                name: '1ère humanités',
                amount: 100000,
              ),
            ],
          ),
        ]),
      );

      expect(find.textContaining('sans désigner de classe'), findsNothing);
    });

    testWidgets('aucune classe : la carte le dit au lieu de rester vide', (
      tester,
    ) async {
      await pump(tester, _till([_block('USD')]));

      expect(find.text('Aucune classe à classer'), findsOneWidget);
    });
  });

  group('la table des reçus', () {
    testWidgets('un 403 nominatif laisse TOUT le reste à l’écran', (
      tester,
    ) async {
      await pump(
        tester,
        _till([_block('USD')]),
        // Le cas réel : un porteur de `finance.stats.read` sans
        // `finance.payment.read`. Les agrégats ont répondu 200 ; seule la table
        // est refusée.
        receiptsState: const FinanceTillReceiptsState(
          status: FinanceTillReceiptsStatus.error,
          currency: 'USD',
          failure: UnauthorizedFailure('Access forbidden'),
        ),
      );

      expect(
        find.textContaining('demande le droit de lecture des paiements'),
        findsOneWidget,
      );
      // Et surtout : rien d'autre n'a disparu.
      expect(find.byType(FinanceTillCashBoxes), findsOneWidget);
      expect(find.text('Caisse dollars · Aujourd\'hui'), findsOneWidget);
      expect(find.byType(FinanceTillBucketsSection), findsOneWidget);
      expect(find.text('Par source'), findsOneWidget);
      expect(find.text('Par classe'), findsOneWidget);
      expect(
        find.textContaining('Journée du'),
        findsOneWidget,
        reason:
            'l’en-tête, les caisses, le graphique et les ventilations viennent '
            'd’un appel qui a réussi : un droit manquant sur la table ne les '
            'emporte pas',
      );
    });

    testWidgets('la ligne croisée écrit son taux comme partout ailleurs', (
      tester,
    ) async {
      await pump(
        tester,
        _till([_block('USD')]),
        receiptsState: FinanceTillReceiptsState(
          status: FinanceTillReceiptsStatus.success,
          currency: 'USD',
          totalElements: 1,
          totalPages: 1,
          receipts: [
            TillReceipt(
              paymentId: 'p-1',
              paidAt: DateTime.utc(2026, 5, 15, 10),
              source: 'BILLING',
              amount: 4000,
              currency: 'USD',
              receiptNumber: 'ETL-RC-2526-000183',
              studentName: 'Ilunga Kasongo Esther',
              settledAmount: 11500000,
              settledCurrency: 'CDF',
              rateMicros: 2850000000,
            ),
          ],
        ),
      );

      // ⚠️ « taux 2 850,00 » et non « taux 2850 » comme l'écrit la maquette.
      // Ce taux-ci est celui DU REÇU ; le bandeau porte celui DU JOUR. Deux
      // nombres différents par nature : si leurs formats différaient aussi, on
      // ne pourrait plus savoir si un écart est dans la valeur ou dans
      // l'écriture.
      expect(find.textContaining('taux 2\u00A0850,00'), findsOneWidget);
      // Le montant soldé est LU sur les imputations, jamais dérivé du taux.
      expect(find.textContaining('115\u00A0000\u00A0FC'), findsOneWidget);

      // ⚠️ La mention dit ce qui s'est passé, pas POURQUOI il y a deux devises
      // sur une ligne. L'explication est une infobulle — donc aussi une
      // étiquette d'accessibilité : une mention qui ne s'obtiendrait qu'à la
      // souris n'existerait pas sur la tablette du caissier.
      final tooltip = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((t) => t.message)
          .whereType<String>()
          .where((m) => m.startsWith('Frais fixé'))
          .toList();
      expect(tooltip, ['Frais fixé en francs, réglé en dollars']);
    });

    testWidgets('une panne réseau sur la table ne se lit pas comme un refus', (
      tester,
    ) async {
      await pump(
        tester,
        _till([_block('USD')]),
        receiptsState: const FinanceTillReceiptsState(
          status: FinanceTillReceiptsStatus.error,
          currency: 'USD',
          failure: NetworkFailure('offline'),
        ),
      );

      expect(find.textContaining('n\'ont pas pu être chargés'), findsOneWidget);
      expect(
        find.textContaining('droit de lecture des paiements'),
        findsNothing,
        reason:
            'un droit manquant et une panne appellent deux gestes différents : '
            'les confondre enverrait le caissier réessayer un refus',
      );
    });

    testWidgets('le sous-titre aligne trois chiffres de FENÊTRE', (
      tester,
    ) async {
      await pump(
        tester,
        _till([_block('USD', fees: 400000, boutique: 12000)]),
        receiptsState: const FinanceTillReceiptsState(
          status: FinanceTillReceiptsStatus.success,
          currency: 'USD',
          totalElements: 17,
          totalPages: 3,
          // Compté par le serveur sur la fenêtre : la page n'en montre que 8.
          withoutReceiptNumber: 2,
        ),
      );

      expect(
        find.textContaining('17 encaissements'),
        findsOneWidget,
        reason: 'le compte porte sur la fenêtre, pas sur la page affichée',
      );
      expect(
        find.textContaining('2 sans pièce scellée'),
        findsOneWidget,
        reason:
            'compté sur la page, ce chiffre changerait à chaque tour de '
            'pagination sous un total immobile',
      );
    });

    testWidgets('sans rattrapage, le sous-titre n’en parle pas', (
      tester,
    ) async {
      await pump(
        tester,
        _till([_block('USD')]),
        receiptsState: const FinanceTillReceiptsState(
          status: FinanceTillReceiptsStatus.success,
          currency: 'USD',
          totalElements: 5,
          totalPages: 1,
        ),
      );

      expect(find.textContaining('sans pièce scellée'), findsNothing);
    });
  });

  group('lectures & alertes', () {
    testWidgets('aucune carte n’expose de bouton — elles expliquent', (
      tester,
    ) async {
      await pump(tester, _till([_block('USD')]));

      expect(find.text('Lectures & alertes'), findsOneWidget);
      // Un bouton ici promettrait une action que cet écran n'a pas : il est en
      // lecture seule, et la décision se prend en Facturation.
      expect(
        find.descendant(
          of: find.byType(FinanceTillInsightsSection),
          matching: find.byType(ElevatedButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(FinanceTillInsightsSection),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
    });

    testWidgets('un seul taux se cite ; plusieurs donnent une FOURCHETTE', (
      tester,
    ) async {
      await pump(
        tester,
        _till(
          [_block('USD')],
          crossed: const TillCrossed(
            count: 3,
            amounts: [TillCurrencyAmount(currency: 'USD', amount: 13500)],
            rateMicros: [2850000000],
          ),
        ),
      );
      // ⚠️ « 2 850,00 » et non « 2850 » : un taux n'a qu'une écriture dans
      // cette application. Ce taux-ci est celui du reçu, le bandeau porte celui
      // du jour — deux nombres différents PAR NATURE, et deux formats
      // empêcheraient de savoir si un écart est dans la valeur ou dans
      // l'écriture.
      expect(find.textContaining('au taux de 2\u00A0850,00'), findsOneWidget);

      await pump(
        tester,
        _till(
          [_block('USD')],
          crossed: const TillCrossed(
            count: 3,
            amounts: [TillCurrencyAmount(currency: 'USD', amount: 13500)],
            rateMicros: [2850000000, 2900000000],
          ),
        ),
      );
      // C'est le changement de taux en cours de fenêtre qui explique l'écart de
      // caisse : en citer un seul en tairait un autre.
      expect(
        find.textContaining('à des taux de 2\u00A0850,00 à 2\u00A0900,00'),
        findsOneWidget,
      );
    });

    testWidgets('les montants croisés ne s’additionnent jamais', (
      tester,
    ) async {
      await pump(
        tester,
        _till(
          [_block('USD')],
          crossed: const TillCrossed(
            count: 5,
            amounts: [
              TillCurrencyAmount(currency: 'USD', amount: 13500),
              TillCurrencyAmount(currency: 'CDF', amount: 1150000),
            ],
            rateMicros: [2850000000],
          ),
        ),
      );

      // Deux montants côte à côte, reliés par « et » — jamais par un « + », et
      // jamais fondus en un total. (L'espace avant le symbole est insécable :
      // on assert sur les chiffres.)
      // Deux montants côte à côte, reliés par « et » — jamais par un « + », et
      // jamais fondus en un total. Chacun garde son symbole et ses décimales
      // propres : le franc n'en affiche pas, le dollar si.
      final body = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(FinanceTillInsightsSection),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data ?? '')
          .firstWhere((text) => text.contains('versements règlent'))
          // Les montants portent des espaces **insécables** — séparateur de
          // milliers et avant le symbole. On normalise pour asserter sur ce que
          // le caissier lit, pas sur des points de code.
          .replaceAll('\u00A0', ' ');

      expect(body, contains('135,00 \$'));
      expect(body, contains('11 500 FC'));
      expect(
        body,
        isNot(contains('635')),
        reason: 'les deux caisses ne s’additionnent jamais, même ici',
      );
    });

    testWidgets('sans croisement, la carte reste et le dit', (tester) async {
      await pump(tester, _till([_block('USD')]));

      expect(
        find.textContaining('Aucun paiement croisé'),
        findsOneWidget,
        reason:
            'une carte absente laisserait croire qu’on a oublié de regarder — '
            '« aucun croisement » est une information',
      );
    });

    testWidgets('la part du jour le plus fort est LUE, pas recalculée', (
      tester,
    ) async {
      await pump(
        tester,
        _till([
          _block(
            'USD',
            bestBucket: const TillBestBucket(
              key: '2026-05-14',
              amount: 130000,
              sharePercent: 22,
            ),
          ),
        ]),
      );

      // 22 % vient du serveur, rapporté à ce qui est DESSINÉ. Recalculé sur la
      // fenêtre comptée, il vaudrait 100 % sur une journée.
      expect(find.textContaining('22 %'), findsOneWidget);
      expect(find.textContaining('14 mai 2026'), findsOneWidget);
    });

    testWidgets('une caisse creuse n’a pas de meilleur jour', (tester) async {
      await pump(tester, _till([_block('USD')]));

      expect(find.text('Jour le plus fort'), findsNothing);
    });

    testWidgets('la baisse porte une phrase d’action, la hausse non', (
      tester,
    ) async {
      await pump(tester, _till([_block('USD', trendPercent: -7)]));
      expect(find.textContaining('Vérifiez si une relance'), findsOneWidget);

      await pump(tester, _till([_block('USD', trendPercent: 18)]));
      expect(find.textContaining('Vérifiez si une relance'), findsNothing);
      expect(find.textContaining('Le rythme se maintient'), findsOneWidget);
    });
  });

  group('les icônes', () {
    testWidgets('chaque carte porte le repère de son sujet', (tester) async {
      await pump(tester, _till([_block('USD')]));

      // ⚠️ **Le repère double le titre, il ne le remplace pas** : chaque titre
      // reste écrit en toutes lettres. L'icône sert à retrouver une carte d'un
      // coup d'œil dans une page qui en empile six.
      //
      // Aucune n'est choisie librement : chacune est **déjà** celle de son
      // sujet ailleurs dans l'application — la flèche de la carte « Tendance »,
      // la pastille « facturation » de la table des reçus, les créances et les
      // versements de Facturation. Une icône inventée ici ferait de la même
      // chose deux sujets.
      const expected = <String, IconData>{
        'Progression des encaissements · caisse dollars':
            Icons.trending_up_rounded,
        'Par source': Icons.account_balance,
        'Créances réglées en \$': Icons.receipt_long_outlined,
        'Par classe': Icons.groups_outlined,
        'Reçus de la caisse dollars': Icons.payments_outlined,
      };

      for (final entry in expected.entries) {
        final heading = find.text(entry.key);
        expect(heading, findsOneWidget, reason: entry.key);

        // Scopé à la carte du titre : la même icône vit ailleurs à l'écran (la
        // flèche est aussi sur la tuile de caisse, la colonne « source »
        // reprend `account_balance`), et un `find.byIcon` global passerait sans
        // rien prouver.
        final card = find.ancestor(
          of: heading,
          matching: find.byType(FinanceStatsChartCard),
        );
        expect(card, findsOneWidget, reason: entry.key);
        expect(
          find.descendant(of: card, matching: find.byIcon(entry.value)),
          findsWidgets,
          reason: entry.key,
        );
      }
    });

    testWidgets('un titre hors carte n’en porte pas', (tester) async {
      // Deux caisses : sans elles, « Détail de la caisse » n'existe pas — un
      // sélecteur à un segment n'offrirait aucun choix.
      await pump(tester, _till([_block('USD'), _block('CDF')]));

      // « Lectures & alertes » et « Détail de la caisse » chapeautent des
      // ensembles, ils ne nomment pas une carte : leur donner un repère les
      // ferait passer pour une carte de plus.
      for (final title in const ['Lectures & alertes', 'Détail de la caisse']) {
        final heading = find.text(title);
        expect(heading, findsOneWidget, reason: title);
        expect(
          find.ancestor(
            of: heading,
            matching: find.byType(FinanceStatsChartCard),
          ),
          findsNothing,
          reason: title,
        );
      }
    });

    testWidgets('celles qui existent sont RENDUES et visibles', (tester) async {
      await pump(tester, _till([_block('USD')]));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();

      expect(
        icons,
        isNotEmpty,
        reason: 'médaillons de tuiles, de lectures, et pastilles de source',
      );
      // ⚠️ Le vrai risque n'est pas l'absence d'icône dans l'arbre, c'est une
      // icône **posée mais invisible** — teinte transparente, ou teinte du
      // fond. Une lecture du code ne l'attrape pas ; cette assertion si.
      for (final icon in icons) {
        expect(icon.icon, isNotNull);
        final color = icon.color;
        if (color == null) continue; // héritée du thème, qui n'en écrase aucune
        expect(
          color.a,
          greaterThan(0),
          reason: 'une icône transparente est une icône absente',
        );
        expect(
          color,
          isNot(AppColors.surfaceRaised),
          reason: 'une icône de la teinte du fond est une icône absente',
        );
      }
    });
  });
}
