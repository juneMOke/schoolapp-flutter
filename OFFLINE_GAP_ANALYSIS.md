# OFFLINE_GAP_ANALYSIS — écarts specs ↔ backend livré ↔ code Flutter

> **Date :** 2026-07-07 · **Branche :** `feature/implements_offline`
> **Sources :** specs `backend_spring/offline/{back-end,front-end,adr}/`,
> document d'autorité `ETAT_IMPLEMENTATION_Backend_V1.md`, code `lib/`.
> **Méthode :** audit multi-agents (7 modules), chaque écart **vérifié en
> contradictoire** (passe adverse). Ce document accompagne `OFFLINE.md` (choix
> d'implémentation) ; il en est le **relevé de dette**.

---

## Diagnostic en une phrase

Le **backend a livré la vague V1.0** (pulls delta `/api/v1/sync/*`, LWW
`updatedAt`, réponses d'écriture enrichies, `422 PERIODE_CLOSE`) le 2026-07-07,
mais le **code Flutter et sa doc sont restés au mental-model « P0 »**
(« on écrit offline, on lit online, les pulls n'existent pas »). Résultat : une
couche offline **largement écrite mais dormante en lecture**, des contrats de
curseur qui ne matchent plus, et deux modules livrés back **sans aucun front**.

---

## 1. Les « deux blocs » — deux lectures, deux écarts réels

**Lecture A — la doc a deux blocs (`back-end/` + `front-end/`) + un 3ᵉ arbitre.**
L'INDEX le dit : *« en cas d'écart avec une spec de conception, ce document
[ETAT] et le code font foi »*. Or **la SPEC front ET le code Flutter sont
périmés** vis-à-vis de l'ETAT : les deux affirment encore que les pulls
n'existent pas alors qu'ils sont livrés.

**Lecture B — le CODE a deux blocs par feature (écart structurant).**
Chaque feature migrée **monte simultanément deux BLoCs** : le bloc *online*
historique (pilote **toutes les lectures**) + un bloc *offline* (`/offline`,
pilote **les écritures**). Les usecases de lecture locale existent, sont
enregistrés en DI, mais **ne sont dispatchés par aucune UI** → code mort à
l'exécution. C'est un `if(online)` de fait, proscrit par l'ADR-003.

| Feature | Bloc online (lecture) | Bloc offline (écriture) |
|---|---|---|
| Facturation | `StudentChargesBloc` + `PaymentsBloc` | `FinanceOfflineBloc` |
| Classe | `ClassroomBloc` (`distributionOverview`) | `ClassroomOfflineBloc` |
| Présence | `AttendanceBloc` (`draftRows`) | `AttendanceOfflineBloc` |
| Discipline | `DisciplinaryCaseBloc` | `DisciplinaryCaseOfflineBloc` |
| Inscription | `EnrollmentBloc` (lectures listing/détail) | `EnrollmentOfflineBloc` (bloc unique : draft-par-étape + finalize + pull ; `EnrollmentDraftBloc` fusionné dedans — voir journal 2026-07-09) |

Conséquences visibles : un **cas de discipline créé hors-ligne ne se réaffiche
pas** (refetch online) ; un **encaissement local n'apparaît pas** avant l'ACK.

---

## 2. Bugs latents (défauts de correction, pas de simples manques)

| # | Bug | Preuve | Impact | Statut |
|---|---|---|---|---|
| **B1** | Genre `OTHER` non modélisé côté inscription (replié sur `MALE`) | `gender.dart` (enum 2 valeurs) ; `fromString` défaut→`male` ; `enrollment_confirm_draft_builder.dart:41` | Perte OTHER **en amont** (domaine), pas au builder | **Reclassé** : limite domaine déjà notée `OFFLINE.md §6` — voir §5 |
| **B2** | Curseur de pull `int` epoch côté Flutter vs **ISO-8601** côté back | `classroom_sync_api.dart:22` (`@Query int?`) ; `classroom_delta_model.dart` (`_asIntOrNull`) ; `sync_meta` `cursor INTEGER` | `serverCursor` ISO → `null` → **pull complet en boucle** ; `int` envoyé → `400` dès qu'un curseur réel est stocké | **Corrigé (Phase 0)** |
| **B3** | Discipline : refetch post-création via le BLoC **online** | `disciplinary_student_detail_page.dart:264-272` | Cas créé hors-ligne **invisible** | Ouvert (Phase 2) |
| **B4** | Présence : stockage « par exception » → 0 ligne = « tous présents » **=** « appel non fait » | `attendance_local_data_source.dart:81-98` | Ambiguïté d'état (AF-1 non tenu) ; taux 100 % ambigu | Ouvert (Phase 4) |
| **B5** | Outbox : pas de cap poison ; `deleteAcked()`/`pendingReadyForSchool()` jamais appelés | `sync_engine.dart:120-128` ; `outbox_dao.dart:40,117` | Entrée en échec `PENDING` **indéfiniment** ; ACKED s'accumulent ; garde tenant inactif | ✅ Phase 1 (cap poison + purge) ; tenant scope **différé** (voir SOC-3) |

---

## 3. Matrice d'écarts par module (vérifiée)

Sévérité : **P0** bloque l'offline-first · **P1** cœur · **P2** raffinement ·
⏳ = **attente backend V1.1 légitime** (ne rien forcer).

### Socle transverse
- `SOC-1` **P0** — ✅ **Phase 1** : orchestration de PULL livrée
  (`PullCoordinator` + `PullHandler`, déclenchée au retour online par
  `SyncStatusCubit`, curseur ISO via `SyncMetaDao`). **Classe** branchée
  (`ClassroomPullHandler`, résout l'année via bootstrap local). *Reste* :
  handlers Présence (client `@GET /sync/attendance` à créer) et
  Notes/Schedule (modules absents → Phase 3).
- `SOC-2` **P1** — ✅ **Phase 1** : cap poison-message (`maxAttempts` →
  `SYNC_ERROR`) + purge `deleteAcked()` en fin de flush.
- `SOC-3` **P1** — ⏸ **différé** : flush scopé tenant. Activer
  `pendingReadyForSchool` **filtrerait tout** aujourd'hui (les writers ne
  renseignent pas `school_id`, nullable) → à câbler **avec** l'écriture du
  `school_id` à l'enqueue, pas avant. Mono-établissement V1 : non bloquant.

### Inscription
- `ENR-1` **P1** — lectures locales : **listing + détail basculés en HYBRIDE
  local-first non-régressif** (superposition read-your-writes du listing +
  détail lecture seule d'un dossier local ; online autoritaire en repli). Reste
  : recherches nom/date/académique online, et RE/PRE (voir ENR-2).
- `ENR-2` **P1** — RE/PRE **basculés en draft local** ; wizard draft-par-étape
  + finalize agrégat unique, comme NEW. **Seed désormais lu DEPUIS LE LOCAL**
  (bascule dure, 2026-07-11) : RE ← `ref_previous_year_students`
  (`findReenrollmentCandidateByStudentId`, matricule → `source_ref` + matricule
  du brouillon, élève canonique conservé, année cible = bootstrap courant), PRE
  ← `ref_pre_enrollments` (`findPreEnrollmentById`, id conservé en enrollmentId
  + `source_ref`). `requestLoad` RE/PRE rendu inerte ; ⏳ tables VIDES tant que
  le pull dort (régression écran vide assumée par l'utilisateur).
- `ENR-3` **P2** — dashboard « Mon poste » local absent.
- `ENR-4` **P2** — éditique PDF provisoire + logique attente-ACK absentes.
- `ENR-5` — pulls référentiel/cohorte/pré-inscriptions/delta/snapshots : **côté
  client LIVRÉ et ALIGNÉ sur le contrat back livré** (`EnrollmentPullApi` +
  `EnrollmentRefDao` + 5 handlers sur le `PullCoordinator`, **pagination keyset
  opaque** — `cursor`/`nextCursor`/`nextWatermark`/`hasMore` + cohorte statique
  `cursorId`/`bootstrapComplete` — dans `sync_meta` ; ADR-008/009). Contrat =
  section Sync de `openApi.yaml` (n'est plus l'ancien `openapi_enrollment_sync`).
  Voir journal 2026-07-15.

### Facturation
- `FAC-1` **P1** — lectures créances/paiements **online** (solde optimiste ignoré).
- `FAC-2` **P1** — `initializeChargesForStudent` **jamais invoqué** par le wizard.
- `FAC-3` **P1** — méthode figée `CASH` + **surplus non modélisé** en avance
  (invariant `total == Σ allocations` non garanti).
- `FAC-4` **P2** — exigibilité locale codée mais non affichée.
- `FAC-5` **P2** — remap créance par `fee_code` au lieu de `fee_tariff_id`.
- `FAC-6` **P2** — soldes optimistes / fraîcheur non surfacés.
- `FAC-7` **P2** ⏳ — NP/RC définitif/RL-QT + pulls tariffs/ledger (attente back).

### Classe
- `CLS-1` **P1** — `ClassroomsSyncRequested` (pull livré) **jamais dispatché** UI
  → cache local vide.
- `CLS-2` **P1** — lectures classes/roster/recherche restées online.
- `CLS-3` **P1** — mismatch curseur int/ISO (= B2) — **corrigé Phase 0**.
- `CLS-4` **P2** — fraîcheur ADR-002 calculée mais non affichée.

### Présence
- `PRE-1` **P1** — réponse enrichie 200 (AG-3) **non consommée** (`markDaySynced`
  ne lit ni `id`/`version`/`updatedAt`).
- `PRE-2` **P1** — `GET /sync/attendance` livré mais **aucun client Flutter**.
- `PRE-3` **P1** — ✅ **Phase 2 (partiel)** : lecture de l'appel du jour basculée
  en LOCAL — source de `AttendanceBloc` redirigée `GetAttendanceUseCase` →
  `LoadDailyAttendanceUseCase` (roster local + exceptions). Reste : taux dérivé
  AF-3 (pas de surface UI → décision produit).
- `PRE-4` **P2** — ambiguïté « par exception » (= B4).
- `PRE-5` **P2** — taux dérivé en Dart (cosmétique, acceptable).

### Discipline
- `DIS-1` **P0** — lecture des cas restée online ; grand-livre local = code mort.
- `DIS-2` **P0** — refetch post-création online → cas invisible (= B3).
- `DIS-3` **P1** ⏳ — traitement régime C (update statut/sanction) **jamais
  déclenché** (écriture locale activable ; PUT `version`/LWW DG-2 = V1.1).
- `DIS-4` **P2** — garde anti-effacement sanction (DG-3) repose sur l'appelant.

### Notes/Bulletins + Emploi du temps
- `NOT-1` **P0** — **module entièrement absent** (ni online ni offline ; l'online
  vit sur `feat/academics` non mergée). Le back a **tout livré**. *(plus gros
  chantier)*
- `NOT-2..8` **P1/P2** — schéma sqflite, pull, écriture outbox, moyenne
  optimiste, `422 PERIODE_CLOSE`, cache Résultats/Bulletin : tout à créer.

---

## 4. Plan d'alignement — phasé par dépendances

### Phase 0 — Rétablir la vérité (fait) · ½ j
1. `app_constants.dart` — retirer « n'existe pas encore côté serveur »,
   documenter les endpoints V1.0 livrés.
2. `OFFLINE.md §4` — requalifier « Lecture = GARDÉE ONLINE » en dette (Phase 2).
3. **B2** — curseur `int` → **ISO-8601 String** (api/model/DAO/repo/outcome +
   schéma `sync_meta`).
4. **B1** — reclassé (limite domaine, voir §5), pas de correctif cosmétique.

### Phase 1 — Socle : orchestrer le PULL (`SOC-1`, prérequis de tout) · P0 — ✅ LIVRÉE
- ✅ `PullCoordinator` + `PullHandler` (`lib/core/offline/`) : registre par
  ressource, pré-garde connectivité, verrou anti-concurrence, isolation par
  handler. Déclenché au **retour online** par `SyncStatusCubit` (push → pull →
  refresh) ; curseur ISO via `SyncMetaDao`.
- ✅ `ClassroomPullHandler` branché (résout l'année via bootstrap local).
- ✅ Housekeeping outbox : cap poison (`maxAttempts` → `SYNC_ERROR`) +
  `deleteAcked()` en fin de flush.
- ⏭ **Reporté** : client `@GET /sync/attendance` + `AttendancePullHandler`
  (Présence) ; handlers Notes/Schedule (modules absents → Phase 3) ; flush scopé
  tenant (`SOC-3`, cf. ci-dessus).

### Phase 2 — Effondrer les « deux blocs » : lectures en local · P0/P1
> **Reconception (recon 4 agents, 2026-07-07)** : PAS un balayage uniforme. Une
> lecture ne peut passer en local que si le cache local **contient la donnée**.
> Seuls 2 modules sur 5 sont réellement basculables maintenant ; les 3 autres
> sont *gated* (régression sans pull, ou refonte requise).

**Basculables maintenant** (cache peuplé par un vrai pull) :
- **Classe** (`CLS-1/2`) — ✅ **FAIT (consultation)** : le roster d'une classe
  (page **liste**, CF3) se lit en LOCAL — `ClassroomBloc._onClassroomMembersRequested`
  redirigé vers `GetOfflineRosterUseCase` (pattern Présence, widgets inchangés ;
  handler **batch** et organisation **inchangés online**) + pull au montage +
  coordination `syncStatus` (échec=snackbar, succès=relecture). Organisation :
  le rappel d'effectif « non-affectés » (compteur + G/F) est maintenant
  **offline** (`GetUnassignedLevelEnrollmentsUseCase`) ; la distribution
  (écriture) et la réassignation restent **online par conception** (ADR-004,
  bouton désactivé hors-ligne). Stats école reste online par conception.
  `CLS-4` (fraîcheur affichée) non fait. Résidu : « cache absent » non
  distingué de « classe vide » (raffinement).
- **Présence** (`PRE-3`, lecture appel) — ✅ **FAIT** : source de `AttendanceBloc`
  redirigée `GetAttendanceUseCase` → `LoadDailyAttendanceUseCase` (pas de swap de
  BLoC — lecture entrelacée avec le brouillon éditable). L'appel du jour se lit
  du cache local (roster + exceptions). AF-3 (taux dérivé) reste non surfacé →
  décision produit. `GetAttendanceUseCase` conservé dormant.

**Gated (à NE PAS basculer maintenant)** :
- **Discipline** (`DIS-1`) — pas de pull → seuls les cas créés *localement*
  seraient visibles ⇒ **régression fonctionnelle** (cas serveur masqués).
  Acceptation PO requise. `DIS-2`/B3 (refetch post-création local) et `DIS-3`
  (déclencheur traitement) restent faisables **isolément**. Mapper
  `OfflineDisciplinaryCase→DisciplinaryCaseSummary` à créer (mapping statut
  lossy).
- **Facturation** (`FAC-1/4/6`) — pas de pull ledger (FF7) → élève pré-existant
  vide en local. Voie viable = **hybride** (online autoritaire + surimposition
  de l'optimiste local). Nécessite d'abord une **refonte de `FinanceOfflineState`**
  (mono-usage charges XOR paiements aujourd'hui). Effort **L**.
- **Inscription** (`ENR-1`) — pas de pull → basculer masquerait l'historique
  serveur ⇒ **prématuré**. Retenir **Option A** : lectures online conservées,
  *read-your-writes* local seulement (déjà partiel via refresh post-confirmation).
  Le code de lecture offline reste actif dormant (à activer au pull).

**Décisions produit à trancher avant d'exécuter** : (a) AF-3 surface du taux ;
(b) Discipline — accepter « cas serveur invisibles hors-ligne » ou attendre le
pull ; (c) Facturation — hybride B (recommandé) vs attendre FF7.

**Dette transverse relevée** : les states d'erreur offline ne portent qu'un
`String` (pas de `ErrorType`) → à typer pour la règle #10 ; chaînes FR en dur
dans les blocs offline à router en enum + l10n.

### Phase 3 — Fermer les modules manquants · P0 (gros)
`NOT-1..8` — créer Notes/Bulletins + Emploi du temps + couche offline
(dépend du merge `feat/academics` ; back prêt).

### Phase 4 — Correctifs money-grade & UX ciblés · P1/P2
`FAC-2/3/5`, `PRE-4` (corrige B4), `DIS-4`, dashboards « Mon poste »,
éditique PDF provisoire.

### Phase 5 — En attente backend V1.1 (⏳ ne rien forcer)
Agrégat `POST /sync/enrollments` (G1) → **RE/PRE draft + cohorte N-1**, pulls
finance, « jamais rejeté »/trop-perçu, discipline PUT `version`/LWW (DG-2),
filtrage `content` par rôle.

---

## 5. Note d'audit — correction sur B1 (genre OTHER)

L'audit initial listait « genre OTHER aplati en MALE » comme correctif rapide au
builder RE/PRE. **Vérification faite, c'est plus profond** : l'enum
`enrollment/domain/entities/gender.dart` **ne modélise que `male`/`female`** et
`Gender.fromString` replie déjà tout `OTHER` serveur sur `male` **à la lecture**.
Le ternaire `student.gender == Gender.female ? 'FEMALE' : 'MALE'` est donc
cohérent avec un enum à 2 valeurs — corriger le builder seul ne changerait rien.
Le vrai correctif = **ajouter `Gender.other`** au domaine + le propager
(`fromString`, picker UI, mapper draft NEW). C'est déjà noté « à raffiner » dans
`OFFLINE.md §6`. → **Traité comme tâche transverse (petite mais cross-cutting),
pas comme quick-fix Phase 0.**

---

## Journal
- **2026-07-29** — **Inscription · Réinscription (RE) alignée sur le cycle de
  status de Première inscription + bug de corruption corrigé + pastille à 3
  états (working tree).** Décision produit : un dossier RE (`enrollment_type=
  'RE_ENROLLMENT'`) portait `status='PRE_REGISTERED'` **constant** tout son
  cycle de vie (jamais `IN_PROGRESS`, ni même après push — `finalizeDraft` ne
  bascule que `sync_status`, jamais le `status` métier) ; il n'apparaissait
  donc jamais dans le listing Première inscription (filtre `status=
  IN_PROGRESS`). Nouvelle règle : RE suit **exactement** le même cycle que
  NEW (`IN_PROGRESS` en brouillon) → apparaît désormais aussi sur Première
  inscription (double affichage **assumé**, décision utilisateur), distingué
  par la pastille type existante (`StatusBadge.enrollmentReEnrollment`,
  pilotée par `enrollmentType`, pas par `status`). PRE_ENROLLMENT inchangé
  (`PRE_REGISTERED`). Changements : `EnrollmentConfirmDraftBuilder.
  fromReenrollmentCandidate` (seed cohorte) + `ReRegistrationDetailPolicy.
  draftStatus` (chaque save d'étape tant que DRAFT/PENDING_SYNC).
  **Bug de corruption trouvé et corrigé dans le même lot** : la reprise d'un
  brouillon local DRAFT depuis N'IMPORTE QUELLE page de listing route
  toujours vers l'origine `localDraftResume` (`EnrollmentListingPageScaffold`,
  sur `summary.isLocalDraft`) → `LocalDraftResumeDetailPolicy`, qui avait des
  défauts codés en dur `NEW_ENROLLMENT`/`IN_PROGRESS` **peu importe le vrai
  type du dossier repris**. Comme `EnrollmentDraftDao.insertDraftEnrollment`
  écrase `enrollment_type`/`status` **sans condition** (pas de COALESCE,
  contrairement à `school_level_id`), un simple re-save d'identité sur un
  brouillon RE/PRE repris via ce chemin corrompait silencieusement
  `enrollment_type` en `NEW_ENROLLMENT` — la pastille « Réinscription »
  aurait disparu à la première reprise. **Fix** : `LocalDraftResumeDetailPolicy`
  paramétrée avec le vrai `enrollmentType` (nouveau champ sur
  `EnrollmentDetailIntent`, porté par `EnrollmentSummary` au tap → query
  param) ; `draftStatus` **DÉRIVÉ du type** (switch `PRE_ENROLLMENT→
  PRE_REGISTERED, sinon IN_PROGRESS`), **jamais lu depuis un `status`
  persisté** — auto-guérit un brouillon RE legacy (créé avant ce changement,
  encore en `PRE_REGISTERED` en base) au prochain re-save au lieu de le
  laisser figé indéfiniment. **Revue adversariale (workflow 3 lenses →
  verify, 9 confirmés/9 corrigés)** : 2 MAJOR (le design initial — passthrough
  `status ?? super.draftStatus` — ne guérissait jamais le legacy, corrigé par
  la dérivation ci-dessus ; aucun test e2e du vrai point d'écriture
  `EnrollmentListingPageScaffold.onViewRequested`, ajouté
  `enrollment_listing_page_scaffold_test.dart` via vrai `GoRouter`), 2 MINOR
  (fixture de test trompeuse ; pas de test DB roundtrip seed→resume→re-save),
  5 NOTE (commentaires stale dans 5 fichiers prod + 2 tests ; code mort
  `FirstRegistrationDetailPolicy.status`/`isStepEditable` jamais consulté côté
  rendu pour l'origine `firstRegistration`, toujours court-circuité vers
  `LocalConsultationDetailPolicy`, cf. fix loading-infini du 2026-07-16
  ci-dessous).
  **Suite (retour utilisateur « petite régression » sur l'onglet
  Réinscription)** : en réalité pas une régression du changement ci-dessus —
  la pastille RE affichait un libellé **générique** « Réinscription » pour
  TOUT dossier RE (brouillon commencé ou finalisé confondus) depuis
  l'introduction même du pill (`629c0ec`, 16 juillet), jamais de distinction
  à 3 états. Ajout de la distinction, pilotée par l'axe `syncState`/
  `isLocalDraft` (indépendant du `status` métier, donc non affecté par le
  changement ci-dessus) dans les 2 widgets partagés (`EnrollmentResultCard`,
  `EnrollmentDataTable`) : **« À réinscrire »** (candidat N-1 non commencé,
  inchangé), **« En cours »** (brouillon local — réutilise
  `enrollmentStatusInProgress`), **« Réinscrit »** (finalisé/synchronisé,
  nouvelle clé l10n `enrollmentReRegisteredBadge`, FR+EN). `flutter gen-l10n`
  suivi de `dart format` sur les fichiers générés (le générateur produit un
  diff de reformatage massif non lié — nettoyé). `flutter analyze` clean,
  **529 tests enrollment verts** (+8 vs avant ce lot), suite complète
  **1983 tests verts** (2 échecs préexistants `test/widget_test.dart`, sans
  rapport, login/auth). **NON commité.**
- **2026-07-16** — **Inscription · DÉTAIL Première inscription = LECTURE SEULE
  LOCALE (fix loading infini, working tree).** Symptôme : ouvrir le détail d'un
  dossier depuis la Première inscription tournait en **spinner infini** au lieu
  de lire en local. Cause : le détail `firstRegistration` dépendait encore du
  **GET détail serveur** (`EnrollmentBloc` → `EnrollmentDetailRequested`) ; la
  sonde locale (`LoadLocalEnrollmentDetail`) ne basculait en lecture seule que
  pour les écritures **non synchronisées** (`isUnsyncedLocalWrite`). Or le
  listing est désormais **100 % local** et l'agrégat complet est **hydraté en
  `SYNCED`** par le pull snapshot → pour un dossier `SYNCED` (cas normal), la
  page retombait sur le GET serveur (hors-ligne : pend → loading infini ; en
  ligne : latence). Pire, la « reprise éditable » d'un `SYNCED IN_PROGRESS`
  documentée était **déjà cassée** : `seedDraft` refuse les lignes non-DRAFT
  (`enrollment_draft_dao.dart:118`) et toute la machinerie d'écriture est gardée
  sur `sync_status = DRAFT`. **Décision (utilisateur) : consultation locale
  seule** — l'édition offline d'un dossier synchronisé (« checkout » agrégat
  `SYNCED→DRAFT`) est **différée**. **Fix** (page uniquement, policy et modèle
  d'écriture **inchangés**, tous les tests policy verrouillés restent verts) :
  (i) `_initializeJourney` — `firstRegistration` sonde le local puis `return`
  (aucun GET) ; (ii) `_onLocalDetail` — bascule `_localReadOnly` pour
  `firstRegistration` **quel que soit l'axe synchro** ; (iii) nouvelle vue
  `_buildFirstRegistrationConsultation` (chargement/erreur pilotés par le bloc
  offline, « Réessayer » re-sonde) ; (iv) libellé parcours = `journeyModeView`
  (« Consulter »). Couvre aussi la **Réinscription** (dossiers finalisés →
  origine `firstRegistration`, cf. son `detailIntentFactory`). Les brouillons
  `DRAFT` éditables restent routés en amont vers `localDraftResume` (scaffold).
  Test miroir : `enrollment_detail_page_first_registration_test.dart` (sonde
  locale + **aucun GET serveur** + erreur→retry). `flutter analyze` clean,
  **411 tests enrollment verts**. **NON commité.**
- **2026-07-15** — **Inscription · MIGRATION CURSEUR KEYSET (contrat back livré,
  working tree).** Le back a **livré** les endpoints de sync d'inscription dans
  le vrai `openApi.yaml` (section Sync) mais **raffiné le mécanisme de pull** :
  on passe du curseur **ISO `updatedSince`/`serverTime`** (mono-page) à une
  pagination **keyset opaque** (ADR-008/009). Enveloppe `KeysetPage` :
  `{ items, nextCursor?, nextWatermark?, hasMore, totalCount?, serverTime }` —
  `nextCursor` présent SSI `hasMore` (progression **dans** le cycle, mémorisée à
  chaque page → reprise), `nextWatermark` présent SSI dernière page NON vide
  (début du prochain cycle, marge Δ appliquée) ; `hasMore=false` ≠ 304 (dernière
  page) ; `cursor` absent = bootstrap (fin de la sentinelle epoch). La **cohorte
  N-1** a une pagination **statique distincte** : `cursorId` (= studentId) →
  `nextCursorId` + `bootstrapComplete` (ni watermark ni 304) — parcourue
  **jusqu'à `bootstrapComplete`** puis remplacée d'un **bloc atomique** ; un
  roster interrompu (réseau/contrat violé) est **jeté** (ni remplacement ni
  avance du curseur → « jamais un demi-roster »). Le **référentiel** reste un
  bundle full always-200 ; **bug latent corrigé** : `RefAcademicYearDto` lisait
  `isCurrent` alors que la clé wire est **`current`** (toute année devenait
  non-courante hors-ligne). Le **PUSH** (`POST /sync/enrollments`,
  `EnrollmentAggregateRequest/Response`) et **tous les DTO d'items** étaient déjà
  alignés — aucun changement. **Changements** : nouvel `keyset_page.dart`
  (`KeysetPageEnvelope` + `cursorToPersist` = `hasMore ? nextCursor :
  nextWatermark` + interface `KeysetPageDto<I>`) ; 3 pages delta/snapshot/pré
  passent à l'enveloppe, cohorte → `nextCursorId`/`bootstrapComplete` ;
  `enrollment_pull_api` : `updatedSince`→`cursor` + `limit` (+ `cursorId` cohorte)
  → regen `.g.dart` ; `enrollment_pull_repository_impl` : `_conditionalPull`
  mono-page remplacé par `_keysetPull` (boucle paginée, curseur mémorisé par
  page, watermark en fin, **garde anti-boucle** `nextCursor==null||==sent` contre
  un serveur non-avançant — cf. historique verrou sqflite), `_cohortPull`
  (boucle→`bootstrapComplete`→swap atomique), référentiel always-200 dédié ;
  docs `sync_meta_dao`/`enrollment_pull_outcome`/repo interface alignées (jeton
  opaque, non ISO). Tests réécrits (modèles : enveloppe + `current` + cohorte
  statique ; repo : keyset + **multi-pages + reprise après interruption +
  watermark + page-vide-conserve + cohorte multi-pages/interrompue/incomplète +
  bootstrap null + garde non-avançant + 304**). `flutter analyze` clean, **996
  tests verts**, `build_runner` relancé. **Revue adversariale (workflow 6 dims →
  verify, 9 confirmés) : 1 vrai défaut = la garde anti-boucle avait été ajoutée
  à `_keysetPull` mais PAS à `_cohortPull` (asymétrie) → `nextCursorId` non-
  avançant = boucle infinie + `all` en OOM ; corrigé (`|| body.nextCursorId ==
  cursorId`) + test de non-régression borné en timeout. + 3 durcissements de test
  (curseur avancé sur delta sans effet, curseur conservé sur snapshot 304) et
  nits de doc. DIFFÉRÉS (pré-existants, hors périmètre migration) : nullabilité
  `ParentSnapshotDto`/`birthPlace` (le contrat `ParentDetailDto` ne déclare aucun
  champ requis → un tuteur mal formé casterait `as String` et avorterait la page
  d'hydratation).** **AFFINAGE (retour utilisateur « le N-1 n'évolue plus une
  fois chargé ») : SKIP-SI-COMPLET de la cohorte** — `syncReenrollmentCohort`
  court-circuite sans réseau (`notModified`) dès `getCursor(cohortResource) !=
  null` (sûr : curseur posé QU'au succès total). Ressource STATIQUE gelée sur la
  saison → re-scanner à chaque montage du scope (`initState`, chaque bascule
  Pré/Ré/Première) était du gaspillage. **Rollover d'année — VÉRIFIÉ + CORRIGÉ** :
  audit du cycle de vie de la base offline = elle **survit** au rollover (fichier
  à nom FIXE `AppConstants.offlineDbName` non scopé année/école ; clé SQLCipher
  persistée et réutilisée ; `clearSession`/logout n'efface que 8 clés de session,
  PAS la clé DB ni `sync_meta` ; aucun `deleteDatabase`/reset ; migrations
  gardées par version de schéma). Donc un marqueur cohorte keyé par ressource
  servirait l'ancien roster N-1 indéfiniment. **Fix : marqueur SCOPÉ par l'année
  académique courante** — `EnrollmentRefDao.findCurrentAcademicYearId()`
  (`ref_academic_years WHERE is_current=1`, peuplé par le pull référentiel qui
  précède) + clé `enrollment_reenrollment_cohort:<yearId>` (repli non scopé si
  année non résolue). Rollover → nouvelle clé → re-pull auto ; vieux marqueurs =
  lignes mortes inoffensives. Le fetch garde `previousAcademicYearId=null` (défaut
  serveur, inchangé) — l'année ne sert qu'à keyer le cache local. Tests : skip
  scopé, skip repli, rollover→re-pull+nouveau marqueur, DAO
  `findCurrentAcademicYearId`. **1001 tests verts.** **NON commité.**
- **2026-07-11** — **Inscription · SEED RE/PRE DEPUIS LE LOCAL (bascule dure,
  working tree).** **Décision utilisateur** : « passe au seed depuis le local »,
  bascule **dure** (pas d'hybride) — régression écran vide RE/PRE assumée tant
  que le pull dort (les tables cohorte/préinscriptions sont VIDES en prod) ;
  l'objectif est la **correction du câblage** pour l'arrivée du pull. Chaîne :
  2 entités (`ReenrollmentCandidate`/`PreEnrollmentCandidate`) → 2 lectures
  `EnrollmentRefDao` (`findReenrollmentCandidateByStudentId`/`findPreEnrollmentById`,
  `null` = table non peuplée) → repo `getReenrollmentCandidate`/`getPreEnrollment`
  (`NotFoundFailure` si absent) → 2 usecases → 2 events
  `SeedFromCohortRequested`/`SeedFromPreEnrollmentRequested` + handlers
  (`_onSeedFromCohort`/`_onSeedFromPreEnrollment`, tail `_seedAndEmit` factorisé)
  → builder `fromReenrollmentCandidate`/`fromPreEnrollment`. **Invariants** : RE
  = studentId canonique conservé, **enrollmentId null** (nouveau dossier N),
  matricule → `matriculationNumber` **et** `source_ref`, année cible = bootstrap
  courant (PAS l'année N-1 de la cohorte) ; PRE = studentId null (élève créé au
  seed), **id préinscription conservé** en enrollmentId + `source_ref`,
  `desiredSchoolLevelId` → niveau visé. Tuteur dénormalisé (nom+tél) → 0/1
  `ConfirmParentDraft` (sans tél = aucun tuteur, clé dédup G3) ; genre normalisé
  MALE|FEMALE|OTHER (défaut MALE, cf. B1). **Page/policy** : `seedsFromLocalRef`
  (RE/PRE=true), `requestLoad` RE/PRE **inerte**, seed dispatché en **post-frame**
  au chargement du bootstrap courant (garde `_seededIntent`, couvre bootstrap
  déjà en cache) ; `_buildLocalDraftPending` suit désormais `EnrollmentDraftError`
  du bloc offline (cohorte vide → erreur + retry). Reprise firstRegistration
  (seed serveur) et détail read-your-writes lecture seule **inchangés**. Tests :
  builder (RE/PRE, matricule→sourceRef, tuteur split/sans-tél, genre défaut, PRE
  id/studentId/dob), handlers bloc (succès + cohorte/snapshot vides → Error),
  repo reads (found/NotFound), RefDao ffi reads, policy (`seedsFromLocalRef` +
  requestLoad inerte). **Revue adversariale (workflow 4 dims → verify) : 3
  confirmés, tous des TROUS DE TEST au niveau PAGE** (aucun widget test
  n'existait pour `EnrollmentDetailPage`) — comblés par un nouveau
  `enrollment_detail_page_seed_test.dart` (3 cas : RE→cohorte/PRE→préinscription
  avec studentId/id de l'intent + **année COURANTE** ; échec seed → écran
  d'erreur + « Réessayer » qui re-dispatche). Mutants vérifiés tués (dont le
  reset `_seededIntent` du retry, prouvé par mutation puis reverté). `flutter
  analyze` clean, **934 tests verts**, format conforme. **NON commité.**
- **2026-07-11** — **Inscription · étape (c) redirect LECTURE HYBRIDE (working
  tree).** Sur demande utilisateur (« bascule-les maintenant »), les lectures
  passent en **local-first NON régressif** malgré le pull dormant : là où le
  cache local est vide (pull absent) on retombe sur l'online → jamais d'écran
  vide, et 100 % local automatiquement quand le pull sera livré. **(1) Listing
  read-your-writes** : `EnrollmentBloc` reçoit un `GetLocalEnrollmentsUseCase?`
  optionnel ; `_withLocalOverlay` **superpose** les dossiers LOCAUX non
  synchronisés (`pendingSync`/`syncError`) en tête de la liste serveur —
  uniquement `byStatus` page 0, dédup par `enrollmentId`, total ajusté,
  best-effort (échec local ignoré). Mapper `local_enrollment_summary_mapper`.
  DI : `localEnrollments` résolu paresseusement. **(2) Détail local-first** :
  pour l'origine `firstRegistration` (listing), la page sonde le cache local
  (`LoadLocalEnrollmentDetail`) ; un dossier local **non synchronisé**
  (`pendingSync`/`syncError`, càd exactement les items de la superposition) →
  **vue LECTURE SEULE** (`_buildLocalReadOnly`, mapper local→detail + bootstrap,
  stepper via `LocalConsultationDetailPolicy`), prioritaire sur draft/serveur ;
  un dossier `SYNCED` (autoritatif serveur) ou NotFound → chemin online/reprise
  inchangé. **⚠️ SUPERSÉDÉ le 2026-07-16 (voir entrée dédiée)** : le GET détail
  serveur pour `firstRegistration` est supprimé → **tout** dossier de la Première
  inscription (y compris `SYNCED`) est désormais servi en **lecture seule depuis
  le local** ; l'édition d'un dossier déjà synchronisé est différée (le modèle
  d'écriture — `seedDraft` — refuse les lignes non-DRAFT). Le résumé traite
  `isReadOnlyConsultation` comme « déjà clos »
  (retour, **jamais finalize** — généralise la garde `status==completed`).
  **Source de vérité unique** `isUnsyncedLocalWrite(SyncState)` partagée par le
  filtre d'overlay et la bascule lecture seule (ne peuvent plus diverger).
  **RE/PRE NON basculés** : cohorte `ref_previous_year_students` /
  `ref_pre_enrollments` VIDES (pull dormant) → les brancher maintenant =
  **dead code** ; restent online, à faire avec le pull.
  **Revue adversariale (9 agents, 3 confirmés minor, 2 réfutés) → corrigés :**
  (i) **détail read-only borné aux non-synchronisés** — auparavant tout dossier
  local non-DRAFT (dont `SYNCED` gardant `status=IN_PROGRESS`, car `finalizeDraft`
  ne bascule que `sync_status`) était figé en lecture seule, ce qui **bloquait la
  reprise** d'un dossier créé hors-ligne puis synchronisé (contredit la règle
  `FirstRegistration IN_PROGRESS = éditable`) ; (ii) **flash d'écran d'erreur**
  — le GET serveur concurrent (voué au 404 pour un id client) pouvait peindre
  l'erreur une frame avant la lecture locale → masque `_probingLocalDetail` le
  temps de la sonde ; (iii/iv) **2 trous de mutation-testing comblés** — garde
  read-only du résumé (test handler + GoRouter/ScaffoldMessenger) et garde
  `query.type != byStatus` de l'overlay (test recherche par nom → `verifyNever`).
  Tests : overlay bloc (dédup/page>0/**non-byStatus**/best-effort), mapper +
  **prédicat `isUnsyncedLocalWrite`**, **garde read-only summary**.
  `flutter analyze` clean, **908 tests verts**, format conforme. **NON commité.**
- **2026-07-10** — **Inscription · étape (c) partie NETTOYAGE (working tree).**
  **Décision utilisateur** : les redirects de LECTURE (RE←cohorte locale
  `ref_previous_year_students`, PRE←`ref_pre_enrollments`, listing/détail←local)
  sont **DIFFÉRÉS** — le pull backend `openapi_enrollment_sync.yaml` n'est pas
  livré, donc ces tables sont VIDES en prod ; basculer afficherait des écrans
  vides (régression). Les lectures RE/PRE/listing restent **online** (plein,
  zéro régression). **Fait = purge sûre** : (1) **one-shot
  `ConfirmLocalEnrollment`** entièrement retiré (mort depuis la convergence b —
  jamais dispatché) : event + états `EnrollmentOfflineConfirming`/
  `…ConfirmedPendingSync` + handler `_onConfirm` du bloc + `ConfirmEnrollmentUseCase`
  + `EnrollmentCommitDao` (fichiers supprimés) + `repo.confirmEnrollment` + DI ;
  fixtures de tests réécrites sur le vrai chemin draft→finalize
  (`seedPendingEnrollment`). (2) **branches online DORMANTES des 5 widgets
  d'étape** (personal_info/address/previous_academic/target_academic/guardian +
  personal_info_step_body) : param `useOfflineDraft` supprimé (le save passe
  TOUJOURS par le brouillon local ; consultation = `isEditable` false, pas de
  save), `_studentBloc`/`_parentBloc` (getIt) + `BlocProvider`/`BlocConsumer`
  inertes retirés, dispatch online morts (`StudentAddressUpdateRequested`,
  `StudentAcademicInfoUpdateRequested`, `EnrollmentAcademicInfoUpdateRequested`,
  `ParentCreate/Update/UnlinkRequested`) + machinerie séquentielle du guardian
  (`_queueAndStartSave`/`_dispatchNextParentUpdate`/`_replaceDraftWithCreated`/
  `_markParentAsSaved`) supprimés ; `EnrollmentDraftStepSaveListener` toujours
  actif (`enabled: true`) ; `isLoading` recâblé sur `_isSaving`/`_isBatchSaving`.
  Suppression d'un tuteur = retrait LOCAL immédiat + ré-écriture du brouillon
  (plus d'unlink online). Test `guardian_delete_flow` réécrit. `flutter analyze`
  clean, **895 tests verts**, format conforme. **NON commité.** **RESTE (c)
  gated backend** : redirects lecture RE/PRE/listing + option hybride
  read-your-writes — à faire quand le back livre le pull.
- **2026-07-09** — **Inscription · convergence 3 blocs→1 + wizard draft-par-étape
  RE/PRE (ENR-1/ENR-2, étape b)** (working tree). **Bloc UNIQUE** :
  `EnrollmentDraftBloc` fusionné dans `EnrollmentOfflineBloc` (événements/états
  draft ré-affiliés à la famille offline, 1 provider de moins dans le feature
  scope). **Wizard offline-first généralisé à TOUS les flux d'édition** (NEW,
  RE, PRE, reprise IN_PROGRESS) via la policy : `usesLocalDraft`/
  `requiresDraftSeed`/`draftEnrollmentType`/`draftStatus`/`seedEnrollmentId`/
  `seedSourceRef` (le flag n'est plus `origin == newFirstRegistration`). RE/PRE/
  reprise = le détail serveur est **photographié en brouillon local (seed)** au
  chargement (`EnrollmentConfirmDraftBuilder.fromDetail` → `SeedDraftRequested`,
  garde une-seule-fois `_seededIntent`), puis édité par étape ; la validation
  finalise **le même chemin `FinalizeDraftRequested`** pour toutes les origines
  (le one-shot `ConfirmLocalEnrollment` n'est plus dispatché). **`source_ref`
  bout en bout** (schéma v3 + migration `ALTER`, modèle/payload outbox/agrégat).
  **Écritures draft PRÉSERVANTES** (re-save d'identité n'écrase pas adresse/
  matricule/antécédents/source_ref seedés). **Purge** de la chaîne online morte
  (create + status-update : bloc/event/state, DI, usecases, repo/datasource/
  modèles data, 2 endpoints + 2 clés l10n orphelins). **Pull au montage** du
  module (`EnrollmentPullRequested`). Revue adversariale (workflow, coupée par
  session-limit → jugée à la main) : **1 bug critique corrigé** (re-save
  d'identité RE/PRE requalifiait le brouillon en NEW_ENROLLMENT/IN_PROGRESS →
  type/statut désormais via policy) + **1 latent corrigé** (reprise
  firstRegistration : studentId canonique conservé, plus de doublon élève au
  push). Tests ajoutés : builder `fromDetail` (4 origines + sourceRef +
  projection), migration v1/v2→v3 (`migrateOfflineDatabase` extraite, ffi), RE
  dispatch identité, seedDraft DAO+repo, bloc fusionné. `flutter analyze`
  clean, **896 tests verts**, format conforme. **NON commité.** RESTE (étape c)
  : redirect lecture RE←cohorte locale / PRE←préinscriptions (sourceRef RE =
  matricule alors disponible) ; purge des branches online dormantes des step
  widgets address/previous/target/guardian ; retrait du one-shot
  `ConfirmLocalEnrollment`. Tout reste dormant réseau tant que le back
  n'implémente pas `openapi_enrollment_sync.yaml`.
- **2026-07-08** — **Inscription · verticale PULL livrée côté client (ENR-5)**
  (working tree). `EnrollmentRefDao` (upserts `ref_*` + réconciliation delta
  `enrollments` UPDATE-only/LWW), `EnrollmentPullRepository(+Impl)` (squelette
  conditionnel partagé : jeton **ETag** pour référentiel/cohorte, **`serverTime`
  → `updatedSince`** pour préinscriptions/delta, 304 via DioException, curseur
  jamais avancé sur échec d'apply), `EnrollmentPullHandler` (classe paramétrée,
  4 ressources) enregistrés sur le `PullCoordinator` en DI. Grille tarifaire du
  bundle → `FinanceLocalDao.replaceTariffsForYears` (seam, purge scopée année).
  Revue adversariale (workflow 5 dimensions + réfutation, 2 findings prouvés
  par mutation testing) → correctifs : **purge scopée du snapshot référentiel**
  (fantômes serveur évacués, `ref_academic_years` jamais purgée — N-1 survit),
  wipe cohorte compté (`notModified` honnête), sentinelle **epoch** au 1ᵉʳ pull
  delta (chemin partagé avec la liste online, ADR-008), DTO delta
  `academicYearId` nullable (contrat), matricule delta répercuté sur l'élève,
  cycle réaligné via `ref_school_levels`, LWW documenté inter-horloges.
  Dormant tant que le back n'implémente pas le contrat (les handlers tournent :
  404/parse → `PullOutcome.error` isolé, sans effet local). Déclenchement au
  montage + lectures RE/PRE = avec la convergence 3 blocs→1 (étape suivante).
  `flutter analyze` clean, **869 tests verts** (+44), format conforme.
- **2026-07-08** — **Inscription · contrat sync réaligné + schéma v2** (working
  tree, avant la verticale pull). Source de vérité = `openapi_enrollment_sync.yaml`
  (transport sync NON livré back ; primitives G2/G3/G4 seules). Schéma **v2 : 14
  tables** (+5 `ref_*` dont cohorte RE et préinscriptions) + migration
  `onUpgrade` idempotente. PUSH réaligné : agrégat `POST /api/v1/enrollments`
  (`EnrollmentAggregateRequest/Response`, 201/200→ACK, 422→`SYNC_ERROR`).
  Refactor anti-god-DAO : `EnrollmentLocalDao` (753 l) → 4 DAO par
  responsabilité (read/draft/commit/ack) + support partagé ; repo = coordinateur.
  Modèles pull éclatés 1 fichier/endpoint + barrels. **825 tests verts** alors.
- **2026-07-07** — **Phase 2 · Classe (consultation) livrée** (working tree).
  Roster d'une classe (page liste, CF3) lu en LOCAL : `ClassroomBloc` handler
  single redirigé vers `GetOfflineRosterUseCase` (batch/organisation intacts
  online) ; pull `ClassroomsSyncRequested` au montage (bootstrap→success) pour
  peupler `ref_classroom_members` ; coordination `ClassroomOfflineBloc.syncStatus`
  (échec=snackbar parité online, succès=relecture). Revue adverse : 1 bug moyen
  (pull en échec avalé → roster vide silencieux) **corrigé** (snackbar + relecture) ;
  reste sain. Test bloc single migré (offline roster + StorageFailure→storage).
  `flutter analyze` clean, **817 tests verts**, format conforme.
- **2026-07-07** — **Phase 2 · Présence livrée** (working tree). Lecture de
  l'appel basculée en local : `AttendanceBloc` lit `LoadDailyAttendanceUseCase`
  (offline) au lieu de `GetAttendanceUseCase` (online) — signature identique,
  drop-in. DI repointée, test bloc migré + cas `StorageFailure→storage` ajouté.
  **Nettoyage** : retrait du chemin d'écriture online mort (`AttendanceSaveRequested`
  → `UpdateAttendanceUseCase`) de `AttendanceBloc`/event/DI/test — l'écriture ne
  vit plus que dans `AttendanceOfflineBloc` (overlay). `saveStatus`/`saveErrorType`
  laissés (gelés, lus par l'UI) = dette vestigiale notée. `flutter analyze` clean,
  **817 tests verts**, format conforme. AF-3 (taux) non fait (décision produit).
- **2026-07-07** — **Recon Phase 2** (4 agents parallèles, lecture seule). Constat
  reconfigurant : Phase 2 ≠ balayage uniforme. Basculables maintenant = **Classe**
  + **Présence** (cache peuplé par un vrai pull). *Gated* = Discipline (régression
  sans pull), Facturation (hybride + refonte state), Inscription (prématuré →
  Option A). Phase 3 **bloquée** (feat/academics non mergée). Plan mis à jour
  ci-dessus. Aucun code exécuté à cette étape.
- **2026-07-07** — **Phase 1 socle livrée** (working tree). `PullCoordinator` +
  `PullHandler` (SOC-1) déclenchés au retour online par `SyncStatusCubit` ;
  `ClassroomPullHandler` (année via bootstrap local) ; housekeeping outbox cap
  poison + purge (SOC-2). `SOC-3` (tenant) différé (writers ne posent pas
  `school_id`). Revue adversariale : 0 bug dur ; 2 notes bénignes documentées.
  `flutter analyze` clean, **818 tests verts** (+15), format conforme.
- **2026-07-07** — Création + **Phase 0 livrée**. Audit 7 modules (14 agents,
  0 erreur, écarts vérifiés en contradictoire). Phase 0 : doc-vérité
  (`app_constants`, `OFFLINE.md §4/§6`) + **B2** (curseur `int`→ISO String :
  `sync_meta` DDL, `SyncMetaDao`, `ClassroomSyncApi` + `.g.dart`,
  `ClassroomDeltaModel`, `ClassroomSyncOutcome` + tests). Validé : `build_runner`
  OK, `flutter analyze` clean, **803 tests verts**, `dart format` conforme.
  **NB** : `finance_pull_models.serverCursor` reste `int` (même dette B2, pull
  dormant V1.1) — à passer en ISO au branchement du pull finance.
