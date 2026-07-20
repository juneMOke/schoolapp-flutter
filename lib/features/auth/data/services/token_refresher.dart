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
      // Distinguer un refresh **définitivement rejeté** (rejeu détecté / refresh
      // expiré → 401/403) d'un **échec transitoire** (réseau, timeout, serveur
      // momentanément injoignable). Ne détruire la session QUE dans le 1er cas :
      // sinon un simple blip réseau éjecterait un utilisateur au refresh valide.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // Refus définitif du refresh → wipe. La fenêtre offline (m4) n'est
        // brûlée QUE si le rejet vient bien de NOTRE API (corps d'erreur JSON
        // structuré) : un portail captif / proxy Wi-Fi sans backhaul répond
        // souvent 401/403 en HTML — brûler là-dessus enverrait l'agent en zone
        // blanche (login offline refusé) sur un simple incident réseau, soit
        // exactement ce que l'amendement m4 doit empêcher.
        final apiShaped = e.response?.data is Map;
        await _sessionManager.wipeSession(revokeOfflineWindow: apiShaped);
        _revocationBus?.notifyRevoked();
      }
      return null;
    } catch (_) {
      // Erreur non-réseau inattendue (ex. parsing) : ne pas wiper — on retente
      // au prochain 401. La requête d'origine échouera, la session survit.
      return null;
    }
  }
}
