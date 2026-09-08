# Ticket de perception — nouveau format, réimpression libre et logo d'école

> ## Statut au 2026-09-08 : **en cours d'exécution**
>
> Contrairement au plan multi-école, écrit *avant* l'exécution, celui-ci est
> écrit **pendant**. Il ne prédit pas, il consigne — et il dit à chaque section
> ce qui est **décidé**, ce qui est **écrit**, et ce qui **reste**.
>
> | | état |
> |---|---|
> | Format du ticket, réimpression, bandeau conditionnel | **décidé**, non écrit |
> | Schéma v47 (`school_logo_cache` + empreintes) | **écrit** |
> | Raster `GS v 0` et bande hors pivot | **décidé**, non écrit |
> | Tirage conditionnel des octets | **bloqué** — attend le contrat réel du back |
>
> Aucun push. Les arbitrages produit viennent du porteur ; ce document porte le
> raisonnement technique, pas la décision.

---

## 1. Pourquoi ce document existe

La spécification a vécu une nuit entière dans des échanges entre sessions. C'est
exactement ce qu'on vient de reprocher au plan multi-école : un document qui
n'est pas dans le dépôt pourrit en silence — celui-là annonçait un numéro de
schéma déjà pris, quatre jours après avoir été écrit, sans que rien ne le
signale.

Ce qui suit n'existe nulle part ailleurs : ni dans le code, qui n'est pas encore
écrit, ni dans les commits, qui viendront après.

---

## 2. Le format du ticket

### En-tête — six lignes, plus la bande

Dans l'ordre : **logo**, nom de l'école, adresse, ville, email, téléphone, filet.

Deux élargissements de requête sont nécessaires, et c'est le point qu'une lecture
rapide manque : **ce n'est pas seulement le modèle qu'il faut étendre**.

- `findSchool()` (`provisional_ticket_dao.dart:245`) ne lit que
  `name, municipality, city`. **Adresse, email et téléphone ne sont pas lus.**
- `ref_school` porte pourtant les huit colonnes depuis toujours : **aucun
  contrat serveur ne bouge.**

### ⚠️ Le getter `locality` est à défaire, pas à étendre

`TicketSchoolRow.locality` (`provisional_ticket_dao.dart:399-405`) écrase
délibérément commune **et** ville en une seule ligne — « commune si connue, ville
à défaut ». La spec demande adresse et ville comme **deux lignes distinctes** :
l'abstraction cesse d'être juste.

Un seul appelant à reprendre (`provisional_ticket_repository_impl.dart:104`).

**⚠️ Homonyme à ne pas toucher** : `School.locality`
(`features/school/domain/entities/school.dart:31-38`) est une **autre classe**,
lue par la bannière d'accueil (`accueil_brand_banner.dart:66-69`). Un
`grep locality` naïf casserait l'accueil.

*Observation, hors périmètre :* les deux getters ont des priorités **opposées** —
le ticket prend la commune d'abord, l'accueil la ville d'abord. La même tablette
peut donc imprimer « Ngaliema » et afficher « Kinshasa ». Séparer adresse et
ville fait disparaître le problème côté ticket ; il restera côté accueil.

### Corps

`Date: ` prend le créneau de gauche avec la date, **l'heure reste à droite sur la
même ligne** :

```
Date: 08/09/2026                           01:35
```

**Aucune ligne de papier ajoutée** : `addPair` calcule `48 − 16 − 5 = 27`
colonnes de reste, et **11 même à 32 colonnes**. Le format des valeurs ne change
pas — `JJ/MM/AAAA` et `HH:MM`, purs et sans locale, pour que le ticket se rende
en test unitaire comme en isolat d'impression.

⚠️ Il n'y avait **aucun libellé** auparavant : la date occupait le créneau du
libellé et l'heure celui de la valeur. C'est un ajout de libellé, pas un
changement de format.

Puis : caissier, élève, classe, **payeur**, section des montants **inchangée**.

### Le payeur — la règle boutique, recopiée mot pour mot

