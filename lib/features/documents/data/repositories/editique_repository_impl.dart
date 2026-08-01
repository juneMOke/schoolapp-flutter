import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/documents/data/datasources/editique_remote_data_source.dart';
import 'package:school_app_flutter/features/documents/data/mappers/editique_document_mapper.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';

/// Coordinateur : pré-garde de connectivité, appel réseau, délégation du mapping
/// (octets → document, exception → `Failure`). Aucune logique de format ici.
class EditiqueRepositoryImpl implements EditiqueRepository {
  final EditiqueRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final Map<String, dynamic> requiredAuth;

  const EditiqueRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, EditiqueDocument>> emitEnrollmentAttestation({
    required String enrollmentId,
  }) {
    return _emit(
      EditiqueDocumentType.enrollmentAttestation,
      () => remoteDataSource.emitEnrollmentAttestation(
        requiredAuth,
        enrollmentId,
      ),
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitNotePerception({
    required String studentId,
    required String academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.notePerception,
      () => remoteDataSource.emitNotePerception(
        requiredAuth,
        studentId,
        academicYearId,
      ),
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitPaymentReceipt({
    required String paymentId,
  }) {
    return _emit(
      EditiqueDocumentType.paymentReceipt,
      () => remoteDataSource.emitPaymentReceipt(requiredAuth, paymentId),
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitAccountStatement({
    required String studentId,
    required String academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.accountStatement,
      () => remoteDataSource.emitAccountStatement(
        requiredAuth,
        studentId,
        academicYearId,
      ),
    );
  }

  @override
  Future<Either<Failure, EditiqueDocument>> emitFinancialClearance({
    required String studentId,
    required String academicYearId,
  }) {
    return _emit(
      EditiqueDocumentType.financialClearance,
      () => remoteDataSource.emitFinancialClearance(
        requiredAuth,
        studentId,
        academicYearId,
      ),
    );
  }

  Future<Either<Failure, EditiqueDocument>> _emit(
    EditiqueDocumentType type,
    Future<HttpResponse<Uint8List>> Function() call,
  ) async {
    // Pré-garde de connectivité : sans elle, un appel hors ligne coûte le
    // `connectTimeout` de la requête PDF **plus** celui du mint proactif de
    // jeton déclenché par l'intercepteur d'authentification quand l'access
    // token est vide — de l'ordre de 12 s d'attente pour une issue connue
    // d'avance. La radio « up » ne prouve pas la joignabilité (cf.
    // [ConnectivityService]) : c'est une pré-garde, pas un verdict, et l'appel
    // reste seul juge quand elle passe.
    if (!await connectivityService.isOnline()) {
      return const Left(
        NetworkFailure('Aucune connexion : le document ne peut pas être émis.'),
      );
    }

    try {
      return EditiqueDocumentMapper.map(await call(), type);
    } on DioException catch (e) {
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Le sort de la requête est indéterminé (erreur locale survenue à un
      // moment inconnu du cycle). Sur une pièce non archivée, un numéro a
      // peut-être déjà été consommé — c'est le cas qui interdit le rejeu
      // automatique.
      return const Left(
        UncertainOutcomeFailure("L'émission du document a échoué."),
      );
    }
  }
}
