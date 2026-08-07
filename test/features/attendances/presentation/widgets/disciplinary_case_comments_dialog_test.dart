import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_comment.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_comments_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockDisciplinaryCaseOfflineBloc
    extends MockBloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState>
    implements DisciplinaryCaseOfflineBloc {}

void main() {
  late MockDisciplinaryCaseOfflineBloc bloc;

  final caseData = OfflineDisciplinaryCase(
    id: 'case-1',
    studentId: 's1',
    studentFirstName: 'Awa',
    studentLastName: 'Diop',
    studentGender: StudentGender.female,
    academicYearId: 'ay1',
    disciplinaryCaseDate: DateTime(2026, 7, 1),
    title: 'Bavardage en classe',
    content: 'Détail du cas',
    category: DisciplinaryCategory.talkingInClass,
    severity: DisciplinarySeverity.minor,
    status: DisciplinaryStatus.open,
    updatedAt: 0,
  );

  setUp(() {
    bloc = MockDisciplinaryCaseOfflineBloc();
    whenListen(
      bloc,
      const Stream<DisciplinaryCaseOfflineState>.empty(),
      initialState: const DisciplinaryOfflineCommentsLoaded('case-1', [
        DisciplinaryComment(
          id: 'c1',
          disciplinaryCaseId: 'case-1',
          content: 'Un commentaire existant',
          authorName: 'M. Traoré',
          createdAt: 0,
          syncState: SyncState.synced,
        ),
      ]),
    );
  });

  Widget harness() {
    return MaterialApp(
      // AppTheme.light câble le FilledButtonThemeData plein-largeur (CTA) —
      // le laisser par défaut (comme les autres harnesses de dialog) aurait
      // masqué la régression : le bouton "Envoyer", inline dans une Row, doit
      // overrider minimumSize sous peine de largeur infinie (crash layout).
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: BlocProvider<DisciplinaryCaseOfflineBloc>.value(
        value: bloc,
        child: DisciplinaryCaseCommentsDialog(caseData: caseData),
      ),
    );
  }

  testWidgets('rendu sans exception (bouton Envoyer inline dans le champ)', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DisciplinaryCaseCommentsDialog), findsOneWidget);
    expect(find.text('Un commentaire existant'), findsOneWidget);
  });
}
