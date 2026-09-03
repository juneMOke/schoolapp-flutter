# FEE_CONTROL_DASHBOARD_PLAN.md — qui est en ordre, et où

> **Statut :** proposé le 2026-09-02, arbitrages D1–D3 tranchés par le user.
> FCD-0 à FCD-7 livrés le 2026-09-03 — **le lot est clos**.
>
> | Lot | État |
> |---|---|
> | FCD-0 · lectures locales (frais de l'année, positions par niveau) | ✅ livré |
> | FCD-1 · projecteur — positions → répartition par groupe | ✅ livré |
> | FCD-2 · BLoC, états, DI | ✅ livré |
> | FCD-3 · la page : sélecteurs, bandeau, classement par niveau | ✅ livré |
> | FCD-4 · dépliage en classes (roster + non-répartis) | ✅ livré |
> | FCD-5 · les non-facturés | ✅ livré |
> | FCD-6 · pont vers l'écran de contrôle | ✅ livré |
> | FCD-7 · a11y, l10n, revue money-grade | ✅ livré |
>
> **Docs de contexte :** `FINANCE_STATS_PLAN.md` (le dashboard voisin, en
> montants et online) · `MULTIDEVISE_PLAN.md` · `NOMMAGE_CHARGES_PLAN.md`
> (nommer par la grille, mesurer par la nature) · `AGENTS.md` §« États
> partagés » · `CLAUDE.md` §règles non-négociables.

---

## 1. La question posée

> « Quel est le taux d'élèves **en ordre** pour tel ou tel groupe d'élèves ? »

Ce n'est pas la question du recouvrement, qui compte des francs. C'est la
question du **préfet** : quelle classe décroche, laquelle convoquer. Le livrable
n'est donc pas un chiffre mais un **classement de groupes**, trié par taux
croissant — ce qui va mal remonte en haut.

---

## 2. Le fait déterminant

**`student_charges` porte déjà tout ce qu'il faut pour grouper.**

```
student_id · academic_year_id · school_level_id · school_level_group_id
fee_tariff_id · fee_code · expected_amount_in_cents · amount_paid_in_cents
optimistic_paid_in_cents · currency · status · due_at
```

`school_level_id` et `school_level_group_id` sont renseignés **par le pull**
(`StudentChargeDto.toLocalModel`) **et par le seed d'inscription**
(`FinanceChargeSeedDao`). Le grand-livre local sait donc répartir par cycle et
par niveau **sans une seule jointure**, sans bump de schéma, sans rien demander
au back.

Seule la **classe** manque : elle vit dans `ref_classroom_members`. Elle se
compose en Dart, comme le fait déjà l'écran de contrôle.

---

## 3. Ce que ce tableau de bord n'est pas

| | Finances › Recouvrement | Contrôle des frais › Tableau de bord |
|---|---|---|
| Unité | des **francs** | des **élèves** |
| Maille | par poste (`fee_code`) | par **groupe d'élèves** (cycle → niveau → classe) |
| Source | `GET /finance-stats/recovery` | **100 % local** |
| Hors ligne | inutilisable | c'est son terrain |
| Aujourd'hui | 404 (le back n'a rien déployé) | — |

Les deux ne se marchent pas dessus : **l'un dit combien il manque, l'autre dit
qui manque.**

---

## 4. Décisions tranchées

### D1 — « en ordre » = soldé sur le frais choisi ✅

`reste == 0` sur le `fee_code` sélectionné, c'est-à-dire très exactement
`LocalFeeChargeAggregate.status == StudentChargeStatus.paid`.

**Pourquoi pas l'échéance** (« a payé tout ce qui est échu ce jour »), qui est
pourtant le sens métier du mot : `due_at` est **nullable** sur `student_charges`
comme sur `ref_fee_tariffs`, et rien ne garantit son peuplement. S'il est vide,
tout le monde ressort « en ordre » — un écran qui ment **sans lever d'erreur**,
la pire des pannes. À rouvrir seulement après avoir sondé le peuplement réel de
`due_at` sur une base de production.

**Conséquence assumée :** un élève qui a réglé T1 et dont T2 n'est pas encore
échue est compté « partiel », pas « en ordre ».

