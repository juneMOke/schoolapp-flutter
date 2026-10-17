import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/sidebar_toggle_shortcut.dart';

class _MockNavigationBloc extends Mock implements NavigationBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const SidebarToggled()));

  testWidgets('Ctrl+B replie ou déplie le menu latéral', (tester) async {
    final bloc = _MockNavigationBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NavigationBloc>.value(
          value: bloc,
          child: const SidebarToggleShortcut(child: SizedBox()),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    verify(() => bloc.add(any(that: isA<SidebarToggled>()))).called(1);
  });
}
