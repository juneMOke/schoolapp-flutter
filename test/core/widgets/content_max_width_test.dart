import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/content_max_width.dart';

const _content = Key('content');

void main() {
  testWidgets('écran large : contenu plafonné et centré', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ContentMaxWidth(
        child: SizedBox(key: _content, width: double.infinity, height: 10),
      ),
    );
    final rect = tester.getRect(find.byKey(_content));
    expect(rect.width, AppDimensions.detailContentMaxWidth);
    expect(rect.center.dx, 960);
  });
}
