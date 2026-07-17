# FACTURATION_OFFLINE_PLAN.md — plan offline du module Facturation

> **Statut :** plan validé (2026-07-16). **Phases 1, 2 (a→e), 3, 4 et 6 ✅ LIVRÉES** (working tree, 1110 tests verts,
> analyze + `dart format` clean). **Les 3 bugs money-grade sont résolus.** Le grand-livre est câblé sur le contrat
> **`openapi_billing_sync` 1.1.0**, pull ET push (§17) : chemins `/api/v1/sync/*`, jeton unique `cursor`, 304
> applicatif, 400 → bootstrap ; push imbriqué idempotent + ACK à créances autoritaires. Déclenché au montage du module +
> au retour online. **Trois revues adversariales** ont fermé ~25 défauts money-grade — dont beaucoup **introduits par les
> correctifs de la revue précédente** : sur ce chemin, une correction est la meilleure cible de la ronde suivante. Voir
> **§6**, qui porte les invariants à ne pas casser (propriété de `sync_status`, dépendance créances→paiements, scope
> année du remap, colonnes réellement portées par le pull). **Plus aucune dette ouverte sur le grand-livre.** Reste
> **Phase 5** (éditique & différés).
>
> **Avancement Phase 2e + Phase 3** : fraîcheur `sync_meta.synced_at` affichée sous les totaux (ADR-002,
> `FacturationLedgerFreshnessCaption` + `LedgerFreshnessCubit` + `GetLedgerFreshnessUseCase`) + badge « en attente de
> synchro » (`FinancePendingSyncBadge`) sur créances (pending>0) et paiements (`isPendingSync`), l10n FR+EN. **Bug #2
corrigé** : issue socle **`OutboxDispatchOutcome.blocked`** (+ `OutboxDao.defer`, délai fixe 5 s) → le gate FIFO
> d'attente d'inscription ne consomme plus tentative/backoff/poison (plus de faux `SYNC_ERROR` sur l'argent).
> **Fail-fast** `total == Σ allocations` dans `recordPayment` (évite un 422 qui immobilise l'argent). **Bornage** de la
> saisie passé au **reste composé** (`chargeRemainingInCents` → `charge.remainingInCents`). RC provisoire toujours émis
> (repo, vérifié en test).
>
> **Avancement Phase 1** (compose-at-read + PROVISIONAL) : `SyncState.provisional` ajouté au socle ;
> `LocalStudentCharge` compose le reste au read (`amountPaidPendingInCents`, `optimisticPaidInCents`/`Remaining`
> dérivés) ; `LocalStudentLedgerTotals.byCurrency` (§5 totaux par devise) ; `FinanceLocalDao.getChargesByStudent`
> recomposé (`sync_status <> 'SYNCED'` → inclut SYNC_ERROR) ; increment `+=` et `_recomputeOptimistic` **retirés** ;
> `initializeChargesForStudent` → `PROVISIONAL` sans outbox ; colonne `optimistic_paid_in_cents` **gelée**. → **bugs
money-grade #1 et #3 dissous par construction** (reste #2 = gate FIFO, Phase 3).
>
> **Avancement Phase 2 (2a→2d)** : entités online enrichies (`StudentCharge.amountPaidPendingInCents`/`isProvisional`/
> `remainingInCents`, `Payment.isPendingSync`, rétro-compatibles) + mappers `Local* → *` ; `FinanceLedgerRefresher`
> (refresh ciblé best-effort déduppé, endpoint livré `ledger?studentId`) ; repos **offline-first**
> `StudentChargesOfflineFirstRepository`/`PaymentsOfflineFirstRepository` (lecture locale composée + refresh ;
> admin/create délégués online) branchés par **override DI** (`unregister`+`register`) dans la branche A ;
> `FinanceLocalDao.getAllocationsByCharge` ajouté ; KPI + pastille + ligne de frais sur le **reste composé** ; filtre
> create → **`remaining>0` (jamais `status`)**. L'UI online (BLoCs/widgets) inchangée. **Reste 2e** : fraîcheur
> `sync_meta.synced_at` affichée (ADR-002) + badge « en attente de synchro » (nécessitent l10n).
> **Source de vérité du besoin :** `FRONT_Facturation_Guide_Fonctionnel_V1.md` (le plus frais — **domine** les specs
> `FF-Lot`/`FB-Lot` là où elles divergent).
> **Docs de contexte :** `OFFLINE_GAP_ANALYSIS.md` (taxonomie `FAC-1..7`), `OFFLINE.md`,
> `SCHEMA_sqflite_Facturation_V1.md`, spec backend `FB-Lot 1..9`, spec frontend `FF-Lot 1..7`.

---

## 1. Hiérarchie des sources

| Source                                                           | Nature                                     | Statut                                                  |
|------------------------------------------------------------------|--------------------------------------------|---------------------------------------------------------|
| `FRONT_Facturation_Guide_Fonctionnel_V1`                         | Guide métier — **le besoin le plus frais** | **FAIT FOI** (domine)                                   |
| `SCHEMA_sqflite_Facturation_V1`                                  | Schéma gelé                                | Référence tables                                        |
| back-end `SPEC_Backend_Facturation_Offline_V1` (`FB-Lot 1..9`)   | Contrat backend livré                      | Référence serveur                                       |
| front-end `SPEC_Frontend_Facturation_Offline_V1` (`FF-Lot 1..7`) | Plan front antérieur                       | Superseded par le FRONT guide sur les points en conflit |

Points où le FRONT guide **tranche contre** l'ancien plan front/back (et qu'on suit désormais) :

- **§5 / §8** : le reste à payer se **compose au read** (miroir serveur − Σ allocations des paiements
  `sync_status <> 'SYNCED'`) ; **on ne stocke ni n'incrémente** le solde (« un compteur incrémenté ne se répare
  jamais »). → **abandon de la colonne matérialisée `optimistic_paid_in_cents` et de son `+=`**.
