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
| `helpers/facturation_collect_labels.dart` | formatage pur : libellés de taux, de monnaie à rendre, view-models du récapitulatif | ~200 |
| `helpers/facturation_rate_board.dart` | le tableau des taux corrigés à la main (contrôleurs, amorces, édition) | ~90 |
| `helpers/facturation_settlement_reads.dart` | lectures pures `(règlement, entrées) → chiffres` | ~120 |
| `helpers/facturation_collect_form_model.dart` | **l'état et les gestes** : entrées, natures, jour désigné, dérivations | ~280 |
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
| **R0** | Mesurer la couverture réelle de la page, combler les gestes non couverts | filet | nul |
| **R1** | Sortir les libellés et view-models | déplacement pur | nul |
| **R2** | **Rendre l'invariant inviolable** | changement d'API | faible |
| **R3** | Sortir le tableau des taux | déplacement | faible |
| **R4** | Sortir les lectures pures | déplacement | faible |
| **R5** | Sortir l'état et les gestes | déplacement | **le seul délicat** |
| **R6** | `_onCollect` → `model.buildRequest()` ; la page ne garde que la navigation | déplacement | faible |

### R0 — le filet avant tout

Ce n'est pas une formalité. On ne *suppose* pas que 57 cas couvrent les 28
méthodes qui vont bouger : on mesure (`flutter test --coverage`), on lit les
lignes non couvertes, on comble les gestes nus. **Aucune ligne de production
n'est touchée dans ce lot.**

### R2 — en deuxième, et non à la fin

Rendre `groupIsSource` et `tenderIsSource` privés derrière des méthodes
d'intention (`handOverToTranches()`, `tenderBecameSource()`) fait porter
l'invariant par `FacturationChargeGroupEntry` — classe déjà testée unitairement.
Le compilateur désigne alors les 21 sites.

Ces sites rebougeront en R5 : c'est mécanique et guidé par le compilateur. Faire
l'inverse ferait porter le lot le plus risqué du chantier par un invariant encore
mou.

---

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

- [ ] la page fait ≤ 350 lignes ;
- [ ] **aucun fichier de test existant n'a été modifié** par un lot de déplacement ;
- [ ] les quatre fichiers neufs ont leurs tests unitaires ;
- [ ] les drapeaux de source sont privés, et un test échoue si l'on retire la
      garde (test de mutation).

---

## 7. Hors périmètre

- **`facturation_create_payment_confirm_dialog.dart` — 812 lignes.** Même
  maladie, chantier distinct.
- **Le ticket imprime en fuseau tablette** (`toLocal()`) et non en fuseau école :
  défaut préexistant du module `documents`, rendu visible par le lot précédent.
- **`SchoolTime` code UTC+1 en dur** alors que le serveur déclare son fuseau dans
  la réponse Caisse.

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

`389` `_formatWithCurrency` · `698` `_bagLabel` · `710` `_ratePairs` ·
`741` `_lineRateLabel` · `752` `_lineChangeLabel` · `769` `_confirmGroups` ·
`804` `_groupTenderLabel` · `833` `_groupRateLabel` · `853` `_groupChangeLabel` ·
`899` `_singleRateLabel` · `911` `_tenderLabelOf` · `930` `_studentFullName` ·
`941` `_classLabel`