`findPayment()` (`provisional_ticket_dao.dart:79-87`) ne sélectionne **aucune**
colonne `payer_*`. Elles existent au schéma et **descendent** par le pull
(`finance_pull_models.dart:120-127` : elles hydratent une ligne inconnue, donc un
versement d'un autre poste). C'est un élargissement de requête, et il marche
partout une fois branché.

La règle vient de `sale_ticket_text_layout.dart:77-107`, et son raisonnement est
la raison de la recopier plutôt que de la réinventer :

> « **Le bloc ENTIER disparaît sur une vente anonyme** — ni cadre vide, ni tiret.
> Sur une pièce, une mention laissée vide se lit comme une mention EFFACÉE, et
> invite à chercher ce qu'on aurait retiré. […] Un téléphone seul GARDE le bloc :
> il a été tapé, donc il désigne quelqu'un. »

⚠️ Côté données : `payerFullName` doit être **`null`, jamais `''`** — c'est ce que
le gabarit lit pour escamoter le bloc.

### Le repli est gratuit, et il ne demande aucune garde

`wrapped('')` rend `const <String>[]` (`ticket_text_primitives.dart:94-95`), donc
`_centered('')` **n'ajoute aucune ligne**. Un champ vide disparaît sans ligne
blanche ni tiret. **Rien ne tronque jamais** : `wrapped` coupe sur les espaces et
découpe un mot trop long en tranches, `addPair` reporte la valeur seule sur la
ligne suivante — « un montant tronqué serait pire qu'un montant reporté ».

Conséquence : aucune perte d'information, mais **chaque débordement coûte une
ligne de papier**. L'adresse est le champ à risque.

---

## 3. Réimpression libre — le modèle Boutique

**Décidé :** le bouton est **toujours** offert, libellé « Imprimer » →
« Réimprimer », et `ticket_printed_at` reste **honnête**, réécrit à chaque tirage
réussi, affiché comme mention de dernière impression.

Le patron existe et tourne en production : `boutique_sale_detail_page.dart:415-436`
et `sale_detail_cubit.dart:59-63`. Sa raison est écrite dans le DAO
(`boutique_sale_history_dao.dart:119-124`) :

> « **N'interdit jamais de réimprimer** : un papier se déchire, une imprimante se
> bloque à mi-course, et un client repart parfois sans son ticket. La mention
> informe, elle ne garde pas la porte. »

### Ce que le drapeau ne fait pas

`payments.ticket_printed_at` est un **horodatage nullable**, pas un booléen, et
**strictement local** — `app_constants.dart:443-444` : « jamais poussée ni
descendue ». Une réimpression ne génère **aucun trafic**, ne touche ni
`sync_status` ni `updated_at`, ne passe pas par l'outbox.

### ⚠️ La condition `deviceId` ne tombe pas toute seule

`awaitsTicketPrint` (`provisional_ticket_repository_impl.dart:55-73`) porte
**quatre** conditions ; le drapeau n'est que la dernière. La troisième —
`deviceId != cette tablette` — masquerait le bouton sur tout versement encaissé
ailleurs, **même drapeau forcé**. Elle ne tombe qu'une fois les deux
branchements du §5 posés.

La cinquième condition, elle, ne bouge pas : **un reçu annulé ne ressort jamais
en ticket** (`facturation_payment_detail_dialog.dart:168`).

---

## 4. Le bandeau conditionnel

**Décidé :** le bandeau pleine largeur disparaît **dès que le ticket porte un
numéro définitif**. Seul le cas non scellé garde une mention, **discrète, sur la
ligne de référence**. Le champ `TicketLabels.provisionalBanner` devient
`provisionalMention`.

### ⚠️⚠️ La règle de non-négation — le point le plus précieux de ce document

> **`isProvisional = receiptId == null`, lu affirmativement. Jamais
> `!hasDefinitiveNumber`, jamais la présence d'une ligne `generated_documents`
> locale, jamais l'état réseau.**

**Pourquoi.** Un versement scellé encaissé sur une **autre caisse** n'a pas de
ligne `generated_documents` locale — le contrat le dit lui-même
(`finance_pull_models.dart:130-134` : « celui-ci n'a jamais eu de ligne
`generated_documents` locale »). Une négation le déclarerait provisoire, et le
bandeau s'imprimerait **exactement sur les tickets que le porteur veut
officiels** — l'inverse de la décision.

**Le dépôt a déjà payé ce bug**, dans l'écran voisin, et le remède y est écrit
(`payment_receipt_cubit.dart:76-82`) :

> « Affirmation positive, et c'est essentiel : `!isDefinitive` serait vrai aussi
> quand **aucune ligne locale n'existe** — cas NORMAL d'un paiement encaissé sur
> un AUTRE poste et descendu par pull. »

La forme juste est celle de la boutique (`sale_ticket_composer.dart:46-49`) :
« `isProvisional` se lit sur **l'absence de NUMÉRO**, pas sur l'état réseau ».

**Référence :** `receiptNumber ?? provisionalNumber ?? paymentId`.
**Renommage :** `TicketReceiptModel.provisionalReference` → `reference`, parce
qu'il portera tantôt l'un tantôt l'autre. La colonne `provisional_number`, elle,
**garde son nom** : elle désigne bien le numéro provisoire, et elle **survit au
scellement** là où `number` est écrasée.

### La mention — `Réf. provisoire <numéro>`, et pourquoi pas l'autre forme

La forme à parenthèse en fin de ligne a été **écartée par simulation**, pas par
goût. Sur le vrai algorithme de repli, à 48 colonnes, dans le cas où la référence
retombe sur l'UUID du paiement (36 caractères — cas réel, puisque `isProvisional`
est alors vrai) :