### D2 — maille : niveau, dépliable en classes ✅

Filtre cycle au-dessus. Le **niveau est gratuit** (déjà dans le grand-livre) ;
la **classe ne coûte qu'au dépliage**, et rien de plus en SQL (cf. D6).

### D3 — une page « Tableau de bord » dans le module ✅

Le module passe à deux pages, comme Inscriptions ou Classes :

```
Contrôle des frais
  ├─ Tableau de bord      ← la question
  └─ Contrôle par frais   ← les noms
```

`MenuConstants.feeControlDashboardId = 'controle-frais-dashboard'`,
route `/controle-frais/controle-frais-dashboard`, permission **`finance.charge.read`**
— la même que la page voisine. La carte d'accueil gagne son
`_dashboard(...)` et son en-tête mène désormais ici.

### D4 — le statut se dérive, il ne se relit pas

La colonne `status` de `student_charges` est autoritaire serveur et **ignore les
encaissements locaux non remontés**. Le tableau de bord dérive donc le statut
des **montants composés**, par la règle de `LocalFeeChargeAggregate` — la même
que l'écran de contrôle, réutilisée et non recopiée.

Sans cela, un guichet qui encaisse hors ligne toute la matinée verrait son taux
figé, et les deux écrans du module se contrediraient sur le même élève.

### D5 — le dénominateur est le couple (élève, niveau)

