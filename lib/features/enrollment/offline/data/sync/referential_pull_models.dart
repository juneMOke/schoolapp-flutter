import 'package:school_app_flutter/features/enrollment/offline/data/sync/pull_json_support.dart';

// Pull du socle référentiel — `GET /api/v1/sync/referential`
// (miroir `openApi.yaml`, amendé par `PLAN_referential_current_previous_FRONT.md`).
// Bundle always-200, gelé sur la saison (D2). Lecture seule → `fromJson`.

/// Bundle racine : identité de l'école + deux slots année (`current`/`previous`).
/// Bundle full **always-200** (jamais 304), gelé sur la saison. `previous` est
/// `null` quand l'école n'a pas d'année antérieure (première année) — jamais un
/// slot vide.
class ReferentialBundleDto {
  final RefSchoolDto school;
  final ReferentialYearBundleDto current;
  final ReferentialYearBundleDto? previous;

  /// Barème de réductions (ADR-021) — **à la racine, pas dans un slot année**.
  /// `reduction_type`/`reduction_line` n'ont pas d'`academic_year_id` : les
  /// loger dans `current`/`previous` les dupliquerait à l'identique. Ils vont
  /// à côté de [school], qui est là pour la même raison.
  ///
  /// **Une seule section, et les lignes du barème dedans.** Le serveur imbrique
  /// (`reductions[].lines[]`) plutôt que de servir une seconde liste à plat :
  /// personne n'a besoin d'une ligne sans son type, et deux listes à joindre
  /// côté client sont deux occasions de les désynchroniser.
  ///
  /// **Nullable, et la nuance porte de l'argent**, comme [ReferentialYearBundleDto.feeTariffs] :
  /// le serveur retire la section pour qui n'a pas `finance.grid.read` et
  /// l'envoie à `null` plutôt qu'à `[]`. `null` = non communiqué,
  /// `[]` = cette école n'a pas de barème. Replier l'un sur l'autre ferait
  /// lire à la purge un ordre de tout supprimer — et ici elle est scopée par
  /// ÉCOLE, donc sur une tablette partagée un pull sans ce droit effacerait le
  /// barème dont dépend le guichet d'un autre poste.
  final List<RefReductionDto>? reductions;
  final String serverTime; // ISO-8601

  const ReferentialBundleDto({
    required this.school,
    required this.current,
    this.previous,
    this.reductions,
    required this.serverTime,
  });

  factory ReferentialBundleDto.fromJson(Map<String, dynamic> j) =>
      ReferentialBundleDto(
        school: RefSchoolDto.fromJson(j['school'] as Map<String, dynamic>),
        current: ReferentialYearBundleDto.fromJson(
          j['current'] as Map<String, dynamic>,
        ),
        previous: j['previous'] == null
            ? null
            : ReferentialYearBundleDto.fromJson(
                j['previous'] as Map<String, dynamic>,
              ),
        // Volontairement hors de `pullList`, qui replie `null` sur la liste
        // vide : c'est exactement la distinction à préserver ici.
        reductions: j['reductions'] == null
            ? null
            : pullList(j['reductions'], RefReductionDto.fromJson),
        serverTime: j['serverTime'] as String,
      );
}

/// Une nature de réduction du barème de l'école, **et son barème avec elle**
/// (`ReductionSummaryDto` côté serveur).
///
/// Pas d'`id` sur le fil : l'identité d'un type est son [code] dans son école,
/// et le serveur a posé sa contrainte sur ce couple. Rien à fabriquer ici.
class RefReductionDto {
  final String code;
  final String label;
  final bool active;

  /// Les rubriques que ce type réduit. Une section peut n'en porter aucune —
  /// un type sans barème ne réduit rien, et le guichet ne le proposera pas.
  final List<RefReductionLineDto> lines;

  const RefReductionDto({
    required this.code,
    required this.label,
    required this.active,
    this.lines = const [],
  });

