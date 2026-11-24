import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';

void main() {
  test('lit X.Y.Z strict et refuse le reste', () {
    expect(AppVersion.tryParseStrict('1.9.0'), const AppVersion(1, 9, 0));
    for (final bad in ['1.9', '1.9.0-rc1', '1.9.0+3', '01.9.0', 'v1.9.0', '']) {
      expect(AppVersion.tryParseStrict(bad), isNull, reason: bad);
    }
  });

  test('tryParse ignore le numéro de build', () {
    expect(AppVersion.tryParse('1.8.0+42'), const AppVersion(1, 8, 0));
  });

  test('compare numériquement, pas comme du texte', () {
    expect(const AppVersion(1, 10, 0) > const AppVersion(1, 9, 9), isTrue);
    expect(const AppVersion(2, 0, 0) < const AppVersion(10, 0, 0), isTrue);
    expect(const AppVersion(1, 9, 0).compareTo(const AppVersion(1, 9, 0)), 0);
  });
}
