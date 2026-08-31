# Multi-devise — plan front

> **Contrat back : « Rupture multi-devise », révision 4 du 30 août 2026.**
> Note de conception associée : « Deux devises au guichet ».
>
> ✅ **`openApi.yaml` est à jour et fait foi sur les noms exacts.** Les formes
> décrites ici peuvent être codées. Le back-end n'est pas encore fusionné — les
> lots de contrat (MD-7 → MD-9) se codent contre la spec et se mergent après lui.
>
> ✅ **Le verrou de production est levé** : D5b est livré, les indicateurs sont
> ventilés, et l'endpoint de pilotage ne refuse plus une école bi-devise. **Ne
> pas coder de garde front temporaire** — elle était la décision n°1 du premier
> jet, elle est caduque.

**Décisions actées.**

| | |
|---|---|
| `payments.amount_in_cents` en local | **Dérivé des allocations**, comme le back — la colonne disparaît (MD-4) |
| La boutique | **Fermée dans ce chantier** (MD-6) |
| Pastille d'AppBar en multi-devise | **« dû » sans montant** au-delà d'une devise ; montant conservé en mono-devise (MD-2). *Tranché faute d'arbitrage — se renverse en une ligne.* |
| Arriéré N-1 affiché à la réinscription | **Non** — statu quo. Hors périmètre de la rupture |

---

## 1. Ce que dit la révision 3

### La forme partout

```json
{ "amountInCents": 42500, "currency": "USD" }
```

Elle s'appelle **`Money`** dans la spec — une seule classe, partagée par tous les
champs ci-dessous. `USD` · `CDF` · `EUR`, majuscules.

### Trois ruptures, six payloads

| Lot back | Rupture | Payloads |
|---|---|---|
| **D2** | un versement porte plusieurs montants (`amounts[]`) | `CreatePaymentRequest`, `PaymentDto`, `PaymentInput`, `PaymentDelta` |
| **D4** | le solde N-1 devient `previousBalances[]` | `ReenrollmentCandidate` |
| **D5b** | `kpis`, `evolution`, `distributionByFeeType` descendent dans `byCurrency[]` | `FinanceStatsResponse` |
| **caisse · envoi** | une **vente** porte `amounts[]`, `currency` obligatoire **par ligne** | vente boutique (push) |
| **caisse · réception** | même bascule en lecture | `BoutiqueSaleDelta`, accusé, ligne de caisse |

> ### 🔄 Révision 4 — la boutique n'est plus épargnée
>
> Les révisions 1 à 3 annonçaient une caisse **inchangée**. Ce n'est plus vrai :
> une vente mixte devient **un acte de caisse, une vente, un reçu** — imposer
> deux gestes au caissier serait « laisser le schéma dicter le métier ».
>
> - `currency` **obligatoire sur chaque ligne**, et c'est la devise **réellement
>   encaissée**, jamais déduite du catalogue. Un article passé du franc au dollar
>   pendant que la tablette était hors ligne ne doit pas faire imprimer des
>   dollars sur un reçu dont le tiroir contient des francs.
> - Un tel décalage **ne refuse pas la vente** : anomalie remontée dans
>   `divergences`. Seul un code hors `USD/CDF/EUR` est refusé
>   (422 `UNKNOWN_CURRENCY`).
> - `INCONSISTENT_TOTAL` se vérifie **devise par devise**. Une devise dont les
>   lignes totalisent zéro — un article offert — **n'a pas** à figurer dans
>   `amounts`.
> - **Le catalogue ne change pas** : c'est la vente qui bascule.

> ### ⚠️ Le piège qui casse en silence : `totals[].saleCount`
>
> Il **garde son nom et change de sens** : il disait « ventes faites en cette
> devise », il dit « ventes ayant **touché** cette devise ». Une vente mixte
> compte dans les deux, donc **la somme de cette colonne dépasse le nombre de
> ventes**. Un `saleCount` **racine** a été ajouté — lui seul donne le nombre de
> ventes du jour.
>
> ✅ **Sans effet chez nous aujourd'hui** : le front n'a aucun écran de fermeture
> de caisse, et `boutique_history_state.dart` agrège **localement** — son
> `totalsByCurrency` est d'ailleurs déjà ventilé. Le `saleCount` que porte
> `BoutiquePayer` est celui de l'annuaire de payeurs, compté en SQL local, sans
> rapport. **À relire le jour où l'écran de caisse arrivera** : c'est la seule
> rupture du lot qui continuerait d'afficher un nombre, simplement faux.

### Nouveautés de la révision 3

1. **D5b est livré.** `context.currency` **disparaît**. Le 422 « devises mixtes »
   **disparaît**. `byCurrency` est trié par code de devise croissant, **l'axe du
   temps est identique dans tous les blocs** (mêmes clés, même
   `currentBucketIndex`), et il est **vide** — jamais un zéro — quand aucun
   argent n'a circulé sur la fenêtre.
2. **Route back-office corrigée :** `POST /api/v1/finance/payments`.
   → **Sans effet chez nous** : `AppConstants.createPaymentEndpoint:104` porte
   déjà la bonne route.
3. **Cette route rendait un 500 sur ces erreurs, elle rend maintenant un 422
   nommé.** → **Sans effet chez nous** : `PaymentsRepositoryImpl` n'a aucun
   traitement particulier du 500, tout passe par l'intercepteur.
