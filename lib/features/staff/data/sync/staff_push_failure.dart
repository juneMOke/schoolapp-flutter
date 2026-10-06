import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

/// Lecture d'un échec de remontée du fichier du personnel, partagée par ses
/// handlers d'outbox.
///
/// Le transport, les 5xx et 401/408/429 se rejouent ; un 4xx est déterministe
/// — la remontée est idempotente, un refus dit que le serveur n'a **rien**
/// écrit, et le rejouer jusqu'au poison ne ferait que retarder le même refus.
///
/// Le 409 a deux sens que seul le `detailCode` sépare :
/// - `STAFF_MEMBER_NOT_YET_SYNCED` / `STAFF_CONTRACT_NOT_YET_SYNCED` : ce qui
///   dépend d'une fiche (contrat, pièce) est arrivé avant elle — une **attente
///   de dépendance**, à rejouer sans consommer de tentative ([isDependencyWait]) ;
/// - `PAYROLL_NOT_YET_VALIDATED` : un versement nomme une validation de paie
///   pas encore arrivée au serveur — même attente ;
/// - `ADVANCE_NOT_YET_SYNCED` / `DISBURSEMENT_NOT_YET_SYNCED` : une
///   annulation arrive avant le fait qu'elle annule — même attente ;
/// - sans code : le même identifiant est encore en vol — un rejeu ordinaire.
class StaffPushFailure {
  final int? status;
  final String? detailCode;

  /// Le corps de la réponse, tel quel : certains refus portent l'état du
  /// serveur (`PAYROLL_STALE` rend ses chiffres).
  final Object? body;

  /// Cause lisible : le code machine d'abord, la phrase du serveur ensuite.
  final String reason;

  const StaffPushFailure._(
    this.status,
    this.detailCode,
    this.reason, [
    this.body,
  ]);

  static const String memberNotYetSynced = 'STAFF_MEMBER_NOT_YET_SYNCED';
  static const String contractNotYetSynced = 'STAFF_CONTRACT_NOT_YET_SYNCED';
  static const String payrollNotYetValidated = 'PAYROLL_NOT_YET_VALIDATED';
  static const String advanceNotYetSynced = 'ADVANCE_NOT_YET_SYNCED';
  static const String disbursementNotYetSynced = 'DISBURSEMENT_NOT_YET_SYNCED';

  /// Les 409 d'attente du module RH : rejoués sans consommer de tentative.
  static const Set<String> dependencyWaitCodes = {
    memberNotYetSynced,
    contractNotYetSynced,
    payrollNotYetValidated,
    advanceNotYetSynced,
    disbursementNotYetSynced,
  };

  /// Un refus décidé sur la tablette, sans réponse du serveur (une fiche
  /// parente refusée) : rangé comme un refus du serveur.
  const StaffPushFailure.local(String code, this.reason)
    : status = null,
      detailCode = code,
      body = null;

  factory StaffPushFailure.of(DioException e) {
    final status = e.response?.statusCode;
    final detailCode = ApiErrorParser.detailCodeOf(e.response);
    final reason = ApiErrorParser.pushFailureReason(e);
    return StaffPushFailure._(status, detailCode, reason, e.response?.data);
  }

  /// Statuts transitoires hormis les 5xx : jeton expiré (l'intercepteur
  /// ré-authentifie), délai, cadence.
  static const Set<int> transientStatuses = {401, 408, 429};

  bool get isDependencyWait =>
      status == 409 && dependencyWaitCodes.contains(detailCode);

  bool get isTransient =>
      status == null ||
      status! >= 500 ||
      transientStatuses.contains(status) ||
      (status == 409 && !isDependencyWait);

  /// Purgé côté serveur : rejouer ferait osciller.
  bool get isTombstoned => status == 410;

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
