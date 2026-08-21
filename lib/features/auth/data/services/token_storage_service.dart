import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/data/session_permissions.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

/// Persistance des **secrets** de session dans le secure storage (Keystore).
///
/// ADR-010 : le refresh token vit ici (jamais en base) — il doit survivre à un
/// wipe de session. L'access token et les bornes d'expiration l'accompagnent.
/// L'état durable non secret (mode dégradé, ancre serveur, `userVersion`) vit,
/// lui, dans `auth_local` (SQLCipher).
class TokenStorageService {
  final FlutterSecureStorage _storage;
  final int Function() _now;

  TokenStorageService(this._storage, {int Function()? now})
    : _now = now ?? _systemNow;

  static int _systemNow() => DateTime.now().millisecondsSinceEpoch;

  /// Dernière session lue, et l'instant où elle l'a été.
  ///
  /// ## Pourquoi mémoriser une lecture de secure storage
  ///
  /// [readAuthSession] enchaîne treize `read()`, chacun un aller-retour
  /// MethodChannel **et** un déchiffrement Keystore. Un tic de battement qui a
  /// du travail prêt la paie quatre fois : la sonde de crédentiels, le
  /// ré-authentificateur, la garde propre du moteur, puis le refresh — soit
  /// une cinquantaine de déchiffrements toutes les 45 secondes, sur une
  /// tablette d'école. Le coût préexistait à chaque cycle ; le battement en a
  /// fait une cadence.
  ///
  /// ## Pourquoi ICI et pas dans le manager
  ///
  /// Toutes les écritures de ces clés passent par cette classe —
  /// [saveAuthSession], [updateTokens], [clearAuthSession] — et par elle seule
  /// (vérifié : aucune autre référence aux clés de session hors
  /// `AppConstants`). L'invalidation est donc **prouvablement complète**, ce
  /// qu'un mémo posé un cran plus haut ne pourrait pas garantir. C'est
  /// l'invalidation, et non le délai, qui porte la correction : un mint qui
  /// vient de réécrire l'access DOIT être vu par la garde du moteur, un
  /// dixième de seconde plus tard.
  ///
  /// Le délai n'est qu'un plafond de dégâts, au cas où une écriture
  /// apparaîtrait un jour ailleurs : il borne la péremption à quelques
  /// secondes au lieu de la vie du processus.
  AuthSession? _memo;
  bool _memoValid = false;
  int _memoAtMs = 0;

  /// Assez long pour couvrir les quatre lectures d'un même tic (elles
  /// s'enchaînent sans réseau entre elles), assez court pour qu'une péremption
  /// imprévue se résorbe seule.
  static const int _memoTtlMs = 3000;

  /// Oublie la session mémorisée. Appelée par **chaque** écriture de ces clés.
  void _invalidateMemo() {
    _memo = null;
    _memoValid = false;
  }

  Future<void> saveAuthSession(AuthSession session) async {
    _invalidateMemo();
    await Future.wait(<Future<void>>[
      _storage.write(
        key: AppConstants.accessTokenKey,
        value: session.accessToken,
      ),
      _storage.write(key: AppConstants.tokenTypeKey, value: session.tokenType),
      _storage.write(
        key: AppConstants.expiresInKey,
        value: session.expiresIn.toString(),
      ),
      _writeOrDelete(AppConstants.refreshTokenKey, session.refreshToken),
      _writeOrDelete(
        AppConstants.accessExpiresAtKey,
        session.accessExpiresAt?.toString(),
      ),
      _writeOrDelete(
        AppConstants.refreshExpiresAtKey,
        session.refreshExpiresAt?.toString(),
      ),
      _writeOrDelete(AppConstants.userIdKey, session.user.id),
      _storage.write(key: AppConstants.userEmailKey, value: session.user.email),
      _storage.write(
        key: AppConstants.userFirstNameKey,
        value: session.user.firstName,
      ),
      _storage.write(
        key: AppConstants.userLastNameKey,
        value: session.user.lastName,
      ),
      _storage.write(key: AppConstants.userRoleKey, value: session.user.role),
      _storage.write(
        key: AppConstants.userSchoolIdKey,
        value: session.user.schoolId,
      ),
      // Ensemble inconnu → on n'écrit rien et on efface : la clé absente est
      // précisément la façon dont « jamais renseigné » se relit.
      _writeOrDelete(
        AppConstants.userPermissionsKey,
        session.permissions == null
            ? null
            : SessionPermissions.encode(session.permissions!),
      ),
    ]);
  }

