# FACTURATION_OFFLINE_PLAN.md — plan offline du module Facturation

> **Statut :** plan validé (2026-07-16). **Phases 1, 2 (a→e) et 3 ✅ LIVRÉES** (working tree, 1054 tests verts, analyze clean). **Les 3 bugs money-grade sont résolus.** Reste **Phase 4** (pull en masse §2.1/§2.2) — dormante, attend l'OpenAPI backend.
>
> **Avancement Phase 2e + Phase 3** : fraîcheur `sync_meta.synced_at` affichée sous les totaux (ADR-002, `FacturationLedgerFreshnessCaption` + `LedgerFreshnessCubit` + `GetLedgerFreshnessUseCase`) + badge « en attente de synchro » (`FinancePendingSyncBadge`) sur créances (pending>0) et paiements (`isPendingSync`), l10n FR+EN. **Bug #2 corrigé** : issue socle **`OutboxDispatchOutcome.blocked`** (+ `OutboxDao.defer`, délai fixe 5 s) → le gate FIFO d'attente d'inscription ne consomme plus tentative/backoff/poison (plus de faux `SYNC_ERROR` sur l'argent). **Fail-fast** `total == Σ allocations` dans `recordPayment` (évite un 422 qui immobilise l'argent). **Bornage** de la saisie passé au **reste composé** (`chargeRemainingInCents` → `charge.remainingInCents`). RC provisoire toujours émis (repo, vérifié en test).
>
> **Avancement Phase 1** (compose-at-read + PROVISIONAL) : `SyncState.provisional` ajouté au socle ; `LocalStudentCharge` compose le reste au read (`amountPaidPendingInCents`, `optimisticPaidInCents`/`Remaining` dérivés) ; `LocalStudentLedgerTotals.byCurrency` (§5 totaux par devise) ; `FinanceLocalDao.getChargesByStudent` recomposé (`sync_status <> 'SYNCED'` → inclut SYNC_ERROR) ; increment `+=` et `_recomputeOptimistic` **retirés** ; `initializeChargesForStudent` → `PROVISIONAL` sans outbox ; colonne `optimistic_paid_in_cents` **gelée**. → **bugs money-grade #1 et #3 dissous par construction** (reste #2 = gate FIFO, Phase 3).
>
> **Avancement Phase 2 (2a→2d)** : entités online enrichies (`StudentCharge.amountPaidPendingInCents`/`isProvisional`/`remainingInCents`, `Payment.isPendingSync`, rétro-compatibles) + mappers `Local* → *` ; `FinanceLedgerRefresher` (refresh ciblé best-effort déduppé, endpoint livré `ledger?studentId`) ; repos **offline-first** `StudentChargesOfflineFirstRepository`/`PaymentsOfflineFirstRepository` (lecture locale composée + refresh ; admin/create délégués online) branchés par **override DI** (`unregister`+`register`) dans la branche A ; `FinanceLocalDao.getAllocationsByCharge` ajouté ; KPI + pastille + ligne de frais sur le **reste composé** ; filtre create → **`remaining>0` (jamais `status`)**. L'UI online (BLoCs/widgets) inchangée. **Reste 2e** : fraîcheur `sync_meta.synced_at` affichée (ADR-002) + badge « en attente de synchro » (nécessitent l10n).
> **Source de vérité du besoin :** `FRONT_Facturation_Guide_Fonctionnel_V1.md` (le plus frais — **domine** les specs `FF-Lot`/`FB-Lot` là où elles divergent).
> **Docs de contexte :** `OFFLINE_GAP_ANALYSIS.md` (taxonomie `FAC-1..7`), `OFFLINE.md`, `SCHEMA_sqflite_Facturation_V1.md`, spec backend `FB-Lot 1..9`, spec frontend `FF-Lot 1..7`.

---

## 1. Hiérarchie des sources

| Source | Nature | Statut |
|---|---|---|
| `FRONT_Facturation_Guide_Fonctionnel_V1` | Guide métier — **le besoin le plus frais** | **FAIT FOI** (domine) |
| `SCHEMA_sqflite_Facturation_V1` | Schéma gelé | Référence tables |
| back-end `SPEC_Backend_Facturation_Offline_V1` (`FB-Lot 1..9`) | Contrat backend livré | Référence serveur |
| front-end `SPEC_Frontend_Facturation_Offline_V1` (`FF-Lot 1..7`) | Plan front antérieur | Superseded par le FRONT guide sur les points en conflit |

