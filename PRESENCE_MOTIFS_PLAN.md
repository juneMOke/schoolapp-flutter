# PRESENCE_MOTIFS_PLAN.md — le verdict d'absence et la saisie des motifs

> **Statut :** plan validé (2026-08-22). **P-1a livré** (back, `7b47b9c` sur
> `fix/absence-unjustified-verdict` du dépôt `eteelo-backend`) et **P-1b livré**
> (front) ; P-1c→P-2b ouverts. Toutes les décisions du §3 sont verrouillées ; un seul sous-point
> reste ouvert (§9).
>
> **Origine :** les deux entrées `P-1` et `P-2` de `REVUE_CODE_BACKLOG.md`,
> §"Ouverts", signalées à l'usage sur la **Présence de l'élève**.
>
> **Besoin, dans les mots du demandeur :** « Aligner la liste des raisons
> d'absences pour le backend et le front end » et « Penser à l'implémentation du
> mode focus comme pour les notes ».
>
> **Docs de contexte :** `REVUE_CODE_BACKLOG.md` §P-1/P-2 (l'analyse et ses
> références ligne à ligne), `AGENTS.md` §"États partagés",
> `openApi.yaml` §`AbsenceReason` (le contrat).

---

## 1. Le fait déterminant

**Le catalogue est déjà aligné. C'est la règle qu'il alimente qui ne l'est pas.**

Les onze motifs sont rigoureusement identiques aux trois endroits qui les
portent — `AbsenceReason.java`, le schéma `AbsenceReason` d'`openApi.yaml:8038`,
`absence_reason.dart` : mêmes noms, même ordre. La demande « aligner la liste »
n'a donc pas d'objet au sens littéral, et c'est précisément ce qui rend le
défaut difficile à voir.

Ce qui diverge, c'est le prédicat qui décide **justifiée / injustifiée** :

| | injustifiée quand… |
|---|---|
| **Back** — `AttendanceStatsService.java:217`, javadoc `:47` | `motif == null \|\| motif == UNKNOWN` |
| **Front** — `absence_reason.dart:57` | `motif == UNJUSTIFIED \|\| motif == UNKNOWN` |

Le back range donc `UNJUSTIFIED` **du côté justifié**. Un enseignant qui choisit
explicitement « Absence non justifiée » la voit comptée injustifiée sur l'écran
d'appel et dans la synthèse élève, et **justifiée** dans les KPIs du tableau de
bord Présence. Chemin nominal, pas transition rare.

**Pourquoi ça a survécu :** `grep -rn "UNJUSTIFIED" src/test/java` du backend
renvoie **zéro résultat**. Le prédicat n'a jamais été éprouvé sur cette valeur —
les 12 occurrences de `AbsenceReason.UNKNOWN` dans les tests couvrent le seul
cas d'origine. Le prédicat n'a jamais été repris quand `UNJUSTIFIED` est entré
au catalogue.

---

## 2. Pertinence

Le verdict n'est pas décoratif : c'est lui qui décide ce qu'un directeur regarde
pour convoquer une famille. Deux écrans du même produit qui répondent le
contraire sur la même absence, c'est un chiffre qu'on ne peut pas défendre — et
le seul contrôle à l'œil possible (compter les lignes rouges de l'appel) donne
raison au front, pas au tableau de bord.

Le mode Focus, lui, n'est pas un besoin de vitesse de saisie : c'est un besoin
de **complétude**. L'enregistrement est déjà bloqué tant qu'un motif manque
(`missingReasonsCount > 0`) ; le Focus est le chemin qui fait tomber ce blocage
sans faire défiler quarante lignes.

---

## 3. Décisions

**D-1 — `UNJUSTIFIED` compte comme injustifiée. C'est le back qui est corrigé,
pas le front.** Il est intenable qu'une valeur nommée `UNJUSTIFIED` soit rangée
du côté justifié ; le front dit déjà la bonne chose et le nom de la valeur est
sa propre spécification.

**D-2 — Motif absent (`null`) ⇒ injustifiée.** Le back le fait déjà, le front
s'aligne. ⚠ Cela ne concerne **que les données déjà écrites** : l'écran d'appel
continue d'interdire l'enregistrement d'une absence sans motif, donc « sans
motif » y reste un troisième compteur (« en attente »), jamais une catégorie de
verdict. Les deux ne sont pas contradictoires — l'un décrit la saisie en cours,
l'autre l'historique.

