import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

void main() {
  group('SyncState', () {
    test('round-trip fromDbValue/toDbValue pour chaque valeur', () {
      for (final state in SyncState.values) {
        expect(SyncState.fromDbValue(state.toDbValue()), state);
      }
    });

    test('fromDbValue tolère la casse et retombe sur pendingSync', () {
      expect(SyncState.fromDbValue('synced'), SyncState.synced);
      expect(SyncState.fromDbValue(null), SyncState.pendingSync);
      expect(SyncState.fromDbValue('???'), SyncState.pendingSync);
    });

    test('accesseurs dérivés', () {
      expect(SyncState.pendingSync.isPending, isTrue);
      expect(SyncState.synced.isSynced, isTrue);
      expect(SyncState.syncError.isError, isTrue);
    });
  });

  group('OutboxStatus', () {
    test('round-trip', () {
      for (final s in OutboxStatus.values) {
        expect(OutboxStatus.fromDbValue(s.toDbValue()), s);
      }
    });

    test('fallback pending', () {
      expect(OutboxStatus.fromDbValue(null), OutboxStatus.pending);
    });
  });

  group('OutboxOperation', () {
    test('round-trip', () {
      for (final o in OutboxOperation.values) {
        expect(OutboxOperation.fromDbValue(o.toDbValue()), o);
      }
    });

    test('fallback create', () {
      expect(OutboxOperation.fromDbValue('nope'), OutboxOperation.create);
    });
  });
}
