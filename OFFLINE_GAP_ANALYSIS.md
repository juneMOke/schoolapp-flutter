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
| Inscription | `EnrollmentBloc` | `EnrollmentOfflineBloc` + `EnrollmentDraftBloc` |

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
- `ENR-1` **P1** — lectures locales listes/détail/recherche **jamais branchées**.
- `ENR-2` **P1** ⏳ — RE/PRE restent online (draft local faisable ; **cohorte N-1
  = attente back G1**).
- `ENR-3` **P2** — dashboard « Mon poste » local absent.
- `ENR-4` **P2** — éditique PDF provisoire + logique attente-ACK absentes.
- `ENR-5` **P2** ⏳ — pulls référentiel/cohorte/pré-inscriptions (attente back).

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
  coordination `syncStatus` (échec=snackbar, succès=relecture). Restent **online
  par conception** : organisation/répartition, `unassignedEnrollments`, stats
  école. `CLS-4` (fraîcheur affichée) non fait. Résidu : « cache absent » non
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
