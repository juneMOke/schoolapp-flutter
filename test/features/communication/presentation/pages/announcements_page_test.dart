import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/helpers/owner_scoped_value.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/audience_referential_repository.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/domain/usecases/announcement_writer.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/announcements_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_referential_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_student_search_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_factory.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/pending_announcement_seed.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcements_page.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../communication_fixtures.dart';

class _Announcements extends Mock implements AnnouncementRepository {}

class _Audience extends Mock implements AnnouncementAudienceRepository {}

class _Referential extends Mock implements AudienceReferentialRepository {}

class _Templates extends Mock implements AnnouncementTemplateRepository {}

class _Year extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _School extends MockCubit<SchoolIdentityState>
    implements SchoolIdentityCubit {}

class _Titles extends MockCubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {}

/// La page telle que la coquille la monte, avec ses fabriques réelles : le
/// seul test qui voit l'éditeur dans son vrai fond de page.
void main() {
  final getIt = GetIt.instance;
  late _Announcements announcements;
  late _Templates templates;

  setUpAll(() {
    registerFallbackValue(const AnnouncementContent());
    registerFallbackValue(const SchoolAudience());
    registerFallbackValue(AnnouncementCategory.info);
  });

  setUp(() async {
    await getIt.reset();
    announcements = _Announcements();
    templates = _Templates();
    final audience = _Audience();
    final referential = _Referential();
    final titles = _Titles();
    when(() => titles.state).thenReturn(const FeeSectionTitlesState());
    when(
      () => announcements.list(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => audience.reach(any()),
    ).thenAnswer((_) async => const Right(reach));
    when(
      () => referential.load(any()),
    ).thenAnswer((_) async => const Right(AudienceReferential()));
    getIt
      ..registerFactory(
        () => AnnouncementsCubit(
          repository: announcements,
          memory: OwnerScopedValue(
            const AnnouncementFilters(),
            owner: () => 'u',
          ),
        ),
      )
      ..registerSingleton(PendingAnnouncementSeed(owner: () => 'u'))
      ..registerFactory(
        () => AnnouncementEditorFactory(
          writer: AnnouncementWriter(announcements),
          uuid: const Uuid(),
        ),
      )
      ..registerFactory(
        () => AnnouncementReachCubit(audience, debounce: Duration.zero),
      )
      ..registerFactory(() => AudienceReferentialCubit(referential))
      ..registerFactory(() => AudienceStudentSearchCubit(audience))
      ..registerFactory(() => AnnouncementTemplatesCubit(templates))
      ..registerFactory<FeeSectionTitlesCubit>(() => titles);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester, {
    Size window = const Size(1400, 1000),
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final year = _Year();
    when(() => year.state).thenReturn(
      const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'y-1',
            name: '2026-2027',
            current: true,
          ),
          schoolLevelGroups: [],
        ),
      ),
    );
    final school = _School();
    when(() => school.state).thenReturn(const SchoolIdentityState.unknown());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AcademicYearContextBloc>.value(value: year),
              BlocProvider<SchoolIdentityCubit>.value(value: school),
            ],
            child: const AnnouncementsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('« Nouveau » ouvre l\'éditeur sans erreur de mise en page', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Nouveau communiqué').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Contenu'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
  });

  testWidgets('« Enregistrer comme modèle » trouve ses modèles', (
    tester,
  ) async {
    when(
      () => templates.create(
        category: any(named: 'category'),
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        AnnouncementTemplate(
          id: 't',
          category: AnnouncementCategory.info,
          title: 'Réunion',
          body: 'Samedi.',
        ),
      ),
    );
    await pump(tester);
    await tester.tap(find.text('Nouveau communiqué').first);
    await tester.pumpAndSettle();
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Réunion');
    await tester.enterText(fields.at(1), 'Samedi.');
    await tester.tap(find.text('Enregistrer comme modèle'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    verify(
      () => templates.create(
        category: AnnouncementCategory.info,
        title: 'Réunion',
        body: 'Samedi.',
      ),
    ).called(1);
    await tester.pump();
    expect(find.text('Modèle enregistré'), findsOneWidget);
  });

  group('grand écran : la liste et le communiqué côte à côte', () {
    setUp(() {
      when(
        () => announcements.list(academicYearId: any(named: 'academicYearId')),
      ).thenAnswer(
        (_) async => Right([
          announcement(
            id: 'sent-1',
            status: AnnouncementStatus.sent,
            title: 'Fête de l\'école',
            sentAt: DateTime.utc(2026, 10, 10, 9),
            reachAtSend: reach,
          ),
        ]),
      );
    });

    testWidgets('sans communiqué ouvert, le volet y invite', (tester) async {
      await pump(tester, window: const Size(1600, 1000));
      expect(find.text('Choisissez un communiqué'), findsOneWidget);
      expect(find.text('Fête de l\'école'), findsOneWidget);
    });

    testWidgets('un envoyé s\'ouvre à côté, la liste reste', (tester) async {
      await pump(tester, window: const Size(1600, 1000));
      await tester.tap(find.text('Fête de l\'école'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Choisissez un communiqué'), findsNothing);
      // Le titre dans la liste, et dans le détail.
      expect(find.text('Fête de l\'école'), findsAtLeastNWidgets(2));
      expect(find.text('Nouveau communiqué'), findsWidgets);
    });

    testWidgets('écran moyen : la liste seule', (tester) async {
      await pump(tester);
      expect(find.text('Choisissez un communiqué'), findsNothing);
    });
  });
}
