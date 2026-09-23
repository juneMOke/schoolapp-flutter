# Module Dépenses — plan front (V1 + v2)

> **Où on en est, en une ligne** : la V1 est livrée dans `main` ; la **v2 —
> circuit de validation** est à mi-chemin sur la branche
> **`feat/expense-validation-circuit`** (lots DEP-9 à DEP-11 faits, DEP-12 à
> DEP-15 à faire) et **`main` n'en porte rien**. Tout est en **partie II**, à
> partir du §8 — c'est là qu'il faut reprendre. ⚠️ Lire d'abord l'encadré du §12 :
> le chantier est à moitié construit, et cela a deux conséquences vérifiées.

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
- Refus : `422 SELF_APPROVAL_FORBIDDEN` (auto-approbation refusée par la
  direction, sans réglage d'école), `422 REASON_REQUIRED`. **`422
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
| F29 | Aucun geste n'est offert pour échouer : `PermissionGate.access` croisé avec le statut et la propriété ; Approuver/Refuser **masqués** sur ses propres demandes |
| F30 | Le fil recopie le patron Discipline **sans ses défauts** : auteur = identifiant résolu, fraîcheur du fil dans sa propre colonne, et il remonte geste par geste au lieu d'être imbriqué dans la poussée du parent |
| F31 | **Le fil est le registre d'ordre** : un geste n'est dispatchable que s'il porte le plus ancien message non synchronisé de sa dépense, sinon `blocked` |
| F32 | « Corriger et renvoyer » = deux entrées dans l'ordre ; le renvoi attend l'accusé du contenu |
| F33 | Les actes du fil sont en **anglais** (décision utilisateur) : `DEPOSIT · REMINDER · APPROVAL · REFUSAL · PAYMENT · RETRACTION · REOPENING · CORRECTION · EDIT`, `null` = commentaire libre |
| F34 | Un 409 ne se lit **jamais** au seul code HTTP (voir §9) |

## 11. Données locales v2 — palier **50**

L'escalier hérité est clos à 48 : un palier neuf va dans
`tenant_migrations.dart` (`if (upTo(50))`), **jamais** dans `app_database.dart`.
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

Sur **`feat/expense-validation-circuit`** (base `a8ff5c7c`, le sommet de `main`
juste après la PR #56), **sans PR ouverte**. Chaque lot compile, passe
`flutter analyze` à zéro et sa suite ciblée ; la suite complète tourne au dernier.

> Note d'historique, pour qui verrait une divergence : ces commits ont d'abord
> atterri **dans `main`** en avance rapide (jusqu'à `e1da561a`, le 2026-09-23),
> puis `main` a été ramené à `a8ff5c7c` — décision explicite : **`main` ne garde
> aucune modification Dépenses tant que le circuit n'est pas fini** (l'encadré
> ci-dessous dit pourquoi). Les commits sont les mêmes, ils vivent désormais sur
> la branche seule.

| Lot | État | Commit |
|---|---|---|
| DEP-9 | ✅ ce document (partie II) | le commit qui le porte |
| DEP-10 | ✅ **cinq statuts** : énumération + `isFirm`, six sites binaires ouverts, `paidOn` dé-dérivé, palier v50 (volet statut), bascule payée/non payée retirée, compteurs du registre supprimés, `ExpenseTransitions` + matrice de transitions testée | `d25197b6` |
| DEP-11 | ✅ **le fil** : palier v50 (volet fil), 9 actes anglais, `ExpenseMessage`, `ExpenseMessageDao` (append atomique), `ExpenseRepository.thread()`, `ExpenseThreadPanel` dans la fiche, fiche découpée | `4d2a855c` |
| DEP-12 | ⏳ **les gestes et les droits** | — |
| DEP-13 | ⏳ **la file** | — |
| DEP-14 | ⏳ **la remontée, et l'ordre** | — |
| DEP-15 | ⏳ **revue et clôture** | — |

Vérifié au dernier commit : `flutter analyze` → **No issues found** ;
`flutter test -j 4 test/features/expense test/core/database test/core/offline/tombstone`
→ **504 verts**. La suite complète n'a pas encore tourné (elle est prévue à
DEP-15).

### ⚠️ Un circuit à moitié construit — deux conséquences vérifiées

Les statuts et le fil existent, les **gestes** et la **remontée** non. Un build de
la branche se comporte donc ainsi, et **ce n'est pas livrable en l'état** — c'est
la raison pour laquelle `main` n'en porte rien :

1. **La poussée d'une dépense neuve sort du contrat servi.** Le dépôt crée une
   demande en `PENDING` (`expense_repository_impl.dart:133`) et
   `ExpenseInputDto.toJson` envoie ce statut tel quel. Or l'`openApi.yaml`
   déployé déclare `ExpenseStatus: enum [PAID, UNPAID]`
   (ligne ~18126, « Binaire en V1 ») : les routes de geste et les cinq statuts
   sont **écrits dans les deux plans mais pas encore servis**. Un 400 de
   validation est classé terminal par F5 ⇒ la dépense reste sur le poste, ligne
   « à corriger », et **ne repart jamais**. Tant que le back n'a pas livré ses
   lots C0→C3, aucune dépense créée depuis cette branche n'atteint le serveur.
2. **Rien ne peut faire sortir une demande de « En attente ».** La bascule payée
   / non payée de la V1 a été retirée à DEP-10 et les gestes de décision
   arrivent à DEP-12/DEP-14. Comme le tableau de bord ne compte que l'argent
   **ferme** (approuvée + payée), une dépense saisie ne compte dans aucun total —
   et personne ne peut l'approuver ni la marquer payée.

Corollaire à surveiller, aujourd'hui **vide mais pas théorique** : un `UNPAID`
redescendu par le pull n'est plus connu du front (`ExpenseStatus.fromWire`
retombe sur `pending`) et se lirait « En attente », donc hors des totaux. Le
renommage défensif du palier 50 ne touche que les lignes déjà locales, pas ce que
le pull rapporte ensuite. C'est sans effet aussi longtemps que D11 tient —
**aucune dépense en base, ni en production ni en staging** — et c'est la
première chose à revérifier si une ligne apparaît.

