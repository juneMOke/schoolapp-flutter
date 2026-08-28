import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/configuration/domain/academic_year_proposal.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/academic_year_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

void main() {
  final today = DateTime(2026, 8, 28);
  late ConfigurationBloc bloc;

  setUp(() {
    bloc = ConfigurationBloc(
      repository: _MockRepository(),
      draftRepository: _MockDraftRepository(),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<ConfigurationBloc>.value(
            value: bloc,
            child: SingleChildScrollView(child: AcademicYearStep(today: today)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('une année est proposée sans que rien n\'ait été saisi', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('2026-2027'), findsOneWidget);
    expect(find.text('Proposée automatiquement'), findsOneWidget);
    // Rien à rétablir tant que rien n'a été touché.
    expect(find.text('Rétablir la proposition'), findsNothing);
  });

  testWidgets('une date touchée fait apparaître « Modifiée » et le retour', (
    tester,
  ) async {
    bloc.add(
      ConfigurationDraftChanged(
        ProvisioningRequest(
          academicYear: AcademicYearProposal.forDate(
            today,
          ).copyWith(endDate: DateTime.utc(2027, 7, 15)),
        ),
        simulate: false,
      ),
    );
    await pump(tester);

    expect(find.text('Modifiée'), findsOneWidget);
    expect(find.text('Rétablir la proposition'), findsOneWidget);
  });

  testWidgets('rétablir reconstruit la proposition du jour', (tester) async {
    bloc.add(
      ConfigurationDraftChanged(
        ProvisioningRequest(
          academicYear: AcademicYearProposal.forDate(
            today,
          ).copyWith(name: 'bricolé'),
        ),
        simulate: false,
      ),
    );
    await pump(tester);

    await tester.tap(find.text('Rétablir la proposition'));
    await tester.pumpAndSettle();

    expect(
      bloc.state.draft.academicYear,
      AcademicYearProposal.forDate(today),
      reason:
          'la proposition se reconstruit, elle ne se restaure pas d\'un '
          'état mémorisé',
    );
  });

  testWidgets('une fin avant le début se dit, dans le champ ET dans la durée', (
    tester,
  ) async {
    bloc.add(
      ConfigurationDraftChanged(
        ProvisioningRequest(
          academicYear: AcademicYearProposal.forDate(
            today,
          ).copyWith(endDate: DateTime.utc(2026, 1, 1)),
        ),
        simulate: false,
      ),
    );
    await pump(tester);

    // Deux fois : l'erreur du champ de date, et la zone de durée qui cesse
    // d'afficher un « ≈ -8 mois » qui ne veut rien dire.
    expect(find.text('La fin doit suivre le début'), findsNWidgets(2));
  });

  testWidgets('le renvoi vers Résultats pour les périodes est visible', (
    tester,
  ) async {
    await pump(tester);

    // Sans ce renvoi, la première demande d'évolution du module est
    // « ajoutez les trimestres ici » — alors que le type de période est porté
    // par le cycle, servi par le catalogue.
    expect(find.textContaining('Le découpage en périodes'), findsOneWidget);
  });
}
