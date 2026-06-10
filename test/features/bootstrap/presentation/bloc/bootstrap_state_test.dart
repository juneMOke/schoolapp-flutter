import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';

class _FakeBootstrap extends Fake implements Bootstrap {}

void main() {
  final cache = _FakeBootstrap();

  BootstrapState stateWith({
    required BootstrapLoadStatus status,
    required BootstrapOperation operation,
    Bootstrap? bootstrap,
    BootstrapSource? source,
  }) {
    return BootstrapState(
      status: status,
      bootstrap: bootstrap,
      source: source,
      errorMessage: status == BootstrapLoadStatus.failure ? 'boom' : null,
      operation: operation,
    );
  }

  group('hasBlockingFailure (échec sans données)', () {
    test('pas de cache + échec remote courant → true', () {
      final s = stateWith(
        status: BootstrapLoadStatus.failure,
        operation: BootstrapOperation.remoteCurrentYear,
      );
      expect(s.hasBlockingFailure, isTrue);
    });

    test('cache présent + échec remote → false (on a des données)', () {
      final s = stateWith(
        status: BootstrapLoadStatus.failure,
        operation: BootstrapOperation.remoteCurrentYear,
        bootstrap: cache,
        source: BootstrapSource.local,
      );
      expect(s.hasBlockingFailure, isFalse);
    });

    test('pas de cache + échec local → false (on attend le remote)', () {
      final s = stateWith(
        status: BootstrapLoadStatus.failure,
        operation: BootstrapOperation.local,
      );
      expect(s.hasBlockingFailure, isFalse);
    });
  });

  group('blocksNavigation (offline-first)', () {
    test('initial sans données → bloque', () {
      const s = BootstrapState.initial();
      expect(s.blocksNavigation, isTrue);
    });

    test('cache présent → ne bloque jamais (on entre, refresh en fond)', () {
      final loadingRefresh = stateWith(
        status: BootstrapLoadStatus.loading,
        operation: BootstrapOperation.remoteCurrentYear,
        bootstrap: cache,
        source: BootstrapSource.local,
      );
      expect(loadingRefresh.blocksNavigation, isFalse);
    });

    test('pas de cache + échec local → bloque encore (attend le remote)', () {
      final s = stateWith(
        status: BootstrapLoadStatus.failure,
        operation: BootstrapOperation.local,
      );
      expect(s.blocksNavigation, isTrue);
    });

    test(
      'pas de cache + échec remote → ne bloque pas (c\'est l\'ErrorView)',
      () {
        final s = stateWith(
          status: BootstrapLoadStatus.failure,
          operation: BootstrapOperation.remoteCurrentYear,
        );
        expect(s.blocksNavigation, isFalse);
        expect(s.hasBlockingFailure, isTrue);
      },
    );
  });

  group('isStale (mode hors-ligne)', () {
    test('cache local + échec refresh → stale', () {
      final s = stateWith(
        status: BootstrapLoadStatus.failure,
        operation: BootstrapOperation.remoteCurrentYear,
        bootstrap: cache,
        source: BootstrapSource.local,
      );
      expect(s.isStale, isTrue);
    });

    test('données fraîches (remote) + échec → pas stale', () {
      final s = stateWith(
        status: BootstrapLoadStatus.failure,
        operation: BootstrapOperation.remotePreviousYear,
        bootstrap: cache,
        source: BootstrapSource.remote,
      );
      expect(s.isStale, isFalse);
    });

    test(
      'cache local chargé avec succès (pas encore d\'échec) → pas stale',
      () {
        final s = stateWith(
          status: BootstrapLoadStatus.success,
          operation: BootstrapOperation.local,
          bootstrap: cache,
          source: BootstrapSource.local,
        );
        expect(s.isStale, isFalse);
      },
    );
  });
}
