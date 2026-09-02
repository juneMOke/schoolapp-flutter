/// Tables de la caisse boutique (ADR-020).
///
/// Deux familles qui ne se ressemblent pas : le **catalogue**, référentiel
/// remplacé en bloc à chaque bundle, et les **ventes**, argent poussé par
/// l'outbox et jamais réécrit.
///
/// **Étanchéité (invariant I-4).** Aucune de ces tables ne référence
/// `ref_fee_tariffs`, `student_charges` ni `payments`, et aucune n'alimente de
/// poste dû. C'est la raison d'être d'un module à part plutôt que d'un type de
/// frais de plus : le minerval repose sur une logique de dette puis imputation,
/// une vente boutique n'a aucun poste préexistant.
library;

import 'package:school_app_flutter/core/database/table_schema.dart';

/// `ref_boutique_articles` — le catalogue vendable de l'année.
///
/// Descend dans la section `boutiqueArticles` du bundle référentiel, **pas** par
/// un delta : remplacement en bloc, donc ni curseur ni `version`. Une colonne de
/// curseur qu'aucun pull ne lit serait une promesse d'ordre total que rien ne
/// tient.
///
/// `pricing_mode` est **déclaré**, jamais inféré de la forme des prix
/// (invariant I-1) : chez La Fontaine la Lacoste vaut 10 en primaire ET 10 en
/// CTEB, et qui déduirait la variation des chiffres conclurait « c'est plat »
/// — puis la vendrait au tarif primaire en humanités, où elle vaut 15.
///
/// `family` porte l'ordre d'affichage, le découpage en groupes, les filtres et
/// l'accent de couleur. Non nullable : le serveur l'exige à la création et
/// rétro-remplit l'existant, un `null` descendu signalerait un défaut de
/// projection plutôt qu'un article sans famille.
const TableSchema refBoutiqueArticlesTable = TableSchema(
  name: 'ref_boutique_articles',
  createTableSql: '''
    CREATE TABLE ref_boutique_articles (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      code TEXT NOT NULL,
      label TEXT NOT NULL,
      family TEXT NOT NULL,
      pricing_mode TEXT NOT NULL,
      unit_price_in_cents INTEGER,
      currency TEXT NOT NULL,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    // Le catalogue se lit toujours « les articles de cette école pour cette
    // année ». Scopé école : la conception « une tablette, une école » a déjà
    // produit dix flux à curseur nu, ne pas en ajouter un onzième.
    'CREATE INDEX idx_ref_boutique_articles_scope '
        'ON ref_boutique_articles(school_id, academic_year_id)',
  ],
);

/// `ref_boutique_article_level_prices` — la grille, une case par niveau.
///
/// Lignes présentes **si et seulement si** `pricing_mode = 'PRIX_PAR_NIVEAU'`.
/// Cette contrainte porte sur deux tables : aucun `CHECK` ne peut la tenir, elle
/// est tenue par le remplacement en bloc et couverte par ses tests.
const TableSchema refBoutiqueArticleLevelPricesTable = TableSchema(
  name: 'ref_boutique_article_level_prices',
  createTableSql: '''
    CREATE TABLE ref_boutique_article_level_prices (
      article_id TEXT NOT NULL,
      school_level_id TEXT NOT NULL,
      price_in_cents INTEGER NOT NULL,
      PRIMARY KEY (article_id, school_level_id)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_boutique_level_prices_article '
        'ON ref_boutique_article_level_prices(article_id)',
  ],
);

