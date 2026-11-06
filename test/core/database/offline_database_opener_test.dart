import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockExecutor extends Mock implements DatabaseExecutor {}

/// La garde de l'ouvreur SQLCipher. Le vrai SQLCipher passe par un canal de
/// plateforme et ne s'ouvre pas en test : sa réponse est simulée, et le refus
/// est prouvé sur un VRAI moteur qui n'est pas SQLCipher (ffi).
void main() {
  group('ensureSqlCipherBuild', () {
    test('laisse passer quand SQLCipher annonce sa version', () async {
      final db = _MockExecutor();
      when(() => db.rawQuery('PRAGMA cipher_version')).thenAnswer(
        (_) async => [
          {'cipher_version': '4.6.1 community'},
        ],
      );

      await expectLater(ensureSqlCipherBuild(db), completes);
    });

    test('refuse un moteur qui ne connaît pas cipher_version', () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);

      await expectLater(ensureSqlCipherBuild(db), throwsStateError);
    });

    test('refuse une version vide', () async {
      final db = _MockExecutor();
      when(() => db.rawQuery('PRAGMA cipher_version')).thenAnswer(
        (_) async => [
          {'cipher_version': ''},
        ],
      );

      await expectLater(ensureSqlCipherBuild(db), throwsStateError);
    });
  });
}