Un élève qui porte le même `fee_code` sur **deux niveaux** (changement de niveau
en cours d'année) compte dans les deux — il doit bel et bien à chacun, et cela
garantit que **le total école est la somme des niveaux**. Cas rare ; l'écrire
évite qu'on « corrige » un jour l'écart entre le bandeau et la somme des lignes.

### D6 — le dépliage ne touche pas au SQL des créances

Ouvrir un niveau appelle `GetComposedRostersUseCase(academicYearId,
schoolLevelId)` — **tous les rosters du niveau en un appel**, transferts pending
compris — et répartit **en mémoire** les positions déjà chargées. Aucune requête
supplémentaire sur `student_charges`. Les élèves du niveau qui ne sont dans
aucune classe forment une ligne **« Non répartis »**
(`GetUnassignedLevelEnrollmentsUseCase`), sans quoi la somme des classes serait
inférieure au niveau sans que rien ne l'explique.

### D7 — le frais est nommé par sa NATURE, jamais par le label d'un tarif

L'écran est **école-wide** : deux niveaux portent le même `fee_code` sous des
libellés différents. Afficher l'un d'eux, c'est rejouer le défaut du
`MIN(currency)` déjà corrigé dans ce module — une valeur choisie au hasard des
données. On affiche donc `feeCode.localizedFeeLabel(l10n)`.

**Amendé à l'écriture de FCD-0 :** la liste des frais est lue dans le
**grand-livre**, non dans la grille tarifaire comme d'abord prévu. Deux raisons
qui vont dans le même sens. La grille peut ne pas être sur l'appareil —
caviardée faute de `finance.grid.read`, ou pas encore descendue — alors que les
créances, elles, sont là : l'écran serait resté vide en ayant tout ce qu'il
faut pour répondre. Et la population mesurée vient des créances : lister un
frais que personne ne porte n'offrirait qu'une sélection qui ne rend rien.

### D8 — on compte des personnes ; les montants viennent en second

Un taux d'élèves est **immunisé contre la multi-devise** : il n'additionne
jamais des francs et des dollars. Le reste dû, lui, s'affiche par devise via
`MoneyBag` (`EteeloKpiCardData.valueLines` est fait pour ça) et **jamais** en un
total unique.

---

## 5. Contrat de lecture

Deux lectures neuves dans `finance_ledger_read_dao.dart` — le module
`fee_control` reste **présentation seule** et consomme `finance/offline`, comme
il consomme déjà `classes` et `enrollment`.

### 5.1 Les frais de l'année

```sql
SELECT DISTINCT fee_code FROM ref_fee_tariffs
WHERE (academic_year_id = ? OR academic_year_id IS NULL)
ORDER BY fee_code
```

### 5.2 Les positions, par élève et par niveau

```sql
SELECT sc.student_id, sc.school_level_id, sc.currency,
       SUM(sc.expected_amount_in_cents) AS expected,
       SUM(sc.amount_paid_in_cents)     AS paid_mirror,
       SUM(COALESCE((
         SELECT SUM(pa.amount_in_cents)
         FROM payment_allocations pa
         JOIN payments p ON p.id = pa.payment_id
         WHERE pa.student_charge_id = sc.id
           AND p.sync_status <> ?          -- PENDING_SYNC *et* SYNC_ERROR
       ), 0))                           AS paid_pending
FROM student_charges sc
WHERE sc.fee_code = ?
  AND (sc.academic_year_id = ? OR sc.academic_year_id IS NULL)
  -- filtre cycle, optionnel :
  AND (? IS NULL OR sc.school_level_group_id = ?)
GROUP BY sc.student_id, sc.school_level_id, sc.currency
```

**Pas de `student_id IN (…)`** ici, contrairement à `getFeeChargeAggregates` :
la population n'est pas donnée, elle est *découverte*. Donc pas de lots de 500,
pas de liste d'identifiants à composer en amont.

**Coût — mesuré à FCD-0.** Base peuplée à 800 élèves × 6 frais = **4 800
créances** et 1 602 allocations non remontées :

| Lecture | à froid | à chaud |
|---|---|---|
| `getFeeCodesForYear` | 5 ms | 2 ms |
| `getFeeChargePositionsByLevel`, toute l'école (800 lignes) | **16 ms** | 8 ms |
| idem, borné à un cycle (267 lignes) | 3 ms | 3 ms |

L'arbitrage « aucun index, aucune migration » **tient** : il n'y a d'index ni
sur `fee_code` ni sur `school_level_id`, la requête scanne, et cela ne coûte
rien à cette échelle. La sous-requête corrélée, elle, s'appuie sur
`idx_payment_allocations_charge`, qui existe.

⚠️ Mesuré sous `sqflite_common_ffi` (bureau), **pas sur tablette avec
SQLCipher** : compter un facteur de l'ordre de 3 à 10 en conditions réelles,
soit ~50 à 150 ms pour l'ouverture de l'écran. Acceptable, mais à revérifier sur
matériel si l'école dépasse le millier d'élèves.

---

## 6. Invariants à ne jamais casser

1. **Une seule règle de statut** dans le module — celle de
   `LocalFeeChargeAggregate`. Le tableau de bord et le contrôle ne peuvent pas
   diverger sur un élève.
2. **Le `paid_pending` est toujours composé.** Un encaissement hors ligne doit
   déplacer le taux immédiatement.
3. **Jamais deux devises additionnées.** Le taux compte des élèves ; les
   montants restent ventilés.
4. **Le taux porte sur les concernés**, jamais sur les inscrits : un élève sans
   créance de ce frais n'est pas un mauvais payeur, il n'est pas facturé (FCD-5
   le compte à part).
5. **Zéro log d'argent** (checklist money-grade).

---

## 7. Pièges identifiés avant d'écrire

- ⚠️ **`due_at` nullable** — cf. D1. Ne pas bâtir « en ordre » dessus sans sonde.
- ⚠️ **Le roster peut ne pas être descendu.** Le scope hydrate
  `SyncClassroomReferentialUseCase`, mais la table peut rester vide (panne
  terrain du 2026-08-14). Le dépliage doit alors **le dire**, et le niveau
  rester lisible — réutiliser `feeControlEmptyRosterMissing`.
- ⚠️ **`classroom.read` peut manquer.** Le dépliage est indisponible et se
  nomme (`feeControlClassroomWithheld` existe déjà) ; le classement par niveau,
  lui, ne dépend d'aucun droit supplémentaire.
- ⚠️ **`AppPageBackground` borne le contenu à 1180 px** — tout seuil responsive
  au-dessus est inatteignable, quelle que soit la taille de l'écran.
- ⚠️ **`accueil_page_test.dart` code en dur** le nombre de cartes et de lignes ;
  `shell_sub_menu_coverage_test.dart` code en dur la table des identifiants. Un
  sous-menu neuf casse les deux — c'est attendu.
- ⚠️ **Un sous-menu déclaré au registre DOIT avoir son `case`** dans le `switch`
  de la coquille, sinon il tombe dans « page en cours de développement » sans la
  moindre erreur.

---

## 8. Architecture

```
lib/features/finance/offline/                    ← lectures (grand-livre)
  data/local/dao/finance_ledger_read_dao.dart     + 2 méthodes (§5)
  domain/entities/                                + FeeLevelChargePosition
  domain/usecases/                                + GetFeeCodesForYearUseCase
                                                  + GetFeeChargePositionsByLevelUseCase

lib/features/fee_control/presentation/           ← le module (présentation seule)
  bloc/fee_control_dashboard_{bloc,event,state}.dart
  bloc/fee_control_dashboard_projector.dart       ← pur, réutilise FeeControlBreakdown
  contracts/fee_control_dashboard_contracts.dart
  pages/fee_control_dashboard_page.dart
  widgets/fee_control_dashboard_{filters,summary_band,group_ranking,group_row}.dart
  widgets/states/fee_control_dashboard_{empty,error}_state.dart
```

Réutilisé tel quel : `EteeloKpiBand` / `EteeloKpiCardData` (dont `percent` et
`valueLines`), `DonutChartSection`, `EteeloListSkeleton`, `EteeloEmptyResult`,
`EteeloErrorResult`, `FeeControlBreakdown`, `LocalFeeChargeAggregate`,
`MoneyBag`, `localizedFeeLabel`, `FeeControlFeatureScope` (déjà monté, rien à
ajouter côté hydratation).

---

## 9. Les lots

**FCD-0 — lectures locales.** ✅ *livré le 2026-09-03.* Les deux requêtes du §5,
`LocalFeeLevelAggregate`, deux usecases, DI, **13 tests DAO** sur base sqflite en
mémoire — multi-devise, élève à cheval sur deux niveaux, créance sans niveau,
créance sans année, filtre de cycle, encaissement hors ligne qui solde.
Trois **contre-épreuves par mutation** passées : réintroduire le `null` en
`whereArgs` fait bien lever sqflite (10 tests rouges), retirer le niveau du
`GROUP BY` ou filtrer `school_level_id IS NOT NULL` font rougir exactement le
test dédié. Mesure de coût reportée au §5.

**FCD-1 — projecteur.** ✅ *livré le 2026-09-03.*
`FeeControlDashboardProjector.project` rend un `FeeControlDashboardSummary` :
total du périmètre, reste dû par devise, et les groupes **classés du plus en
retard au plus en règle**. Pur, sans I/O. **16 tests**, quatre contre-épreuves
par mutation.

Deux règles y sont posées, et une troisième corrigée au passage :

- **Le classement compare des fractions exactes**, en produits croisés
  d'entiers — jamais le pourcentage affiché, qui rendrait ex æquo deux groupes à
  99,4 % et 99,8 %. Départage : effectif décroissant, puis identifiant, pour un
  ordre **reproductible**.
- **`feeSharePercent`** (posé dans `fee_control_projector.dart`, partagé par tout
  le module) : « 100 % » ne s'écrit que si personne ne reste, « 0 % » que si
  personne n'y est, clamp à [1, 99] entre les deux. Un arrondi ordinaire annonce
  « 100 % » sur 249 soldés pour 250 — le préfet lit « niveau en règle » et le
  dernier débiteur sort du radar.
- ⚠️ **Défaut préexistant corrigé** : `FeeControlSummaryBand` (écran de contrôle)
  arrondissait ordinairement. Il passe par `feeSharePercent`, sans quoi le même
  niveau se serait annoncé à 100 % sur un écran et à 99 % sur l'autre. Deux
  tests de régression l'épinglent.

⚠️ **Un test écrit ici ne prouvait rien** : les identifiants de niveau du cas
« ex æquo » faisaient coïncider le départage alphabétique avec l'ordre attendu,
si bien que muter le comparateur ne le faisait pas rougir. Corrigé en choisissant
des identifiants dont l'ordre alphabétique est l'**inverse** de l'ordre attendu.
À refaire pour tout test d'ordre.

**FCD-2 — BLoC + états.** ✅ *livré le 2026-09-03.* `FeeControlDashboardBloc`
(factory GetIt), trois événements — natures de frais, interrogation, reprise —
et un état qui distingue « rien demandé » de « demandé, rien trouvé »
(`lastQuery` / `hasEmptyResult`). **14 tests** : 12 de comportement + 2 de
câblage DI, quatre contre-épreuves par mutation.

Quatre gardes, chacune avec son test et sa mutation :

- **Générations de chargement.** Le transformer par défaut étant `concurrent`,
  changer de frais deux fois suffit à faire voler deux lectures ; seule la plus
  récente écrit. Sans cela, une lecture périmée résolue en dernier repeint le
  classement sous le nom d'un autre frais.
- **Un échec efface le résumé.** Garder l'ancien classement à côté du message le
  ferait passer pour valide sous les critères affichés.
- **`_nullIfEmpty` sur le cycle** : un `'  '` ne descend jamais jusqu'au SQL.
- **Réessayer sans `lastQuery` ne fait rien** : une reprise ne doit pas
  interroger autre chose que ce qui a échoué.

Échecs mappés comme `FeeControlBloc` — lecture locale ⇒ type « serveur », jamais
réseau/401/403 : un même incident ne se dit pas autrement d'un écran à l'autre.

⚠️ **Question laissée à FCD-3** : le tableau de bord doit-il **auto-sélectionner**
un frais à l'ouverture (un tableau de bord se lit, il ne se remplit pas), ou
attendre un choix comme le fait l'écran de contrôle ? Le premier `fee_code` est
le premier par ordre alphabétique du code — arbitraire, et pas forcément le
minerval. Le BLoC sait faire les deux ; c'est une décision d'écran.

**FCD-3 — la page.** ✅ *livré le 2026-09-03.* Deux sélecteurs, bandeau,
classement. Navigation complète : `MenuConstants.feeControlDashboardId`, route
`/controle-frais/controle-frais-dashboard`, barre latérale, carte d'accueil
(dont l'en-tête mène désormais **au tableau de bord**), registre d'accès, `case`
de coquille, 12 chaînes FR + EN. **13 tests** (11 widget + 2 page), trois
contre-épreuves.

- **L'écran ouvre sur le frais le plus porté** (arbitrage du 2026-09-03).
  `getFeeCodesForYear` trie donc par `COUNT(*)` décroissant : un tri
  alphabétique aurait ouvert sur « ASSUR » — douze élèves — quand la question du
  matin porte sur le minerval.
- **Une seule teinte pour toutes les barres.** Colorer chacune selon sa valeur
  double l'encodage de la longueur par la couleur (anti-pattern « value-ramp on
  nominal categories ») et peint un jugement là où le classement suffit : ce qui
  décroche est déjà en tête.
- ⚠️ **Écart au plan assumé : pas d'anneau** à côté du bandeau. Les quatre
  cartes portent déjà leur part ; un second graphique redirait ces trois nombres
  sans rien ajouter. `DonutChartSection` reste disponible si l'on change d'avis.
- **`feeControlSummaryCards` extrait et partagé** par les deux bandeaux du
  module : un même état porte le même nom, la même teinte et le même arrondi
  d'un écran à l'autre.
- **Deux absences, deux messages** dans le classement : « Niveau non renseigné »
  (la créance n'en porte pas) et « Niveau absent du référentiel » (le
  référentiel n'est pas descendu). Une ligne muette vaut mieux qu'une ligne
  effacée, dont l'absence ferait mentir le total.

⚠️ **Deux pièges de test payés ici :**
 - `EteeloListSkeleton` **shimmer sans fin** : `pumpAndSettle` y expire. Les
   états animés se pompent d'une frame.
 - Un `BlocConsumer.listener` ne se déclenche que sur un **changement** d'état :
   un harness qui donne l'état final comme état initial ne voit rien bouger et
   passe à côté de tout. Le harness fait donc transiter `initial → success` —
   fidèle à la production, où la page reçoit un bloc neuf à chaque montage.

**FCD-4 — dépliage en classes.** ✅ *livré le 2026-09-03.* Taper un niveau
l'ouvre sur ses classes ; retaper le referme. **19 tests** (7 bloc + 6 widget,
plus les 6 déjà là), trois contre-épreuves.

- **Aucune relecture du grand-livre.** Les élèves du niveau sont déjà en mémoire
  depuis l'interrogation du frais ; déplier n'est qu'une répartition. Les
  positions sont gardées **hors de l'état** (`_positions`) : les y mettre
  alourdirait chaque comparaison d'`Equatable` de centaines d'objets, à chaque
  `buildWhen`, pour une donnée que l'écran ne rend jamais telle quelle.
- **Un seul niveau ouvert à la fois.** On déplie celui qui décroche pour voir
  quelle classe le tire ; la question ne se pose pas sur deux niveaux en même
  temps.
- **Amendement à D6** : `GetUnassignedLevelEnrollmentsUseCase` n'est **pas**
  utilisé. Les non-répartis se déduisent en mémoire — les élèves du niveau
  qu'aucun roster ne réclame — ce qui évite une lecture et garde le dénominateur
  exact : les élèves *concernés par le frais*, jamais les inscrits.
- ⚠️ **`placed` est marqué avant le filtre du frais** : un élève inscrit dans une
  classe est réparti, qu'il porte ce frais ou non. Le compter « non réparti »
  parce qu'il ne doit rien serait faux.
- **Une nouvelle interrogation replie** : les classes ouvertes étaient celles
  d'un autre frais ou d'un autre périmètre.
- **Deux causes derrière « aucune classe »**, tranchées par `classroom.read` au
  rendu : sans le droit, le roster n'est jamais tiré et « pas encore descendue »
  enverrait chercher côté synchro un manque qui est côté droits.
- **Une seule ligne pour les deux mailles** (`FeeControlDashboardGroupRow`,
  variante `dense`) : un niveau et une de ses classes se lisent pareil, et deux
  widgets auraient fini par les afficher différemment.

⚠️ **Deux pièges de test payés ici :**
 - Un helper nommé `group()` **masque le `group()` de flutter_test** et fait
   échouer la compilation sur un message trompeur.
 - Un `any()` sans `registerFallbackValue` ne casse pas que son propre test :
   mocktail laisse les **suivants** dans un état où le mock ne répond plus, et
   ils échouent sur des messages sans aucun rapport. Six échecs ici pour un
   seul repli manquant.

**FCD-5 — les non-facturés.** ✅ *livré le 2026-09-03.* Une note sous le
bandeau : « N élèves inscrits ne portent pas ce frais ». **9 tests** (5 bloc +
4 widget), trois contre-épreuves.

- **À côté du taux, jamais dedans.** Un élève sans créance de ce frais n'est pas
  un mauvais payeur : il n'est pas facturé. Le compter au dénominateur ferait
  chuter le taux d'une classe pour une raison étrangère au recouvrement.
- **Best-effort, et séparé de la lecture principale.** Si le comptage échoue, le
  classement reste à l'écran et le compteur reste inconnu. Le faire porter par
  le même `Either` aurait fait tomber tout l'écran en échec pour un compteur
  d'appoint — le guichet aurait perdu le classement avec la note.
- **`null` n'est pas `0`.** « On n'a pas pu vérifier » et « personne n'est hors
  facturation » n'autorisent pas le même silence : la note se tait dans les deux
  cas, mais l'état les distingue.
- ⚠️ **Compte des élèves DISTINCTS**, jamais les couples (élève, niveau) du
  classement : un élève à cheval sur deux niveaux y compte deux fois (D5), et le
  soustraire deux fois inventerait un non-facturé.
- Le périmètre de la note est celui de l'écran : le filtre de cycle descend dans
  la lecture.

**FCD-6 — pont vers le contrôle.** ✅ *livré le 2026-09-03.* Une action « Voir
les élèves » sur chaque ligne ouvre `FeeControlPage` pré-remplie, recherche
lancée. **11 tests** (5 dashboard + 6 écran nominatif), quatre contre-épreuves.

- **Geste distinct du dépliage.** Sur un niveau, taper la ligne ouvre ses
  classes ; l'icône ouvre la liste des élèves. Les confondre priverait de l'un
  des deux.
- **Le frais vient de `lastQuery`, jamais des sélecteurs.** Entre la lecture et
  le tap, l'utilisateur a pu changer de frais sans relancer : ce sont les
  chiffres **affichés** qui ouvrent la liste, sinon elle ne répondrait pas de la
  synthèse qui l'a ouverte.
- **Le cycle vient du niveau, pas du filtre** : le filtre peut valoir « tous les
  cycles », que l'écran nominatif refuserait. `SearchLevelOption.keyFor` est
  exposé depuis `core` plutôt que le format de clé recopié — recopié, il
  divergerait au premier changement et la sélection ne retrouverait plus son
  option.
- **La recherche attend la grille.** La requête porte le libellé et le code de
  la ligne tarifaire : lancée plus tôt, elle enverrait une désignation vide et
  la puce de critère mentirait. Si la nature n'est pas dans la grille du niveau,
  **rien n'est cherché** — le formulaire reste pré-rempli et montre ce qui
  manque, plutôt qu'un vide inexplicable.
- **Ni les non-répartis ni le groupe « niveau non renseigné » n'offrent le
  passage** : ils ne désignent pas un périmètre transmissible.
- ⚠️ **Défaut corrigé au passage** : `didUpdateWidget` du formulaire invalidait
  la sélection **pendant le chargement** — la liste vide n'est alors pas une
  disparition, seulement une ignorance. Invisible jusqu'ici (l'opérateur choisit
  le niveau puis le frais), le défaut effaçait le pré-remplissage du pont.

