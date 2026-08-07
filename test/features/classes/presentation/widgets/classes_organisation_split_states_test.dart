import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_states.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpState(
    WidgetTester tester, {
    required ClassroomStatus status,
    ClassroomErrorType errorType = ClassroomErrorType.none,
    List<OfflineClassroom> classrooms = const <OfflineClassroom>[],
    String? errorMessage,
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClassesOrganisationSplitResults(
              classroomsStatus: status,
              classroomsErrorType: errorType,
              classrooms: classrooms,
              composedRosters: const {},
              unassignedEnrollments: const <EnrollmentSummary>[],
              isAssigning: false,
              assigningEnrollmentId: '',
              errorMessage: errorMessage,
              onTransferTap: (_) {},
              onRetry: onRetry ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('chargement : squelette de cartes (pas de spinner)', (
    tester,
  ) async {
    // pas de pumpAndSettle : le shimmer boucle.
    await pumpState(tester, status: ClassroomStatus.loading);

    expect(find.byType(ClassesOrganisationClassroomsSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('vide : médaillon + « Aucun élève à répartir » + invite', (
    tester,
  ) async {
    await pumpState(
      tester,
      status: ClassroomStatus.success,
      classrooms: const <OfflineClassroom>[],
    );

    expect(find.byType(ClassesOrganisationSplitEmptyState), findsOneWidget);
    expect(find.text('Aucun élève à répartir'), findsOneWidget);
  });

  testWidgets('erreur : ErrorState partagé + Réessayer relance', (
    tester,
  ) async {
    var retried = 0;
    await pumpState(
      tester,
      status: ClassroomStatus.failure,
      errorType: ClassroomErrorType.network,
      errorMessage: 'Vérifiez votre connexion internet.',
      onRetry: () => retried++,
    );

    expect(find.byType(EteeloErrorResult), findsOneWidget);
    expect(find.text('Vérifiez votre connexion internet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Réessayer'));
    await tester.pump();
    expect(retried, 1);
  });
}
