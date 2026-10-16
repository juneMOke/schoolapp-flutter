import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell_tab_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockNavigationBloc extends Mock implements NavigationBloc {}

void main() {
  testWidgets('l’onglet porte l’écran ouvert puis le nom de l’application', (
    tester,
  ) async {
    final bloc = _MockNavigationBloc();
    const state = NavigationState(
      menuItems: [],
      selectedMenuId: 'finance',
      selectedSubMenuId: 'facturations',
      openedMenuId: 'finance',
      isSidebarExpanded: true,
      currentTitle: 'Facturation',
    );
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<NavigationBloc>.value(
          value: bloc,
          child: const ShellTabTitle(child: SizedBox()),
        ),
      ),
    );

    expect(
      tester.widget<Title>(find.byType(Title).last).title,
      'Facturation · ETEELO CONNECT',
    );
  });
}
