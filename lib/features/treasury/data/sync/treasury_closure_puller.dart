import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/treasury/data/local/treasury_closure_dao.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';

/// Clé de routage du flux `treasury.closures` côté client.
const String kTreasuryClosuresResource = 'treasury_closures';

/// Une page du flux : des clôtures, réouvertures comprises. Une ligne
/// illisible est sautée, la page reste lisible.
class TreasuryClosurePageDto extends ParsedKeysetPage<CashClosure> {
  TreasuryClosurePageDto._(ParsedKeysetPage<CashClosure> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory TreasuryClosurePageDto.fromJson(Map<String, dynamic> json) =>
      TreasuryClosurePageDto._(ParsedKeysetPage.fromJson(json, _tryParse));

  static CashClosure? _tryParse(Object? raw) {
    try {
      return TreasuryWire.closureFromJson(raw);
    } catch (_) {
      return null;
    }
  }
}

/// La descente des clôtures de caisse (R11, R20).
class TreasuryClosurePuller {
  final Dio _dio;
  final KeysetPullRunner _runner;
  final TreasuryClosureDao _dao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const TreasuryClosurePuller({
    required Dio dio,
    required KeysetPullRunner runner,
    required TreasuryClosureDao dao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _dio = dio,
       _runner = runner,
       _dao = dao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  /// Quelques lignes par jour ouvré et par devise.
  static const int pageLimit = 500;

  /// Curseur scopé par école : une tablette réaffectée ne reprend pas la
  /// seconde école là où la première s'était arrêtée.
  static String cursorKey(String schoolId) =>
      '$kTreasuryClosuresResource@$schoolId';

  Future<Either<Failure, KeysetPullResult>> pull() async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ServerFailure('Aucune école courante'));
    }
    return _runner.run(
      cursorKey: cursorKey(schoolId),
      label: kTreasuryClosuresResource,
      fetch: _fetch,
      apply: (items, nowMs) =>
          _dao.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
    );
  }

  /// Un 304 remonte en `DioException`, comme le lit `KeysetPullRunner`.
  Future<TreasuryClosurePageDto> _fetch(String? cursor) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AppConstants.syncTreasuryClosuresEndpoint,
      queryParameters: {'cursor': ?cursor, 'limit': pageLimit},
      options: Options(extra: _requiredAuth),
    );
    return TreasuryClosurePageDto.fromJson(response.data ?? const {});
  }
}

/// [PullHandler] du flux `treasury.closures`, accordé par `treasury.read`.
class TreasuryClosurePullHandler implements PullHandler {
  final TreasuryClosurePuller _puller;

  const TreasuryClosurePullHandler(this._puller);

  @override
  String get resource => kTreasuryClosuresResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.treasuryRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _puller.pull();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
