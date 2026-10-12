import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/announcement_editor_screen.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementRepository {}

void main() {
  late _MockRepository repo;
  final now = DateTime.utc(2026, 10, 12, 9);

  setUpAll(() => registerFallbackValue(const AnnouncementContent()));
  setUp(() => repo = _MockRepository());

  Future<List<AnnouncementEditorOutcome>> pump(
    WidgetTester tester,
    AnnouncementEditorCubit cubit,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final outcomes = <AnnouncementEditorOutcome>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: AnnouncementEditorScreen(
              now: () => now,
              onBack: () {},
              onDone: (outcome, _) => outcomes.add(outcome),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return outcomes;
  }

  AnnouncementEditorCubit fresh() => AnnouncementEditorCubit.create(
    id: 'uuid',
    writer: AnnouncementWriter(repo),
    now: () => now,
  );

  testWidgets('écrire, insérer au curseur, envoyer', (tester) async {
    when(
      () => repo.create(
        id: any(named: 'id'),
        content: any(named: 'content'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => Right(announcement(id: 'uuid')));
    when(() => repo.send('uuid', version: any(named: 'version'))).thenAnswer(
      (_) async =>
          Right(announcement(id: 'uuid', status: AnnouncementStatus.sent)),
    );
    final cubit = fresh();
    final outcomes = await pump(tester, cubit);

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Réunion');
    await tester.enterText(fields.at(1), 'Chers parents de , bonjour.');
    // Le curseur après « de » : la variable s'y glisse.
    final body = tester.widget<EditableText>(fields.at(1)).controller;
    body.selection = const TextSelection.collapsed(offset: 17);
    await tester.tap(find.text("Nom de l'élève"));
    await tester.pump();
    expect(cubit.state.content.body, 'Chers parents de {eleve}, bonjour.');

    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(outcomes, [AnnouncementEditorOutcome.sent]);
  });

  testWidgets('envoyer vide : les champs le disent, rien ne part', (
    tester,
  ) async {
    await pump(tester, fresh());
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.text('Donnez un titre au communiqué.'), findsOneWidget);
    expect(find.text('Écrivez le message.'), findsOneWidget);
    verifyZeroInteractions(repo);
  });

  testWidgets('le montant hors des retards : bouton grisé', (tester) async {
    await pump(tester, fresh());
    final amount = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Montant dû'),
        matching: find.byType(TextButton),
      ),
    );
    expect(amount.onPressed, isNull);
  });

  testWidgets('programmé : le bandeau et l\'heure d\'envoi', (tester) async {
    final cubit = AnnouncementEditorCubit.edit(
      announcement: announcement(
        status: AnnouncementStatus.scheduled,
        scheduledAt: DateTime.utc(2026, 10, 13, 6, 30),
      ),
      writer: AnnouncementWriter(repo),
      now: () => now,
    );
    await pump(tester, cubit);
    expect(
      find.text(
        "Programmé demain · 07:30. Modifiable jusqu'à l'heure d'envoi.",
      ),
      findsOneWidget,
    );
    expect(find.text('Programmer'), findsWidgets);
    expect(find.text("Annuler l'envoi"), findsOneWidget);
  });

  testWidgets('lecture seule : aucune action', (tester) async {
    final cubit = AnnouncementEditorCubit.edit(
      announcement: announcement(),
      writer: AnnouncementWriter(repo),
      readOnly: true,
      now: () => now,
    );
    await pump(tester, cubit);
    expect(find.text('Envoyer'), findsNothing);
    expect(find.text('Brouillon'), findsNothing);
  });
}