  /// Réécrit les jetons + bornes après un refresh (§7.2), sans toucher le
  /// profil utilisateur déjà stocké — les permissions font exception, cf. plus
  /// bas.
  ///
  /// Le refresh token n'est réécrit que s'il est **fourni** : un backend à
  /// refresh **non rotatif** ne renvoie qu'un nouvel access token → on préserve
  /// le refresh token existant plutôt que de l'effacer (sinon le refresh suivant
  /// serait impossible). Idem pour la borne d'expiration du refresh.
  Future<void> updateTokens(AuthSession session) async {
    _invalidateMemo();
    await Future.wait(<Future<void>>[
      _storage.write(
        key: AppConstants.accessTokenKey,
        value: session.accessToken,
      ),
      _storage.write(key: AppConstants.tokenTypeKey, value: session.tokenType),
      _storage.write(
        key: AppConstants.expiresInKey,
        value: session.expiresIn.toString(),
      ),
      _writeIfPresent(AppConstants.refreshTokenKey, session.refreshToken),
      _writeIfPresent(
        AppConstants.accessExpiresAtKey,
        session.accessExpiresAt?.toString(),
      ),
      _writeIfPresent(
        AppConstants.refreshExpiresAtKey,
        session.refreshExpiresAt?.toString(),
      ),
      // Un ensemble COMMUNIQUÉ est réécrit sans condition, vide compris :
      // le refresh est le seul moment où un retrait de droits se matérialise,
      // et préserver l'ancien laisserait un compte dépouillé afficher ses
      // modules jusqu'à la prochaine reconnexion complète.
      //
      // Un ensemble ABSENT de la réponse (`null`) ne dit rien et ne doit rien
      // écraser : un backend qui ne connaît pas encore ADR-014 dépouillerait
      // sinon l'agent à chaque refresh, y compris hors ligne.
      _writeIfPresent(
        AppConstants.userPermissionsKey,
        session.permissions == null
            ? null
            : SessionPermissions.encode(session.permissions!),
      ),
    ]);
  }

  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  // ── Consigne du refresh token (V1.1) ────────────────────────────────────────
  // Slot UNIQUE, hors du périmètre de [clearAuthSession] : la consigne survit
  // au wipe de session ordinaire. Sa clé de sortie est le mot de passe du
  // compte (vérificateur local) — jamais une simple présence sur la tablette.

  Future<void> parkRefreshToken({
    required String uid,
    required String refreshToken,
  }) async {
    await Future.wait(<Future<void>>[
      _storage.write(
        key: AppConstants.parkedRefreshTokenKey,
        value: refreshToken,
      ),
      _storage.write(key: AppConstants.parkedRefreshUidKey, value: uid),
    ]);
  }

  Future<ParkedRefreshToken?> readParkedRefresh() async {
    final token = await _storage.read(key: AppConstants.parkedRefreshTokenKey);
    final uid = await _storage.read(key: AppConstants.parkedRefreshUidKey);
    if (token == null || token.isEmpty || uid == null || uid.isEmpty) {
      return null;
    }
    return ParkedRefreshToken(uid: uid, refreshToken: token);
  }