⚠️ **Piège de test payé ici, en trois essais :** un `whenListen` alimenté par
`Stream.fromIterable` est **drainé avant le premier frame**. Le widget ne voit
que l'état final et ne traverse jamais les états intermédiaires : la mutation
qui retirait la garde ci-dessus restait verte. Il faut un `StreamController` et
un `pump` entre chaque émission pour éprouver un comportement transitoire.
Une première assertion, `find.textContaining`, était par ailleurs trop
tolérante — le libellé cherché apparaît aussi dans la liste déroulante ; c'est
la **valeur du champ** qu'il faut lire.

**FCD-7 — finition.** ✅ *livré le 2026-09-03.* A11y, l10n, revue money-grade
(`offline-money-grade-review-checklist`) et revue adversariale ciblée sur la
dérivation de statut et le dénominateur. **Trois défauts réels**, tous corrigés
et tous éprouvés par mutation ; deux limites assumées, écrites ici pour qu'on ne
les « corrige » pas un jour.

### 🔴 L'écran ne demandait JAMAIS sa liste de frais

`FeeControlDashboardFeeCodesRequested` était déclaré, câblé dans le bloc, testé
dans le bloc — et **émis par personne**. La page écoutait `feeCodes` sans que
rien ne les charge : sélecteur vide et désactivé, auto-sélection sans liste sur
quoi s'ouvrir, classement jamais interrogé. Le tableau de bord n'affichait
**rien**, sans la moindre erreur, sur un appareil dont le grand-livre était
plein.

