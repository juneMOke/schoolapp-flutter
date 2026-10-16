import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_scroll_behavior.dart';

void main() {
  test('la souris sélectionne, elle ne fait pas glisser le contenu', () {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, isNot(contains(PointerDeviceKind.mouse)));
    expect(
      behavior.dragDevices,
      containsAll([
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      ]),
    );
  });
}
