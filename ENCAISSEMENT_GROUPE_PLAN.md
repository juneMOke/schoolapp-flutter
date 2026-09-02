# Encaisser une nature, ventiler ses tranches — « on règle le minerval, l'écran répartit »

> **Périmètre :** la page d'encaissement (`facturation_create_payment_page.dart`
> et sa section « Frais à régler »). Suite de `GROUPEMENT_FRAIS_PLAN.md`, qui a
> replié la **lecture** ; celui-ci replie la **saisie**.
>
> ✅ **Lu dans le code**, pas deviné : `facturation_create_payment_page.dart`,
> `facturation_charge_entry.dart`, `facturation_collect_payment_utils.dart`,
> `tender_composition.dart`, `finance_ledger_read_dao.dart`.
>
> 🔴 **C'est un chantier money-grade.** Pour la première fois, un montant tapé
> par le caissier n'atterrit pas tel quel sur une créance : il est **réparti**.
> Tout ce plan tient à ce que cette répartition soit exacte au centime.

**Décisions actées.**

| | |
|---|---|
| Mode par défaut | **Groupé**, dépliable par tranche |
| Confirmation & ticket | **Les tranches, sous le nom du groupe** — on valide ce qui sera écrit |
| Répartition | **Cascade par échéance croissante**, jamais au prorata |
| Clé de groupe | **`(fee_code, devise)`** — et c'est volontairement différent de la fiche |
| Contrat de push | **Inchangé** : une imputation par créance, avec son `fee_tariff_id` |
| Groupe d'une seule tranche restante | Ligne nue, comme aujourd'hui |

---

## 1. Ce que le groupement ne change pas

C'est le plus important, et ça conditionne le risque du chantier.

- **Le contrat de push est intact.** `CreatePaymentAllocationInput` porte
  `studentChargeId` + `feeTariffId` : le serveur ne verra jamais « un paiement de
  groupe ». Le groupement est une **affordance de saisie** qui produit exactement
  la requête d'aujourd'hui.
- **Les tenders non plus.** `TenderComposition.identityFor` agrège les
  imputations **par devise**, pas par ligne : grouper ne touche pas à
  l'invariant perçu/imputé.
- **Le grand-livre non plus.** Une créance reste l'unité d'argent ; c'est elle
  qu'on solde, qu'on imprime et qu'on rejoue.

Ce qui change tient en une phrase : **une saisie → N imputations**.

## 2. La cascade, et pourquoi surtout pas un prorata

Le caissier tape 120 000 sur un minerval à trois tranches restantes
(50 000 · 50 000 · 50 000) :

```
T1 ← 50 000   (soldée)
T2 ← 50 000   (soldée)
T3 ← 20 000   (partielle)
```

**La cascade remplit chaque tranche à son restant exact, sans jamais diviser.**
Elle est donc exacte au centime *par construction* : aucun arrondi n'intervient,
donc aucun centime ne se perd ni ne s'invente.

Un prorata (chacun sa part du montant) exigerait un arrondi, et il faudrait
désigner qui garde le reste — aucune règle n'est non-arbitraire, et sur de
l'argent une règle arbitraire finit par être contestée au guichet.

**L'ordre est celui du DAO** — `due_at` croissant, puis code de tarif
(`finance_ledger_read_dao.dart:71`). C'est celui que la fiche affiche, et celui
dans lequel une école apure un arriéré : on solde la tranche la plus ancienne
d'abord.

### L'invariant à tenir, et la contre-épreuve

```
somme(imputations produites) == min(montant tapé, restant du groupe)
∀i : imputation[i] ≤ restant[i]
```

C'est ce qu'un test exhaustif doit établir — **pour tout montant** (0, 1 centime,
pile une tranche, entre deux tranches, exactement le total, au-delà), et non sur
trois exemples heureux. La contre-épreuve n'est pas « la ventilation est
lisible » : c'est « la somme retombe sur le centime ».

## 3. Le modèle de saisie

Un groupe porte **un** montant. Les tranches en découlent.

Quand le caissier déplie et tape sur une tranche, la source s'inverse : les
tranches portent la vérité, le montant du groupe devient leur somme. C'est
exactement l'idiome que `FacturationChargeEntry` tient déjà entre l'imputé et le
comptoir — *« on ne recalcule jamais celui qui a le curseur »* — appliqué d'un
cran au-dessus. Un drapeau `groupIsSource`, et rien d'autre.

L'échappatoire par tranche n'est pas un confort : un parent règle parfois **la
dernière** tranche (sécuriser un examen), et une saisie qui ne saurait pas
l'exprimer forcerait le caissier à mentir sur la répartition.

## 4. Cinq pièges, et pourquoi ils mordent

1. **Le `fee_tariff_id` de chaque tranche est ce qui rend la ventilation légale.**
   Depuis V94, le serveur refuse d'imputer au hasard quand un niveau porte
   plusieurs lignes d'une même nature — `AMBIGUOUS_FEE_CODE`, et il est
   **terminal** (aucune attente ne le corrige, cf. `payment_outbox_handler`). La
   cascade porte le bon par construction, puisqu'elle produit une imputation par
   créance ; c'est la propriété à ne jamais casser en « simplifiant ».

2. **La clé de groupe n'est PAS celle de la fiche.** Là-bas :
   `fee_code` seul, et le multi-devise se rend par deux jauges. Ici :
   `(fee_code, devise)`, parce qu'un montant tapé a exactement une devise. Deux
   clés pour le même mot « groupe », délibérément — celui qui les
   « harmoniserait » casserait la saisie.

