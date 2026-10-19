import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/selection/selectable_list_card.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_teacher.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_teachers_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_direction_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/direction/journal_teacher_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _Teachers extends MockCubit<JournalTeachersState>
    implements JournalTeachersCubit {}

/// La direction lit les journaux : sur grand écran, les professeurs en
/// colonne ; plus étroit, la liste déroulante au-dessus du journal.
void main() {
  late _Teachers teachers;

  setUp(() {
    teachers = _Teachers();
    whenListen(
      teachers,
      const Stream<JournalTeachersState>.empty(),
      initialState: const JournalTeachersState(
        loading: false,
        teachers: [
          JournalTeacher(id: 't1', displayName: 'MBUYI Grâce'),
          JournalTeacher(id: 't2', displayName: 'KALALA Jean'),
        ],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<JournalTeachersCubit>.value(
        value: teachers,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: JournalDirectionPage()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('grand écran : les professeurs en colonne, un clic choisit', (
    tester,
  ) async {
    await pump(tester, const Size(1600, 1000));
    expect(find.byType(SelectableListCard), findsOneWidget);
    expect(find.byType(JournalTeacherPicker), findsNothing);

    await tester.tap(find.text('KALALA Jean'));
    verify(() => teachers.select('t2')).called(1);
  });

  testWidgets('écran moyen : la liste déroulante', (tester) async {
    await pump(tester, const Size(1100, 900));
    expect(find.byType(JournalTeacherPicker), findsOneWidget);
    expect(find.byType(SelectableListCard), findsNothing);
  });
}