**D-3 — La règle vit une seule fois côté front, dans le domaine, avec une
signature qui prend `AbsenceReason?`.** Elle est aujourd'hui recopiée sur quatre
sites avec trois sémantiques ; une fonction qui n'accepte pas `null` force
chaque appelant à réinventer le cas. Même piège que le comparateur d'ensembles
de permissions recopié deux fois (`REVUE_CODE_BACKLOG.md` §B-1+B-2+B-3).

**D-4 — Catalogue de transport ≠ liste de saisie.** Les onze valeurs restent au
contrat (un parc de tablettes les lit et les écrit déjà) ; l'UI cesse de rendre
`AbsenceReason.values` brut et consomme une liste `selectableAtEntry` dérivée.

**D-5 — La liste de saisie compte quatre entrées : `SICKNESS`,
`FAMILY_EMERGENCY`, `PERSONAL`, `OTHER`.** *(arbitré le 2026-08-22)*
Le catalogue mélange trois natures : des motifs, des états du cycle de vie
(`UNKNOWN`, `UNJUSTIFIED`), un fourre-tout (`OTHER`), et cinq valeurs de congé
**salarié** (`VACATION`, `UNDER_GRADUATE_LEAVE`, `MARRIAGE_LEAVE`,
`PARENTAL_LEAVE`, `WORK_LEAVE`) qui n'ont pas de sens pour un élève. Seuls les
motifs restent. `UNKNOWN` n'est jamais choisi — le swagger le dit transitoire.

**Amendement du 2026-08-22 — la liste compte CINQ entrées : `UNKNOWN` reste
proposé, et c'est LUI qui porte « pas justifiée ».**

La version précédente de cette décision retirait `UNJUSTIFIED` sans rien mettre
à sa place : l'appel interdisant déjà d'enregistrer sans motif, les valeurs du
côté injustifié devenaient toutes inatteignables et le taux tendait vers
**zéro** — un KPI qui affiche encore un chiffre tout en ne mesurant plus rien.

Le verdict reste donc **dérivé du motif**, et « on ne sait pas » vaut « pas
justifiée ». La correction après coup passe par le chemin qui existe déjà :
rouvrir l'appel d'un jour passé (le sélecteur de date couvre N−2 → N+2,
`attendance_search_form.dart:123`) et poser le vrai motif. Aucun écran neuf,
aucune colonne, aucun contrat.

⚠️ **`UNJUSTIFIED` reste au catalogue mais n'est plus proposé** : des lignes le
portent déjà, et le retirer du contrat ferait tomber leur parsing sur le repli
défensif. Il devient une valeur d'historique, jamais écrite à neuf.

⚠️ **Le libellé doit dire ce que la valeur veut dire.** `UNKNOWN` s'affiche
« Inconnu » ; un enseignant qui le choisit croirait noter son ignorance, pas
rendre un verdict — et le KPI lirait « non justifié » sur un haussement
d'épaules. Renommé en **« Non justifiée »**.

**D-6 — Le repli de parsing devient une sentinelle front, option (a).**
*(arbitré le 2026-08-22)*
`absence_reason.dart` fait tomber toute valeur serveur inconnue sur `OTHER`
(`_ => AbsenceReason.other`), qui est **aussi** un choix légitime : une fois
écrit, plus rien ne distingue « l'enseignant a choisi Autre » de « cette
tablette est trop ancienne pour connaître ce motif ».
*Retenu :* une sentinelle **front seulement**,
`AbsenceReason.unsupported`, jamais proposée à la saisie, jamais sérialisée,
rendue « Motif non reconnu », et qui **interdit le réenregistrement de la ligne**
tant que l'enseignant ne choisit pas autre chose — sinon on réécrit
silencieusement la donnée d'un autre en `OTHER`.
*Écarté — option (b) :* porter la chaîne brute à côté de l'enum pour la
re-sérialiser à l'identique. Plus complet, mais un changement de modèle pour un
cas qui ne se produit qu'entre un déploiement serveur et le redéploiement du
parc.

**D-7 — La correction des chiffres passés est silencieuse.**
*(arbitré le 2026-08-22)*
Corriger le prédicat back **change les KPIs historiques** : toutes les absences
déjà marquées `UNJUSTIFIED` basculent de justifiées à injustifiées,
rétroactivement. C'est le comportement voulu — les chiffres passés étaient faux.
Aucun bandeau, aucune mention datée dans le tableau de bord : on ne signale pas
un chiffre corrigé, on le corrige.

---

## 4. Problèmes identifiés

