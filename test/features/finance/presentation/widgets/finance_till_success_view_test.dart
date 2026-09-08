import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_cash_boxes.dart';
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

  Future<void> pump(
    WidgetTester tester,
    FinanceTill till, {
    String? selectedCurrency,
    FinanceTillReceiptsState? receiptsState,
  }) async {
    selectedByTap = <String>[];
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
      _till([
        _block('CDF', fees: 0, boutique: 0, receiptCount: 0),
        _block('USD'),
      ]),
      // C'est la caisse SÉLECTIONNÉE qui est creuse : le détail ne décrit
      // qu'elle, et c'est là que la phrase remplace un axe plat.
      selectedCurrency: 'CDF',
    );

    expect(find.text('Aucun mouvement dans cette devise'), findsOneWidget);
    expect(
      find.text('Rien n\'est entré dans le tiroir sur cette période.'),
      findsOneWidget,
    );
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
      find.text('Encaissements jour par jour · caisse dollars'),
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
      find.text('Encaissements jour par jour · caisse dollars'),
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
}
