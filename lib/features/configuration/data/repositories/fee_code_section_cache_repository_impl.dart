import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_dao.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_local_model.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/configuration/data/datasources/provisioning_remote_data_source.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/fee_code_section_cache_repository.dart';

/// Descend les titres de sections et les range dans `ref_fee_code_sections`.
class FeeCodeSectionCacheRepositoryImpl
    implements FeeCodeSectionCacheRepository {
  final ProvisioningRemoteDataSource _remote;
  final FeeCodeSectionDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;
  final DateTime Function() _clock;

  /// La session a-t-elle déjà obtenu le catalogue — ou appris qu'elle n'y a pas
  /// droit ?
  ///
  /// Le repository est un lazy singleton : ce drapeau vit donc aussi longtemps
  /// que la session, ce qui est exactement la portée voulue. Il est armé par un
  /// SUCCÈS, et par un **refus** (403) : un verdict ne change pas d'un écran à
  /// l'autre. Un échec réseau, lui, doit pouvoir être retenté au prochain écran,
  /// sans quoi une tablette démarrée hors couverture nommerait ses frais par la
  /// nature jusqu'à la déconnexion.
  bool _synced = false;

  FeeCodeSectionCacheRepositoryImpl({
    required ProvisioningRemoteDataSource remote,
    required FeeCodeSectionDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
    DateTime Function()? clock,
  }) : _remote = remote,
       _dao = dao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth,
       _clock = clock ?? DateTime.now;

  @override
  Future<Either<Failure, int>> ensureFeeSectionTitles() async {
    if (_synced) return const Right(0);
    final schoolId = _currentUser.schoolId ?? '';
    // Sans école résolue, on ne touche à rien : écrire sous la clé `''` rendrait
    // la ligne invisible à toute lecture scopée, et purger sous cette clé
    // effacerait le cache d'une base héritée. Ce n'est pas un échec — il n'y a
    // simplement rien à faire tant que la session n'a pas d'école.
    if (schoolId.isEmpty) return const Right(0);

    return _guard(
      () async {
        // `includeHidden: true`, et ce n'est pas un excès de zèle : la liste par
        // défaut ne sert pas les sections masquées, et une créance posée sur une
        // nature depuis masquée retomberait sur la nature localisée alors que
        // l'école l'a nommée. Masquer dit « ne me la propose plus à la saisie »,
        // jamais « ne sais plus la nommer ».
        //
        // C'est le piège que `SECTIONS_FRAIS_PLAN.md` §3 a déjà rencontré sur le
        // panneau des tarifs.
        final models = await _remote.getFeeCodes(_requiredAuth, true);
        final written = await _persist([
          for (final (index, model) in models.indexed)
            model.toEntity(fallbackSortOrder: index),
        ], schoolId: schoolId);
        // ⚠️ **Armée APRÈS l'écriture, pas après la réponse.** Une écriture en
        // base qui échoue laisserait sinon la session avec un cache vide et une
        // garde fermée : les frais seraient nommés par la nature jusqu'à la
        // déconnexion, alors que le serveur avait répondu.
        _synced = true;
        return written;
      },
      // Un profil qui a les créances sans le barème (rôle édité) est refusé :
      // chaque écran qui monte le cubit relancerait sinon l'appel, et chaque
      // refus s'inscrirait au journal du serveur. Ses titres lui viennent de
      // toute façon par le socle référentiel, qui ne les caviarde pas.
      onRefused: () => _synced = true,
    );
  }

  @override
  Future<Either<Failure, Unit>> cacheFeeCodeSections(
    List<FeeCodeOption> sections,
  ) async {
    final schoolId = _currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return const Right(unit);

    // Une écriture de cache qui échoue ne doit **rien** casser au-dessus : ce
    // chemin est appelé après un enregistrement réussi côté serveur, et faire
    // remonter un échec de base ferait passer pour raté un renommage qui a bien
    // eu lieu. Le prochain pull rattrape.
    try {
      await _persist(sections, schoolId: schoolId);
      // Ce qu'on vient d'écrire sort du serveur : la session n'a plus rien à
      // tirer.
      _synced = true;
      return const Right(unit);
    } catch (error) {
      return Left(StorageFailure(error.toString()));
    }
  }

  /// Range [sections] **à leur position** : l'ordre de la liste servie fait
  /// foi, et son `sortOrder` peut porter des ex æquo que seul le serveur sait
  /// départager. Le rang local est donc l'index, jamais le champ.
  Future<int> _persist(
    List<FeeCodeOption> sections, {
    required String schoolId,
  }) async {
    final syncedAt = _clock().millisecondsSinceEpoch;
    final rows = [
      for (final (index, section) in sections.indexed)
        FeeCodeSectionLocalModel(
          schoolId: schoolId,
          // Le code est normalisé ici, une fois : c'est la forme que sert le
          // serveur, mais le rapprochement en base se fait sur du texte et une
          // casse discordante ne nommerait plus rien.
          code: section.code.trim().toUpperCase(),
          label: section.label.trim(),
          active: section.active,
          sortOrder: index,
          syncedAt: syncedAt,
        ),
    ];
    await _dao.replaceForSchool(rows, schoolId: schoolId);
    return rows.where((row) => row.isUsable).length;
  }

  /// Même politique d'erreur que `ProvisioningRepositoryImpl` : les échecs déjà
  /// typés par l'intercepteur passent tels quels, le reste retombe sur le code
  /// HTTP puis sur le réseau.
  ///
  /// [onRefused] est prévenu d'un 403, que l'intercepteur l'ait typé ou non :
  /// c'est le code de la réponse qui fait foi, pas la forme de l'échec.
  ///
  /// Pas de cas `UncertainOutcomeFailure` ici, contrairement à l'activation :
  /// une lecture rejouée ne duplique rien.
  Future<Either<Failure, int>> _guard(
    Future<int> Function() call, {
    void Function()? onRefused,
  }) async {
    try {
      return Right(await call());
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 403) onRefused?.call();
      final failure = error.error;
      if (failure is Failure) return Left(failure);
      if (status != null) {
        return Left(
          ServerFailure(
            ApiErrorParser.serverMessageOf(error.response) ?? 'HTTP $status',
          ),
        );
      }
      return const Left(NetworkFailure('Réseau indisponible'));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}