1. **Le verdict diverge sur `UNJUSTIFIED`** entre back et front (§1).
2. **Le front ne s'accorde pas avec lui-même sur `null`** — quatre sites, trois
   comportements :
   - `attendance_overview_palette.dart:63` ⇒ injustifiée (seul d'accord avec le back) ;
   - `presence_status.dart:43` ⇒ justifiée ;
   - `student_attendance_stats.dart:58` (calcul **offline**) ⇒ justifiée ;
   - `attendance_results_section.dart:110/115` ⇒ ni l'un ni l'autre, isolé en
     `missingReasonsCount` — le seul défendable (cf. D-2).
3. **Le docstring d'`absence_reason_stats.dart` ment** : il affirme qu'un motif
   nul est « considérée comme injustifiée (cf. `AbsenceReasonX`) », or
   `isUnjustified` ne traite pas `null`.
4. **Le dropdown propose les onze valeurs brutes**
   (`attendance_row_editors.dart:129`), congés salariés et non-motifs compris.
5. **`OTHER` porte deux sens incompatibles** (D-6).
6. **Aucun test backend n'épingle `UNJUSTIFIED`** — le trou qui a laissé passer
   le défaut est toujours ouvert.
7. **Le prédicat back vit à trois endroits, dont deux en JPQL** :
   `AttendanceStatsService.countUnjustified` (Java) et les requêtes
   `aggregateDailyAbsences` / `aggregateAbsencesByClassroom` de
   `AttendanceRecordRepository` (quatre clauses `case when`, paramétrées sur un
   `:unknownReason` **unique**). ⚠ La règle corrigée a besoin de **deux** valeurs
   du côté injustifié : on ne peut pas la réparer en passant un autre paramètre,
   il faut toucher le JPQL.
8. **Le chiffre offline et le chiffre serveur doivent rester égaux** : la
   synthèse élève se calcule localement (`student_attendance_stats.dart`) et le
   dashboard vient du serveur. Corriger un seul côté remplace une incohérence
   par une autre.

---

## 5. Ce qu'on ne fait pas, et pourquoi

- **On ne touche pas au contrat de transport.** Les onze valeurs restent dans
  l'enum et dans le swagger : un parc de tablettes les lit et les écrit déjà, et
  retirer une valeur du contrat ferait tomber sur le repli défensif des données
  parfaitement valides.
- **On ne migre pas les données.** Aucune absence n'est réécrite ; seul le
  prédicat de lecture change (cf. D-7).
- **On ne copie pas le pavé numérique.** Une note est un nombre, une absence est
  un booléen + un enum + une note libre. Le numpad est la moitié qui ne se
  transpose pas.
- **On ne fait pas un Focus sur tout l'effectif.** Le flux dominant est « tout
  le monde est là sauf trois », déjà servi par « Marquer tous présents » : un
  Focus sur quarante élèves serait **plus lent** que la liste qu'il remplace.
- **On n'extrait pas de `SaisieDraftController` côté présence.** Le brouillon
  vit dans le BLoC (`state.draftRows` + `AttendancePresenceToggled` /
  `AttendanceAbsenceReasonChanged` / `AttendanceAbsenceNoteChanged`) ; c'est plus
  propre que le contrôleur des notes, les deux modes émettront les mêmes
  événements et resteront synchrones par construction.

---

## 6. Lots

### ~~P-1a — Back : le prédicat, et le test qui manquait~~ — LIVRÉ (`7b47b9c`)

Livré sur `fix/absence-unjustified-verdict` du dépôt `eteelo-backend`, avec son
propre cycle de revue et de déploiement. **1557 tests verts, `BUILD SUCCESS`.**

La règle a quitté ses trois copies pour vivre sur l'enum : `UNJUSTIFIED_REASONS`
(ce que reçoivent les requêtes) et `isUnjustified(reason)` (ce qu'appelle le
Java), qui prend un `null` **volontairement** — refuser `null` forcerait chaque
appelant à réinventer ce cas, ce qui est exactement comment les copies avaient
divergé. Les deux JPQL passent d'un motif unique à une `Collection`.

⚠️ **Prouvé par mutation** : en remettant `EnumSet.of(UNKNOWN)` seul, deux tests
rougissent — `unjustifiedIsUnjustified` et `unjustifiedReasonIsCountedUnjustified`.
En revanche `setAndPredicateAgree` reste vert sous cette mutation, et c'est
normal : le prédicat dérive de l'ensemble, donc les deux bougent ensemble. Ce
test garde une divergence **future** (quelqu'un qui réécrirait le prédicat à la
main), pas celle-ci.

⚠️ **Ne pas filtrer les tests sur ce dépôt.** `-Dtest=NomDeClasse` ne découvre
pas les classes `@Nested` : deux suites sur trois rapportaient « 0 test » sous
un `exit 0`. Le résumé `.txt` de surefire attribue par ailleurs 0 à la classe
externe et range les cas imbriqués dans le XML — c'est le XML qui dit vrai.

Corriger les **trois** porteurs de la règle (§4.7) pour ranger `UNJUSTIFIED` du
côté injustifié : `AttendanceStatsService.countUnjustified`, et les deux JPQL de
`AttendanceRecordRepository` — dont la signature passe d'un `:unknownReason`
unique à un ensemble de motifs injustifiés. Mettre à jour les javadocs `:47` et
`:38`, qui énoncent la règle en toutes lettres.

Tests : un cas `UNJUSTIFIED` dans `AttendanceStatsServiceTest`,
`AttendanceOverviewStatsServiceTest` et les deux tests d'intégration — c'est le
trou du §4.6, et le corriger sans le combler laisserait le même angle mort.
Aligner enfin la description du schéma `AbsenceReason` dans `openApi.yaml`, qui
ne dit rien du verdict aujourd'hui.

**Livrable :** le serveur et l'écran d'appel rendent le même verdict.

### ~~P-1b — Front : une seule règle, quatre sites~~ — LIVRÉ

**3938 tests verts, `flutter analyze` propre. Prouvé par mutation** : en retirant
le cas `null` de la règle, trois tests rougissent (le verdict à sa source, le
statut d'un jour, et le calcul offline).

Le getter `isUnjustified` est **supprimé**, pas délégué : c'est lui le défaut.
Ne pouvant pas être appelé sur un motif absent, il forçait chaque appelant à
trancher `null` pour son compte. `isUnjustifiedAbsence(AbsenceReason?)` le
remplace.

⚠️ **Un site a demandé une restructuration non prévue.** `isUnjustifiedAbsence`
ne promeut pas le type comme le faisait `reason == null || …`, et le `else` de
`attendance_overview_palette.dart` ne compilait plus (`byReason[reason]` sur un
nullable). Réécrit en séparant les deux questions : le `!= null` y est la
condition pour servir de **clé de regroupement** — un segment sans nom ne se
dessine pas — et non un verdict rendu localement.

Ce que la fiche disait, pour mémoire :

Une fonction de domaine unique prenant `AbsenceReason?` (D-3), et les quatre
sites du §4.2 qui l'appellent. Supprimer `isUnjustified` de l'extension, ou le
garder en délégation — mais un seul corps.

⚠ `absence_reason_test.dart:5` et
`presence_summary_view_data_test.dart:112` **épinglent la règle actuelle** : ils
rougiront, et c'est le signal que le changement porte. Les réécrire sur la
nouvelle règle, `null` inclus — le cas absent de tous les tests d'aujourd'hui.

Corriger le docstring menteur d'`absence_reason_stats.dart` (§4.3).

⚠ Vérifier que `student_attendance_stats.dart` (offline) et le KPI serveur
rendent le même nombre sur le même jeu — c'est l'invariant du §4.8, et il n'a
aucun test aujourd'hui.

**Livrable :** un seul verdict dans toute l'application, en ligne comme hors ligne.

### P-1c — Front : la liste de saisie, dérivée

Une liste `selectableAtEntry` (D-4/D-5) consommée par
`attendance_row_editors.dart:129` à la place d'`AbsenceReason.values`. Les clés
`.arb` des motifs retirés **restent** : elles servent toujours à l'affichage des
données historiques, seule la liste proposée rétrécit.

La liste est arrêtée : **cinq entrées** — `SICKNESS`, `FAMILY_EMERGENCY`,
`PERSONAL`, `OTHER`, `UNKNOWN` (cf. l'amendement de D-5). Sortent de la saisie
les cinq congés salariés et `UNJUSTIFIED`. Le libellé d'`UNKNOWN` passe à
« Non justifiée » dans les deux `.arb`.

### P-1d — Front : `OTHER` dédoublé

Selon D-6. En option (a) : la sentinelle `unsupported`, jamais proposée, jamais
sérialisée, qui bloque le réenregistrement de sa ligne.

### P-2a — Le Focus, restreint aux absents

Un `SegmentedTabFilter` (composant socle, déjà partagé — ⚠ `expand: true`) au
dessus de la zone de saisie, comme `SaisieModeBar`. Le mode Focus **ne se
propose que s'il reste des motifs à renseigner** et n'itère **que sur les
absents** : une carte par élève, Précédent / Suivant, fil de progression, et le
compteur « en attente » qui décroît sous les yeux.

Le mode émet les événements existants ; aucune couche data, aucun modèle neuf.
⚠ `buildWhen` sur la bascule de mode, sinon toute la page se reconstruit
(règle non-négociable #9).

**Bloqué par P-1c** : construire des cibles sur un catalogue qui contient encore
« Congé de mariage » et « Inconnu » figerait le problème dans une UI bien plus
coûteuse à défaire qu'un dropdown.

### P-2b — La grille de motifs

Le choix du motif en grille de grandes cibles plutôt qu'en dropdown, dans le
mode Focus. C'est l'équivalent fonctionnel du pavé numérique des notes : le
geste qui évite de rouvrir un menu à chaque élève.

**Ordre :** P-1a → P-1b (les deux peuvent partir en parallèle, ils ne se
touchent pas) → P-1c → P-1d → P-2a → P-2b.

---

## 7. Invariants à ne pas casser

1. **Un seul verdict.** Le chiffre de la synthèse élève (calcul local) et celui
   du tableau de bord (serveur) doivent être égaux sur la même période. C'est la
   raison d'être du chantier ; le casser à l'envers serait pire que l'état actuel.
2. **Parsing défensif.** Une valeur de motif inconnue ne lève jamais. Un motif
   ajouté côté serveur ne doit pas faire tomber une tablette non redéployée.
3. **L'appel reste bloqué sur un motif manquant.** `canSave && missingReasonsCount == 0`
   est ce qui garantit qu'aucune absence n'entre en base sans motif ; le Focus
   sert cette garde, il ne la contourne pas.
4. **Aucune valeur retirée du contrat.** Retrait de la liste de *saisie* ≠
   retrait du catalogue.
5. **Zéro string, couleur ou dimension en dur** (règles #4 et #5) : les libellés
   des motifs sont déjà dans les deux `.arb`, les cibles de la grille passent par
   `AppColors` / `AppDimensions`.

---

## 8. Pièges consignés

- ⚠ **Le prédicat back vit en JPQL, pas seulement en Java.** Corriger
  `countUnjustified` seul laisserait le tableau de bord dans l'erreur — et
  l'incohérence serait alors *entre deux écrans serveur*, plus difficile à voir
  que celle d'aujourd'hui.
- ⚠ **`:unknownReason` est un paramètre unique.** La règle corrigée en demande
  deux ; la tentation de « juste passer une autre valeur » ne marche pas.
- ⚠ **Deux tests front épinglent la règle fausse** — leur rougeur est attendue.
  Un lot qui passerait vert du premier coup n'aurait rien changé.
- ⚠ **CORRIGÉ — cette fiche affirmait qu'aucun test ne couvrait le motif
  `null`. C'était faux.** Le front en avait **deux**, et ils épinglaient le
  mauvais comportement : `forAbsenceReason(null) == justified`
  (`presence_summary_view_data_test.dart`) et `unjustifiedAbsences == 1` sur un
  jeu où une absence sur trois n'a pas de motif
  (`attendance_student_stats_test.dart`). Il fallait donc les **retourner**, pas
  les ajouter — et un test qui épingle un défaut est plus coûteux à débusquer
  qu'une absence de test, puisqu'il rend la suite verte sur le mauvais
  comportement.
- ⚠ **Le catalogue est un catalogue RH.** Les cinq valeurs de congé salarié
  suggèrent une reprise d'un module de personnel ; vérifier avant de les retirer
  qu'aucun autre appelant ne s'en sert.
- ⚠ **`AppPageBackground` plafonne à 1180 px** : tout seuil responsive du mode
  Focus au-dessus rendrait la disposition large inatteignable.
- ⚠ **`SegmentedTabFilter` exige `expand: true`** dès qu'il est contraint en
  largeur.

---

## 9. Points restés ouverts

- ~~Le chemin du verdict a posteriori~~ — **TRANCHÉ le 2026-08-22** (voir
  l'amendement de D-5) : le verdict reste dérivé du motif, `UNKNOWN` le porte,
  et la correction passe par la réouverture de l'appel.

- **Qui a le droit de corriger un appel passé ?** Le geste est attribué au
  directeur de discipline, mais le code ne connaît que `attendance.write` —
  « enregistrer un appel », que **tout enseignant** détient. N'importe qui peut
  donc rouvrir n'importe quel jour des deux dernières années et transformer une
  absence non justifiée en absence justifiée. L'acteur nommé n'est pas l'acteur
  autorisé. Ne bloque pas P-1c ; à trancher pour lui-même.
- **Le back est un autre dépôt** (`eteelo-backend`) : P-1a s'y livre, avec son
  propre cycle. Tant qu'il n'est pas déployé, P-1b **aggrave** l'écart visible
  (le front deviendra cohérent avec lui-même et toujours en désaccord avec le
  serveur). Livrer P-1a en premier, ou les deux ensemble.
