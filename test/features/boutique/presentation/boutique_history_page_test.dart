import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_history_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_history_bloc.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_history_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_sale_detail_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_history_sale_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetHistory extends Mock implements GetBoutiqueSalesHistoryUseCase {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// La fiche a ses propres tests : ici on ne vérifie que le CHAÎNAGE. Sa lecture
/// répond « introuvable », l'issue la plus courte qui monte l'écran — la laisser
/// en vol ferait expirer `pumpAndSettle` sur une modale de chargement.
class _MockGetSaleDetail extends Mock implements GetBoutiqueSaleDetailUseCase {}

class _MockMarkPrinted extends Mock implements MarkSaleTicketPrintedUseCase {}

SaleHistoryEntry _sale({
  String id = 's-1',
  String payer = 'Ndombo Lelo Willy',
  int total = 1500,
  String syncStatus = 'SYNCED',
  String? receiptNumber = 'RV-2026-0001',
}) => SaleHistoryEntry(
  id: id,
  payerName: payer,
  totalInCents: total,
  currency: 'USD',
  soldAt: '2026-08-30T09:00:00Z',
  syncStatus: syncStatus,
  receiptNumber: receiptNumber,
  articleCount: 2,
);

AcademicYearContextState _readyContext() => const AcademicYearContextState(
  status: AcademicYearContextLoadStatus.success,
  context: AcademicYearContext(
    academicYear: AcademicYear(id: 'ay-1', name: '2026-2027', current: true),
    schoolLevelGroups: [],
  ),
);

void main() {
  late _MockGetHistory getHistory;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(SalesHistoryPeriod.day));

  setUp(() {
    getHistory = _MockGetHistory();
    academicYearBloc = _MockAcademicYearBloc();
    authBloc = _MockAuthBloc();
    when(() => academicYearBloc.state).thenReturn(_readyContext());
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.authenticated));

    GetIt.I.registerFactory<BoutiqueHistoryBloc>(
      () => BoutiqueHistoryBloc(getHistory: getHistory),
    );
  });

  tearDown(() => GetIt.I.reset());

  void answer(List<SaleHistoryEntry> sales) => when(
    () => getHistory(
      academicYearId: any(named: 'academicYearId'),
      period: any(named: 'period'),
    ),
  ).thenAnswer((_) async => Right(sales));

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: BoutiqueHistoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('l\'écran ouvre sur la caisse DU JOUR', (tester) async {
    // Ouvrir sur l'année ferait défiler des mois pour trouver la vente d'il y a
    // deux minutes.
    answer([_sale()]);

    await pumpPage(tester);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Aujourd\'hui'),
    );
    expect(chip.selected, isTrue);
    verify(
      () => getHistory(academicYearId: 'ay-1', period: SalesHistoryPeriod.day),
    ).called(1);
  });

  testWidgets('les ventes se listent, avec leur total de fenêtre', (
    tester,
  ) async {
    answer([_sale(id: 's-1'), _sale(id: 's-2', total: 2500)]);

    await pumpPage(tester);

    expect(find.byType(BoutiqueHistorySaleTile), findsNWidgets(2));
    // Le total NOMME la fenêtre qu'il additionne.
    expect(find.textContaining('Total encaissé'), findsOneWidget);
    expect(find.textContaining('Aujourd\'hui'), findsWidgets);
    expect(find.text('2 ventes'), findsOneWidget);
  });

  testWidgets('changer de fenêtre relit avec la NOUVELLE période', (
    tester,
  ) async {
    answer([_sale()]);
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Ce mois'));
    await tester.pumpAndSettle();

    verify(
      () =>
          getHistory(academicYearId: 'ay-1', period: SalesHistoryPeriod.month),
    ).called(1);
  });

  testWidgets('une vente NON PARTIE se dit, et se compte', (tester) async {
    // C'est la raison d'être d'une lecture locale : le serveur ne la connaît
    // pas encore, et le guichet doit la voir avant d'éteindre la tablette.
    answer([
      _sale(id: 's-1'),
      _sale(id: 's-2', syncStatus: 'PENDING_SYNC', receiptNumber: null),
    ]);

    await pumpPage(tester);

    expect(find.text('En attente'), findsOneWidget);
    expect(
      find.textContaining('n\'est pas encore partie au serveur'),
      findsOneWidget,
    );
  });

  testWidgets('taper une ligne OUVRE la fiche de la vente', (tester) async {
    // La ligne EST le geste : au guichet, un chevron discret ne se vise pas, et
    // un parent qui revient avec son ticket attend qu'on retrouve sa vente d'un
    // doigt.
    answer([_sale(id: 's-42')]);
    final getSaleDetail = _MockGetSaleDetail();
    when(
      () => getSaleDetail(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));
    GetIt.I.registerFactory<GetBoutiqueSaleDetailUseCase>(() => getSaleDetail);
    GetIt.I.registerFactory<MarkSaleTicketPrintedUseCase>(
      () => _MockMarkPrinted(),
    );

    await pumpPage(tester);
    await tester.tap(find.byType(BoutiqueHistorySaleTile));
    await tester.pumpAndSettle();

    expect(find.byType(BoutiqueSaleDetailPage), findsOneWidget);
  });

  testWidgets('caisse vide : on le DIT, on ne laisse pas un blanc', (
    tester,
  ) async {
    answer(const []);

    await pumpPage(tester);

    expect(find.text('Aucune vente sur cette période'), findsOneWidget);
  });

  testWidgets('base illisible : l\'écran passe en ERREUR, pas en vide', (
    tester,
  ) async {
    // Dire « aucune vente » à un guichet qui vient d'en encaisser trois serait
    // pire qu'une erreur.
    when(
      () => getHistory(
        academicYearId: any(named: 'academicYearId'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('illisible')));

    await pumpPage(tester);

    expect(find.text('Aucune vente sur cette période'), findsNothing);
    // Et le message NOMME la caisse, pas le catalogue : chercher une panne de
    // catalogue quand on vient consulter ses ventes ferait perdre du temps au
    // guichet.
    expect(find.text('Historique illisible'), findsOneWidget);
    expect(find.textContaining('caisse locale'), findsOneWidget);
  });
}
