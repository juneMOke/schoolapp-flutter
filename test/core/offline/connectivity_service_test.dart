import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = MockConnectivity();
    service = ConnectivityService(connectivity);
  });

  group('isOnline — invariants connectivity_plus (état radio)', () {
    test('une interface active (wifi) → true', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      expect(await service.isOnline(), isTrue);
    });

    test('plusieurs interfaces (mobile + wifi) → true', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.mobile, ConnectivityResult.wifi],
      );
      expect(await service.isOnline(), isTrue);
    });

    test('[none] (seul marqueur d\'absence, jamais mélangé) → false', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      expect(await service.isOnline(), isFalse);
    });
  });

  group('onStatusChange — flux réactif (recommandé par la doc)', () {
    test('mappe chaque transition radio en bool', () async {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
        ]),
      );
      expect(service.onStatusChange, emitsInOrder([true, false, true]));
    });
  });
}
