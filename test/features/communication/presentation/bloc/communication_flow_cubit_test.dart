import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/communication_flow_cubit.dart';

import '../../communication_fixtures.dart';

void main() {
  test('un envoyé s\'ouvre en détail, le reste dans l\'éditeur', () {
    final flow = CommunicationFlowCubit()
      ..open(announcement(status: AnnouncementStatus.sent));
    expect(flow.state, isA<CommunicationDetailScreen>());
    flow.open(announcement(status: AnnouncementStatus.failed));
    expect(flow.state, isA<CommunicationEditorScreen>());
  });

  test('deux « Nouveau » de suite ouvrent deux éditeurs distincts', () {
    final flow = CommunicationFlowCubit()..openNew();
    final first = flow.state;
    flow.openNew(seed: const AnnouncementContent(title: 'Copie'));
    expect(flow.state, isNot(first));
    flow.showList();
    expect(flow.state, isA<CommunicationListScreen>());
  });
}
