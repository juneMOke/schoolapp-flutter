# Backlog de revue — branche `feature/auth_permissions`

Sortie de la revue `/code-review high` du **2026-08-19**, portée sur les 38 commits non poussés de la branche (233
fichiers) plus l'arbre de travail.
`flutter analyze` propre, **3621 tests verts** au moment de la revue.

Quinze défauts confirmés, plus quatre issus de la revue adversariale du battement. **Neuf sont corrigés** — le #13
(commit `5123439`), puis H-2, H-3, H-1, M-8, M-1, M-2 et M-3 ensemble, et M-4 ; **plus aucun défaut « haut » n'est
ouvert**. **Douze restent ouverts** et sont listés ici (B-9 compris, ouvert hors revue par la passe « clavier ») ;
aucun n'est traité.

S'y ajoute **B-9**, ouvert par la passe « clavier » du 2026-08-19 — celle qui a fermé les débordements de la connexion,
de l'encaissement, des deux modales de discipline et de la recherche de parent.

S'y ajoutait **H-4**, hors revue : signalé à l'usage le 2026-08-20 — en Facturation, un élève trouvé par
**recherche d'identité** ouvrait une fiche vide, « contexte de détail indisponible » à la place du
grand-livre. Un mode de recherche entier était inexploitable sur l'écran de caisse : **corrigé** (voir
« Traité »).

S'y ajoutait **M-8**, hors revue : constaté à l'usage le 2026-08-19 — le détail d'un élève en Facturation attendait le
réseau avant d'afficher un grand-livre déjà présent en base. Seul défaut du lot à se manifester dans le chemin
**nominal**, à chaque ouverture de fiche : **corrigé** (voir « Traité »).

> Ordre : gravité décroissante. Un défaut « haut » a une conséquence métier
> directe et irréversible sans intervention ; un « moyen » dégrade une décision
> ou un affichage ; un « bas » attend un appelant qui n'existe pas encore, ou ne
> se manifeste que sur une transition rare.

---

## 🟠 Moyen

### M-5 · La garde d'école des préinscriptions est inopérante au premier démarrage

`lib/features/enrollment/offline/data/local/pre_enrollments_school_guard.dart:103`

Rien n'amorce `kPreEnrollmentsSchoolResource` : la première session après mise à jour prend donc toujours le chemin «
rien à purger » et **adopte** ce qui est sur le disque. Une tablette qui portait le vivier de l'école A, réaffectée à B,
garde les candidats de A indéfiniment — `searchPreEnrollmentCandidates` et
`findPreEnrollmentById` n'ont aucun prédicat `school_id` (la colonne n'existe pas), donc le guichet de B peut lister et
amorcer des brouillons depuis les lignes de A.

Un vivier non attribuable est le cas « fermé par défaut » que la docstring de la classe défend elle-même.

**À faire** — traiter le marqueur absent comme « inconnu ⇒ purger ».

---

### M-6 · La garde de préinscriptions court contre le cycle de login

`lib/main.dart:182`

La garde et `syncOnLogin()` sont toutes deux en `unawaited`, alors que le commentaire affirme un ordre (« AVANT le
cycle »). Si l'insert +
`setCursor` du pull des préinscriptions atterrit entre le
`deleteAllPreEnrollments()` et le `deleteCursorsOf` de la garde, les lignes fraîchement tirées sont effacées **derrière
un curseur keyset avancé** : le serveur répond « rien de neuf » pour toujours et ces préinscriptions deviennent
inatteignables, `ref_pre_enrollments` étant désormais la seule source d'amorçage.

Fenêtre étroite (SQLite local contre mint + flush + révocation + deux pulls réseau), mais elle n'existait pas avant ce
PR.

**À faire** — `await` la garde avant de lancer le cycle.

---

### M-7 · Le verrou de tarifs mute sans reconstruire

`lib/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart:130` (listener l. 332)

`_syncTariffsWithheld` compte sur `_recomputeFormState` pour appeler `setState`, et `tariffsWithheld` n'entre dans ce
calcul que via
`blocked = (tariffsWithheld || feeGridUnavailable) && _studentCharges.isEmpty` — donc sans effet dès que les créances
sont chargées, c'est-à-dire dans le cas normal. Une perte de `finance.grid.read` en cours de session laisse les montants
de tarifs à l'écran jusqu'à la fin. Les deux widgets frères touchés par le même commit, eux, reconstruisent
inconditionnellement.

**À faire** — reconstruire sur le changement de droit, comme les frères.

---

## 🟡 Bas

### B-1 · `PullCycleGuard.run<T>` fait un transtypage aveugle

