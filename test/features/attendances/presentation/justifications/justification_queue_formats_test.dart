import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/pages/justification_queue_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';

class _Cubit extends MockCubit<JustificationQueueState>
    implements JustificationQueueCubit {}

class _Years
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

/// Disciplines ▸ Justifications à chaque format de référence (AGENTS.md
/// §« Écran neuf ») : onglets, cartes à deux décisions et une note longue.
void main() {
  AttendanceJustification justification(String id, {String? note}) =>
      AttendanceJustification(
        id: id,
        studentId: 's-$id',
        classroomId: 'c1',
        academicYearId: 'y1',
        attendanceDate: '2026-10-14',
        reason: AbsenceReason.sickness,
        note: note ?? 'Fièvre, vu par le médecin',
        status: JustificationStatus.pending,
        studentFirstName: 'Grace-Esther',
        studentLastName: 'Boboto Mwamba Kalonji',
        classroomName: '6e A scientifique',
        attachment: const AttachmentRef(
          name: 'certificat-medical.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1,
          sha256: 'abc',
        ),
      );

  testAtReferenceFormats('la file des justifications tient', (
    tester,
    format,
  ) async {
    final cubit = _Cubit();
    final state = JustificationQueueState(
      load: JustificationQueueLoad.ready,
      academicYearId: 'y1',
      all: [
        justification('1'),
        justification(
          '2',
          note:
              'Hospitalisé trois jours à la suite d\'une crise de paludisme, '
              'le certificat du centre de santé est joint à la demande.',
        ),
        justification('3'),
      ],
    );
    whenListen(
      cubit,
      const Stream<JustificationQueueState>.empty(),
      initialState: state,
    );
    final years = _Years();
    const yearState = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.loading,
    );
    whenListen(
      years,
      const Stream<AcademicYearContextState>.empty(),
      initialState: yearState,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AcademicYearContextBloc>.value(value: years),
              BlocProvider<JustificationQueueCubit>.value(value: cubit),
            ],
            child: const JustificationQueueScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Boboto Mwamba Kalonji Grace-Esther'), findsWidgets);
  });
}