  factory RefReductionDto.fromJson(Map<String, dynamic> j) => RefReductionDto(
    code: j['code'] as String,
    label: j['label'] as String,
    // Un serveur qui ne porterait pas le drapeau décrit un barème dont tout
    // est utilisable : `true` est le repli sûr, `false` masquerait tout.
    active: (j['active'] as bool?) ?? true,
    // `pullList` replie `null` sur la liste vide, et c'est ce qu'on veut ici :
    // contrairement à la section racine, une absence de lignes ne signifie
    // rien d'autre que « ce type ne réduit encore rien ».
    lines: pullList(j['lines'], RefReductionLineDto.fromJson),
  );
}

/// Une ligne du barème : ce qu'une nature réduit, sur quelle rubrique.
///
/// Ni id ni code de rattachement : la ligne est **imbriquée dans son type**, et
/// ne se lit jamais seule. C'est l'aplatissement local qui lui donne le code de
/// son parent.
///
/// `percentage` est un pourcentage (0–100), pas de l'argent. Rien ne le calcule
/// en V1 ; il descend, il se range, il attend la V2.
class RefReductionLineDto {
  final String feeCode;
  final double percentage;

  const RefReductionLineDto({required this.feeCode, required this.percentage});

  factory RefReductionLineDto.fromJson(Map<String, dynamic> j) =>
      RefReductionLineDto(
        feeCode: j['feeCode'] as String,
        percentage: (j['percentage'] as num).toDouble(),
      );
}

/// Identité du tenant (école) — racine du bundle, pas rattachée à une année
/// (D5). Réutilisable tel quel si un `SchoolDto` équivalent existe déjà
/// ailleurs côté serveur ; ici greenfield côté front (D6).
class RefSchoolDto {
  final String id;
  final String name;
  final String? country;
  final String? city;
  final String? district;
  final String? municipality;
  final String? address;
  final String? phone;
  final String? email;

  const RefSchoolDto({
    required this.id,
    required this.name,
    this.country,
    this.city,
    this.district,
    this.municipality,
    this.address,
    this.phone,
    this.email,
  });

  factory RefSchoolDto.fromJson(Map<String, dynamic> j) => RefSchoolDto(
    id: j['id'] as String,
    name: j['name'] as String,
    country: j['country'] as String?,
    city: j['city'] as String?,
    district: j['district'] as String?,
    municipality: j['municipality'] as String?,
    address: j['address'] as String?,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
  );
}

/// Socle d'une année (`current` ou `previous`) : année + cycles/niveaux/tarifs
/// de CETTE année. `current`/`previous` partagent exactement cette forme (D2).
class ReferentialYearBundleDto {
  final RefAcademicYearDto academicYear;
  final List<RefSchoolLevelGroupDto> schoolLevelGroups;
  final List<RefSchoolLevelDto> schoolLevels;

  /// Grille tarifaire — **nullable, et la nuance porte de l'argent** (ADR-014
  /// §4). Le serveur retire cette portion du bundle pour qui ne détient pas
  /// `finance.grid.read` et l'envoie à `null` plutôt qu'à `[]`, précisément
  /// pour ne pas laisser croire que l'école n'a pas de tarifs. `null` = non
  /// communiquée, `[]` = réellement aucune. La purge scopée du côté local
  /// dépend de cette distinction : voir `_applyReferential`.
  final List<RefFeeTariffDto>? feeTariffs;

  /// Catalogue boutique **vendable** de l'année — nullable pour exactement la
  /// même raison que [feeTariffs], et avec la même conséquence sur la purge
  /// (ADR-020, décision F4). Le serveur le retire du bundle pour qui ne détient
  /// pas `boutique.catalog.read` et l'envoie à `null` plutôt qu'à `[]`.
  ///
  /// La nuance décide de deux écrans distincts : `null` → « catalogue non
  /// communiqué », `[]` → « la boutique n'a pas encore d'article ». Les replier
  /// l'un sur l'autre ferait conclure au guichet que l'école n'a rien
  /// paramétré, alors qu'il lui manque un droit.
  ///
  /// Les articles retirés de la vente n'y descendent pas : le poste reçoit ce
  /// qu'il peut vendre.
  final List<RefBoutiqueArticleDto>? boutiqueArticles;

