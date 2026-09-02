# Le payeur devient facultatif — plan front

> Contrepartie front du commit back `c5d251b`
> (« feat(finance): make the payer optional on both sides of the counter »,
> migration `V114.0.0__optional_payer_identity.sql`).

## Ce que le serveur dit désormais

| Point de contact | Avant | Maintenant |
|---|---|---|
| `CreatePaymentRequest` (encaissement) | `payerFirstName` + `payerLastName` **exigés** par l'arête HTTP | les trois noms `nullable`, téléphone `nullable` et libre |
| `BoutiqueSaleInput` (vente) | `payerLastName` **exigé**, `payer_name` `NOT NULL` en base (V95) | triplet entier `nullable` ; `payer_name` dérivé, `null` si le triplet est vide |
| `BoutiqueSaleDelta` | `payerName` toujours présent | `payerName: null` sur une vente anonyme |
| Reçu de vente scellé (`recu-vente.html`) | bloc Payeur toujours rendu | **bloc entier escamoté** si ni nom ni téléphone ; le téléphone seul le garde |
| Reçu de perception | ne porte pas le payeur | inchangé — son sujet est l'élève |

Deux règles descendent de là et ne se négocient pas :

1. **`null`, jamais `''`.** « Pas de payeur » est un fait, pas un nom de longueur
   zéro. C'est la seule écriture qui se lise sans ambiguïté « rien à imprimer ».
   Le front écrivait `''` (colonnes `NOT NULL`) : c'est précisément ce qu'on
   retire.
2. **Un payeur ABSENT vaut mieux qu'un payeur INVENTÉ.** L'exigence se payait
   comptant au guichet — la file attend pendant qu'on demande son nom à
   quelqu'un qui achète un cahier, et le guichetier finit par taper « X ».

## Ce qui reste exigé

Le **format** du numéro, quand un numéro est entamé. Vide = accepté ; à moitié
tapé = refusé, avec l'erreur existante. Une absence est une décision, un numéro
tronqué est une faute de frappe — et c'est la clé de rapprochement de
l'annuaire, donc ce qui rendrait un payeur introuvable demain.

## Lots — ✅ tous livrés

| Lot | Portée | État |
|---|---|---|
| **PF-0** | Schéma local **v43** : `payments.payer_first_name` / `payer_last_name` et `boutique_sales.payer_last_name` perdent leur `NOT NULL` (reconstruction rename/copy/drop) ; les `''` hérités sont normalisés en `NULL`. | ✅ |
| **PF-1** | Contrat & entités : `String?` de bout en bout (wire, outbox, DAO, entités, intents, événements, usecase, repositories). | ✅ |
| **PF-2** | Encaissement : les quatre champs perdent l'étoile et gagnent une mention de facultativité ; `isValid` ne juge plus que le FORMAT du numéro saisi ; la confirmation a une phrase sans payeur. | ✅ |
| **PF-3** | Boutique : les quatre bloqueurs d'identité disparaissent (`missingLastName` / `missingMiddleName` / `missingFirstName` / `missingPhone` retirés de l'enum), `incompletePhone` reste. | ✅ |
| **PF-4** | Ticket de vente ESC/POS : bloc payeur entier escamoté quand ni nom ni téléphone — même règle que le reçu scellé. | ✅ |
| **PF-5** | Lectures : les deux annuaires refusent une identité vide ; détails et récapitulatifs disent « Sans payeur nommé » / « Payeur non renseigné » plutôt qu'un tiret. | ✅ |
| **PF-6** | l10n (FR + EN) et tests. | ✅ |

## Ce que l'écran dit maintenant

| Endroit | Vente / versement anonyme |
|---|---|
| Formulaire (les deux) | Aucune étoile, mention « ces informations sont facultatives » |
| CTA d'encaissement | **Actif.** Seul un numéro ENTAMÉ mais incomplet le rend gris |
| Confirmation encaissement | Phrase sans payeur : « Vous allez encaisser X pour Y. » |
| Confirmation vente | Ligne « Payeur : Payeur non renseigné » — dernière chance de remarquer un oubli |
| **Ticket de vente** | **Bloc payeur entier absent.** Un téléphone seul le garde |
| Reçu de perception | Inchangé — il ne porte pas le payeur, son sujet est l'élève |
| Détail / liste | « Sans payeur nommé » / « Payeur non renseigné », jamais un tiret |
| Annuaires | La vente ou le versement anonyme n'y entre pas |

## Pièges repérés

- `boutique_sale_pull_dao.dart` écrivait `sale.payerLastName ?? sale.payerName ?? ''`
  pour satisfaire le `NOT NULL`. Sans PF-0, une vente anonyme descendue du delta
  se relit en `''` et le ticket imprime un bloc payeur vide.
- SQLite ne sait pas retirer un `NOT NULL` : reconstruction rename/copy/drop,
  sur le patron déjà utilisé aux paliers v33/v34.
- L'annuaire finance se garde déjà (`_namedPayer`) ; l'annuaire boutique, non —
  une vente anonyme y remonterait comme une entrée sans nom.
- Le ticket de perception ne porte pas le payeur : **rien à faire** de ce
  côté-là, et surtout rien à ajouter.
- 🔴 Trois pièges que l'analyseur ne voyait PAS, trouvés à la relecture :
  `payment_local_model.fromMap` castait en `as String` (**crash** à la lecture
  d'un versement anonyme) ; `finance_pull_models` et `finance_ledger_read_dao`
  repliaient sur `?? ''` — c'est-à-dire réintroduisaient à la lecture la
  confusion que la V114 vient de supprimer à l'écriture.
- `payments_model.g.dart` portait le même cast dur : **relancer `build_runner`**
  après avoir touché aux modèles annotés, sans quoi le code généré garde
  l'ancienne nullabilité.
- `payerIsNew` sur le panier boutique promettait « ce payeur entre au
  répertoire » à une vente anonyme, qui n'y entre sous aucun nom.
