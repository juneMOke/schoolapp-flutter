import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/device/pointer_kind_scope.dart';

Widget _probe() => Builder(
  builder: (context) => Text(
    PointerKindScope.usesMouseOf(context) ? 'souris' : 'doigt',
    textDirection: TextDirection.ltr,
  ),
);

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: SizedBox.expand(child: child),
);

void main() {
  testWidgets('sans geste, la plateforme répond (Android en test : doigt)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(PointerKindScope(child: _probe())));
    expect(find.text('doigt'), findsOneWidget);
  });

  testWidgets('une souris survole : souris ; un doigt touche : doigt', (
    tester,
  ) async {
    await tester.pumpWidget(_host(PointerKindScope(child: _probe())));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    await mouse.moveTo(const Offset(20, 20));
    await tester.pump();
    expect(find.text('souris'), findsOneWidget);

    await tester.tapAt(const Offset(30, 30));
    await tester.pump();
    expect(find.text('doigt'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('un clic de souris compte aussi', (tester) async {
    await tester.pumpWidget(_host(PointerKindScope(child: _probe())));
    await tester.tapAt(
      const Offset(30, 30),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await tester.pump();
    expect(find.text('souris'), findsOneWidget);
  });

  testWidgets('hors de la portée : la plateforme seule', (tester) async {
    await tester.pumpWidget(_host(_probe()));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    await mouse.moveTo(const Offset(20, 20));
    await tester.pump();
    expect(find.text('doigt'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('sans geste, sur un poste (Windows) : souris', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(_host(PointerKindScope(child: _probe())));
    expect(find.text('souris'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('un geste de trackpad ne change pas la main', (tester) async {
    await tester.pumpWidget(_host(PointerKindScope(child: _probe())));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    await mouse.moveTo(const Offset(20, 20));
    await tester.pump();
    final pad = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    await pad.panZoomStart(const Offset(30, 30));
    await pad.panZoomUpdate(const Offset(30, 30), pan: const Offset(0, 20));
    await pad.panZoomEnd();
    await tester.pump();
    expect(find.text('souris'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('usesMouseNow voit la main du geste en cours, avant tout frame', (
    tester,
  ) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        PointerKindScope(
          child: Builder(
            builder: (context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => seen = PointerKindScope.usesMouseNow(context),
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(30, 30), kind: PointerDeviceKind.mouse);
    expect(seen, isTrue);
  });
}