`lib/core/offline/pull_cycle_guard.dart:65` (et l. 84)

`run<T>` agrège un appelant qui arrive sur la future déjà programmée et la transtype en `T`. Or
`PullCoordinator.guarded()` expose publiquement le verrou avec `T = void` pour les appelants qui tirent hors
coordinateur, quand les handlers l'utilisent avec `T = PullOutcome`. Deux `guarded('enrollments', …)`
suivis du cycle du coordinateur sur la même ressource lui rendent la future
`void` : `null as PullOutcome` lève, le `catch` du coordinateur compte un échec, et `handler.pull()` ne tourne jamais.

Aucun appelant ne l'exerce aujourd'hui — l'API est neuve dans ce PR.

**À faire** — séparer les deux usages, ou rendre le verrou non générique.

---

### B-2 · Les drapeaux de lecture dégradée survivent au logout

`lib/core/components/status/sync_status_cubit.dart:80`

Le cubit est app-lifetime et `_pullDegraded` / `_pullRetriable` ne sont réécrits que par un cycle qui a réellement
observé quelque chose. Le compte A pose les drapeaux sur un cycle `forbidden > 0`, A se déconnecte, B se connecte et son
`syncNow()` s'arrête tôt (hors ligne, sans jetons, mint refusé) : **B porte la pastille « Partiellement à jour » de A**,
sans cycle à lui pour la corriger — et sur la tablette en Wi-Fi permanent que ce chantier vise, la transition réseau qui
rattraperait n'arrive jamais.

**À faire** — les remettre à zéro là où `CurrentPermissions.clear()` et
`SyncPlanHolder.clear()` sont déjà appelés.

---

### B-3 · `_sameSet` accepte un doublon comme égal

`lib/core/auth/current_permissions.dart:105`

`_sameSet(['a','a'], ['a','b'])` rend `true` : les longueurs concordent et chaque élément du premier est dans le second.
Un refresh livrant le second après le premier ne notifierait donc pas, `SyncPlanHolder` ne serait jamais marqué périmé,
et le plan d'avant le changement continuerait de gouverner le périmètre de pull jusqu'au logout.

**À faire** — comparer `a.toSet()` à `b.toSet()`.

---

### B-4 · La recherche par niveau n'a pas d'état « inscriptions pas encore synchronisées »

`lib/features/finance/presentation/widgets/fee_control_results_view.dart:161`

`feeControlEmptyNoLocalEnrollment` n'est atteignable que si
`lastQuery.classroomId != null`. Sur « toutes les classes du niveau », une tablette fraîchement hydratée dont le pull
Inscription n'a pas atterri tombe sur « Aucun élève ne correspond à ces critères. Modifiez le formulaire » — on envoie
l'opérateur corriger des critères qui n'y peuvent rien.

**À faire** — rendre l'état atteignable sur les deux formes de recherche.

---

## 🟡 Bas — issu de la passe « clavier » (2026-08-19)

### B-9 · Sept modales de lecture n'ont pas reçu la coquille sûre au clavier

`lib/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart:277`
`lib/features/finance/presentation/widgets/facturation_charge_detail_dialog.dart:136`
`lib/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart:176`
`lib/features/documents/presentation/widgets/editique_document_dialog.dart:359`
`lib/features/academics/presentation/widgets/detail/cours_releve_modal.dart:40`
`lib/features/classes/presentation/widgets/classes_organisation_distribution_result_dialog.dart:129`
`lib/features/classes/presentation/widgets/classes_organisation_reassign_dialog.dart:101`

Ces modales partagent la forme qui débordait ailleurs — en-tête et pied ancrés autour d'un corps défilant — mais
**aucune ne porte de champ de saisie** : le clavier ne monte pas devant elles, et aucun débordement n'y a été constaté.
La passe les a donc laissées en l'état plutôt que d'ouvrir un large diff sur des écrans d'argent sans défaut prouvé
(arbitrage explicite du 2026-08-19).

Elles restent exposées à un seul scénario : s'ouvrir alors que le clavier est **déjà** monté sur l'écran d'en dessous.

**À faire** — les faire passer par `EteeloDialogBody`
(`lib/core/components/dialogs/eteelo_dialog_body.dart`) le jour où l'une d'elles gagne un champ, ou si le scénario
ci-dessus se manifeste. Le seuil
`minPinnedHeight` se règle au-dessus de la hauteur incompressible de l'en-tête et du pied — c'est elle qui déborde.