Pourquoi la suite ne le voyait pas : les deux tests de page partaient d'un état
où les natures étaient **déjà là** — ils éprouvaient ce que l'écran fait de la
liste, jamais qu'il la demande. C'est le trou classique du test qui pose
l'hypothèse qu'il devrait vérifier.

L'amorçage se fait donc dans le `build`, le contexte académique connu, hors
frame (`addPostFrameCallback`) et gardé par l'année déjà demandée : le `build`
est rejoué à chaque frappe des sélecteurs, et un événement par frappe aurait
fait voler autant de lectures.

### L'échec de cette lecture ne disait rien non plus

`feeCodesStatus: failure` était stocké et lu par personne : l'écran retombait
sur le même vide que « aucune créance sur l'appareil ». Deux causes opposées
derrière le même silence — l'une envoie synchroniser, l'autre est une panne
locale. L'échec passe désormais par `EnrollmentResultsErrorState`, avec reprise
(jamais « reconnexion » : la lecture est locale).

### La ligne s'annonçait « bouton » sans porter d'action

`Semantics(button: true)` par-dessus un `InkWell` **enfermé sous
`ExcludeSemantics`** : le nœud n'exposait aucune action, et la double-tape d'un
lecteur d'écran ne dépliait rien. Un rôle sans action est un bouton qui ment.
`onTap: onToggle` posé sur le `Semantics` lui-même ferme le trou — et le test
contre-éprouve **l'action**, pas le rôle : il joue
`node.owner!.performAction(id, tap)` et vérifie que le niveau se déplie.

