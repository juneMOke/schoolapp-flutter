import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_breadcrumb.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_identity_step.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_job_step.dart';

import '../../staff_builders.dart';
import 'staff_agent_harness.dart';

/// Consulter un agent sur grand écran : la fiche entière sur deux colonnes,
/// sans assistant à étapes ; plus étroit, l'assistant reste.
void main() {
  late StaffAgentHarness h;

  setUpAll(StaffAgentHarness.registerFallbacks);

  setUp(() {
    h = StaffAgentHarness()..register(GetIt.instance);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('grand écran : identité et poste côte à côte, sans étapes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await h.pump(
      tester,
      member: member('m-1', firstName: 'Jean'),
      size: const Size(1440, 900),
    );
    await tester.pump();

    expect(find.byType(WizardBreadcrumb), findsNothing);
    final identity = tester.getRect(find.byType(StaffIdentityStep));
    final job = tester.getRect(find.byType(StaffJobStep));
    expect(job.left, greaterThan(identity.right));
  });

  testWidgets('écran moyen : l’assistant, une étape à la fois', (tester) async {
    await h.pump(tester, member: member('m-1', firstName: 'Jean'));
    expect(find.byType(WizardBreadcrumb), findsOneWidget);
    expect(find.byType(StaffJobStep), findsNothing);
  });
}
