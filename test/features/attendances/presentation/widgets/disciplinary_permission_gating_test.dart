import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_comments_dialog.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockCaseBloc
    extends MockBloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState>
    implements DisciplinaryCaseOfflineBloc {}

/// Revue adversariale — les gestes d'INSTRUCTION d'un cas (avancer, classer
/// sans suite, commenter) partent par le même agrégat que la création
/// (`POST /sync/disciplinary-cases`, gardé `discipline.write`), et un 403 y est
/// classé TERMINAL. Ils n'étaient gardés que contre le gel READ_ONLY : un
/// enseignant — `discipline.read` sans `discipline.write` dans le template
/// seedé — produisait une écriture définitivement perdue, tout en laissant la
/// base locale afficher un cas « classé » que le serveur tient pour ouvert.
void main() {
  const lecteur = <String>['discipline.read'];
  const instructeur = <String>['discipline.read', 'discipline.write'];

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

  AuthBloc authWith(List<String> permissions) {
    final bloc = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream<AuthState>.value(state), initialState: state);
    return bloc;
  }

  Widget host(Widget child, List<String> permissions) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthBloc>.value(
      value: authWith(permissions),
      child: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 560, child: child)),
      ),
    ),
  );

  group('carte : avancer / classer sans suite', () {
    testWidgets('discipline.read seul : aucune action offerte', (tester) async {
      await tester.pumpWidget(
        host(
          DisciplinaryCaseCard(
            caseData: caseData,
            onAdvance: () {},
            onDismiss: () {},
          ),
          lecteur,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byIcon(Icons.block_rounded), findsNothing);
      // La carte elle-même reste : la consultation relève de discipline.read.
      expect(find.byType(DisciplinaryCaseCard), findsOneWidget);
      expect(find.text('Bavardage en classe'), findsWidgets);
    });

    testWidgets('discipline.write : les actions reviennent', (tester) async {
      await tester.pumpWidget(
        host(
          DisciplinaryCaseCard(
            caseData: caseData,
            onAdvance: () {},
            onDismiss: () {},
          ),
          instructeur,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });
  });

  group('fil de commentaires', () {
    late _MockCaseBloc caseBloc;

    setUp(() {
      caseBloc = _MockCaseBloc();
      whenListen(
        caseBloc,
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

    Widget dialogHost(List<String> permissions) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authWith(permissions)),
          BlocProvider<DisciplinaryCaseOfflineBloc>.value(value: caseBloc),
        ],
        child: DisciplinaryCaseCommentsDialog(caseData: caseData),
      ),
    );

    testWidgets('discipline.read seul : le fil se lit, l\'ajout est masqué', (
      tester,
    ) async {
      await tester.pumpWidget(dialogHost(lecteur));
      await tester.pumpAndSettle();

      expect(find.text('Un commentaire existant'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('discipline.write : le champ d\'ajout est offert', (
      tester,
    ) async {
      await tester.pumpWidget(dialogHost(instructeur));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
