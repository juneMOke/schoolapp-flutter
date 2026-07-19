import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/revocation_evaluator.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/domain/session_revocation_bus.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_models.dart';
import 'package:school_app_flutter/features/auth/data/services/password_verifier_service.dart';
import 'package:school_app_flutter/features/auth/data/services/token_storage_service.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session.dart';
import 'package:school_app_flutter/features/auth/domain/entities/auth_session_snapshot.dart';
import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';
import 'package:school_app_flutter/features/auth/domain/session_freshness.dart';

/// Horloge murale injectable (epoch ms).
typedef WallClock = int Function();

int _systemWallClock() => DateTime.now().millisecondsSinceEpoch;

/// Cœur de la session offline (ADR-010). Centralise `auth_local` + secure
/// storage + vérificateur, et porte la politique de fraîcheur, de révocation et
/// de wipe. Consommé par le repository (login), le bloc (fraîcheur) et le
/// guardian de révocation (boucle de synchro).
///
/// **Invariants money-grade :**
/// - le wipe efface la session, **jamais** l'outbox ni `auth_local_user` (D-11) ;
/// - `last_server_seen_at` n'est avancé **que** sur un contact serveur réel
///   (interceptor) — la dégradation se mesure `deviceNow − ancre`, ancre et
///   `now` sur la **même** horloge (device) pour éviter un faux « saut horloge » ;
/// - seul un contact serveur peut *améliorer* le mode (D-08).
class AuthSessionManager implements RevocationEvaluator {
  final TokenStorageService _tokenStorage;
  final AuthLocalDao _authLocalDao;
  final PasswordVerifierService _verifier;
  final SessionRevocationBus? _revocationBus;
  final CurrentUserContext? _currentUser;
  final WallClock _now;

  /// Dernier `userVersion` **observé** sur une réponse serveur (header
  /// `X-User-Version`). En mémoire : re-observé au prochain contact si perdu.
  int? _observedUserVersion;

  /// Triche horloge détectée (D-10) : force READ_ONLY jusqu'au prochain contact.
  bool _clockTampered = false;

  AuthSessionManager({
    required TokenStorageService tokenStorage,
    required AuthLocalDao authLocalDao,
    required PasswordVerifierService verifier,
    SessionRevocationBus? revocationBus,
    CurrentUserContext? currentUser,
    WallClock now = _systemWallClock,
  }) : _tokenStorage = tokenStorage,
       _authLocalDao = authLocalDao,
       _verifier = verifier,
       _revocationBus = revocationBus,
       _currentUser = currentUser,
       _now = now;

  /// TTL de refresh par défaut si le serveur ne fournit pas `refreshExpiresIn`
  /// (borne offline externe, D-07). 90 jours.
  static const int _defaultRefreshTtlMs = 90 * 24 * 60 * 60 * 1000;

  // ── Persistance du login online (D-01/D-02) ──────────────────────────────────

  /// Après un login online réussi : calcule et stocke le vérificateur Argon2id,
  /// (ré)écrit `auth_local_user` et ouvre la session locale. Best-effort : sans
  /// `uid` (backend hérité) on ne peut pas ancrer la session offline → on saute.
  Future<void> persistOnlineLogin(AuthSession session, String password) async {
    final uid = session.user.id;
    if (uid.isEmpty) {
      return; // pas d'uid ⇒ pas de login offline possible (D-05).
    }

    final nowMs = _now();
    final salt = _verifier.generateSalt();
    final verifier = await _verifier.computeVerifier(
      password: password,
      saltBase64: salt,
    );

    final existing = await _authLocalDao.getUser(uid);
    await _authLocalDao.upsertUser(
      AuthLocalUserRecord(
        userId: uid,
        email: session.user.email,
        firstName: session.user.firstName,
        lastName: session.user.lastName,
        role: session.user.role,
        schoolId: session.user.schoolId,
        passwordVerifier: verifier,
        verifierSalt: salt,
        userVersion: session.userVersion,
        firstOnlineLoginAt: existing?.firstOnlineLoginAt ?? nowMs,
        lastServerSeenAt: nowMs,
        sessionStartedAt: nowMs,
      ),
    );
    await _authLocalDao.upsertSession(
      AuthLocalSessionRecord(
        userId: uid,
        degradedMode: SessionMode.normal,
        refreshExpiresAt:
            session.refreshExpiresAt ?? nowMs + _defaultRefreshTtlMs,
        lastEvaluatedAt: nowMs,
      ),
    );
    _observedUserVersion = session.userVersion;
    _clockTampered = false;
    _currentUser?.set(uid); // estampillage authorId au write-time (D-05)
  }

