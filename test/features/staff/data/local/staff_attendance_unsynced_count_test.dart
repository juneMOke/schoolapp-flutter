import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

/// Ce que le tableau de bord annonce « encore sur la tablette » : les
/// pointages de la fenêtre que le serveur n'a pas reçus (D1).
void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() async => db.close());

  Future<void> write(String id, String day, {String school = 's-1'}) =>
      StaffAttendanceWriteDao(db).save(
        [
          StaffAttendanceSyncRequestDto(
            staffAttendance: StaffAttendanceDto(
              id: id,
              staffMemberId: 'm-$id',
              workDate: day,
              status: 'PRESENT',
              arrivalTime: '07:30',
              clientUpdatedAt: '${day}T08:00:00.000Z',
            ),
            authorId: 'u-1',
          ),
        ],
        schoolId: school,
        nowMs: 10,
      );

  test('compte les pointages en file de la fenêtre, de cette école', () async {
    await write('a', '2026-10-05');
    await write('b', '2026-10-23');
    await write('c', '2026-09-30');
    await write('d', '2026-10-06', school: 's-2');
    final dao = StaffAttendanceDao(db);

    expect(
      await dao.unsyncedCount('s-1', from: '2026-10-01', to: '2026-10-23'),
      2,
    );
    expect(
      await dao.unsyncedCount('', from: '2026-10-01', to: '2026-10-23'),
      0,
    );
  });

  test('un pointage reçu par le serveur ne compte plus', () async {
    await write('a', '2026-10-05');
    await db.update(
      StaffAttendanceDao.table,
      {'sync_status': 'SYNCED'},
      where: 'id = ?',
      whereArgs: ['a'],
    );

    expect(
      await StaffAttendanceDao(
        db,
      ).unsyncedCount('s-1', from: '2026-10-01', to: '2026-10-31'),
      0,
    );
  });
}
