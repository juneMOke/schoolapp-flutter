import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_outbox_handler.dart'
    show kChapitreNotYetSyncedCode;
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_keyset_cycle.dart';

/// Lecture d'un échec de remontée du programme, partagée par ses handlers.
///
/// Le transport, les 5xx et 401/408/429 se rejouent ; un 409 sans code aussi
/// (même identifiant encore en vol). Deux 4xx ont un sens à eux :
/// - 409 `CHAPITRE_NOT_YET_SYNCED` : un enfant (note, ressource, ordre) est
///   arrivé avant son chapitre — une **attente**, sans tentative consommée ;
/// - 403 `COURS_NOT_OWNED` : le cours n'est plus au professeur — le geste n'a
///   plus d'objet, le cours quitte la tablette.
/// Tout autre 4xx est déterministe : le serveur n'a rien écrit.
class ProgrammePushFailure {
  final int? status;
  final String? detailCode;
  final String reason;
  final bool coursNotOwned;

  const ProgrammePushFailure._(
    this.status,
    this.detailCode,
    this.reason,
    this.coursNotOwned,
  );

  factory ProgrammePushFailure.of(DioException e) => ProgrammePushFailure._(
    e.response?.statusCode,
    ApiErrorParser.detailCodeOf(e.response),
    ApiErrorParser.pushFailureReason(e),
    isCoursNotOwned(e),
  );

  static const Set<int> transientStatuses = {401, 408, 429};

  bool get isTransient =>
      status == null ||
      status! >= 500 ||
      transientStatuses.contains(status) ||
      (status == 409 && detailCode == null);

  bool get awaitsChapitre =>
      status == 409 && detailCode == kChapitreNotYetSyncedCode;

  /// L'objet n'existe plus côté serveur (supprimé ailleurs).
  bool get isGone => status == 410 || status == 404;

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
