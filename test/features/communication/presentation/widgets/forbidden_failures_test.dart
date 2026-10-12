import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/audience/reach_box.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_failure_banner.dart';

import '../../communication_fixtures.dart';

/// Un refus de droit ne se rejoue pas : nulle part « Réessayer » sur un 403.
void main() {
  testWidgets('bandeau d\'échec : 403 → contacter, sans Réessayer', (
    tester,
  ) async {
    await tester.pumpWidget(
      communicationHost(
        EditorFailureBanner(
          failure: const UnauthorizedFailure(),
          gesture: AnnouncementEditorBusy.sending,
          refusal: null,
          onRetry: () {},
        ),
      ),
    );
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text("Contacter l'administrateur"), findsOneWidget);
  });

  testWidgets('bandeau d\'échec : réseau → Réessayer', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      communicationHost(
        EditorFailureBanner(
          failure: const NetworkFailure(),
          gesture: AnnouncementEditorBusy.sending,
          refusal: null,
          onRetry: () => retried++,
        ),
      ),
    );
    await tester.tap(find.text('Réessayer'));
    expect(retried, 1);
  });

  testWidgets('encart de portée : 403 → contacter, sans Réessayer', (
    tester,
  ) async {
    await tester.pumpWidget(
      communicationHost(
        ReachBox(
          state: const AnnouncementReachState(
            status: ReachStatus.failure,
            audience: SchoolAudience(),
            failure: UnauthorizedFailure(),
          ),
          onRetry: () {},
        ),
      ),
    );
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text("Contacter l'administrateur"), findsOneWidget);
  });
}