3. **Le compte de tranches diffère de la fiche.** `_entries` filtre déjà
   `remaining > 0` : un minerval en sept tranches dont quatre sont soldées
   affiche ici **trois tranches restantes** quand la fiche dit sept. Deux comptes
   justes ; il faut les libeller différemment pour qu'ils ne se contredisent pas.

4. **`_lines()` et le sac de règlement itèrent `_entries`.** Ils doivent itérer
   les **tranches ventilées**, jamais les groupes : sinon le total encaissé, les
   tenders et le contrôle de divergence portent sur des lignes qui n'existent pas
   côté serveur.

5. **Une imputation à zéro ne part pas.** La cascade laisse à 0 les tranches
   non atteintes ; la règle actuelle (`effectiveCents > 0`) doit continuer de les
   écarter, sans quoi un versement porterait des imputations vides.

## 5. Les lots

| Lot | Ce qu'il fait | État |
|---|---|---|
| **GE-0** | `cascadeAllocation` — fonction pure, plus sa batterie d'invariants | ✅ |
| **GE-1** | `FacturationChargeGroupEntry` : clé `(fee_code, devise)`, sous-entrées, `groupIsSource` | ✅ |
| **GE-2** | La section « Frais à régler » rend des groupes ; un groupe d'une tranche reste une ligne nue | ✅ |
| **GE-3** | Le pont vers la requête : la ventilation produit les imputations, `_lines()` suit les tranches | ✅ |
| **GE-4** | Devise de règlement et taux au niveau du groupe (une conversion, pas N) | ✅ |
| **GE-5** | Confirmation : tranches groupées sous leur nature ; ticket aligné | ✅ |
| **GE-6** | l10n FR + EN — livrée **au fil des lots**, pas en lot séparé | ✅ |
| **GE-7** | Contre-épreuve bout-en-bout de la requête produite | ✅ |

### Ce que la mise en œuvre a appris

- **Le groupe pilote les entrées de tranche, il ne les remplace pas.** La page
  garde sa liste plate : c'est elle qui porte les contrôleurs, qui est disposée,
  et qui produit les imputations. La requête sortante est donc *identique* à
  celle d'une saisie tranche par tranche — c'est ce qui a rendu GE-3 presque
  gratuit, et ce qui rend le chantier tenable sur de l'argent.
- **La sélection du groupe est dérivée, jamais stockée.** Un drapeau propre au
  groupe aurait été une seconde vérité à tenir d'accord avec celle des tranches ;
  elles divergent au premier décochage manuel.
- **Une re-ventilation vers le bas doit RETIRER ce qui avait été posé.** Sans
  remise à zéro des tranches non atteintes, corriger 1500 en 300 laisse deux
  imputations fantômes de 500 dans le versement.
- 🔴 **Deux devises concurrentes pour un même versement.** La nature porte une
  devise de règlement, la tranche garde la sienne : déplier et changer celle
  d'une tranche affichait deux sélecteurs qui se contredisaient. Règle posée —
  *dès que les tranches commandent, la nature cesse d'être l'unité de règlement*
  et ses contrôles disparaissent. Le mélange reste atteignable en dépliant.
- 🔴 **La contre-épreuve a trouvé un défaut — dans elle-même.** Ses deux
  premiers cas ciblaient `find.byType(TextField).first`, qui attrape le premier
  champ de la PAGE : celui du payeur. Le montant tapé n'atteignait jamais la
  nature, l'écran gardait la valeur posée par la case à cocher, et le test lisait
  un chiffre juste pour une raison fausse. Écrite avec des attentes moins
  précises, elle serait passée du premier coup sans rien prouver. Le champ se
  cible désormais par son intitulé.
- ⚠️ **Une fixture qui dit « deux frais » doit donner deux natures.** Un test du
  règlement multi-devise donnait le même `fee_code` à ses deux créances : sans
  conséquence sur un écran plat, il décrivait un minerval en deux tranches dès
  que l'écran a replié. C'est le test qui a trouvé le défaut ci-dessus.

## 6. Ce que la contre-épreuve établit

Sur la requête réellement dispatchée, pas sur des intermédiaires :

1. **Les deux chemins de saisie produisent la même requête.** Groupé (une nature,
   un montant) et tranche par tranche (déplié, trois montants) passent par la
   même assertion. Si les deux divergeaient, le groupement cesserait d'être une
   affordance de saisie pour devenir **une seconde façon d'écrire de l'argent**.
2. **Aucune imputation vide ne part.** Un règlement partiel n'envoie que les
   tranches réellement atteintes — un versement porteur d'imputations vides
   serait refusé, et le refus arriverait *après* que l'argent soit dans le
   tiroir.
3. **Chaque imputation porte son `fee_tariff_id`.**

## 7. Hors périmètre

- **L'étape « Frais » du wizard d'inscription** : elle crée des créances, elle
  n'en solde pas. Rien à replier.
- **Le prorata configurable** : aucune école ne l'a demandé, et l'introduire
  ferait porter à ce code un arrondi qu'il n'a pas aujourd'hui.
- **La ventilation entre NATURES** (« il donne 100 000, répartis comme tu veux ») :
  c'est un autre geste, qui suppose une politique d'imputation d'établissement.
  Ici, le caissier désigne toujours la nature.
