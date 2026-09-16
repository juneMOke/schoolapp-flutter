# Refonte interne de la page d'encaissement — plan de chantier

> Rédigé le 2026-09-16 sur `feat/editable-payment-date` (base `origin/main` `b82d7fc6`,
> relevés au commit `e67ba6c2`). Source : lecture du code, pas d'une spec — le
> chantier naît d'un défaut d'argent trouvé en revue adversariale sur le lot
> « date d'encaissement saisissable », dont la racine était structurelle.
>
> ⚠️ **Les numéros de ligne de l'annexe dérivent dès le lot R1.** Ils datent de
> `e67ba6c2` et servent à cadrer l'effort, pas à guider un `sed`.

---

## 1. Ce que ce chantier traite

| Mesure | Valeur |
|---|---|
| `facturation_create_payment_page.dart` | **1 208 lignes** (cible projet : ~250) |
| Méthodes portées par la classe `State` | **43**, dont 14 gestionnaires `_on*` |
| Champs d'état mutable portés directement | **8** |
| Occurrences de `IsSource` dans la page | **21** — contre 7 + 2 dans les classes qui *possèdent* ces drapeaux |
| Filet de tests sur le flux | **13 fichiers, 3 348 lignes, ~57 cas**, tous pilotant le widget |

### Le diagnostic

**Ce n'est pas un problème de longueur, c'est un problème de propriété.**

La page détient une machine à états qui porte des invariants d'argent, et ces
invariants ne sont inscrits dans aucun objet capable de les faire respecter.
`groupIsSource` et `tenderIsSource` sont **publics et mutables** sur
`FacturationChargeGroupEntry` : n'importe quel appelant peut les poser dans une
combinaison incohérente.

C'est exactement ce qui s'est produit. `_handOverToTranches` posait
`groupIsSource = false` sans toucher `tenderIsSource` ; l'état « les tranches
commandent, mais le comptoir de la nature se croit encore source » était
**stable et invisible** — le champ qui aurait pu le défaire disparaît de l'écran
dès que la nature rend la main. Tout rejeu de la cascade y écrasait la
ventilation saisie à la main, déplaçant l'argent d'une créance à l'autre sans un
mot. Il a fallu trois relecteurs adversariaux pour le voir ; aucun type, aucun
test, aucun compilateur ne pouvait le signaler.

### Le coût, mesuré sur le lot précédent

1. **Tout devient un test de widget.** La machine à états est privée à un
   `State` : éprouver une branche exige de monter l'arbre, dimensionner la
   surface, taper une `Checkbox`, une `ChoiceChip`, trouver des champs par leur
   libellé français. **267 lignes de test pour couvrir une seule branche.**
2. **Les tests cassent pour de mauvaises raisons** — deux échecs sur trois du lot
   précédent étaient des artefacts de rendu (`60000` vs `60000.00`), pas des
   défauts.
3. **Surface de conflit** entre sessions travaillant sur l'encaissement.

---

## 2. Architecture cible

| Fichier | Responsabilité | ~lignes |
|---|---|---|
| `helpers/facturation_collect_labels.dart` ✅ | formatage pur : montants, taux, monnaie à rendre, identité de l'élève | **125** (livré) |
| `helpers/facturation_rate_board.dart` ✅ | le tableau des taux corrigés à la main (contrôleurs, amorces, édition) | **119** (livré) |
| `helpers/facturation_settlement_reads.dart` ✅ | lectures pures `(règlement, entrées) → chiffres` | **150** (livré) |
| `helpers/facturation_collect_form_model.dart` ✅ | **l'état et les gestes** : entrées, natures, jour désigné, dérivations | **348** (livré) |
| `pages/facturation_create_payment_page.dart` | fournisseurs, `build`, `_body`, navigation, cycle de vie | **~300** |

### Pourquoi ~300 et non 250

