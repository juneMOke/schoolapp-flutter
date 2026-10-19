# MOBILE_RESPONSIVE_PLAN.md — l'app tient dans une main

> Plan des passes **téléphone** (360 dp) et **tablette** (600–1280 dp, §4). Audit du 2026-10-18,
> revérifié sur le code le 2026-10-19. Aucun lot lancé.

---

## 0. Le diagnostic

L'app est pensée tablette, et c'est solide : la saisie de notes,
l'inscription, l'encaissement, les bandes KPI et les sélecteurs en feuille
s'adaptent déjà au téléphone. **La coquille, les tableaux et les modales n'ont
pas de mode téléphone.**

---

## 1. Constats

### Gravité haute

| # | Constat | Où |
|---|---|---|
| H1 | Le retour Android **quitte l'app** depuis tout écran du menu : la coquille est une seule page à clé fixe, ses sous-menus ont une adresse (`/home/{sousMenu}`) mais ne s'empilent pas. Aucun `PopScope`. | `lib/router/app_router.dart`, `lib/features/home` |
| H2 | Aucune borne au facteur de texte. À ×1,3 les hauteurs fixes cassent (catalogue boutique, bandeau du net de paie, graphiques). | `lib/main.dart` |
| H3 | Aucun tableau ne passe en cartes sous 600 dp. Les colonnes se compriment (reçus de caisse : montant à ~40 dp, coupé) ou défilent sans colonne figée (paie, récapitulatifs). | `lib/core/components/tables/data_table_view.dart` |
| H4 | Formulaires en `Dialog` centrés (44 `showDialog`). `EteeloFormDialog` garde l'encart Material de 40 dp par côté ⇒ ~232 dp de champ. `showEteeloAdaptiveSheet` existe mais ne sert à aucun formulaire. | `lib/core/…/eteelo_form_dialog`, `showEteeloAdaptiveSheet` |
| H5 | Barre de coquille saturée : hamburger + pastille de synchro (« Partiellement à jour · il y a 12 min », ~190 dp) + cloche inerte + profil ⇒ ~50 dp pour le titre. Même chose sur les barres sombres de dossier : le nom de l'élève disparaît. | `top_bar_actions.dart:49` (`onPressed: () {}`), `sync_indicator.dart:80`, `student_detail_app_bar.dart:124` |
| H6 | Clavier virtuel : le montant de dépense n'ouvre pas le pavé numérique ; `physicalKeyboardNextAction` vaut `null` sur tactile ⇒ pas de « Suivant », le clavier se ferme à chaque champ. | `expense_amount_fields.dart`, `physicalKeyboardNextAction` |
| H7 | La recherche bi-mode reste dépliée après la recherche (~500 dp) : les résultats commencent sous la ligne de flottaison. | `BiModeSearchForm` |

### Gravité moyenne

- Aucun pull-to-refresh dans toute l'app (0 `RefreshIndicator`).
- Aucune `SafeArea` bas/côtés dans `AppPageBackground`, alors que le bord à
  bord est imposé sous Android 15.
- Cibles tactiles de 34 à 40 dp (profil, appel, cases à cocher, actions de
  dépense) alors que `AppDimensions.minTouchTarget = 48` existe.
- Visionneuse PDF en dialogue : page A4 à ~310 dp, zoom au double-tap que rien
  ne signale.
- Montants de la caisse en Lora 34 coupés au caractère.
- Graphiques : étiquettes qui se chevauchent dès ~8 points.
- Navigation : pas de barre basse ; changer d'écran = trois gestes, tous en
  haut de l'écran.

---

## 2. Débordements mesurés à 360×740

Sonde du 2026-10-18 : toute la suite widget rejouée à 360×740
(8 801 tests, ~46 min). **91 débordements, 26 sources** — 25 restantes,
`expense_thread_panel.dart:43` ayant été corrigé par `66a290d9`.

| Fichier | Débordements |
|---|---|
| `summary_previous_academic_section.dart:90/110` | 11 |
| `recouvrement_fee_picker.dart:187` | 10 |
| `facturation_collect_flow_parts.dart:50` | 6 |
| `attendance_overview_split_bar.dart:138` | 6 |
| `fee_form.dart:264` | 5 |
| `configuration_cycle_card.dart:164` | 5 |
| `configuration_activation_footer.dart:50` | 5 |
| `fees_step.dart:213` | 5 |
| `attendance_overview_context_bar.dart:114` | 4 |
| `academic_year_step.dart:173` | 3 |
| `facturation_payment_line.dart:274` | 3 |
| `data_table_pagination_bar.dart:43` | 3 |
| `cours_notation_atoms.dart:116` | 3 |
| `fee_scope_picker.dart` | 2 |
| `student_detail_app_bar.dart:124`, `segmented_tab_filter.dart:244`, `sync_indicator.dart:80`, … | 1–2 |

