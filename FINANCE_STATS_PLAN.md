# FINANCE_STATS_PLAN.md — le tiroir et la créance

> **Statut :** en cours de livraison (2026-09-01).
>
> | Lot | État |
> |---|---|
> | FS-0 · constantes et fixtures de contrat | ✅ livré |
> | FS-1 · recouvrement — modèles, entités, repo, usecase | ✅ livré |
> | FS-2 · caisse — modèles, entités, repo, usecase | ✅ livré |
> | FS-3 · les deux BLoCs + DI | ✅ livré |
> | FS-4 · la coquille à deux onglets | ✅ livré |
> | FS-5 · onglet Recouvrement (dette de lecture comprise) | ✅ livré |
> | FS-6 · onglet Caisse + démolition de l'ancien chemin | ✅ livré |
> | FS-7 · états partagés, a11y, l10n | ✅ livré |
> | FS-8 · recette croisée (après déploiement du back) | ⬜ 3 vérifications restantes |
>
> **Origine :** note de migration du back (artefact « Recouvrement & Caisse »,
> 2026-09-01) **confrontée au code réel** de `~/my_project/eteelo-backend`,
> branche `fix/finance-outstanding-per-charge`.
>
> ⚠️ **Le back n'a rien commité.** Le split vit dans l'**arbre de travail** de
> cette branche ; le HEAD (`6309c7f`) ne porte que le calcul du reste dû par
> créance. `FinanceStatsController.java` y est marqué supprimé, avec son service,
> ses DTO et ses tests. Il n'y a **pas de cohabitation** : le jour du
> déploiement, tout APK en circulation prend un 404 sur son tableau de bord.
>
> **Analyse d'impact :** artefact « Le tiroir et la créance »
> (`https://claude.ai/code/artifact/03380c44-5e44-4fb6-a82d-ca44025a8686`).
>
> **Docs de contexte :** `openApi.yaml` du back §Finance ·
> `MULTIDEVISE_PLAN.md` (la règle « jamais deux devises additionnées ») ·
> `BOUTIQUE_PLAN.md` (l'étanchéité de l'ADR-020, remise en jeu ici) ·
> `AGENTS.md` §« États partagés » · `CLAUDE.md` §règles non-négociables.

---

## 1. Le fait déterminant

**Un écran répondait à deux questions qui ne se posent jamais en même temps.**

`GET /api/v1/finance-stats` mêlait un **état** — où en est l'école de l'argent
qu'elle doit encaisser cette année — et un **flux** — combien est entré dans le
tiroir. Le sélecteur `period=week` demandait un attendu à la semaine ; les
échéances tombant en fin de mois, il valait zéro, et l'écran annonçait « 0
attendu » un jour de guichet chargé.

Le serveur tranche en deux routes :

| | `/finance-stats/recovery` | `/finance-stats/till` |
|---|---|---|
| Nature | état | flux |
| Paramètres | **aucun** | `period` (défaut `day`) · `date` · `month` · `week` |
| Contenu | attendu, encaissé, reste dû, taux — global et par poste ; 12 mois d'encaissements | total = frais + **boutique** ; ventilation des frais ; une barre par intervalle |
| Absent | — | aucun attendu, aucun dû, aucun taux |

La permission ne bouge pas : `finance.stats.read` ouvre les deux
(`@RequiresPermission(Wire.FINANCE_STATS_READ)` sur les deux contrôleurs,
vérifié).

---

## 2. Ce que la note ne dit pas

Quatre écarts entre la note de migration et le code réellement écrit côté
serveur. Trois sont **silencieux** : rien ne plante, l'écran affiche simplement
autre chose que ce qu'on croit lire.

### 2.1 `collectionRate` a changé de base, et la carte par poste devient illisible

Le taux vaut désormais `(expected − outstanding) / expected`, plus
`collected / expected`. Conséquence directe : un arriéré d'un **autre exercice**
qui se solde fait passer `collected` au-dessus de `expected` pendant que la
barre reste sous 100 %. La carte actuelle affiche exactement ces trois nombres et
rien d'autre — elle se contredira à l'écran.

`byFeeCode[]` porte `outstanding` : la table de migration ne le mentionne pas,
seul l'exemple JSON le montre, et le Javadoc du back le dit explicitement — c'est
lui qui rend la ligne lisible. **Il doit être affiché.**

### 2.2 Un bloc à zéro n'est pas un bloc absent, et c'est le cas courant

Le contrat garde **à zéro** toute devise de la grille tarifaire (et, pour la
caisse, du catalogue boutique). `byCurrency` n'est vide que si l'école n'a ni
grille ni mouvement.

Or l'état vide du front pend **entièrement** à `byCurrency.isEmpty`
(`finance_stats_success_view.dart`) : il ne se déclenchera pour ainsi dire plus,
et un jour creux à la caisse affichera une planche de zéros au lieu de « Aucun
mouvement sur la période ». Le message doit descendre **au niveau du bloc**.

### 2.3 « Supprimer la table locale des `FeeCode` » casserait trois écrans

`localizedFeeLabel` (`student_charge_fee_code_l10n_extension.dart`) sert aussi :

- `student_charge_designation.dart` — la désignation d'une créance ;
- `fee_control_fee_options.dart` — les options du contrôle des frais ;
- l'étape « Frais scolaires » du wizard d'inscription.

