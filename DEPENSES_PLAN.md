# Module Dépenses — plan front (V1, v2, v3)

> **Où on en est, en une ligne** : la V1 et la v2 (circuit de validation) sont
> en prod, front et back. La **v3 — déclarer, puis viser** est planifiée en
> **partie III** (§16 à §22), rien n'est codé : c'est là qu'il faut reprendre.

> Rédigé le 2026-09-13 sur `feat/expense-register` (base `origin/main` 6252762e).
> Sources : spec design `ui_kits/app/Depenses-Frais-Fonctionnement-Spec.html`
> (+ maquette `Depense.jsx`, `DepenseViews.jsx`, `DepenseData.jsx`) et plan back
> « Ce que l'école décaisse » (artifact b25cccca), confronté au code Java de
> `eteelo-backend` (`feat/expense-register`, non commité à la rédaction) et à
> son `openApi.yaml`. **Le serveur fait foi** : là où la spec design parle
> d'un « dépôt serveur » et d'identifiants `DEP-0001` fabriqués par le poste,
> c'est le contrat qui l'emporte.

---

# Partie I — V1 : le registre (livré, dans `main`)

## 1. Ce que le module fait

Deux sous-menus sous un menu « Dépenses » :

| Sous-menu | Question | Source |
|---|---|---|
| Tableau de bord | combien, sur quoi, qu'est-ce qui reste à régler | table locale `expenses` |
| Frais de fonctionnement | le registre : créer, retrouver, dupliquer, marquer payée, retirer | table locale `expenses` |

Les deux lisent la **même liste locale** et partagent la **même période**.
Rien n'est lu au serveur en dehors du pull : le poste détient le registre, les
dépenses non remontées comprises (leçon du Recouvrement).

## 2. Contrat serveur (résumé, cf. `openApi.yaml`)

| Verbe | Route | Garde | Usage front |
|---|---|---|---|
| POST | `/api/v1/sync/expenses` | `expense.write` | outbox `EXPENSE` : état complet, un geste = une requête |
| POST | `/api/v1/sync/expenses/{id}/deletion` | `expense.delete` | outbox `EXPENSE_WITHDRAWAL` : `{deleted, changedAt, authorId}` |
| GET | `/api/v1/sync/expenses?cursor=&limit=` | `expense.read` | pull keyset, 304 sur cycle vide, retraits compris |
| GET | `/api/v1/sync/referential` | socle | clé racine `expenseTypes` (jamais caviardée, masqués compris) |

- Montants en **centimes** dans la devise d'engagement, francs compris.
- Accusé `{expense: ExpenseDelta, lwwOutcome: APPLIED|SUPERSEDED}` ; sur
  `SUPERSEDED` le poste s'aligne sur l'état renvoyé.
- Refus : 400 (validation), 403 (droit / `authorId`), 409 (course, **rejouer**),
  410 `AGGREGATE_TOMBSTONED` (effacer la ligne locale), 422 `detailCode` ∈
  `UNKNOWN_EXPENSE_TYPE`, `EXPENSE_DATE_IN_FUTURE`, `PAYMENT_DATE_IN_FUTURE`,
  devise — **aucun récupérable par rejeu**, la dépense se corrige sur le poste.
  404 sur `/deletion` : dépense inconnue de l'école.
- Flux `expense.expenses` (KEYSET, école, ressource cliente `expenses`,
  `expense.read`, jamais entraîné) ; `expense.read` entraîne
  `finance.exchange-rates` en DEGRADED.
- Rôles : Direction, Super admin, Comptable reçoivent les trois droits.

## 3. Décisions front

| # | Décision | Pourquoi |
|---|---|---|
| F1 | Module `lib/features/expense/` (identifiants anglais), menu propre « Dépenses » | la spec le dessine hors de Finances (menu `depenses`, icône portefeuille) |
| F2 | Lecture 100 % locale, écriture 100 % outbox | D1 du back ; ADR-003 ; un total serveur serait faux sur le poste qui vient d'écrire hors ligne |
| F3 | Deux types d'agrégat d'outbox (`EXPENSE`, `EXPENSE_WITHDRAWAL`) sur le même `aggregate_id` | le FIFO de l'outbox garantit création → retrait ; le retrait a sa propre horloge (`changedAt`) |
| F4 | Accusé et pull ne réécrivent **jamais** un contenu local plus récent (`client_updated_at` local > celui reçu) : seuls les champs serveur (numéro, agent, version, curseur) sont posés | une seconde modification hors ligne ne doit pas être écrasée par l'accusé de la première |
| F5 | Classement des erreurs de push : transport, 5xx, 401/408/409/429 → `retry` ; 410 → ligne effacée + `acked` ; tout autre 4xx → `failed` (ligne « à corriger », A4) | patron `payment_outbox_handler._classifyDioError` ; un 422 rejoué boucle jusqu'au poison |
| F6 | Types lus du socle (`expenseTypes`) → `ref_expense_types` par école ; clé absente / `null` / vide / illisible ⇒ le cache reste, jamais de purge | patron F1 `feeCodeSections` ; A9 |
| F7 | « Année » = **année scolaire** (D2), ancrée sur le jour de rentrée de l'année courante du référentiel, repli 1ᵉʳ septembre ; fenêtres contiguës | comparer recettes et dépenses sur la même année ; aucun jour ne tombe entre deux années |
| F8 | Période partagée entre les deux écrans par un porteur mémoire **non-BLoC** (`ExpensePeriodMemory`, `lazySingleton`) ; les BLoCs restent en factory | spec §2 « basculer d'onglet compare, il ne recommence pas » ; règle n°2 |
| F9 | Totaux par **sac de devises** ; lecture en dollars **seulement** si un taux USD↔CDF est publié, toujours doublée de la paire brute et du taux nommé ; sans taux : paire seule, jamais de 1 pour 1 | A5, doctrine bi-devise §12 |
| F10 | Variation : période en cours comparée **à durée écoulée égale** ; période passée comparée entière | A6 (point ouvert §11) |
| F11 | Recherche insensible à la casse **et aux accents** | A7 |
| F12 | Sélecteur de date plafonné à aujourd'hui | A8 |
| F13 | Numéro « en attente » tant que l'accusé n'est pas revenu | A3 |
| F14 | `paidOn` : aujourd'hui à la bascule, date de la dépense si créée payée, `null` si non payée ; « Payée le … » en fiche | A2 |
| F15 | Champ facultatif « Fournisseur / bénéficiaire » au formulaire | A1 |
| F16 | Supprimer = retrait réversible, depuis la fiche seulement, sans confirmation, toast « Annuler » qui restaure | D4 ; spec §9 |
| F17 | Formulaire et fiche en modales (`EteeloDialogBody`), comme la spec (`RecOverlay` 600/560) | 8 champs sans liste ; clavier géré par le socle, testé en paysage |
| F18 | Droits : menu sous `expense.read` ; créer/modifier/dupliquer/basculer sous `expense.write` ; retirer/restaurer sous `expense.delete` — un geste sans droit est **masqué**, jamais offert pour échouer | un 403 d'outbox est terminal |

## 4. Données locales

Schéma offline + 1 palier :

- `ref_expense_types` (id PK, school_id, code, label, short_label, icon,
  color, soft_color, default_currency, sort_order, active).
- `expenses` (id PK, school_id, expense_number NULL, type_id, title,
  description, amount_in_cents INTEGER, currency, status, paid_on, expense_date
  `YYYY-MM-DD`, supplier, funding_source, recorded_by_id, recorded_by_name,
  client_updated_at, deleted_at, **server_deleted_at** (le retrait tel que le
  serveur l'a dit en dernier — l'état auquel revient un geste refusé),
  **withdrawal_pending_at** (geste de retrait pas encore accusé), version,
  server_updated_at, sync_status, sync_error, sync_error_code).
  Index `(school_id, expense_date)` et `(sync_status)`.

La date d'une dépense n'a pas de fuseau (`DATE`) : les bornes de période se
comparent en chaînes `YYYY-MM-DD`, jamais en instants — le piège de la borne ISO
de la boutique n'existe pas ici.

## 5. Lots

Chaque lot compile, passe `flutter analyze` à zéro et sa suite ciblée ; la
suite complète tourne au dernier lot.

| Lot | Contenu |
|---|---|
| DEP-0 | ce plan |
| DEP-1 | socle données : tables + palier, entités, modèles, DAO, section `expenseTypes` du socle |
| DEP-2 | remontée : API, handlers d'outbox (dépense, retrait), dépôt d'écriture, accusé |
| DEP-3 | descente : pull keyset, clé de plan `expense.expenses`, câblage DI + test de câblage |
| DEP-4 | logique pure : périodes, filtres, recherche, groupes par jour, sacs, lecture USD, séries, variation, postes |
| DEP-5 | navigation et droits : permissions, registre d'accès, menu, routes, carte d'accueil |
| DEP-6 | registre « Frais de fonctionnement » : période, filtres, compteurs, liste, actions, formulaire, fiche, toast |
| DEP-7 | tableau de bord : chiffres clés, évolution, répartition, top 5, encarts |
| DEP-8 | revue adversariale ciblée (push / pull / DAO / présentation), docs |