  const ReferentialYearBundleDto({
    required this.academicYear,
    required this.schoolLevelGroups,
    required this.schoolLevels,
    required this.feeTariffs,
    this.boutiqueArticles,
  });

  factory ReferentialYearBundleDto.fromJson(Map<String, dynamic> j) =>
      ReferentialYearBundleDto(
        academicYear: RefAcademicYearDto.fromJson(
          j['academicYear'] as Map<String, dynamic>,
        ),
        schoolLevelGroups: pullList(
          j['schoolLevelGroups'],
          RefSchoolLevelGroupDto.fromJson,
        ),
        schoolLevels: pullList(j['schoolLevels'], RefSchoolLevelDto.fromJson),
        // Volontairement hors de `pullList`, qui replie `null` sur la liste
        // vide : c'est exactement la distinction à préserver ici.
        feeTariffs: j['feeTariffs'] == null
            ? null
            : pullList(j['feeTariffs'], RefFeeTariffDto.fromJson),
        boutiqueArticles: j['boutiqueArticles'] == null
            ? null
            : pullList(j['boutiqueArticles'], RefBoutiqueArticleDto.fromJson),
      );
}

/// Un article du catalogue boutique, tel qu'il descend dans le bundle.
///
/// `pricingMode` descend **en clair**, et c'est indispensable : c'est la seule
/// chose qui dise à la caisse si elle doit demander un niveau. Le déduire de la
/// forme des prix conclurait « c'est plat » d'un article dont les cases
/// coïncident aujourd'hui — chez La Fontaine, la Lacoste vaut 10 en primaire et
/// 10 en CTEB — puis la vendrait au tarif primaire en humanités, où elle vaut
/// 15.
///
/// Les deux enum restent en `String` ici : la traduction vers le domaine se fait
/// au mapping, où l'inconnu se décide (`ArticleFamily.fromWire`,
/// `PricingMode.fromWire`). Un DTO qui refuserait une valeur inédite ferait
/// échouer tout le bundle sur un seul article servi par un serveur plus récent.
class RefBoutiqueArticleDto {
  final String id;
  final String academicYearId;
  final String code;
  final String label;
  final String? family;
  final String? pricingMode;

  /// Renseigné ssi `PRIX_UNIQUE`.
  final int? unitPriceInCents;

  /// Renseignée ssi `PRIX_PAR_NIVEAU`.
  final List<RefBoutiqueLevelPriceDto> levelPrices;

  final String currency;

  const RefBoutiqueArticleDto({
    required this.id,
    required this.academicYearId,
    required this.code,
    required this.label,
    this.family,
    this.pricingMode,
    this.unitPriceInCents,
    this.levelPrices = const [],
    required this.currency,
  });

  factory RefBoutiqueArticleDto.fromJson(Map<String, dynamic> j) =>
      RefBoutiqueArticleDto(
        id: j['id'] as String,
        academicYearId: j['academicYearId'] as String,
        code: j['code'] as String,
        label: j['label'] as String,
        family: j['family'] as String?,
        pricingMode: j['pricingMode'] as String?,
        unitPriceInCents: (j['unitPriceInCents'] as num?)?.toInt(),
        levelPrices: pullList(
          j['levelPrices'],
          RefBoutiqueLevelPriceDto.fromJson,
        ),
        currency: (j['currency'] as String?) ?? 'USD',
      );
}

/// Une case de la grille : un niveau, un prix en cents.
class RefBoutiqueLevelPriceDto {
  final String schoolLevelId;
  final int priceInCents;

  const RefBoutiqueLevelPriceDto({
    required this.schoolLevelId,
    required this.priceInCents,
  });

  factory RefBoutiqueLevelPriceDto.fromJson(Map<String, dynamic> j) =>
      RefBoutiqueLevelPriceDto(
        schoolLevelId: j['schoolLevelId'] as String,
        priceInCents: (j['priceInCents'] as num).toInt(),
      );
}

