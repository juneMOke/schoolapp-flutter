import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/selection/selectable_list_card.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_picker.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/student_month_tab.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _Cubit extends MockCubit<ClassPresenceState>
    implements ClassPresenceCubit {}

/// La fiche mensuelle : sur grand écran, les élèves en colonne à côté du
/// mois ; plus étroit, la liste déroulante au-dessus.
void main() {
  const state = ClassPresenceState(
    load: ClassPresenceLoad.ready,
    today: '2026-10-19',
    day: '2026-10-19',
    month: '2026-10',
    tab: ClassPresenceTab.studentMonth,
  );

  Future<void> pump(WidgetTester tester, double width) async {
    final cubit = _Cubit();
    whenListen(
      cubit,
      const Stream<ClassPresenceState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ClassPresenceCubit>.value(
            value: cubit,
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: const StudentMonthTab(state: state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('large : la colonne des élèves remplace la liste déroulante', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, 1300);
    expect(find.byType(SelectableListCard), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is PresencePersonPicker),
      findsNothing,
    );
  });

  testWidgets('étroit : la liste déroulante', (tester) async {
    await pump(tester, 760);
    expect(find.byType(SelectableListCard), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is PresencePersonPicker),
      findsOneWidget,
    );
  });
}
