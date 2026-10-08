import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspended_members_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets('chaque élève dit son prénom, sa classe d\'origine et sa date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SuspendedMembersSection(
              members: [
                SuspendedMember(
                  suspension: StudentSuspension(
                    id: 'p',
                    enrollmentId: 'e',
                    studentId: 's',
                    academicYearId: 'y',
                    suspendedAt: DateTime(2026, 10, 8),
                  ),
                  classroomId: 'c-6b',
                  lastName: 'Ngalula',
                  middleName: 'Ntumba',
                  firstName: 'Ruth',
                ),
              ],
              classLabelOf: (id) => id == 'c-6b' ? '6e B' : '?',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Élèves désactivés · 1'), findsOneWidget);
    expect(find.text('Ngalula Ntumba'), findsOneWidget);
    expect(find.text('Ruth · 6e B · depuis le 8 octobre 2026'), findsOneWidget);
  });
}