```
A  « Réf. <uuid> (n° provisoire) »        B  « Réf. provisoire <uuid> »
   |Réf. 550e8400-…-446655440000 (n°|        |Réf. provisoire|
   |provisoire)|                             |550e8400-…-446655440000|
```

**A coupe la parenthèse en deux.** Un papier remis à un parent avec « (n° » qui
pend et « provisoire) » orphelin a l'air d'un bug d'impression.

Et B est **sémantiquement plus juste** : le mot qualifie le **numéro**, pas le
versement. L'argent est reçu — c'est un fait que le ticket affirme ; c'est le
numéro qui n'est pas encore scellé. B tient à 48 comme à 32 colonnes (32
caractères pile).

---

## 5. La convergence — deux colonnes, trois dettes

Deux colonnes **déjà descendues et jamais lues** ferment trois chantiers :

| branchement | ce qu'il ouvre |
|---|---|
| `payments.receipt_id` → `findPayment()` | ① la Réf. définitive hors poste ② le **signal du bandeau conditionnel** ③ la 2ᵉ condition de complétude |
| `payments.collected_by_name` → repli de `cashier_*` | ① le caissier RG-012-11 hors poste ② la 3ᵉ condition de complétude |

Le caissier est **le seul champ vraiment absent** hors du poste d'encaissement :
le patch de pull ne touche pas aux `cashier_*`, et le dit
(`payment_local_model.dart:154-155` : « ce que ce poste a imprimé sur le ticket ne
se réécrit pas depuis le réseau »). Mais `collected_by_name` descend, lui.

Une fois les deux posés, un ticket est **composable ailleurs**, et la condition
`deviceId` peut tomber sans rien perdre.

*Note :* le commentaire de `provisional_ticket_repository.dart:47-49` affirme que
les **libellés de répartition** dégradent aussi hors poste. **C'est périmé** — le
contrat porte `studentChargeLabel` (`finance_pull_models.dart:249`) et le chemin
d'insertion d'une allocation inconnue passe par `toMap()`, qui l'inclut. À
corriger en même temps.

---

## 6. Le logo

### La bande vit **hors** du pivot `List<String>`

C'est la décision qui sauve le critère d'acceptation de l'ADR — « ticket ESC/POS
**et** PDF depuis le même gabarit, comparaison du contenu textuel ». Une image ne
passe pas par une liste de chaînes.

**Le dépôt a déjà tranché ce principe pour un autre élément**
(`pdf_ticket_renderer.dart:82-86`) :

> « [cutNotice] n'apparaît que sur une feuille […] il appartient au **support**,
> jamais au ticket — l'ajouter au gabarit casserait le critère "même contenu
> textuel entre les deux sorties". »

Le trait de découpe, le cadre, la mention de découpe : tous posés **par le
renderer**. La bande entre dans cette catégorie déjà défendue.

**La propriété qui rend tout le lot sûr :** `TicketTextLayout.render()` rend la
même liste avec ou sans logo, donc les tests d'égalité entre sorties survivent
**sans qu'une ligne soit touchée**.

*Et c'est une raison de plus de l'y garder :* le contenu du ticket va encore
évoluer. La bande hors pivot permet de retoucher le gabarit sans jamais reposer
la question du logo, et réciproquement.

