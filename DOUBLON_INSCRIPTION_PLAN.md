# DOUBLON_INSCRIPTION_PLAN.md — cet enfant est-il déjà chez nous ?

> **Statut :** proposé le 2026-09-04, arbitrages D1–D4 tranchés par le user.
> **LOT CLOS — DUP-0 à DUP-5 livrés** (119 tests sur les lots, non commités).
> **La sonde est branchée de bout en bout.**
>
> | Lot | État |
> |---|---|
> | DUP-0 · clé d'identité + rapprochement (pur, testable seul) | ✅ livré |
> | DUP-1 · lectures locales + usecase de confrontation + DI | ✅ livré |
> | DUP-2 · la popin (message seul) + l10n FR/EN | ✅ livré |
> | DUP-3 · hook de continuation du step 1 + garde anti-répétition | ✅ livré |
> | DUP-4 · câblage réel, paysage, anglais | ✅ livré |
> | DUP-5 · revue adversariale | ✅ livré |
>
> **Docs de contexte :** `CLAUDE.md` §règles non-négociables · `AGENTS.md`
> §« États partagés » · `RECHERCHE_INTERACTIVE_PLAN.md` (pourquoi le SQL ne
> filtre jamais sur un nom) · `TELEPHONE_TUTEUR_PLAN.md` (le précédent de
> l'unicité applicative côté tuteur).

---

## 1. La question posée

> « Le guichet ouvre une Première inscription et saisit une identité. Cet
> enfant est-il **déjà** dans nos bases ? »

Ce n'est pas une recherche : personne ne cherche. C'est une **confrontation**,
déclenchée par la saisie elle-même, dont le seul livrable est un avertissement.
Elle n'ouvre aucun dossier, n'écrit rien, et ne barre la route à personne.

---

## 2. Le fait déterminant

**Tout le corpus est déjà sur la tablette, et la carte de résultat existe déjà.**

| Besoin | Existant |
|---|---|
| Élèves de l'année | `students` ⋈ `enrollments` — peuplés par le pull hydratant `EnrollmentPullHandler.enrollmentSnapshots` |
| Élèves de l'an dernier | `ref_previous_year_students` — nom, post-nom, prénom, **date de naissance**, matricule |
| Comparaison casse/accents | `SearchNormalizationHelper.normalize` (`lib/core/helpers/`) |
| Patron de popin « ça existe déjà » | `showGuardianPhoneConflictDialog` (étape Tuteurs) |

Aucune couche data neuve. Aucun bump de schéma. Aucune demande au back : la
sonde est **100 % locale**, comme le tableau de bord du Contrôle des frais.

---

## 3. Ce que cette sonde n'est pas

| | Recherche du listing | Sonde de doublon |
|---|---|---|
| Qui la déclenche | l'utilisateur | la **saisie**, une fois |
| Fréquence | à chaque frappe | une fois par dossier |
| Sortie | une liste à parcourir | un **avertissement**, ou rien |
| Sans résultat | « aucun résultat » | **silence** |
| Effet sur le parcours | aucun | aucun |

C'est cette différence de fréquence qui autorise un balayage Dart complet là où
la recherche interactive ne peut pas se le permettre.

---

## 4. Décisions tranchées

### D1 — Première inscription seule ✅

Le seul parcours où l'identité est **tapée librement**. En Réinscription et en
Pré-inscription, l'élève vient d'un vivier : son `student_id` est canonique,
`ref_previous_year_students` le dit explicitement — « aucun doublon d'élève ».

Concrètement, `appliesTo` ne lit pas une liste de politiques : il lit
`draftEnrollmentType == 'NEW_ENROLLMENT' && isStepEditable(personalInfo)`.

> **Correction du 2026-09-04 (DUP-5).** Cette phrase annonçait **deux**
> politiques. Le critère en couvre **trois** en vie :
> `NewFirstRegistrationDetailPolicy`, `LocalDraftResumeDetailPolicy(NEW)`, et
> — non prévue — `CompletedReeditionDetailPolicy` dont l'`enrollmentType` vaut
> NEW ou est absent (défaut NEW), car la réédition d'un dossier soldé rouvre
> l'étape Identité. C'est **bénin et plutôt souhaitable** : corriger une
> identité vers celle d'un autre élève mérite le même avertissement, et
> l'exclusion de soi tient. `FirstRegistrationDetailPolicy`, elle, n'atteint
> jamais le stepper (court-circuitée en `LocalConsultationDetailPolicy`). Les
> trois politiques sont désormais **épinglées par des tests** : le périmètre
> est une décision lisible, plus un effet de bord du défaut.

### D2 — corpus : dossiers de l'année **et** cohorte N-1 ✅

Le hit N-1 est le plus précieux des deux : il ne dit pas « attention, doublon »,
il dit **« cet enfant relève de la Réinscription, pas de la Première
inscription »**. C'est le doublon que le terrain fabrique vraiment — un ancien
élève que l'agent n'a pas trouvé dans le vivier et qu'il re-saisit à neuf.

### D3 — V1 : le message seul, aucune carte ✅

Pas de `EnrollmentResultCard`, pas de clic, pas de navigation. La popin **nomme
en texte** les identités trouvées et s'arrête là.

> **Hypothèse assumée** : un avertissement qui ne nomme personne n'est pas
> actionnable. La popin cite donc au plus **3 identités** (`NOM Post-nom Prénom
> · né(e) le JJ/MM/AAAA`), suivies de « et N autre(s) » au-delà, avec la
> provenance (dossier de l'année / cohorte de l'an dernier). Aucune autre
> donnée : ni tuteur, ni téléphone, ni adresse.

**Pourquoi pas la carte cliquable en V1 — à relire avant toute V2 :** les routes
Inscription vivent sous **une seule `ShellRoute`** (`app_router.dart:303`) et
`EnrollmentFeatureScope` fournit **un unique** `EnrollmentOfflineBloc` à toutes
ses pages. Or `EnrollmentDetailPage` y lit son dossier.

- `push` d'une 2ᵉ `EnrollmentDetailPage` → son chargement émet un état que **le
  wizard du dessous consomme aussi** : il se ré-hydrate sur l'autre élève.
- `context.go` → le wizard est détruit. Le brouillon survit en base et se
  reprend depuis le listing, mais l'utilisateur perd sa place — ce qui
  contredit « ignorer et continuer ».

La seule sortie propre serait un **aperçu lecture seule dans la popin même**,
alimenté par un bloc dédié au dialogue (modèle `ParentSearchBloc`), sur
`EnrollmentReadDao.getDetail`. C'est le périmètre d'une V2, pas de celle-ci.

### D4 — rapprochement tolérant, trois niveaux ✅

| Niveau | Règle | Ce qu'il attrape |
|---|---|---|
| **Certain** | les 3 noms identiques, position par position, **et** même date de naissance | la re-saisie pure |
| **Probable** | les 3 noms identiques **à l'ordre près**, même date de naissance | l'**inversion nom ↔ post-nom**, l'erreur de guichet classique |
| **Possible** | les noms correspondent, **date de naissance différente** | la date mal saisie, l'année approximative |

Les trois niveaux sont **exclusifs** : un élève ne remonte qu'une fois, au
niveau le plus fort qu'il atteint.

### D5 — la sonde ne bloque jamais

Le niveau « possible » remonte les **vrais homonymes** — trois noms qui
coïncident sur deux enfants différents, que seule la date de naissance sépare.
C'est acceptable **parce que** la popin est informative. Elle le cesserait le
jour où elle barrerait la route.

> **Correction du 2026-09-04 (DUP-0).** Une version antérieure de ce plan
> annonçait ici que les **jumeaux** remontaient. C'est faux : la règle
> d'inclusion de §6.2 exige que *tous* les noms non vides du candidat se
> retrouvent dans la saisie, et deux jumeaux ne partagent que deux noms sur
> trois — leurs prénoms diffèrent. Ils ne remontent donc **pas**, ce qui vaut
> mieux : deux jumeaux sont deux enfants, et les signaler à chaque inscription
> aurait été du bruit pur. Un test épingle cette absence.

### D6 — elle ne parle que quand elle trouve

Jamais de « aucun doublon détecté ». Le corpus est borné (§7) : une absence de
résultat n'est pas une preuve d'absence de doublon, et l'afficher comme telle
donnerait une assurance que la donnée ne porte pas.

### D7 — déclenchement au « Continuer » du step 1

Une seule fois, sur la transition étape 1 → étape 2 — pas au « Enregistrer »,
qui se rejoue à chaque correction. Mémorisée par **signature d'identité** :
revenir en arrière puis repartir ne rejoue pas une popin déjà écartée ; changer
un nom, si.

---

## 5. Contrat de lecture

Deux requêtes, projetées au strict nécessaire, exécutées **une fois**.

### 5.1 Les dossiers de l'année courante

```sql
SELECT e.id AS enrollment_id, s.id AS student_id,
       s.first_name, s.last_name, s.surname, s.date_of_birth,
       e.school_level_id, e.school_level_group_id, e.status
FROM enrollments e
JOIN students s ON s.id = e.student_id
WHERE e.academic_year_id = ?
  AND s.id <> ?          -- exclusion de soi (studentId du brouillon)
  AND e.id <> ?          -- exclusion de soi (enrollmentId du brouillon)
```

`academic_year_id` porte **aussi le scope école** : une année appartient à une
école (`ref_academic_years.school_id`). C'est la seule prise disponible —
`students` et `enrollments` n'ont pas de `school_id` (§7).

Aucun filtre `sync_status` : un brouillon `DRAFT` saisi ce matin sur la même
tablette est exactement le doublon qu'on cherche.

**Aucun filtre `status` non plus** (décidé en DUP-1) : un dossier `CANCELLED`
reste un fait — l'enfant est dans la base. Le taire donnerait un silence que la
donnée ne porte pas, et le front n'écrit jamais ce statut lui-même : « annuler
puis re-saisir sur la tablette » n'est pas un parcours qui existe ici.

**Aucun préfiltre SQL sur la date de naissance**, bien que la colonne soit
indexée : le niveau « possible » vit précisément sur des dates *différentes*.
Une seule projection balayée en Dart, plutôt que deux requêtes à réconcilier.

### 5.2 La cohorte de l'an dernier

```sql
SELECT student_id, matriculation_number,
       first_name, last_name, surname, date_of_birth,
       previous_school_level_id
FROM ref_previous_year_students
WHERE student_id <> ?
```

### 5.3 L'exclusion de soi n'est pas optionnelle

`StartDraftUseCase` ne fige que des ids — aucune écriture. Mais **dès
l'enregistrement du step 1**, le brouillon possède sa propre ligne `students`
*et* sa ligne `enrollments`. Sans les deux exclusions, la sonde se trouve
elle-même : 100 % de faux positifs, à tous les coups.

---

## 6. La règle de rapprochement, en Dart et seulement en Dart

**Le SQL ne peut pas porter le filtre de nom.** `LOWER()` SQLite ne plie pas les
accents. Un `WHERE LOWER(last_name) = LOWER(?)` manquerait « Mukéndi » face à
« Mukendi » — et ici, un faux négatif n'est pas une gêne : c'est **le doublon
manqué**, donc l'échec de la fonctionnalité.

### 6.1 La clé d'identité

```
cleIdentite(v) = SearchNormalizationHelper.normalize(v)   // casse + accents
                 puis  -  ' ’ et espaces multiples  →  un seul espace
                 puis  trim
```

`SearchNormalizationHelper` couvre déjà casse et accents. Le repli des
séparateurs (« Kabeya-Mukendi » ≡ « Kabeya Mukendi », « N'Guessan » ≡
« N Guessan ») est l'ajout de ce lot.

### 6.2 Les trois niveaux, exactement

Soit `saisie = (nom, postnom, prenom)` et `candidat` idem, tous en clé.

- `nomsExacts` : égalité **position par position** des trois clés.
- `nomsPermutes` : le multi-ensemble des clés **non vides** du candidat est
  **contenu** dans celui de la saisie (multiplicités comprises), et le candidat
  porte au moins **deux** clés non vides.
  → tolère un candidat historique sans post-nom, sans pour autant faire matcher
  un candidat vide sur tout le monde.
- `memeDdn` : égalité des dates **date-only** (`DateOnlyJsonHelper`), jamais des
  chaînes brutes.

| | `memeDdn` | `!memeDdn` |
|---|---|---|
| `nomsExacts` | **certain** | possible |
| `nomsPermutes` (et pas exacts) | **probable** | possible |
| ni l'un ni l'autre | — | — |

Fonction **pure**, sans `BuildContext`, sans DAO, sans `l10n` : elle se teste
seule, table de vérité à l'appui.

---

## 7. Limites assumées — à écrire dans le code, pas seulement ici

**Le corpus s'arrête à l'année active.** Le pull hydratant appelle
`pullEnrollmentSnapshots(..., academicYearId: null)` → défaut serveur = année
active. Un élève parti il y a deux ans **n'est pas détectable**. Avec la cohorte
N-1, la fenêtre couvre deux exercices, pas davantage.

**Une tablette non hydratée ne voit rien.** Tant que le curseur
`enrollment_snapshots` est vide, la sonde s'exécute sur un corpus vide et se
tait. C'est précisément ce qui interdit d'annoncer « aucun doublon » (D6).

**Multi-école.** `students` et `enrollments` n'ont pas de `school_id` : le scope
passe par `academic_year_id`. `ref_previous_year_students`, lui, n'a **aucun**
axe école — sur une tablette partagée entre deux écoles, un candidat N-1 de
l'autre école remonterait. C'est la dette déjà ouverte des curseurs non scopés,
pas une régression de ce lot ; l'aggraver serait d'y ajouter une écriture, ce
que la sonde ne fait pas.

**Un nom composé éclaté sur deux champs échappe à la clé.** « Kabeya-Mukendi »
saisi comme un seul nom donne la clé `kabeya mukendi` — une chaîne. Le même
enfant saisi ailleurs en nom `Kabeya` + post-nom `Mukendi` donne deux clés
distinctes. L'inclusion travaille sur des noms entiers, pas sur des mots : ces
deux écritures ne se rapprochent pas. Découper les clés en mots attraperait ce
cas, au prix d'un « possible » sur tout porteur d'un des mots — le compromis n'a
pas été pris ici. (Trouvé en revue DUP-5.)

**Les homonymes remontent** au niveau « possible » — mêmes trois noms, dates de
naissance différentes. C'est le prix de D4, et la raison de D5. Les **jumeaux**,
eux, ne remontent pas (cf. D5).

**Si la Pré-inscription entrait un jour dans le périmètre :**
`ref_pre_enrollments.date_of_birth` est **nullable** (`students.date_of_birth`
ne l'est pas). Comparer sur `null` ferait matcher tout le monde — et `null` en
`whereArgs` **lève** chez sqflite.

---

## 8. Architecture

```
offline/domain/
  duplicate/enrollment_identity_key.dart        ← clé (pur)
  duplicate/enrollment_duplicate_matcher.dart   ← les 3 niveaux (pur)
  entities/enrollment_duplicate_candidate.dart  ← identité + provenance + niveau
  usecases/probe_enrollment_duplicates_use_case.dart

offline/data/local/dao/
  enrollment_read_dao.dart                      ← +2 lectures (§5.1, §5.2)

offline/data/repositories/
  enrollment_offline_repository_impl.dart       ← Either<Failure, List<…>>

presentation/
  widgets/personal_info/enrollment_duplicate_dialog.dart
  step_handlers/enrollment_step_handler.dart    ← hook de continuation
  step_handlers/personal_info_step_handler.dart ← override du hook
  widgets/enrollment_stepper.dart               ← _onContinuePressed → async
```

Le usecase renvoie `Either<Failure, List<EnrollmentDuplicateCandidate>>` ; **le
`Left` se traite comme une liste vide** côté appelant. Une sonde d'aide qui
tombe ne doit pas arrêter un guichet — mais elle ne doit pas non plus prétendre
avoir cherché : elle se tait, sans toast d'erreur (règle : zéro log d'identité).

---

## 9. Les lots

### DUP-0 — la clé et le rapprochement ✅

`offline/domain/duplicate/` : `enrollment_identity_key.dart` (clé),
`enrollment_identity.dart` (les 3 noms + la date, rien d'autre),
`enrollment_duplicate_level.dart` (l'enum, ordonné du plus sûr au moins sûr),
`enrollment_duplicate_matcher.dart` (la table de vérité §6.2). Tout est pur :
ni base, ni `BuildContext`, ni `l10n`. La saisie est normalisée **une fois**, à
la construction du matcher, pas à chaque ligne du corpus.

**29 tests verts** : accents, casse, tiret, les deux apostrophes, espaces
multiples, insécable · inversion nom ↔ post-nom, prénom porté comme nom ·
post-nom absent d'un dossier ancien · date avec partie horaire, date illisible,
deux dates illisibles · jumeaux et homonymes partiels **écartés** ·
multiplicités (un nom répété exige un nom répété) · saisie dégradée.

**Contre-épreuve par mutation du câblage** — cinq mutations, cinq échecs :
retirer le repli des séparateurs (−4), dégrader le multi-ensemble en ensemble
(`contains` au lieu de `remove`, −1), faire valoir égalité à deux dates
illisibles (−1), retirer la garde des deux noms côté candidat (−1), retirer la
garde `isUsable` (−1).

### DUP-1 — les lectures et le usecase ✅

`EnrollmentDuplicateDao` (DAO **dédié** : la sonde n'a pas la discipline de
lecture des listes) porte les deux requêtes §5. Le **repository assemble** —
résout l'année, saute la source « dossiers » si elle ne se résout pas, concatène
les deux sources. Le **usecase rapproche** — matcher construit une fois, tri
`certain → probable → possible` puis alphabétique **sur les clés**,
déduplication par `studentId`. DI : DAO → repo → usecase dans
`enrollment_finance_offline_di.dart`.

Trois entités : `KnownStudentIdentity` (le corpus brut, **sans niveau** : dire à
quel point il ressemble à la saisie n'est pas son travail),
`EnrollmentDuplicateSource`, `EnrollmentDuplicateCandidate`.

**31 tests verts** : DAO (13) — scope année, exclusion de soi par *chacun* des
deux ids, `DRAFT` et `CANCELLED` inclus, post-nom nul, ordre stable, cohorte
vide ; usecase (14) — classement, déduplication, gardes, `Left` préservé ;
assemblage du corpus (4) — année fournie / résolue / non résolue, lecture qui
lève.

**Contre-épreuve par mutation — deux trous trouvés dans les tests, comblés :**

- La déduplication passait avec `if (true)` : mes trois cas étaient tous
  ordonnés de sorte que « le dernier lu gagne » donnait la bonne réponse. Ajout
  des **cas miroir** (le gagnant en tête) ; `if (true)` et `if (kept == null)`
  échouent désormais tous les deux.
- Le tri « ignore les accents » passait sans plier quoi que ce soit :
  l'accent était sur le **post-nom**, qui n'entre pas dans la clé de tri. Refait
  avec une saisie dont le **nom** est accentué (« Élenga » se range après
  « Kabeya » en octets bruts, avant une fois plié).

Les sept autres mutations étaient attrapées d'emblée : exclusion par
`studentId`, scope année, exclusion de la cohorte, arbitrage de source, tri par
niveau, année non résolue interrogée sans scope, garde `isUsable`.

### DUP-2 — la popin ✅

`EnrollmentDuplicateDialog` sur `EteeloDialogBody` + `EteeloDialogDarkHeader`
(règle des modales), et `EnrollmentDuplicateLines` — la mise en mots, **séparée
du widget** pour se tester sans pomper une image : ce sont ces phrases-là que le
guichet lit pour trancher, pas la boîte qui les entoure.

`Future<bool> show(...)` : `true` = passer outre, `false` = retourner corriger.
Croix **et** barrière valent « corriger ». Liste vide → `true` **sans ouvrir de
boîte** : un avertissement sans avertissement n'a rien à dire (même règle que
D6).

**Le bouton plein est « Corriger la saisie »**, pas « Continuer quand même ». Ni
l'un ni l'autre n'est destructeur ; le geste mis en avant est simplement celui
qu'on vient de recommander. Passer outre reste à un seul tap — la sonde ne
bloque jamais (D5) — mais l'écran ne le suggère pas.

**22 tests verts** : la mise en mots (14) — ordre nom/post-nom/prénom, post-nom
absent sans double espace, date ISO avec **et** sans partie horaire, date
illisible, `né(e) le` qui tombe entièrement faute de date, provenances, plafond
de 3 ; la popin (8) — les deux boutons, la croix, la barrière, le « et N
autres », la liste vide.

**Contre-épreuve par mutation — un trou trouvé, comblé :** `?? true` au lieu de
`?? false` survivait, parce que tous mes cas fermaient la popin par un bouton ou
par la croix, qui rendent une valeur explicite. **La barrière est le seul chemin
qui ne rend rien** et donc le seul qui exerce ce `??`. Test ajouté. Les sept
autres mutations tombaient d'emblée (boutons confondus, croix qui laisse passer,
liste vide qui ouvre quand même, plafond de 3 levé, date découpée sur les
tirets, post-nom vide non escamoté, provenance N-1 confondue avec l'année).

### DUP-3 — le branchement ✅

`EnrollmentStepHandler.confirmBeforeContinue(...) → Future<bool>`, `true` par
défaut ; `PersonalInfoStepHandler` l'override et délègue à
`EnrollmentDuplicateGuard`. `_onContinuePressed` passe en `async`, avec `mounted`
guard après l'`await` (règle #8) et un **verrou de ré-entrance** : la question
est asynchrone, donc le bouton reste tapable entre la tape et la popin — sans
verrou, deux tapes lanceraient deux confrontations et empileraient deux popins.

**La garde vit dans `EnrollmentStepperScope`**, créée en `initState` : sa
mémoire est celle d'une session de saisie. Ce que le guichet vient d'assumer ne
lui est pas redemandé au prochain aller-retour d'étape, et lui est redemandé au
dossier suivant.

**On retient l'acquiescement, pas l'exposition.** « Corriger la saisie » n'entre
pas dans la mémoire : qui repart corriger puis ressort sans avoir rien changé
retrouve le même avertissement — ce qui est juste, rien n'a changé — et en sort
d'un tap sur « Continuer quand même », qui vaut décision. La signature est
**normalisée** : corriger « Mukendi » en « MUKÉNDI » ne relance pas ce qu'on
vient d'écarter.

`duplicateGuard` est **requis** dans `EnrollmentStepHandlerDependencies`. Le
rendre optionnel ferait d'un oubli de câblage une fonctionnalité muette que
personne ne remarquerait — c'est précisément ce qu'une garde ne doit pas pouvoir
devenir.

**23 tests verts** : la garde (19) — périmètre par politique (NEW / RE / PRE /
consultation / reprise NEW / reprise RE), lecture non payée hors périmètre,
`Left` qui laisse passer, ids et année transmis, les deux réponses, mémoire
(acquiescement, refus, casse et accents, nom changé, date changée), **câblage du
handler** ; le stepper (4) — défaut du contrat, réponse favorable, réponse
défavorable qui retient, verrou de ré-entrance.

**Contre-épreuve par mutation — un trou trouvé, et c'était le maillon
principal :** supprimer l'appel à la sonde dans `PersonalInfoStepHandler`
laissait **tout vert**. La sonde existait, marchait, et n'était jamais posée —
exactement le défaut « garde jamais branchée ». Deux tests ajoutés qui traversent
le handler jusqu'à la popin. Les huit autres mutations tombaient d'emblée
(stepper qui ignore le dernier mot, verrou de ré-entrance retiré, périmètre
ouvert à tous les parcours, périmètre ouvert à la consultation, « Corriger »
promu en acquiescement, mémoire non normalisée, mémoire sans la date, « rien
trouvé » qui bloquerait).

### DUP-4 — câblage réel, paysage, anglais ✅

**Recentré.** Le lot prévoyait DAO / usecase / popin / hook — tout cela a été
livré au fil de DUP-1 à DUP-3, et les contre-épreuves ont comblé ce qui
manquait. Le dérouler tel quel aurait réécrit des tests existants. Restaient
trois trous réels, aucun couvert :

**1. La chaîne complète, sur une vraie base** (`test/core/di/`,
19 tests avec la popin). Chaque couche était prouvée séparément, sur des
instances construites à la main — nécessaire et insuffisant :
`EnrollmentStepperScope` résout la sonde par
`getIt<ProbeEnrollmentDuplicatesUseCase>()`, et un enregistrement oublié ne fait
broncher ni l'analyseur ni aucun test de comportement. Il lève à l'ouverture du
wizard, au guichet. Le fichier joue donc le **scénario du terrain** de bout en
bout sur sqflite : un ancien élève du vivier N-1 re-saisi à neuf, nom et
post-nom inversés, à côté d'un homonyme déjà inscrit et d'un tiers sans rapport
— DI réelle, DAO réel, repository réel, usecase réel.

**2. Le paysage clavier ouvert.** `Dialog` ajoute les `viewInsets` à son
`insetPadding` : téléphone couché, clavier levé depuis l'étape restée dessous,
il ne reste qu'une centaine de dp — moins que l'en-tête et le pied réunis.

**3. L'anglais.** Une clé absente d'`app_en.arb` retombe silencieusement sur le
français : l'écran reste lisible, et personne ne voit qu'il n'est pas traduit.

**Contre-épreuve — un trou trouvé, comblé :** le premier test de paysage était
posé à 640×360 **sans clavier**, où il reste 312 dp : la disposition ancrée
tient largement, et `minPinnedHeight: 0` passait donc sans broncher. Le test ne
prouvait rien. Refait avec `viewInsets` — la seule condition où le seuil
travaille. Les trois autres mutations tombaient d'emblée (enregistrement DI de
la sonde retiré, DAO retiré du conteneur, cohorte N-1 plus lue).

### DUP-5 — revue adversariale ✅

Cibles annoncées : l'exclusion de soi, le `Left` silencieux, la garde
anti-répétition, l'absence d'affirmation d'absence, zéro écriture.

**13 mutations valides, 13 attrapées.** Exclusion de soi par `enrollmentId`,
par `studentId`, et dans la cohorte N-1 · « Corriger » promu en acquiescement ·
signature amputée de la date · signature non normalisée · un `Left` qui
bloquerait le guichet · verrou de ré-entrance retiré · lecture payée sur saisie
inexploitable · un seul nom suffisant à rapprocher · la barrière qui laisserait
passer · une popin ouverte sans rien à dire (D6) · une écriture glissée dans la
lecture. La suite tient réellement ses invariants — aucun test ne posait sa
propre hypothèse.

**Trois trous trouvés, tous comblés :**

1. **L'invariant n°3 (« zéro écriture ») n'était tenu par aucun test.** Vrai par
   construction, donc invisible, donc cassable sans bruit — et une sonde d'aide
   qui écrit pousse une inscription vers le serveur sans que personne l'ait
   demandé. Test ajouté sur la base réelle : **empreinte du contenu entier**
   (pas un compte de lignes, qui laisserait passer un `UPDATE`) avant/après une
   sonde qui trouve, plus l'outbox nommée à part. Contre-épreuve : un `UPDATE`
   glissé dans le DAO la fait rougir.

2. **Le périmètre réel dépassait le plan** d'une politique (cf. D1). Trois tests
   l'épinglent désormais, dont le cas RE en réédition qui doit rester muet.

3. **Deux commentaires mentaient sur le code.** `displayDate` annonçait « chaîne
   vide si elle ne se lit pas » alors qu'elle rend la date **brute** — et un
   test épinglait déjà ce comportement voulu. Le prochain lecteur aurait
   « corrigé » le code vers le commentaire et cassé le seul champ qui sépare
   deux homonymes. Les deux docs disent maintenant ce que le code fait, et
   pourquoi il diffère de `dateOnlyOrNull` (comparer deux dates illisibles n'a
   pas de sens ; les montrer, si).

**Deux hunts revenus négatifs, et c'est un résultat :**

- **Une garde posée sur une porte quand il y en a deux.** `confirmBeforeContinue`
  n'est câblée que sur `onContinue`. Vérifié : les trois autres chemins de
  changement d'étape vont tous **en arrière** (`onPrevious`, retour depuis le
  résumé) ou sont **refusés** (`_onBreadcrumbStepTap` en avant → simple
  bandeau). La sonde est sur la seule porte qui avance.
- **La mémoire d'acquiescement fuyant d'un dossier au suivant.** Tous les
  nouveaux dossiers partagent la même route littérale
  `/enrollments/detail/**new**` — donc la même clé de page, et le `State` du
  wizard aurait pu être réemployé, avec sa mémoire. On y arrive par
  `context.go`, qui **remplace la pile** : le `State` est détruit en sortant,
  `initState` rejoue, la garde repart vierge. Rien à corriger — mais c'est le
  genre de dépendance qu'un futur passage en `push` casserait en silence.

---

## 10. Invariants à ne jamais casser

1. **La sonde ne bloque jamais** une inscription.
2. **Elle ne parle que quand elle trouve** — jamais « aucun doublon ».
3. **Zéro écriture** : aucune table touchée, aucun outbox alimenté.
4. **Exclusion de soi** sur `studentId` *et* `enrollmentId`.
5. **Aucune donnée d'identité journalisée**, à aucun niveau de log.
6. Un échec de lecture est **silencieux** : ni toast, ni blocage, ni affirmation.