  Future<void> clearParkedRefresh() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: AppConstants.parkedRefreshTokenKey),
      _storage.delete(key: AppConstants.parkedRefreshUidKey),
    ]);
  }

  /// La session courante, **mémorisée** entre deux écritures (cf. [_memo]).
  ///
  /// L'absence de session est mémorisée comme le reste : c'est même le cas le
  /// plus fréquent du chemin froid — hors ligne, déconnecté — et celui où
  /// treize allers-retours pour rien coûtent le plus cher.
  Future<AuthSession?> readAuthSession() async {
    if (_memoValid && _now() - _memoAtMs < _memoTtlMs) return _memo;

    final session = await _readAuthSessionFromStorage();
    _memo = session;
    _memoValid = true;
    _memoAtMs = _now();
    return session;
  }

  Future<AuthSession?> _readAuthSessionFromStorage() async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    // Sans access, il n'y a pas de session à composer : les douze autres
    // lectures seraient payées pour rien.
    if (accessToken == null) return null;

    // Lues ENSEMBLE : chacune est un aller-retour MethodChannel, et rien ne les
    // ordonne entre elles. Sérialisées, elles additionnaient douze latences là
    // où une seule suffit.
    final values = await Future.wait(<Future<String?>>[
      _storage.read(key: AppConstants.tokenTypeKey),
      _storage.read(key: AppConstants.expiresInKey),
      _storage.read(key: AppConstants.refreshTokenKey),
      _storage.read(key: AppConstants.accessExpiresAtKey),
      _storage.read(key: AppConstants.refreshExpiresAtKey),
      _storage.read(key: AppConstants.userIdKey),
      _storage.read(key: AppConstants.userEmailKey),
      _storage.read(key: AppConstants.userFirstNameKey),
      _storage.read(key: AppConstants.userLastNameKey),
      _storage.read(key: AppConstants.userRoleKey),
      _storage.read(key: AppConstants.userSchoolIdKey),
      _storage.read(key: AppConstants.userPermissionsKey),
    ]);

    final tokenType = values[0] ?? 'Bearer';
    final expiresInStr = values[1] ?? '0';
    final refreshToken = values[2];
    final accessExpiresAt = values[3];
    final refreshExpiresAt = values[4];
    final userId = values[5] ?? '';
    final userEmail = values[6] ?? '';
    final userFirstName = values[7] ?? '';
    final userLastName = values[8] ?? '';
    final userRole = values[9] ?? '';
    final userSchoolId = values[10] ?? '';
    final permissions = values[11];

    return AuthSession(
      accessToken: accessToken,
      tokenType: tokenType,
      expiresIn: int.tryParse(expiresInStr) ?? 0,
      refreshToken: refreshToken,
      accessExpiresAt: int.tryParse(accessExpiresAt ?? ''),
      refreshExpiresAt: int.tryParse(refreshExpiresAt ?? ''),
      permissions: SessionPermissions.decodeOrNull(permissions),
      user: AuthenticatedUser(
        id: userId,
        email: userEmail,
        firstName: userFirstName,
        lastName: userLastName,
        role: userRole,
        schoolId: userSchoolId,
      ),
    );
  }

  Future<void> clearAuthSession() async {
    _invalidateMemo();
    await Future.wait(<Future<void>>[
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.tokenTypeKey),
      _storage.delete(key: AppConstants.expiresInKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
      _storage.delete(key: AppConstants.accessExpiresAtKey),
      _storage.delete(key: AppConstants.refreshExpiresAtKey),
      _storage.delete(key: AppConstants.userIdKey),
      _storage.delete(key: AppConstants.userEmailKey),
      _storage.delete(key: AppConstants.userFirstNameKey),
      _storage.delete(key: AppConstants.userLastNameKey),
      _storage.delete(key: AppConstants.userRoleKey),
      _storage.delete(key: AppConstants.userSchoolIdKey),
      _storage.delete(key: AppConstants.userPermissionsKey),
    ]);
  }

  Future<void> _writeOrDelete(String key, String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }

  /// Écrit la valeur si fournie ; **ne supprime pas** si absente (préserve
  /// l'existant — refresh non rotatif).
  Future<void> _writeIfPresent(String key, String? value) {
    if (value == null || value.isEmpty) return Future<void>.value();
    return _storage.write(key: key, value: value);
  }
}

/// Refresh token consigné : le jeton + l'uid de son propriétaire.
class ParkedRefreshToken {
  final String uid;
  final String refreshToken;

  const ParkedRefreshToken({required this.uid, required this.refreshToken});
}