Points où le FRONT guide **tranche contre** l'ancien plan front/back (et qu'on suit désormais) :
- **§5 / §8** : le reste à payer se **compose au read** (miroir serveur − Σ allocations des paiements `sync_status <> 'SYNCED'`) ; **on ne stocke ni n'incrémente** le solde (« un compteur incrémenté ne se répare jamais »). → **abandon de la colonne matérialisée `optimistic_paid_in_cents` et de son `+=`**.
- **§5.2** : créances d'un nouvel élève = `PROVISIONAL` (≠ `PENDING_SYNC`), jamais poussées, aucune entrée outbox.
- **§2.1 / §2.2** : pull des créances (keyset paginé résumable) + pull global des paiements (anti-divergence 2 postes).

---

## 2. Constat build-vs-adapt

Les deux dossiers sont **les deux moitiés complémentaires** d'une même feature :

| | `finance/` (online / « inline ») | `finance/offline/` |
|---|---|---|
| **Présentation** | ✅ riche & complète (page, détail 356 l., ~40 widgets, dialogues, KPI, recherche, CSV, **8 `ErrorType`**) | ❌ bloc « pass-through », erreur = `String` |
| **Modèle domaine/données** | ❌ argent en `double`, entité **100 % miroir serveur** (pas de `remaining`/optimiste/sync), repos Retrofit | ✅ **exactement le modèle FRONT guide** : int cents, reste composé, `PROVISIONAL`, append-only, outbox, ACK/remap |

Le FRONT guide est **déjà implémenté à ~90 % dans la couche DONNÉES de `finance/offline`** ; la belle UI vit dans `finance/`.

### Verdict — Stratégie C (retenue)

**Garder la présentation + les BLoCs online, rediriger leurs lectures vers des usecases local-first adossés au DAO offline.** L'écriture passe par `FinanceOfflineBloc` (déjà partiellement branché via `facturation_offline_payment_mapper`).

| Stratégie | Coût | Risque |
|---|---|---|
| **A** — tout reconstruire au-dessus de l'offline (dupliquer l'UI) | **L** | Élevé (dérive visuelle, double maintenance) |
| **B** — rendre `finance/` online offline-first (réécrire entités + repos + re-créer DAO/outbox/ACK) | **L** redondant | Élevé (touche l'argent partout, ré-invente l'offline) |
| **C** — hybride : rediriger les lectures online → local-first | **S→M** | **Faible** |

**Pourquoi C :**
1. **Pattern déjà validé 2× dans ce repo** — `ClassroomBloc` (CLS-1/2) et `AttendanceBloc` (PRE-3) : « source redirigée vers un usecase offline, widgets inchangés, drop-in ».
2. **Aucune moitié coûteuse dupliquée** (ni les ~40 widgets, ni le DAO/outbox/ACK/provisoire).
3. **Honorer le FRONT guide simplifie la donnée** : le compose-at-read (§5/§8) **supprime la colonne matérialisée** → **2 des 3 bugs money-grade disparaissent par construction**.
4. L'écriture est déjà à moitié routée offline.

---

## 3. Bugs money-grade identifiés (audit du code réel)

1. **`_recomputeOptimistic` exclut les `SYNC_ERROR`** — `finance_local_dao.dart:225` filtre `sync_status = 'PENDING_SYNC'` au lieu de `<> 'SYNCED'` → un paiement `SYNC_ERROR` (cash reçu) sort du solde → la créance réapparaît « à payer » → **re-perception**. → **dissous** par le compose-at-read (Phase 1).
2. **Gate FIFO en canal `retry`** — `payment_outbox_handler.dart:56-61` renvoie `retry` (backoff + `attempts++` + poison→`SYNC_ERROR`) pour une simple attente d'inscription → **faux `SYNC_ERROR`** sur un paiement réel. → corrigé **Phase 3** (issue `blocked`/`waiting`).
3. **`applyPaymentAck` ne recompose que `ack.updatedCharges`** — `finance_local_dao.dart:147-161` → créance omise garde son increment → **double comptage**. → **dissous** par le compose-at-read (Phase 1).