## 6. Hors V1 (inchangé depuis la spec)

Approbation, budget, pièce jointe, référentiel fournisseurs, récurrence
automatique, période libre, débit de caisse par la source de fonds,
configuration des types, état PDF.

> ⚠️ **Périmé depuis la v2 pour un point** : l'**approbation** est entrée dans le
> produit (§8 et suivants) — la dépense est devenue une demande soumise à
> décision. Le reste de cette liste tient toujours ; le hors-périmètre de la v2
> est au §13.

---

## 7. État d'exécution

Commité sur `feat/expense-register` en quatre lots, **non poussé** : `cc80fbab`
(plan), `6d21a8ce` (domaine), `7a5e139c` (données + synchro), `bf220e3c`
(écrans). Les lots domaine et synchro ont été vérifiés seuls, en worktree :
analyze à zéro et tests verts. Le dernier correspond à l'arbre passé en suite
complète (6 776 tests).

| Lot | État | Commit |
|---|---|---|
| DEP-0 | ✅ plan | `cc80fbab` |
| DEP-1 | ✅ palier **v48** (`ref_expense_types`, `expenses`), section `expenseTypes` du socle (seam `replaceExpenseTypes`) | `6d21a8ce`, `7a5e139c` |
| DEP-2 | ✅ `EXPENSE` + `EXPENSE_WITHDRAWAL`, entrées d'outbox déterministes, accusé LWW jugé contre l'état ENVOYÉ | `7a5e139c` |
| DEP-3 | ✅ pull keyset `expenses@<école>`, clé `expense.expenses`, cible de disparition `expenses` | `7a5e139c` |
| DEP-4 | ✅ périodes (année scolaire ancrée), filtres, recherche sans accents, séries, sacs, lecture USD, variation à durée égale | `6d21a8ce` |
| DEP-5 | ✅ `expense.read/write/delete`, menu « Dépenses », deux sous-menus, routes, carte d'accueil | `7a5e139c`, `bf220e3c` |
| DEP-6 | ✅ registre : période, filtres, compteurs, liste par jour, actions, formulaire, fiche, toast « Annuler » | `bf220e3c` |
| DEP-7 | ✅ tableau de bord : chiffres clés, évolution, répartition, top 5, encarts | `bf220e3c` |
| DEP-8 | ✅ deux revues adversariales (sync ; domaine + écrans), 18 défauts corrigés, 1 laissé au socle (ci-dessous) | `6d21a8ce`, `7a5e139c`, `bf220e3c` |

### DEP-8 — ce que la revue a corrigé

**Synchro (revue A)**

- **Retrait zombie** : un retrait mis en file sur une dépense ensuite refusée
  attendait pour toujours un numéro. Le handler règle désormais sur le poste
  seul une dépense sans numéro dont le dernier envoi est refusé, et acquitte
  sans appel un geste qui n'est plus celui en attente sur la ligne.
- **Retrait local** (`setLocalOnlyWithdrawal`) : il neutralise le contenu ET le
  retrait, quel que soit leur statut (un contenu remis en file depuis la
  feuille des erreurs ressusciterait la dépense) ; il revérifie l'état dans sa
  transaction et rend `false` si la dépense a été accusée entre-temps.
- **Résurrection** : l'accusé d'un contenu en vol sur une dépense retirée en
  local ne défait plus le retrait — il le met en file.
- **Refus d'un geste** : la ligne revient à `server_deleted_at` (ce que le
  serveur sait), plus à un état deviné depuis le geste (faux après « retirer
  puis Annuler »).
- **404 sur `/deletion`** : l'attente se lève (le pull reprend la main).
- **Autre école du poste** : une entrée d'une autre école attend sa session
  (`blocked`) au lieu d'être jugée dans la mauvaise école.
- **Saisie** : sur une ligne existante, seuls le contenu et l'état de synchro
  sont réécrits — un accusé appliqué entre la lecture et l'écriture n'est plus
  défait.
- **Auteur obligatoire** : sans agent connecté, la saisie est refusée tout de
  suite (une entrée sans `authorId` serait refusée, donc perdue).
- **Poussée immédiate** : le dépôt lance un flush après chaque écriture.

**Domaine et écrans (revue B)**

- Changer de type ne déplace plus la devise d'une dépense existante, ni après
  un choix explicite, ni quand un montant est saisi (`ExpenseFormModel`).
- F9 complet : toute lecture en dollars qui convertit est doublée de sa paire
  (cartes, en-têtes de jour, encarts) et le taux est nommé sous les chiffres
  clés (`ExpenseRateNote`).
- « Voir le mois entier » ouvre le mois de la journée/semaine consultée et ne
  s'offre que sous le mois ; au tableau de bord, le vide mène alors au
  registre.
- L'en-tête d'une journée coupée par le palier de 40 compte toute la journée.
- Un filtre sur une période vide affiche le vide « période ».
- L'année scolaire a toujours 12 barres (la queue avant la rentrée suivante
  rejoint août).
- La période partagée repart de zéro sous un autre compte ou une autre école.
- « Nouvelle dépense » du vide passe par `PermissionGate` (réactif).
- Règles du dépôt : plus de code de type en dur, jointures « · » en l10n,
  décalages et opacité en jetons, fichiers ≤ 250 lignes.

**Laissé au socle (hors module)** : `OutboxDao.markSyncError` / `reschedule` /
`defer` n'ont pas la garde `expectedCreatedAt` de `markAcked`. Une entrée
remplacée pendant son vol peut hériter d'un compteur ou d'un backoff. Côté
dépenses, le cas terminal est déjà neutralisé : un refus sur une entrée
remplacée rend `retry`. Le correctif touche tous les modules et leurs doublures
de test, et mérite son propre lot.

### Écarts assumés avec la spec design

- **Sous-menus plutôt qu'onglets** : la coquille de l'app porte déjà la navigation
  (même choix que Recouvrement). La période reste partagée
  (`ExpensePeriodMemory`), et un poste du top 5 ouvre le registre pré-filtré.
- **Montants USD à deux décimales** (« 137,50 $ ») : règle D6a du socle
  (`MoneyFormat`), la maquette écrit « 137 $ ».
