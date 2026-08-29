import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/cubit/school_identity_form_cubit.dart';
import 'package:school_app_flutter/features/configuration/presentation/pages/configuration_settings_page.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

const _identity = SchoolIdentity(
  id: 'ecole-1',
  name: 'Complexe Scolaire Eteelo',
  country: 'RD Congo',
  city: 'Kinshasa',
  district: 'Lukunga',
  municipality: 'Gombe',
  address: '12, avenue de la Recette',
  phone: '+243810000001',
  email: 'direction@eteelo.cd',
);

final _enService = AcademicYearContext(
  academicYear: AcademicYear(
    id: 'ay-2026',
    name: '2026-2027',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2027, 7, 1),
    current: true,
  ),
  schoolLevelGroups: const [
    SchoolLevelGroupBundle(
      group: SchoolLevelGroup(id: 'g-1', name: 'Primaire', code: 'PRIM'),
      levels: [
        SchoolLevel(
          id: 'n-1',
          name: '1re année',
          code: 'P1',
          displayOrder: 1,
          splitIntoClassrooms: false,
        ),
      ],
    ),
  ],
);

/// Le premier test à monter réellement l'écran des réglages.
///
/// Ce qu'il tient : la page a une **hauteur bornée**. Sa colonne porte un
/// `Expanded` — bandeau et onglets restent en place, seul le contenu de
/// l'onglet défile — et `AppPageBackground` fait défiler son enfant par défaut,
/// ce qui donnait à cette colonne une hauteur infinie. La mise en page échouait
/// alors AVANT la peinture, et l'écran ne s'affichait pas du tout.
///
/// D'où la vérification à trois tailles, dont celle d'où le défaut a été
/// rapporté : la contrainte est verticale, mais un écran étroit est celui où la
/// hauteur manque en premier.
void main() {
  late _MockRepository repository;
  late _MockAcademicYearContextBloc yearBloc;

  setUpAll(() => registerFallbackValue(_identity));

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.loadSchoolIdentity(),
    ).thenAnswer((_) async => const Right(_identity));
    when(
      () => repository.saveSchoolIdentity(any()),
    ).thenAnswer((_) async => const Right(_identity));
    when(
      () => repository.loadFeeCodes(),
    ).thenAnswer((_) async => const Right(<FeeCodeOption>[]));
    when(() => repository.loadTariffs(any())).thenAnswer(
      (_) async => const Left(ServerFailure('non sollicité par ce test')),
    );

    getIt.registerFactory<ProvisioningRepository>(() => repository);
    getIt.registerFactory<SchoolIdentityFormCubit>(
      () => SchoolIdentityFormCubit(repository: repository),
    );

    yearBloc = _MockAcademicYearContextBloc();
  });

  tearDown(() async => getIt.reset());

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Size surface,
    AcademicYearContext? academicContext,
  }) async {
    final state = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: academicContext,
    );
    when(() => yearBloc.state).thenReturn(state);
    whenListen(
      yearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: state,
    );

    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AcademicYearContextBloc>.value(
          value: yearBloc,
          child: const ConfigurationSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final surface in const [
    // La taille exacte du rapport de défaut, au dp près.
    Size(601, 821),
    Size(411, 731),
    Size(1280, 800),
  ]) {
    testWidgets('$surface : l\'écran se met en page et se peint', (
      tester,
    ) async {
      await pumpSettings(tester, surface: surface, academicContext: _enService);

      // Une hauteur infinie faisait échouer `performLayout` : la taille restait
      // absente, puis la peinture levait « RenderBox was not laid out ».
      expect(tester.takeException(), isNull);

      // Et l'écran est bien celui attendu, pas une coquille vide qui aurait
      // rendu l'assertion ci-dessus gratuite.
      expect(find.textContaining('Complexe Scolaire Eteelo'), findsWidgets);
    });
  }

  testWidgets('les onglets se parcourent sans casser la mise en page', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      surface: const Size(601, 821),
      academicContext: _enService,
    );

    final l10n = AppLocalizationsFr();
    for (final onglet in <String>[
      '${l10n.configurationSettingsTabStructure} · '
          '${l10n.configurationSettingsReadOnly}',
      l10n.configurationSettingsTabFees,
    ]) {
      await tester.tap(find.text(onglet));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet $onglet');
      expect(find.text('Primaire'), findsWidgets);
    }
  });

  testWidgets('sans année académique : l\'état vide se peint aussi', (
    tester,
  ) async {
    await pumpSettings(tester, surface: const Size(601, 821));

    expect(tester.takeException(), isNull);
  });
}
