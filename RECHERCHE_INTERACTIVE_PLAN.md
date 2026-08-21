# RECHERCHE_INTERACTIVE_PLAN.md — recherche interactive des élèves

> **Statut :** plan validé (2026-08-21). **Aucun lot ouvert.** Décisions
> verrouillées au §3, à ne pas rouvrir sans arbitrage.
>
> **Origine :** dernière ligne restante du chantier « Retravailler les
> formulaires » de `REVUE_CODE_BACKLOG.md`. Les deux autres sont livrées —
> bascule de mode (`6f763e9`) et formatage des champs (`f0e92e0`).
>
> **Besoin, dans les mots du demandeur :** « au bout de la troisième lettre de
> saisie, que les informations remontent afin de permettre à l'utilisateur de
> sélectionner un élève », au lieu d'exiger trois noms complets puis un bouton.
>
> **Docs de contexte :** `AGENTS.md` §"Formulaires de recherche" (anatomie de la
> bascule et règles de formatage), `OFFLINE.md`, `FACTURATION_OFFLINE_PLAN.md`
> §6 (invariants money-grade).

---

## 1. Le fait déterminant

**Le SQL ne filtre jamais sur un nom.** Les trois méthodes de recherche de
`EnrollmentReadDao` (`getEnrollments`, `searchByAcademicInfo`,
`searchEnrolledByAcademicInfo`) construisent leur `WHERE` sur l'année, le
niveau, le groupe de niveau, le statut métier et le type d'inscription — jamais
sur `first_name`, `last_name` ni `surname`. Elles rendent **toutes** les lignes
correspondantes, jointes à `students`.

Le filtrage par nom vit ensuite en Dart, dans
`EnrollmentLocalListProjector.project`, via `SearchNormalizationHelper.contains`
— trois `.where()` combinés en **ET**, un par colonne.

Une recherche par identité aujourd'hui, c'est donc, **par frappe** :

1. `WHERE academic_year_id = ?` — soit toutes les inscriptions de l'année ;
2. déchiffrement SQLCipher de chaque ligne ;
3. traversée du canal de plateforme (sqflite sérialise les lignes en maps) ;
4. une construction d'objet par ligne (`_listItem`, puis la projection en
   `EnrollmentSummary`) ;
5. trois `normalize()` de champ **et trois `normalize()` du terme** par ligne :
   `contains(field, term)` renormalise son terme à chaque appel.

`normalize()` alloue un `StringBuffer` et parcourt la valeur rune par rune avec
un `indexOf` sur une chaîne de 29 caractères accentués. Sur un corpus de l'ordre
du millier d'inscriptions — hypothèse de travail, **non mesurée**, à confirmer
au lot R-1 — cela représente plusieurs milliers d'allocations et de l'ordre du
million de comparaisons de caractères, **sur l'isolate UI** : sqflite exécute la
requête hors isolate, mais le mapping et le projector, non.

Brancher un type-ahead là-dessus sans rien changer d'autre, c'est du jank
garanti sur une tablette Android d'entrée de gamme.

**Mais le même fait porte la solution.** Entre deux frappes, le corpus ne change
pas : même année, même niveau, même statut. Seul le terme varie, d'un caractère.
On refait aujourd'hui 100 % du travail pour cette variation. Le cache de corpus
(§6, R-1) supprime les postes 1 à 4, et les clés précalculées (R-2) réduisent le
poste 5 à un `String.contains` natif.

### Ce que la base offre déjà, et ce qu'elle n'offrira pas

| Élément | État | Conséquence |
|---|---|---|
| `idx_students_names ON students(last_name, first_name)` | existe | Sert un préfixe (`LIKE 'kab%'`), **pas** un `contains` (`%kab%`). Et les requêtes attaquent par `enrollments`, pas par `students`. |
| Collation insensible aux accents | **absente** | `LIKE` n'ignore la casse que pour l'ASCII. `COLLATE NOCASE` n'existe dans le schéma que sur l'email d'auth. C'est **la** raison d'être de la normalisation Dart. |
| Scope école | transitif | `enrollments` ne porte pas de `school_id` ; le scope vient de l'année, elle-même scopée par `ref_academic_years.school_id`. Filtrer sur l'année suffit. |
| Garde anti-course | **existe** | `_loadGeneration` dans `EnrollmentLocalListBloc` (sémantique restartable maison, sans `bloc_concurrency`), même motif dans `FeeControlBloc`. À réutiliser, pas à réinventer. |
| Debounce | **absent** | Aucun `EventTransformer` de ce type dans l'app. À introduire. |
| Précédent de `LIKE` en SQL | `ParentSearchDao` | `LIKE '%…%'` avec échappement des métacaractères et `limit: 20` — mais **sans normalisation d'accents** (cf. P5). |

