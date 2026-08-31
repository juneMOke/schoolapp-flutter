import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_sync_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';

/// Handler d'outbox de l'agrégat `BOUTIQUE_SALE`.
///
/// ## Ce qui protège l'argent ici
///
/// **L'encaissement a déjà eu lieu** quand ce code s'exécute : le client a payé,
/// l'article est parti. Tout ce qui suit ne décide donc plus *si* la vente
/// existe, seulement *quand* le serveur l'apprend — et rien ne doit pouvoir la
/// faire disparaître.
///
/// 1. **Garde de dépendance ENROLLMENT**, scopée à l'année de la vente, quand
///    une ligne désigne un bénéficiaire. `waiting` **et** `parentFailed` →
///    `blocked` : attente PROPRE, sans `attempts++`, sans backoff, sans faux
///    `SYNC_ERROR`. Elle est **moins critique** qu'elle ne l'était : le serveur
///    ne refuse plus une ligne dont il ne sait pas dériver le niveau, il
///    consigne une anomalie. Ce qu'elle évite désormais est un reçu au
///    bénéficiaire **anonyme** et une anomalie inutile — pas une perte de vente.
/// 2. **Idempotence** sur `sale.id` : un rejeu rend 200 et les mêmes valeurs.
/// 3. **Classification des échecs** : transitoire pour le transport, les 5xx et
///    401/408/409/429 ; déterministe pour les autres 4xx.
class BoutiqueSaleOutboxHandler implements OutboxSyncHandler {
  final BoutiqueSyncApi _api;
  final BoutiqueSaleWriteDao _dao;
  final OutboxDependencyGate _dependency;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const BoutiqueSaleOutboxHandler({
    required BoutiqueSyncApi api,
    required BoutiqueSaleWriteDao dao,
    required OutboxDependencyGate dependency,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _dependency = dependency,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => BoutiqueSaleWriteDao.aggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final BoutiqueSaleRequest request;
    try {
      request = BoutiqueSaleRequest.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (e) {
      // Un payload illisible ne se répare pas en le rejouant.
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    final blocked = await _dependencyBlock(request);
    if (blocked != null) return blocked;

    try {
      final ack = await _api.commitSale(_extras, request);
      await _dao.applySaleAck(request.sale.id, ack, nowMs: _now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _classifyDioError(e, request.sale.id);
    } catch (e) {
      // Échec LOCAL après un POST possiblement acquitté : impossible de
      // distinguer un verrou SQLite passager d'un bug d'apply. Retry-biaisé,
      // sens de panne sûr pour l'argent — le POST est idempotent, le rejeu rend
      // 200 et le même ACK.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// L'inscription du bénéficiaire doit être partie avant la vente.
  ///
  /// Une vente **walk-in** n'a aucune dépendance : elle ne nomme personne, et la
  /// bloquer sur une inscription qu'elle ne référence pas la retiendrait sans
  /// raison.
  Future<OutboxDispatchResult?> _dependencyBlock(
    BoutiqueSaleRequest request,
  ) async {
    final beneficiaries = {
      for (final line in request.lines)
        if (line.beneficiaryStudentId != null) line.beneficiaryStudentId!,
    };
    for (final studentId in beneficiaries) {
      switch (await _dependency(studentId, request.sale.academicYearId)) {
        case OutboxDependencyState.waiting:
          return const OutboxDispatchResult.blocked(
            'Inscription du bénéficiaire non synchronisée (dépendance)',
          );
        case OutboxDependencyState.parentFailed:
          // `blocked`, jamais `failed` : `failed` serait un cul-de-sac — aucune
          // entrée SYNC_ERROR ne se re-pousse — alors que `blocked` reste
          // AUTO-CICATRISANT. L'erreur d'inscription est déjà surfacée de son
          // côté ; dès qu'elle est corrigée, la vente repart seule.
          return const OutboxDispatchResult.blocked(
            'Inscription du bénéficiaire en échec de synchro — corrigez '
            'l\'inscription, la vente repartira ensuite',
          );
        case OutboxDependencyState.ready:
          break;
      }
    }
    return null;
  }

  /// Statuts HTTP **transitoires** hormis les 5xx : jeton expiré (401,
  /// l'intercepteur ré-authentifie), délai dépassé (408), conflit (409),
  /// cadence (429).
  static const Set<int> _transientStatuses = {401, 408, 409, 429};

  /// Classe un échec HTTP en transitoire (`retry`) ou déterministe (`failed`).
  ///
  /// Le POST est idempotent sur `sale.id` : une vente réellement enregistrée
  /// rendrait 200 au rejeu, jamais un 4xx. Un 4xx signifie donc que le serveur
  /// n'a **rien** enregistré, et le rejouer jusqu'au poison ne ferait que
  /// retarder le même `SYNC_ERROR`.
  ///
  /// **Les trois causes de 422 sont des bugs client**, et c'est pourquoi elles
  /// sont surfacées telles quelles plutôt que rejouées (cf.
  /// `BoutiqueErrorCodes`) : l'arithmétique du panier est fausse, l'article
  /// n'est pas au catalogue de cette école, ou l'année n'est pas la sienne.
  /// Aucune ne se résout en attendant.
  Future<OutboxDispatchResult> _classifyDioError(
    DioException e,
    String saleId,
  ) async {
    final status = e.response?.statusCode;
    if (status == null ||
        status >= 500 ||
        _transientStatuses.contains(status)) {
      return OutboxDispatchResult.retry(_reasonOf(e, status));
    }

    final reason = _reasonOf(e, status);
    // La raison est écrite sur la vente ELLE-MÊME, pas seulement sur l'entrée
    // d'outbox : celle-ci disparaît à l'acquittement, et le guichet doit
    // pouvoir lire des mois plus tard pourquoi cet encaissement n'est jamais
    // arrivé dans les livres.
    await _dao.markSaleFailed(saleId, reason);
    return OutboxDispatchResult.failed(reason);
  }

  /// Nomme la cause, en préférant le **code machine** à la phrase.
  ///
  /// Le message du serveur est rédigé pour un humain et se reformule ; le
  /// `detailCode` est une valeur de fil. Sans lui, les trois causes du 422 se
  /// ressemblaient toutes, et l'écran ne pouvait offrir qu'un « contactez le
  /// support » sur de l'argent déjà encaissé.
  String _reasonOf(DioException e, int? status) {
    final detailCode = ApiErrorParser.detailCodeOf(e.response);
    if (detailCode != null) {
      final serverMessage = ApiErrorParser.serverMessageOf(e.response);
      return serverMessage == null
          ? detailCode
          : '$detailCode — $serverMessage';
    }
    final where = status != null ? 'HTTP $status' : 'réseau';
    final detail =
        ApiErrorParser.serverMessageOf(e.response) ??
        e.message ??
        e.error?.toString();
    return detail == null || detail.isEmpty ? where : '$where — $detail';
  }
}