/// Année scolaire. `isCurrent` pré-sélectionne l'année active hors-ligne. La
/// clé wire est `current` (contrat `openApi.yaml`) — le champ Dart reste
/// `isCurrent`. `startDate`/`endDate` sont des `date-time` ISO-8601.
class RefAcademicYearDto {
  final String id;
  final String name;
  final String? startDate; // ISO-8601 (date-time)
  final String? endDate; // ISO-8601 (date-time)
  final bool isCurrent;

  const RefAcademicYearDto({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    required this.isCurrent,
  });

  factory RefAcademicYearDto.fromJson(Map<String, dynamic> j) =>
      RefAcademicYearDto(
        id: j['id'] as String,
        name: j['name'] as String,
        startDate: j['startDate'] as String?,
        endDate: j['endDate'] as String?,
        isCurrent: (j['current'] as bool?) ?? false,
      );
}

/// Cycle (`SchoolLevelGroup`). `periodType` = pont vers l'Académique.
class RefSchoolLevelGroupDto {
  final String id;
  final String name;
  final String code;
  final String? periodType;
  final String academicYearId;
  final int displayOrder;

  const RefSchoolLevelGroupDto({
    required this.id,
    required this.name,
    required this.code,
    this.periodType,
    required this.academicYearId,
    required this.displayOrder,
  });

  factory RefSchoolLevelGroupDto.fromJson(Map<String, dynamic> j) =>
      RefSchoolLevelGroupDto(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        periodType: j['periodType'] as String?,
        academicYearId: j['academicYearId'] as String,
        displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
      );
}

/// Niveau (`SchoolLevel`). `splitIntoClassrooms` pilote la répartition (Classe).
class RefSchoolLevelDto {
  final String id;
  final String name;
  final String code;
  final String levelGroupId;
  final int displayOrder;
  final bool splitIntoClassrooms;

  const RefSchoolLevelDto({
    required this.id,
    required this.name,
    required this.code,
    required this.levelGroupId,
    required this.displayOrder,
    required this.splitIntoClassrooms,
  });

  factory RefSchoolLevelDto.fromJson(Map<String, dynamic> j) =>
      RefSchoolLevelDto(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        levelGroupId: j['levelGroupId'] as String,
        displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
        splitIntoClassrooms: (j['splitIntoClassrooms'] as bool?) ?? false,
      );
}

/// Ligne de la grille tarifaire. Montant en centimes entiers.
class RefFeeTariffDto {
  final String id;
  final String feeCode;

  /// Ce qui distingue deux lignes de **même nature** sur un niveau : « T1 » et
  /// « T2 » d'un minerval étalé. Le serveur le sert depuis V94 et n'en écrit
  /// jamais de vide — il retombe sur la nature quand l'école ne saisit rien.
  ///
  /// Nullable ici quand même : un serveur d'avant V94 ne le porte pas, et une
  /// section absente doit rester un non-événement, jamais une file bloquée.
  final String? code;

  final String? label;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final int amountInCents;
  final String currency;
  final String academicYearId;
  final String? dueAt; // ISO-8601

  const RefFeeTariffDto({
    required this.id,
    required this.feeCode,
    this.code,
    this.label,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.amountInCents,
    required this.currency,
    required this.academicYearId,
    this.dueAt,
  });

  factory RefFeeTariffDto.fromJson(Map<String, dynamic> j) => RefFeeTariffDto(
    id: j['id'] as String,
    feeCode: j['feeCode'] as String,
    code: j['code'] as String?,
    label: j['label'] as String?,
    schoolLevelGroupId: j['schoolLevelGroupId'] as String,
    schoolLevelId: j['schoolLevelId'] as String,
    amountInCents: (j['amountInCents'] as num).toInt(),
    currency: j['currency'] as String,
    academicYearId: j['academicYearId'] as String,
    dueAt: j['dueAt'] as String?,
  );
}
