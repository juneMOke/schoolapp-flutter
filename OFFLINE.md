# OFFLINE.md — Architecture offline-first

Document de référence des choix d'implémentation de la couche **offline-first**
(4 modules : Inscription, Facturation, Classe, Présence/Discipline).

> Portée : décisions verrouillées, contrat écriture/lecture, câblage UI, gaps
> backend et TODO différés. Pour les patterns génériques (BLoC, Retrofit,
> FeatureScope), voir `AGENTS.md`. Branche de travail : `feature/implements_offline`.

---

## 1. Socle partagé

`lib/core/database/` + `lib/core/offline/`

- **Base chiffrée SQLCipher** (`sqflite_sqlcipher`) — clé 256 bits stockée en
  secure storage via `DatabaseKeyService`. Ouverture eager au démarrage
  (`registerOfflineCore`, `offline_injection.dart`).
- **Outbox générique** (`OutboxDao`) — file de push FIFO par `created_at`, backoff
  exponentiel borné, garde-fou tenant `school_id` (nullable pour l'instant).
  Compteurs `pendingCount()` / `errorCount()`.
- **`SyncEngine`** — vide l'outbox en FIFO, route chaque entrée vers le
  `OutboxSyncHandler` de son `aggregateType`, marque ACKED / SYNC_ERROR / retry.
  Un seul flush à la fois. Déclenché à la demande **et** au passage *online*.
- `SyncMetaDao` (curseurs de pull + fraîcheur), `ConnectivityService`,
  `IdGenerator`, `ConflictFailure` (+ branche 409 de l'intercepteur Dio).

### Mécanisme anti-conflit de merge (clé)

Chaque module ne touche que **2 lignes additives** du socle :

- `buildOfflineSchema()` (`offline_schema.dart`) agrège une `List<TableSchema>`
  par module (ex. `enrollmentFinanceOfflineTables`,
  `classroomAttendanceOfflineTables`).
- `registerOfflineModules()` (`offline_injection.dart`) appelle **un registrar
  par branche** dans `lib/core/di/offline_modules/`.

Les handlers d'outbox sont branchés via `getIt<SyncEngine>().registerHandler(...)`.

---

## 2. Découpage en modules (2 branches parallèles, mergées)

| Branche | Modules | Couplage |
|---|---|---|
| **A** | Inscription + Facturation | FIFO agrégat → paiement du même élève |
| **B** | Classe + Présence/Discipline | roster partagé `ref_classroom_members` |

**15 tables** : outbox, sync_meta, students, parents, student_parent,
enrollments, generated_documents, payments, payment_allocations, student_charges,
ref_fee_tariffs, ref_classrooms, ref_classroom_members, attendance_records,
disciplinary_cases. **4 handlers d'outbox** : ENROLLMENT, PAYMENT, ATTENDANCE,
DISCIPLINARY_CASE.

---

## 3. Décisions verrouillées (avec le *pourquoi*)

| Décision | Détail | Pourquoi |
|---|---|---|
| **Cents INTEGER** | Tous les montants des nouveaux modèles offline en cents entiers | Zéro flottant sur la monnaie (cf. `FINANCE_MOTION_MAP.md`) |
| **Agrégat inscription** | `POST /api/v1/sync/enrollments` consolide les 5 écritures incrémentales + remap ACK (parent provisoire → canonique) | Atomicité côté serveur, remap des id client |
| **Progression niveau RE** | Déléguée au serveur | Règle métier centralisée |
| **Réassignation classe (CF4)** | **ONLINE V1** (PUT + re-pull), **zéro outbox** | Exige la connexion ; conflits difficiles à réconcilier offline |
| **Compteurs élèves** | Jamais `total = F + M` (OTHER inclus) | Le genre `OTHER` existe |
| **Présence** | Stockage **par exception** + LWW `updated_at` | Volume réduit, résolution déterministe |
| **Discipline** | Régime A (create id-client) + C (update LWW) ; sanction toujours renvoyée au PUT | Idempotence + réconciliation best-effort |
| **Écriture UI** | **OFFLINE-FIRST STRICT** (voir §4) | Cible offline-first assumée |
| **Lecture UI** | **GARDÉE ONLINE** (voir §4) | Cache non peuplé sans pull → basculer afficherait du vide |

---

## 4. Contrat offline-first strict (écriture / lecture)

**Écriture = offline-first strict.** Au point d'écriture d'un écran, l'appel
online est **retiré** ; l'écriture passe par le BLoC offline → base locale +
mise en file **outbox**. La pastille de synchro s'allume via
`SyncStatusCubit.notifyLocalWrite()`.

**Lecture = online.** Les listes/détails/rosters restent branchés sur les BLoCs
online existants. Motif : les endpoints de **pull** `/api/v1/sync/*` n'existent
pas encore, donc le cache local n'est pas peuplé — brancher les lectures sur
l'offline afficherait du **vide**.

**Conséquences assumées (tant que `/sync/*` n'est pas livré) :**

- Les écritures **ne persistent pas côté serveur** ; elles restent en attente
  dans l'outbox (la pastille passe « à envoyer », puis « conflit » si rejet).
- **Read-your-writes différé** : après une écriture, la liste online ne reflète
  pas l'entrée en attente. Le retour visuel « en attente de synchronisation »
  (clés l10n `offline*Queued`) compense côté UX.

---

## 5. Câblage UI

### Pastille de synchro globale

- `SyncStatusCubit` (`lib/core/components/status/sync_status_cubit.dart`) —
  agrège connectivité + `SyncEngine.isFlushing` + `OutboxDao.pendingCount`/
  `errorCount` → `SyncStatus{synced, syncing, offline, pendingUpload,
  syncConflict}`. **Défensif** (aucun accès plugin/base ne remonte d'exception
  dans l'arbre — les tests ne mockent pas `connectivity_plus`). Déclenche un
  flush opportuniste au passage *online*.
- Fourni **une fois à la racine** (`main.dart`, `.value` — factory conforme à la
  règle #2, instance unique app-lifetime accessible via `context`). Monté dans
  `TopBarActions` (`SyncIndicator`).

> Gotcha : les modales sont poussées sur le **root navigator**. Le cubit doit
> donc être fourni **au-dessus** de `MaterialApp` pour qu'un `context.read`
> depuis une modale le trouve (vrai en prod ; à reproduire dans les tests widget).

### Les 5 écrans (écriture offline-first, lecture online)

| Écran | Point d'écriture | Bloc offline / event |
|---|---|---|
| **Encaissement** | `facturation_create_payment_confirm_dialog.dart` `_confirm()` | `FinanceOfflineBloc` · `RecordLocalPayment` (mapper `facturation_offline_payment_mapper.dart`) |
| **Appel présence** | `attendance_save_overlay.dart` | `AttendanceOfflineBloc` · `RecordDailyAttendanceRequested` |
| **Cas discipline** | `disciplinary_case_create_dialog.dart` `_submit()` (+ avancement `onAdvance`) | `DisciplinaryCaseOfflineBloc` · `CreateOfflineDisciplinaryCase` / `UpdateOfflineDisciplinaryCase` |
| **Réassignation classe** | `classes_organisation_reassign_dialog.dart` | `ClassroomOfflineBloc` · `MemberReassignRequested` (**online**, pas d'outbox ; gère le succès partiel `reassignRePullFailed`) |
| **Confirmation inscription** | `summary_step_handler.dart` `submit()` | `EnrollmentOfflineBloc` · `ConfirmLocalEnrollment` (draft via `enrollment_confirm_draft_builder.dart`) |

**BLoCs de présentation offline** : la chaîne A (Inscription/Facturation) les
avait déjà ; la chaîne B en était dépourvue → créés dans cette itération
(`AttendanceOfflineBloc`, `DisciplinaryCaseOfflineBloc`, `ClassroomOfflineBloc`),
enregistrés dans `classroom_attendance_offline_di.dart`. Ces BLoCs mappent leurs
échecs via des chaînes FR en dur (aligné sur `FinanceOfflineBloc`, pas de l10n).

**Inscription — approche conservatrice (non-cassante).** Le wizard sauvegarde de
façon **incrémentale online** au fil des étapes ; on **ne refactore pas** cela.
Seule la **confirmation finale** bascule offline. Il en résulte une
double-écriture conceptuelle transitoire (création incrémentale online +
confirmation offline), **inoffensive** tant que `/sync/*` est absent (l'outbox ne
pousse pas). La refonte offline-first complète du wizard reste à faire (§6).

---

## 6. Gaps backend & TODO différés

**Endpoints backend absents** (contrats miroir câblés côté client, testés avec
Dio mocké) :

- `POST /api/v1/sync/*` (push agrégats) — **inexistants**.
- `PUT /disciplinary-cases/{id}` — **inexistant** (créé côté datasource client).
- Pull référentiel / cohorte Inscription (F5) — non implémenté.

**TODO différés :**

- Refonte offline-first complète du **wizard inscription** (arrêter les saves
  incrémentales online, tout confirmer atomiquement).
- **Migration des lectures → offline** quand le pull `/sync/*` sera livré.
- Réconciliation `version` LWW discipline (read model sans version/updatedAt).
- Réponse enrichie présence (AG-3) → `markDaySynced`.
- Visibilité `content` par rôle (DF-3).
- Pastille `onTap` → bottom-sheet détail de synchro.
- Builder inscription : genre `other` éventuel replié sur `MALE` (à raffiner).

---

## 7. Tests & validation

- Socle : tests DAO (`outbox_dao_test`, incl. `errorCount`), `sync_engine_test`,
  `sync_state_test`, `sync_status_cubit_test`.
- Chaîne A/B : tests data/domain/sync + tests des 3 BLoCs offline créés.
- 3 tests widget existants réécrits pour le chemin offline (encaissement,
  réassignation, layout home).
- État validé : `flutter analyze` **clean**, **768 tests verts**, `dart format`
  conforme.

---

## 8. Ajouter un nouveau module offline

1. Créer `lib/core/database/schema/<module>_offline_schema.dart` exposant une
   `List<TableSchema>` ; l'ajouter à `buildOfflineSchema()`.
2. Créer `lib/core/di/offline_modules/<module>_offline_di.dart` (DataSources →
   Repos → UseCases → BLoCs → handlers d'outbox) ; l'appeler depuis
   `registerOfflineModules()`.
3. Ajouter les endpoints de sync dans `AppConstants`.
4. Écriture UI = dispatch offline + `notifyLocalWrite()` ; lecture UI = online
   tant que le pull n'est pas livré (cf. §4).
5. Tests miroir dans `test/`.