Bonus : `recordPayment` incrémente `+=` avec `ConflictAlgorithm.replace` sans garde ; `total == Σ allocations` non asserté (→ 422 immobilise l'argent).

---

## 4. Plan détaillé (Stratégie C, aligné FRONT guide)

> Principe : l'UI lit **toujours** le local (§2.4) ; reste **composé au read** (§5) ; on **ne stocke ni n'incrémente** (§8) ; filtre **`remaining>0`, jamais `status`** (§6/§8).

### Phase 1 — Couche données conforme §5/§5.2/§8 *(`finance/offline`)*
1. Requête composée `getComposedChargesByStudent` dans `FinanceLocalDao` = SQL §5 (`expected`, `paid_server`, `paid_pending = Σ allocations WHERE p.sync_status <> 'SYNCED'`, `remaining`, `paid_total`) + `getStudentTotals` **par devise** (§5 Totaux).
2. **Retirer l'increment** de `recordPayment` (`optimistic_paid_in_cents += …`) ; geler/supprimer la colonne.
3. **`PROVISIONAL`** : `SyncState.provisional('PROVISIONAL')` ; `initializeChargesForStudent` l'écrit ; **aucune entrée outbox** (§5.2).
4. **Fraîcheur** : exposer `sync_meta.synced_at` (ressource ledger) pour l'affichage (ADR-002).
- *Tests* : reste composé incluant `SYNC_ERROR`, totaux par devise, provisoire sans outbox.

### Phase 2 — Rediriger les lectures online → local-first
5. Usecases local-first (`GetStudentChargesLocalUseCase`, `GetPaymentsLocalUseCase`, `GetPaymentAllocationsLocalUseCase`) sur le DAO composé.
6. Enrichir entités online (`StudentCharge`, `Payment`) : argent `double`→**`int`** + `amountPaidPendingInCents`/`remainingInCents`/`syncStatus` ; mapper `Local* → *`.
7. **Swap DI** des usecases de `StudentChargesBloc`/`PaymentsBloc` vers les local-first (drop-in, widgets & blocs inchangés).
8. **Fraîcheur affichée** (« à jour à HHhMM ») + badge « en attente de synchro ».
- *Tests* : blocs rejoués sur source locale ; détail lit 100 % local (aucun GET).

### Phase 3 — Écriture money-grade *(§6)*
9. Filtre **`remaining>0` (jamais `status`)** + **bornage saisie** par le `remaining` composé (§6 step 5-6, §8 #3).
10. **Corriger le gate FIFO** : issue `blocked`/`waiting` (délai fixe, sans `attempts++`/backoff/poison) → plus de faux `SYNC_ERROR` (§6.3).
11. **`assert total == Σ allocations`** avant l'INSERT ; **RP provisoire non-optionnel**.
12. Create-payment **100 % via `FinanceOfflineBloc`** (retirer le chemin online en mode offline).

### Phase 4 — Pull *(§2.1/§2.2 — DÉPEND DU BACKEND, dormant)*
13. **Rafraîchissement ciblé** (`GET /sync/finance/ledger?studentId`, déjà livré) avant encaissement si réseau (§6 step 2) — **actionnable dès Phase 3**.
14. **Pull keyset en masse** des créances (§2.1) + **pull global des paiements** (§2.2) : `FinancePullHandler` sur le patron keyset (`KeysetPage`/`SyncMetaDao` de l'inscription : cursor opaque persisté tel quel, watermark, `bootstrapComplete` à `hasMore=false`). **Prérequis : `openapi_billing_sync.yaml` backend** (à fournir).

### Phase 5 — Éditique & différés
15. NP + RC définitif scellé (`POST /payments/{id}/receipt`) ; multi-devise ; consommation trop-perçu (V2).

---

## 5. Questions ouvertes

- **Phase 4** : le backend a-t-il livré le pull keyset en masse (§2.1) + le pull global des paiements (§2.2) ? Le FRONT guide référence `openapi_billing_sync.yaml`, absent du repo. → **l'utilisateur fournira l'OpenAPI** ; d'ici là Phases 1-3 livrent l'offline par élève (rafraîchi ciblé ou inscrit offline).
- `classroom_id` sur `payments` : requis par le back sur `POST /payments` ? (§6.2 le liste ; absent du code).
- Vocabulaire résolu : le code dit **`RC`**/**`DUE`**, le FRONT guide dit « RP »/« UNPAID » → on garde le vocabulaire **code/back** (RC, DUE).