4. **`detailCode` est posé — 5 causes.** `ALLOCATION_SUM_MISMATCH`,
   `CHARGE_CURRENCY_MISMATCH`, `UNKNOWN_STUDENT_CHARGE`, `UNKNOWN_FEE_CODE`,
   `AMBIGUOUS_FEE_CODE`. Valables sur les **deux** routes de paiement.
5. **L'enum de devise se resserre aussi en LECTURE**, sur dix champs. Cinq nous
   concernent : `FeeTariffDto`, `StudentChargeDto`, `OverpaymentSignal`,
   `PlannedFee`, et **les imputations d'un `PaymentDelta`**.

> #### ⚠️ Ne pas générer d'enum stricte pour `currency`
>
> Le back prévient : *« si votre générateur produit des enums strictes, sachez
> que c'est là que ça se verrait »*. Nos cinq DTO parsent `currency` en `String`
> brut, à la main — **rien ne casse, et il faut que ça reste ainsi**. Une devise
> ajoutée un jour côté serveur ferait échouer la désérialisation d'un
> `PaymentDelta` entier : de l'argent déjà encaissé, invisible au pull. C'est la
> convention maison — `PaymentAnomalyKind.unknown`, `GeneratedDocumentDto`
> — et elle prime ici. **Normaliser** (trim + majuscules), **ne pas fermer**.

> #### ✅ Le piège de l'allocation du delta est probablement refermé
>
> Le premier jet nous laissait avec `PaymentPullAllocationDto` sans `currency`,
> repris du parent — faux dès qu'un versement en porte deux. La révision 3 range
> « les imputations d'un `PaymentDelta` » parmi les champs `currency` **de
> lecture** : le champ existe donc dans la spec. **À confirmer sur
> `openApi.yaml` en ouvrant MD-8**, avant d'écrire le mapper.

### Ce qui ne bouge pas

Les imputations (scalaires), les créances, les PDF, les identifiants / curseurs /
l'idempotence, les stats d'inscription / présence / classe, et — **côté back** —
la boutique, dont le `currency` reste en chaîne libre dans la spec.

---

## 2. La règle qui gouverne tout

> Une liste de montants n'est pas une somme à faire. 425,00 $ et 90 000 FC
> s'affichent côte à côte, jamais additionnés — leur total n'existe pas.

Trois corollaires, à appliquer sans exception :

- **Une liste vide ≠ zéro.** Un élève sans charge ne doit rien, et on ne sait pas
  dans quelle unité. Le rendu du vide n'est jamais « 0 USD ».
- **Jamais deux devises sur un même axe Y.** L'écart d'échelle est de ×2 800 :
  une courbe en francs écrase une courbe en dollars jusqu'à l'illisible. Le back
  garantit l'axe des **X** identique — c'est ce qui permet d'**empiler** les
  graphiques, pas de les superposer.
- **Une allocation ne vise qu'une créance, donc qu'une devise.** Tout ce qui est
  au niveau de l'imputation reste scalaire, définitivement.

---

## 3. Ce qui est déjà faux aujourd'hui

Dix endroits, tous bâtis sur le même motif : `.fold()` sur les montants **plus**
la première devise venue en étiquette. Deux touchent de l'argent. **Aucun
n'attend le back** : il suffit qu'une école ait deux tarifs.

