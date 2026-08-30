import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/student/data/datasources/parent_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/models/set_emergency_contact_request.dart';
import 'package:school_app_flutter/features/student/data/repositories/parent_repository_impl.dart';

class _MockRemote extends Mock implements ParentRemoteDataSource {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockMirror extends Mock implements EnrollmentReconciliationDao {}

/// Désignation du contact d'urgence — **100 % online, hors outbox**.
///
/// Une désignation n'est pas une saisie de guichet qu'on rejoue plus tard : la
/// route n'est pas idempotente au sens de la file d'écritures, et un rejeu
/// différé désignerait peut-être un tuteur que quelqu'un a entre-temps délogé.
void main() {
  late _MockRemote remote;
  late _MockConnectivity connectivity;
  late _MockMirror mirror;
  late ParentRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const SetEmergencyContactRequest(null));
  });

  setUp(() {
    remote = _MockRemote();
    connectivity = _MockConnectivity();
    mirror = _MockMirror();
    repository = ParentRepositoryImpl(
      remoteDataSource: remote,
      requiredAuth: const <String, dynamic>{},
      connectivityService: connectivity,
      emergencyContactMirror: mirror,
    );
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(
      () => mirror.applyEmergencyContactDesignation(
        studentId: any(named: 'studentId'),
        parentId: any(named: 'parentId'),
      ),
    ).thenAnswer((_) async {});
  });

  DioException dioWith(Failure failure) => DioException(
    requestOptions: RequestOptions(path: '/x'),
    error: failure,
  );

  test('204 : la désignation est reflétée en base locale', () async {
    when(
      () => remote.setEmergencyContact(any(), any(), any()),
    ).thenAnswer((_) async {});

    final result = await repository.setEmergencyContact(
      studentId: 'stu-1',
      parentId: 'par-1',
    );

    expect(result, const Right<Failure, Unit>(unit));
    // L'écran de consultation est 100 % local : sans ce reflet, il garderait
    // l'ancien contact jusqu'au prochain pull.
    verify(
      () => mirror.applyEmergencyContactDesignation(
        studentId: 'stu-1',
        parentId: 'par-1',
      ),
    ).called(1);
  });

  test('le retrait (parentId null) part et se reflète aussi', () async {
    when(
      () => remote.setEmergencyContact(any(), any(), any()),
    ).thenAnswer((_) async {});

    await repository.setEmergencyContact(studentId: 'stu-1', parentId: null);

    verify(
      () => mirror.applyEmergencyContactDesignation(
        studentId: 'stu-1',
        parentId: null,
      ),
    ).called(1);
  });

  /// Pré-garde, pas verdict : elle évite de présenter comme une panne ce qui
  /// n'est qu'une absence de réseau — et surtout, elle dit que RIEN n'est mis
  /// en file d'attente.
  test('hors ligne : refus net, aucun appel, aucun reflet', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    final result = await repository.setEmergencyContact(
      studentId: 'stu-1',
      parentId: 'par-1',
    );

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('right'));
    verifyNever(() => remote.setEmergencyContact(any(), any(), any()));
    verifyNever(
      () => mirror.applyEmergencyContactDesignation(
        studentId: any(named: 'studentId'),
        parentId: any(named: 'parentId'),
      ),
    );
  });

  /// Le `409` remonte TEL QUEL : c'est une course entre deux postes que
  /// l'index unique du serveur vient de trancher, et le rejeu converge. Le
  /// rabattre sur un échec générique ferait renoncer là où un second appui
  /// suffit.
  test('409 : ConflictFailure conservée, sans reflet local', () async {
    when(
      () => remote.setEmergencyContact(any(), any(), any()),
    ).thenThrow(dioWith(const ConflictFailure('Conflict — stale version')));

    final result = await repository.setEmergencyContact(
      studentId: 'stu-1',
      parentId: 'par-1',
    );

    result.fold((f) => expect(f, isA<ConflictFailure>()), (_) => fail('right'));
    verifyNever(
      () => mirror.applyEmergencyContactDesignation(
        studentId: any(named: 'studentId'),
        parentId: any(named: 'parentId'),
      ),
    );
  });

  test('404 : NotFoundFailure conservée', () async {
    when(
      () => remote.setEmergencyContact(any(), any(), any()),
    ).thenThrow(dioWith(const NotFoundFailure('Resource not found')));

    final result = await repository.setEmergencyContact(
      studentId: 'stu-1',
      parentId: 'par-1',
    );

    result.fold((f) => expect(f, isA<NotFoundFailure>()), (_) => fail('right'));
  });

  /// Le tuteur EST visible sur la fiche : un « tuteur non rattaché » serait un
  /// mensonge menant à une impasse. Le secrétariat a une sortie — déclarer la
  /// parenté — et le message doit la nommer.
  test('422 UNDECLARED_RELATIONSHIP : cause typée, pas un 422 nu', () async {
    when(() => remote.setEmergencyContact(any(), any(), any())).thenThrow(
      dioWith(
        const ValidationFailure(
          'UNDECLARED_RELATIONSHIP: le tuteur x est bien rattaché…',
        ),
      ),
    );

    final result = await repository.setEmergencyContact(
      studentId: 'stu-1',
      parentId: 'par-1',
    );

    result.fold(
      (f) => expect(f, isA<UndeclaredRelationshipFailure>()),
      (_) => fail('right'),
    );
  });

  test('un 422 d\'une AUTRE cause reste un 422 ordinaire', () async {
    when(
      () => remote.setEmergencyContact(any(), any(), any()),
    ).thenThrow(dioWith(const ValidationFailure('Champ manquant')));

    final result = await repository.setEmergencyContact(
      studentId: 'stu-1',
      parentId: 'par-1',
    );

    result.fold(
      (f) => expect(f, isNot(isA<UndeclaredRelationshipFailure>())),
      (_) => fail('right'),
    );
  });
}
