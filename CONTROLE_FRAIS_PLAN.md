# CONTROLE_FRAIS_PLAN.md — qui est en règle, nom par nom

> **Statut :** proposé le 2026-09-10, **CF-0 → CF-9 livrés le même jour**
> (non commité). `flutter test` : **6472 verts**. `flutter analyze` : 29 issues,
> contre **31 avant** le lot — aucune introduite.
>
> Arbitrages **A1–A3 tranchés par le user le 2026-09-10** — les trois
> recommandations retenues : deux routes (pas d'onglets) · overlay de lecture +
> fiche Facturation pour agir · liste d'appel en PDF **local**.
>
> | Lot | État |
> |---|---|
> | CF-0 · contrats & projecteur (sélection de frais, 5 situations, plancher) | ✅ livré |
> | CF-1 · la lecture : registre × roster, une ligne par élève | ✅ livré |
> | CF-2 · carte de périmètre : pastilles, classe, filet, segments, plancher | ✅ livré |
> | CF-3 · compteurs-filtres + carte « Encaissé » | ✅ livré |
> | CF-4 · tableau : 6 colonnes, cases, tri figé, en-tête qui rejoue la requête | ✅ livré |
> | CF-5 · sélection & barre d'actions contextuelle | ✅ livré |
> | CF-6 · marquage « à renvoyer » : encart, badge, toast, vidage | ✅ livré |
> | CF-7 · aperçu élève (overlay) | ✅ livré |
> | CF-8 · feuille d'appel à signer (PDF local) | ✅ livré |
> | CF-9 · deux vides, deux issues · a11y · l10n FR+EN | ✅ livré |
> | §9 · relance aux parents | ⛔ **hors d'atteinte** — voir 3.5 |
>
> **Écarts assumés à la spec**, tous commentés dans le code :
> 1. pas de tolérance d'arrondi sur le statut (nous comptons en centiers
>    entiers, et la règle est partagée avec le tableau de bord) ;
> 2. le taux est `(attendu − reste) / attendu`, pas `payé / attendu` — la règle
>    du module et du serveur ;
> 3. la fiche montre les frais **retenus**, pas les quatre : la vérité complète
>    du dossier est dans la Facturation, et son bouton y mène ;
> 4. la ligne dit « dossier », pas « matricule · payeur » — le payeur n'a pas
>    de source locale ;
> 5. la pastille ne prend pas la couleur du poste (pas de palette par frais
>    chez nous) et ne montre son symbole que si la grille n'en connaît qu'un.
>
> **Source :** `ui_kits/app/Recouvrement-Controle-Frais-Spec.html` — projet
> Claude Design « ETEELO CONNECT Design System », 14 sections, lue le
> 2026-09-10.
>
> **Docs de contexte :** `RECOUVREMENT_PLAN.md` (le module) ·
> `FEE_CONTROL_DASHBOARD_PLAN.md` (l'onglet voisin, livré) ·
> `MULTIDEVISE_PLAN.md` (la doctrine bi-devise) · `NOMMAGE_CHARGES_PLAN.md`
> (nommer par la grille, mesurer par la nature) · `AGENTS.md` §« États
> partagés ».

---

## 1. La question posée

Le tableau de bord répond « combien, et où ». Cet écran-ci répond **« qui »** :
pour une sélection de frais et une classe, il nomme ceux qui ont tout soldé,
ceux qui ont versé une partie, ceux qui n'ont rien donné.

D'où sa forme : un **tableau nominatif**, une **sélection multiple**, et des
**sorties concrètes** — une feuille à faire signer, un message aux parents, une
liste de travail « à renvoyer ». L'écran ne solde rien, n'émet aucun reçu, ne
remise personne : ses seuls effets sont un document, un message, et un brouillon
en mémoire.

Sept strates, dans l'ordre de la question : **quoi** (frais, classe) → **quelle
situation** → **combien ils sont** → **qui** → **quoi en faire**.

---

## 2. Le fait déterminant — la moitié du travail est déjà faite

**`LocalRecoveryLine` EST le `recLedger` de la spec.** Livré avec le tableau de
bord, il porte déjà, pour un élève et une **sélection de frais** :

```
schoolLevelId · studentId · charges[(fee_code, devise)]
expected / paidTotal / remaining  →  MoneyBag, une entrée par devise
status                            →  rien | partiel | soldé, sur TOUTE la sélection
```

C'est-à-dire, terme pour terme, le `{du, paye, reste, dev, statut, taux}` que la
spec décrit en §11 et §12. La sélection multi-frais, l'agrégation par
compartiment de devise, la règle « soldé seulement si toutes le sont » : rien de
tout cela n'est à écrire.

### Le reste de l'inventaire

| Ce que la spec nomme | Ce que nous avons | Écart |
|---|---|---|
| `recLedger(eleve, postes)` | `LocalRecoveryLine` + `LocalFeeChargeAggregate` | **néant** |
| `MoneyPair {USD, CDF}`, « jamais de somme inter-devises » | `MoneyBag` — le type lui-même interdit la somme | **néant** |
| `finEq(pair,'USD')` (taux, tri) | `ExchangeRates.at(...)` + `dollarInFrancs()` | **néant** |
| `recCounts` → 4 effectifs | `FeeControlBreakdown` + `feeControlSummaryCards` | il manque le **clic** et la 5ᵉ carte |
| `DataTable` + `Pagination` + `DataTableSkeleton` | `DataTableView` / `DataTableViewConfig` | il manque la **colonne de cases** |
| `FinEmpty` (2 vides) | `EteeloEmptyResult` + `FeeControlResultsEmptyState` | il manque le **2ᵉ vide** (classe sans élève) |
| `ErrorState({type})`, 4 tonalités, 403 sans « Réessayer » | `EnrollmentResultsErrorState` | **néant** (règle #10) |
| `Skel` / `FinStatsSkeleton` | `EteeloListSkeleton` / `EteeloSkeletonBox` | **néant** |
| `RecOverlay` | `EteeloDialogBody` | **néant** |
| Impression du document | `printing` 5.14.3 + `pdf` 3.12.0 au `pubspec` | à câbler |
| Les 7 couleurs citées (§Tokens) | **toutes déjà dans `AppColors`** | **néant** |

⇒ Aucun token neuf, aucune couleur en dur, aucune brique de socle à inventer.

---

## 3. Les cinq écarts qui coûtent

### 3.1 — Le périmètre change de nature

| | Aujourd'hui | Cible |
|---|---|---|
| Frais | **un seul**, choisi dans la grille tarifaire du niveau | **plusieurs**, pastilles à cocher, sélection jamais vide |
| Portée | cycle → niveau → classe (facultative) | **la classe**, jamais l'établissement (« on ne fait pas l'appel de 412 élèves ») |
| Identité | nom / postnom / prénom en critères additionnels | **supprimés** |
| Situation | 4 valeurs (`FeeControlPaymentFilter`) | **5** — la 5ᵉ est « A payé au moins… » + montant plancher |

Les deux moitiés du chemin de données existent déjà, mais **elles n'ont jamais
été jointes** : `getRecoveryPositions` lit par `feeCodes` (+ cycle) et **ne sait
pas filtrer par classe** ; le `FeeControlBloc`, lui, borne à la classe via
`GetOfflineRosterUseCase`. Le lot CF-1 consiste à croiser les deux — intersection
en Dart sur `studentId`, aucune requête neuve, aucun bump de schéma.

⚠️ **La devise n'appartient pas au frais chez nous.** La spec pose
`FIN_POSTE[k].dev` — l'inscription en FC, le reste en $, immuable. Notre
`student_charges` porte la devise **par créance** : rien n'interdit à un même
`fee_code` d'exister dans deux devises sur un périmètre. La pastille ne peut
donc pas afficher « son » symbole en dur. **Règle de repli à écrire :** le
symbole d'une pastille est celui des créances du périmètre pour ce code — et
s'il y en a deux, la pastille n'affiche aucun symbole et la sélection compte
comme mixte. Sans cette règle, le champ « montant plancher » s'ouvrirait sur une
sélection mixte et comparerait 50 000 FC à 120 $.

### 3.2 — Le tableau devient un poste de travail

- **Colonne de cases** : sélection sur tout le résultat, « Sélectionner la
  page » ne coche que les 10 visibles, le clic sur la case **ne doit pas** ouvrir
  la fiche.
- **Tri figé** : taux croissant puis nom, **non réordonnable**. On retire donc le
  tri utilisateur actuel (5 colonnes triables) — l'ordre *est* la priorité de
  relance. C'est une perte de capacité assumée par la spec ; elle mérite d'être
  dite au user avant d'être livrée.
- **Cellule élève** : avatar teinté par cycle + nom + badge « à renvoyer » +
  seconde ligne « matricule · payeur ». Nous avons `StudentAvatar` et
  `enrollmentCode` (qui tient lieu de matricule) ; **le payeur, non** (cf. 3.5).
- **Six colonnes** au lieu de sept, et le repli `< 820 dp` fusionne Dû et Payé
  sous Reste — notre bascule actuelle (`feeControlTableWideMin`) fait déjà
  exactement ce mouvement, il n'y a qu'à la recaler.

### 3.3 — Les compteurs deviennent des filtres

Quatre tuiles **cliquables** (`aria-pressed`, état enfoncé) qui appliquent la
situation, plus une cinquième carte non cliquable « Encaissé sur ces frais »
(`MoneyBag`, deux lignes en sélection mixte, **jamais une somme**).

Point de conception à ne pas rater : **les compteurs portent sur la classe
entière**, jamais sur le résultat filtré — sinon la tuile active affiche son
propre reflet. Les quatre effectifs se somment exactement au total.

⚠️ `EteeloKpiCard` n'a pas d'`onTap`. Extension **additive** du composant
partagé (`onTap` + `selected` optionnels), comme la Facturation l'a fait pour
ses KPI : aucun appelant existant ne change.

### 3.4 — Quatre sorties, dont deux neuves

| Sortie | Aujourd'hui | Verdict |
|---|---|---|
| Fiche élève | `push` vers la fiche Facturation | overlay de lecture **+** le `push` conservé (A2) |
| Liste d'appel à signer | rien ici ; `RecouvrementCallListSheet` en est l'ébauche côté tableau de bord | PDF **local** `printing` + `pdf` (A3) |
| Relance aux parents | rien | **hors d'atteinte en V1** (3.5) |
| Marquage « à renvoyer » | rien | faisable tel quel — `Set<String>` de séance, badge, encart, toast |

Le marquage est le plus simple **et le plus délicat à écrire juste** : c'est un
brouillon, rien n'est notifié, rien n'est écrit au dossier, et **aucun bouton
« Appliquer les renvois » n'existe** — ni ici ni au tableau de bord. Un renvoi
effectif passe par le dossier d'inscription, élève par élève. Le texte de
l'encart dit trois choses dans cet ordre : c'est un brouillon · rien n'est
notifié · l'étape suivante est de **mesurer**, pas d'appliquer.

### 3.5 — ⛔ La relance aux parents n'a pas de matière

Deux manques, indépendants l'un de l'autre :

1. **Le numéro.** `guardian_name` / `guardian_phone` n'existent en base locale
   que sur `ref_reenrollment_candidates` et `ref_pre_enrollments` — les
   **candidats**, pas les inscrits. Un élève inscrit de longue date n'a donc
   aucun payeur joignable côté appareil. (`LocalPayerIdentity` ne comble pas le
   trou : c'est l'annuaire des **payeurs constatés à la caisse**, pas le tuteur
   de l'élève.)
2. **Le canal.** `url_launcher` ouvre l'app native **un destinataire à la
   fois** ; il n'existe pas de `sms:` multi-destinataires portable, et
   « Message app » suppose une application parent qui n'existe pas.

⇒ **CF-8 est isolé et sortable du périmètre sans rien casser.** Ce qui reste
atteignable sans back : depuis la **fiche élève**, un bouton « Appeler » /
« Écrire » quand — et seulement quand — un numéro est là. La relance en lot
demande une route back (`POST /finance/relance-notify` ou équivalent) et un
tuteur descendu au pull : c'est une demande à formuler, pas un lot à planifier.

---

## 4. Les trois arbitrages — **tranchés**

### A1 — Onglets, ou deux entrées de menu ? — ✅ **(a) deux routes**

La spec monte une **coque unique** (`RecouvrementScreen`) avec `PageHeader` +
deux onglets : *Contrôle des frais* · *Tableau de bord*. Le titre change avec
l'onglet — « l'écran se renomme au lieu de commuter son contenu ».

Nous avons livré l'inverse **il y a huit jours** : un menu propre, deux
sous-menus, deux routes (`/recouvrement/…`), un `FeatureScope` par écran.

| Option | Ce que ça coûte |
|---|---|
| **(a) Garder les deux routes** *(recommandé)* | zéro. On aligne le contenu de la page, pas la navigation. Le sous-menu latéral *est* déjà le sélecteur d'onglet, une strate plus haut. |
| (b) Passer aux onglets | route unique + `TabBar`, deux `FeatureScope` fusionnés ou imbriqués, sous-menus refondus, ⚠️ `accueil_page_test.dart` **code en dur le nombre de sous-modules** et rougira. ~1 lot à lui seul. |

**Recommandation : (a).** La spec décrit une maquette web où le menu latéral
n'existe pas ; chez nous il existe et fait déjà le travail. Deux sélecteurs de
même niveau empilés seraient une redondance, pas une fidélité.

### A2 — Fiche élève : overlay local, ou fiche Facturation ? — ✅ **(a) les deux**

La spec ouvre un overlay 560 dp qui désagrège **les quatre frais** — barres de
progression, taux, reste par devise — et dit explicitement : *« toujours les
quatre frais, pas seulement les frais retenus : la fiche est la vérité complète
du dossier »*.

Le code actuel `push` la **fiche financière de la Facturation**, avec ce
commentaire : *« aucune duplication du détail »*.

| Option | Ce que ça coûte |
|---|---|
| **(a) Overlay léger + « ouvrir la fiche complète »** *(recommandé)* | un widget de lecture (~200 l.), zéro couche data neuve — `getRecoveryPositions` sait déjà rendre toutes les créances d'un élève. La fiche Facturation reste la sortie « pour agir ». |
| (b) Garder le `push` seul | fidélité nulle sur §7, et on perd le geste central de l'écran (lire vite, sans quitter sa liste ni sa sélection). |
| (c) Overlay seul | duplique la fiche Facturation et on finira par y ajouter « encaisser ». |

**Recommandation : (a).** L'overlay lit, la fiche Facturation agit. La frontière
reste nette et le commentaire du code reste vrai.

### A3 — Liste d'appel : PDF local, ou `POST /finance/relance-list` ? — ✅ **(a) PDF local**

La spec veut un `pw.Document` **reconstruit à l'identique** — en-tête, année,
date d'établissement, taux appliqué, colonne « Signature du parent » vide, deux
visas en pied.

Nous avons déjà, au tableau de bord, **un PDF produit par le serveur**
(`POST /finance/relance-list`) — le seul appel réseau du module, et il ÉCRIT.

| Option | Ce que ça coûte |
|---|---|
| **(a) PDF local, `printing` + `pdf`** *(recommandé)* | ~1 lot. Reste **100 % local**, donc imprimable en salle sans réseau — ce qui est exactement le cas d'usage (« une feuille que le percepteur emporte en classe »). Aucun numéro de pièce consommé. |
| (b) Réutiliser `relance-list` | l'écran devient dépendant du réseau et d'un back à jour ; le document serveur n'a ni colonne de signature ni visas ; et il porte une sémantique de **relance**, pas d'**appel**. |

**Recommandation : (a)**, en nommant la différence dans le code : la liste
d'appel est une **feuille de travail**, pas une pièce scellée du module
`documents` (pas de numéro, pas d'idempotence, pas d'outbox).

---

## 5. Le découpage

| Lot | Intention | Dépend de |
|---|---|---|
| **CF-0** | Contrats & projecteur : `FeeControlPerimeter` (frais multiples + classe), situation à 5 valeurs, plancher, devise dérivée du périmètre | — |
| **CF-1** | La lecture : croiser `getRecoveryPositions(feeCodes)` × roster de la classe ; tolérances §12 (rien = arrondi unité, soldé = reste ≤ ½ unité, trop-perçu = soldé) | CF-0 |
| **CF-2** | La carte de périmètre : pastilles de frais + Select classe + filet + segments de situation + champ plancher conditionnel + avertissement mixte | CF-0 |
| **CF-3** | Les compteurs-filtres : `EteeloKpiCard` cliquable (additif), 4 tuiles + carte « Encaissé » bi-devise | CF-1 |
| **CF-4** | Le tableau : 6 colonnes, cases, tri figé, cellule élève enrichie, en-tête de section qui rejoue la requête, pagination 10 | CF-1 |
| **CF-5** | Sélection & barre d'actions contextuelle (apparition, portée, remise à zéro sur changement de périmètre) | CF-4 |
| **CF-6** | Marquage « à renvoyer » : `Set` de séance, badge de ligne, encart `FinInsight`, toast, vidage | CF-4 |
| **CF-7** | Fiche élève (overlay) — les 4 frais, barres, reste par devise, pied d'actions | CF-1 |
| **CF-8** | Liste d'appel à signer : `pw.Document`, en-tête, numérotation, colonne signature, visas, taux imprimé | CF-5 |
| **CF-9** | Les deux vides distincts, les 4 erreurs, les squelettes qui préservent la géométrie, a11y (`aria-pressed`, `aria-live`, focus piégé), l10n FR+EN, revue money-grade | tous |

**Ordre de livraison utile :** CF-0 → CF-1 → CF-4 (le tableau d'abord : c'est lui
qu'on regarde pour savoir si la lecture est juste) → CF-2 → CF-3 → CF-5 → CF-6 →
CF-7 → CF-8 → CF-9.

---

## 6. Ce que je ne fais pas

- **La relance en lot** (§9) — sans tuteur local ni route back, elle n'a pas de
  matière. Une demande back sera formulée à part.
- **« Message app »** — il n'y a pas d'application parent.
- **Un bouton « Appliquer les renvois »** — la spec l'exclut explicitement, et
  le renvoi effectif relève des Inscriptions, dossier par dossier.
- **Le `FinDemoState`** (sélecteur de revue en pointillés) — la spec elle-même le
  dit à retirer en production.
- **L'impression de l'écran** — seule la liste d'appel s'imprime.

---

## 7. Les pièges connus qui s'appliquent ici

1. **`AppPageBackground` plafonne à 1180 dp.** Le palier « ≥ 1180 : tout sur une
   ligne » de la spec est donc notre **largeur maximale**, jamais un cas
   confortable. Vérifier la rangée de 5 tuiles à exactement 1180.
2. **`null` en `whereArgs` lève** (sqflite). Toute clause optionnelle se retire,
   elle ne se lie pas — `getRecoveryPositions` le fait déjà, ne pas défaire.
3. **Le taux paramétré est effacé par le pull** (POST manquant côté back). Il
   sert au taux affiché, au tri et à la mention imprimée : prévoir l'absence de
   taux (§12 règle 5) plutôt que de supposer qu'il est là.
4. **Un bouton `FilledButton`/`OutlinedButton` inline dans une `Row`** exige
   `minimumSize: Size(0, minTouchTarget)` — sans quoi la modale sort **sans
   taille** et casse au clic suivant. La barre d'actions (CF-5) et les pieds
   d'overlay (CF-7, CF-8) sont exactement ce cas.
5. **Tout test de modale monte `AppTheme.light`.** Sous le thème par défaut, le
   piège 4 est invisible.
6. **Une liste posée dans un `EteeloDialogBody` doit être inerte**
   (`shrinkWrap` + `NeverScrollableScrollPhysics`) : la liste des destinataires
   et le tableau de la feuille d'appel sont concernés.
7. **`resolveEnrollmentLevelLabels` : la ligne d'abord, les critères ensuite.**
   Le niveau est porté par la ligne depuis 2026-08-26.
8. **Zéro string en dur** → `app_fr.arb` **et** `app_en.arb`, puis `gen-l10n`
   **et** `dart format lib/l10n/` (sans quoi 3 clés = 1500 lignes de churn).
