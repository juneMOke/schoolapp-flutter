import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_header.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockEnrollmentStatsBloc
    extends MockBloc<EnrollmentStatsEvent, EnrollmentStatsState>
    implements EnrollmentStatsBloc {}

Widget _host(Widget child, {double width = 1000}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  builder: (context, widget) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: widget!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('en-tête', () {
    testWidgets('dit où l\'on est, ce qu\'on regarde et à quelle date', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardHeader(
            schoolYear: '2026-2027',
            generatedAt: DateTime(2026, 9, 5),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INSCRIPTIONS'), findsOneWidget);
      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.textContaining('Année scolaire 2026-2027'), findsOneWidget);
      expect(find.textContaining('septembre 2026'), findsOneWidget);
    });

    testWidgets('sans données, ne DATE rien et n\'invente pas d\'année', (
      tester,
    ) async {
      // C'est l'en-tête d'un écran en erreur : il continue de dire quel écran
      // il est, sans prétendre à des chiffres qu'il n'a pas.
      await tester.pumpWidget(_host(const EnrollmentDashboardHeader()));
      await tester.pumpAndSettle();

      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.textContaining('Année scolaire'), findsNothing);
      expect(find.textContaining('septembre'), findsNothing);
    });
  });

  group('état vide', () {
    testWidgets('nomme la fenêtre cherchée', (tester) async {
      // « Aucune inscription » tout court laisserait croire que l'école est
      // vide, alors que l'onglet était resté sur la semaine.
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardEmptyState(
            windowLabel: 'Cette semaine',
            isWidestWindow: false,
            onSeeWholeYear: () {},
            onOpenFirstRegistration: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Cette semaine'), findsOneWidget);
      expect(find.byType(EteeloEmptyResult), findsOneWidget);
    });

    testWidgets('fenêtre étroite : élargir d\'abord, saisir ensuite', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardEmptyState(
            windowLabel: 'Ce mois',
            isWidestWindow: false,
            onSeeWholeYear: () {},
            onOpenFirstRegistration: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voir l\'année entière'), findsOneWidget);
      expect(find.text('Ouvrir Première inscription'), findsOneWidget);
    });

    testWidgets(
      'fenêtre la plus large : aucune proposition d\'élargir, une seule issue',
      (tester) async {
        // Proposer « voir l'année entière » alors qu'on Y EST déjà est une
        // impasse : le clic ne changerait rien et l'utilisateur conclurait que
        // l'écran est cassé.
        await tester.pumpWidget(
          _host(
            EnrollmentDashboardEmptyState(
              windowLabel: 'Année',
              isWidestWindow: true,
              onOpenFirstRegistration: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Voir l\'année entière'), findsNothing);
        expect(find.text('Ouvrir Première inscription'), findsOneWidget);
        expect(find.textContaining('la fenêtre la plus large'), findsOneWidget);
      },
    );
  });

  group('état d\'erreur — quatre familles, quatre gestes', () {
    testWidgets('réseau : on propose de réessayer', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardErrorState(
            failure: const NetworkFailure('coupure'),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pas de connexion'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('403 : accès refusé, et JAMAIS de bouton « Réessayer »', (
      tester,
    ) async {
      // Le piège du mapping : 403 arrive en `UnauthorizedFailure`, dont le nom
      // invite à le lire comme un 401. Réessayer un droit qu'on n'a pas ne le
      // donne pas ; offrir le bouton invite à s'acharner.
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardErrorState(
            failure: const UnauthorizedFailure('403'),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accès refusé'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
      expect(find.byType(EteeloButton), findsNothing);
    });

    testWidgets('401 : session expirée, la reprise est globale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardErrorState(
            failure: const InvalidCredentialsFailure('401'),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session expirée'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('500 : réessayer, et le code d\'incident à citer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardErrorState(
            failure: const ServerFailure('boom'),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byType(EteeloErrorResult), findsOneWidget);
    });
  });

  group('chargement', () {
    testWidgets('la silhouette remplace le rond qui tourne', (tester) async {
      // Règle non négociable n°10 : aucune zone de résultats ne monte son
      // propre indicateur.
      await tester.pumpWidget(
        _host(const EnrollmentDashboardSkeleton(kpiCount: 5)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(EnrollmentDashboardSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('elle s\'annonce comme une région vivante', (tester) async {
      await tester.pumpWidget(
        _host(const EnrollmentDashboardSkeleton(kpiCount: 4)),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel('Chargement du tableau de bord des inscriptions'),
        findsOneWidget,
      );
    });
  });

  group('la page assemble le tout', () {
    testWidgets('en erreur, aucun chiffre ne subsiste sous l\'en-tête', (
      tester,
    ) async {
      // La règle « l'erreur remplace tout le contenu sous l'en-tête » est
      // tenue à la source : le bloc a vidé `stats`, donc il n'y a rien à
      // masquer. Ce test vérifie l'absence de rendu partiel.
      final bloc = _MockEnrollmentStatsBloc();
      whenListen(
        bloc,
        const Stream<EnrollmentStatsState>.empty(),
        initialState: const EnrollmentStatsState(
          status: EnrollmentStatsStatus.error,
          failure: ServerFailure('boom'),
        ),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _host(
          BlocProvider<EnrollmentStatsBloc>.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                final state = bloc.state;
                return Column(
                  children: [
                    EnrollmentDashboardHeader(
                      schoolYear: state.stats?.context.schoolYear,
                      generatedAt: state.stats?.context.generatedAt,
                    ),
                    EnrollmentDashboardErrorState(
                      failure: state.failure!,
                      onRetry: () {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.byType(EnrollmentDashboardErrorState), findsOneWidget);
      // Aucune année, aucune date : l'en-tête s'est replié faute de données.
      expect(find.textContaining('Année scolaire'), findsNothing);
    });
  });
}