  /// Amorce l'uid courant depuis une session restaurée (token store), au
  /// démarrage. Couvre le cold-start où le token porte une session valide mais
  /// où `auth_local` n'a pas (encore) de ligne de session (ex. montée de
  /// version) : sans cet amorçage, une écriture offline partirait avec un
  /// `authorId` null → 403 terminal (D-05). `uid` vide = pas d'amorçage
  /// (session héritée sans claim `uid`).
  void primeCurrentUser(String? uid) => _currentUser?.set(uid);

  // ── Login offline (D-01/D-02) ────────────────────────────────────────────────

  Future<bool> hasLocalUser(String email) async {
    return (await _authLocalDao.getUserByEmail(email)) != null;
  }

  /// Login hors ligne : gate D-01 (jamais vu → refus) + vérification Argon2id +
  /// mode selon fraîcheur. Refuse si le refresh est expiré (reconnexion online).
  Future<Either<Failure, AuthSessionSnapshot>> loginOffline({
    required String email,
    required String password,
  }) async {
    final user = await _authLocalDao.getUserByEmail(email);
    if (user == null) {
      // D-01 : compte jamais connecté online sur CE device.
      return const Left(
        InvalidCredentialsFailure('Aucune session locale pour ce compte'),
      );
    }

    final ok = await _verifier.verify(
      password: password,
      saltBase64: user.verifierSalt,
      expectedVerifier: user.passwordVerifier,
    );
    if (!ok) {
      return const Left(InvalidCredentialsFailure('Mot de passe incorrect'));
    }

    final sessionRow = await _authLocalDao.getSession();
    // Pas de session active (ex. après un logout explicite qui a wipé la ligne
    // de session et le refresh token) → on **refuse** le login offline plutôt
    // que de fabriquer une nouvelle fenêtre de 90 j sans aucun contact serveur
    // (sinon logout+login offline en boucle ré-armerait le TTL — le temps ne
    // doit pouvoir que dégrader, D-08). Reconnexion online requise.
    if (sessionRow == null) {
      return const Left(
        AuthFailure('Reconnexion en ligne requise sur ce compte'),
      );
    }

    final nowMs = _now();
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: user.lastServerSeenAt,
      refreshExpiresAt: sessionRow.refreshExpiresAt,
      nowMs: nowMs,
    );
    if (eval.refreshExpired) {
      return const Left(
        AuthFailure('Session expirée — reconnexion en ligne requise'),
      );
    }

    final mode = _clockTampered ? SessionMode.readOnly : eval.mode;
    await _authLocalDao.markSessionStarted(user.userId, at: nowMs);
    await _authLocalDao.upsertSession(
      AuthLocalSessionRecord(
        userId: user.userId,
        degradedMode: mode,
        refreshExpiresAt: sessionRow.refreshExpiresAt,
        lastEvaluatedAt: nowMs,
      ),
    );

    final stored = await _tokenStorage.readAuthSession();
    final session =
        stored?.copyWith(userVersion: user.userVersion) ??
        AuthSession(
          accessToken: '',
          tokenType: 'Bearer',
          expiresIn: 0,
          userVersion: user.userVersion,
          user: _userFromRecord(user),
        );

