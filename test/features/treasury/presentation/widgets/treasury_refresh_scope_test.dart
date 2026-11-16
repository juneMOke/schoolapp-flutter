import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';

/// Relire un écran de la trésorerie : la page tirée au doigt, F5 au clavier.
void main() {
  late int screen;
  late int shell;

  Future<void> pump(WidgetTester tester, {bool pull = true}) async {
    screen = 0;
    shell = 0;
    await tester.pumpWidget(
      MaterialApp(
        // Le geste de la coquille, au-dessus de la page.
        home: RefreshIndicator(
          onRefresh: () async => shell++,
          child: TreasuryRefreshScope(
            pull: pull,
            onRefresh: () async => screen++,
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: 400, child: Text('page')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tirer la page la relit, une seule fois', (tester) async {
    await pump(tester);
    await tester.fling(find.text('page'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(screen, 1);
    expect(shell, 0, reason: 'la coquille ne relance pas en double');
  });

  testWidgets('sans pull : le geste reste celui de la coquille', (
    tester,
  ) async {
    await pump(tester, pull: false);
    await tester.fling(find.text('page'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(screen, 0);
    expect(shell, 1);
  });

  testWidgets('F5 relit la page', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    expect(screen, 1);
  });
}