---

## 2. Pertinence

| Où | Ce que ça apporte | Verdict |
|---|---|---|
| Mode identité des listings d'inscription | Supprime l'exigence des **trois** noms complets (`_hasAllNames`) — la friction n°1. À la caisse on connaît « Kabongo » et un prénom approximatif. | Fort |
| Affinage en mode classe, Contrôle des frais | Corpus d'une soixantaine d'élèves : la liste se réduit sous les doigts, coût quasi nul. | Fort, et le moins risqué |
| Popin « Rechercher un parent » | Le numéro se cherche déjà par bribe, mais derrière un bouton. | Moyen-fort |
| Facturation / Documents | Ouvre un grand-livre ou un catalogue de pièces. | Fort **mais risqué** — cf. P4 |
| Cascade cycle → niveau | Deux listes fermées, rien à taper. | Aucun |

---

## 3. Décisions verrouillées

**D-1 — Un champ unique, en OU sur les trois colonnes.** « kab » remonte tout
élève dont le nom **ou** le post-nom **ou** le prénom contient « kab ». C'est un
**changement de sémantique** : aujourd'hui les trois champs se combinent en ET,
chacun sur sa colonne. Les résultats s'élargissent, ce qui rend P3 et P4 plus
aigus.

**D-2 — Suggestions ET tableau.** Les suggestions sont un panneau
**transitoire** ancré au champ, qui disparaît à la sélection ou à la perte de
focus ; le tableau paginé reste la liste persistante. Les deux ne doivent jamais
se disputer le rôle de « la réponse » au même instant.

**D-3 — Sélectionner une suggestion RESTREINT la recherche, ça n'ouvre jamais
une fiche.** Décidé pour Facturation et Documents, **étendu à tous les
écrans** : un composant qui ouvre ici et pré-remplit là est un composant qu'on
ne peut pas apprendre. Choisir une suggestion restreint le critère à cet élève, le
tableau se réduit à sa ligne, et on l'ouvre par l'œil comme aujourd'hui — aucun
écran ne gagne un second chemin d'ouverture.

**D-4 — Le mode identité passe de trois champs à un seul** (conséquence de D-1).
Un OU sur trois colonnes et trois champs par colonne ne peuvent pas coexister :
quatre saisies dont trois filtrent chacune sa colonne et une les balaie toutes,
personne ne saura où taper « Kabongo ». Le champ « Affiner par nom » du mode
classe (`SearchRefineNameField`, livré en `6f763e9`) **converge** vers ce même
composant et abandonne sa sémantique actuelle « colonne Nom seulement ».

**D-5 — Trois clés normalisées par ligne, testées avec un `any`.** Jamais une
clé concaténée : « nom postnom prénom » créerait des correspondances à cheval
sur deux noms, fausses et impossibles à expliquer à l'utilisateur. Le surcoût
d'un `any` sur trois clés est nul.

**D-6 — Le seuil de déclenchement est dérivé du corpus, pas fixé à 3.** Sur une
classe (corpus borné), un caractère suffit ; sur l'école, trois. Un seuil en dur
est soit trop bavard, soit trop avare selon l'écran.

**D-7 — Le bouton « Rechercher » reste, mais son rôle change.** Il garde un vrai
rôle en mode classe (la cascade doit être validée). En mode identité il devient
cérémoniel une fois R-1/R-2 en place, puisque filtrer le tableau en direct ne
coûte plus rien : il commet la **première** recherche, puis le tableau suit en
direct. Sinon les suggestions et le tableau divergent, ce qui est le reproche
qu'on peut faire à D-2.

