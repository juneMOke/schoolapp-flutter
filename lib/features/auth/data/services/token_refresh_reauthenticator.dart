import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresher.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';

/// Implémentation de [SessionReauthenticator] adossée au [TokenRefresher].
///
/// Ne fait de réseau que si c'est nécessaire : un access encore valide est
/// accepté tel quel. Le mint passe par le single-flight du refresher — une
/// rafale d'appels concurrents ne produit qu'un seul `/auth/refresh`.
class TokenRefreshReauthenticator implements SessionReauthenticator {
  final TokenStorageService _tokenStorage;
  final TokenRefresher _refresher;
  final int Function() _now;

  TokenRefreshReauthenticator({
    required TokenStorageService tokenStorage,
    required TokenRefresher refresher,
    int Function()? now,
  }) : _tokenStorage = tokenStorage,
       _refresher = refresher,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Marge de sécurité : un access qui expire dans moins de 30 s serait périmé
  /// au milieu du flush qu'il est censé couvrir. On le renouvelle d'avance.
  static const int _expirySkewMs = 30 * 1000;

  @override
  Future<bool> ensureFreshAccess() async {
    try {
      final session = await _tokenStorage.readAuthSession();
      if (session != null && session.accessToken.isNotEmpty) {
        final expiresAt = session.accessExpiresAt;
        // Borne absente (backend qui ne la fournit pas) : on fait confiance au
        // jeton — l'interceptor de refresh rattrapera un éventuel 401.
        final stillFresh =
            expiresAt == null || _now() < expiresAt - _expirySkewMs;
        if (stillFresh) return true;
      }
      // Access absent ou (bientôt) périmé : minter une fois. `refresh()` rend
      // `null` sans effet de bord s'il n'y a aucun refresh token à présenter.
      return await _refresher.refresh() != null;
    } catch (_) {
      // Storage indisponible : ne pas lancer de trafic authentifié à l'aveugle.
      return false;
    }
  }
}
