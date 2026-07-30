import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockAcademicYearContextBloc extends Mock
    implements AcademicYearContextBloc {}

class _MockClassroomBloc extends Mock implements ClassroomBloc {}

class _MockClassroomStatsBloc extends Mock implements ClassroomStatsBloc {}

class _MockClassroomOfflineBloc extends Mock implements ClassroomOfflineBloc {}

/// Régression du MÊME bug que `enrollment_feature_scope_key_test.dart`,
/// trouvé par la revue adversariale sur exactement le même schéma dans
/// `home_page.dart` : `ClassesFeatureScope` enveloppait 4 pages différentes
/// (Dashboard classes, Organisation, Liste classes, Liste disciplines) SANS
/// `Key`, au même emplacement d'un `switch` — Flutter réutilisait donc le
/// même `State` (et les mêmes blocs, résolus une seule fois dans `initState`)
/// en basculant entre elles, faisant persister le roster/les résultats de
/// recherche d'une page sur les autres.
void main() {
  int resolutionCount = 0;
  late List<_MockClassroomBloc> resolvedClassroomBlocs;

  setUp(() {
    resolutionCount = 0;
    resolvedClassroomBlocs = [];

    GetIt.instance.registerFactory<EnrollmentBloc>(() {
      final mock = _MockEnrollmentBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    GetIt.instance.registerFactory<AcademicYearContextBloc>(() {
      final mock = _MockAcademicYearContextBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    GetIt.instance.registerFactory<ClassroomStatsBloc>(() {
      final mock = _MockClassroomStatsBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    GetIt.instance.registerFactory<ClassroomOfflineBloc>(() {
      final mock = _MockClassroomOfflineBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    GetIt.instance.registerFactory<ClassroomBloc>(() {
      resolutionCount++;
      final mock = _MockClassroomBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      resolvedClassroomBlocs.add(mock);
      return mock;
    });
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget scopeFor(String menuId, {required bool withKey}) {
    return ClassesFeatureScope(
      key: withKey ? ValueKey(menuId) : null,
      child: Text(menuId),
    );
  }

  testWidgets('AVEC Key distincte par page : chaque bascule résout un NOUVEAU '
      'ClassroomBloc (le correctif)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: scopeFor('classes-dashboard', withKey: true)),
    );
    expect(resolutionCount, 1);

    await tester.pumpWidget(
      MaterialApp(home: scopeFor('organisation', withKey: true)),
    );
    expect(resolutionCount, 2);
    verify(() => resolvedClassroomBlocs[0].close()).called(1);

    await tester.pumpWidget(
      MaterialApp(home: scopeFor('classes-list', withKey: true)),
    );
    expect(resolutionCount, 3);
    verify(() => resolvedClassroomBlocs[1].close()).called(1);

    await tester.pumpWidget(
      MaterialApp(home: scopeFor('disciplines-list', withKey: true)),
    );
    expect(resolutionCount, 4);
    verify(() => resolvedClassroomBlocs[2].close()).called(1);

    expect(resolvedClassroomBlocs.toSet(), hasLength(4));
  });

  testWidgets(
    'SANS Key (comportement bogué reproduit) : basculer entre 2 pages ne '
    'résout PAS de nouveau bloc — le roster/l\'état de recherche périmé '
    'persisterait entre Classes et Disciplines',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: scopeFor('classes-list', withKey: false)),
      );
      expect(resolutionCount, 1);

      await tester.pumpWidget(
        MaterialApp(home: scopeFor('disciplines-list', withKey: false)),
      );
      expect(
        resolutionCount,
        1,
        reason:
            'sans Key, ClassesFeatureScope garde le même Element (même type, '
            'même emplacement) : le State — et les blocs résolus dans son '
            'initState — ne sont jamais recréés.',
      );
    },
  );
}
