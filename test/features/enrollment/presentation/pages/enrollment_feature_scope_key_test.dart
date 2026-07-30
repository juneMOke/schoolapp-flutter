import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockEnrollmentOfflineBloc extends Mock
    implements EnrollmentOfflineBloc {}

class _MockEnrollmentLocalListBloc extends Mock
    implements EnrollmentLocalListBloc {}

class _MockAcademicYearContextBloc extends Mock
    implements AcademicYearContextBloc {}

class _MockAcademicYearPreviousContextBloc extends Mock
    implements AcademicYearPreviousContextBloc {}

/// Régression du bug : « de retour de Première inscription, cliquer sur
/// Réinscription/Préinscription affiche les résultats périmés de Première
/// inscription ». Cause : dans `HomePage._getContentForRoute`, les 3 pages
/// étaient enveloppées par un `EnrollmentFeatureScope(child: ...)` SANS
/// `Key`, au même emplacement d'un `switch` — Flutter réutilisait donc le
/// même `State` (et le même `EnrollmentLocalListBloc`, résolu une seule fois
/// dans `initState`) en basculant entre les 3 pages, au lieu d'en recréer un
/// pour chacune. Ce test isole le mécanisme (au niveau de
/// `EnrollmentFeatureScope` lui-même, sans monter toute `HomePage`) : une
/// `Key` distincte par "page" doit forcer un nouveau `State` à chaque
/// bascule, donc une nouvelle résolution GetIt (`registerFactory`) de
/// `EnrollmentLocalListBloc`.
void main() {
  int resolutionCount = 0;
  late List<_MockEnrollmentLocalListBloc> resolvedLocalListBlocs;

  setUp(() {
    resolutionCount = 0;
    resolvedLocalListBlocs = [];

    void registerCloseable<T extends Object>(T Function() factory) {
      GetIt.instance.registerFactory<T>(factory);
    }

    registerCloseable<EnrollmentBloc>(() {
      final mock = _MockEnrollmentBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    registerCloseable<EnrollmentOfflineBloc>(() {
      final mock = _MockEnrollmentOfflineBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    registerCloseable<AcademicYearContextBloc>(() {
      final mock = _MockAcademicYearContextBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    registerCloseable<AcademicYearPreviousContextBloc>(() {
      final mock = _MockAcademicYearPreviousContextBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      return mock;
    });
    GetIt.instance.registerFactory<EnrollmentLocalListBloc>(() {
      resolutionCount++;
      final mock = _MockEnrollmentLocalListBloc();
      when(() => mock.close()).thenAnswer((_) async {});
      resolvedLocalListBlocs.add(mock);
      return mock;
    });
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget scopeFor(String menuId, {required bool withKey}) {
    return EnrollmentFeatureScope(
      key: withKey ? ValueKey(menuId) : null,
      child: Text(menuId),
    );
  }

  testWidgets('AVEC Key distincte par page : chaque bascule résout un NOUVEAU '
      'EnrollmentLocalListBloc (le correctif)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: scopeFor('pre-inscriptions', withKey: true)),
    );
    expect(resolutionCount, 1);
    expect(find.text('pre-inscriptions'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: scopeFor('re-inscriptions', withKey: true)),
    );
    expect(
      resolutionCount,
      2,
      reason:
          'la Key différente doit forcer un nouveau State '
          '(donc une nouvelle résolution GetIt)',
    );
    expect(find.text('re-inscriptions'), findsOneWidget);
    // L'ANCIEN scope (Pré-inscriptions) a bien été démonté : ses 5 blocs,
    // dont EnrollmentLocalListBloc, sont fermés — sinon chaque bascule de
    // sous-menu fuirait des abonnements DB/stream non libérés.
    verify(() => resolvedLocalListBlocs[0].close()).called(1);

    await tester.pumpWidget(
      MaterialApp(home: scopeFor('premiere-inscription', withKey: true)),
    );
    expect(resolutionCount, 3);
    expect(find.text('premiere-inscription'), findsOneWidget);
    verify(() => resolvedLocalListBlocs[1].close()).called(1);

    // Les 3 instances de bloc résolues sont bien distinctes.
    expect(resolvedLocalListBlocs.toSet(), hasLength(3));
  });

  testWidgets(
    'SANS Key (comportement bogué reproduit) : basculer entre 2 pages ne '
    'résout PAS de nouveau bloc — le même State/bloc est réutilisé',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: scopeFor('pre-inscriptions', withKey: false)),
      );
      expect(resolutionCount, 1);

      await tester.pumpWidget(
        MaterialApp(home: scopeFor('re-inscriptions', withKey: false)),
      );
      expect(
        resolutionCount,
        1,
        reason:
            'sans Key, EnrollmentFeatureScope garde le même Element (même '
            'type, même emplacement) : le State — et le bloc résolu dans son '
            'initState — n\'est jamais recréé. C\'est exactement le bug '
            'reproduit ici : Réinscription hériterait des résultats de '
            'Première inscription.',
      );
    },
  );
}