⚠️ Ne pas confondre avec le plafond `MediaQuery.sizeOf(context).height * 0.88`
que ces fichiers calculent : il n'a jamais été la cause. `ConstrainedBox` borne déjà ses propres contraintes à celles du
parent (`BoxConstraints.enforce`), donc un plafond trop haut est inoffensif. Ce qui déborde, ce sont les zones
**figées**
quand la hauteur offerte passe sous leur hauteur cumulée.

---

## 🟡 Bas — issus de la revue adversariale du battement (2026-08-19)

### B-5 · La feuille de synchro fige des drapeaux qu'un timer peut désormais changer

`lib/core/components/status/sync_errors_sheet.dart:35`

La feuille capture `hasIncompleteRead` / `hasRetriableRead` à l'ouverture, sur la prémisse écrite qu'ils « ne peuvent de
toute façon pas changer utilement le temps d'une modale ouverte ». Le cycle complet du battement invalide cette
prémisse :
un tic peut lever la dégradation pendant que la feuille l'affiche (« Réessayer » brûle alors un cycle de dix-neuf
ressources pour rien), ou l'introduire alors que la feuille n'offre plus aucun bandeau ni geste. Même nature pour
`OutboxErrorsCubit`, chargé une fois sans abonnement à la fin de flush : un flush du battement peut acquitter et
supprimer une ligne que la feuille liste encore, et `requeue` ne touchant que les `SYNC_ERROR`, le tap devient un no-op
muet.

**À faire** — abonner la feuille à l'état du cubit plutôt que de le photographier.

---

### B-6 · Chaque tic productif redéchiffre la session complète trois à quatre fois

`lib/core/components/status/sync_status_cubit.dart` (chemin de push)

`TokenStorageService.readAuthSession()` enchaîne 13 `_storage.read()`, chacun un aller-retour MethodChannel plus un
déchiffrement Keystore. Un tic avec du travail prêt les paie quatre fois : `_canAuthenticate()`, `_ensureFreshAccess()`,
la propre garde de `SyncEngine.flush()`, puis `refresh()` — soit ~52 déchiffrements toutes les 45 s. Le coût préexistait
à chaque cycle ; le battement en fait une cadence.

**À faire** — une lecture unique passée à la sonde, au ré-authentificateur et à la garde du moteur, ou une mémo à TTL
court dans `AuthSessionManager`.

---

### B-7 · L'état de cycle de vie initial est supposé, jamais lu

`lib/core/components/status/sync_lifecycle_observer.dart:57`

Le binding ne notifie que des *transitions* : un observateur monté alors que l'application est déjà hors écran n'en
verra jamais aucune, et le battement tournerait en se croyant au premier plan. Sur la cible (tablette Android, une seule
activité LAUNCHER, ni service ni receiver) le cas est inatteignable — le battement ne s'arme qu'à l'ouverture de
session, qui exige un écran. Sur bureau ou web il ne l'est pas.

