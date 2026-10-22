import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_beneficiaries_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../dashboard_fixtures.dart';

class _MockCubit extends MockCubit<BoutiqueBeneficiariesState>
    implements BoutiqueBeneficiariesCubit {}

void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.loadMore()).thenAnswer((_) async {});
  });

  Future<void> pumpCard(WidgetTester tester, Failure? loadMoreFailure) async {
    when(() => cubit.state).thenReturn(
      BoutiqueBeneficiariesState(
        status: BeneficiariesStatus.ready,
        page: beneficiariesOf(count: 2, total: 4, size: 2),
        expanded: true,
        loadMoreFailure: loadMoreFailure,
      ),
    );
    await tester.pumpWidget(
      BlocProvider<BoutiqueBeneficiariesCubit>.value(
        value: cubit,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: SingleChildScrollView(child: BoutiqueBeneficiariesCard()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sans échec : « Charger la suite », aucun bandeau', (
    tester,
  ) async {
    await pumpCard(tester, null);
    expect(find.text('Charger la suite'), findsOneWidget);
    expect(find.textContaining("n'a pas pu être chargée"), findsNothing);
  });

  testWidgets('coupure : le bandeau le dit, le bouton devient « Réessayer »', (
    tester,
  ) async {
    await pumpCard(tester, const NetworkFailure('x'));
    expect(
      find.text(
        "Connexion perdue : la suite de la liste n'a pas pu être chargée.",
      ),
      findsOneWidget,
    );
    expect(find.text('Charger la suite'), findsNothing);
    await tester.tap(find.text('Réessayer'));
    verify(() => cubit.loadMore()).called(1);
  });

  testWidgets('403 : le bandeau, et jamais « Réessayer »', (tester) async {
    await pumpCard(tester, const UnauthorizedFailure('x'));
    expect(
      find.textContaining("Vous n'avez plus accès à cette liste"),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('Charger la suite'), findsNothing);
  });
}