| # | Emplacement | Défaut | Lot |
|---|---|---|---|
| 1 | `finance/presentation/widgets/facturation_create_payment_dialog.dart:205-216` | **Total du versement au guichet.** `_totalInCents` somme toutes les allocations, `_currency` retient la première non vide → 425 $ + 90 000 FC = « 90 425,00 $ » sur le bandeau or, sur le ticket, dans le payload (42 500 + 9 000 000 centimes, sommés sans égard à l'unité) | **MD-5** |
| 2 | `finance/offline/data/repositories/finance_offline_repository_impl.dart:71-86` | **Fail-fast local** « total ≠ Σ allocations », toutes devises confondues. `ALLOCATION_SUM_MISMATCH` étant resserré devise par devise, un versement mixte mal réparti passe, part, revient en 422 → `failed` → `SYNC_ERROR` : argent encaissé, reçu imprimé, hors du grand-livre | **MD-5** |
| 3 | `finance/presentation/pages/facturation_detail_page.dart:260-284` | 3 cartes KPI du dossier élève + `studentCharges.first.currency` | MD-2 |
| 4 | `finance/presentation/pages/facturation_detail_page.dart:406-413` | Pastille d'AppBar « {montant} dû » | MD-2 |
| 5 | `finance/presentation/widgets/facturation_detail_payments_section.dart:93-99` | « N versements · total X », `payments.first.currency` | MD-2 |
| 6 | `enrollment/presentation/widgets/enrollment_summary/summary_charges_section.dart:67-71` | Total dû du récapitulatif | MD-3 |
| 7 | `enrollment/presentation/widgets/enrollment_summary/summary_compact_header.dart:32-36` | Le même total, en-tête compact | MD-3 |
| 8 | `enrollment/presentation/widgets/student_charges/student_charges_step_body.dart:66-77` | Total de l'étape « frais » | MD-3 |
| 9 | `finance/offline/data/local/dao/finance_ledger_read_dao.dart:222-231` | `MIN(sc.currency)` sur `GROUP BY student_id` — Contrôle des frais | MD-3 |
| 10 | `finance/domain/entities/finance_stats/finance_kpis.dart` · `…/finance_stats_kpi_band.dart:76` | 4 KPI **sans aucune devise**, affichés en nombre nu | MD-9 |

Et **sept replis `?? 'USD'` en dur, sur des chemins de lecture** :
`referential_pull_models.dart:190`, `provisioning_draft_dao.dart:214`,
`fee_tariff_payload_model.dart:66`, `provisioning_plan_model.dart:201`,
`boutique_confirm_dialog.dart:58`, `boutique_cart_footer.dart:92`,
`boutique_sale_repository_impl.dart:76`. *(Les `?? 'USD'` des formulaires de
Configuration sont des défauts de saisie légitimes — l'utilisateur choisit
ensuite. Ne pas les toucher.)*

---

# Les lots

```
MD-0  socle core/money
 │
MD-1  formatage unifié
 │
 ├── MD-2  agrégats Facturation           ┐
 ├── MD-3  agrégats Inscription + Frais   │ aucune dépendance back
 ├── MD-5  le guichet + garde anti-mixte  │ aucun contrat touché
 └── MD-6  la boutique                    ┘
 │
 ├── MD-7  D4 · cohorte  (v34)            ┐
 ├── MD-8  MD-4 (schéma v33) + D2         │ contre la spec, merge après le back
 ├── MD-9  D5b · pilotage                 │
 └── MD-10 erreurs nommées                │
 └── MD-12 caisse boutique · amounts[]    ┘ ← rév. 4
 │
MD-11 revue adversariale + mutations
```

> ## ✅ TOUT EST LIVRÉ
>
> Les douze lots sont faits, contrats compris : le front est **aligné sur la
> révision 4**. `flutter analyze` clean, **4 836 tests verts**, 20 mutations
> prouvées. Schéma **v32 → v35**.
>
> Les quatre questions au back ont toutes trouvé leur réponse — deux dans
> `openApi.yaml`, une en lisant `StudentChargeResolver`, une par la révision 4
> elle-même. Il ne reste plus qu'à attendre le merge du back.
>
> Les deux gardes temporaires (guichet et caisse) ont été **levées** par les lots
> qui ouvraient leurs contrats, comme annoncé.

**Le pari : MD-0, MD-1, MD-2, MD-3, MD-5 et MD-6 avant tout lot de contrat.** Ils ne touchent aucun
payload, ne dépendent d'aucun merge, et rendent le rendu **identique en
mono-devise** — une liste à une entrée s'affiche comme le scalaire d'aujourd'hui
— donc les suites existantes restent vertes et servent de filet. Ils ferment les
deux défauts qui touchent de l'argent. Si le back glisse, rien n'est perdu.

---

## MD-0 · Socle `core/money`

**Objectif.** Un type `Money`, un porteur de liste sans total, une normalisation.

**Fichiers créés** — `lib/core/money/` :

| Fichier | Contenu |
|---|---|
| `money.dart` | `Money { int amountInCents; String currency }`, `Equatable`. Constructeur normalisant (trim + majuscules) |
| `money_bag.dart` | La liste par devise. `entries` triée par code croissant (l'ordre du serveur), `isEmpty`, `isMultiCurrency`, `single` (`null` si 0 ou 2+), `operator +`, `MoneyBag.sumBy<T>()`. **Aucun `total`, aucun `toInt()`** |
| `currency_code.dart` | `normalize(String)` — trim + majuscules. Constantes `usd`/`cdf`/`eur`. **Pas d'enum, pas de validation fermée** (§1) |

**Points de conception non négociables.**

- `MoneyBag` n'expose **jamais** de total scalaire. La tentation reviendra à
  chaque lot ; l'API doit rendre le geste impossible, pas déconseillé.
- `MoneyBag.sumBy` groupe par devise — c'est **le** remplaçant des dix `.fold()`.
- `single` est ce qui rend le rendu mono-devise identique à aujourd'hui : les
  écrans testent `single != null` et n'ont rien d'autre à changer dans ce cas.

**Tests.** `test/core/money/` — normalisation (casse, espaces), groupement,
tri stable, vide ≠ zéro, `single` nul à 0 et à 2 entrées, addition commutative.

**Fini quand** le socle existe, est testé, et n'est encore utilisé nulle part.

---

## MD-1 · Formatage unifié

**Objectif.** Une seule règle d'écriture d'un montant, celle de D6a.

**Le problème.** Quatre conventions divergentes aujourd'hui :

| Où | Règle actuelle | 42500 · USD | 9000000 · CDF |
|---|---|---|---|
| `core/widgets/currency_field.dart:6` `formatMonetaryAmount` | décimales selon **la valeur** | `425 USD` | `90 000 CDF` |
| `boutique/…/boutique_money_format.dart` | `$` pour USD, code sinon | `425 $` / `425.00 $` | `90000 CDF` |
| `documents/…/ticket_text_layout.dart:163` | **toujours** 2 décimales | `425,00 USD` | `90 000,00 CDF` |
| `configuration/domain/fee_amount.dart:34` | délègue au core, **mais** `CDF` → « FC » | `425 USD` | `90 000 FC` |

**La règle cible (D6a).** Les décimales se décident sur **la devise**, jamais sur
la valeur — et la valeur ne peut qu'en **rajouter** :

```
décimales affichées = max( decimalsOf(currency),  cents % 100 != 0 ? 2 : 0 )

USD  42500   → « 425,00 $ »        USD  42550   → « 425,50 $ »
CDF  9000000 → « 90 000 FC »       CDF  9000050 → « 90 000,50 FC »
```

*« Une convention d'écriture ne doit jamais arrondir sous les yeux du lecteur. »*

**Fichier créé.** `lib/core/money/money_format.dart` :
`decimalsOf` (USD/EUR 2, CDF 0, défaut 2), `symbolOf` (USD → `$`, CDF → `FC`,
sinon le code), `format(Money)`, `formatCompact(Money)` (le besoin catalogue de
la boutique).

**Fichiers réécrits en façades** — signatures publiques **inchangées**, pour ne
pas transformer ce lot en refactor de 40 fichiers :

- `core/widgets/currency_field.dart` — `formatMonetaryAmount`,
  `formatMonetaryAmountWithCurrency`
- `boutique/presentation/helpers/boutique_money_format.dart` — `compact`, `exact`
- `documents/domain/ticket/ticket_text_layout.dart:163` — `formatAmount`
- `configuration/domain/fee_amount.dart` — `display`, `displayCurrency`

**⚠️ Pièges.**

- Le **ticket thermique** exige l'espace **normal** comme séparateur de milliers
  (une imprimante ne rend pas l'insécable) — le socle doit porter ce paramètre,
  pas le contourner. Le reste de l'app garde l'insécable.
- Le passage de `formatMonetaryAmount` à la règle par devise **change des
  rendus USD existants** : « 425 USD » devient « 425,00 $ ». C'est voulu, mais
  ça fait rougir des tests d'attente de chaîne. Ils épinglaient une écriture que
  le back nous demande de changer — **les retourner, pas les contourner.**
- `FeeAmount.inputFromCents` sert à **remplir un champ de saisie**, pas à
  afficher : il ne doit pas hériter du symbole. Vérifier avant de le brancher.

**Tests.** `test/core/money/money_format_test.dart` — les quatre combinaisons du
tableau ci-dessus, l'espace du ticket, et un test de non-régression par façade.

**Fini quand** les quatre chemins passent par `MoneyFormat` et qu'un même montant
s'écrit pareil sur les quatre surfaces.

---

## MD-2 · Agrégats honnêtes — Facturation

**Objectif.** Fermer #3, #4, #5. Aucun contrat touché.

**Fichiers.**

| Fichier | Change |
|---|---|
| `presentation/pages/facturation_detail_page.dart:260-284` | Les trois `.fold<double>` → `MoneyBag.sumBy` sur `studentCharges` (attendu / payé / reste). `first.currency` supprimé |
| `presentation/widgets/finance_detail_kpi_strip.dart` | `totalDueCents` + `currency` → trois `MoneyBag`. Chaque carte rend ses lignes empilées |
| `presentation/pages/facturation_detail_page.dart:406-413` | Pastille : `MoneyBag` du reste. `single != null` → « {montant} dû » ; sinon → « dû » nu |
| `presentation/widgets/facturation_detail_payments_section.dart:93-99` | Total des versements → `MoneyBag` |
| `presentation/helpers/finance_csv_export_helper.dart` | Vérifier le pied. La colonne `currency` **par ligne** existe déjà — probablement conforme |

**⚠️ Piège de mise en page.** `AppPageBackground` **plafonne à 1180 px** : tout
seuil responsive posé au-dessus rend la disposition large inatteignable. Trois
cartes qui deviennent trois cartes × N lignes tiennent en hauteur, pas en
largeur — **empiler dans la carte**, ne pas multiplier les cartes.

**Tests.** Rendu mono-devise **identique** (les tests existants doivent passer
sans être touchés — c'est le critère de réussite du lot). Nouveaux cas
bi-devises : deux lignes par carte, pastille sans montant, liste vide.

---

## MD-3 · Agrégats honnêtes — Inscription et Contrôle des frais

**Objectif.** Fermer #6, #7, #8, #9.

**Fichiers.**

| Fichier | Change |
|---|---|
| `enrollment/…/summary_charges_section.dart:67-71` | `.fold` + `first.currency` → `MoneyBag` |
| `enrollment/…/summary_compact_header.dart:32-36` | idem |
| `enrollment/…/student_charges_step_body.dart:66-77` | idem, sur les montants du brouillon |
| `finance/offline/…/finance_ledger_read_dao.dart:222-231` | `MIN(sc.currency)` → `GROUP BY sc.student_id, sc.currency` |
| `finance/offline/domain/entities/local_fee_charge_aggregate.dart` | Une ligne par (élève, devise) ; `remainingInCents` reste scalaire **par devise** |
| `finance/presentation/widgets/fee_control_table_layout.dart` | Une ligne d'élève peut porter deux montants |

**⚠️ Question ouverte au back, à poser avant d'ouvrir ce lot.** *Un même
`fee_code` peut-il porter deux devises selon le niveau ?* La requête est bornée
à **un** `fee_code`, donc `MIN(sc.currency)` est sûr **si** la réponse est non.
Si elle est oui, le tableau du Contrôle des frais peut porter deux montants sur
une même colonne, et la mise en page change.
→ Faire le `GROUP BY` dans tous les cas : il est correct des deux côtés de la
réponse, et coûte un index déjà présent (`idx_student_charges_student_fee`).

**Tests.** Idem MD-2 : mono-devise inchangé, cas bi-devises ajoutés. Le DAO se
teste sur base ffi avec deux créances de devises différentes pour le même élève.

---

## MD-4 · Schéma v33 · montants dérivés des allocations

> ### ✅ FINALEMENT JOUÉ, dans MD-8 — la spec a levé l'obstacle
>
> Le report ci-dessous tenait à une lecture du contrat de synchro. `openApi.yaml`
> tranche : l'imputation d'un `PaymentDelta` porte **son propre** `currency`,
> « toujours présent », et le back écrit noir sur blanc que c'est *« ce qui
> permet à un client de reconstruire le total par devise du versement sans faire
> confiance à `amounts` »*. La seule source manquante ne manquait pas.
>
> `payments` a donc perdu ses montants (palier v34), comme prévu à l'origine.
>
> ### Ce que le report disait (conservé — le raisonnement reste juste)
>
> ### 🔴 REPORTÉ — ce lot **ne peut pas** précéder MD-8
>
> Découvert en l'ouvrant. `PaymentPullAllocationDto` **ne porte pas** de
> `currency` : `toLocalModel(currency: payment.currency)` la reprend du
> **paiement parent** (`finance_pull_models.dart:224-262`), et
> `PaymentLocalModel.toPullPatch()` réécrit `payments.currency` à chaque delta.
>
> Retirer `payments.currency` maintenant supprimerait donc **la seule source de
> devise** des allocations venues du pull — un versement encaissé sur un autre
> poste arriverait sans unité. Le contrat actuel fournit encore cette colonne ;
> la jeter avant que l'allocation ne porte la sienne (rév. 3, branchée en MD-8)
> serait perdre une information qu'on a.
>
> **Le back a fait le même choix** : chez lui aussi « les montants quittent
> `payments` » est *dans* D2 (migration V104), pas avant. Le plan les avait
> séparés à tort.
>
> ⇒ **MD-4 fusionne dans MD-8**, dont il devient la première étape (le palier de
> schéma, puis les payloads). Le contenu ci-dessous reste valable tel quel.


**Objectif.** Suivre le back : `payments` ne porte plus de montant. **Refactor
pur, comportement inchangé** — c'est le pendant du `D5a` que le back s'est
détaché pour la même raison.

**Schéma.** `core/database/schema/enrollment_finance_offline_schema.dart:461-491`
→ retrait de `amount_in_cents` et `currency` de `payments`. Palier `upTo(33)`
dans `core/database/app_database.dart`.

**Ce qui doit être re-routé sur `payment_allocations`** avant le retrait :

- `finance/offline/data/local/models/payment_local_model.dart`
- `finance/offline/data/local/dao/finance_ledger_read_dao.dart:50` — `getPaymentsByStudent`
- `finance/offline/data/mappers/local_finance_online_mappers.dart`
- `finance/presentation/widgets/facturation_offline_payment_mapper.dart:21`
- `documents/data/local/provisional_ticket_dao.dart` — le ticket provisoire
- `finance/offline/data/repositories/finance_offline_repository_impl.dart` — cesse d'écrire les deux colonnes

La jointure existe déjà et est éprouvée : `finance_ledger_read_dao.dart:29`.

**⚠️ Pièges de migration.**

- **Un palier écrit avec le schéma d'aujourd'hui casse toute base montant d'une
  version antérieure** — le palier v2 posait un index d'aujourd'hui sur une
  table d'alors. Écrire le palier v33 contre le schéma **v32**, pas contre le
  fichier de schéma courant.
- SQLite ne sait pas `DROP COLUMN` avant 3.35 : passer par
  table temporaire → copie → `DROP` → `RENAME`, et **recréer les deux index**
  (`idx_payments_student`, `idx_payments_client_uuid`).
- `INSERT OR REPLACE` + index unique partiel = destruction silencieuse.
- Aucune purge sans rembobinage de curseur.

**Tests.** `test/core/database/offline_migration_multidevise_v33_test.dart` —
montée depuis une base v32 **peuplée** (paiements + allocations), les totaux
dérivés égalent les scalaires d'avant, les index survivent. Plus les suites
existantes du DAO et du ticket, inchangées.

**Fini quand** la colonne n'existe plus, que rien ne la lit, et qu'aucun test
existant n'a eu besoin d'être modifié autrement que pour la retirer de ses
fixtures.

---

## MD-5 · Le guichet multi-devise

**Objectif.** Fermer #1 et #2 — les deux défauts qui touchent de l'argent.

**Fichiers.**

| Fichier | Change |
|---|---|
| `finance/offline/domain/repositories/finance_offline_repository.dart:26-56` | `RecordPaymentDraft` : `currency` + `amountInCents` → `MoneyBag amounts` (ou `null` → Σ allocations par devise) |
| `finance/offline/data/repositories/finance_offline_repository_impl.dart:71-86` | **Le fail-fast devient par devise.** `total ≠ Σ allocations` → comparaison de deux `MoneyBag` |
| `finance/presentation/widgets/facturation_create_payment_dialog.dart:205-216` | `_totalInCents`/`_currency` → un `MoneyBag`. Bandeau or en liste |
| `…/facturation_create_payment_dialog.dart:298-338` | Garde d'envoi : `total > 0 && currency.isEmpty` → `bag.isNotEmpty` |
| `…/facturation_create_payment_confirm_dialog.dart` | Confirmation ventilée |
| `documents/domain/ticket/ticket_receipt_model.dart:133-141` | `amountReceivedInCents` + `currency` → `MoneyBag` ; `remainingBalanceInCents` → `MoneyBag?` |
| `documents/domain/ticket/ticket_text_layout.dart:94-146` | Montant reçu, ligne d'avance et solde ventilés. **La répartition est déjà par ligne** — rien à y faire |

> ### 🔴 Découvert en implémentant MD-4 : MD-5 ne peut pas ouvrir le mixte seul
>
> Le payload de push n'est **pas figé dans l'outbox** : `finance_payment_write_dao.dart:131-160`
> le **reconstruit depuis la table** `payments` au moment de l'envoi.
>
> Conséquence : tant que **MD-8 (D2)** n'est pas livré, le contrat de push reste
> scalaire. Un versement composé en deux devises par un guichet MD-5 partirait
> avec un `amountInCents` unique — refusé par le serveur en
> `ALLOCATION_SUM_MISMATCH` (resserré devise par devise) → `failed` →
> `SYNC_ERROR`. **C'est exactement le défaut n°2 que le lot existe pour fermer,
> recréé par le lot lui-même.**
>
> **MD-5 pose donc une garde temporaire** : le guichet refuse de composer un
> versement à deux devises, et le dit — « encaissez-les séparément », deux
> versements, deux reçus. Dégradé, mais l'argent remonte. **MD-8 retire cette
> garde** dans le même commit qu'il ouvre le contrat.
>
> Tout le reste de MD-5 est joué : total ventilé, fail-fast par devise, ticket
> ventilé. Ce sont eux qui ferment les défauts ; la garde ne fait qu'empêcher
> d'en ouvrir un nouveau en attendant le back.

**⚠️ Le fail-fast est la pièce maîtresse.** Il est ce qui empêche un 422 sur de
l'argent déjà reçu. Sa version par devise doit refuser un versement dont une
devise est mal répartie **même si le total global colle** — c'est exactement le
resserrement de `ALLOCATION_SUM_MISMATCH`. Le message d'erreur doit nommer la
devise fautive, pas seulement l'écart.

**⚠️ Le ticket fait 32 colonnes.** « Montant reçu » sur deux devises ne tient pas
sur une ligne. Deux lignes étiquetées, ou une ligne par devise sous un intitulé
unique — à décider en imprimant, pas sur écran. *(Piège connu : le spouleur
Android ne voit pas la NT-8003DD, ESC/POS est le seul chemin.)*

**⚠️ « Tout solder » traverse les devises** et produit un versement mixte. C'est
le cas nominal du nouveau modèle, pas un cas limite — il doit être le premier
test écrit.

**Tests.** Versement mono-devise : comportement **identique**, tests existants
verts. Versement mixte : total ventilé, fail-fast qui laisse passer une
répartition juste et refuse une répartition fausse dans une seule devise, ticket
rendu à 32 colonnes, « Tout solder » sur deux devises.

---

## MD-6 · La boutique

**Objectif.** Refermer le trou que le code désigne lui-même.

> *« Un panier USD + CDF est donc additionné par `totalInCents`, encaissé, et
> scellé avec un total qui n'a pas de sens, sans que rien ne le signale au
> caissier. C'est le trou que la branche multi-devises devra fermer. »*
> — `boutique/domain/entities/boutique_cart.dart:44-56`

`isMultiCurrency` existe déjà et a été **délibérément gardé** pour ce lot.

**Fichiers.**

| Fichier | Change |
|---|---|
| `boutique/domain/entities/boutique_cart.dart:30-37` | `totalInCents` → `MoneyBag totals` ; `currency` (première ligne) **supprimé** |
| `…/boutique_cart.dart:69-105` | `blockers` : le mélange **bloque temporairement**, le temps que le contrat de la rév. 4 soit fusionné (MD-12). « Pas encore », et non « jamais » |
| `boutique/presentation/widgets/boutique_cart_footer.dart:92` | Pied ventilé ; `?? 'USD'` retiré |
| `boutique/presentation/widgets/boutique_confirm_dialog.dart:58` | idem |
| `boutique/data/repositories/boutique_sale_repository_impl.dart:76` | idem — **⚠️ la devise scellée sur la vente** |
| `boutique/data/ticket/sale_ticket_composer.dart` · `domain/ticket/sale_ticket_*.dart` | Ticket de vente ventilé |

**⚠️ Le back n'a rien changé ici.** Le contrat de vente reste scalaire et son
`currency` reste en chaîne libre. **Vérifier ce que le push attend** avant de
toucher `boutique_sale_repository_impl.dart:76` : si la vente ne porte qu'une
devise sur le fil, un panier mixte doit se scinder ou se refuser — et ça, c'est
une décision produit à reposer, pas une correction d'affichage.
→ **Ouvrir MD-6 par cette question**, pas par le code.

---

## MD-7 · D4 · Cohorte de réinscription *(contrat · v34)*

**Objectif.** `previousBalanceInCents` + `currency` → `previousBalances[]`.

**Zéro travail d'interface** : la recherche est exhaustive, le champ n'apparaît
que dans l'entité, le DAO, le modèle de pull, le schéma et cinq tests.

**Fichiers.**

| Fichier | Change |
|---|---|
| `enrollment/offline/data/sync/reenrollment_cohort_pull_models.dart:53-98` | `previousBalances: List<Money>`, défaut `const []` |
| `enrollment/offline/domain/entities/reenrollment_candidate.dart:22-23` | `MoneyBag previousBalances` |
| `enrollment/offline/data/local/dao/enrollment_seed_dao.dart:50,206` | Écriture / relecture |
| `core/database/schema/enrollment_finance_offline_schema.dart:302-325` | Table fille `ref_previous_year_student_balances(student_id, currency, amount_in_cents)`, clé `(student_id, currency)`. Palier `upTo(34)` |

**Pourquoi une table fille et non un JSON.** La cohorte se re-seede par lots ; un
JSON obligerait à relire-modifier-réécrire une chaîne à chaque pull, là où une
table fille se remplace par `DELETE … WHERE student_id IN (…)` + `INSERT`, sous
le même index que le reste du seed.

**⚠️ `previousBalances` absent ou vide = ne doit rien**, jamais « 0 USD ». Le
défaut de parsing est la liste vide, pas `[Money(0, 'USD')]`.

**Tests.** Parsing (présent / absent / vide), seed + relecture, migration v33→v34
depuis une base peuplée (le scalaire existant devient une entrée, `currency` nulle
→ aucune entrée).

---

## MD-8 · D2 · Le versement *(contrat)*

**Objectif.** Les quatre payloads. **Le seul lot réellement risqué.**

**Fichiers.**

| Fichier | Sens | Change |
|---|---|---|
| `finance/data/models/create_payment_request_model.dart` | envoi online | `amountInCents`+`currency` → `amounts[]` |
| `finance/data/models/payments_model.dart` · `domain/entities/payment.dart` | réception online | idem |
| `finance/offline/data/sync/payment_push_request_models.dart` (`PaymentInput`) | push | idem |
| `finance/offline/data/sync/finance_pull_models.dart:111-186` (`PaymentDto`) | pull | idem |
| `finance/offline/data/sync/finance_pull_models.dart:224-262` | pull | `PaymentPullAllocationDto` prend son **propre** `currency` (§1) |
| `finance/domain/repositories/payments_repository.dart` · `usecases/create_payment_usecase.dart` | | signatures |

**Les imputations ne bougent pas.** `PaymentAllocationInput`,
`PaymentAllocationsModel`, `PaymentAllocation` : montant et devise scalaires.

> ### ⚠️ Le piège qui coûte de l'argent : l'outbox relit d'anciens payloads
>
> `PaymentAggregateRequest.fromJson` tolère **déjà deux formes** — imbriquée
> 1.1.0 et l'ancienne à plat — précisément parce qu'une tablette mise à jour
> hors ligne peut porter en file un versement écrit par la version précédente.
> Il lui en faut une **troisième** : montant scalaire → `amounts[]`.
>
> Le fichier dit lui-même ce que coûte l'oubli : *« le cash encaissé au guichet,
> reçu déjà imprimé, ne remonterait JAMAIS et l'élève resterait débiteur. »*
>
> **Test obligatoire du lot :** un payload d'outbox écrit à la main dans la forme
> scalaire, relu par le nouveau parseur, poussé, acquitté.

**⚠️ Avant d'écrire le mapper**, confirmer sur `openApi.yaml` : (a) que
l'imputation d'un `PaymentDelta` porte bien `currency`, (b) le nom exact du champ
liste (`amounts`), (c) que `PaymentDto` en réception porte la même forme que
`PaymentInput` en envoi.

**Tests.** Aller-retour JSON sur les quatre payloads, les trois formes d'outbox,
push mixte acquitté, remap d'allocations inchangé, idempotence du rejeu.

---

## MD-9 · D5b · Le tableau de bord par devise *(contrat)*

**Objectif.** `byCurrency[]`, et fermer #10.

**Ce qui casse dur.** `FinanceStatsResponseModel.fromJson` lit
`json['kpis'] as Map<String, dynamic>` : avec `byCurrency`, **il lève**.

**Non-événements, à ne pas chercher.**
`context.currency` disparaît → `StatsContextModel` de finance **ne le lisait
déjà pas** (celui de présence porte un commentaire disant qu'il l'ignore).
Le 422 « devises mixtes » disparaît → nous n'avions **aucun** traitement
spécifique à retirer.

**Fichiers.**

| Fichier | Change |
|---|---|
| `data/models/finance_stats_response_model/finance_stats_response_model.dart` | `kpis`/`evolution`/`distributionByFeeType` → `List<FinanceCurrencyBlockModel> byCurrency` |
| `data/models/finance_stats_response_model/` | **Nouveau** `finance_currency_block_model.dart` |
| `domain/entities/finance_stats/finance_stats.dart` | `List<FinanceCurrencyBlock> byCurrency` |
| `domain/entities/finance_stats/` | **Nouveau** `finance_currency_block.dart` |
| `domain/entities/finance_stats/finance_kpis.dart` | inchangée — elle descend d'un niveau, elle ne change pas de forme |
| `presentation/widgets/finance_stats_success_view.dart` | Répétition du bloc complet par devise |
| `presentation/widgets/finance_stats_kpi_band.dart:76` | Le montant porte enfin sa devise |

**Rendu.** **Répéter le bloc complet par devise**, sous un en-tête de devise —
et non un sélecteur. Le back dit « les blocs se regardent côte à côte » ; un
sélecteur cacherait la moitié du pilotage derrière un clic, et c'est justement
la comparaison qui a de la valeur. L'axe des X étant garanti identique, les
graphiques empilés s'alignent naturellement.

**⚠️ Jamais deux devises sur un même axe Y** (§2).

**⚠️ `byCurrency` vide** = aucun argent sur la fenêtre. C'est un **état vide**,
pas une erreur ni un zéro → `EteeloEmptyResult`, règle non négociable #10.

**⚠️ Une devise** doit rendre **exactement** l'écran d'aujourd'hui, en-tête de
devise compris ou non — à trancher à la maquette.

**Tests.** Parsing (0 / 1 / 2 blocs), ordre stable, `currentBucketIndex` partagé,
état vide, rendu mono-devise non régressé.

---

## MD-10 · Les erreurs nommées

**Objectif.** Dire au guichet ce qu'il doit corriger.

**Fichier créé.** `finance/offline/data/sync/finance_error_codes.dart` — miroir
exact de `boutique/data/sync/boutique_error_codes.dart`, qui est le patron.

| `detailCode` | Classement proposé | Pourquoi |
|---|---|---|
| `ALLOCATION_SUM_MISMATCH` | `failed` | Défaut client déterministe — le panier a calculé faux |
| `CHARGE_CURRENCY_MISMATCH` | `failed` | idem |
| `UNKNOWN_FEE_CODE` | `failed` | Référentiel local en désaccord avec le serveur |
| `AMBIGUOUS_FEE_CODE` | `failed` | idem |
| **`UNKNOWN_STUDENT_CHARGE`** | **`retry`** | ⚠️ **Voir ci-dessous** |

> ### ⚠️ `UNKNOWN_STUDENT_CHARGE` est probablement transitoire, pas terminal
>
> Le serveur remappe par `studentId + feeCode`. S'il ne trouve pas la créance,
> c'est peut-être que **l'inscription de l'élève n'est pas encore remontée** —
> auquel cas le paiement repartira seul au cycle suivant. Le classer `failed`
> le figerait en `SYNC_ERROR` sur de l'argent qui n'avait qu'à attendre.
>
> C'est **exactement** le cas que la boutique documente : *« l'inscription du
> bénéficiaire n'est pas encore partie, la vente repartira seule »*.
>
> **À confirmer avec le back avant de figer le classement.** En cas de doute,
> `retry` est le sens de panne sûr : le POST est idempotent, et le poison finit
> par surfacer un `SYNC_ERROR` de toute façon.

**Fichiers.**

| Fichier | Change |
|---|---|
| `finance/offline/data/sync/payment_outbox_handler.dart:134-142` | `_classifyDioError` lit `ApiErrorParser.detailCodeOf` avant de classer sur le statut |
| `…/payment_outbox_handler.dart:145-149` | `_dioReason` → le patron `_reasonOf` de la boutique (code machine d'abord, message ensuite) |
| `finance/presentation/bloc/finance/payments_bloc.dart` | Les causes nommées ont leur message |
| `configuration/…` | Le **409** « devise d'un tarif figée » a un message |
| `lib/l10n/app_fr.arb` + `app_en.arb` | Les libellés, puis `flutter gen-l10n` **et `dart format lib/l10n/`** |

**Rien à retirer côté online.** `ApiValidationFailure.detailCode` remonte déjà
jusqu'aux repositories (`core/di/injection.dart:377`) : seul le chemin outbox
l'ignore.

**⚠️ `gen-l10n` sans `dart format lib/l10n/` = 1 500 lignes de churn** pour trois
clés.

---

## MD-11 · Revue adversariale et mutations

**Six mutations à faire échouer** — un test qui ne rougit pas sous mutation
n'épingle rien :

1. Rendre `MoneyBag.sumBy` insensible à la devise (tout dans une seule entrée).
2. Retirer la branche par devise du fail-fast de `recordPayment`.
3. Faire rendre `MoneyBag(vide)` comme `Money(0, 'USD')`.
4. Retirer la tolérance à la forme scalaire de `PaymentAggregateRequest.fromJson`.
5. Reclasser `UNKNOWN_STUDENT_CHARGE` en `failed`.
6. Remettre `MIN(sc.currency)` dans le DAO du Contrôle des frais.

**Points de revue money-grade.** Une lecture ne remonte jamais d'erreur ; parsing
tolérant ; zéro log d'argent ; un test vert en isolé peut rougir dans la suite
complète ; **un bloc né dans `setUp` ne dénoue jamais ses `Future` sous `pump()`**
→ `runAsync`.

---

## 4. Ce qui reste à demander au back

| # | Question | Bloque |
|---|---|---|
| 1 | L'imputation d'un `PaymentDelta` porte-t-elle bien son `currency` ? *(la rév. 3 le laisse entendre — à lire sur `openApi.yaml`)* | MD-8 |
| 2 | Un même `fee_code` peut-il porter deux devises selon le niveau ? | MD-3 (mise en page seulement) |
| 3 | `UNKNOWN_STUDENT_CHARGE` : terminal ou transitoire ? | MD-10 |
| ~~4~~ | ~~Le push de vente boutique acceptera-t-il un panier mixte ?~~ **RÉPONDU (rév. 4) : oui**, en un seul acte de caisse — `sale.amounts[]`, `currency` par ligne | → MD-12 |

---

## 5. Volume

| | |
|---|---|
| Fichiers `lib/` touchant `currency` | **114** (hors générés et l10n) |
| Fichiers de test touchant `currency` / `amountInCents` | **86** sur 547 (dont **38** en finance) |
| Schéma offline | v32 → **v33** (MD-4) → **v34** (MD-7) |
| Formateurs à unifier | **4** |
| Motif « première devise venue » | **7** en Dart + **1** en SQL |
| Replis `?? 'USD'` en dur | **7** |
| Lots | **12** (MD-0 → MD-11), dont **7** sans dépendance back |

---

## 6. Rappels qui ne se négocient pas

- **Une liste vide n'est pas zéro.** Nulle part.
- **Ne pas fermer l'enum `currency`** côté front (§1) — normaliser, jamais rejeter.
- **Jamais deux devises sur un même axe Y** — l'écart est de ×2 800.
- **La règle que le code ne peut pas faire respecter.** Si un caissier accepte
  des francs pour une créance en dollars, le serveur enregistre des dollars, le
  tiroir reçoit des francs, et rien ne le révélera jamais. La seule contribution
  du logiciel est de rendre l'écart malcommode : **afficher le dû par devise, et
  n'offrir aucun choix de devise à l'encaissement.** Exigence d'interface, pas
  garde serveur.
- **Le change et le module caisse sont différés** côté back, sans dette : le
  régime actuel est un sous-cas du régime avec change. Ne rien anticiper.
