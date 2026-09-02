import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/exchange_rate_pull_models.dart';

/// Ce qu'un cycle de pull des taux rapporte.
///
/// [notModified] et une liste vide ne disent **pas** la même chose : l'un dit
/// « rien n'a changé », l'autre « cette école ne publie aucun taux ». Les
/// confondre viderait le cache d'un guichet sur un simple 304, et la bascule de
/// devise s'éteindrait sans qu'aucune écriture n'ait eu lieu.
class ExchangeRatePullResult {
  final List<ExchangeRatePullDto> points;

  /// L'empreinte du bundle, à renvoyer en `If-None-Match` au cycle suivant.
  final String? etag;

  final bool notModified;

  const ExchangeRatePullResult({
    this.points = const [],
    this.etag,
    this.notModified = false,
  });
}

/// Le bundle des taux, lu sur le flux de synchro.
///
/// **Dio direct, sans Retrofit**, et c'est un choix : la négociation
/// conditionnelle (`If-None-Match` en entrée, `ETag` en sortie, 304 traité comme
/// une réponse et non comme une panne) demande de toucher aux en-têtes des deux
/// côtés. Écrire l'appel à la main coûte vingt lignes et évite de tordre le
/// contrat pour plaire à un générateur.
class ExchangeRateRemoteDataSource {
  final Dio _dio;

  const ExchangeRateRemoteDataSource(this._dio);

  /// Les points du bundle, ou « rien de neuf ».
  ///
  /// Les points illisibles sont écartés en silence : une ligne mal formée ne
  /// doit pas emporter la série entière, donc la bascule de devise de tout le
  /// guichet.
  Future<ExchangeRatePullResult> fetch(
    Map<String, dynamic> extras, {
    String? etag,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        AppConstants.exchangeRatesSyncEndpoint,
        options: Options(
          extra: extras,
          headers: {if (etag != null && etag.isNotEmpty) 'If-None-Match': etag},
          // 304 est une RÉPONSE ici, pas une panne : sans cette tolérance, Dio
          // la lève, et un cycle « rien de neuf » se lirait comme un échec de
          // synchro sur l'écran de fraîcheur.
          validateStatus: (status) =>
              status != null && (status < 300 || status == 304),
        ),
      );
      if (response.statusCode == 304) {
        return ExchangeRatePullResult(
          etag: _etagOf(response) ?? etag,
          notModified: true,
        );
      }
      return ExchangeRatePullResult(
        points: _pointsOf(response.data),
        etag: _etagOf(response),
      );
    } on DioException catch (e) {
      // Selon la configuration du client, le 304 peut aussi arriver par ici.
      if (e.response?.statusCode == 304) {
        return ExchangeRatePullResult(
          etag: _etagOf(e.response!) ?? etag,
          notModified: true,
        );
      }
      rethrow;
    }
  }

  /// L'enveloppe du bundle : `{points, serverTime}`.
  ///
  /// ⚠️ **Une forme inconnue LÈVE, elle ne rend pas une série vide.** Les deux
  /// se ressemblent — zéro point — mais n'ont pas la même conséquence : une
  /// liste vide est une réponse complète (« cette école ne publie aucun taux »)
  /// et le cache se vide légitimement, tandis qu'une enveloppe non reconnue
  /// viderait le cache de toutes les écoles du parc sur un simple changement de
  /// forme, sans erreur et sans trace. Un cycle en échec, lui, se voit : le
  /// cache est conservé et la fraîcheur n'avance pas.
  static List<ExchangeRatePullDto> _pointsOf(Object? body) {
    if (body is! Map<String, dynamic> || body['points'] is! List) {
      throw const FormatException(
        'Bundle de taux illisible : `points[]` attendu dans l\'enveloppe.',
      );
    }
    return [
      for (final raw in body['points'] as List)
        ?ExchangeRatePullDto.tryFrom(raw),
    ];
  }

  /// Pose un point dans la série de l'école — l'écran de **direction**.
  ///
  /// ⚠️ **Le paramétrage ne peut pas rester local.** Le pull remplace la table
  /// en bloc : un taux écrit seulement sur la tablette disparaîtrait au premier
  /// cycle réussi, et la bascule de devise du guichet s'éteindrait sans qu'un
  /// mot soit dit. C'est le serveur qui publie le taux ; la tablette le relit
  /// ensuite comme n'importe quel poste.
  ///
  /// Gardé par `finance.grid.write`, que la comptabilité ne détient pas : un
  /// caissier qui poserait son propre taux fabriquerait sa propre marge.
  ///
  /// Le taux part en **décimal** — les micro-unités sont une convention locale,
  /// elles ne voyagent pas — et la tolérance en **pourcent**, pas en points de
  /// base.
  Future<void> publish(
    Map<String, dynamic> extras, {
    required String base,
    required String quote,
    required int rateMicros,
    int? divergenceBandBp,
    DateTime? effectiveFrom,
  }) async {
    await _dio.post<dynamic>(
      AppConstants.exchangeRatesEndpoint,
      options: Options(extra: extras),
      data: <String, dynamic>{
        'devisePivot': base,
        'deviseRecue': quote,
        'taux': rateMicros / ExchangeRate.scale,
        if (divergenceBandBp != null)
          'tolerancePourcent': divergenceBandBp / 100,
        // Omis vaut « maintenant » côté serveur, qui refuse le passé : lui
        // envoyer l'horloge de la tablette ferait rejeter une pose légitime dès
        // que celle-ci retarde de quelques secondes.
        if (effectiveFrom != null)
          'enVigueurDepuis': effectiveFrom.toUtc().toIso8601String(),
      },
    );
  }

  static String? _etagOf(Response<dynamic> response) =>
      response.headers.value('etag');
}