- **§5.2** : créances d'un nouvel élève = `PROVISIONAL` (≠ `PENDING_SYNC`), jamais poussées, aucune entrée outbox.
- **§2.1 / §2.2** : pull des créances (keyset paginé résumable) + pull global des paiements (anti-divergence 2 postes).

---

## 2. Constat build-vs-adapt

Les deux dossiers sont **les deux moitiés complémentaires** d'une même feature :

|                            | `finance/` (online / « inline »)                                                                           | `finance/offline/`                                                                                                |
|----------------------------|------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| **Présentation**           | ✅ riche & complète (page, détail 356 l., ~40 widgets, dialogues, KPI, recherche, CSV, **8 `ErrorType`**)  | ❌ bloc « pass-through », erreur = `String`                                                                       |
| **Modèle domaine/données** | ❌ argent en `double`, entité **100 % miroir serveur** (pas de `remaining`/optimiste/sync), repos Retrofit | ✅ **exactement le modèle FRONT guide** : int cents, reste composé, `PROVISIONAL`, append-only, outbox, ACK/remap |

Le FRONT guide est **déjà implémenté à ~90 % dans la couche DONNÉES de `finance/offline`** ; la belle UI vit dans
`finance/`.

### Verdict — Stratégie C (retenue)

**Garder la présentation + les BLoCs online, rediriger leurs lectures vers des usecases local-first adossés au DAO
offline.** L'écriture passe par `FinanceOfflineBloc` (déjà partiellement branché via
`facturation_offline_payment_mapper`).

| Stratégie                                                                                           | Coût            | Risque                                                |
|-----------------------------------------------------------------------------------------------------|-----------------|-------------------------------------------------------|
| **A** — tout reconstruire au-dessus de l'offline (dupliquer l'UI)                                   | **L**           | Élevé (dérive visuelle, double maintenance)           |
| **B** — rendre `finance/` online offline-first (réécrire entités + repos + re-créer DAO/outbox/ACK) | **L** redondant | Élevé (touche l'argent partout, ré-invente l'offline) |
| **C** — hybride : rediriger les lectures online → local-first                                       | **S→M**         | **Faible**                                            |

**Pourquoi C :**

1. **Pattern déjà validé 2× dans ce repo** — `ClassroomBloc` (CLS-1/2) et `AttendanceBloc` (PRE-3) : « source redirigée
   vers un usecase offline, widgets inchangés, drop-in ».
2. **Aucune moitié coûteuse dupliquée** (ni les ~40 widgets, ni le DAO/outbox/ACK/provisoire).
3. **Honorer le FRONT guide simplifie la donnée** : le compose-at-read (§5/§8) **supprime la colonne matérialisée** →
   **2 des 3 bugs money-grade disparaissent par construction**.