Aucun de ces trois ne reçoit de `label` du serveur. **La table reste** ; seul
l'écran de statistiques cesse de l'appeler.

### 2.4 Le `label` serveur nomme la nature, pas le frais de l'école

C'est « Minerval » pour `TUITION`, pas le libellé que la direction a rédigé sur
sa grille tarifaire — celui-là vit sur le tarif. Cohérent pour une ligne de
répartition, mais ne pas s'attendre à y retrouver le vocabulaire de l'école.

### 2.5 Hors périmètre, mais à savoir le même jour

Le même arbre du back change le sens de `firstEnrollments` / `reEnrollments` :
ils se départagent désormais sur le drapeau `formerStudent`, plus sur le type
d'inscription. **Aucun champ ne bouge** — rien à changer côté front — mais deux
KPI de l'écran Inscriptions changent de valeur au déploiement. À ne pas prendre
pour une régression.

---

## 3. Décisions tranchées

### D1 — Deux onglets, pas deux sous-menus ✅ *(tranché)*

Le sous-menu séparé achoppait sur un droit : un caissier boutique ne détient que
`boutique.sale.read` et n'aurait pas vu le total de ses propres ventes.

**Retenu : le tableau de bord Finances garde sa route et son entrée de menu, et
porte deux onglets** — *Recouvrement* et *Caisse* — qui représentent la dualité
état/flux à l'écran. Conséquences, toutes bonnes :

- `app_routes_names.dart`, `menu_constants.dart`, `menu_factory.dart`,
  `accueil_modules_factory.dart`, `module_access_registry.dart` et le `switch`
  de `home_page.dart` **ne bougent pas** ;
- `accueil_page_test.dart` — qui code en dur `findsNWidgets(15)` de sous-modules
  et le compte des « 3 pages » — **ne casse pas** ;
- une seule permission à porter, celle qui existe déjà.

### D2 — La fraîcheur se dit en relatif ✅ *(tranché)*

Encaissements et ventes boutique passent tous deux par l'outbox : le serveur ne
totalise que ce qui lui est parvenu. À la fermeture, hors ligne ou file non
vidée, l'écran **sous-compte sans le dire** — et c'est le seul écran du projet
qu'on compare à des billets.

**Retenu : une ligne discrète sous la bande KPI de la Caisse, au format relatif**
— « Arrêté à la dernière synchro · Il y a 1 h ». Pas de décompte d'écritures en
attente, pas de calcul local de la caisse : la pastille de la barre supérieure
porte déjà l'état de la file.

Le socle existe entièrement : `SyncStatusCubit` est fourni au niveau de
`main.dart` (donc lisible partout), porte `lastSyncAtMs` en **heure serveur**,
persisté, et les clés `syncLastSyncJustNow / MinutesAgo / HoursAgo / DaysAgo`
sont déjà traduites. Voir FS-6 pour le seul geste à faire : sortir le
formatteur de sa classe privée.

### D3 — Le total sur les barres, la part boutique dans les KPI ✅ *(tranché)*

`CycleBarChart` fixe la barre à 20 px, ne défile pas et pose un libellé sous
chaque barre : il a été dessiné pour douze compartiments, pas trente-et-un. Et
rien dans le socle ne dessine une barre **empilée** frais + boutique.

**Retenu :** les barres portent `total`, la ventilation frais/boutique vit dans
les KPI. C'est exactement l'arbitrage que le back a fait pour lui-même — il a
refusé de ventiler ses barres par poste, la ventilation vit sur le résumé, une
fois. Pas de variante empilée dans ce plan.

### D4 — Pas d'ancre en V1 *(décidé ici, révisable)*

Le serveur accepte `date` / `month` / `week` pour viser une fenêtre passée. Le
front ne les enverra **pas** en V1 : les quatre grains portent toujours la
fenêtre courante, et l'écran affiche `context.periodStart` / `periodEnd` pour
dire laquelle. Raisons :

