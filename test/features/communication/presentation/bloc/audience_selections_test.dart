import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/audience_selections.dart';

void main() {
  test('changer de mode garde les sélections des autres modes', () {
    final s = const AudienceSelections()
        .withMode(AudienceMode.levels)
        .toggleLevel('l-1')
        .withMode(AudienceMode.classrooms)
        .toggleClassroom('c-1')
        .withMode(AudienceMode.levels);
    expect(s.audience, const LevelsAudience(['l-1']));
    expect(
      s.withMode(AudienceMode.classrooms).audience,
      const ClassroomsAudience(['c-1']),
    );
  });

  test(
    'le libellé d\'un niveau coche toutes ses classes, puis les décoche',
    () {
      final some = const AudienceSelections().toggleClassroom('a');
      final all = some.toggleClassrooms(['a', 'b']);
      expect(all.classroomIds, ['a', 'b']);
      expect(all.toggleClassrooms(['a', 'b']).classroomIds, isEmpty);
    },
  );

  test('un élève ne s\'ajoute qu\'une fois', () {
    const grace = AudienceStudent(id: 's-1', lastName: 'KABONGO');
    final s = const AudienceSelections().addStudent(grace).addStudent(grace);
    expect(s.students, [grace]);
    expect(s.removeStudent('s-1').students, isEmpty);
  });

  test('une autre nature remet la tranche à « toutes »', () {
    final s = const AudienceSelections(
      mode: AudienceMode.overdue,
    ).withFee('TUITION', tariffCode: 'T1').withOverdueDays(30);
    expect(
      s.audience,
      const OverdueAudience(
        feeCode: 'TUITION',
        tariffCode: 'T1',
        overdueDays: 30,
      ),
    );
    expect(
      s.withFee('TRANSPORT').audience,
      const OverdueAudience(feeCode: 'TRANSPORT', overdueDays: 30),
    );
  });

  test('relire une audience reçue', () {
    final s = AudienceSelections.of(
      const OverdueAudience(feeCode: 'TUITION', overdueDays: 60),
    );
    expect(s.mode, AudienceMode.overdue);
    expect(s.overdueDays, 60);
    final students = AudienceSelections.of(const StudentsAudience.ids(['x']));
    expect(students.students.single.id, 'x');
  });
}
