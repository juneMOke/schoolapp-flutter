import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/data/models/login_response_model.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/session_revocation_bus.dart';

/// Rotation du refresh token (ADR-010 §7.2) avec **single-flight** : plusieurs
/// 401 concurrents ne déclenchent qu'un seul appel `/auth/refresh`.
///
/// Utilise un `Dio` **nu** (sans intercepteur d'auth/refresh) pour éviter toute
/// récursion. En cas d'échec (rejeu détecté / refresh expiré → 401), wipe la
/// session et publie sur le bus (l'`AuthBloc` repasse `unauthenticated`).
class TokenRefresher {
  final Dio _bareDio;
  final TokenStorageService _tokenStorage;
  final AuthSessionManager _sessionManager;
  final SessionRevocationBus? _revocationBus;
  final int Function() _now;

  Future<String?>? _inFlight;

  TokenRefresher({
    required Dio bareDio,
    required TokenStorageService tokenStorage,
    required AuthSessionManager sessionManager,
    SessionRevocationBus? revocationBus,
    int Function()? now,
  }) : _bareDio = bareDio,
       _tokenStorage = tokenStorage,
       _sessionManager = sessionManager,
       _revocationBus = revocationBus,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Renvoie un nouvel access token, ou `null` si le refresh échoue. Coalesce
  /// les appels concurrents.
  Future<String?> refresh() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _doRefresh();
    _inFlight = future;
    // Réinitialise le verrou une fois l'appel terminé (succès comme échec).
    future.whenComplete(() {
      _inFlight = null;
    });
    return future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _bareDio.post<Map<String, dynamic>>(
        AppConstants.refreshEndpoint,
        options: Options(headers: {'X-Refresh-Token': refreshToken}),
      );
      final data = response.data;
      if (data == null) return null;
      final model = LoginResponseModel.fromJson(data);
      final session = model.toAuthSession(nowMs: _now());
      await _sessionManager.applyRefresh(session);
      return session.accessToken;
    } on DioException catch (e) {
      // Distinguer un refresh **définitivement rejeté** d'un **échec
      // transitoire** (réseau, timeout, proxy, serveur momentanément
      // injoignable). Ne détruire la session QUE dans le 1er cas : sinon un
      // simple blip réseau éjecterait un utilisateur au refresh parfaitement
      // valide, depuis n'importe quel écran.
      //
      // **Seul le 401 est un verdict du contrat** : `/auth/refresh` ne déclare
      // que 200/400/401 (openApi). Un 403 sur cette route ne dit RIEN de la
      // validité du jeton — il dit que la requête n'a pas atteint le
      // contrôleur (chaîne de sécurité mal ouverte, ingress, WAF, portail
      // Wi-Fi). Le traiter comme un refus définitif détruisait la session ET
      // brûlait la fenêtre offline sur un incident d'infrastructure.
      final status = e.response?.statusCode;
      if (status == 401) {
        // Refus définitif du refresh → wipe. La fenêtre offline (m4) n'est
        // brûlée QUE si le rejet porte la signature de NOTRE API (corps JSON
        // structuré avec un `message`, cf. ApiErrorResponse) : un portail
        // captif répond souvent 401 en HTML — ou en JSON générique — et brûler
        // là-dessus enverrait l'agent en zone blanche (login offline refusé),
        // soit exactement ce que l'amendement m4 doit empêcher.
        await _sessionManager.wipeSession(
          revokeOfflineWindow: _looksLikeApiRejection(e.response?.data),
        );
        _revocationBus?.notifyRevoked();
      }
      return null;
    } catch (_) {
      // Erreur non-réseau inattendue (ex. parsing) : ne pas wiper — on retente
      // au prochain 401. La requête d'origine échouera, la session survit.
      return null;
    }
  }

  /// Vrai si le corps d'erreur porte la signature de **notre** API
  /// (`ApiErrorResponse` = `{timestamp,status,error,message}`) et non celle
  /// d'une couche intermédiaire.
  ///
  /// Le simple `data is Map` ne discrimine pas : le corps `/error` par défaut
  /// de Spring est lui aussi une Map (`{timestamp,status,error,path}`), tout
  /// comme la page JSON d'un proxy. On exige donc un `message` non vide **et**
  /// l'absence de `path` — la clé que le gestionnaire d'erreurs par défaut
  /// ajoute et que notre contrat n'a pas. Dans le doute : pas de brûlure (la
  /// fenêtre offline est irrécupérable, la session non).
  bool _looksLikeApiRejection(Object? data) {
    if (data is! Map) return false;
    if (data.containsKey('path')) return false;
    final message = data['message'];
    return message is String && message.trim().isNotEmpty;
  }
}
