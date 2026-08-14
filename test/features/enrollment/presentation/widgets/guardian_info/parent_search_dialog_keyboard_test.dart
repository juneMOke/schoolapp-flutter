import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_parents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_search_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockSearchParentsUseCase extends Mock implements SearchParentsUseCase {}

/// `Dialog` retire la hauteur du clavier (`viewInsets`) à ce qu'il offre à son
/// contenu. En paysage il ne reste qu'une centaine de dp, quand l'en-tête et le
/// formulaire de critères figés en coûtent trois fois plus : la modale
/// débordait dès que le clavier s'ouvrait sur un de ses quatre champs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSearchParentsUseCase searchUseCase;

  setUp(() {
    searchUseCase = _MockSearchParentsUseCase();
    when(
      () => searchUseCase(
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        surname: any(named: 'surname'),
        phoneNumber: any(named: 'phoneNumber'),
      ),
    ).thenAnswer((_) async => const Right(<LocalParent>[]));

    getIt.registerFactory<ParentSearchBloc>(
      () => ParentSearchBloc(search: searchUseCase),
    );
  });

  tearDown(() async => getIt.reset());

  Future<void> openDialogAt(WidgetTester tester, Size surface) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showParentSearchDialog(context: context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('paysage, clavier ouvert : la modale ne déborde plus', (
    tester,
  ) async {
    // 187 dp de haut moins les 2 × 24 dp d'inset ≈ les 139 dp qui restent à la
    // modale sur un téléphone en paysage clavier ouvert.
    await openDialogAt(tester, const Size(961.5, 187));

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'les critères doivent rejoindre le défilement, pas déborder',
    );
    // Les champs restent atteignables — en défilant, pas en débordant.
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('hauteur confortable : les critères restent figés en tête', (
    tester,
  ) async {
    await openDialogAt(tester, const Size(961.5, 900));

    expect(tester.takeException(), isNull);
    // Disposition d'origine : formulaire hors du défilement des résultats.
    final scrollable = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollable, findsOneWidget);
    expect(
      find.descendant(of: scrollable, matching: find.text('Rechercher')),
      findsNothing,
      reason: 'le bouton Rechercher appartient au bloc figé, pas au défilement',
    );
  });
}
