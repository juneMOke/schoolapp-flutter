import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/enrollment_suspension_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/repositories/enrollment_suspension_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../offline_full_db.dart';
import '../../suspension_fixtures.dart';

SuspensionTarget _target(String student) => SuspensionTarget(
  enrollmentId: enrollmentOf(student),
  studentId: student,
  academicYearId: kYear,
);

void main() {
  late Database db;
  late EnrollmentSuspensionChangeBus bus;
  late CurrentUserContext user;
  late EnrollmentSuspensionRepositoryImpl repository;

  setUp(() async {
    db = await openFullOfflineDb();
    bus = EnrollmentSuspensionChangeBus();
    user = CurrentUserContext()..set(kAuthor, schoolId: kSchool);
    repository = EnrollmentSuspensionRepositoryImpl(
      reader: EnrollmentSuspensionReadDao(db),
      writer: EnrollmentSuspensionWriteDao(db),
      bus: bus,
      currentUser: user,
      ids: const IdGenerator(Uuid()),
      now: () => DateTime.utc(2026, 10, 8, 9, 30).millisecondsSinceEpoch,
    );
  });
  tearDown(() => db.close());

  test('un lot désactive, annonce les inscriptions et date le geste', () async {
    final changes = bus.stream.first;

    final result = await repository.suspend(
      [_target('s1'), _target('s2')],
      reason: SuspensionReason.medical,
      precision: '  retour après les congés  ',
    );

    expect(result.getOrElse(() => -1), 2);
    expect(await changes, {enrollmentOf('s1'), enrollmentOf('s2')});
    final open = (await repository.openByEnrollment(kYear)).getOrElse(() => {});
    final s1 = open[enrollmentOf('s1')]!;
    expect(s1.precision, 'retour après les congés');
    expect(s1.suspendedAt.toUtc(), DateTime.utc(2026, 10, 8, 9, 30));
  });

  test('réactiver rend le nombre d\'élèves réactivés', () async {
    await repository.suspend([_target('s1')]);
    final result = await repository.reactivate([_target('s1'), _target('s2')]);
    expect(result.getOrElse(() => -1), 1);
    expect(
      (await repository.latestFor(
        enrollmentOf('s1'),
      )).getOrElse(() => null)!.isOpen,
      isFalse,
    );
  });

  test('sans session : échec, rien d\'écrit', () async {
    user.set(null);
    final result = await repository.suspend([_target('s1')]);
    expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
  });

  test('la précision est rognée, bornée, nulle si vide', () {
    expect(EnrollmentSuspensionRepositoryImpl.cleanPrecision('   '), isNull);
    expect(
      EnrollmentSuspensionRepositoryImpl.cleanPrecision('x' * 200)!.length,
      140,
    );
  });
}
