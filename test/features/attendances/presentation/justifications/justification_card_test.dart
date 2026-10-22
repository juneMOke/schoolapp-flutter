import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  AttendanceJustification justification({
    JustificationStatus status = JustificationStatus.pending,
    JustificationDecision? local,
    JustificationAcceptBlock? block,
    String? refusal,
    bool withFile = true,
  }) => AttendanceJustification(
    id: 'j1',
    studentId: 's1',
    classroomId: 'c1',
    academicYearId: 'y1',
    attendanceDate: '2026-10-14',
    reason: AbsenceReason.sickness,
    note: 'Fièvre, vu par le médecin',
    status: status,
    localDecision: local,
    acceptBlock: block,
    refusal: refusal,
    studentFirstName: 'Grace',
    studentLastName: 'Boboto',
    classroomName: '6e A',
    attachment: withFile
        ? const AttachmentRef(
            name: 'c.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 1,
            sha256: 'abc',
          )
        : null,
  );

  Future<List<String>> pump(
    WidgetTester tester,
    AttendanceJustification j, {
    bool attachmentAvailable = true,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: JustificationCard(
              justification: j,
              attachmentAvailable: attachmentAvailable,
              onOpenAttachment: () => taps.add('file'),
              onAccept: () => taps.add('accept'),
              onReject: () => taps.add('reject'),
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('une demande en attente propose la pièce et les deux décisions', (
    tester,
  ) async {
    final taps = await pump(tester, justification());

    expect(find.text('Boboto Grace'), findsOneWidget);
    expect(find.text('6e A'), findsOneWidget);
    expect(find.text('Fièvre, vu par le médecin'), findsOneWidget);
    await tester.tap(find.text('Voir la pièce'));
    await tester.tap(find.text('Refuser'));
    await tester.tap(find.text('Accepter'));
    expect(taps, ['file', 'reject', 'accept']);
  });

  testWidgets('acceptation refusée par le serveur : seul le refus reste', (
    tester,
  ) async {
    await pump(
      tester,
      justification(block: JustificationAcceptBlock.notAnAbsence),
    );

    expect(find.text('Accepter'), findsNothing);
    expect(find.text('Refuser'), findsOneWidget);
    expect(find.textContaining("n'est plus absent"), findsOneWidget);
  });

  testWidgets('hors ligne sans la pièce : le bouton est grisé', (tester) async {
    final taps = await pump(
      tester,
      justification(),
      attachmentAvailable: false,
    );

    await tester.tap(find.text('Pièce disponible en ligne'));
    expect(taps, isEmpty);
  });

  testWidgets('une décision en route ne propose plus que la pièce', (
    tester,
  ) async {
    await pump(tester, justification(local: JustificationDecision.accept));

    expect(find.text("Décision en cours d'envoi"), findsOneWidget);
    expect(find.text('Accepter'), findsNothing);
    expect(find.text('Refuser'), findsNothing);
    expect(find.text('Voir la pièce'), findsOneWidget);
  });

  testWidgets('un refus de la dernière décision est dit', (tester) async {
    await pump(tester, justification(refusal: 'droit retiré'));

    expect(find.text('Décision non transmise : droit retiré'), findsOneWidget);
  });
}