### Ce que l'a11y vérifie désormais (8 tests)

Un écran de mesure est le plus exposé de tous : ses chiffres vivent dans des
barres, et une barre ne se lit pas. Sont éprouvés : la ligne s'annonce **d'une
phrase** (« Primaire · 1ère année : 84 % en ordre, 26 sur 31 élèves
concernés »), le geste se **nomme** selon l'état (déplier / masquer), une ligne
inerte n'annonce **ni rôle ni action**, le passage « Voir les élèves » est un
**nœud à part** qui agit, et le bandeau se dit d'un seul nœud **son nom
d'abord** — sans quoi le lecteur attaquerait par « 31 », un nombre sans sujet.

Le dépliage, enfin, **répond**. Sa barre de progression était muette et ses
trois notes (échec, droit manquant, roster non descendu) inertes : taper un
niveau ne disait rien du tout à qui ne voit pas l'écran, et l'attente ne se
distinguait pas d'un geste sans effet. La barre se nomme
(`feeControlDashboardClassesLoading`, clé neuve dans les deux `.arb`) et les
notes sont des **régions vives** — elles sont la réponse à la tape, elles
doivent s'annoncer sans qu'on aille les chercher.

### Revue money-grade — verdict

Rien à corriger sur l'argent lui-même. Vérifié un à un : le `paid_pending` est
composé à la lecture par la **même requête** que l'écran nominatif (`sync_status
<> SYNCED`, donc `PENDING_SYNC` **et** `SYNC_ERROR`) ; le statut est **emprunté**
à `LocalFeeChargeAggregate`, jamais recopié ; aucune addition de devises nulle
part (`MoneyBag` partout, `remaining` ventilé) ; **zéro log** sur ces chemins ;
aucun `null` en `whereArgs` (le filtre de cycle est une clause ajoutée) ; les
colonnes lues en cast strict sont `NOT NULL` au schéma (`student_id`,
`fee_code`) ; les deux lectures passent par le `_guard` du repository, donc
aucune n'échappe en `throw`. Le module n'écrit rien : ni outbox, ni curseur.

**Un défaut de comptage, tout de même, mais côté note.** Les non-facturés
comptaient des **lignes de dossier**, quand le commentaire promettait des
**élèves distincts** : un élève portant deux dossiers sur l'année — une
pré-inscription reprise, un brouillon local à côté du dossier descendu —
inventait un non-facturé. Deux ensembles d'élèves et une différence, désormais.
Le taux, lui, n'a jamais été touché : la note vit à côté.

### Deux limites assumées

- **Un élève parti garde sa créance, donc sa ligne.** Le tableau de bord découvre
  sa population dans le grand-livre (invariant §6.4 : « le taux porte sur les
  concernés »), tandis que l'écran nominatif croise les **inscriptions**. Un
  élève qui a quitté l'école en gardant une dette est donc compté ici et absent
  là-bas. C'est voulu — une dette ne s'efface pas d'un départ — mais cela
  explique qu'un niveau annonce « 31 concernés » quand la liste nominative
  n'affiche que 30 noms.
- **La note des non-facturés croise deux cycles qui peuvent diverger.** Les
  positions sont bornées par le `school_level_group_id` de la **créance**, les
  inscrits par celui du **dossier**. Un élève dont la créance porte encore
  l'ancien cycle apparaîtrait comme non facturé. Cas de données incohérentes,
  sans effet sur le taux.
