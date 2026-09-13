# Module Dépenses — plan front (V1)

> Rédigé le 2026-09-13 sur `feat/expense-register` (base `origin/main` 6252762e).
> Sources : spec design `ui_kits/app/Depenses-Frais-Fonctionnement-Spec.html`
> (+ maquette `Depense.jsx`, `DepenseViews.jsx`, `DepenseData.jsx`) et plan back
> « Ce que l'école décaisse » (artifact b25cccca), confronté au code Java de
> `eteelo-backend` (`feat/expense-register`, non commité à la rédaction) et à
> son `openApi.yaml`. **Le serveur fait foi** : là où la spec design parle
> d'un « dépôt serveur » et d'identifiants `DEP-0001` fabriqués par le poste,
> c'est le contrat qui l'emporte.

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
