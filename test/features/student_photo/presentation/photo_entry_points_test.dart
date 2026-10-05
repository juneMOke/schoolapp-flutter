import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/avatars/person_photo_source.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_edit_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_recap_row.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_session_button.dart';
import 'package:school_app_flutter/features/student_photo/presentation/widgets/photo_slot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements StudentPhotoRepository {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _id = 's-1';

void main() {
  late _MockRepository repository;
  late StudentPhotoRegistry registry;
  late StreamController<Set<String>> changes;
  var index = <String, StudentPhotoRef>{};

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const StudentPhotoRef(studentId: 'x'));
    registerFallbackValue(StudentPhotoSize.thumb);
  });

  setUp(() async {
    repository = _MockRepository();
    changes = StreamController<Set<String>>.broadcast();
    index = {};
    when(() => repository.changes).thenAnswer((_) => changes.stream);
    when(() => repository.loadIndex()).thenAnswer((_) async => Right(index));
    when(
      () => repository.bytesOf(any(), any(), exact: any(named: 'exact')),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repository.removePhoto(
        studentId: any(named: 'studentId'),
        removedAt: any(named: 'removedAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    registry = StudentPhotoRegistry(
      loadIndex: LoadStudentPhotoIndexUseCase(repository),
      read: ReadStudentPhotoUseCase(repository),
    );
    await getIt.reset();
    getIt
      ..registerSingleton<StudentPhotoRegistry>(registry)
      ..registerFactory<StudentPhotoEditCubit>(
        () => StudentPhotoEditCubit(
          remove: RemoveStudentPhotoUseCase(repository),
        ),
      );
  });

  tearDown(() async {
    await registry.dispose();
    await changes.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    List<String>? permissions,
    StudentPhotoDraftCubit? draft,
  }) async {
    await registry.start();
    Widget body = child;
    if (draft != null) {
      body = BlocProvider<StudentPhotoDraftCubit>.value(
        value: draft,
        child: body,
      );
    }
    if (permissions != null) {
      final auth = _MockAuthBloc();
      final state = AuthState(
        status: AuthStatus.authenticated,
        permissions: permissions,
      );
      when(() => auth.state).thenReturn(state);
      whenListen(auth, Stream<AuthState>.value(state), initialState: state);
      body = BlocProvider<AuthBloc>.value(value: auth, child: body);
    }
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
          body: PersonPhotoScope(
            source: registry,
            child: SingleChildScrollView(child: Center(child: body)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const slot = PhotoSlot(studentId: _id, studentName: 'Kabongo Daniel');

  group('PhotoSlot', () {
    testWidgets('sans photo : Prendre, Importer, facultatif', (tester) async {
      await pump(tester, slot);
      expect(find.text('Prendre'), findsOneWidget);
      expect(find.text('Importer'), findsOneWidget);
      expect(find.text('Facultatif'), findsOneWidget);
    });

    testWidgets('sans le droit : la mention du secrétariat, aucun geste', (
      tester,
    ) async {
      await pump(tester, slot, permissions: const ['student.read']);
      expect(find.text('Gérée par le secrétariat'), findsOneWidget);
      expect(find.text('Prendre'), findsNothing);
    });

    testWidgets('avec photo : Reprendre · Recadrer · Retirer ; le retrait se '
        'confirme en place', (tester) async {
      index = {_id: const StudentPhotoRef(studentId: _id, version: 's:1')};
      await pump(tester, slot, permissions: const ['student.photo.write']);

      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.text('Recadrer'), findsOneWidget);
      await tester.tap(find.text('Retirer'));
      await tester.pump();
      expect(find.text('Retirer la photo ?'), findsOneWidget);

      await tester.tap(find.text('Retirer'));
      await tester.pump();
      verify(
        () => repository.removePhoto(
          studentId: _id,
          removedAt: any(named: 'removedAt'),
        ),
      ).called(1);
    });

    testWidgets('« Non » annule le retrait', (tester) async {
      index = {_id: const StudentPhotoRef(studentId: _id, version: 's:1')};
      await pump(tester, slot);
      await tester.tap(find.text('Retirer'));
      await tester.pump();
      await tester.tap(find.text('Non'));
      await tester.pump();
      expect(find.text('Retirer la photo ?'), findsNothing);
      verifyNever(
        () => repository.removePhoto(
          studentId: any(named: 'studentId'),
          removedAt: any(named: 'removedAt'),
        ),
      );
    });

    testWidgets('un geste en attente, puis refusé, se dit sous la photo', (
      tester,
    ) async {
      index = {
        _id: const StudentPhotoRef(
          studentId: _id,
          version: 'p:1',
          isPending: true,
        ),
      };
      await pump(tester, slot);
      expect(find.text("En attente d'envoi"), findsOneWidget);

      index = {
        _id: const StudentPhotoRef(
          studentId: _id,
          rejection: 'PHOTO_NOT_SQUARE',
        ),
      };
      changes.add({_id});
      await tester.pump();
      await tester.pump();
      expect(find.text('Photo refusée par le serveur'), findsOneWidget);
    });

    testWidgets('nouvelle inscription : la photo gardée attend l\'étape', (
      tester,
    ) async {
      final draft = StudentPhotoDraftCubit(
        save: SaveStudentPhotoUseCase(repository),
      );
      await draft.keep(Uint8List.fromList([1, 2]), DateTime(2026));
      await pump(tester, slot, draft: draft);
      expect(find.text("Enregistrée avec l'étape"), findsOneWidget);
      expect(find.text('Recadrer'), findsOneWidget);

      await tester.tap(find.text('Retirer'));
      await tester.pump();
      await tester.tap(find.text('Retirer'));
      await tester.pump();
      expect(draft.state.photo, isNull);
      verifyNever(
        () => repository.removePhoto(
          studentId: any(named: 'studentId'),
          removedAt: any(named: 'removedAt'),
        ),
      );
      await draft.close();
    });
  });

  group('PhotoRecapRow', () {
    const row = PhotoRecapRow(
      studentId: _id,
      firstName: 'Daniel',
      lastName: 'Kabongo',
      studentName: 'Kabongo Daniel',
    );

    testWidgets('sans photo : un rappel facultatif, jamais une erreur', (
      tester,
    ) async {
      await pump(tester, row);
      expect(find.text('Non renseignée — facultatif'), findsOneWidget);
      expect(find.text('Ajouter une photo'), findsOneWidget);
    });

    testWidgets('avec photo : « Ajoutée » et « Reprendre »', (tester) async {
      index = {_id: const StudentPhotoRef(studentId: _id, version: 's:1')};
      await pump(tester, row);
      expect(find.text('Ajoutée'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
    });

    testWidgets('sans le droit : le statut, pas l\'action', (tester) async {
      await pump(tester, row, permissions: const ['student.read']);
      expect(find.text('Non renseignée — facultatif'), findsOneWidget);
      expect(find.text('Ajouter une photo'), findsNothing);
    });
  });

  group('PhotoSessionButton', () {
    testWidgets('absent sans le droit, présent avec', (tester) async {
      await pump(
        tester,
        const PhotoSessionButton(),
        permissions: const ['enrollment.read'],
      );
      expect(find.text('Séance photo'), findsNothing);

      await pump(
        tester,
        const PhotoSessionButton(),
        permissions: const ['student.photo.write'],
      );
      expect(find.text('Séance photo'), findsOneWidget);
    });
  });
}
