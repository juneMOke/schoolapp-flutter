import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell_tab_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockNavigationBloc extends Mock implements NavigationBloc {}

const _state = NavigationState(
  menuItems: [],
  selectedMenuId: 'finance',
  selectedSubMenuId: 'facturations',
  openedMenuId: 'finance',
  isSidebarExpanded: true,
  currentTitle: 'Facturation',
);

void main() {
  testWidgets('l’onglet porte l’écran ouvert puis le nom de l’application', (
    tester,
  ) async {
    final bloc = _MockNavigationBloc();
    when(() => bloc.state).thenReturn(_state);
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

  testWidgets('quitter la coquille rend le nom de l’application à l’onglet', (
    tester,
  ) async {
    final labels = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
          labels.add((call.arguments as Map)['label'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final bloc = _MockNavigationBloc();
    when(() => bloc.state).thenReturn(_state);
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    Widget app(Widget home) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
    await tester.pumpWidget(
      app(
        BlocProvider<NavigationBloc>.value(
          value: bloc,
          child: const ShellTabTitle(child: SizedBox()),
        ),
      ),
    );
    await tester.pumpWidget(app(const SizedBox()));

    expect(labels.last, 'ETEELO CONNECT');
  });
}
