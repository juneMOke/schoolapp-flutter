import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payer_search_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Repo de test : seules les deux lectures d'annuaire comptent ici.
class _FakeRepo implements FinanceOfflineRepository {
  Either<Failure, List<LocalPayerIdentity>> suggestions = const Left(
    StorageFailure('base illisible'),
  );
  int suggestionCalls = 0;

  @override
  Future<Either<Failure, List<LocalPayerIdentity>>> getPayerSuggestions(
    String studentId, {
    int limit = 8,
  }) async {
    suggestionCalls++;
    return suggestions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('hors périmètre de cette popin');
}

/// « Réessayer » doit rejouer le chemin QUI A ÉCHOUÉ.
///
/// La popin a deux entrées : les suggestions, tirées à l'ouverture sans que
/// rien ne soit demandé, et la recherche explicite. Seule la seconde laisse des
/// critères derrière elle — un « Réessayer » qui n'en connaît que ceux-là est
/// mort là où l'erreur est la plus probable : au tout premier chargement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
    getIt.registerFactory<PayerSearchBloc>(
      () => PayerSearchBloc(
        suggestions: GetPayerSuggestionsUseCase(repo),
        search: SearchPayersUseCase(repo),
      ),
    );
  });

  tearDown(() async => getIt.reset());

  Future<void> ouvrirLaPopin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showFacturationPayerSearchDialog(
                context: context,
                studentId: 'stu-1',
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'erreur au chargement initial : « Réessayer » relance les suggestions',
    (tester) async {
      await ouvrirLaPopin(tester);

      expect(find.text('Erreur d\'accès à la base locale.'), findsOneWidget);
      expect(repo.suggestionCalls, 1);

      final reessayer = find.text('Réessayer');
      await tester.ensureVisible(reessayer);
      await tester.pumpAndSettle();
      await tester.tap(reessayer);
      await tester.pumpAndSettle();

      // Avant le correctif, aucun critère n'ayant été saisi, `_retry()`
      // sortait aussitôt : le bouton ne faisait RIEN, sans le dire.
      expect(repo.suggestionCalls, 2);
    },
  );

  testWidgets('la relance aboutit et affiche les suggestions', (tester) async {
    await ouvrirLaPopin(tester);

    repo.suggestions = const Right([
      LocalPayerIdentity(
        lastName: 'Kabongo',
        firstName: 'Joseph',
        phoneNumber: '+243816939060',
        origin: PayerOrigin.previousPayment,
        paymentCount: 2,
      ),
    ]);

    final reessayer = find.text('Réessayer');
    await tester.ensureVisible(reessayer);
    await tester.pumpAndSettle();
    await tester.tap(reessayer);
    await tester.pumpAndSettle();

    expect(find.text('Kabongo Joseph'), findsOneWidget);
  });
}
