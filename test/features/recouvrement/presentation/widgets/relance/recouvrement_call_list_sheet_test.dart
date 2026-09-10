import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_call_list_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/recouvrement_call_list_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La modale doit **avoir une taille** — et la garder dans ses trois états.
///
/// ⚠️ Le harnais monte `AppTheme.light`, et ce n'est pas décoratif : le thème
/// donne aux `FilledButton` une largeur minimale **infinie** (pensée pour les
/// CTA pleine largeur). Un tel bouton posé en enfant non-flex d'une `Row` lève
/// « BoxConstraints forces an infinite width » ; l'erreur est avalée pendant le
/// layout, la modale sort **sans taille**, et c'est le clic suivant qui éclate
/// sur « Cannot hit test a render box with no size ». Sous le thème par défaut
/// des tests, rien de tout cela n'apparaît.
class _MockCallList extends MockCubit<RecouvrementCallListState>
    implements RecouvrementCallListCubit {}

class _MockRelance extends MockCubit<RelanceListState>
    implements RelanceListCubit {}

RecouvrementCallListRow _row(int index) => RecouvrementCallListRow(
  studentId: 'stu-$index',
  displayName: 'Nom$index Prénom$index',
  expected: MoneyBag.from(const Money(120000, 'CDF')),
  paid: MoneyBag.from(const Money(20000, 'CDF')),
  remaining: MoneyBag.from(const Money(100000, 'CDF')),
);

void main() {
  late _MockCallList callList;
  late _MockRelance relance;

  setUp(() {
    callList = _MockCallList();
    relance = _MockRelance();
    when(() => relance.state).thenReturn(const RelanceListState());
  });

  /// Une tablette en **paysage** : c'est là que la hauteur manque, et le
  /// portrait masquerait le débordement du squelette.
  Future<void> pumpSheet(
    WidgetTester tester,
    RecouvrementCallListState state,
  ) async {
    when(() => callList.state).thenReturn(state);
    tester.view.physicalSize = const Size(960, 528);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<RecouvrementCallListCubit>.value(value: callList),
            BlocProvider<RelanceListCubit>.value(value: relance),
          ],
          child: RecouvrementCallListSheet(
            groupLabel: '1ère année',
            criterionLabel: 'Reste à payer',
            onEmit: () {},
          ),
        ),
      ),
    );
    // Pas de `pumpAndSettle` : le squelette scintille sans fin.
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Une modale sans taille lève ici même — `size` est inaccessible.
  void expectLaidOut(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Dialog)).isEmpty, isFalse);
  }

  testWidgets('en chargement : le squelette défile, il ne déborde pas', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      const RecouvrementCallListState(status: EnrollmentLoadStatus.loading),
    );

    expectLaidOut(tester);
  });

  testWidgets('liste vide : la modale tient debout', (tester) async {
    await pumpSheet(
      tester,
      const RecouvrementCallListState(status: EnrollmentLoadStatus.success),
    );

    expectLaidOut(tester);
  });

  testWidgets('liste pleine : la modale tient debout et nomme ses élèves', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      RecouvrementCallListState(
        status: EnrollmentLoadStatus.success,
        rows: [for (var i = 0; i < 40; i++) _row(i)],
      ),
    );

    expectLaidOut(tester);
    expect(find.text('Nom0 Prénom0'), findsOneWidget);
  });
}
