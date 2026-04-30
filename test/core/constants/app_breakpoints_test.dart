import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

void main() {
  group('AppBreakpoints', () {
    test('uses expected global responsive values', () {
      expect(AppBreakpoints.detailCompactMax, 760.0);
      expect(AppBreakpoints.homeMobileMax, 768.0);
      expect(AppBreakpoints.authWideMin, 800.0);
      expect(AppBreakpoints.formMediumMin, 860.0);
      expect(AppBreakpoints.formWideMin, 1280.0);
    });

    test('keeps monotonic order for responsive tiers', () {
      expect(
        AppBreakpoints.detailCompactMax < AppBreakpoints.homeMobileMax,
        isTrue,
      );
      expect(
        AppBreakpoints.homeMobileMax < AppBreakpoints.authWideMin,
        isTrue,
      );
      expect(
        AppBreakpoints.authWideMin < AppBreakpoints.formMediumMin,
        isTrue,
      );
      expect(
        AppBreakpoints.formMediumMin < AppBreakpoints.formWideMin,
        isTrue,
      );
    });
  });
}
