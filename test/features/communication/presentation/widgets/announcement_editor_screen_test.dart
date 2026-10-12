import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/audience_referential_repository.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_referential_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_student_search_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/announcement_editor_screen.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementRepository {}

class _MockAudience extends Mock implements AnnouncementAudienceRepository {}

class _MockReferential extends Mock implements AudienceReferentialRepository {}

class _MockTitles extends MockCubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {}

const _groups = [
  SchoolLevelGroupBundle(
    group: SchoolLevelGroup(id: 'g-1', name: 'Primaire', code: 'P'),
    levels: [
      SchoolLevel(
        id: 'l-6',
        name: '6ème primaire',
        code: '6P',
        displayOrder: 6,
        splitIntoClassrooms: true,
      ),
    ],
  ),
];

void main() {
  late _MockRepository repo;
  late _MockAudience audience;
  late _MockReferential referential;
  late _MockTitles titles;
  final now = DateTime.utc(2026, 10, 12, 9);

  setUpAll(() {
    registerFallbackValue(const AnnouncementContent());
    registerFallbackValue(const SchoolAudience());
  });
  setUp(() {
    repo = _MockRepository();
    audience = _MockAudience();
    referential = _MockReferential();
    titles = _MockTitles();
    when(() => titles.state).thenReturn(const FeeSectionTitlesState());
    when(
      () => audience.reach(any()),
    ).thenAnswer((_) async => const Right(reach));
    when(() => referential.load(any())).thenAnswer(
      (_) async => const Right(
        AudienceReferential(
          classrooms: [
            AudienceClassroom(id: 'c-a', name: '6e A', levelId: 'l-6'),
            AudienceClassroom(id: 'c-b', name: '6e B', levelId: 'l-6'),
          ],
        ),
      ),
    );
  });

  Future<List<AnnouncementEditorOutcome>> pump(
    WidgetTester tester,
    AnnouncementEditorCubit cubit, {
    bool keepSize = false,
  }) async {
    if (!keepSize) {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final outcomes = <AnnouncementEditorOutcome>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider(
                create: (_) =>
                    AnnouncementReachCubit(audience)
                      ..update(cubit.state.content.audience),
              ),
              BlocProvider(
                create: (_) =>
                    AudienceReferentialCubit(referential)..load('y-1'),
              ),
              BlocProvider(create: (_) => AudienceStudentSearchCubit(audience)),
              BlocProvider<FeeSectionTitlesCubit>.value(value: titles),
            ],
            child: AnnouncementEditorScreen(
              now: () => now,
              groups: _groups,
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
    // Le brouillon créé ne porte pas encore la saisie : un PUT la rattrape.
    when(
      () => repo.update('uuid', any(), version: any(named: 'version')),
    ).thenAnswer((_) async => Right(announcement(id: 'uuid', version: 2)));
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
    // Le récapitulatif d'abord : la portée, puis le geste irréversible.
    expect(find.text('Envoyer 113 messages ?'), findsOneWidget);
    await tester.tap(find.text('Envoyer maintenant'));
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

  testWidgets(
    'cibler des classes : le niveau les coche toutes, la portée suit',
    (tester) async {
      final cubit = fresh();
      await pump(tester, cubit);
      expect(find.text('113 messages joignables sur 120'), findsOneWidget);
      await tester.tap(find.text('Classes'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez au moins un destinataire.'), findsOneWidget);
      await tester.tap(find.text('6ème primaire'));
      await tester.pumpAndSettle();
      expect(
        cubit.state.content.audience,
        const ClassroomsAudience(['c-a', 'c-b']),
      );
      verify(
        () => audience.reach(const ClassroomsAudience(['c-a', 'c-b'])),
      ).called(1);
    },
  );

  testWidgets('aperçu : le gabarit WhatsApp, puis la page de lecture', (
    tester,
  ) async {
    final cubit = fresh()
      ..setTitle('Réunion')
      ..setBody('Bonjour {eleve} ({classe}).');
    await pump(tester, cubit);
    expect(
      find.textContaining(
        'vous adresse un communiqué concernant Grâce KABONGO',
      ),
      findsOneWidget,
    );
    expect(find.text('Lire le communiqué'), findsOneWidget);
    await tester.tap(find.text('Page de lecture'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Grâce KABONGO (6e A).'), findsOneWidget);
  });

  testWidgets('écran étroit : bascule Rédiger · Aperçu parent', (tester) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, fresh(), keepSize: true);
    expect(find.text('Lire le communiqué'), findsNothing);
    await tester.tap(find.text('Aperçu parent'));
    await tester.pumpAndSettle();
    expect(find.text('Lire le communiqué'), findsOneWidget);
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
