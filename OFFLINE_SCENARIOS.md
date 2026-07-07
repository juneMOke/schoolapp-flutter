# OFFLINE_SCENARIOS — scénarios offline bout en bout, par module

> Décrit **le cycle complet lecture / écriture / flush (push) / pull** de chaque
> module offline-first, tel qu'implémenté dans le code (pas la cible théorique).
> Compagnon de `OFFLINE.md` (choix d'archi) et `OFFLINE_GAP_ANALYSIS.md` (dette).
> Socle : `SyncEngine` (push outbox) + `PullCoordinator` (pull delta) — cf.
> `OFFLINE.md §1`.

---

## Rappel socle (commun à tous les modules)

- **Écriture** = transaction locale (sqflite chiffré) + **1 entrée `outbox`**.
  Retour immédiat, zéro réseau au geste. `SyncStatusCubit.notifyLocalWrite()`
  allume la pastille et déclenche un flush opportuniste.
- **Flush (push)** = `SyncEngine.flush()`, déclenché **au retour online** et
  **après chaque écriture locale**. Vide l'outbox en **FIFO**, une tentative par
  entrée, backoff exponentiel sur erreur, plafond poison. **Aucun timer** : les
  flushs sont opportunistes.
- **Pull (delta)** = `PullCoordinator.pullAll()`, déclenché **au retour online**
  (après le flush). Chaque `PullHandler` tire sa ressource (curseur ISO via
  `SyncMetaDao`, `304` si rien de neuf) et peuple le cache local.
- **Ordre au retour online** (`SyncStatusCubit._syncOnReconnect`) :
  **flush (push) → pull → refresh pastille**.

### Comportement du flush en cas d'erreur — **important**

`SyncEngine.flush()` :
1. **Verrou** `_flushing` (un seul flush à la fois ; concurrent = `skipped`).
2. **Pré-garde radio** : hors-ligne → `offline`, rien n'est touché.
3. `pendingReady(now, limit: 50)` : entrées `PENDING` dont `next_attempt_at <= now`,
   triées **FIFO** (`created_at, rowid`).
4. **Boucle, dans l'ordre. Chaque entrée est tentée EXACTEMENT UNE FOIS :**
   | Issue du handler | Action | Suite |
   |---|---|---|
   | **acked** (2xx) | `markAcked` | purgée en fin de flush (`deleteAcked`) |
   | **retry** (réseau / 5xx / le handler lève) | `reschedule` : `attempts++`, `next_attempt_at = now + backoff`, reste `PENDING` | **passe à l'entrée suivante** |
   | **failed** (rejet métier) | `markSyncError` (terminal) | surfacé « conflit », pas de rejeu auto |

**On NE réessaie PAS la même ligne N fois avant de passer à la suivante.** Un
flush = une passe, une tentative par entrée. Les « N essais » se produisent sur
des **flushs ultérieurs distincts** :
- l'entrée reprogrammée porte une **barrière `next_attempt_at`** dans le futur
  (backoff **1s → 2s → 4s → … plafonné 5 min**) ; aucun flush ne la reprend tant
  que `now` ne l'a pas dépassée (`pendingReady` la filtre) ;
- un flush ultérieur (autre reconnexion / autre écriture, barrière passée) la
  retente **une fois de plus** ; backoff croissant ;
- jusqu'au **plafond poison `maxAttempts = 50`** → au-delà, `SYNC_ERROR`
  **terminal** (surfacé « conflit », recouvrement = ré-écriture).

Conséquences : une entrée en retry **ne bloque pas** les suivantes ; le FIFO
garantit seulement l'ordre de *tentative* (utile pour les dépendances
ENROLLMENT→PAYMENT) ; **pas de timer** → une entrée reprogrammée attend le
prochain déclencheur *et* l'échéance du backoff ; **idempotence** garantie (clé
naturelle / id client + LWW) → un re-flush ne double jamais.

---

## Module Présence (appel du jour)

**État : lecture ✅ offline · écriture ✅ offline · pull = via Classe · AF-3 (taux) non fait.**

### 1. Lecture — afficher l'appel
`PresencesPage._handleSearch` → `AttendanceFetchRequested` sur **`AttendanceBloc`**
→ **`LoadDailyAttendanceUseCase`** → `AttendanceOfflineRepository.loadDailyAttendance` :
- roster local `ref_classroom_members WHERE classroom_id=? AND status='ACTIVE'`
  (peuplé par le **pull Classe**) ;
- exceptions locales `attendance_records` pour ce (classe, date, année) ;
- **fusion** : tout élève « présent » par défaut, écrasé par une ligne d'absence
  locale. Renvoie `List<AttendanceRecord>` → `draftRows` éditables.

Zéro réseau. Roster vide (pas de pull encore) → liste vide → renvoi Composition.

### 2. Écriture — confirmer l'appel
Édition en mémoire (aucune écriture). Confirmation → `attendance_save_overlay`
→ **`RecordDailyAttendanceRequested`** sur **`AttendanceOfflineBloc`** (liste
complète). Transaction : UPSERT `attendance_records` **par exception** (seules
les absences deviennent des lignes, `updated_at=now` = arbitre LWW) + UPSERT
**`outbox`** (`aggregateType=ATTENDANCE`, **id déterministe par (classe, date,
année)** → **coalescé** : re-confirmer le même jour = 1 entrée). Émet
`PendingSync` → overlay succès + `notifyLocalWrite()`.

### 3. Flush — pousser
`AttendanceOutboxHandler` → `POST /api/v1/attendances` (upsert clé naturelle +
LWW `updatedAt`). acked → `markDaySynced` (bascule `sync_status` ; réponse
enrichie AG-3 non consommée = PRE-1 différé) ; retry/failed → cf. socle ci-dessus.