---

## 4. Problèmes identifiés

- **P1 — Les accents interdisent la descente en SQL.** SQLite n'a pas de
  collation insensible aux accents. Toute tentative de pousser le filtre en base
  casse « José » trouvé par « jose ». C'est structurel, pas une paresse.
- **P2 — Le corpus est relu et renormalisé à chaque frappe** alors qu'il est
  constant. Le `_cache` du bloc garde le résultat **filtré**, pas le corpus.
- **P3 — Homonymie.** En RDC les patronymes sont très partagés : trois lettres
  sur un nom ne donnent pas une liste courte, et D-1 élargit encore. D'où le
  plafond de suggestions et le message « affinez » plutôt qu'une liste de 80
  lignes.
- **P4 — Sélectionner vite sur un écran d'argent.** Une suggestion tapée sans
  être lue, et c'est un encaissement sur le mauvais compte. Chaque ligne doit
  porter de quoi désambiguïser — classe, date de naissance ou matricule. D-3
  ajoute la confirmation explicite ; la ligne désambiguïsante reste obligatoire.
- **P5 — Deux sémantiques de recherche coexistent déjà dans l'app.**
  `ParentSearchDao` fait un `LIKE '%…%'` **en SQL, sans normalisation** : dans
  la popin parent, « jose » ne trouve pas « José », alors que dans les listings
  si. Défaut existant, à corriger par ce chantier (R-6), pas à dupliquer.
- **P6 — La course entre frappes est déjà résolue** par `_loadGeneration`. À
  réutiliser tel quel.

---

## 5. Ce qu'on ne fait pas, et pourquoi

**Pas de colonnes normalisées persistées avec index** (`last_name_norm`, …).
Cela demanderait un palier de schéma, un backfill de tout le parc, et un
maintien à chaque écriture — pour un gain que le cache mémoire rend inutile en
dessous de l'ordre de 10 000 lignes. À garder en réserve si le corpus explosait
; le constater se fait avec la mesure du lot R-1, pas par anticipation.

**Pas de FTS5.** Mal supporté par SQLCipher/sqflite, tokenizer insensible aux
accents non garanti, et disproportionné pour un corpus qui tient en mémoire.

---

## 6. Lots

| Lot | Contenu | Prouvé par | Jours | Dép. |
|---|---|---|---|---|
| **R-1** | Corpus chaud dans le bloc | DAO espion : 5 frappes = **1** requête | 1 – 1,5 | — |
| **R-2** | Critère OU de bout en bout + clés normalisées | Parité accents/casse + contre-épreuve « pas de correspondance à cheval » | 1,5 – 2 | R-1 |
| **R-3** | Composant DS de suggestion | Widget tests des 4 états ; debounce au `pump(Duration)` | 2 – 3 | R-2 |
| **R-4** | Mode classe + Contrôle des frais | Tests des deux formulaires | 1 | R-3 |
| **R-5** | Listings Ré-/Pré-/Première inscription | Tests des trois formulaires | 1,5 – 2 | R-4 |
| **R-6** | Popin parent + normalisation des accents | Un test : « jose » trouve « José » | 1 | R-3 |
| **R-7** | Facturation / Documents | **Revue adversariale money-grade** | 1 – 1,5 | R-5 |

**Total 9 à 12 jours.** R-1 et R-2 gardent une valeur propre si le chantier
s'arrête là : ils suppriment le balayage complet à chaque frappe et corrigent la
renormalisation redondante du terme, qui pénalisent déjà la recherche actuelle.

### R-1 — Corpus chaud

`EnrollmentLocalListBloc` mémorise la liste **non filtrée** de la dernière
requête structurelle, et l'**identité** de cette requête (année, niveau, groupe
de niveau, statut, type, scope `sync_status`). Un nouvel événement de
raffinement porte le terme seul : tant que l'identité ne bouge pas, il refiltre
**en mémoire**, sans aucune I/O. Réutilise `_loadGeneration` pour la garde
anti-course (P6).