### Le format, décidé

- `thermal` — PNG **1 bit**, **576×128**, centré dans ses octets. 128 points =
  **16 mm de rouleau par ticket**. ~1,5 ko.
- `display` — PNG **256×256** palette, **alpha conservé** (pose sur n'importe
  quel fond sans halo). ~12,5 ko.
- Une troisième variante `print` existe **côté serveur** (aplatie sur blanc, sans
  alpha) et **n'a rien à faire sur une tablette** — d'où le `CHECK` en base.

Le logo est **carré** : une bande à la largeur maximale de 576 aurait fait 576 de
haut, soit **72 mm par ticket**. Les 576 points sont un plafond de largeur, pas
une cible.

### Le raster `GS v 0` — trois pièges

`GS v 0 m xL xH yL yH [octets]`, largeur **en octets** (dots/8), MSB à gauche.
Recevant du 1 bit déjà tramé à la bonne largeur, le renderer n'a que quatre
gestes : valider `largeur % 8 == 0` et `≤ 576`, écrire l'en-tête de 8 octets,
verser les données, envoyer un `LF`. **20 à 30 lignes, sans algorithme.**

1. **Le centrage matériel est interdit par contrat de classe**
   (`esc_pos_ticket_renderer.dart:46-49`, et le flux force `ESC a 0`). Le serveur
   envoie donc la bande **déjà centrée dans ses octets** — vérifié sur le vrai
   fichier : colonnes encrées 224→351, marges 224/224.
2. **Point d'insertion : `render()`, jamais `renderLines()`.** Ce dernier est
   exposé pour la **sonde de page de code** : y injecter la bande ferait imprimer
   un logo à chaque sonde matérielle.
3. **Ordre** : après `ESC @` / `ESC t` / `ESC a 0`, avant la première ligne.
   Avant `ESC @`, la réinitialisation l'efface.

Côté PDF : premier enfant de la `pw.Column` du rouleau et de la liste `build:` en
chemin feuille — **jamais un `header:`**, qui la répéterait sur chaque page. Le
cadre de découpe est calculé autour du bloc : la bande vit dedans, elle ne le
déplace pas.

### ⚠️ L'inversion de polarité

Mesuré sur le fichier réel : **92,3 % des bits valent 1**. En PNG gris 1 bit,
**1 = blanc**. Mais `GS v 0` lit l'inverse — **un bit à 1 est un point
imprimé**.

Versés tels quels, ces octets sortent un **rectangle noir de 576×128 avec le
sceau en réserve blanche**, 92 % de la bande chauffée à chaque ticket.

**Contrat retenu :** le transport reste un **PNG à convention PNG**, affichable
et vérifiable à l'œil par n'importe qui ; **le renderer inverse à l'empaquetage**
(`~b & 0xFF`). La seule brique qui connaît ESC/POS porte la seule ligne qui
connaît sa polarité.

**Le test qui garde cette décision ne compare pas des octets** — il compare la
**proportion de points imprimés** attendue (~8 %) à celle que produit
l'empaquetage. C'est la leçon de `58360f63`, où six tests mesuraient `.width` sur
une barre de hauteur nulle : « une mesure qui ne peut pas distinguer ce qu'elle
cherche d'autre chose n'est pas une preuve ».

---

## 7. Le stockage — v47

**Écrit.** `school_logo_cache(school_id, variant, sha256, bytes, fetched_at)`,
clé primaire composite `(school_id, variant)`, `CHECK (variant IN ('thermal',
'display'))`, voisine de `ref_school` dans `enrollment_finance_offline_schema.dart`
et marquée **tenant** en commentaire — le découpage `deviceOfflineTables` /
`tenantOfflineTables` est du **lot 1 multi-école** et n'existe pas encore.

Empreintes : `ref_school.logo_thermal_sha256` / `logo_display_sha256`, du texte,
sur une table réécrite à chaque pull. Les octets vivent à côté, dans une table que
le pull ne touche pas — sans quoi chaque cycle les redemanderait.

### Le précédent `pdf_blob`, cité puis écarté

Le palier v21 a refusé les octets en base : « les octets ne rejoignent PAS la base
[…] **avant d'introduire le moindre risque de volumétrie** ». Le motif nommé est
la **volumétrie** — des centaines de pièces de plusieurs Mo, avec éviction LRU et
budget. Un logo, c'est **~14 ko par école**, deux lignes, mesurés. Aucune
éviction, aucun budget, aucune croissance.

