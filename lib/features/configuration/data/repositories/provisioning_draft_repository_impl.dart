import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/configuration/data/local/provisioning_draft_dao.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';

/// Brouillon persisté en base chiffrée, scopé `(école, utilisateur)`.
class ProvisioningDraftRepositoryImpl implements ProvisioningDraftRepository {
  final ProvisioningDraftDao _dao;
  final CurrentUserContext _currentUser;

  const ProvisioningDraftRepositoryImpl({
    required ProvisioningDraftDao dao,
    required CurrentUserContext currentUser,
  }) : _dao = dao,
       _currentUser = currentUser;

  @override
  Future<ProvisioningDraft?> load() async {
    final scope = _scope();
    if (scope == null) return null;

    try {
      return await _dao.find(schoolId: scope.schoolId, userId: scope.userId);
    } catch (_) {
      // Une lecture ne remonte jamais d'échec : sans brouillon, l'assistant
      // s'ouvre vierge, ce qui reste utilisable. Le refuser ne le serait pas.
      return null;
    }
  }

  @override
  Future<Either<Failure, Unit>> save({
    required ProvisioningRequest request,
    required int step,
    required int maxStep,
  }) async {
    final scope = _scope();
    if (scope == null) {
      return const Left(AuthFailure('Aucune session active'));
    }

    try {
      await _dao.save(
        schoolId: scope.schoolId,
        userId: scope.userId,
        request: request,
        step: step,
        // `maxStep` ne recule pas : revenir en arrière ne doit pas refermer les
        // étapes déjà atteintes.
        maxStep: maxStep < step ? step : maxStep,
      );
      return const Right(unit);
    } catch (error) {
      // Une écriture, elle, se dit : l'agent doit savoir que sa saisie ne
      // survivra pas à la fermeture de l'application.
      return Left(StorageFailure('Brouillon non enregistré : $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clear() async {
    final scope = _scope();
    if (scope == null) return const Right(unit);

    try {
      await _dao.delete(schoolId: scope.schoolId, userId: scope.userId);
      return const Right(unit);
    } catch (error) {
      return Left(StorageFailure('Brouillon non effacé : $error'));
    }
  }

  _DraftScope? _scope() {
    final schoolId = _currentUser.schoolId;
    final userId = _currentUser.uid;
    if (schoolId == null || userId == null) return null;
    return _DraftScope(schoolId: schoolId, userId: userId);
  }
}

class _DraftScope {
  final String schoolId;
  final String userId;

  const _DraftScope({required this.schoolId, required this.userId});
}
