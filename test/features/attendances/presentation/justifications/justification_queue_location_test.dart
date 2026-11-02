import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/pages/justification_queue_page.dart';

class _Cubit extends MockCubit<JustificationQueueState>
    implements JustificationQueueCubit {}

/// L'onglet de la file (« À traiter » / « Traitées ») vit dans l'adresse.
void main() {
  late _Cubit cubit;
  late StreamController<JustificationQueueState> states;
  late GoRouter router;

  setUpAll(() => registerFallbackValue(JustificationQueueFilter.open));

  setUp(() {
    cubit = _Cubit();
    states = StreamController<JustificationQueueState>.broadcast();
    whenListen(
      cubit,
      states.stream,
      initialState: const JustificationQueueState(),
    );
    when(() => cubit.setFilter(any())).thenReturn(null);
  });

  tearDown(() => states.close());

  Future<void> pump(WidgetTester tester, String location) async {
    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/home/:subMenuId',
          builder: (_, _) => BlocProvider<JustificationQueueCubit>.value(
            value: cubit,
            child: const JustificationQueueLocation(child: SizedBox()),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  String address() => router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('« Traitées » s\'inscrit dans l\'adresse', (tester) async {
    await pump(tester, '/home/justifications');
    expect(address(), '/home/justifications');

    when(() => cubit.state).thenReturn(
      const JustificationQueueState(filter: JustificationQueueFilter.decided),
    );
    states.add(cubit.state);
    await tester.pumpAndSettle();

    expect(address(), '/home/justifications?onglet=decided');
  });

  testWidgets('F5 : l\'adresse rouvre « Traitées »', (tester) async {
    await pump(tester, '/home/justifications?onglet=decided');

    verify(() => cubit.setFilter(JustificationQueueFilter.decided)).called(1);
  });

  testWidgets('contre-épreuve : une adresse nue garde « À traiter »', (
    tester,
  ) async {
    await pump(tester, '/home/justifications');

    verifyNever(() => cubit.setFilter(any()));
  });
}
