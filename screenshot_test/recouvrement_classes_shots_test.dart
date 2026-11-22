// Captures du bloc D et de la fiche de classe (O2) du Recouvrement — HORS CI.
//
//   flutter test screenshot_test/recouvrement_classes_shots_test.dart \
//     --dart-define=SHOTS_OUT=/chemin/de/sortie
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../test/features/recouvrement/fixtures/recovery_fixtures.dart';
import 'recouvrement_shots.dart';

class _Repo extends Mock implements RecoveryDashboardRepository {}

class _Pending extends Mock implements CountPendingPaymentsUseCase {}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    registerFallbackValue(
      const RecoveryStudentsQuery(question: RecoveryQuestion(feeCodes: ['X'])),
    );
    final repo = _Repo();
    final pending = _Pending();
    when(pending.call).thenAnswer((_) async => const Right(0));
    when(
      () => repo.students(
        any(),
        any(),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => Right(recoveryStudentsFixture()));
    getIt.registerFactory<RecoveryStudentsCubit>(
      () => RecoveryStudentsCubit(repository: repo, countPending: pending),
    );
  });

  Widget app(Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  final d = recoveryDashboardFixture();

  for (final w in [360.0, 600.0, 860.0, 1312.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('classes $w x$scale', (tester) async {
        await shoot(
          tester,
          'classes_${w.toInt()}_x$scale',
          Size(w, 1100),
          app(
            Scaffold(
              backgroundColor: AppColors.surface,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: RecoveryClassRankingPanel(
                  dashboard: d,
                  rankingFeeCode: 'TUITION',
                  onRankingFeeChanged: (_) {},
                  onClassTapped: (_) {},
                ),
              ),
            ),
          ),
          textScale: scale,
        );
      });
    }
  }

  for (final size in [const Size(360, 740), const Size(1280, 900)]) {
    testWidgets('fiche ${size.width}', (tester) async {
      final row = d.classRankings.single.ranked[8];
      await _shootAfterTap(
        tester,
        'classe_fiche_${size.width.toInt()}',
        size,
        app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showRecoveryClassSheet(
                    context,
                    academicYearId: 'y1',
                    question: const RecoveryQuestion(feeCodes: ['TUITION']),
                    feeCode: 'TUITION',
                    feeLabel: 'Frais de scolarité',
                    row: row,
                    situationAt: DateTime(2026, 9, 5),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Comme `shoot`, mais touche « ouvrir » avant la capture (la fiche est une
/// sur-couche).
Future<void> _shootAfterTap(
  WidgetTester tester,
  String name,
  Size size,
  Widget child,
) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: child));
  await tester.tap(find.text('ouvrir'));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$shotsOut/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  tester.view.reset();
}
