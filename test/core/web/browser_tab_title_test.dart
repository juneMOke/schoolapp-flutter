import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/web/browser_tab_title.dart';

void main() {
  testWidgets('une fiche par-dessus prend l\'onglet, puis le rend à l\'écran '
      'd\'en dessous', (tester) async {
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
    final showRecord = ValueNotifier(false);
    addTearDown(showRecord.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BrowserTabTitle(
          title: 'Facturation',
          fallback: 'Appli',
          child: ValueListenableBuilder<bool>(
            valueListenable: showRecord,
            builder: (_, show, _) => show
                ? const BrowserTabTitle(
                    title: 'Grâce Tshala',
                    fallback: 'Appli',
                    child: SizedBox(),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    );
    expect(labels.last, 'Facturation');
    showRecord.value = true;
    await tester.pump();
    expect(labels.last, 'Grâce Tshala');
    showRecord.value = false;
    await tester.pump();
    expect(labels.last, 'Facturation');
    await tester.pumpWidget(const SizedBox());
    expect(labels.last, 'Appli');
  });
}
