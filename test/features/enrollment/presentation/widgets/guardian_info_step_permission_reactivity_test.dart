import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_info_step_body.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _parent = ParentSummary(
  id: 'parent-1',
  firstName: 'Jean',
  lastName: 'Dupont',
  surname: 'K',
  identificationNumber: 'ID-123',
  phoneNumber: '+243000000000',
  email: 'jean.dupont@example.com',
  relationshipType: RelationshipType.guardian,
);

/// `kEnrollmentSubmitAccess` est une CONJONCTION : les deux droits, ou rien.
const _partial = <String>['enrollment.write'];
const _complete = <String>['enrollment.write', 'editique.write'];

/// L'étape lit le droit d'écrire dans `build` — donc juste à chaque
/// reconstruction — mais `PermissionGate.allows` ne s'abonne à rien, et rien ne
/// reconstruisait cette étape sur une émission de l'`AuthBloc`. Un droit
/// accordé ou retiré par un refresh en arrière-plan laissait les champs et la
/// corbeille dans l'état du montage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockOfflineBloc offlineBloc;

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    when(
      () => offlineBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());
    getIt.registerLazySingleton<IdGenerator>(() => const IdGenerator(Uuid()));
  });

  tearDown(() async => getIt.reset());

  bool bodyIsEditable(WidgetTester tester) => tester
      .widget<GuardianInfoStepBody>(find.byType(GuardianInfoStepBody))
      .isEditable;

  testWidgets('un droit complété en cours de session rouvre l\'écriture', (
    tester,
  ) async {
    final emissions = StreamController<AuthState>.broadcast();
    addTearDown(emissions.close);

    var current = const AuthState(
      status: AuthStatus.authenticated,
      permissions: _partial,
    );
    final authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenAnswer((_) => current);
    whenListen(authBloc, emissions.stream, initialState: current);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<EnrollmentOfflineBloc>.value(value: offlineBloc),
              BlocProvider<AuthBloc>.value(value: authBloc),
            ],
            child: const SizedBox(
              width: 360,
              child: GuardianInfoStep(
                parentDetails: [_parent],
                studentId: 'student-1',
                enrollmentId: 'enrollment-1',
                showInlineSaveButton: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      bodyIsEditable(tester),
      isFalse,
      reason: 'la conjonction n\'est pas satisfaite au montage',
    );

    current = const AuthState(
      status: AuthStatus.authenticated,
      permissions: _complete,
    );
    emissions.add(current);
    await tester.pumpAndSettle();

    expect(bodyIsEditable(tester), isTrue);
  });

  testWidgets('un droit retiré en cours de session referme l\'écriture', (
    tester,
  ) async {
    final emissions = StreamController<AuthState>.broadcast();
    addTearDown(emissions.close);

    var current = const AuthState(
      status: AuthStatus.authenticated,
      permissions: _complete,
    );
    final authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenAnswer((_) => current);
    whenListen(authBloc, emissions.stream, initialState: current);
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<EnrollmentOfflineBloc>.value(value: offlineBloc),
              BlocProvider<AuthBloc>.value(value: authBloc),
            ],
            child: const SizedBox(
              width: 360,
              child: GuardianInfoStep(
                parentDetails: [_parent],
                studentId: 'student-1',
                enrollmentId: 'enrollment-1',
                showInlineSaveButton: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(bodyIsEditable(tester), isTrue);

    current = const AuthState(
      status: AuthStatus.authenticated,
      permissions: _partial,
    );
    emissions.add(current);
    await tester.pumpAndSettle();

    expect(bodyIsEditable(tester), isFalse);
  });
}
