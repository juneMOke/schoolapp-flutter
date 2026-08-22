# Backlog de revue — branche `feature/auth_permissions`

Sortie de la revue `/code-review high` du **2026-08-19**, portée sur les 38
commits non poussés de la branche (233 fichiers) plus l'arbre de travail.
`flutter analyze` propre, **3621 tests verts** au moment de la revue.

Quinze défauts confirmés, plus quatre issus de la revue adversariale du
battement, plus deux signalés hors revue (M-8 et H-4). **Tous sont clos** —
dix-neuf corrigés, un tranché sans changement (B-7, faute d'un harnais qui
l'observe), et le dernier corrigé autrement que ce que sa fiche prescrivait
(B-9, dont la modale d'éditique ne pouvait pas recevoir la coquille commune).

**Le corps de ce fichier n'est plus une liste de travail** : c'est la mémoire
de ce qui a été trouvé, tranché, et parfois refusé. Seule la section « Ouverts »
en tête reste du travail à faire. Les fiches ci-dessous gardent leur ⚠️ —
ce sont les pièges à ne pas réintroduire, et plusieurs disent aussi ce que la
fiche d'origine annonçait de travers.

L'ordre des lots : #13 (`5123439`), puis H-2, H-3, H-1, M-8, M-1, M-2+M-3, M-4,
M-5+M-6, M-7, B-5+B-6 (B-7 tranché), B-8, B-1+B-2+B-3, et enfin B-4 puis B-9.

S'y ajoutait **H-4**, hors revue : signalé à l'usage le 2026-08-20 — en
Facturation, un élève trouvé par **recherche d'identité** ouvrait une fiche
vide, « contexte de détail indisponible » à la place du grand-livre. Un mode de
recherche entier était inexploitable sur l'écran de caisse : **corrigé** (voir «
Traité »).

S'y ajoutait **M-8**, hors revue : constaté à l'usage le 2026-08-19 — le détail
d'un élève en Facturation attendait le réseau avant d'afficher un grand-livre
déjà présent en base. Seul défaut du lot à se manifester dans le chemin
**nominal**, à chaque ouverture de fiche : **corrigé** (voir « Traité »).

S'y ajoutent **P-1**, **P-2** et **P-3**, hors revue, sur la **Présence de
l'élève** (2026-08-22). P-1 était un défaut du chemin nominal — l'écran d'appel
et les KPIs rendaient des verdicts contraires sur la même absence : **livré**
(`PRESENCE_MOTIFS_PLAN.md`). P-2 est un besoin produit, P-3 un défaut trouvé en
revue de P-1 : tous deux **ouverts**. Voir « Ouverts ».

> Ordre : gravité décroissante. Un défaut « haut » a une conséquence métier
> directe et irréversible sans intervention ; un « moyen » dégrade une décision
> ou un affichage ; un « bas » attend un appelant qui n'existe pas encore, ou ne
> se manifeste que sur une transition rare.

---

## 🟠 Ouverts — hors revue, signalés à l'usage

Besoins et défauts constatés sur la **Présence de l'élève** le 2026-08-22,
analysés contre le code front **et** back. Ils ne sortent pas de la revue : ce
sont des entrées neuves.

➜ **Plan d'implémentation : `PRESENCE_MOTIFS_PLAN.md`** — P-1 y est décomposé et
**livré** (P-1a→c, plus la permission `attendance.amend` qui n'y figurait pas).
P-2 et P-3 restent ouverts. Les fiches ci-dessous décrivent le défaut ; le plan
porte les lots, les invariants et les pièges.

### P-1 · Le verdict « justifiée / injustifiée » n'a pas le même sens des deux côtés

Les onze motifs d'absence sont rigoureusement identiques aux trois endroits qui
les portent — `attendance/domain/AbsenceReason.java`, le schéma `AbsenceReason`
d'`openApi.yaml:8038`, et `absence_reason.dart`. Même contenu, même ordre. **Le
catalogue est aligné ; la règle qu'il alimente ne l'est pas.**

`AttendanceStatsService.java:217` — javadoc `:47`, identique dans
`AttendanceOverviewStatsService.java:38` :

```
motif == null || motif == UNKNOWN   →  injustifiée
tout le reste                        →  justifiée
```

« Tout le reste » **inclut `UNJUSTIFIED`**. Le front dit l'inverse
(`absence_reason.dart:57`) : `isUnjustified = unjustified || unknown`.

⇒ Un enseignant qui choisit explicitement « Absence non justifiée » la voit
comptée **injustifiée** sur l'écran d'appel et dans la synthèse élève, et
**justifiée** dans les KPIs du tableau de bord Présence. Même absence, deux
verdicts selon l'écran regardé — et c'est le chemin **nominal**, pas une
transition rare.

C'est le **back** qui a tort : son prédicat n'a jamais été repris quand
`UNJUSTIFIED` est entré au catalogue, il teste encore les deux seuls cas
d'origine. Il est intenable qu'une valeur nommée `UNJUSTIFIED` compte comme
justifiée.

⚠️ **Et le front n'est pas d'accord avec lui-même sur le motif absent.** Quatre
sites appliquent la règle, pour trois comportements :

- `attendance_overview_palette.dart:63` — `reason == null || reason.isUnjustified`
  ⇒ injustifiée (le seul d'accord avec le back) ;
- `presence_status.dart:43` — `reason?.isUnjustified ?? false` ⇒ **justifiée** ;
- `student_attendance_stats.dart:58`, le calcul **offline** ⇒ **justifiée**, et
  le commentaire assume le choix ;
- `attendance_results_section.dart:110/115` ⇒ ni l'un ni l'autre, exclu des deux
  compteurs et isolé en `missingReasonsCount`. C'est le seul défendable :
  l'écran d'appel **interdit d'enregistrer** tant qu'un motif manque
  (`canSave && missingReasonsCount == 0`), donc « sans motif » y est un état
  transitoire, jamais une catégorie.

⚠️ Le docstring d'`absence_reason_stats.dart` affirme qu'un motif nul « est
alors considérée comme injustifiée (cf. `AbsenceReasonX`) » — or
`AbsenceReasonX.isUnjustified` ne traite pas `null` du tout. **La doc renvoie à
un code qui ne fait pas ce qu'elle dit.**

⚠️ **Le catalogue est un catalogue RH, pas un catalogue élève.**
`attendance_row_editors.dart:129` rend `AbsenceReason.values` **brut**, sans
filtre, dans l'ordre de déclaration. L'enseignant se voit donc proposer, pour un
élève : « Congé de mariage », « Congé parental », « Congé professionnel »
(motifs de congé de salarié), « Vacances » (un calendrier, pas une absence à
justifier), et surtout « Inconnu » et « Absence non justifiée » — que le swagger
décrit lui-même comme n'étant **pas** des motifs de saisie (`UNKNOWN` = *reason
not known at entry (transient)*, `UNJUSTIFIED` = *verdict rendered afterwards*).
Le catalogue mélange trois natures — des motifs, des états du cycle de vie, un
fourre-tout — et l'UI les aplatit en une liste de onze.

⚠️ **`OTHER` porte deux sens incompatibles.** `absence_reason.dart` fait tomber
toute valeur serveur inconnue sur `OTHER` (`_ => AbsenceReason.other`), avec un
bon commentaire expliquant pourquoi ce n'est pas `UNKNOWN`. Mais `OTHER` est
**aussi** un choix légitime de l'enseignant : une fois la valeur écrite, plus
rien ne distingue « l'enseignant a choisi Autre » de « cette tablette est trop
ancienne pour connaître ce motif ». C'est précisément le risque que
l'enrichissement du catalogue est censé rendre sûr.

**Ce que ça demande** — décider qui arbitre le verdict, une fois, à un seul
endroit, puis dériver la liste de saisie de cette décision au lieu d'exposer
l'enum de transport brut. Trois gestes, dans cet ordre :

1. **Corriger le prédicat back** pour qu'il couvre `UNJUSTIFIED`, et acter par
   écrit le sort du motif absent. Correctif serveur, petit.
2. **Une seule règle front**, dans le domaine, qui prenne `AbsenceReason?` —
   donc qui traite `null` — et remplacer les quatre sites. La règle est
   aujourd'hui recopiée quatre fois avec trois sémantiques : même piège que le
   comparateur d'ensembles de permissions recopié deux fois (cf. B-1+B-2+B-3).
3. **Séparer catalogue de transport et liste de saisie** : une liste
   `selectableAtEntry` qui exclut `UNKNOWN`, `UNJUSTIFIED` et le `OTHER`-repli,
   et qui écarte les motifs de congé salarié si le métier confirme qu'ils n'ont
   pas de sens pour un élève.

---

### P-2 · L'appel n'a qu'un seul mode de saisie — et le Focus des notes ne s'y transpose pas tel quel

Côté notes, la saisie a deux modes : `SaisieModeBar` bascule Tableau | Focus via
le `SegmentedTabFilter` du socle, vers `SaisieTable` ou `SaisieFocus` (183 + 250
lignes) et un `SaisieNumpad` (108 lignes), le tout piloté par un
`SaisieDraftController` partagé (208 lignes) pour que les deux modes éditent le
même brouillon.

Côté appel, **un seul rendu** : `AttendanceRecordsMobileList`, un
`ListView.separated` de lignes dans un panneau à hauteur fixe (`height * 0.62`
clampé), chaque ligne portant un `DropdownButtonFormField` inline et un champ
note. Aucune bascule.

**Ce qui se transpose** : la barre de mode (composant socle déjà partagé), la
carte un-élève-à-la-fois, le fil de progression, Précédent / Suivant, et les
compteurs par statut en direct — l'écran d'appel les calcule déjà dans
`AttendanceResultsToolbar`.

⚠️ **Ce qui ne se transpose pas : le pavé numérique.** Une note est un nombre ;
une présence est un **booléen + un enum + une note libre**. Tout le bénéfice du
Focus des notes tient au « grand nombre + pavé + clavier physique mappé, on ne
quitte jamais le pavé ». L'équivalent pour la présence est un grand basculeur
Présent / Absent et les motifs en grille de cibles larges — pas un pavé. Copier
le numpad serait copier la mauvaise moitié.

**Prérequis structurel** : les notes ont un `SaisieDraftController` que les deux
modes partagent ; la présence n'en a pas — le brouillon vit dans le BLoC
(`state.draftRows`, muté par événements, chaque ligne faisant son
`context.read<AttendanceBloc>()`). Ce n'est pas un blocage, c'est même plus
propre : le mode Focus émettrait les mêmes événements et les deux modes
resteraient synchrones par le BLoC. À surveiller, un `buildWhen` pour que la
bascule de mode ne reconstruise pas tout (règle non-négociable #9).

⚠️ **L'objection qui compte, et le recadrage qu'elle impose.** Le gain du Focus
pour les notes, c'est saisir ~40 nombres vite. Pour l'appel, le flux dominant
est « tout le monde est là sauf 3 » — et l'écran a déjà « Marquer tous présents »
(`AttendanceMarkAllPresentRequested`). En mode liste on scanne et on bascule
trois lignes ; un Focus sur tout l'effectif imposerait **40 passages pour 3
absences**, donc serait plus lent que ce qu'il remplace.

Là où le Focus vaut quelque chose, c'est sur la **passe des motifs** —
exactement ce qui bloque l'enregistrement aujourd'hui (`missingReasonsCount > 0`
interdit de sauver). Un Focus **restreint aux seuls absents**, une carte par
absent, motif en grille de grandes cibles, Suivant automatique : la bascule ne
se propose que quand il reste des motifs à renseigner, et elle traite trois
élèves, pas quarante. Ce n'est pas le Focus des notes — c'est un meilleur, et il
coûte moins cher.

⚠️ **Ordre entre les deux fiches : P-1 d'abord.** Construire une grille de
motifs sur un catalogue qui contient « Congé de mariage » et « Inconnu »
figerait le problème de P-1 dans une UI bien plus coûteuse à défaire qu'un
dropdown.

---

### P-3 · Le donut des motifs ne totalise pas les absences qu'il prétend ventiler

Trouvé en revue du lot P-1a, **antérieur à ce lot** et hors de son périmètre.

`AttendanceRecordRepository.aggregateAbsenceByReason` filtre
`ar.absenceReason is not null`. La ventilation par motif renvoyée au client ne
contient donc **jamais** d'entrée pour les absences sans motif. Or ces absences
existent — le contrat les autorise (`AbsenceInput.absenceReason` n'est pas
`@NotNull`) et des lignes historiques en portent — et les KPIs du même écran
les comptent, du côté **injustifié**, depuis toujours.

Le tableau de bord affiche donc deux nombres qui ne se réconcilient pas : le
total central du donut (`AttendanceOverviewReasonsSection` le rend) vaut les
absences **avec** motif, tandis que la bande de KPIs annonce des jours d'absence
qui incluent celles sans motif. L'écart est exactement le nombre de jours
d'absence sans motif sur la période.

⚠️ **Et le front prétend gérer un cas que le serveur ne peut pas produire.**
`attendance_overview_palette.dart` replie `reason == null` dans la part
« Non justifié » du donut. Cette branche est **morte** : aucune entrée nulle
n'arrive jamais. Elle a l'air d'une précaution et n'en est pas une — elle
masque le défaut en donnant à lire que le cas est traité.

⚠️ **Ne pas confondre avec la part rouge.** Le donut a bien une part
« Non justifié », alimentée par `UNKNOWN` et `UNJUSTIFIED`, qui sont des motifs
non nuls. Ce n'est donc pas la part qui manque, c'est le **sans-motif** qui
n'atteint jamais le graphique.

**Ce que P-1c change, et ce qu'il ne change pas.** Depuis que l'écran d'appel
interdit d'enregistrer sans motif et propose « Non justifiée » (`UNKNOWN`), les
absences neuves portent toutes un motif : la population concernée ne grandit
plus. Elle ne disparaît pas pour autant — l'historique reste, et le contrat
continue d'accepter un motif nul d'un autre client.

**Deux façons d'en sortir, et il faut choisir.** Soit le serveur émet une entrée
à motif nul dans `byAbsenceReason` (le front sait déjà la replier, sa branche
morte reprend vie, et les deux totaux se rejoignent) ; soit le front cesse de
prétendre gérer ce cas et le tableau de bord dit explicitement sur quoi porte le
donut. **Le premier réconcilie les chiffres, le second se contente de ne plus
mentir** — et un donut qui ne totalise pas ce que la bande de KPIs annonce reste
un chiffre qu'un directeur ne peut pas vérifier à l'œil.

---

## ✅ Traité

Douze défauts de la revue adversariale du battement ont été corrigés dans la
foulée (garde `isFlushing` avant le cycle complet, garde hors-ligne en tête de
tic, push muet, séparation tentative/pull, révocation non évaluée par le timer,
`inactive` neutre, seuil de poison du moteur, fermeture de session sur toute
issue non authentifiée, renoncement coopératif, câblage racine testé, verrou de
réentrance testé, prémisses périmées réécrites) — tous vérifiés par mutation.

### ~~H-1 · Le champ « Prénom » de la recherche de parent est intapable~~ — corrigé

`parent_search_dialog.dart` — le bloc de critères porte une `GlobalKey`
(`_searchFormKey`, via `KeyedSubtree`) : la bascule `pinsForm` le **reparente**
au lieu de le détruire, donc les `FocusNode` que chaque `EteeloTextInput` se
crée — et dispose — survivent au passage. Le focus reste, le clavier ne se
referme pas, la bascule ne repart pas en sens inverse.

Le seuil n'a **pas** été touché : le calculer sur une hauteur sans les inserts
de clavier rouvrirait le débordement que la bascule existe à fermer (téléphone
en paysage, ~100 dp restants pour un en-tête et des critères qui en coûtent
trois fois plus).

⚠️ **Pourquoi les deux tests clavier existants ne l'ont jamais vu** : ils
mesurent deux dispositions **statiques**, chacune à sa taille de surface, alors
que la panne est dans la **transition**. Les deux tests ajoutés ouvrent le
clavier (`tester.view.viewInsets`) sur un champ **déjà focalisé**, dans les deux
sens, et vérifient d'abord que la bascule a bien eu lieu — sans quoi ils
seraient vides — puis que le `FocusNode` est le **même objet**. Sans la clé,
l'assertion rougit sur un élément `DEFUNCT`.

---

### ~~H-2 · Un flux rejeté au parsing désarme l'arête créances → paiements~~ — corrigé

`lib/core/offline/pull_coordinator.dart` — les clés écartées à l'analyse
amorcent `unusableResources` **avant la boucle**, converties en ressources par
`resourcesOf`. Un `mode` neuf déployé sur `finance.student-charges` fait donc
renoncer aux paiements au lieu de les poser sur un `amount_paid_in_cents`
périmé. Amorçage pris sur le PLAN et non sur la sélection du cycle : un
`pullSubset` de la seule ressource paiements — le chemin de l'écran de
Facturation — renonce lui aussi, puisque l'amont ne sera rafraîchi par aucun
cycle. Trois tests, dont une contre-épreuve (une clé écartée qui n'est l'amont
de rien ne bloque personne) ; l'amorçage retiré fait rougir les deux premiers.

---

### ~~H-3 · « Le client n'a rien compris » est classé « rien à tirer »~~ — corrigé

`sync_plan_parser.dart` mesure désormais `allStreamsDropped` — le serveur a
annoncé des flux, ce client n'en a retenu aucun — et le repository le traduit en
`SyncPlanUnknownCause.unsupportedStreams`, donc en repli sur le registre. Le
corps n'est plus mis en cache (la garde `state is! SyncPlanUnknown` couvrait
déjà le cas dès qu'il change de famille), donc la panne ne survit plus au
redémarrage. C'est un **verdict** et non un incident : `refreshFromNetwork` le
rend en état, contrairement au corps illisible, parce qu'une nouvelle tentative
rendrait le même corps tant que l'APK n'a pas appris ce vocabulaire.

Le drapeau est mesuré sur la liste **brute**, pas sur `rejectedKeys` : une
entrée sautée faute de `key` ne peut pas être nommée dans la trace, et laisse
pourtant la tablette sans rien à tirer. Le déduire des seules clés écartées
laissait ce corps-là retomber sur « rien à tirer ».

⚠️ **Conséquence à ne pas défaire** : `SyncPlanEmpty` ne porte plus de
`rejectedKeys`, et le test du coordinateur qui les y vérifiait a été retiré. Ce
champ avait été ajouté par la revue adversariale de F5/F9 pour nommer les clés
fautives d'un plan « vide parce que tout a été écarté » — un état que ce lot
supprime à la source. Le nommer était le lot de consolation d'un parc à l'arrêt
; il tire, désormais. La garantie a déménagé dans
`sync_plan_repository_impl_test.dart`, groupe « TOUS les flux écartés → INCONNU,
jamais vide ».

---

### ~~M-8 · Le détail d'un élève attend le réseau avant de servir le grand-livre local~~ — corrigé

Les deux repos offline-first (`student_charges_offline_first_repository.dart`,
`payments_offline_first_repository.dart`) **lancent** le rafraîchissement ciblé
sans l'attendre, et servent le DAO immédiatement. Ce qui était lent était le
réseau, jamais la base : le skeleton tenait jusqu'à ~22 s en réseau dégradé pour
afficher des lignes déjà en local.

L'attente n'a pas été supprimée, elle a **déménagé** là où
`FACTURATION_OFFLINE_PLAN.md` §13 la plaçait — devant l' **encaissement**, où le
« reste » composé borne la saisie et décide s'il faut encaisser. Sous-estimé
parce qu'un versement du poste voisin n'est pas descendu, il fait réencaisser.
`runFacturationCollectPreflight` (nouveau) la tient au tap « Encaisser »,
derrière une barrière qui n'apparaît qu'au-delà de 220 ms — la plupart des taps
n'attendent rien, et une modale ouverte puis refermée en 20 ms se lit comme un
bug. Une relecture en échec **n'y ferme jamais le guichet** : on retombe sur
l'affichage courant plutôt que de refuser une famille qui a l'argent en main.

Trois bornes, et il faut les trois :

| Borne | Valeur | Ce qu'elle empêche |
|---|---|---|
| TTL de lecture (`readMaxAge`) | 120 s | Chaque (ré)ouverture de fiche rejouait tout le cycle |
| Fraîcheur exigée à l'encaissement | 15 s | Une rafale d'encaissements repayait l'aller-retour à chaque fois |
| Plafond de l'attente visible | 4 s | On ne remplace pas un blocage de 22 s par un blocage indéfini |

Le TTL n'est posé que sur un cycle **abouti** : un cycle en échec ne s'amortit
pas, sinon un réseau qui retombe gèlerait la fiche jusqu'au délai suivant.

⚠️ **La borne d'attente vit chez l'APPELANT** (`refresh(..., deadline:)`), pas
dans `_refreshCharges`. Y poser un timeout retirerait l'entrée in-flight pendant
que la pagination tourne encore, et un second cycle concurrent partirait sur le
même élève. Passé le délai, le cycle n'est **pas annulé** : il poursuit en fond
et annoncera son aboutissement.

⚠️ **Ne pas retirer le signal `FinanceLedgerRefresher.revalidated`** en croyant
simplifier. C'est la contrepartie exacte de l'`await` supprimé : sur une
tablette dont la base est encore vide, l'écran afficherait « Aucun frais » et
n'en sortirait pas de la visite. La relecture qu'il déclenche est
**silencieuse** (drapeau `silent` sur les deux events) — pas de retour en
`loading`, et son échec ne détruit pas ce qui est affiché. Les états étant
`Equatable`, un cycle qui ne change rien ne reconstruit rien. La légende de
fraîcheur s'y abonne aussi : sans ça elle resterait figée sur l'ancienne heure
quand le grand-livre n'a pas bougé.

Les deux lectures passent en `transformer: _sequential()` : le traitement
concurrent par défaut laissait une relecture silencieuse rendre **avant** la
lecture initiale et se faire écraser par un résultat plus ancien.

Tests : la non-régression qui compte est un seam de rafraîchissement qui ne rend
**jamais** la main, et une lecture qui aboutit quand même (avec `timeout`, sinon
une régression ferait pendre le test au lieu de le faire échouer). Plus deux
tests de câblage sur le conteneur réel — les trois pièces en sortent, et l'écran
écoute le canal **de ce refresher** (identité), pas d'un autre.

⚠️ **Piège de test rencontré** : un `Completer` créé dans `setUp` planifie ses
continuations dans la zone racine, que `tester.pump()` ne draine jamais.
L'attente ne se dénouait pas, et cela ressemblait trait pour trait à un défaut
du code testé.

---

### ~~B-4 · La recherche par niveau n'a pas d'état « inscriptions pas encore synchronisées »~~ — corrigé

Les trois messages de vide écrits jusqu'ici disaient tous « de cette classe ».
Une recherche « toutes les classes du niveau » ne pouvait donc qu'échouer vers «
Aucun élève ne correspond à ces critères. Modifiez le formulaire » — on envoyait
l'opérateur corriger des critères qui n'y peuvent rien, alors que sa tablette
n'avait simplement aucune inscription pour ce niveau.

La maille décide désormais du **vocabulaire** autant que des causes. Deux
messages neufs pour la maille niveau, et la cascade est réécrite par maille
plutôt que par cause.

⚠️ **Ce que la maille niveau ne peut PAS trancher, et que le message ne prétend
donc pas savoir** : à l'échelle d'une classe, le roster départage « pas descendu
» de « aucun dossier local » ; à l'échelle du niveau, rien ne distingue « ce
niveau n'a réellement aucun élève » de « le flux Inscription n'a pas atterri ».
Le message dit donc ce qui est vrai des deux côtés — « sur cet appareil » — et
n'offre le geste qu'en condition (« si des inscriptions viennent d'être saisies
ailleurs »). Inventer une certitude aurait refait le défaut dans l'autre sens.

Le « modifiez le formulaire » subsiste, et c'est maintenant le seul cas où il
est juste : des élèves portent bien ce frais, et c'est le filtre de statut ou
les noms qui n'ont rien laissé passer. Le décompte qui le décide est mesuré
**avant** le filtre (`FeeControlProjector.join`), donc il dit « personne n'est
concerné », jamais « le filtre a tout écarté ».

Tests : trois cas de maille niveau, dont la contre-épreuve du seul vide qui
relève vraiment de la saisie. Vérifié par mutation.

---

### ~~B-9 · Sept modales de lecture n'ont pas reçu la coquille sûre au clavier~~ — corrigé

L'arbitrage du 2026-08-19 était de ne pas ouvrir un large diff sur des écrans
d'argent sans défaut prouvé. Le défaut est désormais **prouvé** : forcer la
disposition ancrée sur l'une d'elles, téléphone en paysage clavier levé, fait
déborder de **106 px** — la mesure est dans le test.

Six des sept passent par `EteeloDialogBody`. Les seuils sont posés au-dessus de
la hauteur incompressible réelle de chacune, et non recopiés : 300 pour les
modales à en-tête sombre et pied à deux actions, 320 pour la confirmation
d'encaissement (son bandeau d'étapes est plus épais), 220 pour les deux qui
n'ont qu'un en-tête.

⚠️ **La modale d'éditique ne passe PAS par la coquille, et ce n'est pas un
oubli.** Son corps n'est pas un document qui coule : c'est `PdfPreview`, une
fenêtre qui gère son propre défilement et exige une hauteur **bornée**. La
disposition défilante lui offrirait une hauteur infinie — exception de layout,
ou défilement dans un défilement, la pathologie même que ce socle documente. Son
exposition est donc fermée à la source : on **abaisse le clavier** avant
d'ouvrir. C'est aussi ce qu'attend l'utilisateur d'une pièce à lire, et le champ
qui avait le focus le reprend d'un tap — là où une pièce illisible ne se
rattrape pas.

⚠️ **La modale de réaffectation est la seule dont le corps est une LISTE**, et
elle est passée `shrinkWrap: true` **+** `NeverScrollableScrollPhysics`. Une
liste laissée maîtresse de son défilement gagne l'arène des gestes en tant que
`Scrollable` le plus intérieur sans avoir rien à faire défiler : le doigt ne
déplace alors plus rien. `ScrollView` fige son `physics` dans son constructeur —
impossible de la museler depuis la coquille.

Tests : un cas « téléphone en paysage, clavier déjà levé » par modale migrée,
six en tout. Le relevé par élève n'avait **aucun** test : il en reçoit deux, au
moment où on le touche. Vérifié par mutation (`minPinnedHeight: 0` rétablit la
disposition ancrée et fait ressortir le débordement de 106 px).

---

### ~~B-1 + B-2 + B-3 · Trois fuites du socle : un transtypage, un drapeau, un doublon~~ — corrigés

Trois défauts sans rapport apparent, et un point commun qui justifie le lot :
chacun rend **silencieuse** une information qui existait. Aucun ne fait planter
un écran ; tous les trois font travailler la synchronisation sur une prémisse
fausse.

**B-1 — une voie générique pour deux attentes.** Les handlers du coordinateur
veulent leur issue (`PullOutcome`) ; les écrans qui tirent hors coordinateur
veulent seulement que la ressource soit à jour. Un `guarded('enrollments', …)`
programmé avec `T = void`, puis le cycle du coordinateur sur la même ressource,
et ce dernier recevait le futur du premier : `null as PullOutcome` lève, le
`catch` du coordinateur compte un échec, et `handler.pull()` **ne tourne
jamais**. La ressource ainsi perdue est l'Inscription — source de `students`,
donc de la Facturation, du Contrôle des frais, des Documents et du ticket
imprimé.

Le garde a désormais deux voies. Seuls les cycles de `run` s'enregistrent comme
**coalesçables**, si bien que le transtypage qui les partage ne voit jamais
qu'un cycle du même type ; `runIgnoringResult` se coalesce volontiers sur eux —
il ignore la valeur, donc ne transtype rien — mais ne s'offre jamais en retour.
⚠️ **La coalescence entre appelants typés est préservée**, et c'est délibéré :
c'est le cas NORMAL (un écran qui se monte pendant un cycle complet), et le
supprimer coûterait un aller-retour réseau par écran. Le surcoût du correctif
est un cycle de plus dans le cas mixte, c'est-à-dire un 304 ; le prix de
l'erreur inverse était une ressource jamais tirée.

**B-2 — la pastille du compte précédent.** Le cubit vit aussi longtemps que
l'application, et les deux drapeaux de lecture dégradée ne sont réécrits que par
un cycle qui a réellement observé quelque chose (délibéré : neuf chemins
appellent `refresh()` sans avoir rien tiré). A pose « partiellement à jour », A
part, B arrive — et si le cycle de B s'arrête tôt, **B porte la pastille de A**.
Remis à zéro dans `onSessionClosed()`, au même endroit et pour la même raison
que `CurrentPermissions.clear()` et `SyncPlanHolder.clear()`. ⚠️ `_lastSyncAtMs`
n'en fait PAS partie — c'est la date de dernière synchro de la **tablette**,
persistée, vraie quel que soit le porteur — ni `_hasHeldWork`, relu de la file à
chaque `refresh()` et partagé entre les comptes.

**B-3 — `['a','a']` valait `['a','b']`.** Longueurs égales, puis « chaque
élément de a est dans b » : deux ensembles différents passaient pour identiques.
Rien n'oblige le serveur à dédupliquer ce qu'il sérialise, et la conséquence
était muette — un refresh livrant le second après le premier ne notifiait
personne, le plan de synchro n'était jamais marqué périmé, et le périmètre de
pull restait celui d'avant le changement de droits jusqu'au logout.

⚠️ **Le comparateur était recopié DEUX fois**, et les deux copies portaient
l'erreur : `CurrentPermissions` et `PermissionGate`. La fiche n'en nommait
qu'une. Il vit maintenant une seule fois, dans `permission_policy.dart`
(`samePermissionSet`), à côté de `canAccess` dont il partage la raison d'être :
un contrôle d'accès recopié finit par diverger.

Tests : quatre sur le garde (le cycle sans issue ne se fait pas passer pour un
cycle typé, la contre-épreuve que la coalescence typée tient, l'inverse est sûr,
la sérialisation vaut entre les voies), un sur la fermeture de session, trois
sur les doublons dans les deux sens. Vérifiés par mutation.

---

### ~~B-8 · `sync_status_cubit.dart` dépasse largement la cible de taille~~ — corrigé

Le fichier faisait **deux métiers** : projeter un état sur une pastille, et
exécuter la séquence `flush → évaluation de révocation → pull` avec les trois
gardes qui la protègent. Le second avait doublé en trois lots de battement et
noyait le premier. `SyncCycleRunner` (`lib/core/offline/`) porte désormais le
corps de cycle, ses gardes et les estampilles qui datent le cache ; le cubit
garde les quatre déclencheurs et la projection.

| avant | après |
|---|---|---|
| `sync_status_cubit.dart` | 670 lignes, **293 de code** | 516 lignes, **219 de code** |
| `sync_cycle_runner.dart` | — | 292 lignes, **134 de code** |

⚠️ **La cible de ~250 lignes est atteinte sur le code, pas sur le fichier**, et
c'est la mesure qui compte ici : le reste est de la documentation que ce dépôt
garde délibérément (les deux fichiers sont à ~50 % de commentaire). Aller
chercher les 516 lignes brutes demanderait de sortir aussi la politique du tic
et les déclencheurs, en donnant au cubit une référence arrière vers eux : on
échangerait de la taille contre du couplage circulaire. À rouvrir si le fichier
se remet à grossir par le code.

**Refonte pure, zéro changement de comportement** — et c'est vérifiable : les
**77 tests** du cubit passent sans une seule modification. C'était le critère
d'acceptation, l'API publique et le constructeur étant inchangés (les deux
seuils restent lisibles sur `SyncStatusCubit`, alias de ceux du runner, pour que
la politique n'ait qu'une définition).

La frontière neuve, elle, est épinglée par onze tests directs :
`SyncCycleOutcome` porte des drapeaux **nullables au sens de « rien observé »**,
jamais « sain ». Un cycle arrêté sur une garde, un rapport `skipped` ou
`offline` n'ont rien vu ; les traduire en « tout va bien » effacerait une
dégradation bien réelle. La paire de tests qui le prouve compare
l'après-`skipped` (un cycle redevient dû dès le plancher de reprise, le cache
n'ayant jamais été rajeuni) à l'après-rapport-exploitable (le même délai ne
suffit pas, le cache tient son quart d'heure).

⚠️ **Écrit en le vérifiant, pas en le supposant** : ma première attente sur le
rapport `skipped` était fausse — je croyais le cycle immédiatement dû, alors que
le plancher de reprise de cinq minutes s'applique d'abord. Le test a été
corrigé, pas le code.

---

### ~~B-5 + B-6 · Ce que le battement a périmé : une feuille photographiée, et quatre déchiffrements par tic~~ — corrigés

Traités ensemble : ce sont les deux dettes que le battement de la file a créées
sans les inventer. Le code était juste **avant** que quelque chose ne tourne
toutes les 45 secondes.

**B-5 — la feuille ne photographie plus, elle suit.** `hasIncompleteRead` /
`hasRetriableRead` étaient relevés à l'ouverture, sur la prémisse écrite qu'ils
« ne peuvent de toute façon pas changer utilement le temps d'une modale ouverte
». Un tic peut lever la dégradation pendant qu'on lit — « Réessayer » brûlait
alors dix-neuf ressources pour rien — ou l'introduire alors que la feuille
n'offrait plus ni bandeau ni geste. C'est l'**instance** du cubit qui est
emportée dans le sous-arbre du `Navigator` (`.value`, la racine en reste
propriétaire), et un `buildWhen` borne la reconstruction aux deux champs lus :
une feuille qui se repeindrait à chaque tic sous les doigts de l'utilisateur
serait le remède pire que le mal.

Même nature côté écritures : `OutboxErrorsCubit` était chargé une fois, sans
abonnement. Un flush du battement peut acquitter et supprimer une ligne que la
feuille liste encore, et `requeue` ne touchant que les `SYNC_ERROR`, le tap
devenait un **no-op muet**. Il s'abonne désormais à la fin de flush — même point
d'accroche que `PaymentAnomaliesCubit`, et pour la même raison : c'est la
transaction d'ACK qui modifie la file. ⚠️ La relecture est **refusée pendant
`_runAction`**, qui tient déjà `busy` et recharge en sortie : recharger au
milieu rendrait la main aux boutons pendant leur propre geste.

**B-6 — une session lue une fois par tic, pas quatre.** `readAuthSession()`
enchaînait treize `read()`, chacun un aller-retour MethodChannel et un
déchiffrement Keystore ; un tic avec du travail prêt les payait quatre fois
(sonde, ré-authentificateur, garde du moteur, refresh) — une cinquantaine de
déchiffrements toutes les 45 s sur une tablette d'école. Le mémo vit dans
`TokenStorageService`, et **le choix du lieu est le cœur de la correction** :
toutes les écritures de ces clés passent par cette classe et par elle seule,
donc l'invalidation est *prouvablement* complète. C'est elle, et non le délai de
3 s, qui garantit qu'un mint tout juste écrit est vu par la garde du moteur un
dixième de seconde plus tard ; le délai n'est qu'un plafond de dégâts si une
écriture apparaissait un jour ailleurs. Les douze lectures restantes partent
désormais **ensemble** (`Future.wait`) au lieu de s'additionner, et l'absence de
session est mémorisée comme le reste — c'est le cas le plus fréquent du parc
hors ligne.

⚠️ **Piège pour les tests** : écrire directement dans le faux en mémoire de
`flutter_secure_storage` contourne l'invalidation. Passer par le service, ou
avancer l'horloge injectée.

Tests : trois cas de feuille (le tic qui lève la dégradation, celui qui
l'introduit, celui qui ne change que l'horodatage et ne doit rien repeindre),
deux de file (un flush du moteur retire la ligne acquittée ; un cubit fermé ne
s'abonne plus), six de mémo (une seule lecture pour quatre appels, l'absence
mémorisée, les trois invalidations, le plafond de délai). Vérifiés par mutation
: `buildWhen` figé, abonnement retiré, invalidation retirée — chacun fait rougir
son cas.

---

### ~~B-7 · L'état de cycle de vie initial est supposé, jamais lu~~ — clos sans changement

Vérifié, pas corrigé, et c'est le résultat qui compte : **trois harnais essayés,
aucun ne l'observe.** `WidgetsBinding.instance.lifecycleState` rend bien l'état
depuis le corps du test — après `handleAppLifecycleStateChanged` comme après un
message de plateforme sur `flutter/lifecycle` — mais `null` depuis `initState`,
y compris après un premier `pumpWidget`. La note de la revue disait vrai ; on
sait maintenant qu'elle tient à autre chose qu'un oubli de harnais.

La décision reste donc celle du code : ne rien semer, et l'écrire. Sur la cible
— tablette Android, une seule activité LAUNCHER, ni service ni receiver — le
battement ne s'arme qu'à l'ouverture de session, laquelle exige un écran. Poser
une garde qu'aucun test n'exerce, c'est exactement la panne que le dépôt a déjà
payée une fois (une sonde livrée, jamais branchée, toute la suite verte).

⚠️ **À rouvrir si le périmètre s'étend au bureau ou au web.** Une piste alors,
qui rendrait la politique testable sans dépendre du binding : injecter l'état
initial en paramètre du widget (défaut =
`WidgetsBinding.instance.lifecycleState`), ce qui laisse hors test une seule
expression par défaut au lieu de tout le comportement.

---

### ~~M-7 · Le verrou de tarifs mute sans reconstruire~~ — corrigé

`_syncTariffsWithheld` s'en remettait à `_recomputeFormState` pour appeler
`setState`, or celui-ci ne reconstruit que si la **validité** de l'étape bascule
— et le droit sur la grille n'y entre que par `blocked = (tariffsWithheld ||
feeGridUnavailable) && charges.isEmpty`. Dès que des créances sont chargées, le
verdict de droit changeait sans que rien ne reconstruise. Le listener de droits
passe désormais par `_onPermissionsChanged`, qui reconstruit sur changement,
comme le frère `disciplinary_student_detail_page.dart`.

⚠️ **La fiche annonçait un symptôme qui n'était pas atteignable, vérification
faite.** « Une perte de `finance.grid.read` laisse les montants de tarifs à
l'écran » : c'est vrai, mais ce n'est pas ce défaut — `StudentChargesStepBody`
n'utilise `tariffsWithheld` **que** sur liste vide, et affiche les créances quel
que soit le droit dès qu'il y en a. C'est même une décision explicite, épinglée
par le test « grille caviardée mais créances présentes → aucune alerte » : si
des créances sont là, elles font foi. Reconstruire ne change donc rien à l'écran
aujourd'hui.

Ce qui était réellement cassé est le **contrat** : le corps recevait le droit du
montage jusqu'à ce qu'un changement d'état sans rapport le rafraîchisse. Le
rebuild n'était garanti que par une **coïncidence** — les cas où l'affichage
dépend du droit (liste vide) sont exactement ceux où la validité bascule. Le
jour où ce rendu dépendra du droit avec une liste non vide, la panne serait
visible, silencieuse, et cherchée ailleurs.

⚠️ **`didChangeDependencies` ne reconstruit toujours pas, et c'est délibéré** :
il précède immédiatement un `build`, et Flutter n'y tolère un `markNeedsBuild`
que parce que l'élément est dans la portée de la construction en cours. Les deux
appelants sont donc séparés — relecture nue depuis `didChangeDependencies`,
relecture **et** rebuild depuis le listener, qui est hors phase de build.

Tests : un cas neuf dans `student_charges_step_permission_read_test.dart` —
créances à l'écran, droit retiré en séance, le corps doit recevoir le droit
courant. Il mesure le **prop** reçu et non un pixel, puisqu'aucun pixel ne bouge
: c'est le contrat qui est en jeu. Écrit rouge d'abord (il reproduit le défaut),
vérifié par mutation ensuite.

---

### ~~M-5 + M-6 · Le vivier de préinscriptions : une garde qui n'a jamais gardé, et une purge qui court contre le pull~~ — corrigés

Traités ensemble parce que le premier **arme** le second : tant que la garde ne
purgeait qu'au changement d'école constaté, la course de M-6 ne concernait
qu'une tablette réaffectée ; depuis M-5 elle purge aussi sur marqueur absent,
c'est-à-dire au premier démarrage de **tout le parc** après ce lot. Corriger M-5
seul aurait donc généralisé la fenêtre de M-6.

**M-5 — l'absence n'est pas la continuité.** Rien n'amorce
`kPreEnrollmentsSchoolResource` : la première session prenait toujours le chemin
« rien à comparer, rien à purger » et **adoptait** le disque. Or la première
session est aussi celle qui suit la mise à jour — la seule que voit une tablette
réaffectée avant que cette garde n'existe. Les candidats de l'école A restaient
lisibles par B pour toujours : ni `searchPreEnrollmentCandidates` ni
`findPreEnrollmentById` n'ont de prédicat `school_id`, faute de colonne. Le
marqueur répond désormais à **trois** choses et non deux — même école (on
garde), autre école (on purge), **inconnue (on purge)** — comme le tri-état des
permissions et celui du plan de synchro. Prix : un rebootstrap unique par
tablette ; nul sur une installation neuve, où la table est déjà vide.

**M-6 — deux `unawaited` n'ordonnent rien.** La garde et `syncOnLogin()`
partaient l'un sous l'autre, et le commentaire affirmait un ordre que le code
n'établissait pas. La purge étant en deux temps — vider la table, puis
rembobiner le curseur — un cycle de préinscriptions qui insère ses lignes juste
avant le premier et écrit son curseur keyset juste après le second laisse
exactement ce que la garde existe à interdire : **une table vide derrière un
curseur avancé**. Le serveur répond « rien de neuf » indéfiniment, et
`ref_pre_enrollments` étant la seule source d'amorçage d'un brouillon PRE, ces
préinscriptions ne reviennent jamais. Les deux gestes sont maintenant une
**séquence** — `_guardPreEnrollmentsSchoolThenSync()` — elle-même lancée en
`unawaited` : ce qui est ordonné, c'est la paire, pas son rapport à l'écran. La
porte de navigation ne dépend toujours que du contexte académique.

⚠️ **La docstring qui disait « l'ordre inverse ne serait pas faux pour autant »
a été retirée** — c'est elle qui a laissé passer le défaut. Son raisonnement («
la purge rembobine tout le flux, une page arrivée trop tôt redescend ») vaut
pour un pull qui a fini, pas pour un pull qui s'entrelace.

Tests. Côté garde : le test « première session → aucune purge » est **inversé**
(avec la note qui dit pourquoi), plus deux cas neufs — le rebootstrap ne se
répète pas à la session suivante, et sur une base vierge la purge ne coûte rien.
Côté ordre, un test **de source** (`test/core/session/`) : le motif
`unawaited(syncOnLogin())` ne doit pas revenir, la garde doit précéder le cycle,
et le cycle n'être appelé qu'une fois. Le dépôt a le même genre de garde-fou
pour le manifeste Android — la panne ne se voit qu'en production, et un test qui
tenterait de reproduire l'entrelacement échouerait une fois sur mille. **C'est
une garantie structurelle, pas comportementale, et c'est assumé.** Les deux lots
sont vérifiés par mutation.

---

### ~~H-4 · Une fiche ouverte depuis une recherche par identité n'affiche aucun détail~~ — corrigé

Signalé à l'usage, hors revue. La chaîne, entière, tenait à une condition de
trop :

1. le formulaire bi-mode arme la recherche sur « les **trois noms** ou un niveau
   » — en mode identité, aucun niveau n'est choisi, donc `schoolLevelId` part
   vide ;
2. `facturation_student_table.dart` lit le niveau de la ligne dans… **les
   derniers critères de recherche** (`lastSummariesQuery.schoolLevelId`) — vide,
   donc, dans ce mode ;
3. `facturation_page.dart` cherche le nom du niveau dans le référentiel avec cet
   id vide : aucun `levelName`, aucun `levelGroupName` dans l'intent ;
4. `FacturationDetailIntent.hasDisplayContext` exigeait **les deux** en plus de
   l'identité ;
5. la page rendait `FinanceContextErrorCard` **à la place** du chargeur : ni
   frais, ni versements, ni totaux — pour un élève dont on connaissait
   parfaitement le nom.

La classe ne sert qu'au sur-titre « Facturation · {classe} ». Le grand-livre,
lui, ne se lit qu'avec `studentId` + `academicYearId`. La condition a donc été
ramenée à ce qu'elle protège réellement — `hasStudentIdentity` : **on n'affiche
pas un solde sans pouvoir dire à qui il appartient**, et rien de plus. Un lien
profond sans `extra` (le vrai cas sans contexte) garde la carte d'erreur.

⚠️ **Ce n'est pas une invention locale : les deux modules voisins avaient déjà
tranché ainsi.** `DisciplinaryStudentDetailIntent` porte niveau, cycle et
classe, et n'exige que les noms. Le catalogue Documents l'écrit en toutes
lettres — la classe est « du contexte d'affichage, jamais une condition
d'ouverture » — et vit très bien avec un sur-titre vide après une recherche par
nom. Facturation était le seul des trois à en faire une porte.

Les **trois intents frères** (détail d'un frais, détail d'un versement,
encaissement) portaient la même condition class-inclusive. Aucun n'était lu —
getters morts — mais les laisser ainsi, c'était laisser trois mines : la
première modale qu'on y câblerait aurait refait la panne au-dessus d'une ligne
parfaitement identifiée. Alignés sur la même règle, identifiant de ligne compris
(un frais sans `chargeId` n'a toujours rien à afficher).

⚠️ **Ce qui n'est PAS corrigé, et qui est un choix** : le sur-titre affiche «
Facturation · - » après une recherche par identité, faute de classe à mettre. La
corriger vraiment demanderait de porter le niveau **par ligne** — projection du
DAO (`e.school_level_id`, `e.school_level_group_id` ne sont pas dans le
`SELECT`), `LocalEnrollmentListItem`, `EnrollmentSummary`, puis la table — pour
un sur-titre. Documents vit avec le même « - » depuis son lot. À rouvrir si
l'usage le réclame ; une variante moins chère existe (dériver la classe des
créances déjà chargées, qui portent `schoolLevelId`), au prix d'un sur-titre qui
se remplit un instant après l'ouverture.

Tests : deux au niveau **page** — la fiche issue d'une recherche par identité
rend bien ses deux sections, et la contre-épreuve du lien profond sans identité
garde la carte d'erreur — plus cinq unitaires qui figent la règle sur les quatre
intents. Le test de page a d'abord été écrit **rouge** : il reproduit la panne
signalée avant de la corriger. Vérifié par mutation (la classe remise dans la
condition fait rougir le cas nominal).

---

### ~~M-1 · Un 403 transitoire sur `/sync/plan` gèle le repli pour la session~~ — corrigé

`sync_plan_holder.dart` — `_resolve()` ne mémorise plus comme **frais** tout ce
qui ne lui revient pas en `null`. Deux questions avaient été confondues : « la
jambe réseau a-t-elle abouti ? », à laquelle `refreshFromNetwork` répond, et «
relire y changerait-il quelque chose ? », qui seule autorise à éteindre le
drapeau. Le refus (401/403), l'uid pas encore posé et le plan d'un autre sujet
répondent oui à la première et non à la seconde : ils reviennent en état, et
étaient donc tenus pour définitifs. Comme `markStale()` n'a qu'un déclencheur —
un vrai changement d'ensemble de droits — un seul 403 rendait la main à
`requiredPermissions` **jusqu'au prochain login**, derrière une pastille verte.

La liste des verdicts vit désormais sur `SyncPlanUnknownCause.isVerdict`, à côté
des causes qu'elle trie, et nulle part ailleurs. Elle en compte **deux** :
`notDeployed` (la route n'apparaîtra pas d'ici le cycle suivant) et
`unsupportedStreams` (le serveur rendra le même corps tant que l'APK n'aura pas
appris son vocabulaire). Les deux `switch` — celui de l'extension, celui du
porteur — sont exhaustifs et sans `_` : une huitième cause casse la compilation
au lieu de tomber du côté « définitif », celui où l'erreur ne se manifeste plus
jamais.

⚠️ **Le partage `null` / état du repository n'a PAS bougé**, et il ne fallait
pas le faire bouger : un 401/403 ne consulte toujours pas le cache — il vient du
même serveur et ne démentirait rien — et le cycle en cours retombe donc sur le
registre en dur. Ce que le correctif change est la **durée** : un cycle au lieu
d'une session. Le coût est un `GET /sync/plan` par cycle tant que l'anomalie
dure, déjà borné par la sonde `_canAuthenticate()` du coordinateur, qui empêche
de lire le plan sans jetons utilisables.

`isDegraded` n'a pas été touché : la pastille ne s'alarme toujours que
d'`unsupportedStreams`. Un refus transitoire n'a plus à être signalé puisqu'il
ne dure plus, et compter `notDeployed` ou `absent` mettrait tout le parc en
alerte permanente avant déploiement du plan.

Tests : trois cas paramétrés (`unauthorized`, `absent`, `foreignSubject`) qui
vérifient le drapeau levé **puis que le cycle suivant relit vraiment** — c'est
là qu'est le défaut, pas dans l'état rendu ; une contre-épreuve
`unsupportedStreams` sans laquelle « ne plus rien tenir pour définitif »
passerait ; et la liste des verdicts figée sur `values`. Vérifié par mutation
dans les deux sens : rétablir `fresh: true` fait rougir les trois cas
paramétrés, retirer `unsupportedStreams` de la liste fait rougir la
contre-épreuve.

---

### ~~M-2 + M-3 · La Facturation confond « droit refusé » et « droits pas encore lus »~~ — corrigés

Traités ensemble parce que c'est **un seul défaut à deux moitiés** : la moitié
qui se tait (M-2, trois écrans) et la moitié qui ne demande rien (M-3, le
chargeur). Corriger l'une seule aurait aggravé l'autre — une section rouverte
au-dessus d'un BLoC resté `initial` affiche « Aucun versement enregistré », qui
est précisément la phrase que la carte « relève de la caisse » existait à
éviter.

**La règle, désormais tenue aux quatre sites :** on ne se tait, et on ne renonce
à lire, que sur `missing` — quand on **sait** que le droit manque. Une lecture
tentée à tort coûte un 403, rendu en état d'erreur avec « Réessayer » ; une
lecture omise à tort ment, sur l'écran même où un caissier décide s'il faut
encaisser. C'est la même asymétrie que le socle de synchro, qui tire sur
inconnu.

`permission_holding.dart` gagne les deux pièces qui manquaient à la matrice :

| Deux états | Trois états |
|---|---|---|
| **Abonné** | `PermissionGate` (une garde doit fermer sur inconnu) | `PermissionHoldingBuilder` *(nouveau)* |
| **Ponctuel** | `PermissionGate.allows` | `permissionHolding` / `permissionHoldingOf` *(nouveau)* |

`permissionHoldingOf` est la règle sans arbre, pour les appelants qui tiennent
déjà l'état de session — un `buildWhen`, un `listenWhen`, un `State` qui décide
d'émettre. Sans elle, chacun réécrivait « inconnu ne vaut pas refusé » pour son
compte, et c'est exactement la divergence qui a produit le défaut.

⚠️ **L'abonnement n'est pas un luxe, c'est l'autre moitié.** Le tri-état lu une
seule fois dans un `build` extérieur fige son verdict pour la vie de l'écran :
rien ne reconstruit la section Versements quand les permissions arrivent en
séance. Le `buildWhen` et le `listenWhen` comparent la **décision**, jamais les
ensembles — un droit qui bouge ailleurs dans le catalogue ne reconstruit ni ne
relit rien, et la comparaison n'a pas à se prononcer sur les doublons d'une
liste (cf. B-3, qui reste ouvert sur `PermissionGate._sameSet`).

Côté chargeur, la lecture de rattrapage ne redemande **que** les versements —
les créances sont déjà à l'écran, et les relire ferait clignoter une donnée
intacte — et elle n'est **pas** silencieuse : il n'y a rien à préserver, un
skeleton dit honnêtement qu'on est allé chercher. Un drapeau
`_paymentsRequested` empêche le doublon, et retombe quand le droit se retire,
pour qu'un élargissement ultérieur reparte d'une vraie lecture plutôt que d'une
donnée d'avant.

Tests : `facturation_permissions_unknown_test.dart`, 11 cas — les quatre sites
sur ensemble inconnu, les deux sens de bascule en séance (le droit qui arrive
rouvre et relit, celui qui se retire referme), la non-relecture sur un
changement qui ne change pas la décision, et deux contre-épreuves « sans le
droit, on se tait toujours ». Vérifié par mutation sur les cinq sites de
décision : chacun, remis en deux états, fait rougir au moins un cas.

⚠️ **Piège de test rencontré** : les sections traversent un `AnimatedSwitcher`.
Sans `pumpAndSettle`, l'ancien enfant est encore à l'arbre et un `findsNothing`
échoue sur une carte en train de disparaître — ce qui ressemble trait pour trait
à un abonnement qui n'a pas fonctionné.

---

### ~~M-4 · Une lecture de tarifs en échec est rendue « aucun frais défini pour ce niveau »~~ — corrigé

`tariffsStatus: failure` était calculé, stocké, et lu par **personne** :
`fee_control_page.dart` ne transmettait que `isTariffsLoading` et
`feeGridMissing`, si bien qu'une base SQLCipher verrouillée tombait dans le
dernier `else` du sélecteur et annonçait « Aucun frais n'est défini pour ce
niveau ». C'est une affirmation sur **l'école** là où seule la lecture de
**l'appareil** avait échoué — et comme le frais est obligatoire dans ce module,
la recherche restait fermée sans que rien n'explique pourquoi.

Le sélecteur distingue désormais **trois** causes d'une liste vide, au lieu de
deux :

| Cause | Ce qu'on affiche | Se répare en |
|---|---|---|
| Ce niveau n'a pas de frais | information | rien — il n'y a rien à contrôler |
| Grille pas descendue / caviardée | « synchronisez » ou « votre administrateur peut ouvrir cet accès » | une synchro, ou un droit |
| **Lecture en échec** *(nouveau)* | « la liste des frais n'a pas pu être lue sur cet appareil » | **réessayer** |

L'échec passe **en tête** de la cascade : les deux autres messages affirment
quelque chose sur l'école ou sur la synchronisation, et une lecture qui n'a pas
abouti n'autorise ni l'une ni l'autre.

Le bouton « Réessayer » n'apparaît que pour cette cause-là — les deux autres ne
se réparent pas en réessayant, et l'offrir y promettrait une issue qui n'existe
pas. Il rejoue les **deux** lectures locales du niveau courant en passant par
`onLevelSelected`, le canal existant : une base qui refuse la grille refuse en
général aussi le roster, et un canal de reprise dédié aurait fini par diverger
de celui-là. La sélection n'est pas remise à zéro, contrairement à un vrai
changement de niveau — le niveau n'a pas changé.

⚠️ **Écart assumé avec la consigne d'origine de cette fiche** (« lui donner son
propre état d'erreur, règle non-négociable #10 : `EteeloErrorResult` »). La
règle #10 vise les **zones de résultats** ; ici l'erreur naît dans un **champ de
formulaire**. `EteeloErrorResult` a une anatomie de carte pleine — médaillon,
titre, `minHeight: 380` — qu'il aurait fallu vider de sa substance pour la loger
entre deux sélecteurs, ce qui ruine précisément l'« anatomie unique » que la
règle protège. On garde donc le vocabulaire du champ (`errorText`, comme les
deux autres causes, et comme le sélecteur de classe voisin) en lui ajoutant ce
qui manquait vraiment : un geste de reprise. À rediscuter si la revue préfère la
lettre de la règle à son intention.

⚠️ Le bouton est un `EteeloButton.ghost(fullWidth: false)`, **jamais** un
`TextButton`/`OutlinedButton` nu : le thème du dépôt les veut pleine largeur, et
un bouton inline sans `minimumSize` casse la mise en page sur contrainte infinie
(piège déjà rencontré, cf. le mémo dédié).

Tests : trois cas dans `fee_control_search_form_test.dart` — l'échec dit l'échec
et jamais « aucun frais », la reprise rejoue la lecture du **même** niveau (les
deux appels sont capturés et comparés), et une contre-épreuve « grille absente ⇒
pas de bouton ». Vérifié par mutation : neutraliser la branche d'échec, puis
neutraliser la reprise, font rougir chacune leur cas.

---

### ~~#13 · L'anti-rafale de reprise n'est pas monotone~~ — corrigé (`5123439`)

`lib/core/components/status/sync_status_cubit.dart` — l'horloge est celle du
device, donc reculable : un NTP corrigeant une dérive de RTC laissait
`_lastCycleAtMs` dans le futur, l'écart devenait négatif et le déclencheur de
reprise ne repartait plus jamais en cycle complet. Un écart négatif prend
désormais le chemin long, avec test de régression vérifié par mutation.

---

## Vérifié sain par la revue

L'escalier de migration v27 (bornes `upTo`, DDL v9 inliné, plus aucune lecture
du schéma vivant sur une table retirée, `UPDATE students` gardé), le câblage DI
de `credentialsProbe` / `permissions` / `planHolder` sur `PullCoordinator`,
l'arithmétique en centimes du contrôle des frais et la jointure `fee_code` par
lots de 500, `ClientSidePaginator`, `PullSequencer`, la table d'alias des 18
clés, `leaveWizardToListing` / `onDetailReturned`, `SyncStateIcon` (null vs
DRAFT), et l'observateur de reprise du lot 1.




* Dans le module Finance les resultats issus d'une recherche par identité de l'élève n'affiche pas le détail





* Retravailler les Formulaires pour : 
- ~~Inclure la version des switch~~ — FAIT : `BiModeSearchForm` et
  `FirstRegistrationSearchForm` passent sur une bascule exclusive
  (`SearchModeSwitch`, classe puis identité). Le « OU », les badges de mode et
  la disposition à deux colonnes sont supprimés. Résultats garde sa propre
  bascule : ses deux modes sont additifs (le mode élève a besoin de la classe et
  de la période).
- ~~Inclure le formattage des champs~~ — FAIT : la capitalisation est le défaut
  d'`EteeloTextInput` (mot par mot / phrase, résolue sur le type de clavier),
  l'exception se déclare. Formatters promus dans `lib/core/formatters/`.
- Inclure la recherche interactive — ANALYSÉ, pas ouvert :
  `RECHERCHE_INTERACTIVE_PLAN.md` (7 lots, 9-12 j, décisions verrouillées).
  ⚠ Le fait déterminant : le SQL ne filtre JAMAIS sur un nom — tout le
  filtrage par nom est en Dart, sur la totalité des inscriptions de l'année,
  rejouée à chaque frappe. Le plan attaque par là (corpus chaud), pas par
  l'UI.
======== Exception caught by rendering library ===================================================== The following
assertion was thrown during layout:
A RenderFlex overflowed by 62 pixels on the bottom.

The relevant error-causing widget was:
Column Column:file:///home/junethink/my_project/school_app_flutter/lib/core/components/skeletons/eteelo_list_skeleton.dart:73:18
