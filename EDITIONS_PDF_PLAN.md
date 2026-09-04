# EDITIONS_PDF_PLAN.md — imprimer ce que la tablette sait déjà

> **Statut :** proposé le 2026-09-03, arbitrages D1–D4 tranchés par le user.
> Aucun lot ouvert.
>
> | Lot | État |
> |---|---|
> | ED-0 · socle de rendu (`core/reporting`) — modèle, gabarit A4, isolate | ⬜ |
> | ED-1 · visionneuse locale (aperçu · imprimer · partager) | ⬜ |
> | ED-2 · sélecteur partagé période + cycles + niveaux | ⬜ |
> | ED-3 · Inscriptions › Éditions — liste des inscrits par classe | ⬜ |
> | ED-4 · Finances › export du tableau de bord (fidèle à l'écran) | ⬜ |
> | ED-5 · Finances › Éditions — journal des transactions + recouvrement local | ⬜ |
> | ED-6 · Contrôle des frais › Éditions — relances | ⬜ |
> | ED-7 · l10n, a11y, états partagés, revue money-grade | ⬜ |
>
> **Docs de contexte :** `FINANCE_STATS_PLAN.md` (le dashboard online qu'on
> exporte) · `FEE_CONTROL_DASHBOARD_PLAN.md` (les mêmes lectures locales, en
> compte d'élèves) · `MULTIDEVISE_PLAN.md` (jamais d'addition inter-devises) ·
> `NOMMAGE_CHARGES_PLAN.md` · `AGENTS.md` §« États partagés » · `CLAUDE.md`
> §règles non-négociables.

---

## 1. La question posée

> « Peut-on **sortir sur papier** ce que la tablette affiche déjà : qui est
> inscrit, et ce qui est entré en caisse ? »

Rien n'est à calculer que l'application ne calcule déjà. Ce lot ne produit
aucune donnée neuve : il ouvre une **sortie**. Le livrable est un PDF qui
s'ouvre dans la visionneuse existante, s'imprime, et se partage par les canaux
du système (Bluetooth compris).

---

## 2. Ce que ces éditions ne sont pas

C'est la distinction structurante du lot, et elle porte le nom du module.

| | Documents (éditique, ADR-012) | **Éditions** (ce plan) |
|---|---|---|
| Nature | une **pièce** : attestation, reçu, quitus | un **état de gestion** : une liste, un journal |
| Fait foi ? | oui — numérotée, scellée, horodatée serveur | **non**, jamais |
| Origine | le serveur rend les octets | la tablette rend les octets |
| Réseau | 100 % online | 100 % local |
| Rejeu | interdit sur RL/QT (brûle un numéro) | libre, à volonté |
| Portée | **un** élève | **une population** |

Les mêler serait une faute de catégorie : un état de gestion réimprimé dix fois
n'a aucune conséquence, une note de perception réémise une seule fois de trop en
a une. D'où **D1** ci-dessous — et d'où le pied de page obligatoire, qui dit à
haute voix ce que la pièce n'est pas.

---

## 3. Les faits déterminants

### 3.1 Le socle PDF existe, mais borné au ticket 80 mm

`pdf` 3.12 et `printing` 5.14 sont en place. `PdfTicketRenderer`
(`lib/features/documents/data/ticket/pdf_ticket_renderer.dart`) prouve le
chemin : rendu 100 % Dart, **aucune police à embarquer** — les base-14 sont
intégrées au format PDF et couvrent le WinAnsi, donc les accents français.

Ce qui manque est un **gabarit A4 paginé**. Sur une feuille la hauteur est
finie : la contrainte qui interdisait `pw.MultiPage` au ticket tombe, et
`pw.MultiPage` redevient le bon outil — c'est écrit noir sur blanc dans l'en-tête
du renderer du ticket.

### 3.2 La visionneuse existe, mais elle est soudée à l'émission serveur

`EditiqueDocumentDialogView`
(`lib/features/documents/presentation/widgets/editique_document_dialog.dart`)
porte déjà l'aperçu (`PdfPreview`), l'impression (`Printing.layoutPdf`), le
partage (`Printing.sharePdf`) et — précieux — `_runPlatformAction`, qui rend
visible l'échec du canal natif au lieu de le laisser filer en erreur
asynchrone non capturée.

Mais elle se construit sur `EditiqueDocumentBloc` : états d'émission, `canRetry`,
anatomie 401/403. Un état de gestion n'a **rien** de tout cela — il n'y a pas de
session à rouvrir pour rendre un PDF qu'on a déjà les données de rendre. D'où
l'extraction d'ED-1, et non une réutilisation en l'état.

### 3.3 Inscriptions — tout est local, sauf la classe

`enrollments` porte `enrollment_type` (`NEW_ENROLLMENT` / `RE_ENROLLMENT` /
`PRE_ENROLLMENT`), `enrollment_date`, `school_level_id`,
`school_level_group_id`, `status`. La jointure vers `students` donne nom,
sexe, date de naissance, matricule.

**La classe n'y est pas.** Elle vit dans `ref_classroom_members`
(`student_id` · `classroom_id` · `academic_year_id` · `status`) et se compose en
Dart, exactement comme le fait déjà l'écran de contrôle des frais. Trois
conséquences directes sur une liste « par classe » :

* il faut un seau **« non répartis »** — un élève inscrit sans affectation
  existe, et l'omettre ferait mentir le total ;
* pour un niveau dont `ref_school_levels.split_into_classrooms = 0`, la
  **classe est le niveau** : pas de sous-groupe à afficher ;
* `ref_classroom_members` peut porter plusieurs lignes pour un même élève
  (transferts) — filtrer `status = 'ACTIVE'`, sinon l'élève est compté deux fois.

### 3.4 Finance — le tableau de bord ne peut pas produire ce qui est demandé

`/recovery` et `/till` sont **online**, et leur charge utile n'a **aucune**
dimension cycle ni niveau. `FinanceRecovery` se ventile par devise
(`RecoveryCurrencyBlock`), puis par code de frais (`FeeTypeItem`) et par seau
temporel (`FinanceEvolution`). `FinanceTill` de même. Filtrer un export du
dashboard par cycle et par niveau est donc **impossible sans le back**.

Le **grand-livre local**, lui, a tout :

```
payments              id · student_id · paid_at · method · payer_* · cashier_* · collected_by_*
payment_allocations   payment_id · fee_code · student_charge_label · amount_in_cents · currency
student_charges       student_id · school_level_id · school_level_group_id · fee_code
                      expected_amount_in_cents · amount_paid_in_cents · currency · due_at
```

Et le pull descend **tout le périmètre de l'école**, pas seulement les dossiers
ouverts : `FinancePullHandler.payments` est documenté « y compris ceux de
l'autre poste de perception », `FinancePullHandler.studentCharges` porte « les
créances autoritaires du roster ».

Un rapport financier 100 % local, filtrable par date, cycle et niveau, est donc
faisable **aujourd'hui, sans une ligne de back**. Son seul défaut est réel : il
dépend de l'avancement du pull, et peut donc afficher un montant différent de
celui du dashboard juste au-dessus. D'où **D2**.

---

## 4. Arbitrages tranchés

### D1 — « Éditions », un sous-menu par module ✅

Pas « Documents » : le mot est pris, et il désigne ce qui fait foi (§2). Pas non
plus un menu unique — chaque module possède ses données, ses filtres et sa
permission ; un écran commun aurait fait cohabiter la grille tarifaire et le
roster sous un même sélecteur.

| Module | Sous-menu | Route | Permission |
|---|---|---|---|
| Inscriptions | Éditions | `/inscriptions/inscriptions-editions` | `enrollment.read` |
| Finances | Éditions | `/finances/finances-editions` | disjonction `finance.payment.read` ∨ `finance.charge.read` |
| Contrôle des frais | Éditions | `/controle-frais/controle-frais-editions` | `finance.charge.read` |

La disjonction en Finances reprend celle de la Facturation, et pour la même
raison : le secrétariat lit les créances sans lire la caisse. Lui fermer l'écran
entier lui retirerait une lecture qu'il détient — il verra le rapport de
recouvrement, pas le journal des transactions.

### D2 — Deux pièces distinctes en Finance, jamais un chiffre à deux sources ✅

| | **Export du tableau de bord** (ED-4) | **Rapports** (ED-5) |
|---|---|---|
| Où | bouton sur le dashboard | sous-menu Éditions |
| Source | la réponse serveur **affichée** | le grand-livre local |
| Filtres | ceux de l'écran, **rien de plus** | date · cycle · niveau · frais |
| Réseau | exige le réseau | fonctionne hors réseau |
| Ce qu'il dit | « d'après le serveur, au {horodatage} » | « arrêté au {…}, d'après le grand-livre local » |

Deux titres, deux promesses. Le danger qu'on écarte est précis : un état qui
annonce un total différent de l'écran d'où on l'a lancé, **sans dire pourquoi**,
sur de l'argent.

### D3 — « Nouveau » = `NEW_ENROLLMENT`, « ancien » = `RE_ENROLLMENT` ✅

Le champ est déjà là, sans jointure ni calcul. Nuance assumée et à écrire dans
la légende : un élève parti puis revenu compte comme **nouveau** — c'est le
type d'inscription de l'année qui parle, pas l'histoire de l'élève. Le drapeau
`former_student` n'est **pas** consulté.

`PRE_ENROLLMENT` n'est ni l'un ni l'autre : une pré-inscription n'est pas une
inscription, et la liste ne la contient pas (cf. PO-1).

### D4 — Une seule idée annexe retenue : les relances ✅ (ED-6)

Écartées pour l'instant : fiche d'appel, arrêté de caisse, registre matricule,
état des effectifs, export CSV. Le socle d'ED-0 les rend peu coûteuses le jour
où elles seront voulues — c'est précisément pourquoi le gabarit ne doit rien
savoir du domaine qu'il imprime.

---

## 5. Architecture

```
lib/core/reporting/                     ← neuf, partagé, sans domaine
  domain/report_document.dart           modèle pur : en-tête, colonnes, sections, légende, pied
  domain/report_period.dart             la période, calculée à UN seul endroit
  data/report_pdf_renderer.dart         A4 pw.MultiPage → Uint8List (fonction top-level + compute)
  presentation/report_viewer_dialog.dart  aperçu · imprimer · partager
  presentation/report_scope_picker.dart   période + cycles + niveaux

lib/features/enrollment/presentation/editions/    ← DAO + projecteur + page
lib/features/finance/presentation/editions/
lib/features/fee_control/presentation/editions/
```

Le socle **ne connaît aucun domaine**. Il reçoit un `ReportDocument` — des
chaînes déjà formatées, des colonnes déjà nommées — et rend des octets. C'est
ce qui rend la pagination et le gabarit testables sans base de données, et ce
qui met les cinq éditions écartées en D4 à un projecteur de distance.

Chaque module fournit son **projecteur** : lectures locales → `ReportDocument`.
Le formatage des montants, des dates et des libellés se fait **dans le
projecteur**, jamais dans le renderer : le renderer n'a pas de `BuildContext`,
donc pas d'`AppLocalizations`.

---

## 6. Les lots

### ED-0 · Le socle de rendu

* `ReportDocument` : identité école (`ref_school`), titre, sous-titre de portée
  (« Année 2025-2026 · Primaire · du 01/09 au 30/09 »), sections (une par
  classe), colonnes, lignes, légende, totaux.
* `ReportPdfRenderer` : A4, en-tête répété sur chaque page, « page n / N »,
  pied **« État de gestion — ne fait pas foi · édité le {date} par {agent} »**.
* Rendu **en isolate** : fonction top-level + `compute`, sur le modèle exact de
  `editique_blob_cipher.dart:133`. Le modèle passé doit être plat — aucune
  poignée sqflite, aucun `BuildContext`.
* Tests : le modèle, le découpage en sections, la présence du pied. Pas la
  rastérisation (canal de plateforme, invisible en test widget).

### ED-1 · La visionneuse locale

Extraire de `editique_document_dialog.dart` un `ReportViewerDialog` qui prend
`Uint8List` + nom de fichier, sans BLoC : aperçu (`PdfPreview`, `useActions:
false`), imprimer, partager, fermer. `_runPlatformAction` est repris tel quel —
c'est lui qui empêche l'appui sans effet quand le canal natif manque.

Le repli d'erreur de `PdfPreview` reste, mais sans `canRetry` : ici, régénérer
est gratuit.

### ED-2 · Le sélecteur partagé

Un composant, deux modules. Période (**date précise · jour · semaine · mois ·
année · plage libre**) et multi-sélection **cycles → niveaux** (les niveaux
proposés dépendent des cycles cochés ; « tous » est l'état par défaut).

La période produit un `DateRange` **fermé-ouvert** `[début, fin[`, calculé dans
`ReportPeriod` et nulle part ailleurs — sinon Inscriptions et Finance
diviseront le mois différemment.

### ED-3 · Inscriptions › Éditions — la liste des inscrits

* `EnrollmentReportDao` : `enrollments ⨝ students`, filtré année + période sur
  `enrollment_date` + cycles/niveaux ; la classe composée en Dart depuis
  `ref_classroom_members` (`status = 'ACTIVE'`).
* Une **section par classe**, triée par cycle puis niveau puis classe, seau
  « non répartis » en dernier ; colonnes : n°, nom complet, sexe, date de
  naissance, matricule, **type**.
* Code couleur nouveaux / anciens **redondant** : un fond teinté *et* une
  colonne « N » / « R ». Une photocopie noir et blanc réduit deux pastels au
  même gris — la couleur seule ne code rien.
* Totaux par section et généraux : effectif, M/F, nouveaux/anciens.

### ED-4 · Finances › Export du tableau de bord

Bouton visible sur `finance_stats_dashboard_page`, actif sur les deux onglets,
qui rend **exactement ce que l'écran porte** : les KPI de l'onglet courant, sa
ventilation par devise et par frais, sa courbe, la période **du serveur** et son
horodatage. Aucun sélecteur supplémentaire — et l'écran dit pourquoi : la
ventilation par cycle et par niveau n'est pas dans la réponse (PO-2).

### ED-5 · Finances › Éditions — les rapports locaux

Deux pièces, un même sélecteur :

1. **Journal des transactions** — une ligne par encaissement : date, élève,
   classe/niveau, frais imputé, montant, devise, mode, caissier. Source :
   `payments ⨝ payment_allocations`, période sur `paid_at`.
2. **Rapport de recouvrement** — attendu / encaissé / reste, par cycle →
   niveau → frais. Source : `student_charges`, avec le solde calculé comme le
   fait déjà `FinanceLedgerReadDao.getFeeChargeAggregates`.

Contraintes non négociables : **un bloc par devise, jamais d'addition
inter-devises** ; bandeau de fraîcheur en tête (« arrêté au {…} · d'après le
grand-livre local ») ; le journal est gardé par `finance.payment.read`, le
recouvrement par `finance.charge.read`.

### ED-6 · Contrôle des frais › Éditions — les relances

Réutilise le projecteur existant (`FeeControlRow`, `FeeControlPaymentFilter`) :

* **Liste des retardataires par classe** — élève, frais, attendu, payé, reste,
  échéance. Une classe par page : c'est le format qu'un titulaire distribue.
* **Lettre de relance nominative** — une page par élève, en-tête école, nom du
  tuteur, détail du reste dû, échéance. Même pied « ne fait pas foi ».

### ED-7 · Finition

FR + EN dans les deux `.arb`, `flutter gen-l10n` **puis `dart format
lib/l10n/`** ; états partagés (`EteeloListSkeleton` pendant le rendu,
`EteeloEmptyResult` sur zéro ligne, `EteeloErrorResult` sur échec) ; zéro
couleur en dur ; revue money-grade ciblée sur ED-5.

---

## 7. Pièges recensés

1. **Le rendu sur l'isolate UI gèle l'écran.** 2 000 lignes, c'est plusieurs
   secondes. `compute`, dès ED-0 — pas en rattrapage.
2. **`pw.MultiPage` plafonne à 20 pages par défaut.** Une liste d'école entière
   les dépasse. Relever `maxPages` explicitement, comme le ticket a dû le faire.
3. **Les base-14 couvrent le WinAnsi, et rien d'autre.** Un nom portant un
   caractère hors de ce jeu sortira en `?`, **en silence**. À trancher : accepter,
   ou embarquer une police Unicode (coût : ~300 Ko d'asset). Cf. PO-3.
4. **Le partage laisse le PDF en clair.** `Printing.sharePdf` écrit dans
   `cacheDir/share/` et n'efface jamais ; seul `SharedDocumentCache.purge()`
   nettoie, **à la déconnexion**. Une liste nominative de toute l'école y
   séjourne donc jusqu'à la fin de session. Le dossier est bien le même, donc la
   purge existante couvre — mais c'est à vérifier, pas à supposer.
5. **La couleur seule ne survit pas à la photocopie.** D'où la colonne N/R.
6. **`null` en `whereArgs` lève** (défaut latent connu, cf. mémoire projet). Les
   filtres optionnels construisent la clause, ils ne passent jamais `null` en
   argument.
7. **Le fuseau.** `/till` renvoie un `timeZone` : le serveur arrête ses journées
   dans celui de l'école. Un « jour » recalculé sur `paid_at` avec le fuseau de
   l'appareil donnera un autre total. Figer le fuseau de l'école dans
   `ReportPeriod`.
8. **`AppPageBackground` plafonne le contenu à 1180 px** — vérifié sur le
   contrôle des frais.
9. **`accueil_page_test.dart` code en dur le nombre de sous-modules.** Trois
   sous-menus ajoutés, c'est ce test qui rougit en premier.
10. **Un élève peut apparaître deux fois** si `ref_classroom_members` porte
    plusieurs lignes pour lui : filtrer `status = 'ACTIVE'`.
11. **Le local peut être en retard.** Toute pièce d'ED-5 et ED-6 porte sa
    fraîcheur en tête. Une pièce muette sur son âge est une pièce qui ment.

---

## 8. Points ouverts

* **PO-1 — Quels statuts comptent comme « inscrit » ?** Proposition :
  `COMPLETED`, `FINANCIAL_COMPLETED`, `ADMIN_COMPLETED` ; exclus `CANCELLED`,
  `PRE_REGISTERED` et `IN_PROGRESS` — une liste des inscrits ne doit pas
  contenir des brouillons. **À confirmer avant ED-3.**
* **PO-2 — Demande back :** ventilation par cycle et par niveau sur `/recovery`
  et `/till`. Sans elle, ED-4 restera sans filtres pour toujours.
* **PO-3 — Police :** accepter le WinAnsi (aucun asset) ou embarquer une police
  Unicode. Dépend des jeux de caractères réellement saisis dans les noms.
* **PO-4 — `/recovery` expose-t-il un fuseau ?** Seul `/till` en porte un dans
  les entités actuelles. À vérifier contre le Swagger avant ED-4.