- **Sans taux publié** : les cartes empilent une ligne par devise, le graphique
  d'évolution se tait (il le dit) quand deux devises se mêlent, et les postes se
  classent par nombre de dépenses (A5 poussé jusqu'au classement).
- **Formulaire** : le scrim ne ferme pas la modale (une saisie est du travail
  non enregistré) ; fermeture par « Annuler » ou la croix.

---

# Partie II — v2 : le circuit de validation

> Plan front publié et révisé deux fois le 2026-09-23 :
> artifact **`V5HXc9yjnjSEkWBhrvttAN`** (« Décider hors ligne ») — à republier sur
> cette URL, ne pas en créer un second. Plan back en regard : artifact
> **`LyahMoYhZ3c7M9LvuxGjDX`** (« Demander avant de dépenser »), lots C0→C3.
> Spec design `ui_kits/app/Depenses-Frais-Fonctionnement-Spec.html` (+ `Depense*.jsx`)
> — **elle n'est pas sur le disque** : projet Claude Design « ETEELO CONNECT
> Design System », `DesignSync get_file`, projectId
> `9a727b6b-c244-415d-975c-a476d6114f3e`. `DepenseViews.jsx` porte l'anatomie du
> fil, de la chaîne de validation et de la fiche ; il est bien plus court que la
> spec (175 KB).
>
> **Le contrat est figé** : les dix questions au back sont tranchées, plus aucune
> n'est ouverte de part et d'autre.

## 8. Ce que la v2 change

Une dépense n'est plus un fait constaté, c'est une **demande** : elle naît en
attente, quelqu'un la tranche, le paiement se constate après. Le poste sait déjà
tout faire seul (lecture 100 % locale, écriture 100 % outbox, F2) ; ce qui change
pour lui, c'est qu'une décision **ne s'arbitre plus à l'horloge** — le serveur a
le droit de la refuser, et il exige que les gestes lui arrivent **dans l'ordre où
ils ont été faits**.

| | V1 | v2 |
|---|---|---|
| Statut | `PAID` \| `UNPAID`, basculé d'un clic de liste | 5 états, jamais saisis, résultat d'un geste |
| Argent engagé | `== PAID` lu en six endroits | le drapeau `isFirm` (approuvée + payée), et lui seul |
| Date de règlement | dérivée du statut à la sauvegarde | posée par le geste de paiement, par lui seul |
| Fil | aucun | `expense_messages`, append-only, un message par geste |
| Remontée | 2 agrégats d'outbox | + `EXPENSE_GESTURE`, une entrée **par geste**, en séquence |
| Écrans | registre + tableau de bord | + la **file de validation** |

## 9. Contrat serveur v2 (delta)

Sept routes de geste, toutes en `POST /api/v1/sync/expenses/{id}/…` :
`decision`, `payment`, `reopen`, `retraction`, `resubmit`, `reminder`,
`messages`. Telles que le plan back les arrête ; **l'`openApi.yaml` fera foi à la
livraison**.

- **L'uuid du message est la clé d'idempotence** de chaque geste (Q3) : un rejeu
  est inerte — 200, état canonique, compteur de relances inchangé.
- **Les messages quittent la poussée de contenu** (Q1) : `POST /sync/expenses`
  n'en porte plus aucun. Commenter a sa propre route, sous `expense.write` mais
  **sans contrôle de propriété** — c'est ce qui permet au validateur de commenter
  la demande d'un collègue.
- **La poussée de contenu ne transitionne JAMAIS** (Q2, D8) : « corriger et
  renvoyer » = deux gestes dans l'ordre, contenu **puis** `/resubmit`.
  `/retraction` n'est plus une bascule ; c'est `/resubmit` qui réengage.
- `/resubmit` porte le `clientUpdatedAt` du contenu attendu (**F32**, offre du
  back acceptée) : tant que la copie serveur est plus ancienne, il refuse. **À
  transmettre au back avant son lot C2 si ce n'est pas déjà fait.**
- Le **409 porte le fil** (Q8) : le poste réaligne statut et fil d'un seul geste.
- Pull : `messages[]` en `{ id, body, act, createdAt, authorId, authorName }`,
  **toujours entier** (la pagination porte sur les demandes, jamais sur les
  messages). Page à ramener de 100 à **50** :
  `expense_pull_repository_impl.dart:50`.
- Refus : `422 REASON_REQUIRED`. (`422 SELF_APPROVAL_FORBIDDEN` a été
  abandonné le 2026-09-25, cf. §13.) **`422
  INVALID_TRANSITION` a disparu des routes de geste** (Q10) : le serveur ne peut
  pas distinguer un geste hors séquence d'un geste impossible — payer une demande
  en attente est absurde jusqu'à ce que l'approbation arrive.

### 🔴 Les deux 409, aux conduites OPPOSÉES

Seul le `detailCode` les sépare, et s'y tromper réécrit la décision d'un collègue :

| `detailCode` | Conduite | Jamais |
|---|---|---|
| `DECISION_ALREADY_TAKEN` | se réaligner sur l'état canonique renvoyé, fil compris ; toast rouge nommant le décideur | **ne jamais rejouer** |
| `TRANSITION_OUT_OF_ORDER` | rejouer : la ligne locale est juste, c'est le serveur qui n'a pas vu le prédécesseur | **ne jamais réaligner** |

C'est **F34**. `ExpensePushFailure.isTransient`
(`expense_push_failure.dart:44-45`) juge sur le SEUL statut
(`transientStatuses = {401, 408, 409, 429}`) : en l'état il rejouerait une
décision déjà prise. ✅ Vérifié : le socle n'est pas en cause —
`ApiErrorParser.detailCodeOf` (`api_error_parser.dart:94`) lit `body['detailCode']`
quel que soit le statut, et `ExpensePushFailure.of:24` l'appelle déjà sans
condition. Seul le commentaire `api_error_parser.dart:88` (« sur un 422, `null`
sinon ») deviendra faux et est à corriger.

## 10. Décisions front v2 (F19 → F34)

La numérotation continue celle de la V1. Détail et justification dans l'artifact.

| # | Décision |
|---|---|
| F19 | `ExpenseStatus` = 5 valeurs portant `wireValue` + `isFirm` ; toute somme lit `isFirm`, jamais une égalité de statut |
| F20 | `paidOn` cesse d'être dérivé du statut (`_paidOnFor` supprimé) |
| F21 | Un geste = une entrée d'outbox `EXPENSE_GESTURE`, identifiée par l'uuid de son message. **L'inverse du contenu, délibérément** : le contenu s'écrase (LWW), un geste jamais — approuver puis annuler puis refuser, ce sont trois faits |
| F22 | La décision est optimiste et **restaurable** ; `DECISION_ALREADY_TAKEN` réaligne, 403 et 422 sont terminaux (ligne « à corriger ») |
| F23 | Le lot est un geste d'écran, pas un appel réseau (le back a retiré la route de lot) ; le refus en lot recopie son motif dans chaque geste |
| F24 | La propriété se juge sur `recordedById` / `authorId`, **jamais sur le nom** — deux homonymes suffisent à se tromper |
| F25 | Le geste V1 `/deletion` s'appelle **Supprimer** à l'écran ; le mot « Retirer » est rendu au circuit (contrat inchangé) |
| F26 | « Année » reste l'année scolaire — amendement A13 refusé (D2 tient) |
| F27 | La recherche reste insensible aux accents (A12 déjà acquis, F11) |
| F28 | Les compteurs du registre disparaissent : les montants vivent au tableau de bord, l'attente dans la file |
| F29 | Aucun geste n'est offert pour échouer : `PermissionGate.access` croisé avec le statut et la propriété ; Approuver/Refuser restent offerts sur ses propres demandes : seule la direction décide, et A11 est abandonnée (§13) |
| F30 | Le fil recopie le patron Discipline **sans ses défauts** : auteur = identifiant résolu, fraîcheur du fil dans sa propre colonne, et il remonte geste par geste au lieu d'être imbriqué dans la poussée du parent |
| F31 | **Le fil est le registre d'ordre** : un geste n'est dispatchable que s'il porte le plus ancien message non synchronisé de sa dépense, sinon `blocked` |
| F32 | « Corriger et renvoyer » = deux entrées dans l'ordre ; le renvoi attend l'accusé du contenu |
| F33 | Les actes du fil sont en **anglais** (décision utilisateur) : `DEPOSIT · REMINDER · APPROVAL · REFUSAL · PAYMENT · RETRACTION · REOPENING · CORRECTION · EDIT`, `null` = commentaire libre |
| F34 | Un 409 ne se lit **jamais** au seul code HTTP (voir §9) |

## 11. Données locales v2 — palier **52**

L'escalier hérité est clos à 48 : un palier neuf va dans
`tenant_migrations.dart` (`if (upTo(52))`), **jamais** dans `app_database.dart`.
DDL écrit en clair dans l'étape, jamais relu du schéma vivant, et l'étape reste
rejouable.

Six colonnes sur `expenses`, **en fin de table** (`ALTER TABLE` ne sait
qu'ajouter à la fin, et une base montée doit finir identique à une base créée à
neuf — le test de palier le vérifie colonne par colonne, dans l'ordre) :
`decided_by_id`, `decided_by_name`, `decided_at`, `decision_reason`,
`reminder_count` (`INTEGER NOT NULL DEFAULT 0`), `last_message_at`.

Table neuve `expense_messages` : `id` PK (uuid du poste), `school_id`,
`expense_id`, `body`, `act` NULL, `author_id`, `author_name`, `created_at`
(ISO-8601 UTC), `sync_status` (`DEFAULT 'PENDING_SYNC'`). Index
`(expense_id, created_at)` — il sert l'affichage **et** la garde d'ordre de F31.

**Reprise : il n'y a rien à reprendre** (D11 close — le back a vérifié qu'aucune
dépense n'existe en base). Le palier garde tout de même le renommage défensif
`UNPAID` → `APPROVED` : un `count(*)` serveur ne dit rien des bases locales des
postes de développement, et une ligne au statut inconnu se lirait « en attente »
sur un écran qui la croirait non décidée.

## 12. Lots v2 et état d'exécution

Sur **`feat/expense-validation-circuit`**, **PR #59**. Partie de `a8ff5c7c`
(le sommet de `main` juste après la PR #56), rebasée le 2026-09-25 sur `main`
après les PR #57 et #58 : le palier du circuit est passé de **v50 à v52**,
derrière `till_phone` (v50) et le matricule annuel (v51). Chaque lot compile, passe
`flutter analyze` à zéro et sa suite ciblée ; la suite complète tourne au dernier.

> Note d'historique, pour qui verrait une divergence : ces commits ont d'abord
> atterri **dans `main`** en avance rapide (jusqu'à `660cfbc5`, le 2026-09-23),
> puis `main` a été ramené à `a8ff5c7c` — décision explicite : **`main` ne garde
> aucune modification Dépenses tant que le circuit n'est pas fini** (l'encadré
> ci-dessous dit pourquoi). Les commits sont les mêmes, ils vivent désormais sur
> la branche seule.

| Lot | État | Commit |
|---|---|---|
| DEP-9 | ✅ ce document (partie II) | le commit qui le porte |
| DEP-10 | ✅ **cinq statuts** : énumération + `isFirm`, six sites binaires ouverts, `paidOn` dé-dérivé, palier v52 (volet statut), bascule payée/non payée retirée, compteurs du registre supprimés, `ExpenseTransitions` + matrice de transitions testée | `559e1746` |
| DEP-11 | ✅ **le fil** : palier v52 (volet fil), 9 actes anglais, `ExpenseMessage`, `ExpenseMessageDao` (append atomique), `ExpenseRepository.thread()`, `ExpenseThreadPanel` dans la fiche, fiche découpée | `504ebbfe` |
| DEP-12 | ✅ **les gestes et les droits**, en cinq commits : les trois droits (`expense.decide`/`pay`/`reopen`, hors de `kGuardedWriteActions` tant que le back ne les sème pas) · `ExpenseGesture` + `ExpenseGesturePolicy` + `appendGesture` (inerte au rejeu) · la chaîne à trois jalons et les encarts de situation · le pied de fiche, le panneau de refus et les toasts · le champ du fil | `5f4990ce` `29793ade` `9d0e9db7` `e5d9712d` `d7c30363` |
| DEP-13 | ✅ **la file** : sous-menu, route et accès · `ExpenseWait` (tiède 3 j, chaud 5 j) · `ExpenseQueueOrder` (3 tris, stables) · `ExpenseQueueView` + cubit + écran · sélection et lot local · bloc « approuvées, à payer » | `2610b7fa` |
| DEP-14 | ✅ **la remontée et l'ordre** : 7 routes + `ExpenseGesturePayload` · entrée d'outbox dans la transaction de `appendGesture` · garde d'ordre F31 **et** son échappatoire · les deux 409 (F34) · delta enrichi (6 colonnes + `messages[]`) · page à 50 | `cbfabbc5` |
| DEP-15 | ✅ **revue et clôture** : 7 défauts trouvés et corrigés | `42e2a080` `4875da4f` |

Vérifié au dernier commit : `flutter analyze` → **No issues found** ;
`flutter test -j 4` **complet** → vert, code de sortie capturé sans pipe. La
revue adversariale de DEP-15 a été jouée, et §13 dit ce qu'elle a rendu.

> ⚠️ **`flutter analyze` doit être relancé APRÈS le commit**, pas avant : le
> hook `pre-commit` reformate les fichiers stagés sur le disque, et un `if`
> d'une ligne que le formateur éclate en deux fait apparaître un
> `curly_braces_in_flow_control_structures` que le contrôle d'avant-commit ne
> pouvait pas voir. Payé à DEP-12 (commit amendé).

### ⚠️ Le circuit est complet côté poste — et toujours pas livrable

Les cinq statuts, le fil, les gestes, la file et la remontée existent. Ce qui
manque n'est plus à nous :

1. **La poussée sort du contrat servi.** Le dépôt crée une demande en
   `PENDING` et l'`openApi.yaml` déployé déclare encore
   `ExpenseStatus: enum [PAID, UNPAID]` (~l. 18126). Un 400 de validation est
   terminal par F5 ⇒ la dépense reste « à corriger » et n'atteint jamais le
   serveur. Les **sept routes de geste n'existent pas non plus** : chaque
   geste y mourra en 404, terminal lui aussi.
2. **Donc : rien ne fusionne dans `main`, et pas de release du module Dépenses
   avant la livraison back C0→C3.** C'est la seule dépendance qui reste, et
   elle n'a pas de contournement côté poste — un module qui écrit dans une
   outbox dont chaque entrée meurt terminale est pire qu'un module absent.

Corollaire à surveiller, aujourd'hui **vide mais pas théorique** : un `UNPAID`
redescendu par le pull n'est plus connu du front (`ExpenseStatus.fromWire`
retombe sur `pending`) et se lirait « En attente », donc hors des totaux.
C'est sans effet aussi longtemps que D11 tient — **aucune dépense en base, ni
en production ni en staging** — et c'est la première chose à revérifier si une
ligne apparaît.

### Décisions prises pendant DEP-12 — ne pas les rouvrir

- **Les trois droits sont déclarés avant d'être semés**, comme
  `finance.rate.override`, et restent **hors de `kGuardedWriteActions`** : les
  y inscrire ferait rougir, à raison, le test « aucune exigence n'est hors de
  portée de tous ». Le jour où le back les sème (C0→C3), les inscrire **et**
  mettre à jour la copie du template dans `role_journeys_test.dart`, ensemble.
- **`ExpenseGesture` porte les huit gestes** — sept routes, `decision` en sert
  deux — avec l'acte qu'ils écrivent, l'état qu'ils visent et à qui ils
  appartiennent. Trois filtres à l'écran, tous des ET : `PermissionGate.access`
  (réactif), l'état et la propriété (`ExpenseGesturePolicy`).
- **La propriété indécidable ne penche pas du même côté selon le geste** : ce
  qu'on ne sait pas prouver sien n'ouvre pas les gestes du demandeur
  (fail-closed), mais ne ferme pas une approbation légitime (fail-open) — le
  serveur, lui, sait, et son 422 rattrape.
- **`appendGesture` est INERTE au rejeu**, par l'uuid du message, comme le
  serveur (Q3) : c'est ce qui garantit qu'une relance rejouée ne compte pas
  double. Il se distingue d'`append`, qui écrase délibérément parce qu'il sert
  le pull.
- **Le dépôt relit la ligne avant d'écrire** : la copie de l'écran peut dater,
  et un geste jugé sur elle écrirait une transition absente de la table. Le
  refus est un **`ConflictFailure`**, pas un `ValidationFailure` — rien n'est à
  corriger dans ce que l'agent a tapé, et « Réessayez » ne l'aiderait pas.
- **Modifier suit la règle des gestes du demandeur** (en attente + sienne), ce
  que la V1 n'imposait pas : une demande accordée dont on réécrirait le montant
  ne serait plus celle qui a été accordée. C'est `depActions` de la maquette.
- **Refuser n'est jamais direct** : le bouton ouvre le panneau de motif, dans
  la fiche et non par-dessus, pour que le décideur garde le montant, la chaîne
  et le fil sous les yeux.
- **Commenter ne ferme pas la fiche** — on commente en lisant. C'est le seul
  geste dans ce cas, et son échec se dit **dans le champ** : une `SnackBar`
  levée sous une modale est inatteignable.
- **Un jalon franchi sans date affiche « — », pas « en attente »** : se
  contredire dans la même cellule serait pire que se taire. Cas courant tant
  que le pull ne rapporte pas les colonnes de décision.
- **Refuser reste `secondary` et non `danger`** : le socle n'a pas de variante
  rouge sortante, et deux boutons pleins côte à côte se disputeraient l'accent.
  Le rouge arrive au panneau.
- Le toast de dépôt ne dit plus « non payée » : une demande neuve est toujours
  en attente, donc la formule disait la même chose à chaque fois, et à tort.

### Décisions prises pendant DEP-10 / DEP-11 — ne pas les rouvrir

- Le **statut n'est plus saisissable** : le formulaire ne l'offre plus, et
  `ExpenseDeltaColumns` l'a fait passer du contenu vers la **famille serveur**
  (avec `paid_on`) — côté contenu, une saisie locale plus récente aurait retenu
  une décision prise ailleurs, qui serait restée invisible sur ce poste.
- Le fil est **lu avant** l'ouverture de la fiche et lui est passé en argument
  **obligatoire** : `null` = illisible, `[]` = rien à lire. Aucun `FutureBuilder`
  dans une modale, donc ni squelette ni anatomie d'échec de la règle n°10 — et
  « pas fourni » ne peut pas se lire « illisible ».
- **Aucun champ de saisie dans le fil avant DEP-12** : écrire est un geste, il
  lui faut sa permission et son entrée d'outbox. Un champ offert plus tôt
  fabriquerait des messages que rien ne pousse.
- `ExpenseMessageDao.append` ne touche **que** `last_message_at` sur la dépense —
  jamais `client_updated_at`, `sync_status` ni `updated_at`. C'est précisément le
  défaut du fil de la Discipline, et un test le verrouille. La fraîcheur **ne
  recule jamais** (comparaison textuelle d'ISO-8601 UTC, d'où la forme unique
  imposée par `ExpenseMessageLocalModel.at`).
- `threadFor` est **scopé par école**, comme `expensesForSchool`.
- Un acte inconnu se lit comme un commentaire libre ; un message dont l'horloge
  est illisible est **écarté** du fil, jamais placé au hasard.
- L'entrée d'outbox du geste s'ajoutera **dans la transaction de
  `appendGesture`** à DEP-14 (la méthode est née à DEP-12, `append` reste au
  pull) : aucun seam n'a été pré-construit pour elle.
- `expense_messages` est déclarée **fille de `expenses`** dans
  `tombstone_targets.dart` : sans cela, une purge serveur aurait effacé la
  demande en laissant son fil orphelin.
- La famille ambre a reçu son encre, `AppColors.feeStatusPartialInk` (#7A5A16) :
  `feeStatusPartial` fonde un pavé mais ne s'écrit qu'à **3,83** sur la bulle
  neutre, sous le seuil, là où l'encre atteint **5,44**.

## 13. Ce que la revue de clôture a trouvé (DEP-15)

Revue adversariale de la synchro, puis du domaine et des écrans — le même
exercice qu'à DEP-8, qui avait rendu dix-huit défauts. Sept ici, dont **un
bloquant**.

| # | Défaut | Corrigé par |
|---|---|---|
| 1 | 🔴 **La garde d'ordre gelait la demande pour toujours.** Elle lisait le plus ancien message *non accusé*, et un message mort reste au fil (il est append-only). Après le premier refus terminal, tout geste suivant échouait à vue — **y compris le geste neuf par lequel l'agent venait réparer**. | La garde lit le plus ancien message **en attente** ; l'échappatoire condamne la suite **sur-le-champ** (`rejectFrom`) au lieu de la découvrir une dispatch à la fois |
| 2 | Un **commentaire** refusé marquait toute la dépense « à corriger » — il n'y a rien à corriger dans une demande parce qu'un mot n'a pas pu s'écrire, et la ligne n'avait même pas bougé | `markGestureRejected` seulement si le geste transitionne |
| 3 | Un geste réussi laissait en place le « à corriger » qu'un geste précédent avait posé | `applyGestureAck` le lève — **et lui seul** : un refus de contenu attend une vraie correction |
| 4 | Un message **refusé** montrait son horloge comme un message accusé : le fil laissait croire que le geste avait eu lieu | `ExpenseThreadStateTag` : « en attente d'envoi » / « non envoyé », à la place de l'horloge |
| 5 | La fiche ouverte **depuis la file** offrait Supprimer / Dupliquer / Modifier, qui renvoyaient au registre **sans rien faire** | `allowShortcuts: false` depuis la file |
| 6 | L'abandon local d'une dépense jamais acceptée neutralisait contenu et retrait, **pas les gestes** — un 404 par geste, tous terminaux | `setLocalOnlyWithdrawal` neutralise l'agrégat `EXPENSE_GESTURE` entier |
| 7 | Une purge serveur (410) effaçait la demande et **laissait son fil** orphelin | `deleteExpense` emporte les messages |

Vérification de clôture : `flutter analyze` → **No issues found**,
`flutter test -j 4` **complet** → vert, **code de sortie capturé sans pipe**
(`| tail` masque le code et fait annoncer « 0 » sur une suite rouge).

### Écarts assumés avec la spec design (v2)

- **Le sous-menu ne porte pas le compteur d'attente** que la maquette met sur
  son onglet : le socle de menu n'a pas de pastille, et lui en donner une
  supposerait que la barre latérale s'abonne au registre des dépenses — une
  dépendance de `home` vers un module métier, pour un seul appelant. Le compte
  vit sur l'écran de la file, en tête.
- **Le sélecteur de rôle et le bandeau de rôle ne passent pas** : ce sont des
  outils de revue de la maquette, et les « trois rôles » n'existent pas dans
  l'application — ce sont trois combinaisons de permissions (F29). Seul le
  repli « vous voyez la file mais ne décidez pas » est repris.
- **La file ne modifie ni ne duplique** : la saisie appartient au registre.
- **« Refuser » reste `secondary` et non `danger`** : le socle n'a pas de
  variante rouge sortante, et deux boutons pleins côte à côte se disputeraient
  l'accent. Le rouge arrive au panneau de motif.
- **Pas de palier « 40 de plus » sur la file** : une file qu'il faut paginer
  est une file qu'on ne traite pas.

### Tranché avec le back le 2026-09-25

Réponses du back en commentaires sur la page « Dépenses v2 — ce que le front
attend du back » (Claude Docs, artifact `4af59671-e169-4ea5-bc0b-35245434c6a1`).

- **`DEPOSIT` et `EDIT` sont écrits par le serveur.** `DEPOSIT` à la création
  seulement (corps = description, auteur = déposant, instant = le
  `clientUpdatedAt` borné) ; `EDIT` à chaque modification `APPLIED`, jamais sur
  un `SUPERSEDED` ni un rejeu, **corps vide**. uuid5 déterministes (dépense +
  acte, + `clientUpdatedAt` pour un `EDIT`). Le poste ne les écrit jamais en
  local : il les reçoit par le pull.
- **Une seule enveloppe pour les sept routes**, celle du poste :
  `{ action?, decidedAt, message: { id, body }, expectedClientUpdatedAt?, authorId }`.
  `reason` sort du contrat : le serveur recopie `message.body` dans
  `decisionReason`. `/messages` passe de `createdAt` à `decidedAt` en C2.
  `body` peut être vide, sauf pour un refus (422) et un commentaire (400).
- **`/resubmit` sur une copie serveur plus ancienne** → 409
  `TRANSITION_OUT_OF_ORDER`, rejouable, jamais un 422.
- **A11 abandonnée : `SELF_APPROVAL_FORBIDDEN` disparaît.** Seule la direction
  décide (DIRECTOR, SUPER_ADMIN), et refuser l'auto-approbation aurait gelé
  pour toujours les demandes du directeur. La propriété n'entre plus dans
  décider ; le code reste reconnu en lecture.
- **Droits (migration V140)** : `expense.decide` et `expense.reopen` →
  DIRECTOR, SUPER_ADMIN ; `expense.pay` → ACCOUNTANT, DIRECTOR, SUPER_ADMIN
  (**hypothèse non confirmée**) ; `expense.delete` retiré à ACCOUNTANT.
- **Reprise des données** : la production compte 3 dépenses, toutes `PAID`.
  V139.0.0 convertit les `UNPAID` en `APPROVED` avant toute descente ; les
  `PAID` reçoivent une décision datée de leur saisie, V140 un message de
  reprise. Le corollaire « `UNPAID` lu comme en attente » (§12) ne se
  produira donc pas.

Appliqué côté poste le même jour : décider offert sur sa propre demande
(`ExpenseGestureOwnership.othersOnly` supprimé), `reason` retiré du corps de
`/decision`, et le fil n'affiche plus de ligne vide sous un message au corps
vide.

### Ce qui reste, et qui ne dépend plus de nous

- 🔴 **La livraison back C0→C3.** Tant qu'elle n'est pas déployée, la poussée
  d'une dépense neuve sort du contrat servi (`enum [PAID, UNPAID]`) et meurt en
  400 terminal, et les sept routes de geste n'existent pas. **Rien ne fusionne
  dans `main` avant.**
- 🔴 **Release conjointe, back et front v2 ensemble, mise à jour des tablettes
  forcée.** La V1 de `main` lit tout statut autre que `PAID` comme non payé :
  les demandes `PENDING` et `REFUSED` y entreraient dans les totaux, et sa
  bascule payé / non payé serait ignorée puis écrasée au pull. Aucune fenêtre
  entre les deux déploiements.
- ⚠️ **`user_version` à incrémenter à la release** qui sème les trois droits
  (cf. §15).
- ⚠️ **`expense.pay` pour ACCOUNTANT** reste une hypothèse du back.

## 14. Hors périmètre v2

Seuils, paliers et délégation (une seule chaîne, la direction comme filet) ·
notification de relance (A14 : le badge d'onglet reste le seul canal) ·
référentiel fournisseurs, pièce jointe, budget par type, récurrence (la
duplication manuelle en tient lieu) · câblage de la caisse (la source de fonds
reste « envisagée » et ne débite rien) · clôture de période (une approbation
tardive recompte un mois déjà lu : comptablement juste, et cela fait bouger un
total passé) · **une file par agrégat au socle** : la garde de F31 est écrite dans
le module, sur un signal métier, comme les quatre autres modules qui ont eu le
même besoin ; un vrai ordonnancement par `aggregate_id` dans le moteur mérite son
propre lot et profiterait aussi aux paiements et aux ventes.

## 15. Pièges connus de la v2

- **Le moteur d'outbox n'ordonne rien par agrégat** : il ne lit jamais
  `aggregate_id`, poursuit après un `retry`, et le backoff retire une entrée de la
  course pendant 1 à 256 s. Tout ordre est à la charge du handler.
- **`blocked` n'est pas un statut** : c'est un `PENDING` repoussé de 5 s, sans
  tentative consommée — il ne s'empoisonne donc jamais.
- **Le palier va dans le bon escalier** : v49+ dans `tenant_migrations.dart`,
  `if (upTo(52))` et non `if (oldVersion < 52)`.
- **Dix tests hors module cassent** dès qu'on touche au socle : table figée des
  permissions, migration du registre, ordre d'enregistrement des pulls, clés de
  plan, placement du module dans le menu.
- **Les `.arb` n'écrivent que l'apostrophe droite** (zéro apostrophe
  typographique dans `app_fr.arb`) : un `find.text` qui cite une chaîne l10n doit
  **copier la valeur du `.arb`**, sinon il ne trouve rien — et les deux
  caractères se ressemblent dans le terminal.
- **`dart format lib/l10n/` suit `flutter gen-l10n`**, sinon le diff enfle de
  quinze cents lignes pour rien. Une clé à paramètre porte son bloc `@` juste
  après elle.
- **En test de widget, un cubit ne peint qu'à la seconde frame** : `pump()` deux
  fois, ne jamais conclure sur la première.
- **`intl` n'est pas une dépendance** : les dates passent par
  `MaterialLocalizations`. Et `enterText` avec la valeur déjà présente ne
  déclenche pas `onChanged` — le test serait vert pour une raison étrangère.
- **Le motif de refus nomme des fournisseurs et des collègues** : aucun corps de
  message dans un journal, ici comme côté serveur (`ExpenseMessage` et sa ligne
  locale ont `stringify = false`).
- 🔴 **Les permissions n'arrivent qu'au login.** Sans incrément de
  `user_version` à la release, un poste **déjà connecté** ne verra aucun bouton
  de décision — et gardera le bouton Supprimer que la comptabilité vient de
  perdre, pour un 403 terminal. À faire au moment où le back sème
  `expense.decide` / `expense.pay` / `expense.reopen`, pas avant.

---

# Partie III — v3 : déclarer, puis viser

> Rédigé le 2026-11-25 sur `main` (`80b10f5d`, palier local 88). Contrat :
> doc « Dépenses : déclaration et visa — contrat front »
> (https://claude.ai/artifact/8oKtzW4JJynUbo17eSchK5, rev 17 : arbitrages du
> 25/11 et réponses du back à Q1, Q2, C1-C4 comprises). **Le contrat fait foi** ; ce qui suit dit comment le poste
> le tient.

## 16. Ce que la v3 change

Une dépense peut naître **déclarée** : payée tout de suite, sortie de la caisse
à l'heure du décaissement, photo du bon jointe, et visée ensuite par le
promoteur. Le mode est choisi sur chaque bon, à sa création, et ne change plus.
Le circuit d'autorisation de la partie II reste tel quel.

Le statut et le visa sont **deux axes séparés** : `status` dit où en est
l'argent (`PAID`, ou `RETRACTED` une fois annulée), `visaStatus` dit si le
promoteur a contrôlé (`PENDING` · `VISAED` · `FLAGGED`). Un visa ne déplace
jamais le statut, et un statut ne se lit jamais pour savoir si une dépense est
visée.

## 17. Ce qu'on reprend, et d'où

Presque tout existe déjà ; le lot qui recode l'un de ces socles fait fausse
route.

| Besoin | Patron existant | Où |
|---|---|---|
| Prendre ou importer la photo | `DocumentCaptureService` + une politique par usage | `lib/core/capture/` |
| Garder les octets chiffrés hors ligne | `EncryptedBlobStore` (attente puis promotion) | `lib/core/storage/encrypted_blob/`, cf. `StudentPhotoBlobs` |
| Envoyer JSON + fichier depuis l'outbox | Dio à la main, partie JSON en `application/json` | `StaffDocumentTransferApi.upload`, `StaffDocumentOutboxHandler` (octets relus au dispatch, `LOCAL_BYTES_LOST`) |
| Relire la photo | `download` en octets, cache chiffré | `StaffDocumentTransferApi.download` |
| Ordonner les gestes d'une dépense | le fil, garde F31 + `rejectFrom` | `ExpenseGestureOutboxHandler._orderGuard` |
| Bloquer la clôture tant qu'un fait d'argent n'est pas parti | une requête de plus dans la sonde | `CashPendingProbeSql` |
| Savoir qu'une journée est close | `treasury_closures` | `TreasuryClosureDao` (n'a que `closedToday()` aujourd'hui) |
| « Jamais effacé, à régulariser » | la paie | `PayrollLedger.toRegularize` |

## 18. Décisions front v3 (F35 → F48)

| # | Décision |
|---|---|
| F35 | **La permission est l'interrupteur.** Le choix « Déclaration » n'apparaît qu'avec `expense.declare`, que seule la migration du back sème. Un front livré avant le back n'offre donc rien qui mourrait en 404 : **pas de release conjointe obligatoire**, contrairement à la v2. |
| F36 | `ExpenseMode` (`AUTHORIZATION` · `DECLARATION`) et `ExpenseVisaStatus` sont deux énumérations à part, lues avec tolérance : un `mode` absent ou inconnu se lit `AUTHORIZATION` (c'est ce que sont toutes les dépenses existantes), un `visaStatus` inconnu sur une déclaration se lit `PENDING` (le sens prudent : pas visée). `isFirm` ne change pas : une déclaration `PAID` compte, une déclaration annulée ne compte plus. |
| F37 | **Une déclaration = une seule entrée d'outbox**, d'un agrégat neuf `EXPENSE_DECLARATION:{expenseId}`, poussée en multipart. Elle **remplace** l'entrée de contenu `EXPENSE:{id}`, et n'y est jamais ajoutée : l'ancienne route refuse `mode = DECLARATION` (`EXPENSE_MODE_LOCKED`). Les octets sont relus dans le magasin chiffré au moment de l'envoi, comme pour une pièce du personnel. |
| F38 | **Le message `DECLARATION` est écrit sur le poste**, `PENDING`, dans la même transaction que la ligne, la photo en attente et l'entrée d'outbox. C'est lui qui ordonne : la garde F31 retient visa, signalement et annulation derrière la déclaration **sans une ligne de code de plus**. Accusée, la déclaration marque son message `SYNCED` ; refusée pour de bon, elle appelle `rejectFrom` et la suite meurt avec elle. **Confirmé par le back (Q2)** : l'accusé `APPLIED` porte la dépense entière, fil imbriqué, et `messages[]` rend ce message sous notre id. Un rejeu `SUPERSEDED` rend l'état du premier envoi : si celui-ci portait un autre message pour le même `expense.id`, c'est le sien qui fait foi, et le poste s'aligne dessus. |
| F39 | **Photo :** une politique `DocumentCapturePolicy.expenseVoucher` (5 Mo ; JPEG, PNG, PDF). Le contrat demande 1 600 px et une qualité de 80 : la politique gagne `maxImageDimension` et `jpegQuality` **par instance**, avec les valeurs actuelles (2 000 / 82) par défaut. Les pièces du personnel et des chapitres ne bougent pas (règle du socle partagé). Le WebP du contrat n'est pas produit par le poste : le reconnaisseur de type ne le connaît pas, et une image importée est de toute façon réencodée en JPEG. |
| F40 | **Les octets de la photo : une seule copie par dépense**, `v_{expenseId}`, dans un magasin chiffré à part (`expense_vouchers`, sa clé à lui). La photo ne change jamais : les octets scellés à la déclaration sont à la fois ceux que l'envoi relit et ceux que le détail affiche ; sur un autre poste, ce sont ceux que `GET …/voucher` a rangés. **« Viser » se règle sur la présence de cette copie**, pas sur une colonne : un magasin vidé (clé perdue) referme le bouton de lui-même. (Révisé à DEP-17 : la paire attente / affichage prévue d'abord n'apportait rien pour une photo immuable.) |
| F41 | **Visa d'office** : si le déclarant a `expense.decide`, la ligne naît `VISAED` et signée par lui, dès la saisie. C'est de l'optimisme, l'accusé réaligne. La règle lit la permission, jamais le rôle (confirmé, C3). Le serveur écrit alors au fil un message `VISA` d'id **uuid5 dérivé de `expense.id` et de `"VISA"`**, comme le dépôt (`NameBasedIds.of(expenseId, "DEPOSIT")`) : le poste fabrique le même id d'avance (`uuid` v5, déjà employé par `payroll_ids.dart`), et l'accusé ne double jamais le message. Ce message n'a pas d'entrée d'outbox : il voyage dans la déclaration. |
| F42 | **Viser et signaler sont deux gestes de plus** dans `ExpenseGesture` (actes `VISA`, `FLAG`) : ils ne déplacent pas `status` (`target = null`), ils portent une **cible de visa**. Ils passent par `EXPENSE_GESTURE`, l'uuid du message reste la clé d'idempotence, `/flag` exige un motif (`requiresNote`). Ils ne sont offerts que sur une déclaration ; visé est terminal. |
| F43 | **Annuler une déclaration = le geste `reopen` existant**, même route et même droit, mais la cible dépend du mode : `PENDING` en autorisation, `RETRACTED` en déclaration (visa effacé, sortie de caisse défaite par le serveur). `ExpenseTransitions` prend le mode en entrée ; une seconde table, pas des `if` dans la première. Une déclaration annulée est terminale : ni renvoi, ni visa, ni signalement. Elle s'affiche **« Annulée »**, jamais « Retirée ». |
| F44 | **Journée close ⇒ pas d'« Annuler ».** La journée lue est celle **de la sortie de caisse**, jamais celle de `paidOn` : le delta descend `cashDay` (date, `null` sans caisse dans la devise) et `afterClosure` (booléen). « Annuler » est caché si une clôture vivante de la devise existe **à `cashDay` ou après** (`TreasuryClosureDao.hasLiveClosureFrom(day, currency)`, à côté de `closedToday()`), ou dès que `afterClosure` est vrai, réponse de la caissière ou pas (Q6, option b : la dépense ne redescend pas quand la caissière répond, un champ `awaitsAnswer` serait vite périmé ; l'erreur va dans le sens prudent, « Annuler » caché à tort, jamais montré à tort). `cashDay` et `afterClosure` sont remplis pour toute dépense en espèces qui a une ligne au registre de caisse, mode autorisation compris ; sinon `null` et `false`. Le bouton est remplacé par un renvoi vers l'ajustement de caisse. Le serveur (`CashLedgerService.noLongerCounts`) refuse aussi quand une compensation « déjà en caisse » a annulé la sortie, ce que le poste ne voit pas : le refus `CASH_DAY_ALREADY_CLOSED` reste le filet. |
| F45 | **Un refus terminal de déclaration ne se corrige pas, il se régularise.** La ligne n'est jamais effacée : elle reste visible, marquée « Refusée par le serveur — à régulariser » avec le motif, mais **sort des totaux dès le refus** (le serveur ne l'a jamais comptée ; la compter ferait partir la clôture sur un attendu faux, `EXPECTED_CHANGED`). L'argent ne compte plus que par sa redéclaration. « Redéclarer » ouvre le formulaire prérempli, photo comprise, sous un **nouvel** identifiant, et abandonne la ligne refusée sur le poste dans la même transaction : jamais les deux à la fois. Rien ne remonte pour l'ancienne (C1, accordé). |
| F46 | **La sonde de clôture compte deux familles de plus** : les déclarations en espèces dont l'entrée `EXPENSE_DECLARATION` est `PENDING`, et les annulations de déclarations en espèces encore à envoyer. Une déclaration refusée (« à régulariser ») ne bloque pas la clôture, comme partout ailleurs dans la sonde. |
| F47 | **L'écran évite d'avance les refus** : type `STAFF_ADVANCE` absent du choix, photo et poids vérifiés à la capture, `expenseDate` dérivée de l'heure du décaissement (jamais saisie à part), heure bornée à maintenant. Il ne reste pour la file que ce que le poste ne peut pas savoir : un droit retiré, un type supprimé. |
| F48 | **Les codes du contrat entrent dans `ExpenseErrorCodes`** et se lisent dans `detailCode` (F34 tient). Tous les nouveaux 422 sont terminaux ; `409 DECISION_ALREADY_TAKEN` réaligne et ne rejoue pas, comme aujourd'hui. |
| F49 | **Le décaissement ne s'antidate pas** (écart de recette E1, porteur, 2026-11-26). Le bon de sortie n'a plus de champ jour/heure : `disbursedAt` = l'instant de l'appui sur « Déclarer », à l'horloge du poste. Une redéclaration garde le `disbursedAt` de la ligne refusée. Côté serveur, rien de neuf (accord back) : `disbursedAt` est borné au « maintenant » serveur, et une ligne dont la journée est close tombe sur la journée ouverte suivante avec `afterClosure` (réponse exigée avant la clôture suivante). Aucun refus par âge : un envoi hors ligne tardif et un antidatage ont la même forme. L'option du back (`declaredAt` au delta, visa d'office suspendu au-delà de 72 h d'écart) attend le porteur. |
| F50 | **L'écart décaissement → réception se voit au visa** (option du back validée par le porteur, 2026-11-26). La réception est `voucher.uploadedAt` (déjà au delta depuis la v89 ; `declaredAt` du contrat en est l'alias), donc aucun palier. Fiche et onglet « À viser » : « Déclarée N jours après le décaissement » dès un jour d'écart, jours comptés à l'heure de l'école ; ambre dans « À viser » au-delà de 72 h. Au-delà de 72 h, le serveur ne pose pas le visa d'office (la ligne reste `PENDING`) : la tablette reste optimiste, l'accusé réaligne. |
| F51 | **Le motif d'un refus se demande dans une modale par-dessus la fiche**, comme celui d'un signalement (recette staging, 2026-11-26) : le panneau ouvert sous le fil restait hors de vue. Même gabarit (`ExpenseReasonDialog`), rouge pour le refus, ambre pour le signalement ; le « Refuser » d'une ligne de file ouvre la fiche avec la modale déjà posée. Le refus en lot garde sa modale propre. |

## 19. Données locales v3 — palier **89**

⚠️ Prendre le palier libre au moment du lot : 88 est le dernier dans `main`
(`intitulés des colonnes de notes`), et la saisie des notes a réservé des
paliers à elle. Toujours dans `tenant_migrations.dart` (`if (upTo(89))`).

Sur `expenses`, en fin de table :

| Colonne | Type | Rôle |
|---|---|---|
| `mode` | TEXT NOT NULL DEFAULT `'AUTHORIZATION'` | figé à la création |
| `visa_status` | TEXT | `NULL` en autorisation |
| `visa_by_id`, `visa_by_name` | TEXT | dernier qui a visé ou signalé |
| `visa_at` | TEXT (ISO UTC) | instant du dernier visa ou signalement |
| `flag_reason` | TEXT | non nul si et seulement si `FLAGGED` |
| `disbursed_at` | TEXT (ISO UTC) | l'heure envoyée, et celle que « Redéclarer » reprend ; le delta la remplit par `paidAt` (porté depuis V210, = `disbursedAt` borné à maintenant) |
| `cash_day` | TEXT (`YYYY-MM-DD`) | journée de caisse de la sortie (F44), `NULL` sans caisse |
| `after_closure` | INTEGER (0/1) | sortie arrivée après une clôture |
| `voucher_id`, `voucher_content_type`, `voucher_size_bytes`, `voucher_uploaded_at` | TEXT / INTEGER | la fiche de la photo, sans ses octets |

Les octets ne sont jamais en base (F40). Le delta pull et l'accusé passent par
la même lecture (`expense_delta_columns.dart`) : un champ absent du delta ne
doit pas effacer un visa local en attente (même règle que les gestes v2).

## 20. Lots v3

Les lots DEP-16, DEP-17 et DEP-20 s'écrivent sans serveur. DEP-18, DEP-19 et
DEP-21 se codent sur le contrat, mais **ne se recettent qu'en staging avec le
back**. Grâce à F35, la branche peut néanmoins fusionner avant lui.

| Lot | Contenu | Tests attendus |
|---|---|---|
| **DEP-16 — Le modèle** | `ExpenseMode`, `ExpenseVisaStatus`, `ExpenseVoucher` ; les 3 actes (`DECLARATION`, `VISA`, `FLAG`) dans `ExpenseAct` ; champs de l'entité, getters `isDeclaration` / `isCancelledDeclaration` ; palier 89 ; delta et mappers ; `ExpenseTransitions` par mode (F43). Aucune UI. | lecture tolérante (F36), palier rejouable, delta sans visa n'efface rien, table des transitions des deux modes |
| **DEP-17 — La photo du bon** | `DocumentCapturePolicy.expenseVoucher` + dimensions par instance (F39) ; `ExpenseVoucherBlobs` (attente, promotion, cache) ; `ExpenseVoucherApi.download` + `voucherFor(expense)` dans le dépôt, `404` = pas de photo. | défauts des autres politiques inchangés, promotion atomique, magasin vidé ⇒ « pas vue » |
| **DEP-18 — Déclarer** | permission `expense.declare` (`Perm`, `kExpenseDeclareAccess`, `kGuardedWriteActions`, copie du template de `role_journeys_test.dart`) ; `DeclareExpenseUseCase` (F41, F47) ; transaction ligne + message + photo + entrée (F37, F38) ; `ExpenseDeclarationOutboxHandler` multipart, classement des codes (F48), accusé ⇒ photo promue, refus ⇒ « à régulariser » + `rejectFrom` (F45) ; sonde de clôture, famille (i) (F46) ; DI. | rejeu `SUPERSEDED` inerte, octets perdus ⇒ `LOCAL_BYTES_LOST`, aucun refus terminal n'efface la ligne, visa retenu derrière la déclaration, sonde |
| **DEP-19 — Viser, signaler, annuler** | gestes `visa` / `flag` (F42) : payload, routes Retrofit (`build_runner`), `writeAccessFor`, politique par mode ; `reopen` ⇒ `RETRACTED` en déclaration (F43) ; `isClosed(day, currency)` (F44) ; sonde, famille (j) (F46). | `DECISION_ALREADY_TAKEN` réaligne, `DECLARATION_CANCELLED` terminal, visé terminal, « Annuler » absent sur journée close |
| **DEP-20 — Le bon de sortie** | bascule « Déclaration / Pour autorisation » en tête du formulaire (avec le droit, sans `STAFF_ADVANCE`) ; bloc photo (caméra, photothèque, PDF) avec aperçu ; heure du décaissement (maintenant, vers le passé seulement) ; note sur l'accord reçu. `expense_form_dialog` (212 l.) et `expense_form_fields` (214 l.) sont déjà près de la cible : le bloc déclaration va dans ses propres fichiers. | formats de référence et texte ×1,3 (règle 13), cibles ≥ 48 dp, `EteeloDialogBody` pour le clavier |
| **DEP-21 — Registre, file, détail** | badge de visa (« À viser » · « Visée » · « Signalée »), « Annulée », « à régulariser » ; filtre sur les trois états de visa ; onglet **« À viser »** dans la file existante, sous `expense.decide`, plus anciennes d'abord, vignette ; détail : photo en grand, Viser / Signaler (motif), « Viser » fermé tant que la photo n'est pas sur le poste (F40), Redéclarer (F45). | `switch` exhaustifs sur les deux axes, onglet absent sans le droit, états partagés (règle 10) pour le chargement de la photo |
| **DEP-22 — Revue et clôture** | revue adversariale (liste money-grade), suite complète sans pipe, `flutter analyze` **après** le commit, mise à jour de `CLAUDE.md` (ligne `expense`). | — |

**Ordre :** DEP-16 → DEP-17 → DEP-18 → DEP-19, puis DEP-20 et DEP-21 (DEP-20
peut partir dès DEP-18). Une PR par lot, ou une seule à la fin : au choix de
l'utilisateur.

### État d'exécution (2026-11-25, branche `feat/expense-declaration`)

| Lot | État |
|---|---|
| DEP-16 | ✅ commité |
| DEP-17 | ✅ commité (F40 révisé : une seule copie de la photo) |
| DEP-18 | ✅ commité |
| DEP-19 | ✅ commité ; `CashClosureReader` ajouté au socle (`lib/core/money`) |
| DEP-20 | ✅ commité ; défaut du formulaire : « Pour autorisation » |
| DEP-21 | ✅ commité ; l'onglet « À viser » de la file n'a pas d'adresse propre |
| DEP-22 | ✅ revue adversariale jouée, 17 défauts corrigés (ci-dessous) |

### Ce que la revue de DEP-22 a trouvé (trois relecteurs, sans mon avis)

| Défaut | Correction |
|---|---|
| Redéclarer une refusée déjà accusée, ou deux fois, comptait deux fois l'argent | `_abandon` exige une refusée **vivante** ; sinon la transaction est défaite (`ConflictFailure`) |
| « Supprimer » offert sur une déclaration : une refusée disparaissait sans régularisation | aucun « Supprimer » sur une déclaration |
| Une déclaration empoisonnée (1 000 tentatives) restait comptée et gelait ses gestes | **corrigé puis défait** (remarque du back) : une absence d'accusé n'est pas un refus — le serveur a peut-être la dépense, la redéclarer la compterait deux fois. Elle reste payée, comptée, relançable depuis la feuille des erreurs (le rejeu rend `SUPERSEDED`). Seul un payload illisible, jamais parti, passe « à régulariser » |
| Viser / signaler / annuler offerts sur une refusée, inconnue du serveur (404, motif d'origine écrasé) | plus aucun geste sauf commenter ; hors de la file « À viser » |
| Un poste d'avant la v3 a pu ranger des déclarations en demandes | le palier 89 fait repartir le flux `expenses@…` de zéro |
| Une clôture descendue après l'ouverture de la fiche n'empêchait pas l'annulation | règle rejugée au moment du geste ; pas d'« Annuler » sans la règle |
| L'accusé ressuscitait une ligne retirée localement | `deleted_at` respecte `withdrawal_pending_at`, comme le contenu |
| Une horloge reculée datait un geste avant la déclaration | un geste prend au moins la milliseconde après le dernier message du fil |
| 404 / 405 sans code (déploiement en cours) rendait toutes les déclarations « à régulariser » | rejoués |
| Redéclarer en basculant vers « Pour autorisation » ne faisait rien | la bascule est cachée en redéclaration |
| Vignettes de la file « À viser » décalées après un visa | une clé par ligne |
| Titre du panneau de signalement débordant à 360 dp, texte ×1,3 | `Flexible` |
| Borne du calendrier au jour de la tablette, pas de l'école | jour de l'école |
| « Viser » ouvert sur une photo illisible | refermé quand l'image ne se décode pas |
| Note « journée close » affichée avant la réponse de la règle | attend la réponse |
| Date de la file « À viser » à l'heure de la tablette | heure de l'école |
| Séparateur du compteur d'onglet en dur | clé l10n |

**Règle (accord back, 2026-11-25)** : « à régulariser » ne vise **que** les
refus du fond (4xx avec réponse). Une ligne descendue au flux porte un numéro
et n'est donc jamais redéclarable (`isDeclarationToRegularize` et `_abandon`
exigent `number == null`) — la seconde parade du back, déjà tenue.

Non retenu : `visaBy*` posé aussi sur un signalement — c'est le contrat
(« qui a visé ou signalé en dernier »).

**Écarts assumés** (pas de maquette Claude Design pour la v3 : les écrans
suivent les patrons du module) :
- un bon en PDF s'affiche comme une marque « Bon en PDF », sans visionneuse ;
- l'onglet de la file et le filtre de visa vivent dans l'état de l'écran, pas
  dans l'adresse ;
- `expense.declare` reste hors de `kGuardedWriteActions` tant que le back ne
  l'a pas semée (même raison que les trois droits du circuit).

## 21. Questions encore ouvertes

| # | Question | À qui | Bloque |
|---|---|---|---|
| Q1 | ✅ Tranché (back, 2026-11-25) : journée de la sortie, `cashDay` + `afterClosure` dans le delta (F44) | — | — |
| Q2 | ✅ Tranché (back, 2026-11-25) : le message revient sous notre id ; visa d'office = message `VISA` d'id uuid5 (F38, F41) | — | — |
| Q7 | ✅ Vérifié par le back (`ExpenseDeclarationService.declare`, test `replay`) : un rejeu d'un id déjà déclaré rend **toujours** 200 `SUPERSEDED` avant toute validation métier — annulée entre-temps comprise (`RETRACTED`, le poste s'aligne). Seuls passent avant : 403 (permission ou auteur, retenu), 400 / `DOCUMENT_TOO_LARGE` (impossibles sur un envoi identique accepté), `EXPENSE_MODE_LOCKED` (l'id porte une demande : rien d'écrit, terminal) | — | — |
| Q6 | ✅ Tranché (back, 2026-11-25) : option (b), pas de `awaitsAnswer` ; noms des champs confirmés, `voucher.id` = id de la dépense | — | — |
| Q5 | ✅ Tranché (back, 2026-11-25) : uuid5 RFC 4122 standard, **espace de noms = l'`expenseId` lui-même**, nom = `"VISA"` seul en UTF-8 (vecteur au §22) | — | — |
| Q3 | Le rapport de caisse journalier mentionne-t-il les déclarations non visées du jour ? | produit | rien côté poste (rapport serveur) |
| Q4 | Notifier le promoteur quand des déclarations attendent son visa | produit | hors v3 |

## 22. Pièges à surveiller

- **Le moteur d'outbox n'ordonne rien par agrégat** (§15) : sans le message
  `DECLARATION` local (F38), un visa donné sur le poste déclarant partirait
  avant la déclaration et mourrait en 404.
- **Un 422 sur une déclaration n'est pas un 422 ordinaire** : l'argent est
  déjà sorti. Le chemin « à corriger » de la v2 (`markGestureRejected`) est
  le mauvais pour elle (F45).
- **La permission n'arrive qu'au prochain login ou rafraîchissement de
  session.** `user_version` est un champ **serveur** (ADR-010), et le back ne
  l'incrémente pas pour un ajout de droit : un bump effacerait la session de
  tout le parc (même choix qu'en V85, V86, V90, V140). Ne pas compter dessus ;
  le §15 se lit désormais ainsi.
- **Les octets de la photo ne doivent jamais apparaître dans un journal**, ni
  le motif d'un signalement (`stringify = false`, comme pour le fil).
- **L'id du message `VISA` d'office** (F41) se fabrique comme
  `NameBasedIds.of` du serveur : `Uuid().v5(expenseId, 'VISA')`, l'`expenseId`
  servant d'**espace de noms**, pas d'espace fixe comme dans
  `payroll_ids.dart`. Vecteurs à figer dans un test de DEP-18 (vérifiés par
  `uuid.uuid5` de Python le 2026-11-25 ; le back les met dans
  `ServerMessageIdsTest`) :
  - `expenseId = 7d0c5a8e-1b2f-4c3d-9e8f-0a1b2c3d4e5f` :
    `VISA` → `97d3f5b8-da8d-5cf2-9fd1-a2a80dff56c2`,
    `DEPOSIT` → `77d45430-dd26-5dbd-83c4-b8a0ba3a52fb` ;
  - contrôle RFC : espace DNS, `www.example.com` →
    `2ed6657d-e927-568b-95e1-2665a8aea6a2`.
- **Une déclaration n'a pas de message `DEPOSIT`** : son premier message est
  le `DECLARATION` du poste, sous son id.
- **Le magasin des bons n'a ni garde de session ni ménage des orphelins**
  (DEP-17). Les pièces du personnel effacent leurs octets quand le compte
  change ; une photo de bon reste. À trancher en revue (DEP-22) : une photo
  de bon n'est pas une donnée personnelle, mais un bon abandonné laisse un
  fichier derrière lui.
