import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_action_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Notifier les parents » dans la barre d'actions (spec §4.6 D) : entre la
/// liste d'appel et le marquage, inactif hors ligne.
void main() {
  late FeeControlSelectionCubit cubit;

  setUp(() => cubit = FeeControlSelectionCubit()..toggle('s1'));
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, {VoidCallback? onNotify}) async {
    tester.view.physicalSize = const Size(1180, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<FeeControlSelectionCubit>.value(
          value: cubit,
          child: Scaffold(
            body: FeeControlActionBar(
              onCallList: () {},
              onNotify: onNotify,
              onMark: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('placé entre « Liste d\'appel » et « Marquer à renvoyer »', (
    tester,
  ) async {
    var notified = 0;
    await pump(tester, onNotify: () => notified++);

    final callList = tester.getTopLeft(find.text('Liste d\'appel')).dx;
    final notify = tester.getTopLeft(find.text('Notifier les parents')).dx;
    final mark = tester.getTopLeft(find.text('Marquer à renvoyer')).dx;
    expect(callList < notify && notify < mark, isTrue);

    await tester.tap(find.text('Notifier les parents'));
    expect(notified, 1);
  });

  testWidgets('hors ligne (onNotify nul) : visible mais inactif', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Notifier les parents'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Notifier les parents'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