/// `boutique_sales` — une vente au comptant, pivot **payeur**.
///
/// `id` est l'uuid **client**, honoré par le serveur : c'est la clé
/// d'idempotence money-grade. Un rejeu après coupure ne compte jamais l'argent
/// deux fois. Pas de `client_uuid` séparé comme sur `payments` — il n'y a rien
/// à remapper, l'identifiant local EST l'identifiant serveur.
///
/// **Aucune colonne de reste, de solde ni de statut de paiement** : comptant
/// intégral (invariant I-5). En ajouter une laisserait croire le contraire.
///
/// Le payeur est en trois champs, comme sur `payments` et comme le serveur les
/// accepte depuis sa V99 : le nom composé qui s'imprime est **dérivé serveur**,
/// et ne remonte que par le delta.
///
/// **Les quatre colonnes sont NULLABLES (v43)**, à l'image de la V114 serveur
/// qui a retiré le `NOT NULL` de `payer_name`. Une vente au comptant remet sa
/// contrepartie sur-le-champ : aucune dette à rattacher, personne à
/// recontacter. Exiger un nom pour encaisser un cahier faisait taper « X » au
/// guichet — mieux vaut un payeur ABSENT qu'un payeur INVENTÉ.
///
/// `NULL`, **jamais `''`** : jusqu'à la v43 le pull repliait sur `''` pour
/// satisfaire le `NOT NULL`, et une vente anonyme descendue du delta se
/// relisait alors comme une vente au nom vide — assez pour imprimer un bloc
/// payeur creux sur le ticket. Le palier normalise ces `''` hérités.
const TableSchema boutiqueSalesTable = TableSchema(
  name: 'boutique_sales',
  createTableSql: '''
    CREATE TABLE boutique_sales (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      payer_first_name TEXT,
      payer_last_name TEXT,
      payer_middle_name TEXT,
      payer_phone_number TEXT,
      payer_name TEXT,
      collected_by_id TEXT,
      collected_by_name TEXT,
      sold_at TEXT NOT NULL,
      receipt_document_id TEXT,
      receipt_number TEXT,
      device_id TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      synced_at INTEGER,
      server_updated_at TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0,
      ticket_printed_at INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_boutique_sales_scope '
        'ON boutique_sales(school_id, academic_year_id)',
    // La caisse du jour se compte sur l'heure MÉTIER de la vente, jamais sur sa
    // date d'arrivée : une vente saisie hors ligne le lundi et synchronisée le
    // mercredi appartient à la caisse du lundi.
    'CREATE INDEX idx_boutique_sales_sold_at ON boutique_sales(sold_at)',
    'CREATE INDEX idx_boutique_sales_sync ON boutique_sales(sync_status)',
  ],
);

/// `boutique_sale_lines` — le panier d'une vente, figé.
///
/// `article_label` est **recopié** et non joint : le catalogue est remplacé en
/// bloc à chaque bundle, et une vente d'hier doit rester lisible après le
/// retrait de l'article qu'elle porte.
///
/// `unit_price_in_cents` est le prix **appliqué**, figé à la vente
/// (invariant I-6) : modifier la grille plus tard ne rétro-modifie aucune vente.
///
/// `catalog_price_in_cents` est ce que le serveur a répondu — nullable, et
/// **jamais zéro** : `null` dit « le catalogue ne disait plus rien » (grille
/// rééditée, devise changée, bénéficiaire réinscrit ailleurs), zéro dirait
/// « il disait gratuit ».
const TableSchema boutiqueSaleLinesTable = TableSchema(
  name: 'boutique_sale_lines',
  createTableSql: '''
    CREATE TABLE boutique_sale_lines (
      id TEXT PRIMARY KEY,
      sale_id TEXT NOT NULL,
      article_id TEXT NOT NULL,
      article_label TEXT NOT NULL,
      article_code TEXT,
      beneficiary_student_id TEXT,
      beneficiary_name TEXT,
      school_level_id TEXT,
      size TEXT,
      quantity INTEGER NOT NULL,
      unit_price_in_cents INTEGER NOT NULL,
      line_total_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      catalog_price_in_cents INTEGER,
      position INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_boutique_sale_lines_sale ON boutique_sale_lines(sale_id)',
  ],
);

/// `boutique_sale_tenders` — ce qui est **entré dans le tiroir** pour une vente.
///
/// Sœur de [boutiqueSaleLinesTable], à la même profondeur : une **liste**, pas
/// un scalaire. Un client peut poser des francs pour des cahiers tarifés en
/// dollars, et deux devises de catalogue imposent deux lignes de toute façon —
/// c'est le modèle qui découpe, pas le geste.
///
/// Append-only immuable → **PAS de `version`**, comme les lignes du panier.
///
/// ## Les deux axes, et pourquoi ils ne se confondent pas
///
/// La ligne de panier répond à « qu'est-ce qui a été vendu, et à quel prix »,
/// dans la devise du **catalogue**. Le tender répond à « qu'est-ce qui est entré
/// dans le tiroir », dans la devise **reçue**. Les deux se confondaient tant que
/// l'unité était la même ; le jour où un franc paie un dollar, la caisse
/// annoncerait des dollars sur une journée où le tiroir n'a vu que des francs.
///
/// ## `amount_in_cents` est le **net conservé**, jamais le montant présenté
///
/// 120 000 tendus, 5 000 rendus : on écrit 115 000. Même règle que
/// `payment_tenders`, et pour la même raison — sans elle, le total de caisse ne
/// retombe jamais sur le comptage du tiroir.
///
/// ## Aucun lien vers la ligne de panier, et c'est délibéré
///
/// Une liasse posée pour un panier de trois articles n'a pas été découpée
/// article par article. Stocker une correspondance enregistrerait une proration
/// comme si c'était une observation — or une proration se recalcule
/// (`ligne × taux`), elle ne se conserve pas.
const TableSchema boutiqueSaleTendersTable = TableSchema(
  name: 'boutique_sale_tenders',
  createTableSql: '''
    CREATE TABLE boutique_sale_tenders (
      id TEXT PRIMARY KEY,
      sale_id TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      rate_micros INTEGER NOT NULL DEFAULT 1000000,
      pivot_currency TEXT NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_boutique_sale_tenders_sale '
        'ON boutique_sale_tenders(sale_id)',
  ],
);

/// Tables de la caisse boutique.
const List<TableSchema> boutiqueOfflineTables = [
  refBoutiqueArticlesTable,
  refBoutiqueArticleLevelPricesTable,
  boutiqueSalesTable,
  boutiqueSaleLinesTable,
  boutiqueSaleTendersTable,
];