`build` + `_body` + le cycle de vie + la navigation sont **irréductiblement** la
page. Viser 250 obligerait à découper par blocs visuels — c'est le mauvais
découpage : des widgets qui continuent de partager le même état mutable donnent
plus de fichiers et les mêmes invariants dispersés. **Le découpage utile est par
propriété de l'état, jamais par morceau d'écran.**

### Le gabarit existe déjà deux fois dans le dépôt

- `expense/presentation/helpers/expense_form_model.dart` — 91 lignes, classe
  **simple** (pas un `ChangeNotifier`) : possède contrôleurs, état mutable et
  règles ; la modale enveloppe chaque geste d'un `setState`. Testée unitairement
  (`expense_form_model_test.dart`).
- `finance/presentation/helpers/facturation_payer_form_controller.dart` —
  160 lignes, `ChangeNotifier`, **déjà extrait de cette même page**.

`test/features/finance/presentation/helpers/` existe et porte déjà 7 fichiers de
tests unitaires. Le terrain est prêt.

---

## 3. La règle d'or du chantier

> **Un lot déplace du code, ou change du comportement. Jamais les deux.**

Corollaire, et c'est le seul garde-fou qui ne mente pas :

> Sur un lot de déplacement, **aucun fichier de test existant ne doit être
> modifié**. Si un test doit changer, le comportement a bougé — on s'arrête et on
> regarde pourquoi.

---

## 4. Les lots

| # | Lot | Nature | Risque |
|---|---|---|---|
| **R0** ✅ | Mesurer la couverture réelle de la page, combler les gestes non couverts | filet | nul |
| **R1** ✅ | Sortir les libellés | déplacement pur | nul |
| **R2** ✅ | **Rendre l'invariant inviolable** | changement d'API | faible |
| **R3** ✅ | Sortir le tableau des taux | déplacement | faible |
| **R4** ✅ | Sortir les lectures pures | déplacement | faible |
| **R5** ✅ | Sortir l'état et les gestes | déplacement | **le seul délicat** |
| **R6** | `_onCollect` → `model.buildRequest()` ; la page ne garde que la navigation | déplacement | faible |

### R0 — le filet avant tout

Ce n'est pas une formalité. On ne *suppose* pas que 57 cas couvrent les 28
méthodes qui vont bouger : on mesure (`flutter test --coverage`), on lit les
lignes non couvertes, on comble les gestes nus. **Aucune ligne de production
n'est touchée dans ce lot.**

#### ✅ Résultat — livré le 2026-09-16, commit `f5d3db2d`

| | Départ | Fin de R0 |
|---|---|---|
| Couverture de la page | 399/480 | **445/480** |
| Lignes nues | 81 | **35** |
| **Famille B** (le code qui déménage) | ~34 | **0** |
| Suite `test/features/finance` | — | **1 031 verts** |