Réutiliser `EditiqueBlobStore` aurait au contraire **coûté le logo** : son
`reclaimOrphans()`, appelé au démarrage depuis `main.dart`, supprime tout fichier
dont l'id n'est pas dans l'index `editique_cache_entries` — index dont le
`doc_type` est contraint à `{AI, NP, RC, BU}`.

### Trois règles d'écriture non négociables

- **Jamais d'upsert `replace` avec une map partielle** — c'est ce qui a vidé
  `pdf_blob` : une écriture qui omet `bytes` remet la colonne à NULL sans rien
  signaler.
- **`sha256` et `bytes` dans la même transaction.**
- **Jamais de `SELECT *`** — l'invalidation lit `sha256` seul.

### ⚠️ La règle de l'`If-None-Match`

> **L'en-tête conditionnel se construit exclusivement sur l'empreinte que porte
> `school_logo_cache`. Jamais sur celle du lot référentiel.**

Il y a **deux** empreintes, et elles ne disent pas la même chose : celle de
`ref_school` est la **cible** (« voici le logo que l'école a »), celle de la table
logo est l'**état** (« voici celui que je détiens »).

Envoyer la cible produit un `304` **définitif** après un tirage raté : le serveur
répond « rien de neuf » sur une empreinte qu'on ne détient pas, et les octets
n'arrivent jamais. État stable, silencieux, sans erreur. Ligne absente ⇒ **aucun
en-tête conditionnel**, donc `200` + octets.

### Le numéro

**v47 est au logo. Le lot 2 multi-école prend v48.** Le numéro a été **pris en
fusionnant**, pas réservé — `app_constants.dart` documente le **v24 brûlé**,
« Ne jamais le réattribuer », après que deux branches l'ont revendiqué.

---

## 8. Le papier — accepté en connaissance de cause

### ⚠️ L'interligne n'est pas la hauteur du caractère

**24 points est la hauteur du CARACTÈRE.** L'avance ESC/POS par défaut est de
1/6 de pouce = 30 points. Le renderer n'envoie **aucune** commande d'interligne,
donc c'est ce défaut qui s'applique — et le dépôt l'a **mesuré au papier** :
`esc_pos_ticket_renderer.dart:70-71`, « 6 lignes (~25 mm […] où une ligne vaut
~4,2 mm) ». Soit **4,17 mm**, pas 3.

Cette erreur a été commise une fois sur ce chantier, avec 40 % d'écart. Elle se
refera.

### Le coût, interligne mesuré, en-tête actuel 12,5 mm, bande 16 mm

| cas | en-tête | **delta/ticket** | 30 tickets/jour |
|---|---|---|---|
| plancher, rien ne se replie | 41,0 mm | **+32,7 mm** | 98 cm |
| réaliste, adresse sur 2 lignes | 45,2 mm | **+36,8 mm** | 110 cm |
| pire, adresse 2 l. + payeur 2 l. | 49,3 mm | **+45,2 mm** | 136 cm |

Le bandeau retiré ne rend que **4,2 mm** — **environ un dixième** de ce que
l'en-tête prend. Et le filet qui le suivait **reste** : le retirer ferait couler
le titre directement dans le nom de l'élève, supprimant la coupure entre « ce
qu'est ce document » et « de qui il parle ».

Le porteur a vu ces trois cas et les assume.

---

## 9. Les tests

**Dix-sept cas**, dont les replis — c'est là que le gabarit décide vraiment.

**En-tête (1-5)** : les six lignes dans l'ordre ; chaque champ absent n'ajoute
aucune ligne ; une école réduite au nom seul ; une adresse > 48 caractères se
replie sans perte ; `ref_school` absente ⇒ le ticket sort quand même ; 32
colonnes sans débordement.

**Bandeau (6-8)** :
- `receiptId != null` ⇒ **aucune** ligne ne porte le bandeau ;
- `receiptId == null` ⇒ mention sur la ligne de référence, et **assertion négative
  explicite** qu'aucun bandeau pleine largeur n'existe ;
- ⚠️ **n°8, celui qui garde la décision du porteur** : un versement **scellé sans
  ligne `generated_documents` locale** — le cas « encaissé sur une autre caisse »
  — **ne porte aucune mention provisoire**. Sans lui, la régression est
  **invisible sur un poste de développement**, où la ligne locale existe toujours.

**Payeur (9-12)** : bloc complet ; **bloc entier absent** sans filet orphelin ;
**téléphone seul ⇒ le bloc reste** ; nom composé long replié sans troncature.

**Caissier (13-15)** : `cashier_*` sur le poste ; **repli `collected_by_name`**
hors poste ; les deux absents ⇒ la ligne disparaît.

### ⚠️ Ce qu'il ne faut PAS toucher (16-17)

- **Les tests d'égalité entre sorties** (`esc_pos_ticket_renderer_test.dart:93-101`,
  `pdf_ticket_renderer_test.dart:295`) comparent à `TicketTextLayout.render()`
  **lui-même**, pas à un texte littéral. Ils absorbent l'en-tête, le payeur et le
  bandeau conditionnel **sans modification**. Les « mettre à jour » les
  détruirait : leur valeur tient à ce qu'ils ne nomment aucun contenu.
