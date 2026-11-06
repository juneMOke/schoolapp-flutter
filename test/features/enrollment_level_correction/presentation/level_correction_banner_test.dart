import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_status_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockStatus extends MockCubit<LevelCorrectionStatusState>
    implements LevelCorrectionStatusCubit {}

LevelCorrection _correction(LevelCorrectionStatus status, {String? code}) =>
    LevelCorrection(
      id: 'g-1',
      enrollmentId: 'enr-1',
      studentId: 'stu-1',
      academicYearId: 'year-1',
      fromSchoolLevelId: 'lvl-m2',
      toSchoolLevelId: 'lvl-p2',
      toSchoolLevelGroupId: 'grp',
      reason: 'Motif',
      correctedAt: '2026-11-06T10:15:00.000Z',
      status: status,
      refusalCode: code,
    );

void main() {
  late _MockStatus cubit;
  setUp(() => cubit = _MockStatus());

  Future<AppLocalizations> pump(
    WidgetTester tester,
    LevelCorrection? correction,
  ) async {
    when(() => cubit.state).thenReturn(LevelCorrectionStatusState(correction));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<LevelCorrectionStatusCubit>.value(
            value: cubit,
            child: LevelCorrectionBanner(
              levelName: (id) => const {
                'lvl-m2': '2e maternelle',
                'lvl-p2': '2e primaire',
              }[id]!,
            ),
          ),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  }

  testWidgets('en attente : les deux niveaux, et la caisse suspendue', (
    tester,
  ) async {
    final l10n = await pump(tester, _correction(LevelCorrectionStatus.pending));
    expect(
      find.textContaining(
        l10n.levelCorrectionBannerPendingLead('2e maternelle', '2e primaire'),
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        l10n.levelCorrectionBannerPendingBody,
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('refusée : la phrase du refus', (tester) async {
    final l10n = await pump(
      tester,
      _correction(LevelCorrectionStatus.refused, code: 'STALE_LEVEL'),
    );
    expect(
      find.textContaining(
        l10n.levelCorrectionBannerRefused(
          '2e maternelle',
          '2e primaire',
          l10n.levelCorrectionRefusedStaleLevel,
        ),
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('appliquée, ou aucune : rien', (tester) async {
    await pump(tester, _correction(LevelCorrectionStatus.applied));
    expect(find.byType(RichText), findsNothing);
    await pump(tester, null);
    expect(find.byType(RichText), findsNothing);
  });
}
