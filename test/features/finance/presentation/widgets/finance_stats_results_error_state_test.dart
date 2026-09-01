import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/finance_stats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'anatomie d'erreur du pilotage financier.
///
/// L'écran rendait une carte ad hoc : un titre unique, « Erreur de chargement »,
/// et le même bouton « Réessayer » pour les quatre familles — y compris pour un
/// droit manquant, que réessayer n'a jamais donné.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onReconnect,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinanceStatsResultsErrorState(
              failure: failure,
              onRetry: onRetry ?? () {},
              onReconnect: onReconnect ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('réseau : on réessaie', (tester) async {
    await pump(tester, const NetworkFailure('offline'));

    expect(find.byType(EteeloErrorResult), findsOneWidget);
    expect(find.text('Connexion indisponible'), findsOneWidget);
    expect(find.textContaining('Vérifiez votre connexion'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('401 : on se reconnecte, on ne réessaie pas', (tester) async {
    await pump(tester, const InvalidCredentialsFailure('expired'));

    expect(find.text('Session expirée'), findsOneWidget);
    expect(find.text('Se reconnecter'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('403 : AUCUNE action de reprise', (tester) async {
    await pump(tester, const UnauthorizedFailure('forbidden'));

    expect(find.text('Accès refusé'), findsOneWidget);
    expect(
      find.textContaining('pas autorisé à consulter ces statistiques'),
      findsOneWidget,
    );
    // Réessayer un droit qu'on n'a pas ne le donne pas : l'absence de bouton
    // est ici le bon message. Cas réel — un enseignant arrive sur l'URL du
    // tableau de bord.
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('Se reconnecter'), findsNothing);
  });

  testWidgets('500 : on réessaie, avec le code d’incident à citer', (
    tester,
  ) async {
    await pump(
      tester,
      const ApiServerFailure(incidentId: 'INC-4821', message: 'boom'),
    );

    expect(find.text('Chargement impossible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('INC-4821'), findsOneWidget);
  });

  testWidgets('le message garde le grain du Failure, pas celui de la famille', (
    tester,
  ) async {
    // Une ancre incohérente part en 400 côté serveur. Replier ce cas sous « une
    // erreur inattendue est survenue » perdrait la seule information qui
    // distingue un bug de l'application d'une panne du serveur.
    await pump(tester, const ValidationFailure('Invalid request data'));

    expect(
      find.textContaining('paramètres demandés sont invalides'),
      findsOneWidget,
    );
  });

  testWidgets('sans geste de reprise offert, aucun bouton n’est inventé', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FinanceStatsResultsErrorState(
              failure: NetworkFailure('offline'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réessayer'), findsNothing);
  });
}
