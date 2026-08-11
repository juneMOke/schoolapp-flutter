import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/storage/shared_document_cache.dart';
import 'package:school_app_flutter/core/offline/revocation_evaluator.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
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
class AuthSessionManager
    implements
        RevocationEvaluator,
        SessionCredentialsProbe,
        OutboxAuthorDirectory {
  final TokenStorageService _tokenStorage;
  final AuthLocalDao _authLocalDao;
  final PasswordVerifierService _verifier;
  final SessionRevocationBus? _revocationBus;
  final CurrentUserContext? _currentUser;

  /// Ensemble effectif des permissions de la session (ADR-014 §4), tenu à
  /// jour aux MÊMES points que [_currentUser] : les consommateurs hors arbre
  /// de widgets — la boucle de synchronisation d'abord — n'ont pas d'autre
  /// source. Un point d'alimentation oublié se paierait en ressources
  /// sautées à tort, pas en droits accordés à tort.
  final CurrentPermissions? _currentPermissions;
  final WallClock _now;

  /// Purge des pièces déposées en clair par le partage système. Optionnel : sans
  /// lui, la fin de session se comporte exactement comme avant.
  final SharedDocumentCache? _sharedDocumentCache;

  /// Dernier `userVersion` **observé** sur une réponse serveur (header
  /// `X-User-Version`). En mémoire : re-observé au prochain contact si perdu.
  int? _observedUserVersion;

  /// Triche horloge détectée (D-10) : force READ_ONLY jusqu'au prochain contact.
  bool _clockTampered = false;

  /// Incrémenté à chaque [wipeSession] : permet à [applyRefresh] de détecter
  /// qu'un wipe est survenu pendant que le refresh était en vol et d'annuler
  /// la réécriture des jetons (anti-résurrection, revue adversariale).
  int _wipeGeneration = 0;

  AuthSessionManager({
    required TokenStorageService tokenStorage,
    required AuthLocalDao authLocalDao,
    required PasswordVerifierService verifier,
    SessionRevocationBus? revocationBus,
    CurrentUserContext? currentUser,
    CurrentPermissions? currentPermissions,
    SharedDocumentCache? sharedDocumentCache,
    WallClock now = _systemWallClock,
  }) : _tokenStorage = tokenStorage,
       _authLocalDao = authLocalDao,
       _verifier = verifier,
       _revocationBus = revocationBus,
       _currentUser = currentUser,
       _currentPermissions = currentPermissions,
       _sharedDocumentCache = sharedDocumentCache,
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

    final refreshExpiresAt =
        session.refreshExpiresAt ?? nowMs + _defaultRefreshTtlMs;
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
        refreshExpiresAt: refreshExpiresAt,
        // Copie durable des permissions (ADR-014 §4) : elle survit au logout
        // pour que le login offline suivant rouvre la session avec les droits
        // du dernier contact serveur, et non avec zéro droit.
        permissions: session.permissions,
      ),
    );
    await _authLocalDao.upsertSession(
      AuthLocalSessionRecord(
        userId: uid,
        degradedMode: SessionMode.normal,
        refreshExpiresAt: refreshExpiresAt,
        lastEvaluatedAt: nowMs,
      ),
    );
    _observedUserVersion = session.userVersion;
    _clockTampered = false;
    // estampillage authorId + schoolId au write-time (D-05)
    _currentUser?.set(uid, schoolId: session.user.schoolId);
    _currentPermissions?.set(session.permissions);

    // Des jetons frais rendent la consigne de CE compte obsolète. Celle d'un
    // AUTRE compte survit (slot partagé : elle attend son propriétaire).
    try {
      final parked = await _tokenStorage.readParkedRefresh();
      if (parked?.uid == uid) await _tokenStorage.clearParkedRefresh();
    } catch (_) {
      // Best-effort : une consigne périmée sera écrasée au prochain logout.
    }
  }

  /// Amorce l'uid courant depuis une session restaurée (token store), au
  /// démarrage. Couvre le cold-start où le token porte une session valide mais
  /// où `auth_local` n'a pas (encore) de ligne de session (ex. montée de
  /// version) : sans cet amorçage, une écriture offline partirait avec un
  /// `authorId` null → 403 terminal (D-05). `uid` vide = pas d'amorçage
  /// (session héritée sans claim `uid`).
  /// [permissions] amorce du même coup l'ensemble effectif : au cold-start,
  /// il vient de la session restaurée du token store — `null` le laisse
  /// inconnu plutôt que vide, la nuance décidant si la synchro filtre ou non.
  void primeCurrentUser(
    String? uid, {
    String? schoolId,
    List<String>? permissions,
  }) {
    _currentUser?.set(uid, schoolId: schoolId);
    _currentPermissions?.set(permissions);
  }

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

    // Borne offline PAR UTILISATEUR (amendement m4) : posée au dernier contact
    // online de CE compte, elle survit au logout — fermer la session ne brûle
    // pas la fenêtre de travail offline. C'est la SEULE source de vérité : les
    // trois écrivains (login online, refresh, migration v10) posent toujours
    // borne user et borne session ensemble — un repli sur la ligne de session
    // serait du code mort en régime nominal, et un trou de révocation en crash
    // partiel (revue adversariale). Aucune borne (compte jamais migré sans
    // session active, ou fenêtre brûlée par une révocation D-09) → reconnexion
    // online exigée. Rien n'est ré-armé ici : ni la borne ni
    // `last_server_seen_at` ne sont avancées offline — le temps ne peut que
    // dégrader (règle d'or D-08).
    final bound = user.refreshExpiresAt;
    if (bound == null) {
      return const Left(
        AuthFailure('Reconnexion en ligne requise sur ce compte'),
      );
    }

    final nowMs = _now();
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: user.lastServerSeenAt,
      refreshExpiresAt: bound,
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
        refreshExpiresAt: bound,
        lastEvaluatedAt: nowMs,
      ),
    );

    // Identité : la session du token store n'est réutilisée QUE si elle
    // appartient à CE compte. Sinon (tablette partagée : les jetons résiduels
    // sont ceux d'un autre utilisateur), ils sont CONSIGNÉS sous LEUR uid
    // (leur propriétaire pourra resynchroniser à son prochain login) puis
    // purgés de l'actif — l'interceptor Authorization ne doit jamais émettre
    // sous l'identité d'autrui (D-05 : flush sous le JWT d'un autre → 403).
    final stored = await _tokenStorage.readAuthSession();
    final AuthSession session;
    if (stored != null && stored.user.id == user.userId) {
      // Les permissions d'une session ouverte HORS LIGNE viennent toujours de
      // la copie durable du compte (ADR-014 §4), jamais du secure storage : les
      // deux sont écrites au même contact serveur, mais seule la copie durable
      // survit à un logout — une seule source évite qu'elles divergent selon la
      // branche empruntée ici.
      var reused = stored.copyWith(
        userVersion: user.userVersion,
        permissions: user.permissions,
      );
      // État partiel (crash du `clearAuthSession` au logout, deletes non
      // ordonnés) : access présent mais refresh ABSENT alors que la consigne
      // du compte existe. Sans réinjection, le premier 401 n'aurait aucun
      // refresh à présenter → retour du poison d'outbox (revue F4). Le mot de
      // passe vient d'être vérifié : mêmes garanties que la déconsignation.
      final storedRefresh = stored.refreshToken;
      if (storedRefresh == null || storedRefresh.isEmpty) {
        final parked = await _tokenStorage.readParkedRefresh();
        if (parked != null && parked.uid == user.userId) {
          reused = reused.copyWith(refreshToken: parked.refreshToken);
          await _tokenStorage.saveAuthSession(reused);
          await _tokenStorage.clearParkedRefresh();
        }
      }
      session = reused;
    } else {
      if (stored != null) {
        final foreignRefresh = stored.refreshToken;
        final foreignUid = stored.user.id;
        if (foreignRefresh != null &&
            foreignRefresh.isNotEmpty &&
            foreignUid.isNotEmpty) {
          await _tokenStorage.parkRefreshToken(
            uid: foreignUid,
            refreshToken: foreignRefresh,
          );
        }
        await _tokenStorage.clearAuthSession();
      }

      // Consigne de CE compte (posée à son logout) ? Le mot de passe vient
      // d'être vérifié (Argon2id) → déconsigner : snapshot COMPLET réécrit en
      // storage (profil + refresh, access vide — le refresh interceptor
      // mintera au premier 401) → resynchronisation silencieuse au retour
      // réseau. Le profil est indispensable : sans `userId` en storage,
      // l'estampille `authUid` resterait vide et le filtre d'identité
      // ignorerait tous les contacts serveur de cette session.
      final parked = await _tokenStorage.readParkedRefresh();
      if (parked != null && parked.uid == user.userId) {
        session = AuthSession(
          accessToken: '',
          tokenType: 'Bearer',
          expiresIn: 0,
          refreshToken: parked.refreshToken,
          refreshExpiresAt: bound,
          userVersion: user.userVersion,
          permissions: user.permissions,
          user: _userFromRecord(user),
        );
        await _tokenStorage.saveAuthSession(session);
        await _tokenStorage.clearParkedRefresh();
      } else {
        session = AuthSession(
          accessToken: '',
          tokenType: 'Bearer',
          expiresIn: 0,
          userVersion: user.userVersion,
          permissions: user.permissions,
          user: _userFromRecord(user),
        );
      }
    }

    // estampillage authorId + schoolId au write-time (D-05)
    _currentUser?.set(user.userId, schoolId: user.schoolId);
    _currentPermissions?.set(user.permissions);
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

    // Restaure l'uid/schoolId courants (ex. après redémarrage : la session
    // existe mais le contexte mémoire est vide) — nécessaire pour estampiller
    // authorId (D-05) et scoper le référentiel par école.
    _currentUser?.set(user.userId, schoolId: user.schoolId);
    _currentPermissions?.set(user.permissions);

    final nowMs = _now();
    final eval = SessionFreshness.evaluate(
      lastServerSeenAt: user.lastServerSeenAt,
      refreshExpiresAt: sessionRow.refreshExpiresAt,
      nowMs: nowMs,
    );
    if (eval.clockTampered) _clockTampered = true;
    final mode = _clockTampered ? SessionMode.readOnly : eval.mode;
    await _authLocalDao.updateDegradedMode(mode, at: nowMs);
    // Un contact serveur DEPUIS l'ouverture de la session courante : une
    // session ouverte offline qui a resynchronisé en silence (déconsignation →
    // refresh → flush) n'est plus « hors ligne » — le bandeau peut tomber.
    final sessionStart = user.sessionStartedAt;
    final hadServerContact =
        sessionStart != null && user.lastServerSeenAt >= sessionStart;
    return SessionEvaluation(
      refreshExpired: eval.refreshExpired,
      clockTampered: _clockTampered,
      mode: mode,
      hadServerContact: hadServerContact,
    );
  }

  /// Permissions du compte de la session courante (ADR-014 §4), lues sur la
  /// copie durable — la seule que le refresh tient à jour. `null` s'il n'y a
  /// pas de session locale : rien à dire, l'appelant garde ce qu'il a (ne PAS
  /// confondre avec l'ensemble vide, qui est un retrait de droits réel).
  ///
  /// Volontairement séparée de [evaluateFreshness] : la dégradation temporelle
  /// et l'ensemble des droits sont deux axes sans rapport.
  Future<List<String>?> currentPermissions() async =>
      (await _authLocalDao.getSessionUser())?.permissions;

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
    // Garde anti-résurrection (revue adversariale) : si la session a été wipée
    // pendant que le refresh était en vol (révocation D-09, logout), ne RIEN
    // réécrire — sinon des jetons frais réapparaissent en secure storage après
    // le wipe : au prochain démarrage le révoqué serait `authenticated`, et la
    // ligne de session ayant disparu, le guardian serait désarmé
    // (`getSessionUser() == null` court-circuite `evaluateRevocation`).
    final generation = _wipeGeneration;
    final user = await _authLocalDao.getSessionUser();
    if (user == null) return;

    // Filtre d'identité (même discipline que `recordServerContact`) : la garde
    // anti-résurrection ci-dessus ne couvre que la fenêtre lecture→écriture,
    // jamais le VOL RÉSEAU du refresh. Sur tablette partagée, A se déconnecte,
    // B ouvre sa session, et la réponse tardive de A arrive : sans ce test elle
    // écrirait les jetons de A dans le slot actif de B, réécrirait durablement
    // les permissions de B, et poserait le `userVersion` de A — que le guardian
    // comparerait au baseline de B, brûlant sa fenêtre offline. Ensuite chaque
    // écriture de B partirait sous le Bearer de A : 403 par item, classé
    // TERMINAL, encaissements perdus.
    //
    // On abandonne sans rien nettoyer : la session de B est saine, ce sont les
    // jetons de A qui n'ont plus de destinataire.
    final refreshedUid = session.user.id;
    if (refreshedUid.isEmpty || refreshedUid != user.userId) return;

    await _tokenStorage.updateTokens(session);
    if (generation != _wipeGeneration) {
      // Wipe survenu entre la lecture et l'écriture (TOCTOU) : on annule.
      await _tokenStorage.clearAuthSession();
      return;
    }
    final nowMs = _now();
    await _authLocalDao.updateLastServerSeen(user.userId, nowMs);
    // Le refresh est le SEUL canal par lequel un changement de droits redescend
    // (ADR-014 §4) : la copie durable suit, ensemble vide compris. Contrairement
    // à `user_version`, il n'y a rien à blanchir ici — les permissions ne sont
    // qu'une projection d'affichage, jamais l'autorité.
    await _authLocalDao.updatePermissions(user.userId, session.permissions);
    _currentPermissions?.set(session.permissions);
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
      // La borne par utilisateur suit (amendement m4) : un refresh réussi est
      // un contact online — la fenêtre offline de CE compte est ré-ancrée.
      await _authLocalDao.updateRefreshExpiresAt(
        user.userId,
        session.refreshExpiresAt!,
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
  ///
  /// [observedUid] = uid sous le JWT duquel la requête est partie (posé par
  /// l'interceptor d'auth au moment où il attache l'Authorization). Les
  /// compteurs `userVersion` sont PAR utilisateur : une réponse tardive émise
  /// sous le JWT d'un autre compte (tablette partagée, déconnexion/reconnexion
  /// rapide) ne doit ni ré-ancrer la fraîcheur ni alimenter la révocation —
  /// sinon la version de A, comparée au baseline de B, éjecte B et brûle sa
  /// fenêtre (revue adversariale).
  Future<void> recordServerContact({
    required int? observedUserVersion,
    required int? serverTimeMs,
    required String? observedUid,
  }) async {
    final user = await _authLocalDao.getSessionUser();
    if (user == null) return;
    if (observedUid == null || observedUid != user.userId) return;
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
      await wipeSession(revokeOfflineWindow: true);
      _revocationBus?.notifyRevoked();
      return true;
    }
    return false;
  }

  // ── Wipe (D-09/D-11) ─────────────────────────────────────────────────────────

  /// Wipe de session : jetons (secure storage) + `auth_local_session` +
  /// `session_started_at`. **Jamais** l'outbox, **jamais** `auth_local_user`.
  ///
  /// [revokeOfflineWindow] distingue les deux régimes (amendement m4) :
  /// - `false` (logout ordinaire) : la borne offline du compte survit — l'agent
  ///   pourra se reconnecter offline dans sa fenêtre (ADR §6, D-01 seul gate).
  ///   Le refresh token n'est pas détruit mais **consigné** sous l'uid de son
  ///   propriétaire (V1.1) : ressorti uniquement par un login offline du même
  ///   compte → resynchronisation silencieuse au retour réseau ;
  /// - `true` (révocation D-09 / refresh rejeté définitivement) : la fenêtre
  ///   est brûlée ET la consigne du compte détruite — le prochain login de ce
  ///   compte devra être online.
  Future<void> wipeSession({bool revokeOfflineWindow = false}) async {
    _wipeGeneration++; // invalide tout applyRefresh en vol (anti-résurrection)
    final user = await _authLocalDao.getSessionUser();
    // Le propriétaire RÉEL des jetons actifs est le profil du TOKEN STORE (les
    // jetons et le profil y sont toujours écrits ensemble). La session DB peut
    // diverger (crash entre l'upsert de session et la réconciliation des
    // jetons au login offline) : étiqueter la consigne avec l'uid DB
    // transférerait le crédentiel d'un compte à un autre (revue F1).
    final ownerUid = (await _tokenStorage.readAuthSession())?.user.id;
    final dbUid = user?.userId;

    if (revokeOfflineWindow) {
      // Révocation : rien ne survit pour le compte concerné — ni l'actif, ni
      // sa consigne. Par prudence (revue F2) : brûler si la consigne
      // correspond à L'UN OU L'AUTRE uid connu, et brûler inconditionnellement
      // si aucun uid n'est connaissable (slot unique, contexte = révocation).
      final parked = await _tokenStorage.readParkedRefresh();
      if (parked != null) {
        final matches = parked.uid == dbUid || parked.uid == ownerUid;
        final unknowable =
            dbUid == null && (ownerUid == null || ownerUid.isEmpty);
        if (matches || unknowable) {
          await _tokenStorage.clearParkedRefresh();
        }
      }
    } else {
      final refresh = await _tokenStorage.readRefreshToken();
      // Parquer SEULEMENT si : jeton présent · propriétaire connu (profil du
      // token store) · cohérent avec la session DB si elle existe (mismatch →
      // détruire, F1) · fenêtre offline du propriétaire encore vivante — les
      // chemins refresh-expiré passent aussi par ce wipe, et parquer un jeton
      // MORT certain écraserait la consigne valide d'un autre compte (F3).
      if (refresh != null &&
          refresh.isNotEmpty &&
          ownerUid != null &&
          ownerUid.isNotEmpty &&
          (dbUid == null || dbUid == ownerUid)) {
        final owner = await _authLocalDao.getUser(ownerUid);
        final bound = owner?.refreshExpiresAt;
        if (bound != null && _now() < bound) {
          await _tokenStorage.parkRefreshToken(
            uid: ownerUid,
            refreshToken: refresh,
          );
        }
      }
    }

    await _tokenStorage.clearAuthSession();
    if (user != null) {
      if (revokeOfflineWindow) {
        // Brûler AVANT de fermer la session : un crash entre les deux laisse
        // alors la borne déjà nulle → login offline refusé (l'ordre inverse
        // laisserait une fenêtre vivante après révocation).
        await _authLocalDao.clearRefreshExpiresAt(user.userId);
      }
      await _authLocalDao.wipeSession(user.userId);
    }
    _observedUserVersion = null;
    _currentUser?.clear();
    _currentPermissions?.clear();

    // Les pièces partagées vivent EN CLAIR dans le cache de l'application, hors
    // de la base chiffrée : elles doivent partir avec la session (ADR-012 D-7).
    // En dernier, et sans jamais faire échouer le wipe — fermer la session
    // prime sur nettoyer un cache.
    await _sharedDocumentCache?.purge();
  }

  // ── Sonde de crédentiels (boucle de synchro, V1.1) ──────────────────────────

  /// Vrai si la session peut authentifier des appels API : access non vide et
  /// NON EXPIRÉ, ou refresh actif non expiré (l'interceptor mintera). La
  /// Identité locale d'un auteur d'écriture d'outbox ([OutboxAuthorDirectory]).
  ///
  /// Sert à nommer, sur une tablette partagée, le collègue dont les écritures
  /// attendent sa reconnexion. Lecture pure de `auth_local_user`, jamais du
  /// contenu des écritures. Défensif : base indisponible ou compte inconnu →
  /// `null`, l'appelant retombe sur une formulation anonyme.
  @override
  Future<OutboxAuthorIdentity?> identityOf(String uid) async {
    try {
      final user = await _authLocalDao.getUser(uid);
      if (user == null) return null;
      return OutboxAuthorIdentity(
        firstName: user.firstName,
        lastName: user.lastName,
      );
    } catch (_) {
      return null;
    }
  }

  /// consigne ne compte pas (verrouillée par mot de passe). Les bornes
  /// manquantes valent « valide » (backend qui ne les fournit pas).
  /// Défensif : storage indisponible → `false` (ne pas marteler le serveur).
  @override
  Future<bool> canAuthenticate() async {
    try {
      final nowMs = _now();
      final stored = await _tokenStorage.readAuthSession();
      if (stored != null && stored.accessToken.isNotEmpty) {
        final accessExp = stored.accessExpiresAt;
        if (accessExp == null || nowMs < accessExp) return true;
        // Access périmé : utilisable seulement si un refresh peut minter.
      }
      final refresh =
          stored?.refreshToken ?? await _tokenStorage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;
      final refreshExp = stored?.refreshExpiresAt;
      return refreshExp == null || nowMs < refreshExp;
    } catch (_) {
      return false;
    }
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