104 tests rougissent à cette taille : beaucoup sont des finders hors écran, pas
des bugs. **Seuls les débordements sont des défauts certains.**

### L'instrument

Un `test/flutter_test_config.dart` dont `testExecutable` pose un `setUp` global
(`physicalSize` 1080×2220, `devicePixelRatio` 3) rejoue toute la suite à
360×740 ; compter `overflowed by` dans le log. À lancer dans un **worktree
détaché**, jamais dans l'arbre de travail. Elle sert d'oracle au lot M2 :
le lot est fini quand le compte est à zéro.

---

## 3. Lots

Un lot par validation, comme la passe desktop.

| Lot | Contenu | Effet |
|---|---|---|
| **M1 — Socle** | Retour Android dans la coquille (fermer le tiroir → revenir à l'Accueil → double appui pour quitter) ; `textScaler` borné à ×1,3 ; `SafeArea` dans `AppPageBackground` ; « Suivant » au clavier virtuel ; pavé numérique pour les montants | Beaucoup de gain, peu de fichiers |
| **M2 — Débordements** | Les 25 sources du §2 | Zéro bande jaune à 360 dp |
| **M3 — En-têtes** | Pastille de synchro en icône seule et cloche retirée en compact ; barres de dossier sans doublon retour/croix ; cibles à 48 dp | Titres et noms lisibles |
| **M4 — Modales** | `EteeloFormDialog` et dérivés en plein écran sous 760 dp ; corriger d'abord `showEteeloAdaptiveSheet` (clavier, `SafeArea`) | Saisie confortable |
| **M5 — Tableaux** | Mode carte dans `DataTableView` (reçus de caisse, entrées d'inscription, facturation d'abord) ; première colonne figée pour la paie | Le plus gros chantier |
| **M6 — Confort** | Pull-to-refresh, recherche repliée en résumé, visionneuse plein écran, graphiques | Finition |
| ~~**M7**~~ | ~~Barre de navigation basse sous 600 dp~~ — abandonné (cf. §5) | — |

---

## 4. Tablette (audit du 2026-10-19)

Formats de référence en dp : 7" portrait 600×960, 7" paysage 960×600,
10" portrait 800×1280, 10" paysage 1280×800. Pas de verrou d'orientation ;
`configChanges` contient `orientation|screenSize` (l'activité survit),
`adjustResize` est posé, `resizeableActivity` vaut true (écran partagé permis).

### Ce qui tient déjà

Modales via `EteeloDialogBody` (~30 fichiers) et densité du stepper selon la
hauteur ; claviers numérique et téléphone ; autofocus réservé au clavier
physique ; pages routées (encaissement, stepper, fiche de facturation)
indemnes à la rotation ; bandes KPI et tableaux de bord fluides ; pavé de
notes à 52 dp ; tout raccourci clavier a son équivalent tactile.

### Constats

| # | Gravité | Constat | Où |
|---|---|---|---|
| T-H1 | **Bloquant** | Franchir 1024 dp (rotation d'une 10", écran partagé) **remonte tout le contenu de la coquille** : deux arbres distincts (`Row` + `Sidebar` / `Scaffold` + tiroir), aucune `GlobalKey`. Perdus : brouillon de notes, panier boutique, appel en cours, filtres, défilement ; les `FeatureScope` relancent leurs pulls. | `home_page.dart:115-183`, `_buildContentArea` l.274 |
| T-H2 | Gênant | Entre 760 et 1024 (10" portrait, 7" paysage) : tiroir seul, deux taps par navigation, alors que la barre repliée de 84 dp existe (`AppTheme.sidebarCollapsedWidth`). | `home_page.dart:117,172` |
| T-H3 | Gênant | Une 10" paysage n'atteint presque aucun seuil deux colonnes : 1280 − 280 de barre dépliée ≈ 1000 dp < 1024 (panier boutique, historique boutique, focus résultats, périmètre recouvrement). Le repli ne tient pas : déplier un accordéon rouvre la barre. | `navigation_state.dart:39`, `navigation_bloc.dart:105`, `boutique_page.dart:209` |
| T-H4 | Gênant | Cibles tactiles au guichet : case de frais 24×24, ligne non tapable ; « Tout régler » `minimumSize: Size(0,0)` ; chip de devise compact. Appel : segment P/R/A 40 dp, icônes 36 dp. | `facturation_create_payment_charge_group_line.dart:292,433`, `…_charge_allocation_line.dart:222`, `presence_row_controls.dart:53,119,168` |
| T-H5 | Gênant | Faible hauteur (600 dp) : double barre de titre boutique (~140 dp) ; saisie de notes Focus empilée (défilement à chaque élève, pas de côte à côte en paysage) ; total de l'encaissement en `bottomNavigationBar` sous le clavier (à vérifier sur appareil). | `boutique_page.dart:218`, `saisie_focus.dart:121-150`, `facturation_create_payment_page.dart:778` |
| T-H6 | Gênant | Barre gestuelle sur la barre d'enregistrement des notes et le pied de fiche d'évaluation (pas de `SafeArea`). | `eval_saisie_page.dart:177`, `eval_detail_page.dart:230` |
| T-M1 | Confort | Vue liste de l'appel ≥ 900 dp : à 800 elle défile de côté sans ascenseur (`EteeloMinWidthScroll` sans `Scrollbar`). | `presence_list_frame.dart:35` |
| T-M2 | Confort | Pastilles du dossier d'inscription en icône seule sous 1024 (libellé à l'appui long), même en 7" paysage. | `enrollment_journey_pill_button.dart:35` |
| T-M3 | Confort | Encaissement en une colonne de 880 dp même à 1280 ; tableaux en 12 sp / en-têtes 11 sp ; `autofocus: true` forcé dans le dialogue bénéficiaire boutique ; `eval_creation_modal.dart:42` hors `EteeloDialogBody`. | — |

### Débordements mesurés (sonde du 2026-10-19)

Même instrument que le §2, `devicePixelRatio` 2. 8 865 tests par passe, ~25-30 min.

| Format | Débordements | Sources |
|---|---|---|
| 600×960 | 2 | `fees_step.dart:213` (79 px, déjà au §2), `facturation_payment_line.dart:274` (5 px, déjà au §2) |
| 960×600 | 4 | `facturation_detail_statement_bar.dart:57` (183 px : légende + action longue en `Row` dès `formMediumMin`) ; tableau de bord des présences, 35 px — source avalée par `takeException`, probablement `attendance_overview_context_bar.dart:114` (§2) |

Les autres tests rouges (22 en portrait, 6 en paysage) sont des attentes liées
à la taille (600 = pile `stepperControlsCompactMax`, grilles, finders), pas des
défauts.

### Lots tablette

| Lot | Contenu | Effet |
|---|---|---|
| **T1 — Coquille stable** | Un seul arbre pour les deux modes (contenu sous `GlobalKey` ou même squelette `Scaffold`), test de rotation 1280 ↔ 800 qui garde un brouillon | Bloquant levé ; à faire avec M1 (même fichier) |
| **T2 — Navigation tablette** | Barre repliée existante (84 dp, menu flottant) entre 760 et 1024 au lieu du tiroir seul (`home_page.dart:117,172`) ; repli de la barre persistant ; seuils deux colonnes recalés pour une 10" paysage | Un tap par navigation, maître-détail à 1280 |
| **T3 — Guichet & appel au doigt** | Cibles à 48 dp (lignes de frais tapables, « Tout régler », chips, P/R/A) | Fusionnable avec M3 |
| **T4 — Paysage bas** | Une seule barre de titre en boutique ; Focus de notes côte à côte en paysage ; total d'encaissement visible clavier ouvert ; `SafeArea` des barres basses | Saisie sans défilement |
| **T5 — Débordements & confort** | `facturation_detail_statement_bar`, ascenseur d'`EteeloMinWidthScroll`, libellés des pastilles ≥ 760, densité des tableaux, autofocus boutique | Finition |

Ordre proposé : **M1 + T1** (socle commun, coquille), puis T2, T3+M3, T4, M2+T5.

---

## 5. Questions ouvertes

1. ~~**M7**~~ — **abandonné le 2026-10-19** : une barre basse tient 5 destinations, l'app a 13 modules hiérarchisés. Le téléphone garde le tiroir ; le retour Android (M1) et la barre d'en-tête allégée (M3) traitent le vrai problème.
2. ~~**T2**~~ — **tranché le 2026-10-19 : la barre repliée existante** (84 dp, menu flottant des sous-menus depuis `54a6eca9`), pas de `NavigationRail` (sans hiérarchie, 3 à 7 destinations). Une seule navigation qui se replie selon la largeur : tiroir < 760, barre repliée 760-1024, barre dépliée au-delà.
3. **Branche** — `feat/mobile-responsive` depuis `main`, créée avec `--no-track`.