### 4. Pull
**Pas de pull Présence dédié** (PRE-2 différé : pas de `GET /sync/attendance`).
La lecture dépend du **pull Classe** (`ClassroomPullHandler` →
`GET /api/v1/sync/classrooms` → upsert `ref_classroom_members`, le roster). Les
lignes de présence ne sont pas re-tirées (écriture-seule + locale).

### Cycle en une ligne
Lire local (roster + exceptions) → éditer en mémoire → confirmer = écrire local
+ 1 entrée outbox coalescée → au retour online : flush (1 tentative/entrée,
sinon backoff+poison) puis pull Classe (roster frais).

### Notes d'implémentation
- L'écriture n'a **qu'un** chemin (offline, `AttendanceOfflineBloc`). L'ancien
  chemin online (`AttendanceSaveRequested` → `UpdateAttendanceUseCase`) a été
  **retiré** d'`AttendanceBloc`.
- Dette vestigiale : `saveStatus`/`saveErrorType` de `AttendanceState` restent
  (gelés à `initial`, lus par quelques conditions UI toujours fausses) — nettoyage
  d'état séparé, non fait.
- AF-3 (taux dérivé local) : implémenté côté repo mais **aucune surface UI** →
  décision produit.

---

## Module Classe (consultation)

**État : lecture ⏳ à basculer (approche arrêtée) · écriture (réassignation) ✅ online · pull ✅ (socle) mais non déclenché à la demande.**

### Surfaces et périmètre
Le module a 3 surfaces distinctes ; **seule la consultation** est cible offline (CF3) :
| Surface | Fichier | Régime |
|---|---|---|
| **Consultation** (chercher une classe → roster, recherche nominale) | `classes_list_page.dart` | **cible offline** (roster local) |
| **Organisation / répartition** (distribution, non-affectés, réassignation) | `classes_organisation_page.dart` | **online** (CF4/CF5 : `distributionOverview` + `unassignedEnrollments` non représentables offline) |
| **Stats école** | `classes_stats_dashboard_page.dart` | **online** (agrégat serveur, ADR-004) |

### 1. Lecture — consultation d'un roster (cible)
Aujourd'hui : `classes_list_page._handleSearch` (classe ciblée) → `ClassroomMembersRequested(classroomId, academicYearId)` sur **`ClassroomBloc`** → `GetClassroomMembersUseCase` (**online**, `ClassroomRepository`) → `state.members` (`List<ClassroomMember>`) → `ClassesListClassroomResults` (recherche nominale = `filterMembers` côté client).

Cible : **rediriger la source** du handler single `_onClassroomMembersRequested` vers `ClassroomOfflineRepository.getRoster(classroomId)` (`ref_classroom_members WHERE status='ACTIVE'`, **même type `List<ClassroomMember>`**). Pattern identique à la Présence : **zéro changement de widget** (`state.members` vient désormais du cache local). Le handler **batch** (`_onClassroomMembersBatchRequested`) reste sur le usecase online → la bascule est **scopée à la consultation single**.

La **liste des classes** (pour choisir laquelle consulter) vient déjà du **bootstrap local** (`schoolLevelGroups`) — pas de dépendance réseau. La recherche **nominale** (élève par nom/niveau, mode « level ») reste **online** (Inscription, gated).

### 2. Écriture — réassignation d'élève
Reste **ONLINE V1** (CF4 Option A) : `classes_organisation_reassign_dialog` → `MemberReassignRequested` sur `ClassroomOfflineBloc` → PUT online + re-pull local best-effort. **Pas d'outbox** (exige la connexion). Inchangé.

### 3. Pull — peupler le cache roster
`ClassroomPullHandler` (livré Phase 1) → `GET /api/v1/sync/classrooms?updatedSince=<ISO>` → upsert `ref_classrooms` + `ref_classroom_members`. Déclenché **au retour online** par le socle. **Manque** : un déclenchement **à la demande** (au montage / à la recherche), car au 1er lancement *déjà online* il n'y a pas de transition ⇒ cache vide ⇒ roster vide. La bascule doit donc **coordonner « peupler-puis-lire »** : à la sélection d'une classe, dispatcher `ClassroomsSyncRequested` (pull) puis relire le roster local à la complétion du pull (listener sur `ClassroomOfflineBloc.syncStatus`).

### Approche d'implémentation retenue (read-switch)
1. Injecter `GetOfflineRosterUseCase` dans `ClassroomBloc` ; l'utiliser dans `_onClassroomMembersRequested` (single) à la place de `GetClassroomMembersUseCase`. Batch inchangé.
2. `classes_list_page._handleSearch` (classe) : dispatcher `ClassroomsSyncRequested(academicYearId)` (pull) + `ClassroomMembersRequested` (lecture cache immédiate) ; ajouter un `BlocListener<ClassroomOfflineBloc>` qui **relit** le roster à la complétion du pull (fraîcheur).
3. États chargement/vide/erreur : inchangés (le mapping d'erreur locale → `storage` existe déjà via `mapClassroomErrorToMessage`).
4. Tests : le test `ClassroomBloc` du handler single passe du mock `GetClassroomMembersUseCase` au mock `GetOfflineRosterUseCase` (le batch garde l'online).

### Ce qui NE bascule PAS (documenté)
- Organisation / répartition / non-affectés (`unassignedEnrollments` absents du cache local) → **online**.
- Recherche nominale d'élève (Inscription, pas de pull) → **online**.
- Stats école (agrégat serveur) → **online**.

### Cycle cible en une ligne
Choisir une classe → pull `/sync/classrooms` (peuple `ref_classroom_members`) → lire le roster **local** (`ClassroomBloc.members` redirigé) → recherche nominale filtrée côté client. Réassignation reste online.
