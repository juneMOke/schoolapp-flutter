class AppConstants {
  const AppConstants._();

  static const String appEnvironmentDefineKey = 'APP_ENV';
  static const String apiBaseUrlDefineKey = 'API_BASE_URL';
  static const String showEnvironmentBannerDefineKey =
      'SHOW_ENVIRONMENT_BANNER';
  static const String enableVerboseNetworkLoggingDefineKey =
      'ENABLE_VERBOSE_NETWORK_LOGGING';
  static const String defaultAppEnvironment = 'dev';

  static const String loginEndpoint = '/api/v1/auth/login';
  static const String refreshEndpoint = '/api/v1/auth/refresh';
  static const String generateOtpEndpoint = '/api/v1/auth/otp/generate';
  static const String validateOtpEndpoint = '/api/v1/auth/otp/validate';
  static const String resetPasswordEndpoint = '/api/v1/auth/reset-password';

  static const String enrollmentEndpoint = '/api/v1/enrollments';

  static const String studentPersonalInfoEndpoint =
      '/api/v1/students/{studentId}/personal-info';

  static const String studentAddressEndpoint =
      '/api/v1/students/{studentId}/address';

  static const String studentAcademicInfoEndpoint =
      '/api/v1/students/{studentId}/academic-info';

  static const String parentUpdateEndpoint = '/api/v1/parents/{parentId}';
  static const String parentCreateEndpoint = '/api/v1/parents';
  static const String parentUnlinkEndpoint =
      '/api/v1/parents/students/{studentId}/{parentId}';

  static const String enrollmentAcademicInfoEndpoint =
      '/api/v1/enrollments/{enrollmentId}/previous-school-info';

  static const String enrollmentDetailEndpoint =
      '/api/v1/enrollments/{enrollmentId}/detail';
  static const String enrollmentSearchByStudentInfoEndpoint =
      '/api/v1/enrollments/search/by-names';
  static const String enrollmentSearchByStudentInfoWithDateOfBirthEndpoint =
      '/api/v1/enrollments/search/by-names-and-dob';

  static const String enrollmentSearchByDateOfBirthEndpoint =
      '/api/v1/enrollments/search/by-date-of-birth';

  static const String enrollmentSearchByAcademicInfoEndpoint =
      '/api/v1/enrollments/search/by-academic-info';

  static const String enrollmentPreviewByStudentEndpoint =
      '/api/v1/enrollments/students/{studentId}/preview';

  static const String enrollmentStatsEndpoint = '/api/v1/enrollment-stats';

  static const String classroomsEndpoint = '/api/v1/classrooms';
  static const String classroomMembersEndpoint =
      '/api/v1/classrooms/{classroomId}/members';
  static const String classroomDistributionOverviewEndpoint =
      '/api/v1/classrooms/distribution-overview';
  static const String classroomStatsEndpoint = '/api/v1/classroom-stats';
  static const String classroomsDistributeEndpoint =
      '/api/v1/classrooms/distribute';

  static const String academicYearBySchoolEndpoint =
      '/api/v1/academic-years/current';

  static const String bootstrapEndpoint = '/api/v1/bootstrap';
  static const String bootstrapCurrentYearEndpoint =
      '/api/v1/bootstrap/current-year';
  static const String bootstrapPreviousYearEndpoint =
      '/api/v1/bootstrap/previous-year';
  static const String feeTariffsEndpoint = '/api/v1/finance/tariffs';
  static const String initializeStudentChargesEndpoint =
      '/api/v1/finance/student-charges/{studentId}/initialize-charges';
  static const String listStudentChargesByStudentAndAcademicYearEndpoint =
      '/api/v1/finance/student-charges/student/{studentId}/academic-year/{academicYearId}';
  static const String listPaymentsByStudentAndAcademicYearEndpoint =
      '/api/v1/finance/payments/student/{studentId}/academic-year/{academicYearId}';
  static const String createPaymentEndpoint = '/api/v1/finance/payments';
  static const String listPaymentAllocationsByPaymentIdEndpoint =
      '/api/v1/finance/payments/{paymentId}/allocations';
  static const String listPaymentAllocationsByChargeIdEndpoint =
      '/api/v1/finance/student-charges/{chargeId}/allocations';
  static const String updateStudentChargeExpectedAmountEndpoint =
      '/api/v1/finance/student-charges/{studentChargeId}';
  static const String financeStatsEndpoint = '/api/v1/finance-stats';

  // ── Éditique (documents PDF scellés) ──────────────────────────────────────
  // Toutes ces routes répondent `application/pdf` en corps binaire, sans body
  // de requête, et posent un `Content-Disposition: attachment; filename="<n°>.pdf"`
  // (non contractualisé dans le swagger — il est lu en best-effort, cf.
  // `ContentDispositionParser`).
  //
  // ⚠️ Deux régimes très différents côté serveur, portés par
  // `EditiqueDocumentType.isReplayable` :
  //  - AI / NP / RC sont **archivés et idempotents** : réémettre re-sert les
  //    mêmes octets sous le même numéro — **tant que la pièce est en vigueur**.
  //    Depuis le lot back B5, une pièce ANNULÉE ne satisfait plus cette
  //    promesse : le serveur la traite comme absente et en scelle une neuve,
  //    donc un nouveau numéro est consommé et, pour le reçu, `payment.receiptId`
  //    est repointé. Pour ressortir une pièce annulée il faut la RESTITUTION
  //    (`GET .../editique/documents/{id}`), qui ne filtre pas l'annulation et
  //    n'écrit rien — jamais une réémission ;
  //  - RL / QT ne sont **jamais archivés** et consomment un numéro de séquence
  //    à CHAQUE appel. Un rejeu après échec crée une seconde pièce numérotée.
  static const String emitEnrollmentAttestationEndpoint =
      '/api/v1/enrollments/{enrollmentId}/attestation';
  static const String emitNotePerceptionEndpoint =
      '/api/v1/finance/students/{studentId}/note-perception';
  static const String emitPaymentReceiptEndpoint =
      '/api/v1/finance/payments/{paymentId}/receipt';
  static const String emitAccountStatementEndpoint =
      '/api/v1/finance/students/{studentId}/releve';
  static const String emitFinancialClearanceEndpoint =
      '/api/v1/finance/students/{studentId}/quitus';

  /// Re-téléchargement d'une pièce **archivée**, par son identifiant d'archive.
  ///
  /// Ressert les octets gelés à l'identique (RG-012-3 : un reçu retéléchargé six
  /// mois plus tard est identique au bit près). C'est un `GET` : il ne produit
  /// rien, ne consomme aucun numéro de séquence, et se rejoue librement — à
  /// l'inverse des cinq routes d'émission ci-dessus.
  ///
  /// N'existe que pour les pièces que le serveur conserve : un relevé ou un
  /// quitus n'a pas d'identifiant à désigner.
  static const String downloadEditiqueDocumentEndpoint =
      '/api/v1/editique/documents/{documentId}';

  /// Delta de synchronisation des pièces scellées — **métadonnées seules**.
  ///
  /// Apprend à la tablette ce qui existe ailleurs (une pièce émise depuis un
  /// autre poste, ou scellée par la clôture d'une période) ; les octets restent
  /// tirés un par un par [downloadEditiqueDocumentEndpoint]. Cadré par école,
  /// pas par année : l'année est nullable sur ces pièces, la demander laisserait
  /// ces lignes hors de portée.
  static const String syncEditiqueDocumentsEndpoint =
      '/api/v1/sync/editique-documents';

  /// Type MIME attendu en réponse des routes d'éditique. Sert de **garde de
  /// contenu** : un corps qui n'est pas un PDF ne doit jamais être présenté
  /// comme un document.
  static const String pdfContentType = 'application/pdf';

  /// En-tête `Accept` des routes d'éditique — volontairement **plus large** que
  /// [pdfContentType].
  ///
  /// Le succès est un PDF, mais le corps d'erreur du serveur est en JSON
  /// (schéma `ApiError`). Avec `application/pdf` seul, Spring ne trouve plus de
  /// converter capable d'écrire `ApiError` dans un type acceptable et lève
  /// `HttpMediaTypeNotAcceptableException` : le 404 « Aucune charge pour
  /// l'élève » ressort en 500 au corps vide, et tout le décodage d'erreur du
  /// module devient inopérant. Le chemin nominal n'est pas affecté — les
  /// contrôleurs posent explicitement `contentType(APPLICATION_PDF)`, ce qui
  /// court-circuite la négociation de contenu.
  static const String pdfAcceptHeader = '$pdfContentType, application/json';

  static const String bootstrapPayloadKey = 'bootstrap_payload';
  static const String bootstrapSchemaVersionKey =
      'bootstrap_local_schema_version';
  static const String bootstrapSchemaVersion = '1';

  static const String accessTokenKey = 'access_token';
  static const String tokenTypeKey = 'token_type';
  static const String expiresInKey = 'expires_in';
  // ADR-010 — secrets de session offline (jamais en base : survivent au wipe).
  static const String refreshTokenKey = 'refresh_token';
  // Consigne du refresh token (V1.1) : au logout ORDINAIRE, le refresh token
  // n'est pas détruit mais consigné avec l'uid de son propriétaire ; il n'est
  // ressorti QUE par un login offline du même compte (preuve par mot de passe,
  // vérificateur Argon2id) → resynchronisation silencieuse au retour réseau.
  // Slot unique (dernier consigné gagne) ; brûlé sur révocation du compte.
  static const String parkedRefreshTokenKey = 'parked_refresh_token';
  static const String parkedRefreshUidKey = 'parked_refresh_uid';
  static const String accessExpiresAtKey = 'access_expires_at';
  static const String refreshExpiresAtKey = 'refresh_expires_at';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userFirstNameKey = 'user_first_name';
  static const String userLastNameKey = 'user_last_name';
  static const String userRoleKey = 'user_role';
  static const String userSchoolIdKey = 'user_school_id';
  static const String userCreatedAtKey = 'user_created_at';

  static const String bootstrapPreviousYearPayloadKey =
      'bootstrap_previous_year_payload';

  // ─── Support / Contact ───────────────────────────────────────────────────────
  /// Adresse de contact de l'administration (actions « Contacter l'administrateur »
  /// des etats d'erreur 403). Centralisee ici pour eviter la duplication.
  static const String supportEmail = 'support@school.local';

  // ─── Attendance ────────────────────────────────────────────────────────────
  static const String attendanceEndpoint = '/api/v1/attendances';
  static const String attendanceByClassroomEndpoint =
      '/api/v1/attendances/classes/{classroomId}';
  static const String attendanceOverviewEndpoint =
      '/api/v1/attendance-stats/overview';
  static const String disciplinaryCasesEndpoint = '/api/v1/disciplinary-cases';
  static const String disciplinaryCaseByIdEndpoint =
      '/api/v1/disciplinary-cases/{caseId}';

  // ─── Academics ───────────────────────────────────────────────────────────
  /// Cours de l'enseignant connecté, regroupés par classe (résolu via le JWT).
  static const String myCoursesEndpoint = '/api/v1/academics/cours/mes-cours';

  /// Détail de notation d'un cours par période (semestre/trimestre) puis
  /// sous-période. `{coursId}` est résolu via `@Path`.
  static const String coursNotationDetailEndpoint =
      '/api/v1/academics/cours/{coursId}/notation';

  /// Création d'une évaluation (interro/devoir/examen) sous un cours.
  /// `{coursId}` est résolu via `@Path` ; l'école vient du JWT (multi-tenant).
  static const String createEvaluationEndpoint =
      '/api/v1/academics/cours/{coursId}/evaluations';

  /// Grille de saisie : chaque élève de la classe du cours + sa note pour
  /// l'évaluation `{evaluationId}` (résolu via `@Path`).
  static const String notesElevesEndpoint =
      '/api/v1/academics/evaluations/{evaluationId}/notes/eleves';

  /// Saisie/rattrapage (upsert idempotent) de la note d'un élève pour
  /// l'évaluation `{evaluationId}` (résolu via `@Path`).
  static const String saisirNoteEndpoint =
      '/api/v1/academics/evaluations/{evaluationId}/notes';

  // ─── Résultats par classe (lecture seule, calcul live) ─────────────────────
  /// Vue classe (synthèse + table roster × sous-période) pour une grande
  /// période. `classroomId`, `periodeScolaireId` et `seuil?` en query.
  static const String resultatsClasseEndpoint =
      '/api/v1/academics/resultats/classe';

  /// Vue focus d'un élève. `{studentId}` résolu via `@Path` ; `classroomId` et
  /// `periodeScolaireId` en query.
  static const String resultatFocusEndpoint =
      '/api/v1/academics/resultats/classe/{studentId}';

  /// Recherche roster scopée classe (mode « Par élève »). `{classroomId}`
  /// résolu via `@Path` ; `academicYearId` requis + `nom`/`postnom`/`prenom`.
  static const String classroomMembersSearchEndpoint =
      '/api/v1/classrooms/{classroomId}/members/search';

  /// Grandes périodes (trimestres/semestres) **d'une classe**, chaque entrée
  /// portant le `periodeScolaireId` exigé par la vue classe / focus, la période
  /// `courant` marquée, et un `libelle` déjà synthétisé côté serveur.
  ///
  /// Scopé **classe** (`classroomId` requis) : le backend résout l'année × cycle
  /// depuis la classe. Trié par `ordre` asc. Auth JWT (`@Extras() requiredAuth`).
  static const String resultatsPeriodesEndpoint =
      '/api/v1/academics/resultats/periodes';

  // ─── Schedule (emploi du temps) ────────────────────────────────────────────
  /// Emploi du temps de l'enseignant connecté (résolu via le JWT).
  static const String myTimetableEndpoint = '/api/v1/schedule/my-timetable';

  /// Grille d'une classe (conseil pédagogique / admin).
  static const String classroomGridEndpoint = '/api/v1/schedule/grid';

  /// Création d'un créneau de sonnerie (une ligne de la grille).
  static const String timeSlotsEndpoint = '/api/v1/schedule/time-slots';

  /// Placement d'un cours à l'emploi du temps.
  static const String sessionsEndpoint = '/api/v1/schedule/sessions';

  /// Retrait d'une séance. `{id}` est résolu via `@Path`.
  static const String sessionByIdEndpoint = '/api/v1/schedule/sessions/{id}';

  // ─── Pagination ────────────────────────────────────────────────────────────
  /// Taille de page par défaut pour les listes d'enrollments.
  static const int enrollmentDefaultPageSize = 10;

  // ─── Offline / Socle local chiffré ───────────────────────────────────────────
  /// Nom du fichier de la base locale chiffrée (SQLCipher).
  static const String offlineDbName = 'school_offline.db';

  /// Version du schéma sqflite local. Bump = nouvelle étape de migration
  /// (onUpgrade dans AppDatabase). V1 = création greenfield.
  // v2 (2026-07-08) : tables de référence Inscription (cohorte RE
  // `ref_previous_year_students`, `ref_pre_enrollments`, socle référentiel).
  // v3 (2026-07-08) : `enrollments.source_ref` (matricule RE / id préinscription
  // PRE, contrat agrégat).
  // v4 (2026-07-16) : Présence — modèle session-agrégat (`attendance_sessions`).
  // v5 (2026-07-18) : Classe — événement `classroom_transfers` (transfert offline).
  // v6 (2026-07-18) : Discipline — agrégat {case, comments[]} : table
  // `disciplinary_case_comments` (append-only) + `disciplinary_cases.server_updated_at`
  // (visibilité serveur, base du pull keyset). Table neuve → aucun backfill.
  // v7 (2026-07-19) : Auth/session offline (ADR-010) — tables `auth_local_user`,
  // `auth_local_session`, `auth_clock_guard`. Tables neuves → aucun backfill.
  // v8 (2026-07-19) : Notes / Cours (academics + schedule, ADR-006) — réf
  // `ref_time_slots`/`ref_recurring_sessions`/`ref_cours` + écriture `evaluation`
  // (régime A) et `note_evaluation` (régime C). Tables neuves → aucun backfill.
  // v9 (2026-07-19) : Notes / Cours — cache `ref_cours_notation` (squelette
  // période/sous-période + statut + effectif). Table neuve → aucun backfill.
  // v10 (2026-07-20) : Auth (ADR-010, amendement m4) — borne offline par
  // utilisateur `auth_local_user.refresh_expires_at` (survit au logout, brûlée
  // sur révocation). Backfill depuis la session active vers son propriétaire.
  // v11 (2026-07-22) : Notes / Cours — purge + rebootstrap forcé après le
  // passage au contrat back scopé enseignant (commit `1ec6be3`, DF-K/DF-L) :
  // les pulls antérieurs n'étaient pas scopés au prof connecté, la base locale
  // pouvait porter des cours/évaluations/notes/séances d'autres enseignants.
  // v12 (2026-07-23) : Notes / Cours — bundle `grades-referential` (ETag,
  // cadré prof) : 5 tables réf neuves (branches, lignes de barème + plafonds,
  // chapitres, périodes/sous-périodes), devient la seule source du statut de
  // clôture (retire le squelette `ref_cours_notation`, workaround online v9).
  // `evaluation.chapitre_ids_json`/`rejection_code`, `note_evaluation.rejection_reason`.
  // v13 (2026-07-26) : Inscription — `ref_academic_years.school_id` (bootstrap
  // remplacé par le référentiel scopé école). Backfill best-effort depuis
  // `auth_local_user` (mono-école sur device connu) ; sinon vide, réécrit au
  // prochain pull référentiel.
  // v14 (2026-07-26) : Inscription — `ref_school` (identité du tenant), le
  // bundle référentiel renvoyant désormais `school` + `current`/`previous`
  // au lieu d'une liste plate d'années. Table neuve, aucun backfill (réécrite
  // au prochain pull référentiel).
  // v15 (2026-07-26) : Inscription — `enrollments.previous_school_level_id`,
  // id référentiel du niveau N-1 (distinct du texte libre
  // `previous_school_level`), utilisé par le calcul auto de la classe cible
  // en réinscription. Renseigné uniquement au seed RE ; aucun backfill.
  // v16 (2026-07-27) : Classe — re-contrat CB-2 en pull KEYSET (`classrooms`
  // bundlé → deux flux indépendants `classrooms`/`classroom-members`, curseur
  // opaque au lieu de l'ancien `updatedSince` ISO). La clé `sync_meta.classrooms`
  // est réutilisée mais change de nature de curseur : purge du curseur hérité
  // (comme v11) pour repartir d'un bootstrap propre, sans dépendre d'un rejet
  // 400 serveur pour s'auto-guérir.
  // v17 (2026-07-30) : Inscription — recherche de tuteur existant (étape
  // Tuteurs). Index composé (nom, prénom) pour accélérer le LIKE de
  // recherche. L'unicité du téléphone reste APPLICATIVE (DAO), pas de UNIQUE
  // INDEX SQL (risque de casser la migration sur des doublons hérités).
  // v19 (2026-08-04) : Éditique offline (ADR-012 D-3) — le reçu provisoire est
  // une PROJECTION de lignes locales, il faut donc que ces lignes portent tout
  // ce que le ticket imprime. `payments` gagne le caissier (uid + nom
  // dénormalisé : `OutboxAuthorDirectory.identityOf` peut rendre null, et
  // l'entrée d'outbox qui portait l'auteur est supprimée à l'ACK) et
  // l'identifiant d'appareil. `generated_documents` gagne `provisional_number`,
  // conservé après scellement : c'est le seul lien entre le papier détenu par
  // un parent et le reçu définitif. `payments.receipt_id` capte l'UUID que le
  // serveur envoie déjà (ACK et delta) et que le client jetait.
  // v20 (2026-08-04) : Éditique offline (ADR-012 D-5, amendé) — table
  // `payment_anomalies`. L'issue terminale d'un encaissement offline n'est pas
  // un REJET (le contrat garantit qu'un paiement n'est jamais rejeté pour motif
  // métier) mais une ANOMALIE de trop-perçu, à arbitrer. Table dédiée et non
  // l'outbox : une entrée acquittée y est supprimée au flush, et son motif
  // effacé par un clic sur « Réessayer ».
  // v21 (2026-08-05) : Éditique offline (ADR-012 D-2/D-7, AM-10) — table
  // `editique_cache_entries`, INDEX du cache de restitution. Aucun octet n'y
  // entre : les PDF scellés vivront dans des fichiers chiffrés hors base (le
  // `CursorWindow` de 16 Ko d'Android fait lever la RELECTURE d'un blob, et le
  // défaut est invisible en CI qui tourne en ffi). Index seul d'abord, pour
  // éprouver éviction LRU, mesure et purge avant toute volumétrie.
  // v22 (2026-08-05) : Éditique offline (ADR-012 RG-012-6/18) — l'index du cache
  // doit pouvoir décrire une pièce dont la tablette n'a PAS les octets. Le delta
  // de synchronisation lui apprend ce qui existe ailleurs ; les octets restent
  // tirés à la demande. `content_sha256` devient nullable et porte cette
  // différence : renseigné = octets détenus, NULL = connaissance seule. Sans
  // elle, le budget compterait des octets absents et l'éviction évincerait du
  // vide. Reconstruction AVEC copie — vider la table ferait perdre l'accès aux
  // fichiers chiffrés déjà détenus, donc des pièces qu'un guichet hors ligne ne
  // pourrait plus ressortir.
  // v23 (2026-08-06) : Éditique offline (ADR-012, lot back B5) — `cancelled_at`
  // et `cancellation_reason` sur `editique_cache_entries`. Le delta descend
  // l'annulation depuis B5 ; le front la jetait, et une pièce retirée par le
  // serveur continuait d'être proposée hors ligne. L'axe est ORTHOGONAL à
  // `content_sha256` : une pièce annulée garde ses octets, parce qu'un guichet
  // doit pouvoir ressortir le papier qu'une famille lui présente pour lui
  // expliquer pourquoi il n'a plus cours. Deux `ALTER` nullables, sans backfill
  // — une pièce déjà en cache n'a jamais connu son annulation, et le prochain
  // cycle la lui apprendra.
  static const int offlineDbSchemaVersion = 23;

  /// Clé du secure storage hébergeant la clé de chiffrement SQLCipher,
  /// générée au premier lancement (cf. DatabaseKeyService).
  static const String sqlCipherKeyStorageKey = 'sqlcipher_db_key';

  /// Clé du secure storage hébergeant l'identifiant d'installation, généré au
  /// premier besoin (cf. DeviceIdentityService). Imprimé sur le ticket
  /// provisoire et porté par les anomalies de synchro.
  static const String deviceIdStorageKey = 'device_installation_id';

  /// Clé du secure storage hébergeant la clé AES-256 du cache de restitution
  /// éditique (cf. EditiqueCacheKeyService).
  ///
  /// **Distincte de [sqlCipherKeyStorageKey]** : les pièces scellées vivent
  /// hors de la base, et l'effacement physique de D-7 doit pouvoir les rendre
  /// illisibles — en supprimant cette clé — sans rien détruire de la base.
  static const String editiqueCacheKeyStorageKey = 'editique_cache_key';

  // ─── Éditique — cache de restitution (ADR-012 D-2, RG-012-5) ─────────────────
  /// Budget disque du cache éditique, en octets (2 Gio).
  ///
  /// Dimensionnement de référence : une école de 500 élèves produit ~1 `AI` +
  /// 1 `NP` + ~5 `RC` + 3 `BU` par élève et par an, soit ~5 000 pièces de
  /// ~120 Ko ≈ 600 Mo par année scolaire. Deux années tiennent donc largement,
  /// sur des tablettes d'administration de 128 Go.
  ///
  /// Budget du **disque de l'appareil**, pas d'un établissement : il ne se
  /// divise pas par école, il se partage.
  static const int editiqueCacheBudgetBytes = 2 * 1024 * 1024 * 1024;

  /// Part du budget visée **après** un balayage d'éviction.
  ///
  /// Redescendre exactement au seuil ferait rebalayer à chaque écriture
  /// suivante ; libérer 2 % (~40 Mo, ~340 pièces) laisse de quoi encaisser
  /// plusieurs centaines d'émissions avant le balayage suivant. Volontairement
  /// proche de 1 : une pièce évincée n'est récupérable qu'**en ligne**, ce qui
  /// est précisément ce qui manque à ces écoles, donc on évince le moins
  /// possible à la fois.
  static const double editiqueCacheEvictionTargetRatio = 0.98;

  // ─── Auth/session offline — dégradation graduée (ADR-010 D-08) ────────────────
  /// Seuil J7 : au-delà de `now − last_server_seen_at`, la session passe en
  /// WARNING (saisie OK, bandeau permanent, scellement de documents bloqué).
  static const Duration sessionWarningThreshold = Duration(days: 7);

  /// Seuil J21 : au-delà, la session passe en READ_ONLY (lecture seule,
  /// reconnexion online exigée).
  static const Duration sessionReadOnlyThreshold = Duration(days: 21);

  // ─── Offline sync — contrats miroir backend ──────────────────────────────────
  // État au 2026-07-07 (cf. ETAT_IMPLEMENTATION_Backend_V1.md, OFFLINE_GAP_ANALYSIS.md) :
  //  • LIVRÉS V1.0 (consommables) : GET /api/v1/sync/classrooms (+ attendance,
  //    academics/cours, academics/notes, schedule — à déclarer ici lors de leur
  //    branchement, cf. Phase 1/3 du plan d'alignement).
  //  • NON livrés (V1.1, câblage miroir en attente) : l'agrégat d'inscription, le
  //    référentiel/cohorte/pré-inscriptions et les pulls finance ci-dessous.
  // Câblés côté client conformément aux SPEC_Frontend_*_Offline_V1.

  // ── Offline sync — Inscription (contrat openapi_enrollment_sync.yaml) ──
  // Contrat que le back met en place. Convention app : préfixe /api/v1
  // (le contrat OpenAPI l'abrège en /api).
  //
  // PUSH (commit agrégat) + PULL delta descendant partagent le chemin de la
  // ressource de synchro `syncEnrollmentsEndpoint` (/api/v1/sync/enrollments) :
  //  • POST → commit {enrollment, student, parents} (201/200 = OK, 422 = rejet).
  //  • GET  → delta descendant (curseur updatedSince → 304).
  // Le pull HYDRATANT (agrégats complets, tablette neuve) est servi à part par
  // `syncEnrollmentSnapshotsEndpoint` (/api/v1/sync/enrollments/snapshots).

  /// Pull du socle référentiel (années, cycles, niveaux, tarifs) — bundle
  /// conditionnel ETag/304. GET /api/v1/sync/referential.
  static const String syncReferentialEndpoint = '/api/v1/sync/referential';

  /// Pull de la cohorte de réinscription N-1 (bornée/statique, ETag/304)
  /// → `ref_previous_year_students`. GET /api/v1/sync/reenrollment-cohort.
  static const String syncReenrollmentCohortEndpoint =
      '/api/v1/sync/reenrollment-cohort';

  /// Pull des préinscriptions en ligne (delta `updatedSince`)
  /// → `ref_pre_enrollments`. GET /api/v1/sync/pre-enrollments.
  static const String syncPreEnrollmentsEndpoint =
      '/api/v1/sync/pre-enrollments';

  /// Pull des inscriptions en ligne (delta maigre `updatedSince`, réconciliation)
  /// + PUSH agrégat idempotent. → `enrollments`. GET/POST /api/v1/sync/enrollments.
  static const String syncEnrollmentsEndpoint = '/api/v1/sync/enrollments';

  /// Pull HYDRATANT des inscriptions (agrégats complets = inscription + élève
  /// canonique + tuteurs) pour reconstituer une tablette neuve (delta
  /// `updatedSince`). GET /api/v1/sync/enrollments/snapshots.
  static const String syncEnrollmentSnapshotsEndpoint =
      '/api/v1/sync/enrollments/snapshots';

  /// Pull delta de la grille tarifaire (gelée sur la saison, 304 fréquent).
  static const String syncFinanceTariffsEndpoint =
      '/api/v1/sync/finance/tariffs';

  /// Pull KEYSET des créances élèves (le plus gros volume ; paginé, résumable,
  /// jeton `cursor` opaque base64url, 304 applicatif). Contrat openapi_billing_sync.
  static const String syncStudentChargesEndpoint =
      '/api/v1/sync/student-charges';

  /// Agrégat paiement offline (contrat openapi_billing_sync) :
  ///  - **POST** = push idempotent de l'encaissement (uuid client honoré) ;
  ///  - **GET** = pull KEYSET des paiements, y compris ceux de l'autre poste de
  ///    perception (anti-divergence de snapshot) — même enveloppe keyset.
  ///
  /// À ne pas confondre avec [createPaymentEndpoint], le POST **en ligne** du
  /// module Facturation (forme à plat), qui reste en service hors offline.
  static const String syncPaymentsEndpoint = '/api/v1/sync/payments';

  // ── Offline sync — Classe/Présence/Discipline ──
  /// Agrégat d'appel Présence (contrat openapi_attendance_sync 1.2.0) :
  ///  - **POST** = push de l'agrégat `{session, absences[]}` (upsert clé
  ///    naturelle + LWW `updatedAt` ; réponse `lwwOutcome` + `expectedCount`) ;
  ///  - **GET** = pull KEYSET des sessions (absences imbriquées), cadré année,
  ///    jeton `cursor` opaque, 304 applicatif.
  ///
  /// Remplace l'ancien push record-level [attendanceEndpoint] côté offline
  /// (celui-ci reste en service pour les lectures online hors offline).
  static const String syncAttendanceEndpoint = '/api/v1/sync/attendance';

  /// Pull KEYSET des `ref_classrooms` (CB-2, re-contracté 2026-07-27 —
  /// remplace l'ancien contrat bundlé `updatedSince`/`serverCursor`) :
  /// `KeysetPage<ClassroomSyncView>` (`nextCursor`/`nextWatermark`/`hasMore`),
  /// jeton `cursor` opaque, 304 applicatif. Query : `academicYearId`, `cursor`,
  /// `limit`. Ressource **indépendante** de [syncClassroomMembersEndpoint] (curseur
  /// séparé, pas de synchro artificielle entre les deux flux).
  static const String syncClassroomsEndpoint = '/api/v1/sync/classrooms';

  /// Pull KEYSET du roster (`ref_classroom_members`), même contrat que
  /// [syncClassroomsEndpoint] mais ressource indépendante (curseur séparé,
  /// ACTIVE+INACTIVE — la sortie d'un élève doit se propager au cache).
  static const String syncClassroomMembersEndpoint =
      '/api/v1/sync/classroom-members';

  /// Volet transfert du module Classe (contrat openapi_classroom_sync 1.1.0) :
  ///  - **POST** = push de l'événement de transfert (régime A, idempotent sur
  ///    `transfer.id` ; réponse = appartenance canonique + compteurs des 2
  ///    classes recalculés). 201 créé ≡ 200 rejeu, les deux succès ;
  ///  - **GET** = pull KEYSET des transferts de l'année (dont ceux faits online
  ///    par le conseil pédagogique), cadré année, jeton `cursor` opaque, 304
  ///    applicatif. Indispensable au dénominateur d'assiduité par intervalles.
  static const String syncClassroomTransfersEndpoint =
      '/api/v1/sync/classroom-transfers';

  /// Volet Discipline offline (contrat openapi_discipline_sync 1.1.0) :
  ///  - **POST** = push de l'agrégat `{case, comments[]}` (upsert 200) : le FAIT
  ///    insert-only (régime A, uuid honoré), le TRAITEMENT `status`/`sanction`
  ///    gardé par LWW `clientUpdatedAt`, les commentaires append-only ; la réponse
  ///    porte `lwwOutcome` (APPLIED/SUPERSEDED) + l'état canonique ;
  ///  - **GET** = pull KEYSET des cas de l'année (commentaires imbriqués), cadré
  ///    année, jeton `cursor` opaque, 304 applicatif.
  ///
  /// Remplace côté offline l'ancien couple [disciplinaryCasesEndpoint] (POST) +
  /// [disciplinaryCaseByIdEndpoint] (PUT) : chemin unique upsert, sémantique LWW.
  static const String syncDisciplinaryCasesEndpoint =
      '/api/v1/sync/disciplinary-cases';

  // ── Offline sync — Notes / Cours (contrat PLAN_notes_cours_offline) ──
  // Frontière ADR-006 : seules la SAISIE (évaluation régime A, note régime C)
  // et sa RÉFÉRENCE (cours, emploi du temps) transitent ; bulletin, rang et
  // résultats « live » restent serveur. 5 pulls keyset (lecture seule) + 2
  // ingest. Jeton `cursor` opaque, `KeysetPage`, 304 applicatif sur cycle vide.

  /// Pull KEYSET des cours du prof connecté (réf, lecture seule). Scope
  /// **enseignant dérivé du token** (email, insensible à la casse — commit back
  /// `1ec6be3`), jamais de `classroomId` côté client. Query : `cursor`, `limit`.
  /// `404` = compte non lié à un enseignant. → `ref_cours`.
  static const String syncAcademicsCoursEndpoint =
      '/api/v1/sync/academics/cours';

  /// Pull KEYSET **et** ingest des évaluations (régime A, insert-only) :
  ///  - **GET** = delta keyset des évaluations d'un cours (`coursId`, `cursor`,
  ///    `limit`) → `evaluation` ;
  ///  - **POST** = push idempotent d'une évaluation (uuid client honoré) :
  ///    200 rejeu / 201 créée.
  static const String syncAcademicsEvaluationsEndpoint =
      '/api/v1/sync/academics/evaluations';

  /// Pull KEYSET **et** ingest des notes (régime C, upsert clé naturelle + LWW) :
  ///  - **GET** = delta keyset des notes d'un cours (`coursId`, `cursor`,
  ///    `limit`) → `note_evaluation` (curseur INDÉPENDANT de celui des
  ///    évaluations — split assumé) ;
  ///  - **POST** = push d'un lot de notes d'une évaluation ; réponse = **outcome
  ///    par ligne** (APPLIED / SUPERSEDED / REJECTED:PERIODE_CLOSE|INVALID) +
  ///    l'état serveur. Toujours 200.
  static const String syncAcademicsNotesEndpoint =
      '/api/v1/sync/academics/notes';

  /// Pull du **bundle** grille & périodes (réf de saisie, lecture seule),
  /// cadré **enseignant dérivé du token**. Mécanisme **ETag applicatif**
  /// (`If-None-Match` → `200` + en-tête `ETag` + corps, ou `304` sans corps) —
  /// **pas** keyset, non paginé. `404` = compte non lié à un enseignant.
  /// Contenu : branches, lignes de barème (plafonds `maxJournalierParSousPeriode`/
  /// `maxExamenParPeriodeScolaire` nullable), chapitres (`contenu` omis),
  /// périodes/sous-périodes à plat avec statut de clôture. → `ref_branche`,
  /// `ref_ligne_bareme`, `ref_chapitre`, `ref_periode`, `ref_sous_periode`
  /// (remplacement d'ensemble à chaque `200`).
  static const String syncAcademicsGradesReferentialEndpoint =
      '/api/v1/sync/academics/grades-referential';

  /// Pull KEYSET de la trame horaire de l'école (réf, lecture seule). Scope
  /// école résolu par le JWT. Query : `cursor`, `limit`. → `ref_time_slots`.
  static const String syncScheduleTimeSlotsEndpoint =
      '/api/v1/sync/schedule/time-slots';

  /// Pull KEYSET des séances récurrentes de l'année (réf, lecture seule ; labels
  /// dénormalisés). Scope **enseignant dérivé du token** + année (commit back
  /// `1ec6be3`). Query : `academicYearId`, `cursor`, `limit`. `404` = compte non
  /// lié à un enseignant. → `ref_recurring_sessions`.
  static const String syncScheduleSessionsEndpoint =
      '/api/v1/sync/schedule/sessions';
}