Le pourcentage global n'a jamais été le critère : ce qui comptait est que les
lignes nues restantes soient toutes de la **plomberie qui reste en place** —
31 lignes de famille A (le corps de `Page.build`, que nul test ne monte, et les
branches d'erreur) et 4 replis de libellés. **Aucune ne bouge pendant le
chantier.**

Ce qui était nu et ne l'est plus : « Tout solder » sur une tranche comme sur une
nature (deux gestes entiers) ; l'écrêtage aux deux niveaux ; la lecture d'un taux
corrigé à la main et la fermeture d'une boîte de taux intacte ; les deux branches
de `_onPaidDayChanged` où le comptoir est source.

614 lignes de tests neufs, **zéro ligne de production**.

### R1 — les libellés

#### ✅ Résultat — livré le 2026-09-16

| | |
|---|---|
| Page | 1 208 → **1 128** lignes (28 insertions, 108 suppressions) |
| Bibliothèque `facturation_collect_labels.dart` | **125 lignes** |
| Tests unitaires | **199 lignes, 19 cas**, instantanés |
| Suite `test/features/finance` | **1 050 verts** |
| **Règle d'or** | ✅ **aucun fichier de test existant modifié** |

**L'estimation de ~200 lignes retirées était fausse** : la page n'en perd que 80.
Deux méthodes sont restées, réduites à leur garde — `_groupRateLabel` et
`_groupChangeLabel` portent `isConverted` / `tenderIsSource` et un calcul de
cents, qui ne sont pas du formatage — et plusieurs sites d'appel se sont
allongés d'une ligne.

Le gain est ailleurs, et il vaut mieux que le décompte :

- **trois duplications supprimées.** L'expression du taux était écrite **trois
  fois à l'identique** (ligne, nature, récapitulatif) ; la monnaie à rendre et ce
  que le tiroir conserve, deux fois chacun. Trois écritures d'un même nombre qui
  divergent, c'est le parent qui recompte au guichet et ne retombe pas sur son
  total.
- **dix comportements passés du widget à l'unitaire.** Les mêmes règles coûtaient
  267 lignes de test d'écran ; elles tiennent en 19 tests qui s'exécutent en
  moins d'une seconde. C'est la thèse du chantier, vérifiée sur le lot le moins
  risqué.

#### ⚠️ Rectification du découpage

Le classement initial rangeait en famille C deux méthodes qui **ne sont pas
pures**. Elles n'ont donc pas bougé, et le plan est corrigé :

- `_ratePairs` fabrique des contrôleurs et des closures `setState` → elle
  appartient au **tableau des taux (R3)** ;
- `_confirmGroups` parcourt `_groups` et lit `widget.sectionTitles` → **R4/R5**.

### R2 — en deuxième, et non à la fin

Rendre `groupIsSource` et `tenderIsSource` privés derrière des méthodes
d'intention (`handOverToTranches()`, `tenderBecameSource()`) fait porter
l'invariant par `FacturationChargeGroupEntry` — classe déjà testée unitairement.
Le compilateur désigne alors les 21 sites.

Ces sites rebougeront en R5 : c'est mécanique et guidé par le compilateur. Faire
l'inverse ferait porter le lot le plus risqué du chantier par un invariant encore
mou.

#### ✅ Résultat — livré le 2026-09-16

| | |
|---|---|
| `flutter analyze` **projet entier** | ✅ clean |
| Suite `test/features/finance` | **1 052 verts** (+2 tests d'invariant) |
| Fichiers touchés | 4, dont **exactement les deux** fichiers de test annoncés |

Les deux drapeaux sont privés, exposés en lecture seule, et ne se posent plus que
par cinq gestes nommés par l'intention : `groupCommands()`,
`amountBecomesSource()`, `tenderBecomesSource()`, `tenderStopsBeingSource()`,
`handsOverToTranches()`. **Aucun** ne laisse « la nature ne commande plus » avec
« son comptoir est encore source » : l'état qui a coûté une ventilation de
caissier ne s'écrit plus.

L'analyse a porté sur **tout le projet**, et non sur les fichiers touchés :
privatiser un champ peut casser n'importe quel appelant, y compris un qu'un grep
manquerait.

C'est le **seul lot du chantier où des tests existants bougent** — l'API change.
Deux fichiers, annoncés avant l'écriture ; les 1 048 autres passent sans avoir
été touchés.

#### Preuve par mutation

La garde retirée de `handsOverToTranches()`, **deux tests tombent** : « rendre la
main aux tranches ÉTEINT aussi le comptoir source » et « aucun geste ne laisse
non source avec un comptoir source ». La garde est porteuse, pas décorative.

⚠️ **J'en attendais trois.** Le test de widget de R0 — celui qui reconstitue le
parcours du caissier — ne tombe PAS, et c'est instructif : `_onPaidDayChanged`
porte sa **propre** garde (`groupIsSource && tenderIsSource`), posée en R0. Avec
la mutation, `groupIsSource` vaut faux, la condition est fausse, et la cascade
n'est pas rejouée.

Les deux protections sont donc **redondantes par construction**, et chacune tient
seule : le test unitaire éprouve la garde de l'entité, le test de widget celle de
la page. Les garder toutes les deux est délibéré — c'est un chemin d'argent.

---

### R3 — le tableau des taux

#### ✅ Résultat — livré le 2026-09-16

| | |
|---|---|
| `flutter analyze` **projet entier** | ✅ clean |
| Suite `test/features/finance` | **1 066 verts** (+14) |
| Page | 1 122 → **1 056** lignes (15 insertions, 81 suppressions) |
| `facturation_rate_board.dart` | **119 lignes**, 14 tests unitaires |
| **Règle d'or** | ✅ **strictement** tenue — aucun test existant modifié |

Trois fichiers touchés, dont **deux neufs** : c'est la signature d'un déplacement
pur, et le contraste avec R2 est net — là-bas le changement d'API imposait de
reprendre deux fichiers de test, ici aucun n'a bougé.

Les trois champs d'état (`_rateControllers`, `_editingRates`, `_rateSeeds`) et
leurs trois méthodes formaient en réalité **un objet** : ce que le caissier a
corrigé, et ce qu'il n'a fait qu'ouvrir.

Le **piège P2 est évité par construction** : le rappel de rafraîchissement est
injecté au constructeur du tableau, qui pose l'écoute sur chaque contrôleur qu'il
crée. `setState` reste donc dans la page, et la nouvelle classe ne connaît ni
widget ni cycle de rendu. Ce n'est pas une vigilance à tenir, c'est une
dépendance qui n'existe pas.

#### Ce qui n'a PAS été traité, et pourquoi

L'écart **« affiché ≠ soumis »** sur le taux corrigé (cf. §7) vit précisément
dans cette zone. Il n'a pas été corrigé au passage : R3 est un lot de
déplacement, et y glisser un changement de comportement rendrait la preuve
inutilisable — on ne saurait plus si un test rouge vient du déplacement ou de la
correction. C'est la règle d'or, et elle vaut surtout quand la tentation est
grande.

### R4 — les lectures

#### ✅ Résultat — livré le 2026-09-16

| | |
|---|---|
| `flutter analyze` **projet entier** | ✅ clean |
| Suite `test/features/finance` | **1 082 verts** (+16) |
| Page | 1 056 → **948** lignes |
| `facturation_settlement_reads.dart` | **150 lignes**, 16 tests unitaires |
| **Règle d'or** | ✅ **strictement** tenue |

**Le plus gros lot du chantier** : −108 lignes d'un coup, et trois fichiers
touchés dont deux neufs.

Huit lectures ont quitté la classe `State` : `lineOf` et sa branche d'écrêtage,
`linesOf`, les deux sacs de devises, `hasConversion`, `groupTenderCents`, et les
deux gardes du CTA. Elles ne touchaient à rien — on leur donne un règlement et
des lignes de saisie, elles rendent un chiffre.

#### Une optimisation écartée, délibérément

Ces fonctions **recalculent les lignes à chaque appel** — trois fois par rendu.
Les faire prendre des lignes déjà calculées aurait été facile et tentant.

Ce n'a pas été fait : ce serait un changement de comportement glissé dans un lot
de déplacement, et l'on ne saurait plus attribuer un test rouge. L'inefficacité
est préservée **à l'identique**, et elle pourra se traiter seule, dans un lot qui
ne fait que cela.

#### Rectification du découpage (suite)

Comme en R1, deux fonctions n'étaient pas pures et ont été corrigées **avant**
d'écrire plutôt que découvertes après : `_lines` et `_hasNoConvertibleCharge`
parcourent `_entries`. Elles reçoivent désormais les entrées en argument.

### R5 — l'état et les gestes

#### ✅ Résultat — livré le 2026-09-16

| | |
|---|---|
| `flutter analyze` **projet entier** | ✅ clean |
| Suite `test/features/finance` | **1 095 verts** (+13) |
| Page | 948 → **701** lignes |
| `facturation_collect_form_model.dart` | **348 lignes**, 13 tests unitaires |
| **Règle d'or** | ✅ **strictement** tenue |

Le lot annoncé comme le seul délicat s'est révélé **le plus propre** : aucun
fichier de test existant n'a bougé, trois fichiers touchés dont deux neufs, et
pas une erreur dans le recâblage des vingt sites d'appel — l'analyseur n'a
signalé que la méthode qui restait à supprimer.

Les deux pièges sont **évités par construction**, et non par vigilance :

- **P1** — le modèle reçoit `settlementOf`, un *rappel*. Il ne mémorise jamais la
  série de taux, donc ne peut pas convertir au taux d'une série périmée quand le
  cubit finit de charger. Un test l'épingle : une série arrivée **après** la
  construction est bien prise en compte.
- **P2** — aucune méthode du modèle n'appelle `setState`. Tout passe par `_act`,
  seul endroit où un geste devient un rendu.

## 5. Les trois pièges, repérés en lisant le code

### 🔴 P1 — Le modèle ne doit JAMAIS mémoriser les taux

`_settlement()` lit `widget.rates` à **chaque appel**, donc toujours frais. Or
`ExchangeRatesCubit` charge en **asynchrone** et reconstruit la vue : un modèle
qui capterait la série à sa construction ignorerait un taux arrivé après, et
convertirait de l'argent au mauvais taux.

⇒ Signature `settlement(rates, now)`, **jamais un champ**.

### ⚠️ P2 — La granularité de `setState`

Aujourd'hui chaque geste fait son `setState` dans le `State`. Après extraction,
oublier une enveloppe donne un écran qui ne se rafraîchit pas — sans erreur.

⇒ Un unique `_act(void Function())` dans la page, et **tous** les gestes y
passent.

### ⚠️ P3 — Propriété des contrôleurs

Le modèle possède et dispose ; la page délègue. Un `dispose` en double est
silencieux jusqu'au crash.

### Ce qui reste dans la page

`_collectInFlight` et `_closeConfirmationOpen` sont des **verrous de
navigation**, pas de l'état de saisie. Ils ne descendent pas dans le modèle.

---

## 6. Vérification et fin de chantier

Par lot : `flutter analyze` sur les fichiers touchés, puis
`flutter test test/features/finance` (~90 s).

À la fin : verify global (`flutter analyze` + `flutter test`, ~6 900 tests) **puis
revue adversariale**, dans cet ordre. La leçon a été payée sur le lot précédent :
*un correctif est la meilleure cible de la ronde suivante*.

**Le chantier est terminé quand :**

- [ ] ~~la page fait ≤ 350 lignes~~ — **critère révisé après R5, voir ci-dessous** ;
- [ ] **aucun fichier de test existant n'a été modifié** par un lot de déplacement ;
- [ ] les quatre fichiers neufs ont leurs tests unitaires ;
- [ ] les drapeaux de source sont privés, et un test échoue si l'on retire la
      garde (test de mutation).

---

### ⚠️ Recalibration de la cible, après R5

**Les ~350 lignes ne seront pas atteintes par R6 seul**, et mon estimation de
départ était optimiste — comme celle de R1 (−200 annoncées, −80 réelles).

R6 ne touche que `_onCollect` : on atterrira autour de **635 lignes**. Ce qui
reste ensuite n'est plus de la machine à états mais du **rendu** — `_body`,
`build`, le wrapper `Page`, et quatre constructeurs de view-models
(`_ratePairs`, `_confirmGroups`, les deux libellés de nature).

Deux voies :

1. **un lot R7** — sortir les view-models et découper `_body` en sous-widgets ;
2. **réviser le critère** — une page de ~600 lignes dont l'essentiel est du rendu
   déclaratif n'est plus le god-object de départ.

**Recommandation : la voie 2.** Le mal qu'on soignait était la **propriété de
l'état**, pas le nombre de lignes. Les invariants d'argent sont désormais portés
par des objets qui les font respecter, et éprouvés par 62 tests unitaires
instantanés là où il fallait monter un écran. Le décompte de lignes était un
symptôme, pas la maladie.

## 7. Hors périmètre

- **`facturation_create_payment_confirm_dialog.dart` — 812 lignes.** Même
  maladie, chantier distinct.
- **Le ticket imprime en fuseau tablette** (`toLocal()`) et non en fuseau école :
  défaut préexistant du module `documents`, rendu visible par le lot précédent.
- **`SchoolTime` code UTC+1 en dur** alors que le serveur déclare son fuseau dans
  la réponse Caisse.

### 🔴 Trouvé par R0 — « affiché ≠ soumis » sur le taux corrigé

Une correction de taux atteint le règlement — donc ce qui partira en base via
`tendersFor` — **mais pas le montant affiché au comptoir**. Trois faits vérifiés
l'établissent, et ils se contredisent :

1. le champ porte bien la correction saisie ;
2. `overriddenRates` la contient — prouvé indépendamment par l'avertissement de
   divergence, qui ne s'affiche **que** par elle ;
3. `rateFor`, `fromSettled` et `fromTender` la consultent (lu en source) ;
4. et pourtant le comptaffiché reste au taux du référentiel, même après un geste
   censé le re-dériver.

Préexistant, hors périmètre du chantier. `..._rate_override_test.dart` **cloue le
comportement observé** avec un commentaire disant que ce n'est pas le
comportement souhaitable : le jour où ce sera traité, ce test échouera, et c'est
ce qu'on lui demande. Mérite son propre ticket — il touche l'argent que le
caissier lit.

---

## Annexe — inventaire de départ

Les 56 déclarations de la page, par famille. Numéros relevés à `e67ba6c2`.

### A — Plomberie widget (reste dans la page)

`55` ctor Page · `58` build Page · `140` ctor View · `150` createState ·
`237` initState · `256` dispose · `369` `_requestClose` · `921` `_pickPayer` ·
`948` `_onCollect` · `1047` build · `1115` `_body`

### B — Machine à états (→ modèle)

**Horloge** : `207` `_paidDay` · `209` `_now` · `213` `_today`

**Taux** : `273` `_rateControllerOf` · `352` `_closeUntouchedRateEditors` ·
`530` `_settlement` · `545` `_rateMicrosOf`

**Gestes** : `305` `_onPaidDayChanged` · `392` `_onToggle` · `411` `_onSettleAll` ·
`437` `_onGroupToggle` · `452` `_onGroupSettleAll` · `462` `_onGroupAmountEdited` ·
`477` `_onGroupTenderEdited` · `498` `_onGroupTenderCurrencyChanged` ·
`509` `_onGroupToggleExpanded` · `623` `_onAllocationEdited` ·
`652` `_onTenderEdited` · `670` `_onTenderCurrencyChanged`

**Dérivations** : `518` `_reflectGroupTender` · `563` `_lineOf` · `601` `_lines` ·
`610` `_reflectTender` · `635` `_handOverToTranches` · `815` `_groupTenderCents`

**Lectures** : `430` `_groupOf` · `690` `_settledBag` · `694` `_tenderBag` ·
`706` `_hasConversion` · `871` `_tenderInvariantBroken` ·
`887` `_hasNoConvertibleCharge`

### C — Formatage pur (→ libellés)

**Sorties en R1** : `_formatWithCurrency` · `_bagLabel` · `_lineRateLabel` ·
`_lineChangeLabel` · `_groupTenderLabel` · `_singleRateLabel` ·
`_tenderLabelOf` · `_studentFullName` · `_classLabel`.

**Restées, réduites à leur garde** : `_groupRateLabel` et `_groupChangeLabel` —
elles portent `isConverted` / `tenderIsSource` et un calcul de cents, qui sont de
l'état, pas du formatage.

**Reclassées** (elles n'étaient pas pures) : `_ratePairs` → **R3** (contrôleurs
et closures `setState`) ; `_confirmGroups` → **R4/R5** (parcourt `_groups`, lit
`widget.sectionTitles`).