Une lecture de `WidgetsBinding.instance.lifecycleState` en `initState` fermerait le trou, mais **elle n'est pas
observable sous `testWidgets`** (le binding rapporte bien l'état depuis le corps du test, jamais depuis `initState`) :
elle a été retirée plutôt que laissée non prouvée.

**À faire** — si le périmètre s'étend au bureau/web, trouver un harnais qui l'observe avant de la remettre.

---

### B-8 · `sync_status_cubit.dart` dépasse largement la cible de taille

420 lignes avant ces trois lots, **670 après** — contre une cible de ~250 (CLAUDE.md, règle non-négociable n°7).
L'extraction de `SyncHeartbeat` n'a sorti que la cadence ; le corps de cycle (`syncNow`, `_syncOnReconnect`, les trois
gardes, les estampilles) reste entier.

**À faire** — extraire un `SyncCycleRunner` qui porte le corps de cycle et ses gardes, laissant au cubit la seule
projection d'état. Refonte de code préexistant : à faire à froid, pas en fin de lot.

---

## ✅ Traité

Douze défauts de la revue adversariale du battement ont été corrigés dans la foulée (garde `isFlushing` avant le cycle
complet, garde hors-ligne en tête de tic, push muet, séparation tentative/pull, révocation non évaluée par le timer,
`inactive` neutre, seuil de poison du moteur, fermeture de session sur toute issue non authentifiée, renoncement
coopératif, câblage racine testé, verrou de réentrance testé, prémisses périmées réécrites) — tous vérifiés par
mutation.

### ~~H-1 · Le champ « Prénom » de la recherche de parent est intapable~~ — corrigé

`parent_search_dialog.dart` — le bloc de critères porte une `GlobalKey`
(`_searchFormKey`, via `KeyedSubtree`) : la bascule `pinsForm` le **reparente**
au lieu de le détruire, donc les `FocusNode` que chaque `EteeloTextInput` se crée — et dispose — survivent au passage.
Le focus reste, le clavier ne se referme pas, la bascule ne repart pas en sens inverse.

Le seuil n'a **pas** été touché : le calculer sur une hauteur sans les inserts de clavier rouvrirait le débordement que
la bascule existe à fermer (téléphone en paysage, ~100 dp restants pour un en-tête et des critères qui en coûtent trois
fois plus).

⚠️ **Pourquoi les deux tests clavier existants ne l'ont jamais vu** : ils mesurent deux dispositions **statiques**,
chacune à sa taille de surface, alors que la panne est dans la **transition**. Les deux tests ajoutés ouvrent le clavier
(`tester.view.viewInsets`) sur un champ **déjà focalisé**, dans les deux sens, et vérifient d'abord que la bascule a
bien eu lieu — sans quoi ils seraient vides — puis que le `FocusNode` est le **même objet**. Sans la clé, l'assertion
rougit sur un élément `DEFUNCT`.

---

### ~~H-2 · Un flux rejeté au parsing désarme l'arête créances → paiements~~ — corrigé

`lib/core/offline/pull_coordinator.dart` — les clés écartées à l'analyse amorcent `unusableResources` **avant la
boucle**, converties en ressources par
`resourcesOf`. Un `mode` neuf déployé sur `finance.student-charges` fait donc renoncer aux paiements au lieu de les
poser sur un `amount_paid_in_cents`
périmé. Amorçage pris sur le PLAN et non sur la sélection du cycle : un
`pullSubset` de la seule ressource paiements — le chemin de l'écran de Facturation — renonce lui aussi, puisque l'amont
ne sera rafraîchi par aucun cycle. Trois tests, dont une contre-épreuve (une clé écartée qui n'est l'amont de rien ne
bloque personne) ; l'amorçage retiré fait rougir les deux premiers.

---

### ~~H-3 · « Le client n'a rien compris » est classé « rien à tirer »~~ — corrigé

`sync_plan_parser.dart` mesure désormais `allStreamsDropped` — le serveur a annoncé des flux, ce client n'en a retenu
aucun — et le repository le traduit en
`SyncPlanUnknownCause.unsupportedStreams`, donc en repli sur le registre. Le corps n'est plus mis en cache (la garde
`state is! SyncPlanUnknown` couvrait déjà le cas dès qu'il change de famille), donc la panne ne survit plus au
redémarrage. C'est un **verdict** et non un incident : `refreshFromNetwork` le rend en état, contrairement au corps
illisible, parce qu'une nouvelle tentative rendrait le même corps tant que l'APK n'a pas appris ce vocabulaire.

Le drapeau est mesuré sur la liste **brute**, pas sur `rejectedKeys` : une entrée sautée faute de `key` ne peut pas être
nommée dans la trace, et laisse pourtant la tablette sans rien à tirer. Le déduire des seules clés écartées laissait ce
corps-là retomber sur « rien à tirer ».

⚠️ **Conséquence à ne pas défaire** : `SyncPlanEmpty` ne porte plus de
`rejectedKeys`, et le test du coordinateur qui les y vérifiait a été retiré. Ce champ avait été ajouté par la revue
adversariale de F5/F9 pour nommer les clés fautives d'un plan « vide parce que tout a été écarté » — un état que ce lot
supprime à la source. Le nommer était le lot de consolation d'un parc à l'arrêt ; il tire, désormais. La garantie a
déménagé dans
`sync_plan_repository_impl_test.dart`, groupe « TOUS les flux écartés → INCONNU, jamais vide ».

---

### ~~M-8 · Le détail d'un élève attend le réseau avant de servir le grand-livre local~~ — corrigé

Les deux repos offline-first (`student_charges_offline_first_repository.dart`,
`payments_offline_first_repository.dart`) **lancent** le rafraîchissement ciblé sans l'attendre, et servent le DAO
immédiatement. Ce qui était lent était le réseau, jamais la base : le skeleton tenait jusqu'à ~22 s en réseau dégradé
pour afficher des lignes déjà en local.

L'attente n'a pas été supprimée, elle a **déménagé** là où
`FACTURATION_OFFLINE_PLAN.md` §13 la plaçait — devant l' **encaissement**, où le « reste » composé borne la saisie et
décide s'il faut encaisser. Sous-estimé parce qu'un versement du poste voisin n'est pas descendu, il fait réencaisser.
`runFacturationCollectPreflight` (nouveau) la tient au tap « Encaisser », derrière une barrière qui n'apparaît
qu'au-delà de 220 ms — la plupart des taps n'attendent rien, et une modale ouverte puis refermée en 20 ms se lit comme
un bug. Une relecture en échec **n'y ferme jamais le guichet** : on retombe sur l'affichage courant plutôt que de
refuser une famille qui a l'argent en main.

Trois bornes, et il faut les trois :

| Borne                             | Valeur | Ce qu'elle empêche                                               |
|-----------------------------------|--------|------------------------------------------------------------------|
| TTL de lecture (`readMaxAge`)     | 120 s  | Chaque (ré)ouverture de fiche rejouait tout le cycle             |
| Fraîcheur exigée à l'encaissement | 15 s   | Une rafale d'encaissements repayait l'aller-retour à chaque fois |
| Plafond de l'attente visible      | 4 s    | On ne remplace pas un blocage de 22 s par un blocage indéfini    |

Le TTL n'est posé que sur un cycle **abouti** : un cycle en échec ne s'amortit pas, sinon un réseau qui retombe gèlerait
la fiche jusqu'au délai suivant.

⚠️ **La borne d'attente vit chez l'APPELANT** (`refresh(..., deadline:)`), pas dans `_refreshCharges`. Y poser un
timeout retirerait l'entrée in-flight pendant que la pagination tourne encore, et un second cycle concurrent partirait
sur le même élève. Passé le délai, le cycle n'est **pas annulé** : il poursuit en fond et annoncera son aboutissement.

⚠️ **Ne pas retirer le signal `FinanceLedgerRefresher.revalidated`** en croyant simplifier. C'est la contrepartie exacte
de l'`await` supprimé : sur une tablette dont la base est encore vide, l'écran afficherait « Aucun frais » et n'en
sortirait pas de la visite. La relecture qu'il déclenche est **silencieuse**
(drapeau `silent` sur les deux events) — pas de retour en `loading`, et son échec ne détruit pas ce qui est affiché. Les
états étant `Equatable`, un cycle qui ne change rien ne reconstruit rien. La légende de fraîcheur s'y abonne aussi :
sans ça elle resterait figée sur l'ancienne heure quand le grand-livre n'a pas bougé.

Les deux lectures passent en `transformer: _sequential()` : le traitement concurrent par défaut laissait une relecture
silencieuse rendre **avant** la lecture initiale et se faire écraser par un résultat plus ancien.

Tests : la non-régression qui compte est un seam de rafraîchissement qui ne rend **jamais** la main, et une lecture qui
aboutit quand même (avec `timeout`, sinon une régression ferait pendre le test au lieu de le faire échouer). Plus deux
tests de câblage sur le conteneur réel — les trois pièces en sortent, et l'écran écoute le canal **de ce refresher**
(identité), pas d'un autre.

⚠️ **Piège de test rencontré** : un `Completer` créé dans `setUp` planifie ses continuations dans la zone racine, que
`tester.pump()` ne draine jamais. L'attente ne se dénouait pas, et cela ressemblait trait pour trait à un défaut du code
testé.

---

### ~~H-4 · Une fiche ouverte depuis une recherche par identité n'affiche aucun détail~~ — corrigé

Signalé à l'usage, hors revue. La chaîne, entière, tenait à une condition de trop :

1. le formulaire bi-mode arme la recherche sur « les **trois noms** ou un niveau » — en mode identité,
   aucun niveau n'est choisi, donc `schoolLevelId` part vide ;
2. `facturation_student_table.dart` lit le niveau de la ligne dans… **les derniers critères de
   recherche** (`lastSummariesQuery.schoolLevelId`) — vide, donc, dans ce mode ;
3. `facturation_page.dart` cherche le nom du niveau dans le référentiel avec cet id vide : aucun
   `levelName`, aucun `levelGroupName` dans l'intent ;
4. `FacturationDetailIntent.hasDisplayContext` exigeait **les deux** en plus de l'identité ;
5. la page rendait `FinanceContextErrorCard` **à la place** du chargeur : ni frais, ni versements, ni
   totaux — pour un élève dont on connaissait parfaitement le nom.

La classe ne sert qu'au sur-titre « Facturation · {classe} ». Le grand-livre, lui, ne se lit qu'avec
`studentId` + `academicYearId`. La condition a donc été ramenée à ce qu'elle protège réellement —
`hasStudentIdentity` : **on n'affiche pas un solde sans pouvoir dire à qui il appartient**, et rien de
plus. Un lien profond sans `extra` (le vrai cas sans contexte) garde la carte d'erreur.

⚠️ **Ce n'est pas une invention locale : les deux modules voisins avaient déjà tranché ainsi.**
`DisciplinaryStudentDetailIntent` porte niveau, cycle et classe, et n'exige que les noms. Le catalogue
Documents l'écrit en toutes lettres — la classe est « du contexte d'affichage, jamais une condition
d'ouverture » — et vit très bien avec un sur-titre vide après une recherche par nom. Facturation était
le seul des trois à en faire une porte.

Les **trois intents frères** (détail d'un frais, détail d'un versement, encaissement) portaient la même
condition class-inclusive. Aucun n'était lu — getters morts — mais les laisser ainsi, c'était laisser
trois mines : la première modale qu'on y câblerait aurait refait la panne au-dessus d'une ligne
parfaitement identifiée. Alignés sur la même règle, identifiant de ligne compris (un frais sans
`chargeId` n'a toujours rien à afficher).

⚠️ **Ce qui n'est PAS corrigé, et qui est un choix** : le sur-titre affiche « Facturation · - » après une
recherche par identité, faute de classe à mettre. La corriger vraiment demanderait de porter le niveau
**par ligne** — projection du DAO (`e.school_level_id`, `e.school_level_group_id` ne sont pas dans le
`SELECT`), `LocalEnrollmentListItem`, `EnrollmentSummary`, puis la table — pour un sur-titre. Documents
vit avec le même « - » depuis son lot. À rouvrir si l'usage le réclame ; une variante moins chère
existe (dériver la classe des créances déjà chargées, qui portent `schoolLevelId`), au prix d'un
sur-titre qui se remplit un instant après l'ouverture.

Tests : deux au niveau **page** — la fiche issue d'une recherche par identité rend bien ses deux
sections, et la contre-épreuve du lien profond sans identité garde la carte d'erreur — plus cinq
unitaires qui figent la règle sur les quatre intents. Le test de page a d'abord été écrit **rouge** : il
reproduit la panne signalée avant de la corriger. Vérifié par mutation (la classe remise dans la
condition fait rougir le cas nominal).

---

### ~~M-1 · Un 403 transitoire sur `/sync/plan` gèle le repli pour la session~~ — corrigé

`sync_plan_holder.dart` — `_resolve()` ne mémorise plus comme **frais** tout ce qui ne lui revient pas en `null`. Deux
questions avaient été confondues : « la jambe réseau a-t-elle abouti ? », à laquelle `refreshFromNetwork` répond, et «
relire y changerait-il quelque chose ? », qui seule autorise à éteindre le drapeau. Le refus (401/403), l'uid pas encore
posé et le plan d'un autre sujet répondent oui à la première et non à la seconde : ils reviennent en état, et étaient
donc tenus pour définitifs. Comme `markStale()` n'a qu'un déclencheur — un vrai changement d'ensemble de droits — un
seul 403 rendait la main à
`requiredPermissions` **jusqu'au prochain login**, derrière une pastille verte.

La liste des verdicts vit désormais sur `SyncPlanUnknownCause.isVerdict`, à côté des causes qu'elle trie, et nulle part
ailleurs. Elle en compte **deux** :
`notDeployed` (la route n'apparaîtra pas d'ici le cycle suivant) et
`unsupportedStreams` (le serveur rendra le même corps tant que l'APK n'aura pas appris son vocabulaire). Les deux
`switch` — celui de l'extension, celui du porteur — sont exhaustifs et sans `_` : une huitième cause casse la
compilation au lieu de tomber du côté « définitif », celui où l'erreur ne se manifeste plus jamais.

⚠️ **Le partage `null` / état du repository n'a PAS bougé**, et il ne fallait pas le faire bouger : un 401/403 ne
consulte toujours pas le cache — il vient du même serveur et ne démentirait rien — et le cycle en cours retombe donc sur
le registre en dur. Ce que le correctif change est la **durée** : un cycle au lieu d'une session. Le coût est un
`GET /sync/plan` par cycle tant que l'anomalie dure, déjà borné par la sonde `_canAuthenticate()` du coordinateur, qui
empêche de lire le plan sans jetons utilisables.

`isDegraded` n'a pas été touché : la pastille ne s'alarme toujours que d'`unsupportedStreams`. Un refus transitoire n'a
plus à être signalé puisqu'il ne dure plus, et compter `notDeployed` ou `absent` mettrait tout le parc en alerte
permanente avant déploiement du plan.

Tests : trois cas paramétrés (`unauthorized`, `absent`, `foreignSubject`) qui vérifient le drapeau levé **puis que le
cycle suivant relit vraiment** — c'est là qu'est le défaut, pas dans l'état rendu ; une contre-épreuve
`unsupportedStreams`
sans laquelle « ne plus rien tenir pour définitif » passerait ; et la liste des verdicts figée sur `values`. Vérifié par
mutation dans les deux sens : rétablir
`fresh: true` fait rougir les trois cas paramétrés, retirer `unsupportedStreams`
de la liste fait rougir la contre-épreuve.

---

### ~~M-2 + M-3 · La Facturation confond « droit refusé » et « droits pas encore lus »~~ — corrigés

Traités ensemble parce que c'est **un seul défaut à deux moitiés** : la moitié qui se tait (M-2, trois écrans) et la
moitié qui ne demande rien (M-3, le chargeur). Corriger l'une seule aurait aggravé l'autre — une section rouverte
au-dessus d'un BLoC resté `initial` affiche « Aucun versement enregistré », qui est précisément la phrase que la carte «
relève de la caisse » existait à éviter.

**La règle, désormais tenue aux quatre sites :** on ne se tait, et on ne renonce à lire, que sur `missing` — quand on
**sait** que le droit manque. Une lecture tentée à tort coûte un 403, rendu en état d'erreur avec « Réessayer » ; une
lecture omise à tort ment, sur l'écran même où un caissier décide s'il faut encaisser. C'est la même asymétrie que le
socle de synchro, qui tire sur inconnu.

`permission_holding.dart` gagne les deux pièces qui manquaient à la matrice :

|              | Deux états                                           | Trois états                                             |
|--------------|------------------------------------------------------|---------------------------------------------------------|
| **Abonné**   | `PermissionGate` (une garde doit fermer sur inconnu) | `PermissionHoldingBuilder` *(nouveau)*                  |
| **Ponctuel** | `PermissionGate.allows`                              | `permissionHolding` / `permissionHoldingOf` *(nouveau)* |

`permissionHoldingOf` est la règle sans arbre, pour les appelants qui tiennent déjà l'état de session — un `buildWhen`,
un `listenWhen`, un `State` qui décide d'émettre. Sans elle, chacun réécrivait « inconnu ne vaut pas refusé » pour son
compte, et c'est exactement la divergence qui a produit le défaut.

⚠️ **L'abonnement n'est pas un luxe, c'est l'autre moitié.** Le tri-état lu une seule fois dans un `build` extérieur
fige son verdict pour la vie de l'écran :
rien ne reconstruit la section Versements quand les permissions arrivent en séance. Le `buildWhen` et le `listenWhen`
comparent la **décision**, jamais les ensembles — un droit qui bouge ailleurs dans le catalogue ne reconstruit ni ne
relit rien, et la comparaison n'a pas à se prononcer sur les doublons d'une liste (cf. B-3, qui reste ouvert sur
`PermissionGate._sameSet`).

Côté chargeur, la lecture de rattrapage ne redemande **que** les versements — les créances sont déjà à l'écran, et les
relire ferait clignoter une donnée intacte — et elle n'est **pas** silencieuse : il n'y a rien à préserver, un skeleton
dit honnêtement qu'on est allé chercher. Un drapeau `_paymentsRequested` empêche le doublon, et retombe quand le droit
se retire, pour qu'un élargissement ultérieur reparte d'une vraie lecture plutôt que d'une donnée d'avant.

Tests : `facturation_permissions_unknown_test.dart`, 11 cas — les quatre sites sur ensemble inconnu, les deux sens de
bascule en séance (le droit qui arrive rouvre et relit, celui qui se retire referme), la non-relecture sur un changement
qui ne change pas la décision, et deux contre-épreuves « sans le droit, on se tait toujours ». Vérifié par mutation sur
les cinq sites de décision : chacun, remis en deux états, fait rougir au moins un cas.

⚠️ **Piège de test rencontré** : les sections traversent un `AnimatedSwitcher`. Sans `pumpAndSettle`, l'ancien enfant
est encore à l'arbre et un `findsNothing`
échoue sur une carte en train de disparaître — ce qui ressemble trait pour trait à un abonnement qui n'a pas fonctionné.

---

### ~~M-4 · Une lecture de tarifs en échec est rendue « aucun frais défini pour ce niveau »~~ — corrigé

`tariffsStatus: failure` était calculé, stocké, et lu par **personne** : `fee_control_page.dart` ne
transmettait que `isTariffsLoading` et `feeGridMissing`, si bien qu'une base SQLCipher verrouillée
tombait dans le dernier `else` du sélecteur et annonçait « Aucun frais n'est défini pour ce niveau ».
C'est une affirmation sur **l'école** là où seule la lecture de **l'appareil** avait échoué — et comme le
frais est obligatoire dans ce module, la recherche restait fermée sans que rien n'explique pourquoi.

Le sélecteur distingue désormais **trois** causes d'une liste vide, au lieu de deux :

| Cause | Ce qu'on affiche | Se répare en |
|---|---|---|
| Ce niveau n'a pas de frais | information | rien — il n'y a rien à contrôler |
| Grille pas descendue / caviardée | « synchronisez » ou « votre administrateur peut ouvrir cet accès » | une synchro, ou un droit |
| **Lecture en échec** *(nouveau)* | « la liste des frais n'a pas pu être lue sur cet appareil » | **réessayer** |

L'échec passe **en tête** de la cascade : les deux autres messages affirment quelque chose sur l'école
ou sur la synchronisation, et une lecture qui n'a pas abouti n'autorise ni l'une ni l'autre.

Le bouton « Réessayer » n'apparaît que pour cette cause-là — les deux autres ne se réparent pas en
réessayant, et l'offrir y promettrait une issue qui n'existe pas. Il rejoue les **deux** lectures locales
du niveau courant en passant par `onLevelSelected`, le canal existant : une base qui refuse la grille
refuse en général aussi le roster, et un canal de reprise dédié aurait fini par diverger de celui-là. La
sélection n'est pas remise à zéro, contrairement à un vrai changement de niveau — le niveau n'a pas
changé.

⚠️ **Écart assumé avec la consigne d'origine de cette fiche** (« lui donner son propre état d'erreur,
règle non-négociable #10 : `EteeloErrorResult` »). La règle #10 vise les **zones de résultats** ;
ici l'erreur naît dans un **champ de formulaire**. `EteeloErrorResult` a une anatomie de carte pleine —
médaillon, titre, `minHeight: 380` — qu'il aurait fallu vider de sa substance pour la loger entre deux
sélecteurs, ce qui ruine précisément l'« anatomie unique » que la règle protège. On garde donc le
vocabulaire du champ (`errorText`, comme les deux autres causes, et comme le sélecteur de classe voisin)
en lui ajoutant ce qui manquait vraiment : un geste de reprise. À rediscuter si la revue préfère la
lettre de la règle à son intention.

⚠️ Le bouton est un `EteeloButton.ghost(fullWidth: false)`, **jamais** un `TextButton`/`OutlinedButton`
nu : le thème du dépôt les veut pleine largeur, et un bouton inline sans `minimumSize` casse la mise en
page sur contrainte infinie (piège déjà rencontré, cf. le mémo dédié).

Tests : trois cas dans `fee_control_search_form_test.dart` — l'échec dit l'échec et jamais « aucun
frais », la reprise rejoue la lecture du **même** niveau (les deux appels sont capturés et comparés), et
une contre-épreuve « grille absente ⇒ pas de bouton ». Vérifié par mutation : neutraliser la branche
d'échec, puis neutraliser la reprise, font rougir chacune leur cas.

---

### ~~#13 · L'anti-rafale de reprise n'est pas monotone~~ — corrigé (`5123439`)

`lib/core/components/status/sync_status_cubit.dart` — l'horloge est celle du device, donc reculable : un NTP corrigeant
une dérive de RTC laissait
`_lastCycleAtMs` dans le futur, l'écart devenait négatif et le déclencheur de reprise ne repartait plus jamais en cycle
complet. Un écart négatif prend désormais le chemin long, avec test de régression vérifié par mutation.

---

## Vérifié sain par la revue

L'escalier de migration v27 (bornes `upTo`, DDL v9 inliné, plus aucune lecture du schéma vivant sur une table retirée,
`UPDATE students` gardé), le câblage DI de `credentialsProbe` / `permissions` / `planHolder` sur `PullCoordinator`,
l'arithmétique en centimes du contrôle des frais et la jointure `fee_code` par lots de 500, `ClientSidePaginator`,
`PullSequencer`, la table d'alias des 18 clés, `leaveWizardToListing` / `onDetailReturned`, `SyncStateIcon`
(null vs DRAFT), et l'observateur de reprise du lot 1.




* Dans le module Finance les resultats issus d'une recherche par identité de l'élève n'affiche pas le détail





* Retravailler les Formulaires pour : 
- Inclure la version des switch comme dans documents
- Inclure le formattage des champs
- Inclure la recherche interactive
======== Exception caught by rendering library ===================================================== The following
assertion was thrown during layout:
A RenderFlex overflowed by 62 pixels on the bottom.

The relevant error-causing widget was:
Column Column:file:///home/junethink/my_project/school_app_flutter/lib/core/components/skeletons/eteelo_list_skeleton.dart:73:18