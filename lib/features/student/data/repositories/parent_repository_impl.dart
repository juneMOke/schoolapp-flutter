import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/student/data/datasources/parent_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/models/create_parent_request.dart';
import 'package:school_app_flutter/features/student/data/models/set_emergency_contact_request.dart';
import 'package:school_app_flutter/features/student/data/models/update_parent_request.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';

class ParentRepositoryImpl implements ParentRepository {
  final ParentRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  /// Pré-garde de connexion pour la seule écriture ONLINE de ce dépôt.
  final ConnectivityService connectivityService;

  /// Reflet local d'une désignation acquittée. Le DAO appartient à la branche
  /// Inscription, et c'est là que vit `student_parent` — l'import croisé est
  /// assumé, comme il l'est déjà dans l'autre sens (`ParentSummary` importe
  /// `RelationshipType` d'inscription).
  final EnrollmentReconciliationDao emergencyContactMirror;

  const ParentRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
    required this.connectivityService,
    required this.emergencyContactMirror,
  });

  /// Marqueur du 422 « parenté jamais déclarée » — le seul refus de cette route
  /// qui offre une SORTIE au secrétariat (déclarer la parenté par
  /// `POST /api/v1/parents`, qui peut poser le drapeau dans le même appel).
  ///
  /// ⚠️ **Reconnu au préfixe du message tant que le serveur ne renseigne pas
  /// `detailCode` sur cette cause** — il sait le faire (le champ existe), mais
  /// ne l'utilise pas ici. Brancher sur une phrase est une dépendance qu'aucune
  /// reformulation ne survit : elle est donc isolée à cet endroit unique, à
  /// corriger d'une ligne le jour où le code machine arrive.
  static const String _undeclaredRelationshipCode = 'UNDECLARED_RELATIONSHIP';

  static bool _isUndeclaredRelationship(Failure failure) {
    if (failure is ApiErrorDetails &&
        failure.detailCode == _undeclaredRelationshipCode) {
      return true;
    }
    return failure.message.contains(_undeclaredRelationshipCode);
  }

  @override
  Future<Either<Failure, ParentSummary>> updateParent({
    required String parentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  }) async {
    try {
      final model = await remoteDataSource.updateParent(
        requiredAuth,
        parentId,
        UpdateParentRequest(
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          email: email,
          phoneNumber: phoneNumber,
          relationshipType: relationshipType,
        ),
      );
      return Right(model.toParentSummary());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ParentSummary>> createParent({
    required String studentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  }) async {
    try {
      final model = await remoteDataSource.createParent(
        requiredAuth,
        CreateParentRequest(
          studentId: studentId,
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          email: email,
          phoneNumber: phoneNumber,
          relationshipType: relationshipType,
        ),
      );
      return Right(model.toParentSummary());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setEmergencyContact({
    required String studentId,
    required String? parentId,
  }) async {
    // Pré-garde, pas verdict : l'appel peut encore échouer juste après. Elle
    // évite seulement de présenter comme une panne ce qui n'est qu'une absence
    // de réseau — et surtout, elle dit clairement que RIEN n'est mis en file.
    if (!await connectivityService.isOnline()) {
      return const Left(
        NetworkFailure(
          'Aucune connexion : le contact d\'urgence ne peut pas être modifié.',
        ),
      );
    }
    try {
      await remoteDataSource.setEmergencyContact(
        requiredAuth,
        studentId,
        SetEmergencyContactRequest(parentId),
      );
      // Reflet local APRÈS l'acquittement, jamais avant : l'écran de
      // consultation est 100 % local, et sans cette ligne il garderait
      // l'ancien contact jusqu'au prochain pull.
      await emergencyContactMirror.applyEmergencyContactDesignation(
        studentId: studentId,
        parentId: parentId,
      );
      return const Right(unit);
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is Failure) {
        if (_isUndeclaredRelationship(failure)) {
          return const Left(UndeclaredRelationshipFailure());
        }
        return Left(failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkParent({
    required String studentId,
    required String parentId,
  }) async {
    try {
      await remoteDataSource.unlinkParent(requiredAuth, studentId, parentId);
      return const Right(null);
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
