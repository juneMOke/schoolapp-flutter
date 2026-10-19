import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_pull_to_sync.dart';

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// Tirer un écran vers le bas relance la synchronisation — même quand le
/// défilement est celui de la page, sous son fond, et non la racine.
void main() {
  late _MockSyncStatusCubit cubit;

  setUp(() {
    cubit = _MockSyncStatusCubit();
    whenListen(
      cubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    when(() => cubit.syncNow()).thenAnswer((_) async {});
  });

  Future<void> pullDown(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: ShellPullToSync(
            // Défilement imbriqué, comme celui d'`AppPageBackground`.
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [for (var i = 0; i < 80; i++) Text('ligne $i')],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.fling(find.text('ligne 0'), const Offset(0, 300), 1000);
    // Défilement, mise en place de l'indicateur, puis son retrait.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('tablette, téléphone : le geste relance la synchro', (
    tester,
  ) async {
    await pullDown(tester);
    verify(() => cubit.syncNow()).called(1);
  });

  testWidgets('poste de bureau : rien ne se tire', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await pullDown(tester);
    debugDefaultTargetPlatformOverride = null;
    verifyNever(() => cubit.syncNow());
  });
}