- ni la note du back ni le besoin exprimé ne demandent un sélecteur de date ;
- les paramètres traversent déjà tout le front (`month` et `week` sont dans le
  BLoC, dans l'état et dans la requête) **et n'ont jamais été envoyés** : le
  chemin existe mais n'a jamais été parcouru, donc jamais éprouvé ;
- une ancre qui ne correspond pas à la période part en **400**, pas en silence.

Les paramètres restent dans la signature du datasource, toujours `null`. Le jour
où l'ancre arrive, la règle est écrite d'avance : **remettre l'ancre à zéro à
chaque changement de période**, sinon un simple clic d'onglet produit un écran
d'erreur.

---

## 4. Ce qui ne bouge pas

À dire explicitement, parce que chacun de ces points a été vérifié :

- **La permission** — `finance.stats.read` ouvre les deux routes.
- **La route et le menu** — conséquence de D1.
- **Le pattern `Either`** et le mapping des `Failure` — inchangés.
- **Les centimes** — tous les montants restent en centimes, CDF compris.
  `MoneyFormat` divise par 100 puis arrondit ; ne jamais tronquer le champ.
- **La règle multi-devise** — aucune conversion, jamais ; les blocs se lisent
  côte à côte et ne s'additionnent pas (cf. `MULTIDEVISE_PLAN.md`).
- **L'ordre du serveur** — `byCurrency` est trié par code ; les cartes KPI comme
  les sections descendent de **la même liste**, jamais de deux tris parallèles
  (le commentaire de `finance_stats_kpi_band.dart` explique pourquoi).
- **La lecture reste 100 % en ligne.** Aucun cache, aucune outbox, rien en base
  locale sur ce chemin. Ce plan ne l'ouvre pas.

---

## 5. Modèle de données — la carte des renommages

```
context                                  → context                    (inchangé)
byCurrency[].kpis                        → recovery · byCurrency[].kpis
byCurrency[].evolution                   → recovery · byCurrency[].monthlyCollected
byCurrency[].distributionByFeeType.items → recovery · byCurrency[].byFeeCode
                                           (le niveau « items » disparaît)
                                         + byFeeCode[].label       NOUVEAU
                                         + byFeeCode[].outstanding NOUVEAU
—                                        → till · timeZone                NOUVEAU
—                                        → till · byCurrency[].summary
                                             {total, fees, boutique, byFeeCode[]}
—                                        → till · byCurrency[].buckets[]
                                             {key, total, fees, boutique, isCurrent}
```

Arborescence cible :

```
data/models/
  stats_context_model.dart                    ← remonté d'un cran, partagé
  finance_recovery_response_model.dart        (barrel)
  finance_recovery_response_model/
    finance_recovery_response_model.dart
    recovery_currency_block_model.dart
    fee_type_item_model.dart                  (+ label, + outstanding)
    finance_evolution_model.dart              (inchangé, sert monthlyCollected)
    finance_evolution_bucket_model.dart
  finance_till_response_model.dart            (barrel)
  finance_till_response_model/
    finance_till_response_model.dart
    till_currency_block_model.dart
    till_summary_model.dart
    till_fee_code_amount_model.dart
    till_bucket_model.dart

domain/entities/
  finance_recovery.dart                       (barrel)
  finance_recovery/
    finance_recovery.dart · recovery_currency_block.dart
    fee_type_item.dart · finance_evolution.dart
    finance_evolution_bucket.dart · finance_evolution_granularity.dart
  finance_till.dart                           (barrel)
  finance_till/
    finance_till.dart · till_currency_block.dart · till_summary.dart
    till_fee_code_amount.dart · till_bucket.dart · till_period.dart
```

`fee_type_distribution_model.dart` et `fee_type_distribution.dart`
**disparaissent** : le niveau `items` saute.

`FinanceStatsPeriod` devient `TillPeriod { day, week, month, year }` et vit sous
`finance_till/`. **Ne pas le factoriser dans `core/entities/stats_period.dart`** :
le back a délibérément tenu `day` hors du jeu par défaut de son parseur, parce
que les stats d'inscriptions et de présences l'auraient accepté puis répondu
n'importe quoi, faute d'unité de compte à la journée. Le TODO de migration
inscrit dans `stats_period.dart` est **caduc pour la finance** — l'y suivre
rouvrirait exactement ce que le serveur vient de fermer.

---

## 6. Les lots

### FS-0 — Constantes et fixtures de contrat ✅

**Livré.** `flutter analyze` propre sur les chemins touchés, 15 tests verts.

- `app_constants.dart` : `financeRecoveryStatsEndpoint`
  (`/api/v1/finance-stats/recovery`) et `financeTillStatsEndpoint`
  (`/api/v1/finance-stats/till`), chacune documentée par ce qu'elle accepte —
  aucun paramètre pour l'une, `period` + ancre refusée en 400 pour l'autre.
- `test/features/finance/data/models/finance_stats_fixtures.dart` : les huit
  charges utiles de référence.
- `finance_stats_fixtures_test.dart` : 15 tests qui vérifient **les fixtures
  elles-mêmes**.

> **Correction d'ordonnancement.** Le lot devait aussi porter la scission de
> `finance_remote_data_source.dart`. Impossible : une signature Retrofit ne
> peut pas exister sans son type de retour, et les modèles de réponse
> n'arrivent qu'en FS-1 et FS-2. **Chaque méthode Retrofit part donc avec sa
> famille de modèles** ; `financeStatsEndpoint` et `getFinanceStats` sont
> conservés le temps de FS-0 (l'arbre reste vert) et disparaissent en FS-1.

**Les fixtures sont du JSON brut, pas des `Map` Dart.** Le projet construit ses
charges utiles en `Map` littérales, qui portent déjà les types que le modèle
attend : leurs nombres sont des `int`, leurs objets imbriqués des
`Map<String, dynamic>`. Elles ne disent donc rien des deux seuls endroits où la
lecture casse en vrai — un `as Map<String, dynamic>` sur un élément de liste, et
un entier que le décodeur rend en `double`. `jsonDecode` reproduit exactement ce
que Dio pose dans le modèle. (À ne pas confondre avec le piège connu, qui reste
entier : une fixture qui construit **l'objet** en Dart, elle, n'exerce jamais
`fromJson`.)

Fidélité au serveur, y compris là où elle surprend : `periodStart` / `periodEnd`
sont des `LocalDate` côté Java et descendent **sans heure** (`"2025-09-01"`),
quand `generatedAt` est un `Instant` horodaté. Les fixtures existantes du dépôt
posaient `"2025-09-01T00:00:00Z"` — `DateTime.parse` avale les deux, donc
personne ne l'avait vu.

Les huit fixtures : recouvrement mono-devise · recouvrement bi-devise dont une
**dormante à zéro** · recouvrement avec `collected > expected` sur un poste ·
recouvrement à montants flottants et code de devise en minuscules · caisse
`period=day` bi-devise · caisse `period=month` (31 barres, un dimanche creux) ·
caisse d'une journée sans mouvement · caisse `period=year` (axe `YYYY-MM`) ·
`byCurrency: []`.

**Le test garde les fixtures, pas le code.** Tout le reste de la feature se
vérifiera contre elles : une fixture qui violerait un invariant du serveur
ferait passer au vert un code incapable de tourner en production. Sont
épinglés : `total == fees + boutique` sur le résumé **et sur chaque barre** ;
`summary.total == Σ buckets[].total` ; `Σ byFeeCode[].amount == fees`, jamais
`total` ; `buckets` jamais vide ; la clé journalière partout sauf sur l'axe
annuel ; `outstanding` plancherisé dans `[0, expected]` ; le taux sous 100 quand
l'encaissé dépasse l'attendu ; le taux à 100 quand l'attendu est nul.

⚠️ **Ce qui n'est PAS épinglé, délibérément :** `Σ monthlyCollected[].value ==
kpis.collected`. Ce n'est pas un invariant — un versement rattaché à l'année
mais daté hors de sa fenêtre compte dans le KPI sans apparaître sur l'axe.
L'assertionner serait épingler un faux invariant, et le premier vrai cas de
production le ferait rougir.

---

### FS-1 — Recouvrement : modèles, entités, repository, usecase

**Livré.** `flutter analyze lib test` propre sur tout le dépôt, 43 tests verts
sur la surface `test/features/finance/data/`.

- Sept entités sous `domain/entities/finance_recovery/` + barrel, six modèles
  sous `data/models/finance_recovery_response_model/` + barrel.
- `FeeTypeItem` gagne `label` et `outstanding`.
- `stats_context_model.dart` **remonté** à `data/models/` : les deux familles
  le partagent, sans duplication.
- `getFinanceRecovery(@Extras() extras)` — aucun paramètre — sur le datasource,
  le repository, l'implémentation et `GetFinanceRecoveryUseCase`.

**Deux règles descendues dans le domaine**, plutôt que redérivées par chaque
widget qui en aura besoin :

- `FinanceKpis.hasNoExpectation` / `FeeTypeItem.hasNoExpectation`
  (`expected == 0`) — c'est là que se décide le tiret au lieu du 100 % ;
- `RecoveryCurrencyBlock.hasNoMovement` (`expected == 0 && collected == 0`) —
  et **pas** `collected == 0` seul : un bloc qui porte une créance entière à
  recouvrer est exactement ce qu'un écran de recouvrement doit montrer.

**Deux régimes de tolérance, et la frontière est le sens du chiffre :**

| Champ | Absent ⇒ | Pourquoi |
|---|---|---|
| `kpis` | **lève** → `ServerFailure` → état d'erreur | un repli à zéro afficherait « 0 encaissé » sur un tableau de bord d'argent, ce qui se lit comme un résultat |
| `byFeeCode`, `monthlyCollected` | section vide | ce sont des ornements du tableau de bord, pas son chiffre |
| `currency` | normalisée (`trim().toUpperCase()`), jamais refusée | une devise ajoutée par le serveur avant cette version du client ne doit pas emporter tout l'écran |
| `label` | repli sur le **code** dans `toEntity()` | un libellé générique confondrait toutes les natures inconnues ; le modèle, lui, reste la copie exacte du fil |

> ⚠️ **Correction de séquence.** Ce lot devait démolir l'ancien chemin. Il ne le
> fait pas : `getFinanceStats` nourrit encore le BLoC, l'écran et huit widgets,
> qui ne basculent qu'en FS-4 → FS-6. Le supprimer ici aurait rendu l'arbre rouge
> sur **cinq lots** — c'est-à-dire pendant toute la partie où `flutter analyze`
> est le seul filet. **La démolition est donc reportée à la fin de FS-6**, quand
> plus rien ne la référence. L'ancienne famille et la nouvelle coexistent d'ici
> là, et c'est sans risque tant qu'aucun fichier n'importe les deux.
>
> ⚠️ **Corollaire, et il a mordu tout de suite :** les deux familles portent des
> noms communs (`FinanceKpisModel`, `FeeTypeItemModel`, `FinanceEvolution*`).
> Dart ne s'en plaint qu'au **point d'usage**, pas à l'import — un fichier qui
> importerait les deux barrels compile jusqu'à ce qu'il nomme l'un des sept.
> Pendant la fenêtre de coexistence : **importer le fichier, pas le barrel.**
- `stats_context_model.dart` remonte d'un cran et devient commun aux deux
  familles (le projet duplique déjà ce modèle par module — attendances,
  enrollment, finance — c'est la convention, on ne la change pas ici).
- `FinanceRepository.getFinanceRecovery()` — **sans paramètre**.
- `GetFinanceRecoveryUseCase`.
- Le parsing reste tolérant là où il l'est déjà : devise normalisée
  (`trim().toUpperCase()`) et jamais refusée, `byCurrency` absent ⇒ liste vide.
  `label` absent ⇒ repli sur le code (le serveur le garantit, le client ne le
  suppose pas).

**Tests :** `finance_recovery_model_test.dart` sur les fixtures — dont le cas
`collected > expected` et le cas devise dormante.

---

### FS-2 — Caisse : modèles, entités, repository, usecase

**Livré.** `flutter analyze lib test` propre, 64 tests verts sur
`test/features/finance/data/`.

- Six entités sous `domain/entities/finance_till/` + barrel, cinq modèles sous
  `data/models/finance_till_response_model/` + barrel.
- `getFinanceTill` sur le datasource, le repository, l'implémentation, et
  `GetFinanceTillUseCase` — défaut `TillPeriod.day`.
- `TillCurrencyBlock.hasNoMovement` (`summary.total == 0`) : **le cas le plus
  fréquent de l'onglet**, une journée creuse dans une devise que l'école
  facture. Une seule vente boutique suffit à le rendre faux, et c'est testé.
- `FinanceTill.hasTimeZone` : le fuseau absent **se tait**. Affirmer « heure de
  Kinshasa » sans l'avoir reçu serait inventer le découpage d'une journée de
  caisse.

Même frontière de tolérance qu'en FS-1, appliquée au chiffre de cet écran-ci :
un `summary` absent **lève** (dire « rien n'est entré aujourd'hui » à un
caissier qui a le tiroir ouvert devant lui est pire que dire « erreur ») ;
`buckets` et `byFeeCode` absents cèdent (l'axe est un ornement, le total est le
chiffre).

> **Écart avec D4, assumé.** Le plan disait de garder `date` / `month` / `week`
> dans la signature Retrofit, toujours `null`. C'est exactement la plomberie
> dormante que le même plan reproche à `month` et `week` sur l'ancienne route :
> trois ans dans la signature, jamais envoyés une fois, donc jamais éprouvés.
> **La signature ne porte donc que `period`.** Les ancres arriveront avec le
> sélecteur qui les remplit — la règle de leur remise à zéro reste écrite
> d'avance en D4, et la famille de `Failure` qu'un 400 produit est déjà
> couverte par un test du repository.

---

### FS-3 — Les deux BLoCs + DI

**Livré.** `flutter analyze lib test` propre, **688 tests verts** sur
`test/features/finance`.

`finance_stats_bloc.dart` se scinde en `finance_recovery_bloc.dart` et
`finance_till_bloc.dart` (chacun avec ses `part` event/state).

**Recouvrement — un seul évènement.** L'état perd `selectedPeriod`,
`selectedMonth`, `selectedWeek` : il n'y a plus rien à choisir. Et comme il n'y
a plus de fenêtre à mémoriser pour la rejouer, le premier chargement et le
bouton « Réessayer » sont **le même geste** : `FinanceRecoveryRequested`, seul.
Le trio `Requested / Refresh / Reset` d'avant n'existait que pour ça — `Reset`
n'a d'ailleurs jamais eu d'appelant.

**Caisse — deux évènements.** `FinanceTillRequested({period})` (défaut
`TillPeriod.day`, envoyé explicitement : un défaut qui vit des deux côtés du fil
finit par diverger d'un seul) et `FinanceTillRefreshRequested`, qui rejoue la
fenêtre **retenue** — recharger après une coupure ne doit pas ramener l'écran au
jour courant sans le dire. Le grain est inscrit dans l'état **dès l'émission du
chargement**, pas à l'arrivée de la réponse : le sélecteur doit montrer ce
qu'on est en train de charger.

> **Écart avec le plan, sur les erreurs.** Le plan disait de garder l'enum
> `FinanceStatsErrorType` **et** d'ajouter le `Failure`. Les deux états ne
> portent que le **`Failure`**. Deux taxonomies parallèles de la même chose se
> désynchronisent, et c'est l'anatomie d'erreur partagée qui décide du
> médaillon, du titre et du geste — depuis le `Failure`, où un 500 porte en plus
> son code d'incident qu'un enum aurait perdu. L'ancien enum et son extension
> l10n restent en place pour l'ancien écran, et partent avec lui.
>
> `errorMessage` est bien mort : quatre phrases françaises en dur dans
> `_mapFailureToMessage()` (violation de la règle #4) que **personne ne lisait**.

DI : `GetFinanceRecoveryUseCase`, `GetFinanceTillUseCase`,
`FinanceRecoveryBloc`, `FinanceTillBloc` en `registerFactory`. **Deux fabriques
distinctes et non un bloc commun** : l'onglet Caisse ne se charge qu'à sa
première ouverture, et un bloc unique aurait appelé les deux routes au montage
pour un écran dont on ne lit qu'une moitié. L'ancien couple reste enregistré
jusqu'à la démolition.

**Tests :** 8 `blocTest` neufs — dont « un second essai efface l'échec
précédent », « un échec après un succès conserve la donnée déjà lue » et
« le rafraîchissement rejoue la fenêtre retenue, jamais le défaut ».

---

### FS-4 — La coquille à deux onglets

**Livré.** `flutter analyze lib test` propre, tests finance + accueil verts.

`FinanceStatsDashboardScope` fournit **les deux** blocs et **ferme les deux**.
La page devient une coquille : en-tête, `FinanceDashboardTabs`, puis l'onglet
courant dans un `AnimatedSwitcher`.

`FinanceDashboardTabs` — widget local à la finance, sur l'anatomie de
`DisciplinaryDossierTabs` (médaillon accentué, libellé, descriptif, carte
surélevée sur l'onglet actif) :

| Onglet | Libellé | Descriptif | Accent |
|---|---|---|---|
| 1 | Recouvrement | Ce qu'il reste à encaisser cette année | `bleuArdoise` |
| 2 | Caisse | Ce qui est entré dans le tiroir | `terreCuite` |

**Chargement paresseux.** `FinanceRecoveryRequested` à l'`initState` ;
`FinanceTillRequested` à la **première ouverture** de l'onglet 2, jamais aux
allers-retours suivants. Le test le vérifie sur le **cas d'usage**, pas sur
l'évènement : ce qu'on veut interdire est l'appel réseau.

**La ligne de contexte disparaît.** Elle ne portait que l'année scolaire — que
l'en-tête affiche déjà — et le sélecteur de période, qui n'a plus de cible sur
le recouvrement.

**Les widgets du recouvrement sont convertis en place** (`success_view`,
`kpi_band`, `fee_type_section`, `evolution_section`) : `FinanceStats` →
`FinanceRecovery`, `evolution` → `monthlyCollected`, `distributionByFeeType` →
`byFeeCode` (la section prend désormais une `List<FeeTypeItem>`, le niveau
`items` ayant sauté). Leurs trois suites de tests suivent.

**L'onglet Caisse ouvre avec sa bande KPI** — `FinanceTillKpiBand`, **trois
cartes et aucun taux** : ici rien n'est dû, rien n'est attendu. Le reste de
l'onglet (sélecteur de fenêtre, axe, fuseau, fraîcheur) est FS-6.

> ⚠️ **Deux cartes homonymes à un onglet d'écart.** La première carte de la
> caisse s'appelait « Total encaissé » — exactement le libellé de la première
> carte du recouvrement, qui compte l'**année**. Un test l'a révélé en trouvant
> deux fois le même texte. La caisse dit désormais **« Total du tiroir »** :
> c'est le vocabulaire du contrat lui-même, et il ne peut pas se confondre avec
> le cumul de l'exercice.

**Erreurs.** Nouvelle extension `financeStatsMessage` branchée sur le
`Failure`, qui réutilise les neuf clés `financeStats*Error` existantes. L'ancien
enum et son extension restent pour l'ancien code, et partent avec lui.
`FinanceStatsErrorView` et `FinanceStatsLoadingView` sont conservés tels quels —
l'anatomie partagée (règle #10) est le travail de FS-7.

**Tests :** 5 `testWidgets` neufs sur la coquille — ouverture sur Recouvrement
sans appel à la caisse, descriptifs présents, caisse chargée une seule fois,
allers-retours sans rappel, et un échec de caisse qui laisse intact le
recouvrement déjà lu.

---

### FS-5 — Onglet Recouvrement

**Livré.** `flutter analyze lib test` propre, **699 tests verts** sur
`test/features/finance`.

1. **Le filtre de période était déjà parti** avec la ligne de contexte, en FS-4.
2. **Le libellé vient du serveur.** La section par poste n'appelle plus
   `localizedFeeLabel` et affiche `item.label` — le mapping ayant déjà fait
   retomber un libellé vide sur le code, le widget n'a aucune branche à tenir.
   La table locale **reste en place** pour ses trois autres appelants.
3. **Le reste dû est affiché**, entre l'attendu et la barre.
4. **« Sans objet » quand rien n'était attendu**, dans la bande KPI (mono- et
   multi-devise, où la ligne nomme sa devise comme les autres) **et** sur la
   carte de poste. La barre de progression suit la même règle : à 100 % sur un
   poste dormant, elle affirmerait un recouvrement qui n'a pas eu lieu.
5. **Le bloc à zéro se dit.** `RecoveryCurrencyBlock.hasNoMovement` remplace les
   deux graphiques par une ligne discrète — la devise garde sa place dans la
   bande KPI, où ses zéros sont justes. L'état vide global
   (`byCurrency.isEmpty`) est conservé ; il devient le cas rare.

> ⚠️ **Deux tests épinglaient le comportement d'avant.** Ceux de la section par
> poste vérifiaient que le libellé venait de **la table locale** (« Frais de
> scolarité » pour `TUITION`) et que l'inconnu retombait sur son code. Le
> premier a été **retourné** — c'est désormais « Minerval », celui du serveur,
> et l'ancien libellé est explicitement absent. Le second survit tel quel : il
> décrit une règle qui n'a pas changé de sens, seulement de lieu.

**Tests :** 8 `testWidgets` sur la section par poste, la bande KPI et la vue de
succès — dont « une créance non payée n'est PAS un bloc sans mouvement », qui
garde la distinction du côté visible.

### FS-6 — Onglet Caisse

**Livré.** `flutter analyze lib test` propre, **702 tests verts** sur
`test/features/finance`.

**Sélecteur de période** — `SegmentedTabFilter<TillPeriod>`, quatre grains,
`day` par défaut. Il **coiffe** l'onglet, hors du `BlocBuilder` : faire
disparaître pendant le chargement le contrôle qu'on vient d'actionner rendrait
la bascule de grain impossible à répéter. « Aujourd'hui » est la seule étiquette
neuve ; les trois autres existaient déjà.

**Bande KPI** — trois cartes, aucun taux (livrée en FS-4).

**La fenêtre se dit** — « Journée du 15 mai 2026 » sur un jour, « Du … au … »
au-delà, plus la mention du fuseau. Les bornes viennent de
`context.periodStart` / `periodEnd`, **jamais d'un `DateTime.now()` local** : la
journée de caisse se découpe dans le fuseau de l'école, et un fuseau absent se
tait au lieu d'être deviné.

**La ligne de fraîcheur** — « Arrêté à la dernière synchro · Il y a 1 h », lue
sur `SyncStatusCubit`, avec « Jamais synchronisé » quand rien n'est connu. Le
formatteur relatif a été **sorti de `SyncIndicator`** vers
`core/components/status/last_sync_label.dart` : deux formulations du même écoulé
finiraient par se contredire à quelques minutes près. Son doc porte l'avertissement
qui compte — cette estampille date le **pull**, pas le push, donc elle vieillit
plus vite que la réalité, dans le sens prudent.

**L'axe et la ventilation** — les barres portent `total` (D3) ; la ventilation
n'affiche qu'un montant, sans attendu ni taux ni barre de progression.

> ⚠️ **Le formatteur de libellé d'axe était faux, comme annoncé.**
> `_shortKey('2026-05-15')` rendait `5-15` : il coupait les quatre derniers
> caractères d'une chaîne qui en compte dix. `shortBucketLabel` découpe
> désormais **par nombre de segments** — trois pour une clé journalière, deux
> pour l'axe annuel — et trois tests purs l'épinglent. Au-delà de douze
> compartiments, les libellés pivotent : un mois de trente-et-un jours est le
> pire cas que l'écran ait à dessiner.

> ⚠️ **Le piège de test annoncé s'est présenté.** La ligne de fraîcheur lit un
> cubit fourni au niveau de `main.dart` : le test de la coquille a levé un
> `ProviderNotFoundException` dès que l'onglet Caisse s'est monté, et l'échec ne
> ressemblait en rien à sa cause. Un `MockCubit<SyncStatusState>` le résout, sur
> le patron déjà en place dans `attendance_save_overlay_reload_test.dart`.

---

### Démolition de l'ancien chemin ✅

Plus rien ne référençait la route qui répond 404. **Douze fichiers supprimés** :
l'ancienne famille de modèles (7) et d'entités, `GetFinanceStatsUseCase`, le
`FinanceStatsBloc` et ses deux `part`, l'extension l10n sur `FinanceStatsErrorType`,
l'ancien filtre de période, et deux suites de tests. `financeStatsEndpoint`,
`getFinanceStats` (datasource, repository, implémentation) et les deux
enregistrements DI partent avec eux ; `build_runner` rejoué.

La coexistence aura duré cinq lots, et n'a mordu qu'une fois — sur les sept noms
communs aux deux familles de modèles, au point d'usage et non à l'import.

**Tests :** 14 `testWidgets` et 3 tests purs sur la caisse — fenêtre, fuseau,
fraîcheur, trois cartes sans taux, ventilation limitée aux frais, devise
dormante, état vide, et le libellé de barre par grain.

### FS-7 — États partagés, a11y, l10n, tests de widgets

**Livré.** `flutter analyze lib test` propre, **708 tests verts** sur
`test/features/finance`.

**La dette de la règle #10 est soldée.**

- Le `CircularProgressIndicator` centré devient un squelette **à la silhouette
  de l'écran** : la bande KPI puis les deux cartes, aux mêmes places. Un rond
  qui tourne ne dit rien de ce qui arrive, et la page se réagençait sous l'œil.
  Le nombre de cartes est paramétré — **trois pour la caisse**, qui ne compte
  aucun taux, quatre pour le recouvrement. Le mouvement réduit est respecté par
  `EteeloSkeletonBox` lui-même.
- La carte d'erreur ad hoc devient
  `states/finance_stats_results_error_state.dart` sur `EteeloErrorResult`,
  quatre familles et **quatre gestes** : réseau → Réessayer · 401 → Se
  reconnecter · **403 → aucune action** · 500/stockage → Réessayer + code
  d'incident.

> **Écart avec le patron de la boutique, et il est délibéré.** Le wrapper
> boutique tire **et** son titre **et** son message de la famille d'erreur —
> quatre messages pour neuf `Failure`. Ici le titre vient de la famille, le
> message du `Failure` lui-même (`financeStatsMessage`, écrite en FS-4). Les
> neuf clés existantes restent donc vivantes, et « les paramètres demandés sont
> invalides » ne se replie pas sous « une erreur inattendue est survenue » — la
> seule information qui distingue un bug de l'application d'une panne du
> serveur.

`onReconnect` reste `null`, comme partout ailleurs dans le dépôt : l'expiration
de session est reprise globalement, et un second chemin de reconnexion en ferait
deux à tenir d'accord.

**Trois clés l10n meurent** avec la carte ad hoc — `financeStatsErrorTitle`
(« Erreur de chargement », le titre unique des quatre familles),
`financeStatsRetryHint` et `financeStatsErrorA11yLabel`. Six arrivent : quatre
titres, « Se reconnecter » et le code d'incident.

**Tests :** 6 `testWidgets` sur l'anatomie d'erreur, dont « 403 : AUCUNE action
de reprise » et « le message garde le grain du `Failure`, pas celui de la
famille ».

### FS-8 — Recette croisée *(après déploiement du back)*

**Cinq des sept cas sont déjà des scénarios de test automatisés.** Ce qui reste
à jouer à la main est ce qu'aucun test front ne peut prouver : le comportement
du **serveur**, et celui d'un **APK déjà déployé**.

| # | Cas | Couvert par |
|---|---|---|
| 1 | Journée à cheval sur minuit | ⚠️ **partiel** — le front ne calcule aucune borne, et trois tests l'épinglent (la fenêtre et le fuseau viennent de la réponse, un fuseau absent se tait). Que 00 h 20 tombe dans la bonne journée est une propriété de `TillWindow`, côté serveur. |
| 2 | École bi-devise | ✅ 8 tests — même carte, ordre du serveur, lignes qui se correspondent d'une carte à l'autre, jamais additionnées |
| 3 | Devise dormante | ✅ 6 tests — bloc à zéro qui se dit, « Sans objet » au lieu de 100 %, sur les deux onglets |
| 4 | Mois de 31 jours | ✅ 7 tests — rendu à 1280×800 **et** en largeur compacte, libellés pivotés au-delà de douze, jour et non clé entière |
| 5 | File d'écritures non vidée | ⚠️ **partiel** — « Il y a 1 h » et « Jamais synchronisé » sont testés. Que la ligne **vieillisse** pendant qu'une file attend n'est pas un comportement du front : la ligne date le pull, la pastille porte la file (D2). C'est la lecture conjointe des deux qui se vérifie à la main. |
| 6 | Encaissé > attendu | ✅ 4 tests — de la fixture à la carte, taux sous 100 et reste dû affiché |
| 7 | 404 sur un APK ancien | ⚠️ **partiel** — l'anatomie d'erreur est testée sur les quatre familles ; qu'un binaire déjà installé y aboutisse ne se prouve qu'au déploiement |

Restent donc **trois vérifications de bout en bout**, toutes suspendues au
déploiement du back :

1. Encaisser à 00 h 20 heure de Kinshasa, et vérifier que la vente tombe dans la
   caisse **du jour** — pas de la veille.
2. Laisser une file d'écritures non vidée à la fermeture : la ligne de
   fraîcheur et la pastille de la barre supérieure doivent raconter la même
   histoire.
3. Ouvrir le tableau de bord depuis un APK de la version précédente : il doit
   afficher l'état d'erreur, pas un écran blanc.

## 7. Pièges qui ne se négocient pas

- **`monthlyCollected` n'est pas un contrôle de cohérence.** Un versement
  rattaché à l'année mais daté hors de sa fenêtre compte dans `kpis.collected`
  sans apparaître sur l'axe : la somme des douze barres peut être **inférieure**
  au KPI. Ne jamais l'assertionner dans un test — ce serait épingler un faux
  invariant.
- **`summary.byFeeCode` somme à `fees`, jamais à `total`.** Une vente boutique
  n'est imputée sur aucune créance ; sa contribution reste entière dans
  `boutique`.
- **`summary.total == somme des buckets[].total`**, celui-là est vrai et garanti
  par construction. C'est le seul des deux qui peut servir de test.
- **Ne jamais additionner deux blocs `byCurrency`.** Aucune conversion n'est
  appliquée, jamais.
- **Le fuseau est au serveur.** Aucun `DateTime.now()` pour borner une journée.
- **Les fixtures viennent du YAML**, pas de l'exemple de la note — et surtout pas
  construites en Dart : une fixture construite en Dart n'exerce jamais
  `fromJson`.
- **`flutter analyze` à zéro issue** avant tout commit : le hook `pre-push` en
  fait une condition, et il dure ~7 min — pousser en tâche de fond.

---

## 8. Volume estimé

| Couche | Fichiers | Nature |
|---|---|---|
| Contrat | 2 (+1 généré) | modifiés |
| Modèles | 7 → 12 | 4 supprimés, 9 créés, 3 modifiés |
| Entités | 9 → 14 | idem |
| Repo / usecases | 4 | 1 méthode → 2, 1 usecase → 2 |
| BLoCs | 3 → 6 | scission |
| Écrans / widgets | ~14 | 2 créés, 1 supprimé, le reste réécrit |
| DI | 1 | 2 factories |
| l10n | 2 `.arb` + généré | ~18 clés |
| Tests | 6 réécrits + ~8 neufs | — |

**Ordre d'exécution :** FS-0 → FS-1 → FS-2 → FS-3 → FS-4 → FS-5 → FS-6 → FS-7,
puis FS-8 quand le back est déployé. Les quatre premiers lots ne touchent aucun
pixel et peuvent partir avant que le back ne fusionne ; FS-8 ne peut pas.

---

## 9. Hors périmètre

- **L'ancre de fenêtre** (`date` / `month` / `week`) — cf. D4.
- **La barre empilée frais + boutique** — cf. D3.
- **La promotion de `FinanceDashboardTabs` au socle** — un seul appelant.
- **La caisse calculée en local** — elle rouvrirait la question du fuseau côté
  tablette, que le back vient précisément de fermer. À reconsidérer seulement si
  la caisse devient l'écran de fermeture officiel.
- **Les stats d'inscriptions** — leur sémantique change côté serveur (§2.5),
  mais aucun champ ne bouge : rien à faire ici.
