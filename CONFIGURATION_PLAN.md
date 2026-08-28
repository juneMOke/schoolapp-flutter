# CONFIGURATION_PLAN.md — assistant de mise en service de l'école

> **Statut :** plan proposé (2026-08-28). Aucun lot ouvert. Aucune ligne écrite.
>
> **Origine :** `Configuration-Spec-standalone.html` (révision 2, « amendée sur
> l'API »), scratch IntelliJ `eteelo-connect/`. La révision 1 a été confrontée au
> code de la branche back `feat/parametrage-automatique-l0` ; huit arbitrages en
> sont sortis, tous intégrés ici.
>
> **Ce que le module fait :** l'établissement et son compte de direction existent
> déjà (provisionnés à la souscription). Ce module fait le reste — un assistant
> linéaire en 5 étapes qui déclare l'année académique, l'offre pédagogique et le
> catalogue de frais, puis **active** l'établissement en une transaction. Les
> mêmes étapes se rouvrent ensuite en onglets de réglages.
>
> **Docs de contexte :** `AGENTS.md` §"États partagés" · `CLAUDE.md` §règles
> non-négociables · ADR-014 (permissions de session) · `openApi.yaml` du back
> (⚠ `/provisioning/**` n'y est **pas** documenté — cf. §7).

---

## 1. Le fait déterminant

**Le back est prêt, le front n'a rien, et la porte d'entrée est murée.**

Les trois affirmations sont vérifiées, et la troisième est celle qui décide de
l'ordre des lots.

Côté back, sur `feat/parametrage-automatique-l0`, tout existe :
`ProvisioningController` sert `/catalog` et `/apply` (avec `dryRun`),
`ProvisioningRequest` / `ProvisioningPlan` / `ProvisioningCatalogResponse` sont
écrits, la permission `school.provisioning.write` est semée par
`V93.0.0__grant_school_provisioning.sql` sur `DIRECTOR` et `SUPER_ADMIN`.

Côté front, `grep -ril provisioning lib test` ne rend **rien**. La feature
`school` existe mais se limite à lire `ref_school` en local — aucune couche
réseau, aucun `/schools` dans `AppConstants`.

Et entre les deux, `lib/router/app_router.dart:176` :

```dart
if (isAcademicYearBlocking) {
  return isOnSplash ? null : '/splash';
}
```

`AcademicYearContextState.blocksNavigation` vaut `!hasData && status != failure`.
Une école **non paramétrée** n'a pas d'année académique — c'est sa définition.
Donc `hasData == false`, donc le routeur renvoie tout vers `/splash`, **y compris
`/configuration`**. Le module serait inatteignable exactement dans la seule
situation pour laquelle il existe.

C'est le même piège que celui consigné à l'ADR-015 : *une garde écrite mais
jamais branchée*. Ici elle est branchée, et c'est elle qui ferme la porte.

---

## 2. État des lieux vérifié

### 2.1 Ce que le back sert déjà

| Route | Permission | Vérifié dans |
|---|---|---|
| `GET /api/v1/provisioning/catalog` | `school.read` | `ProvisioningController.java:46` |
| `POST /api/v1/provisioning/apply[?dryRun]` | `school.provisioning.write` | `ProvisioningController.java:62` |
| `GET /api/v1/schools/{id}` | `school.read` | `SchoolController.java:28` |
| `PUT /api/v1/schools/{id}` | `school.write` | `SchoolController.java:41` |
| `GET /api/v1/bootstrap/current-year` | `school.read` | déjà consommée par le front |
| `POST /api/v1/classrooms` | `classroom.write` | déjà dans `AppConstants:52` |
| `POST·PUT·DELETE /api/v1/finance/tariffs` | `finance.grid.write` | déjà dans `AppConstants:69` |

`SchoolDto` porte exactement **huit champs**, tous `@NotBlank`, l'e-mail en plus
`@Email` : `name · country · city · district · municipality · address · phone ·
email`. Sigle, régime et agrément MINEPST n'existent pas — la spec a raison de
les retirer de la V1.

### 2.2 Ce que le back ne sert pas

- **`GET /finance/fee-codes` n'existe pas encore.** `grep -rn "fee-codes"
  src/main` est vide. **Sa livraison est engagée** (2026-08-28, D-5) : c'est le
  seul prérequis back qui conditionne le démarrage d'un lot (CFG-7).
  L'énumération `FeeCode` compte **23 valeurs** (pas 8) : aux huit de la spec
  s'ajoutent `ENROLLMENT`, `APPLICATION`, `ADMISSION`, `BOARDING`, `LAB_FEE`,
  `ACTIVITY`, `SPORTS`, `LIBRARY`, `TECHNOLOGY`, `DEVELOPMENT`,
  `SECURITY_DEPOSIT`, `PROCESSING_FEE`, `LATE_PAYMENT_FEE`, `REFUND`, `OTHER` —
  **les 23 sont exposés** à l'écran.
- **`/provisioning/**` n'est pas dans `openApi.yaml`.** La seule mention y est
  `platform.school.provision`, qui est une **autre** permission (§3.1).

### 2.3 ⚠ Le lot « Nommage » est en cours de livraison, non commité

Au 2026-08-28, `git status` de `eteelo-backend` montre **10 fichiers modifiés non
commités**, tous sur ce sujet : `Filiere.java`, `OfficialGrilleSummaryDto.java`
(+`filiereAbregee`), `ProvisioningCatalogService`, `ProvisioningPlanner` (+108
lignes), `ProvisioningCatalogResponse`, et +94 lignes dans
`ProvisioningPlannerTest`.

`ProvisioningPlanner:289-294` construit désormais le nom en trois morceaux —
libellé du niveau, abréviation de filière si ce n'est pas du tronc commun, lettre
si nécessaire — exactement la règle de la spec.

**Conséquence pour le plan :** le prérequis que la spec déclarait « Bloquant » est
en train d'être levé. Mais il n'est **pas commité**, donc pas figé : le contrat
`filiereAbregee` peut encore bouger. Le front ne doit s'y brancher qu'à partir de
CFG-6, et sur un commit, pas sur un arbre de travail.

> ⚠️ L'arbre de travail du back **a changé sous cette analyse** : `CatalogSectionView`
> avait 5 composants à la première lecture, 6 à la seconde. Consigné en mémoire, et
> confirmé ici. Toute lecture du back doit être refaite au moment d'écrire le code,
> et de préférence via `git worktree`.

### 2.4 Ce que le front a déjà et qu'il ne faut pas refaire

| Besoin de la spec | Existe déjà | Où |
|---|---|---|
| Cascade district → commune (Kinshasa) | ✅ | `assets/catalogs/address_geo_catalog.json` + `AddressGeoCatalog` (444 lignes) |
| Champs de saisie (texte, e-mail, téléphone E.164, date, select) | ✅ | `core/widgets/eteelo_*_input.dart` |
| Champs lecture seule (Pays / Ville) | ✅ | `core/components/fields/read_only_field.dart` — règle « readOnly = pleine couleur » |
| Squelettes de chargement | ✅ | `EteeloListSkeleton` / `EteeloSkeletonBox` (reduced-motion géré) |
| État vide (médaillon pointillé + action) | ✅ | `EteeloEmptyResult` |
| État d'erreur 4 types (réseau / 401 / 403 / 500) | ✅ | `EteeloErrorResult` + wrapper `XxxResultsErrorState` |
| Bascule segmentée (assiette du frais) | ✅ | `core/components/controls/segmented_tab_filter.dart` |
| Largeur max 1180 dp centrée | ✅ | `AppPageBackground` — **plafonne déjà à 1180** |
| Texture kuba de la barre de titre | ✅ | `core/widgets/kuba_pattern_layer.dart` |
| Stepper visuel (pastilles + traits) | ⚠ partiel | `enrollment/presentation/widgets/breadcrumb/` — `WizardBreadcrumb`, `WizardStepDot`, `WizardProgressBar` |
| Saisie de montant + devise | ✅ | `core/widgets/currency_field.dart` |

Le stepper est le seul cas ambigu : `WizardBreadcrumb` est une bande pleine
largeur sous l'AppBar, la spec décrit des pastilles numérotées dans une barre de
68 dp. La forme diffère, la mécanique (rang courant, franchi, atteignable, tap)
est la même. **Décision D-6** en §3.

---

## 3. Décisions à verrouiller avant d'écrire

### D-1 — La permission est `school.provisioning.write`, pas `platform.school.provision`

Le catalogue client `lib/core/auth/permissions.dart` connaît
`platformSchoolProvision('platform.school.provision')`, documentée comme **« ne
peut jamais apparaître dans un ensemble effectif »** (ADR-014 §2.13) : elle garde
`POST /schools`, la création d'établissement par la plateforme.

Ce module a besoin de l'**autre** : `school.provisioning.write`, semée par V93 sur
`DIRECTOR` et `SUPER_ADMIN`, absente du catalogue client.

→ Ajouter `schoolProvisioningWrite('school.provisioning.write')` à `Perm`, et la
table figée de `test/core/auth/permissions_test.dart`. **Ne pas réutiliser
`platformSchoolProvision`** : elle est une impasse par construction, et le module
n'ouvrirait jamais.

### D-2 — Les codes d'erreur typés doivent survivre à l'intercepteur

`lib/core/di/injection.dart:341-350` aplatit **400 et 422 sur la même**
`ValidationFailure('Invalid request data')`, et jette `code` et `incidentId`.
`429` n'est mappé nulle part.

Or le back sert `ApiErrorResponse{ timestamp, status, error, message, code,
incidentId }` avec `ApiErrorCode ∈ { BUSINESS_RULE, VALIDATION, UNAUTHENTICATED,
FORBIDDEN, NOT_FOUND, DUPLICATE, CONCURRENT_MODIFICATION, UNPROCESSABLE,
TOO_MANY_REQUESTS }`, et le module en a un besoin **de conduite**, pas
d'affichage :

| Reçu | Ce que l'écran doit faire |
|---|---|
| `400 BUSINESS_RULE` (année déjà existante) | **purger le brouillon** et revenir à l'étape 2 |
| `400 VALIDATION` | rester, signaler le champ |
| `422 UNPROCESSABLE` | afficher le message serveur **dans la carte du niveau fautif** |
| `500` | afficher `incidentId` en mono, avec bouton copier |
| `429` | compte à rebours, **pas** de « Réessayer » |

Deux conduites opposées derrière un même `ValidationFailure` : impossible à
distinguer aujourd'hui.

→ **Sous-classer, ne pas remplacer.** `ApiValidationFailure extends
ValidationFailure` et `ApiServerFailure extends ServerFailure`, porteuses de
`code` / `incidentId` / `serverMessage`. Les ~18 repositories qui testent
`is ValidationFailure` continuent de matcher sans être touchés ; le module
Configuration teste le sous-type. Ajouter `TooManyRequestsFailure` pour le 429.

**Se brancher sur `code`, jamais sur le texte** — le message est rédigé pour un
humain et changera.

### D-3 — La porte du routeur

`redirect` doit laisser passer `/configuration` malgré le gate académique, **et
seulement pour qui détient la permission** :

```
si isAcademicYearBlocking (ou hasBlockingFailure)
   et la destination est /configuration
   et permissions contient school.provisioning.write
→ laisser passer
```

Sans la troisième condition, la porte s'ouvre pour tout le monde sur une école
en panne de référentiel. Le splash doit en outre proposer **une issue visible**
vers `/configuration` quand le contexte est vide et la permission détenue — sinon
la route existe mais rien ne la désigne.

### D-4 — Le brouillon vit en base chiffrée, scopé (école, utilisateur)

Les étapes 2 à 4 ne construisent qu'un **brouillon local** — un unique
`ProvisioningRequest` — que le serveur ne voit qu'en simulation. Seule l'étape 1
écrit vraiment.

→ Table mono-ligne `provisioning_draft` en **schéma v30** (v29 aujourd'hui),
colonnes `school_id`, `user_id`, `payload` (JSON), `step`, `max_step`,
`updated_at`. Clé primaire composite `(school_id, user_id)`.

**Le scope n'est pas décoratif** : la conception « 1 tablette = 1 école » a déjà
produit dix flux à curseur nu (mémoire *multi-école*). Un brouillon non scopé
ferait reprendre l'assistant de l'école A sur la session de l'école B.

À détruire **au succès de l'activation, jamais avant** : un brouillon survivant
rejouerait l'assistant jusqu'au refus « année déjà existante », que rien à
l'écran n'expliquerait.

### D-5 — Le catalogue de frais est servi, et le front ne le filtre jamais

**Arbitré le 2026-08-28 :** le back livre `GET /finance/fee-codes`, et le front
s'y branche directement — **aucune constante Dart de repli**, aucune fonction à
débrancher plus tard. Le repli des huit types figés que proposait la spec est
abandonné : il n'a de sens que face à une route absente.

**Et les 23 codes sont exposés, pas 8.** La restriction à huit était un oubli de
la spec, pas une décision produit : le serveur accepte l'énumération entière
(`FeeCode`, 23 valeurs), et un directeur qui facture une bibliothèque ou un
laboratoire n'a aucune raison de se le voir refuser par l'écran.

Corollaire, à tenir : **le front n'applique jamais de liste blanche** sur ce que
la route sert. Un code ajouté côté serveur apparaît sans release client — c'est
la propriété que la constante détruisait, et la seule raison de consommer une
route plutôt qu'un fichier.

Deux conséquences qui ne se voient qu'à l'écriture, traitées en CFG-7 :
l'**ordre** d'affichage et les **montants indicatifs**.

### D-6 — Promouvoir le stepper, ne pas le dupliquer

`WizardBreadcrumb` / `WizardStepDot` / `WizardProgressBar` vivent sous
`features/enrollment/`. Le module Configuration a besoin de la même mécanique
sous une autre forme.

→ Promouvoir la mécanique dans `core/components/wizard/` (rang courant, franchi,
atteignable, tap borné par `maxStep`), et laisser chaque module habiller. Deux
steppers dupliqués divergeraient au premier amendement — c'est ce qui est arrivé
aux barres d'AppBar des dossiers élève avant `StudentDetailAppBar`.

### D-7 — `dueAt` : deux sérialisations, une fonction par route

Vérifié dans le back : `ProvisioningRequest.FeeInput.dueAt` est un **`Instant`**
(suffixe `Z` obligatoire), `FeeTariffDto.dueAt` et `CreateFeeTariffCommand.dueAt`
sont des **`LocalDateTime`** (suffixe `Z` interdit). Dette de contrat assumée,
non corrigée.

→ Deux fonctions nommées, une par route, dans le data layer. Jamais une
conversion recopiée à chaque appel. Sans `Z` sur `/provisioning/apply`, le corps
est illisible et l'appel rend 400.

### D-8 — Aucun référentiel pédagogique en constante Dart

Codes, libellés, ordre d'affichage, pré-cochage, sections proposables, nombre de
cours : **tout** vient de `GET /provisioning/catalog`. Le serveur refuse en 422
tout code qu'il ne connaît pas. Seules restent côté app **les couleurs d'accent
par cycle**, indexées sur le code servi, avec une couleur de repli pour un code
inconnu.

Corollaire : ne pas coder « Scientifique / Littéraire / Commerciale / Pédagogie »
— `LITTERAIRE` et `COMMERCIALE` ne sont servies par aucun barème. Et afficher
`cycle.name` (« Cycle Terminal de l'Éducation de Base », « Humanités Générales »),
jamais « Secondaire — CTEB ».

### D-9 — Le catalogue pédagogique vit en mémoire de session, pas en base

**Arbitré le 2026-08-28.** `GET /provisioning/catalog` est mis en cache pour la
durée de la session, clé sur `version`, et **rien n'est persisté**.

**Persister ne rendrait rien de plus possible.** Le module est structurellement
online : `dryRun` et `/apply` le sont, et les `counts` comme les noms de classes
viennent du plan — jamais calculés localement (§7.7). Même catalogue en base,
l'étape 3 hors ligne reste inerte. Ce serait une table payée pour un écran mort.
Le module est dans la même famille que `documents` : 100 % online, pas d'outbox,
et c'est assumé.

**Un cache persistant est un fichier de constantes qui se croit frais.** D-8
supprime le référentiel Dart parce qu'il *« divergerait au premier amendement du
catalogue »* — une table locale ne déplace ce défaut que d'un cran. Précédent
dans ce projet : les cours d'un exercice révolu restés à l'écran après le passage
online→offline, *ce que le serveur décidait à chaque appel étant devenu une
donnée à cadrer soi-même*. Ici la divergence ne se verrait qu'à l'activation, en
**422 code inconnu**, sur l'écriture irréversible.

**Le remède à la coupure est la fenêtre de chargement, pas le cache.** Charger le
catalogue à l'**entrée de l'assistant**, pas à l'entrée de l'étape 3 : le
promoteur passe une à deux minutes sur les étapes 1 et 2, et le catalogue est là
quand il arrive au cœur. Le point de fragilité se déplace vers un moment où rien
n'est encore investi.

Catalogue perdu malgré tout (processus tué par Android, redémarrage hors ligne) →
`EteeloErrorResult` type réseau + « Réessayer », **brouillon intact derrière**.
Une `version` différente au rechargement → jeter le cache et **re-simuler** ; ne
pas tenter de réconcilier un brouillon avec un catalogue amendé, c'est au 422 de
le dire.

---

## 4. Les lots

Ordre imposé par les dépendances. CFG-0 est un préalable transverse : sans lui,
les lots suivants sont écrits mais inatteignables.

### CFG-0 — Socle (aucune UI de module)

| Sous-lot | Travail | Fichiers |
|---|---|---|
| **0a** | `Perm.schoolProvisioningWrite` + table figée | `core/auth/permissions.dart`, `test/core/auth/permissions_test.dart` |
| **0b** | Failures porteuses de `code` / `incidentId` / message serveur ; `429` mappé ; parsing tolérant de l'enveloppe | `core/error/failures.dart`, `core/di/injection.dart:306-360` |
| **0c** | Porte du routeur + issue depuis le splash | `router/app_router.dart:176`, `features/splash/presentation/pages/splash_page.dart` |
| **0d** | Promotion du stepper au socle | `core/components/wizard/` (depuis `enrollment/.../breadcrumb/`) |

**Tests :** table de permissions figée ; un test par code d'erreur (le 400
`BUSINESS_RULE` ≠ 400 `VALIDATION` est le cas qui compte) ; un test de routeur
qui prouve que `/configuration` passe le gate **avec** la permission et **ne passe
pas** sans ; non-régression du stepper d'inscription après promotion.

> **Contre-épreuve obligatoire sur 0c** : débrancher la condition doit faire
> rougir un test. Un test qui vérifie seulement que la route existe ne prouve
> rien — c'est la leçon de `isPastCorrection` (mémoire *présence/motifs*).

### CFG-1 — Contrat & couche data

Modèles Retrofit + `@JsonSerializable`, miroirs exacts des records back :

- `ProvisioningCatalogResponse` → cycles / niveaux / sections (`officialCode`,
  `filiere`, `filiereAbregee`, `libelle`, `codeOfficiel`, `courseCount`),
  `warnings[]` par niveau
- `ProvisioningRequest` → `academicYear`, `defaultClassroomsPerLevel`, `cycles[]`,
  `fees[]` avec `appliesTo{scope, levelCatalogCodes}`
- `ProvisioningPlan` → `counts`, `cycles[].levels[].classrooms[]`, `fees[]`,
  `warnings[]`
- `SchoolDto` (8 champs)

- `FeeCodeDto` — le catalogue de frais servi par `GET /finance/fee-codes` (D-5)

Endpoints dans `AppConstants` (`/api/v1/provisioning/catalog`, `/apply`,
`/schools/{schoolId}`, `/finance/fee-codes`). `ProvisioningRepository` en
`Either<Failure, T>`, modèles → entités **dans le repository**.

Le catalogue pédagogique et le catalogue de frais sont tous deux **mis en cache
pour la durée de la session** et chargés à l'**entrée de l'assistant** (D-9), pas
à l'entrée de leur étape.

**Tests :** sérialisation aller-retour sur un plan complet ; le `Z` de `dueAt`
présent sur `/apply` ; un code inconnu ne fait pas exploser le parsing.

### CFG-2 — Brouillon local (schéma v30)

Table, DAO, repository, scope `(school_id, user_id)`. Reprise à l'étape non
validée. Destruction au succès de l'activation seulement.

**Tests :** un brouillon d'une autre école n'est jamais relu ; la reprise
restaure `step` et `maxStep` ; le succès détruit, l'échec conserve.

### CFG-3 — Chrome de l'assistant

Route `/configuration` (hors coquille, donc dans `kStandaloneRouteAccess` avec
`school.provisioning.write`), barre de titre 68 dp, stepper, zone scrollable
1180 dp centrée, `CfgSaveBar` en pied, toast bas-droite.

`CfgSaveBar` : Retour · message extensible · Enregistrer · Continuer. Les deux
boutons `disabled` si l'étape est invalide, en chargement, en erreur, ou si un
sous-formulaire est ouvert. Message : `saving` → « Enregistrement… », `saved` →
coche, sinon le hint de l'étape, sinon le message par défaut.

**BLoC en `registerFactory`**, `buildWhen` sur chaque zone.

### CFG-4 — Étape 1 · Identité de l'école

Lecture `GET /schools/{user.schoolId}` (formulaire **jamais vide**), écriture
`PUT` complet des huit champs — y compris `country` / `city` en lecture seule,
dont l'omission rend 400.

Cascade district → commune sur `AddressGeoCatalog`. Validation : huit champs non
vides ∧ e-mail. Message d'échec : « À compléter : » + **liste nommée** des champs
vides.

⚠ L'identifiant du chemin est confronté à celui du jeton : un écart rend **403,
pas 404**. Toujours passer `user.schoolId`, jamais un identifiant d'une session
antérieure.

### CFG-5 — Étape 2 · Année académique

Proposition d'après la date du jour (bascule au 1er juillet), dates au format
`jj/mm/aaaa` → **instants UTC** à l'envoi. Durée indicative `(fin − début)/30,44`.
`fin ≤ début` → étape invalide.

Pastille d'origine « Proposée automatiquement » / « Modifiée » + « Rétablir ».
**Pas d'identifiant d'année affiché** : il n'existe qu'après activation, et c'est
un UUID.

Renvoi explicite vers Résultats pour les périodes — ne pas ajouter de trimestres
ici.

### CFG-6 — Étape 3 · Cycles, niveaux & classes ★

Le cœur, et le lot le plus lourd. Dépend du commit back du nommage (§2.3).

- Bandeau de 4 totaux (**cycles, niveaux, classes, cours**) — **jamais calculés
  localement**, lus dans `plan.counts`
- Trois familles de rendu, décidées sur `sections.length` servi :
  1 section `filiere: null` → tronc commun, compteur simple ;
  plusieurs sections → **une ligne par filière**, un compteur par ligne (le
  compteur simple est refusé par le serveur) ;
  0 section → compteur simple + avertissement ambre
- Clé de colonne `levelCode` ou `levelCode|officialCode` — **jamais la position**
- La matrice n'est **pas** un produit cartésien : HG1 porte 4 barèmes, HG2→HG4
  n'en portent que 3 → 13 colonnes, pas 16
- Compteur ±, bornes 0–10 ; case = deux vues du même nombre (cocher → 1,
  décocher → 0)
- Réglage global « Classes par niveau », sans effet sur les niveaux à sections
- Noms de classes **lus dans `plan.…classrooms[].name`**, jamais concaténés
- `NO_OFFICIAL_GRID` lu dans `warnings`, **jamais déduit de `sections.isEmpty`**
- Simulation `dryRun=true` **en debounce** à chaque changement

**Tests :** la matrice 13 ≠ 16 ; la clé composite ; le refus du compteur simple
sur un niveau multi-barèmes ; le total à 0 bascule en état vide et désactive
« Continuer ».

### CFG-7 — Étape 4 · Frais scolaires

Un frais = type + montant + échéance + **assiette de niveaux** (jamais de
classes). Bascule segmentée « Tous les niveaux ouverts » (`ALL_OPENED_LEVELS`) /
« Certains niveaux » (`LEVELS` + pilules groupées par cycle).

**Le sélecteur de type porte les 23 codes servis** (D-5), ce que la grille de
pilules de la maquette ne sait pas rendre : dessinée pour huit, elle noierait à
vingt-trois les trois types qui comptent. → **Grille des usuels, puis un dépliant
« Autres types »** qui ouvre le reste. Le cas nominal garde la maquette, et rien
n'est hors d'atteinte.

⚠ **La liste des usuels est un ordre, jamais un filtre.** Elle ne décide que de
ce qui est en tête ; tout code servi reste sélectionnable, et un code servi
qu'elle ne nomme pas tombe dans le dépliant — jamais dans l'oubli. Un code
qu'elle nomme et que le serveur ne sert plus disparaît, sans erreur : on n'affiche
que l'intersection. C'est ce qui distingue ce tri d'une constante de référentiel,
que D-8 interdit.

**Montants indicatifs :** la spec n'en donne que pour huit types. Ils restent une
**aide à la saisie**, pas une donnée — les quinze autres ouvrent simplement sur un
montant vide. À reverser au back si la route venait à les porter (§6).

Montant fr-FR (virgule) → `amountInCents` (×100). Devise USD / CDF affiché
« FC », **totaux jamais additionnés entre devises**. Échéance pré-remplie à la
fin de l'année.

⚠ **Dissymétrie à ne pas perdre** : un frais saisi produit **autant de tarifs que
de niveaux dans son assiette**. Un minerval sur 20 niveaux = 1 ligne à l'écran,
20 entrées dans `plan.fees`. Le récapitulatif regroupe par `feeCode` ;
`counts.fees` compte les tarifs.

### CFG-8 — Étape 5 · Récapitulatif & activation

Quatre cartes en lecture, **toutes alimentées par le plan** (rien n'est
recalculé) : École · Année · Structure · Frais. Avertissements du plan en bloc
ambre, **affichés tels quels** (déjà rédigés en français), avec saut vers l'étape.

Liste de 4 contrôles, puis `POST /provisioning/apply` — **un seul appel, tout ou
rien**. Pas d'appel partiel de rattrapage. Échec → toast + bloc d'erreur, l'écran
de succès n'apparaît pas, **aucune donnée perdue** (transaction annulée côté
serveur, brouillon intact côté client).

Succès → détruire le brouillon, écran de mise en service, deux issues.

**Nuance à tenir dans le texte** : après activation, identité et frais restent
modifiables, **la structure est en lecture**. Ne pas promettre « la configuration
reste modifiable » sans réserve.

### CFG-9 — Réglages réouvrables

Mêmes widgets, coquille de l'app. Bandeau d'état déduit de
`GET /bootstrap/current-year` (il n'existe **pas** de statut sur l'école : une
année courante avec des classes *est* la mise en service).

Trois onglets modifiables + un en lecture : Identité · **Structure (lecture)** ·
Frais. L'onglet Année disparaît. `onNext = onSave`.

L'assistant **ne se rejoue pas** — le serveur le refuserait à l'étape 5. Le bouton
« Relancer » devient « **Préparer l'année suivante** », **désactivé en V1** avec
une infobulle qui dit pourquoi (arbitré le 2026-08-28, §9.3). Il attend un geste
serveur dédié, qui n'est pas planifié : ne pas le câbler sur `/apply`.

⚠ **Ne câbler aucune suppression de structure.** `DELETE /school-levels/{id}` et
`/school-level-groups/{id}` existent mais ne vérifient ni l'appartenance à l'école
de l'appelant ni que la cible est vide — ces entités ne portent pas de colonne
`school_id`. Sur un niveau peuplé, la base rend une violation de clé étrangère
remontée en **500**, pas le 409 attendu. `DELETE /classrooms/{id}` n'existe pas.

Sur l'onglet Frais, un tarif porte **un seul niveau** : la notion d'assiette de
l'étape 4 n'y existe plus.

### CFG-10 — Conformité des états partagés

À faire au fil, contrôlé en fin de parcours : squelettes (jamais de spinner),
états vides avec issue, `ErrorView` 4 types dans la carte de l'étape **et jamais
seulement en toast**, 403 sans « Réessayer », `LiveRegion` polie, reduced-motion.

Le sélecteur « Démo état » de la maquette est **un outil de recette — à ne pas
livrer en production**.

---

## 5. Localisation

Toutes les chaînes dans `app_fr.arb` **et** `app_en.arb`, puis `flutter gen-l10n`
**suivi de `dart format lib/l10n/`** (sans quoi 3 clés produisent 1500 lignes de
churn).

Volume estimé : ~180 clés. Les messages d'avertissement du plan
(`NO_OFFICIAL_GRID`, `LEVEL_WITHOUT_CLASSROOM`, `LEVEL_WITHOUT_FEE`) ne sont
**pas** à traduire — ils sont servis rédigés.

---

## 6. Ce qui reste au back

| Lot | État | Ce que le front fait en attendant |
|---|---|---|
| Nommage par filière | ⚠ **en cours, non commité** (10 fichiers) | rien à prévoir : le nom est lu du plan. Attendre le commit avant CFG-6 |
| `GET /finance/fee-codes` | ⏳ **attendu** (engagement du 2026-08-28) | rien : le front s'y branche directement, sans repli (D-5). CFG-7 est bloqué tant que la route n'est pas livrée |
| `displayOrder` sur les fee-codes | 💡 souhaité | le front trie sur sa liste d'usuels ; servi, l'ordre cesserait d'être un choix client |
| Montant indicatif sur les fee-codes | 💡 souhaité | 8 montants côté front, aide à la saisie seulement |
| Cloisonnement des `DELETE` de structure | ❌ absent | CFG-9 : onglet Structure en lecture, aucun DELETE câblé |
| `/provisioning/**` dans `openApi.yaml` | ❌ absent | s'appuyer sur la spec + les records Java |
| Grilles Littéraire / Commerciale | décision produit | invisibles du catalogue, ne rien coder |

---

## 7. Pièges

1. **La porte murée** (§1) — à traiter en premier, contre-épreuve par mutation.
2. **`platform.school.provision` n'est pas la bonne permission** (D-1) : la
   confondre livrerait un module qui ne s'ouvre jamais, sans erreur visible.
3. **Les codes d'erreur aplatis** (D-2) : sans eux, « année déjà existante »
   s'affiche « Invalid request data » et l'assistant boucle.
4. **L'arbre de travail du back bouge** (§2.3) : relire au moment d'écrire,
   passer par `git worktree`.
5. **Le brouillon non scopé** (D-4) : mémoire *multi-école*, dix flux déjà touchés.
6. **La dissymétrie frais → tarifs** (CFG-7) : un écran qui compte les lignes au
   lieu des tarifs affichera un chiffre que l'activation démentira.
7. **`counts` recalculés localement** : la spec l'interdit deux fois. Un total
   local qui diverge du plan est un engagement chiffré faux juste avant une
   écriture irréversible.
8. **Le `Z` de `dueAt`** (D-7) : absent → 400 ; présent sur `/finance/tariffs` →
   400 aussi. Deux fonctions, jamais une.
9. **`AppPageBackground` plafonne à 1180** : tout seuil responsive au-dessus rend
   la disposition large inatteignable (mémoire *contrôle des frais*).
10. **`mounted` après chaque `await`** dans les `StatefulWidget` de l'assistant —
    les étapes enchaînent lecture, simulation et navigation.

---

## 8. Ordre d'exécution proposé

```
CFG-0  socle (permission · erreurs · porte · stepper)   ← sans lui, rien n'est atteignable
  ↓
CFG-1  contrat & data          CFG-2  brouillon v30      ← parallélisables
  ↓
CFG-3  chrome de l'assistant
  ↓
CFG-4  étape 1     CFG-5  étape 2                        ← parallélisables
  ↓
CFG-6  étape 3 ★   (attend le commit back du nommage)
  ↓
CFG-7  étape 4     ← BLOQUÉ tant que GET /finance/fee-codes n'est pas livré
  ↓
CFG-8  étape 5 · activation
  ↓
CFG-9  réglages réouvrables
  ↓
CFG-10 conformité des états partagés + revue adversariale money-grade
```

**Definition of done, par lot :** `flutter analyze` clean · `flutter test` vert ·
`build_runner` relancé si modèle touché · les deux `.arb` + `gen-l10n` +
`dart format lib/l10n/` · chaque `Failure` mappée dans `_mapFailureToMessage()` ·
aucune string / couleur / dimension en dur · tests miroir sous
`test/features/configuration/`.

---

## 9. Décisions arbitrées le 2026-08-28

Les quatre questions ouvertes de la première rédaction sont tranchées. Elles sont
reportées dans les décisions du §3 ; consignées ici pour que l'origine de chacune
reste lisible.

| # | Question | Arbitrage |
|---|---|---|
| 1 | `GET /finance/fee-codes` : livrer côté back, ou figer 8 types côté front ? | **Le back le livre.** Le front s'y branche sans repli — pas de constante, rien à débrancher (D-5). CFG-7 en dépend |
| 2 | Les 15 types de frais non exposés : choix produit ou oubli ? | **Oubli.** Les 23 codes sont exposés ; le front ne filtre jamais ce que la route sert (D-5, CFG-7) |
| 3 | « Préparer l'année suivante » | **Désactivé en V1**, avec infobulle. Le geste serveur dédié reste à planifier (CFG-9) |
| 4 | Cache du catalogue : session ou persistance ? | **Session, sans persistance** — chargé à l'entrée de l'assistant, invalidé sur `version` (D-9) |

**Ce que l'arbitrage 1 change à l'ordre des lots :** CFG-7 devient le seul lot
dont le démarrage dépend d'une livraison back qui n'est pas encore commencée —
là où CFG-6 attend seulement un commit de travail déjà écrit (§2.3). Si la route
tarde, l'ordre reste tenable : CFG-8 ne lit que le plan, et sait s'écrire sur un
catalogue de frais vide.
