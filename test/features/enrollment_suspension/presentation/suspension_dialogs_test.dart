import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/reactivate_dialog.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspend_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockCubit extends MockCubit<SuspensionGestureState>
    implements SuspensionGestureCubit {}

SuspensionCandidate _candidate(String id, String first) => SuspensionCandidate(
  target: SuspensionTarget(
    enrollmentId: 'enr-$id',
    studentId: id,
    academicYearId: 'y',
  ),
  lastName: 'Kabongo',
  middleName: 'Mwamba',
  firstName: first,
  classLabel: '6e A',
);

void main() {
  late _MockCubit cubit;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.state).thenReturn(const SuspensionGestureIdle());
    when(
      () => cubit.suspend(
        any(),
        reason: any(named: 'reason'),
        precision: any(named: 'precision'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<SuspensionGestureCubit>.value(
            value: cubit,
            child: dialog,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('désactiver un élève : titre, cible, date d\'effet', (
    tester,
  ) async {
    await pump(
      tester,
      SuspendDialog(
        candidates: [_candidate('s1', 'Daniel')],
        today: DateTime(2026, 10, 8),
      ),
    );

    expect(find.text("Désactiver l'élève"), findsOneWidget);
    expect(find.textContaining('Kabongo Mwamba'), findsOneWidget);
    expect(find.text('Classe 6e A'), findsOneWidget);
    expect(find.textContaining('8 octobre 2026'), findsOneWidget);
  });

  testWidgets('désactiver trois élèves : pile et prénoms', (tester) async {
    await pump(
      tester,
      SuspendDialog(
        candidates: [
          _candidate('s1', 'Daniel'),
          _candidate('s2', 'Ruth'),
          _candidate('s3', 'Élie'),
        ],
        today: DateTime(2026, 10, 8),
      ),
    );

    expect(find.text('Désactiver 3 élèves'), findsNWidgets(2));
    expect(find.text('3 élèves · Daniel, Ruth, Élie'), findsOneWidget);

    await tester.tap(find.text('Désactiver 3 élèves').last);
    verify(
      () => cubit.suspend(
        any(that: hasLength(3)),
        reason: any(named: 'reason'),
        precision: any(named: 'precision'),
      ),
    ).called(1);
  });

  testWidgets('un échec garde la modale ouverte et le dit', (tester) async {
    when(
      () => cubit.state,
    ).thenReturn(const SuspensionGestureFailed(StorageFailure('disque')));
    await pump(
      tester,
      SuspendDialog(
        candidates: [_candidate('s1', 'Daniel')],
        today: DateTime(2026, 10, 8),
      ),
    );

    expect(find.textContaining('Rien n\'a été modifié'), findsOneWidget);
  });

  testWidgets('réactiver un élève rappelle depuis quand et pourquoi', (
    tester,
  ) async {
    await pump(
      tester,
      ReactivateDialog(
        candidates: [_candidate('s1', 'Espérance')],
        suspension: StudentSuspension(
          id: 'p',
          enrollmentId: 'enr-s1',
          studentId: 's1',
          academicYearId: 'y',
          suspendedAt: DateTime(2026, 10, 2),
          reason: SuspensionReason.medical,
          precision: 'Hospitalisation',
        ),
      ),
    );

    expect(find.text("Réactiver l'élève"), findsOneWidget);
    expect(find.textContaining('2 octobre 2026'), findsOneWidget);
    expect(
      find.textContaining('Raison médicale · Hospitalisation'),
      findsOneWidget,
    );
  });
}