**Porte de sortie** : la suite du chantier (DEP-12 → DEP-14) referme les deux
points, et la livraison back C0→C3 referme le premier. D'ici là : **rien ne fusionne
dans `main`, et pas de release du module Dépenses avant DEP-14 et la livraison
back.**

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
- L'entrée d'outbox du geste s'ajoutera **dans la transaction de `append`** à
  DEP-14 : aucun seam n'a été pré-construit pour elle.
- `expense_messages` est déclarée **fille de `expenses`** dans
  `tombstone_targets.dart` : sans cela, une purge serveur aurait effacé la
  demande en laissant son fil orphelin.
- La famille ambre a reçu son encre, `AppColors.feeStatusPartialInk` (#7A5A16) :
  `feeStatusPartial` fonde un pavé mais ne s'écrit qu'à **3,83** sur la bulle
  neutre, sous le seuil, là où l'encre atteint **5,44**.

## 13. Reprendre ici — ce qui reste

### DEP-12 — les gestes et les droits (sans serveur)

- Trois permissions neuves : `expense.decide`, `expense.pay`, `expense.reopen`
  (58 → 61), le registre d'accès, le masquage réactif, auto-approbation masquée
  (F29). ⚠️ **La table figée de `permissions_test.dart:34-36` rougit** tant
  qu'elle n'est pas complétée, et les permissions **n'apparaissent qu'au login** :
  sans incrément de `user_version` à la release, un poste déjà connecté ne verra
  aucun bouton de décision — et gardera le bouton Supprimer que la comptabilité
  vient de perdre, pour un 403 terminal.
- Les transitions **locales** : approuver, refuser avec motif, payer, relancer,
  retirer, corriger et renvoyer, annuler la décision — chacune écrivant son
  message par `ExpenseMessageDao.append`. `ExpenseTransitions` dit déjà ce qui
  est permis ; aucune paire absente de sa table ne doit être atteignable.
- La chaîne à trois jalons (`DepChain` de la maquette), les encarts de situation,
  le panneau de refus (motif obligatoire + motifs proposés), les toasts.
- Le champ de saisie du fil arrive ici, avec sa permission — et le marqueur
  « en attente d'envoi » d'un message non accusé (l'entité porte déjà
  `isPending`).

### DEP-13 — la file (sans serveur)

- Troisième sous-menu et sa route, badge d'attente compté sur **toute** la liste
  et non sur la période.
- Quatre compteurs, trois tris, sélection et lot local, bloc « approuvées, à
  payer », ancienneté d'une demande (`DepAgeTag` : tiède à 3 jours, chaud à 5).
- États : le vide de la file est une **bonne nouvelle** — il ne passe pas par
  l'anatomie d'échec de la règle n°10.

### DEP-14 — la remontée, et l'ordre (le cœur du lot)

- Agrégat `EXPENSE_GESTURE`, une entrée par geste, sept routes ; DTO de geste et
  de message ; l'entrée d'outbox entre dans la transaction de `append`.
- **La garde d'ordre de F31 ET son échappatoire**, plus l'attente du contenu de
  F32. ⚠️ L'échappatoire s'écrit **en même temps** que la garde, sinon elle
  devient un gel : `blocked` n'incrémente rien et ne s'empoisonne jamais. Si le
  geste le plus ancien part en `SYNC_ERROR`, ses suivants sur la même dépense
  sont marqués en erreur à leur tour et la ligne passe « à corriger ».
- **Les deux 409 et leurs conduites opposées** (§9, F34) ; les nouveaux
  `detailCode` traduits (`expense_error_codes.dart` + `expense_labels.dart` + les
  deux `.arb`) ; commentaire `api_error_parser.dart:88` à corriger.
- Delta enrichi au pull (les six colonnes de décision **et** `messages[]`, que
  `ExpenseDeltaColumns` ne porte pas encore) ; le pull **saute** un message encore
  `PENDING_SYNC` ; page ramenée à 50.
- Tests attendus : séquence de trois gestes rejouée dans l'ordre ; geste doublé
  par le backoff qui attend au lieu de partir ; prédécesseur en erreur qui libère
  ses suivants ; rejeu inerte ; `DECISION_ALREADY_TAKEN` qui réaligne sans
  rejouer ; `TRANSITION_OUT_OF_ORDER` qui rejoue sans réaligner.

### DEP-15 — revue et clôture

Revue adversariale ciblée (synchro, puis domaine et écrans — comme DEP-8, qui
avait rendu dix-huit défauts), puis la suite complète avec `-j 4` et **le code de
sortie capturé sans pipe** (`| tail` masque le code et fait annoncer « 0 » sur une
suite rouge).

> ⚠️ **La branche n'est pas livrable avant DEP-14** : sans la remontée, DEP-12 et
> DEP-13 laissent des gestes locaux qu'aucune file ne peut pousser. C'est aussi ce
> qui la tient hors de `main` (§12).

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
  `if (upTo(50))` et non `if (oldVersion < 50)`.
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