Invalidation du corpus — **le point de vigilance du lot** : retour de synchro
(un pull change le corpus), changement d'année, écriture locale (le wizard crée
un dossier), rafraîchissement explicite. Servir des suggestions périmées après
un pull serait exactement le genre de fuite silencieuse déjà chassée sur cette
branche.

Mesurer au passage la taille réelle du corpus sur un jeu représentatif, pour
confirmer ou infirmer l'hypothèse du §1 — c'est cette mesure qui décide si le §5
(« pas d'index ») reste vrai.

### R-2 — Critère OU de bout en bout, clés précalculées

Le terme unique doit voyager du formulaire jusqu'au projector.
`AcademicInfoSearchCommand` et `StandardSearchCommand` portent aujourd'hui
`firstName` / `lastName` / `surname` ; il leur faut un critère « n'importe
lequel des noms ». Ripple : contrats de commande, événements du bloc local,
projector, `SearchLocalEnrollmentsUseCase`. Chaîne partagée par Facturation,
Documents et les trois formulaires d'inscription — c'est le lot le plus
transverse.

Au chargement du corpus, calculer **une fois** les trois clés normalisées par
ligne (D-5). Le terme est normalisé **une fois par frappe**, pas une fois par
ligne comme aujourd'hui.

### R-3 — Composant DS de suggestion

Champ unique + panneau de suggestions ancré. Quatre états : saisie trop courte,
aucun résultat, liste, trop de résultats (plafond atteint → « affinez »). Seuil
dérivé du corpus (D-6). Chaque ligne porte la désambiguïsation : nom complet,
classe, né(e) le ou matricule (P4). Debounce court (~150 ms) — il ne limite plus
des I/O mais des reconstructions. Accessibilité : rôle combobox, annonce du
nombre de résultats. Libellés FR + EN.

### R-4 → R-7 — Branchement par risque croissant

R-4 est le moins risqué : corpus borné, la sélection ne navigue pas. R-5 fait
passer le mode identité au champ unique (D-4) — l'armement suit le seuil au lieu
des trois noms, et les trois libellés `.arb` correspondants disparaissent. R-6
unifie la popin parent et corrige P5 au passage. R-7 vient en dernier, sur les
écrans d'argent, sous revue adversariale.

---

## 7. Invariants à ne pas casser

1. **Le corpus chaud est invalidé par la synchro.** Un pull qui ne l'invalide
   pas fait servir des suggestions périmées, silencieusement.
2. **Seuls les critères du mode actif partent** (invariant de la bascule, cf.
   `AGENTS.md`). Le champ unique du mode identité ne voyage pas en mode classe,
   et réciproquement.
3. **Une suggestion n'ouvre jamais une fiche** (D-3). Sur les écrans d'argent,
   elle ne peut pas non plus être servie sans sa ligne désambiguïsante (P4).
4. **La recherche reste insensible aux accents et à la casse, partout.** Y
   compris dans la popin parent après R-6 — c'est le point du lot.
5. **`_loadGeneration` reste la seule garde anti-course.** Ne pas introduire un
   second mécanisme à côté.

---

## 8. Pièges consignés

- **Test du debounce :** un `Completer` né hors `FakeAsync` ne se dénoue jamais
  sous `tester.pump()`. Le debounce se teste au `pump(Duration)`.
- **Test sous chargement :** `pumpAndSettle` ne rend jamais la main quand un
  indicateur tourne. Utiliser `pump()` (constaté sur les tests de la bascule).
- **Échappement `LIKE` :** si un jour un chemin SQL revient, reprendre
  l'échappement de `%` / `_` / `\` de `ParentSearchDao` — une saisie utilisateur
  n'est pas un motif.
- **Correspondance à cheval :** cf. D-5, à couvrir par une contre-épreuve
  explicite, pas seulement par un test positif.

---

## 9. Points restés ouverts

- La **taille réelle du corpus** en production : hypothèse non mesurée (§1),
  tranchée par R-1. C'est elle qui valide le §5.
- Le **plafond de suggestions** et les seuils exacts (1 / 3) : à caler sur des
  données réelles au lot R-3, pas à décréter ici.
- Le **sort du bouton « Rechercher » en mode identité** après R-5 : D-7 le garde
  pour la première recherche ; à réévaluer une fois le direct éprouvé.