- **La section des montants** doit rester verte **sans modification** — c'est ce
  qui prouvera que l'élargissement de l'en-tête n'a pas déplacé la colonne.

### Un test à ré-ancrer, surtout pas à supprimer

`ticket_text_layout_test.dart:303-306` se sert du bandeau comme **repère** pour
tester tout autre chose : que deux filets se retrouvent collés quand la zone élève
est vide. Sans bandeau, `indexWhere` rend `-1`, le test lit `lines[0]`/`lines[1]`
et **passera peut-être, en mesurant autre chose**. Un vert qui a changé de sujet.
**Ré-ancrer sur le titre.**

---

## 10. Ce qui reste ouvert

1. **Le tirage des octets attend le contrat réel du back** — chemins,
   `Content-Type`, sémantique exacte de l'`ETag` et du `304`, codes d'erreur.

   ⚠️ **Le DTO de pull n'est délibérément PAS écrit.** Une première version
   supposait deux champs plats `logoThermalSha256` / `logoDisplaySha256` **dans**
   `RefSchoolDto` : c'était faux sur deux points. Le back construit un objet
   **imbriqué** `{ displaySha256, thermalSha256 }`, **frère** de `school` à la
   racine du lot — pressenti `logoRefs`, à confirmer — et `null` quand l'école
   n'a pas de logo.

   La forme du back est la bonne, et pour une raison qui vaut d'être retenue :
   `SchoolDto` est **aussi le corps du `PUT`**, tous champs obligatoires. Y loger
   des valeurs dérivées et nullables ouvrirait un chemin pour **déposer une
   empreinte forgée** que le mapping recopierait par nom. Un champ frère est en
   lecture pure par construction.

   **Les deux colonnes plates côté base restent bonnes** : on lit un objet à la
   racine, on écrit deux colonnes. La platitude est un choix interne, pas un
   décalque du fil.

   Une divergence de nom de clé ne se verrait qu'à l'exécution — d'où l'attente.
2. **La hauteur de 128 points est une valeur de départ**, à confirmer au tirage
   réel sur le banc `/dev/ticket-print`. L'avance de déchirure a été calée au
   papier et non au calcul ; il n'y a pas de raison que la bande y échappe.
3. **Le séquencement de release** entre ce lot et le lot 2 multi-école, qui
   renumérote en v48.

---

## 11. Journal des décisions

| date | décision |
|---|---|
| 2026-09-08 | Réimpression **libre** (modèle Boutique), sans mention « DUPLICATA » — le rang aurait été un palier de schéma |
| 2026-09-08 | En-tête complet + logo ; bandeau **conditionnel** au numéro définitif ; titre **inchangé** (« note de perception » désigne déjà une pièce scellée) |
| 2026-09-08 | `isProvisional` **lu affirmativement** sur `receiptId == null` |
| 2026-09-08 | Mention `Réf. provisoire <n°>`, l'autre forme écartée **par simulation de repli** |
| 2026-09-08 | Logo : bande **hors pivot**, PNG à convention PNG, **inversion dans le renderer** |
| 2026-09-08 | Stockage **v47** en base (précédent `pdf_blob` écarté, motif volumétrie) ; multi-école en **v48** |
| 2026-09-08 | Papier : **+32,7 à +45,2 mm/ticket** accepté par le porteur |