    _currentUser?.set(
      user.userId,
    ); // estampillage authorId au write-time (D-05)
    return Right(
      AuthSessionSnapshot(session: session, mode: mode, isOffline: true),
    );
  }

  // ── Fraîcheur périodique (D-08) ──────────────────────────────────────────────

  /// Recalcule le mode sans réseau. Retourne `null` s'il n'y a pas de session
  /// active. `refreshExpired` remonté via [SessionEvaluation.refreshExpired].
  Future<SessionEvaluation?> evaluateFreshness() async {
    final user = await _authLocalDao.getSessionUser();
    final sessionRow = await _authLocalDao.getSession();
    if (user == null || sessionRow == null) return null;

    // Restaure l'uid courant (ex. après redémarrage : la session existe mais le
    // contexte mémoire est vide) — nécessaire pour estampiller authorId (D-05).
    _currentUser?.set(user.userId);

    final nowMs = _now();
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: user.lastServerSeenAt,
      refreshExpiresAt: sessionRow.refreshExpiresAt,
      nowMs: nowMs,
    );
    if (eval.clockTampered) _clockTampered = true;
    final mode = _clockTampered ? SessionMode.readOnly : eval.mode;
    await _authLocalDao.updateDegradedMode(mode, at: nowMs);
    return SessionEvaluation(
      refreshExpired: eval.refreshExpired,
      clockTampered: _clockTampered,
      mode: mode,
    );
  }

  // ── Refresh rotatif (D-07/§7.2) ──────────────────────────────────────────────

  /// Applique une paire fraîche issue d'un refresh réussi : réécrit les jetons
  /// (secure storage) et met à jour l'ancre temporelle + la borne refresh. Un
  /// refresh réussi **est** un contact serveur récent.
  ///
  /// ⚠ N'avance **PAS** la colonne `user_version` en base : le refresh est un
  /// simple renouvellement (sans ré-authentification), et le régime doux (D-11)
  /// laisse le refresh aboutir *après* un reset password (`userVersion++` sans
  /// denylist). On se contente donc d'**observer** la version serveur ; le
  /// guardian comparera `observed > DB` et wipera si divergence — sinon une
  /// révocation matérialisée via le chemin refresh serait silencieusement
  /// blanchie (contournement de révocation).
  Future<void> applyRefresh(AuthSession session) async {
    await _tokenStorage.updateTokens(session);
    final user = await _authLocalDao.getSessionUser();
    if (user == null) return;
    final nowMs = _now();
    await _authLocalDao.updateLastServerSeen(user.userId, nowMs);
    _observedUserVersion = session.userVersion;

    final sessionRow = await _authLocalDao.getSession();
    if (sessionRow != null && session.refreshExpiresAt != null) {
      await _authLocalDao.upsertSession(
        AuthLocalSessionRecord(
          userId: user.userId,
          degradedMode: sessionRow.degradedMode,
          refreshExpiresAt: session.refreshExpiresAt!,
          lastEvaluatedAt: nowMs,
        ),
      );
    }
  }

  // ── Contact serveur & révocation (D-07/D-09) ─────────────────────────────────

  /// Enregistre un contact serveur réussi (interceptor) : réancre la fraîcheur
  /// et mémorise le `userVersion` observé. **N'exécute jamais** le wipe (D-11 :
  /// observer, pas décideur).
  ///
  /// ⚠ L'ancre est posée sur l'horloge **device** (`_now()`), PAS sur
  /// `serverTimeMs`. La dégradation se mesure `deviceNow − ancre` : mélanger une
  /// ancre en temps serveur et un `now` device produirait un `elapsed` faussé
  /// (faux « saut horloge » READ_ONLY dès que le device est désynchronisé du
  /// serveur, même en ligne). Anchor device ⇒ mesure cohérente ; l'ancre n'étant
  /// avancée QUE sur un contact réel, le device ne peut pas se ré-autoriser seul
  /// (D-08). `serverTimeMs` reste capté (diagnostic / détection de dérive future).
  Future<void> recordServerContact({
    required int? observedUserVersion,
    required int? serverTimeMs,
  }) async {
    final user = await _authLocalDao.getSessionUser();
    if (user == null) return;
    // Un contact serveur authentique a eu lieu → réancre + lève le verrou de
    // triche (seul un contact serveur peut améliorer le mode, D-08).
    await _authLocalDao.updateLastServerSeen(user.userId, _now());
    _clockTampered = false;
    if (observedUserVersion != null) {
      _observedUserVersion = observedUserVersion;
    }
  }

  /// Décide de la révocation (guardian, **après** le flush, D-11). Vrai si le
  /// `userVersion` observé diverge du local → wipe de session (jamais l'outbox),
  /// puis publie sur le bus (l'`AuthBloc` repasse à `unauthenticated`).
  @override
  Future<bool> evaluateRevocation() async {
    final observed = _observedUserVersion;
    if (observed == null) return false;
    final user = await _authLocalDao.getSessionUser();
    if (user == null) return false;
    // `userVersion` est monotone croissant côté serveur : seule une version
    // observée **strictement supérieure** au baseline local signale une
    // révocation. Comparer avec `>` (et non `!=`) neutralise une réponse en vol
    // périmée (version antérieure) arrivant après un re-login — sinon faux wipe.
    if (observed > user.userVersion) {
      await wipeSession();
      _revocationBus?.notifyRevoked();
      return true;
    }
    return false;
  }

  // ── Wipe (D-09/D-11) ─────────────────────────────────────────────────────────

  /// Wipe de session : jetons (secure storage) + `auth_local_session` +
  /// `session_started_at`. **Jamais** l'outbox, **jamais** `auth_local_user`.
  Future<void> wipeSession() async {
    final user = await _authLocalDao.getSessionUser();
    await _tokenStorage.clearAuthSession();
    if (user != null) {
      await _authLocalDao.wipeSession(user.userId);
    }
    _observedUserVersion = null;
    _currentUser?.clear();
  }

  AuthenticatedUser _userFromRecord(AuthLocalUserRecord r) => AuthenticatedUser(
    id: r.userId,
    email: r.email,
    firstName: r.firstName,
    lastName: r.lastName,
    role: r.role,
    schoolId: r.schoolId,
  );
}