4. L'écriture est déjà à moitié routée offline.

---

## 3. Bugs money-grade identifiés (audit du code réel)

1. **`_recomputeOptimistic` exclut les `SYNC_ERROR`** — `finance_local_dao.dart:225` filtre
   `sync_status = 'PENDING_SYNC'` au lieu de `<> 'SYNCED'` → un paiement `SYNC_ERROR` (cash reçu) sort du solde → la
   créance réapparaît « à payer » → **re-perception**. → **dissous** par le compose-at-read (Phase 1).
2. **Gate FIFO en canal `retry`** — `payment_outbox_handler.dart:56-61` renvoie `retry` (backoff + `attempts++` +
   poison→`SYNC_ERROR`) pour une simple attente d'inscription → **faux `SYNC_ERROR`** sur un paiement réel. → corrigé
   **Phase 3** (issue `blocked`/`waiting`).
3. **`applyPaymentAck` ne recompose que `ack.updatedCharges`** — `finance_local_dao.dart:147-161` → créance omise garde
   son increment → **double comptage**. → **dissous** par le compose-at-read (Phase 1).

Bonus : `recordPayment` incrémente `+=` avec `ConflictAlgorithm.replace` sans garde ; `total == Σ allocations` non
asserté (→ 422 immobilise l'argent).

---

## 4. Plan détaillé (Stratégie C, aligné FRONT guide)

> Principe : l'UI lit **toujours** le local (§2.4) ; reste **composé au read** (§5) ; on **ne stocke ni n'incrémente**
> (§8) ; filtre **`remaining>0`, jamais `status`** (§6/§8).

### Phase 1 — Couche données conforme §5/§5.2/§8 *(`finance/offline`)*

1. Requête composée `getComposedChargesByStudent` dans `FinanceLocalDao` = SQL §5 (`expected`, `paid_server`,
   `paid_pending = Σ allocations WHERE p.sync_status <> 'SYNCED'`, `remaining`, `paid_total`) + `getStudentTotals` **par
   devise** (§5 Totaux).
2. **Retirer l'increment** de `recordPayment` (`optimistic_paid_in_cents += …`) ; geler/supprimer la colonne.
3. **`PROVISIONAL`** : `SyncState.provisional('PROVISIONAL')` ; `initializeChargesForStudent` l'écrit ; **aucune entrée
   outbox** (§5.2).
4. **Fraîcheur** : exposer `sync_meta.synced_at` (ressource ledger) pour l'affichage (ADR-002).

- *Tests* : reste composé incluant `SYNC_ERROR`, totaux par devise, provisoire sans outbox.

### Phase 2 — Rediriger les lectures online → local-first

5. Usecases local-first (`GetStudentChargesLocalUseCase`, `GetPaymentsLocalUseCase`,
   `GetPaymentAllocationsLocalUseCase`) sur le DAO composé.
6. Enrichir entités online (`StudentCharge`, `Payment`) : argent `double`→ **`int`** + `amountPaidPendingInCents`/
   `remainingInCents`/`syncStatus` ; mapper `Local* → *`.
7. **Swap DI** des usecases de `StudentChargesBloc`/`PaymentsBloc` vers les local-first (drop-in, widgets & blocs
   inchangés).
8. **Fraîcheur affichée** (« à jour à HHhMM ») + badge « en attente de synchro ».

- *Tests* : blocs rejoués sur source locale ; détail lit 100 % local (aucun GET).

### Phase 3 — Écriture money-grade *(§6)*

9. Filtre **`remaining>0` (jamais `status`)** + **bornage saisie** par le `remaining` composé (§6 step 5-6, §8 #3).
10. **Corriger le gate FIFO** : issue `blocked`/`waiting` (délai fixe, sans `attempts++`/backoff/poison) → plus de faux
    `SYNC_ERROR` (§6.3).
11. **`assert total == Σ allocations`** avant l'INSERT ; **RP provisoire non-optionnel**.
12. Create-payment **100 % via `FinanceOfflineBloc`** (retirer le chemin online en mode offline).

### Phase 4 — Pull *(§2.1/§2.2)* ✅ LIVRÉE

13. **Rafraîchissement ciblé** avant encaissement si réseau (§6 step 2) — `FinanceLedgerRefresher`, désormais servi par
    le **keyset scopé élève** (`GET /api/v1/sync/student-charges?studentId=`). C'est un **point read** : il UPSERT les
    créances de l'élève et bumpe `synced_at` (fraîcheur ADR-002), **sans toucher au jeton du cycle de masse**. L'ancien
    `GET /sync/finance/ledger` est **retiré** (`pullLedger`/`LedgerDelta`/`PaymentAllocationDto` supprimés) — le keyset
    couvre les deux usages, un seul contrat à maintenir.
14. **Pull keyset en masse** des créances (§2.1) + **pull global des paiements** (§2.2) — `FinancePullRepositoryImpl`
    sur le patron keyset de l'inscription (ADR-008/009). **Jeton unique** (contrat 1.1.0) : `sync_meta` mémorise le
    jeton opaque **tel quel**, sans préfixe — `nextCursor` (progression, repris après coupure) tant que `hasMore`, puis
    `nextWatermark` (départ du cycle suivant, Δ appliqué serveur), les deux repassant par le **même** paramètre
    `cursor`. Même convention que l'Inscription (`KeysetPageEnvelope.cursorToPersist`). Ordre porteur : **créances
    d'abord** (la vérité du grand-livre), **paiements ensuite** (les événements, y compris ceux de l'autre poste =
    anti-divergence). `UNPAID` (contrat) normalisé en `DUE` (local) au mapping.
15. **Déclenchement** — deux points, car le `PullCoordinator` global ne se déclenche **qu'au retour online**
    (`sync_status_cubit.dart`) : une tablette démarrée déjà connectée ne tirerait jamais. D'où `SyncFinancePullsUseCase`
    appelé au **montage de `FinanceFeatureScope`** (best-effort, non attendu), miroir exact de
    `SyncEnrollmentPullsUseCase`. Ouvrir la Facturation = le moment d'hydrater, avant de partir encaisser hors-ligne.

### Phase 5 — Éditique & différés

16. NP + RC définitif scellé (`POST /payments/{id}/receipt`) ; multi-devise ; consommation trop-perçu (V2). →
    **Partiellement dissous** : le RC définitif arrive désormais dans l'ACK du push (`documents[]`, §17) — plus besoin
    d'un appel dédié pour le cas nominal. Reste différé : la NP, le multi-devise, la consommation du trop-perçu.

### Phase 6 — Push aligné sur `openapi_billing_sync` 1.1.0

17. **`POST /api/v1/sync/payments`** (ex-`/api/v1/finance/payments`, forme à plat) — l'agrégat passe à la forme
    **imbriquée** `{payment, allocations}` (`PaymentAggregateRequest`). L'enrichissement `clientUuid` est **retiré du
    wire** : la spec ne le porte pas, `payment.id` (uuid client honoré) EST la clé d'idempotence
    (`ON CONFLICT (id) DO NOTHING`). La colonne locale `client_uuid` reste (usage local). L'ACK
    (`PaymentAggregateResponse`) change de forme sur 4 points :
    - `updatedCharges`/`AckCharge` (id+solde+statut) → **`charges`/`StudentCharge` complet** — le MÊME schéma que le
      pull, donc `StudentChargeDto` est réutilisé. L'apply passe d'UPDATE à **UPSERT** (le serveur peut renvoyer une
      créance inconnue de ce poste) ⇒ **garde-fou money-grade** : avant insert, la jumelle PROVISIONAL (même
      `student_id + fee_code`, uuid local) est dissoute via `_remapProvisionalCharge`, sinon l'élève semblerait devoir
      deux fois le même frais.
    - `AckAllocation` (id, studentChargeId?) → **`AllocationRemap`** (`providedId`/`canonicalId`,
      `providedStudentChargeId`/`canonicalStudentChargeId`, `feeCode`) : le `feeCode` est désormais **porté par la
      réponse** → plus de relecture locale pour résoudre la créance, et l'uuid d'allocation peut lui aussi être remappé.
    - **`documents[]`** (RC scellé) : le `documentNumber` définitif remplace le `PROV-…` local (patron
      `enrollment_ack_dao`). **Vide = cas NORMAL** (scellement best-effort hors transaction serveur, décision G) → reçu
      provisoire conservé, l'encaissement reste acquis.
    - `overpayment` : `{amountInCents}` → `{detected, excessInCents, currency, feeCode, reason}` — parsé, **pas encore
      consommé** (liste d'arbitrage admin = V2). Disparu de l'ACK : `payment.status`/`payment.paidAt` (le statut local
      n'est plus écrasé) ; `payment.receiptId` est parsé mais **sans usage** (aucune colonne `receipt_id` sur
      `payments` — le scellement passe par `documents[]`).

---

## 5. Questions ouvertes

- ~~**Phase 4** : le backend a-t-il livré le pull keyset ?~~ **Résolu** : contrat `openapi_billing_sync` **1.1.0** livré
  et câblé — chemins alignés sur la convention projet (§2.1 `/api/v1/sync/student-charges`, §2.2
  `/api/v1/sync/payments`), **jeton unique `cursor`** (paramètre `watermark` retiré), **304 applicatif** (ni ETag ni
  `If-None-Match`), **400** sur curseur forgé/étranger. Reste à vérifier **sur tablette réelle** que le pull peuple bien
  le local (aucun test d'intégration ne monte `FinanceFeatureScope`).
- `classroom_id` sur `payments` : le contrat 1.1.0 l'expose (`PaymentInput.classroomId`, nullable) et `PaymentInput` le
  porte — mais **aucune colonne locale** ne l'alimente : toujours envoyé `null`. À câbler si le back en a besoin.
- **Trop-perçu** : `OverpaymentSignal` est parsé mais jamais remonté à l'UI (ni toast, ni liste d'arbitrage). Décision
  produit à prendre — la spec le veut « signalé pour arbitrage admin ».
- `FinanceLocalDao` reste un **god-DAO** (~540 l., lectures + écritures + ACK + pull) : à découper sur le patron
  `enrollment_*_dao` (referential/seed/reconciliation).

## 6. Dettes money-grade du pull (revue adversariale 2026-07-17) — RÉSORBÉES

Confirmées par revue multi-agents (36 agents), **corrigées** :

1. ~~**Double facturation au pull de masse**~~ — `upsertLedger` dissout désormais la **jumelle PROVISIONAL** avant
   d'insérer une créance canonique (`_dissolveProvisionalTwins`) : les imputations sont repointées vers l'id serveur, la
   ligne locale disparaît. Pendant, côté pull de masse, de ce que `_remapProvisionalCharge` fait à l'ACK. L'index des
   jumelles est calculé **une fois** par pull (les créances non remontées sont rares) et non par ligne : le pull en
   masse porte des milliers de créances.
2. ~~**Identité du payeur écrasée**~~ / 3. ~~**Libellé d'allocation écrasé**~~ — le pull n'est plus un `REPLACE`
   aveugle : sur une ligne DÉJÀ connue il applique un **patch borné aux colonnes qu'il porte**
   (`PaymentLocalModel.toPullPatch` / `PaymentAllocationLocalModel.toPullPatch`). Le payeur et le libellé, saisis au
   guichet et absents du contrat `PaymentDelta`, ne sont plus écrasés par leur repli `''`/`feeCode`. Une ligne INCONNUE
   (paiement de l'autre poste) s'insère toujours en entier.
5. ~~**`FinanceLedgerRefresher` ne rafraîchit plus que les créances**~~ — il enchaîne maintenant le **cycle global des
   paiements** (seam `PaymentsSync`), le contrat n'ayant pas d'endpoint paiements scopé élève. Motif : le refresher est
   le point de fraîcheur DEVANT la lecture de l'historique, et cet historique est **replié en « total payé »** à l'écran
   (`facturation_detail_payments_section`) → un encaissement fait au poste A restait invisible au poste B, qui affichait
   un total sous-estimé et pouvait **réencaisser**. Cycle keyset ⇒ delta vide la plupart du temps (coût réel : un 304).
   Hors-ligne, aucun des deux pulls ne part ; un échec de l'un ne bloque pas l'autre.

**4. Créances et paiements non atomiques — DISSOUS par une règle de propriété.** La 2ᵉ revue a montré que le levier
n'était pas l'ordre des pulls mais **qui possède `sync_status`** :

> **Le pull ne bascule JAMAIS un paiement en SYNCED. Seul `applyPaymentAck` le fait — et dans la MÊME transaction que
> l'intégration des créances autoritaires.**

Le pull dit « le serveur connaît ce paiement » ; `sync_status` encode, lui, « mon miroir de créances a intégré son
montant » — c'est ce que lit `paid_pending` (FRONT §5). Confondre les deux sortait le montant du pending alors que
`amount_paid` pouvait être périmé → créance affichée **impayée** → réencaissement. `toPullPatch` exclut donc
`sync_status`/`sync_error`/`synced_at`. Une ligne INCONNUE (autre poste) s'insère en SYNCED : elle est bien au serveur,
et n'a aucun pending local à préserver.

L'ordre des handlers (créances puis paiements) reste le sens de panne conservateur et le ⚠️ de
`enrollment_finance_offline_di.dart` tient : **ne pas l'inverser**. Le refresher applique la même règle — il n'avance le
cycle des paiements que si le point read des créances a **réussi**.

### Corrigés dans la même passe

Régressions du câblage 1.1.0 (1ʳᵉ revue) : payload outbox legacy à plat relu sans perte ; `_remapProvisionalCharge`
scopé année + jamais SYNCED ; PK d'allocation jamais réécrite ; 400 → purge du jeton + bootstrap.

Régressions des correctifs **eux-mêmes** (2ᵉ revue — le chemin de l'argent ne pardonne pas) :

- `AllocationRemap.canonicalStudentChargeId` rendu **nullable** : la spec ne le liste PAS dans `required`. Le cast
  non-null levait à la désérialisation → `retry` → ACK jamais appliqué, POST rejoué à l'infini, argent encaissé bloqué
  hors du grand-livre. Un remap sans cible est simplement sauté.
- `toPullPatch` (allocation) n'écrit `student_charge_id` **que s'il est résolu** : `nullable` au contrat = absence
  d'info, pas rétractation. Le propager effaçait le lien du versement/de l'ACK → imputation hors du `paid_pending` →
  montant redevenu dû.
- `_pendingChargeIndex` renvoie une **liste** d'ids par clé : rien ne garantit l'unicité de
  `(student_id, année, fee_code)` (pas de contrainte ; `initializeChargesForStudent` peut avoir rejoué). Une
  `Map<String,String>` ne dissolvait qu'une jumelle sur deux → frais facturé en double.
- `_remapProvisionalCharge` ne **fabrique plus** `SYNCED` en renommant : c'est l'UPSERT autoritaire qui apporte soldes
  ET état.
- Le retry du 400 est **hors du `catch`** : une exception levée dans un `catch` n'est pas rattrapée par les `on …`
  frères — elle s'échappait de `_keysetPull`, qui promet de ne jamais lever (appelé en `unawaited` ⇒ async error non
  gérée).
- **Guard in-flight par ressource** dans `FinancePullRepositoryImpl` : `FinanceFeatureScope` (pull au montage) et le
  refresher (via la lecture) lançaient deux cycles paiements concurrents qui se **rembobinaient** le curseur. Piège Dart
  au passage : `whenComplete(() => map.remove(k))` en flèche renvoie le Future retiré, et `whenComplete` attend tout
  Future renvoyé ⇒ le cycle s'attend lui-même (interblocage). Corps en **bloc** obligatoire.

Régressions et angles morts trouvés par la **3ᵉ revue** (elle a invalidé deux affirmations de ce §6 — les correctifs
d'une ronde sont la meilleure cible de la suivante) :

- **`applyPaymentAck` n'estampille `SYNCED` que si `charges` est non vide.** Le §6 prétendait que « ne pas estampiller
  SYNCED dans le remap » protégeait du cas « SYNCED, rien payé » : **c'était inerte** — `paid_pending` lit le
  `sync_status` du PAIEMENT, jamais celui de la créance. Sur un ACK sans créance (contrat violé), le stamp sortait le
  montant du pending sans que rien ne l'ait intégré → créance impayée → réencaissement. `PaymentOutboxHandler` renvoie
  désormais `retry` sur un tel ACK : c'est une panne serveur, pas un encaissement acquitté.
- **`_remapProvisionalCharge` dissout TOUTES les jumelles** : le `limit: 1` avait survécu côté ACK alors que la ronde 2
  ne l'avait corrigé que côté pull. Même trou, autre chemin.
- **`SyncFinancePullsUseCase` garde la dépendance** créances→paiements : l'invariant n'était appliqué que dans le
  refresher, si bien que le pull au montage avançait les paiements par-dessus un miroir périmé. Un **ordre** ne suffit
  pas, il faut une **garde** (nouveau compteur `skipped`, distinct de `failed`).
- **`toPullPatch` (paiement) n'écrit plus `status` ni `method`** : il violait l'invariant qu'il documente —
  `PaymentDelta` ne porte pas `status` (la colonne locale était vidée) et `method` y est nullable alors que le DTO
  replie sur `'CASH'` (un `BANK_TRANSFER` devenait `CASH`).
- **Fraîcheur estampillée après les DEUX pulls**, et seulement s'ils ont abouti : « à jour à HHhMM » couvre aussi
  l'historique, replié en « total payé » à l'écran. Un **304 sur le point read vaut succès** (« rien n'a changé » = le
  miroir est bon) — le traiter en échec coupait l'historique dans le cas nominal.
- **Le 304 en cours de cycle ne rembobine plus** : le refactor de la ronde 2 réécrivait le jeton de DÉPART, effaçant la
  progression déjà persistée → re-téléchargement des mêmes pages à chaque cycle.
- **`hasMore` sans curseur qui progresse lève** au lieu de sortir en silence : la garde anti-boucle rendait un `Right`
  « updated » sur une tablette définitivement bloquée, comptée comme synchronisée.
- **Index des jumelles calculé PAR LOT**, dans la transaction du lot : `applyInBatches` relâche le verrou entre les
  lots, un élève inscrit hors-ligne pendant le pull échappait à un index pris avant la boucle.

### Les 4 derniers points — FERMÉS

- ~~**Allocation créée APRÈS dissolution d'une jumelle**~~ → `recordPayment` **re-résout le lien à l'écriture**
  (`_resolveChargeLink`) : si l'uuid de créance tenu par l'UI n'existe plus, on retrouve la ligne par la clé MÉTIER
  `(élève, année, fee_code)` — stable là où l'uuid ne l'est pas. Sans cible locale, on écrit `null` (« créance pas encore
  matérialisée », le serveur remappera) plutôt qu'un id mort. Le **payload d'outbox porte le même lien** que le local :
  pousser un uuid mort ferait diverger le diagnostic serveur du miroir.
- ~~**Latence de lecture**~~ → le cycle global des paiements est **borné par un délai** côté refresher
  (`paymentsDeadline`, 4 s). Au-delà, la lecture rend la main — l'écran sert le local, promesse offline-first tenue — et
  le cycle continue en tâche de fond (son guard le sérialise), faisant avancer le curseur pour la prochaine lecture. On
  renvoie alors `false` : **borner la latence ne doit pas devenir un mensonge**, donc aucune fraîcheur n'est affichée.
- ~~**`_guarded` rejoignait un cycle en vol**~~ → il **CHAÎNE** désormais. Rejoindre mentait sur la fraîcheur : un cycle
  déjà parti a lu son curseur AVANT l'appel du nouvel arrivant, il ne peut donc pas contenir un encaissement fait
  entre-temps sur l'autre poste — alors que le refresher conditionne la fraîcheur affichée à sa réussite. Chaîne bornée à
  deux (un qui tourne + un qui attend) : tant que le cycle en attente n'est pas parti, les arrivants s'y coalescent. Le
  surcoût est un 304.
- ~~**`_chargeKey` joint par `|`**~~ → **record Dart 3** `(String, String?, String)` : égalité structurelle, donc aucun
  délimiteur à choisir (plus de collision possible) et `null` reste distinct de `''` — exactement la sémantique du
  `academic_year_id IS ?` du SQL, que la chaîne jointe confondait.

**Gotcha Dart au passage** (`_pullPaymentsBestEffort`) : un seam qui échoue **sans jamais suspendre** rend un
`Future<Never>` — type statique `Future<bool>`, type réifié plus étroit. `.timeout` exige alors un `onTimeout` en
`() => Never` : notre `() => false` lève un `TypeError` que le `catch` avale, **masquant la vraie erreur** qui remonte
non gérée à la zone. `Future.sync` ne corrige rien (il renvoie le future tel quel quand c'en est déjà un) : il faut
ré-emballer dans une fonction `async` déclarée `Future<bool>` avant le `.timeout`.

- Vocabulaire résolu : le code dit **`RC`**/ **`DUE`**, le FRONT guide dit « RP »/« UNPAID » → on garde le vocabulaire
  **code/back** (RC, DUE).
