import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/configuration/data/datasources/provisioning_remote_data_source.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_request_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/school_identity_model.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';

/// Implémentation en ligne de la mise en service.
///
/// Les deux catalogues sont gardés **en mémoire, le temps de la session** —
/// jamais en base (D-9 du plan). Les persister n'ouvrirait rien : la simulation
/// et l'activation sont en ligne, et les comptes viennent du plan. En revanche
/// un catalogue persisté qui aurait vieilli deviendrait un fichier de constantes
/// qui se croit frais, et sa divergence n'apparaîtrait qu'en 422, à l'activation
/// — sur l'écriture irréversible.
class ProvisioningRepositoryImpl implements ProvisioningRepository {
  final ProvisioningRemoteDataSource _remote;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  ProvisioningRepositoryImpl({
    required ProvisioningRemoteDataSource remote,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _remote = remote,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  ProvisioningCatalog? _catalogCache;
  List<FeeCodeOption>? _feeCodesCache;

  @override
  Future<Either<Failure, ProvisioningCatalog>> loadCatalog({
    bool forceRefresh = false,
  }) async {
    final cached = _catalogCache;
    if (cached != null && !forceRefresh) return Right(cached);

    return _guard(() async {
      final model = await _remote.getCatalog(_requiredAuth);
      final catalog = model.toEntity();
      _catalogCache = catalog;
      // Le catalogue de frais n'est pas versionné avec celui-ci ; on ne purge
      // donc que ce qui vient d'être relu.
      return catalog;
    });
  }

  @override
  Future<Either<Failure, List<FeeCodeOption>>> loadFeeCodes({
    bool forceRefresh = false,
  }) async {
    final cached = _feeCodesCache;
    if (cached != null && !forceRefresh) return Right(cached);

    return _guard(() async {
      final models = await _remote.getFeeCodes(_requiredAuth);
      final codes = models.map((model) => model.toEntity()).toList();
      _feeCodesCache = codes;
      return codes;
    });
  }

  @override
  Future<Either<Failure, SchoolIdentity>> loadSchoolIdentity() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null) {
      return const Left(AuthFailure('Aucune session active'));
    }

    return _guard(() async {
      final model = await _remote.getSchool(_requiredAuth, schoolId);
      return model.toEntity(fallbackId: schoolId);
    });
  }

  @override
  Future<Either<Failure, SchoolIdentity>> saveSchoolIdentity(
    SchoolIdentity identity,
  ) async {
    // L'identifiant du chemin vient TOUJOURS de la session, jamais de l'entité
    // affichée : réutiliser celui d'une session antérieure rendrait 403, et le
    // message d'erreur ne dirait pas pourquoi.
    final schoolId = _currentUser.schoolId;
    if (schoolId == null) {
      return const Left(AuthFailure('Aucune session active'));
    }

    return _guard(() async {
      final model = await _remote.updateSchool(
        _requiredAuth,
        schoolId,
        SchoolIdentityModel.fromEntity(identity),
      );
      return model.toEntity(fallbackId: schoolId);
    });
  }

  @override
  Future<Either<Failure, ProvisioningPlan>> simulate(
    ProvisioningRequest request,
  ) => _apply(request, dryRun: true);

  @override
  Future<Either<Failure, ProvisioningPlan>> activate(
    ProvisioningRequest request,
  ) => _apply(request, dryRun: false);

  Future<Either<Failure, ProvisioningPlan>> _apply(
    ProvisioningRequest request, {
    required bool dryRun,
  }) async {
    final ProvisioningRequestModel body;
    try {
      body = ProvisioningRequestModel.fromEntity(request);
    } on StateError catch (error) {
      // Brouillon incomplet : refusé ici plutôt qu'en 400 côté serveur. Un
      // aller-retour réseau pour apprendre ce que le client sait déjà coûte à
      // l'agent une attente, et au journal serveur une fausse alerte.
      return Left(ValidationFailure(error.message));
    }

    return _guard(() async {
      final model = await _remote.apply(_requiredAuth, dryRun, body);
      return model.toEntity();
    });
  }

  /// Traduit les échecs réseau en [Failure], en préservant celles que
  /// l'intercepteur a déjà typées — c'est là que vivent le code serveur et la
  /// référence d'incident, dont l'écran a besoin pour décider quoi faire.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on DioException catch (error) {
      final failure = error.error;
      if (failure is Failure) return Left(failure);
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        // La requête est partie, son sort est inconnu. Sur l'activation, c'est
        // la distinction qui compte : rejouer une écriture peut-être exécutée
        // produirait le refus « année déjà existante », que rien à l'écran ne
        // saurait expliquer.
        return const Left(UncertainOutcomeFailure());
      }
      return const Left(NetworkFailure('Réseau indisponible'));
    } catch (error) {
      return Left(ServerFailure('Réponse illisible : $error'));
    }
  }
}
