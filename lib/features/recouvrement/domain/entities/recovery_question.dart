import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';

/// La rubrique « Non affectés » sur le fil (`classroomId=UNASSIGNED`,
/// périmètre `UNASSIGNED` de la liste de relance).
const String recoveryUnassigned = 'UNASSIGNED';

/// Le périmètre du tableau de bord : tout l'établissement, un cycle ou une
/// classe. Mêmes noms de fil que le serveur (`scope=…`).
enum RecoveryScopeKind {
  school('SCHOOL'),
  cycle('SCHOOL_LEVEL_GROUP'),
  classroom('CLASSROOM');

  final String wire;

  const RecoveryScopeKind(this.wire);

  static RecoveryScopeKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Les trois onglets de « Où en est chaque élève ? ».
enum RecoveryTab {
  toChase('TO_CHASE'),
  inOrder('IN_ORDER'),
  all('ALL');

  final String wire;

  const RecoveryTab(this.wire);

  static RecoveryTab? fromWire(String? value) {
    for (final tab in values) {
      if (tab.wire == value) return tab;
    }
    return null;
  }
}

/// La question que pose toute la page (R14 : une seule source) — frais,
/// périmètre, règle « en ordre » et son montant.
///
/// Les chiffres, la liste, la fiche de classe et les exports partent tous de
/// cette question : c'est elle que le cache hors ligne retient avec sa
/// réponse.
class RecoveryQuestion extends Equatable {
  /// Codes du catalogue, dans l'ordre de l'école ; jamais vide.
  final List<String> feeCodes;
  final RecoveryScopeKind scope;

  /// Le cycle ou la classe ; `null` pour tout l'établissement.
  final String? scopeId;
  final RecoveryRuleKind rule;

  /// Le montant de « a payé au moins », en centimes de l'unique devise du
  /// périmètre. Envoyé aussi hors de cette règle : il nourrit le compteur
  /// du troisième choix (A8).
  final int? thresholdInCents;

  const RecoveryQuestion({
    required this.feeCodes,
    this.scope = RecoveryScopeKind.school,
    this.scopeId,
    this.rule = RecoveryRuleKind.somePayment,
    this.thresholdInCents,
  });

  /// La règle réellement posée au serveur : « au moins » sans montant ne
  /// compte personne (R8) et part en 400 — on demande alors la règle par
  /// défaut, l'écran affichant « saisissez un montant ».
  RecoveryRuleKind get effectiveRule =>
      rule == RecoveryRuleKind.atLeast && thresholdInCents == null
      ? RecoveryRuleKind.somePayment
      : rule;

  RecoveryQuestion copyWith({
    List<String>? feeCodes,
    RecoveryScopeKind? scope,
    Object? scopeId = _keep,
    RecoveryRuleKind? rule,
    Object? thresholdInCents = _keep,
  }) => RecoveryQuestion(
    feeCodes: feeCodes ?? this.feeCodes,
    scope: scope ?? this.scope,
    scopeId: identical(scopeId, _keep) ? this.scopeId : scopeId as String?,
    rule: rule ?? this.rule,
    thresholdInCents: identical(thresholdInCents, _keep)
        ? this.thresholdInCents
        : thresholdInCents as int?,
  );

  /// Les paramètres de requête communs aux quatre routes.
  Map<String, dynamic> toQueryParameters() => {
    'feeCodes': feeCodes.join(','),
    'scope': scope.wire,
    if (scope != RecoveryScopeKind.school && scopeId != null)
      'scopeId': scopeId,
    'rule': effectiveRule.wire,
    if (thresholdInCents != null) 'thresholdInCents': thresholdInCents,
  };

  Map<String, dynamic> toJson() => {
    'feeCodes': feeCodes,
    'scope': scope.wire,
    'scopeId': scopeId,
    'rule': rule.wire,
    'thresholdInCents': thresholdInCents,
  };

  /// `null` si la photo est illisible : elle ne se sert pas.
  static RecoveryQuestion? fromJson(Object? json) {
    if (json is! Map) return null;
    final codes = json['feeCodes'];
    final scope = RecoveryScopeKind.fromWire(json['scope'] as String?);
    final rule = RecoveryRuleKind.values
        .where((r) => r.wire == json['rule'])
        .firstOrNull;
    if (codes is! List || codes.isEmpty || scope == null || rule == null) {
      return null;
    }
    return RecoveryQuestion(
      feeCodes: [for (final c in codes) c.toString()],
      scope: scope,
      scopeId: json['scopeId'] as String?,
      rule: rule,
      thresholdInCents: (json['thresholdInCents'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [feeCodes, scope, scopeId, rule, thresholdInCents];
}

/// Une page de la liste nominative (E) ou de la fiche de classe (O2).
class RecoveryStudentsQuery extends Equatable {
  final RecoveryQuestion question;
  final RecoveryTab tab;

  /// Fiche de classe : une classe, ou `UNASSIGNED` pour « Non affectés ».
  final String? classroomId;

  /// Filtre de situation de la fiche de classe (`NO_PAYMENT`, `PARTIAL`,
  /// `SETTLED`).
  final String? situation;
  final String? search;
  final int page;
  final int size;

  const RecoveryStudentsQuery({
    required this.question,
    this.tab = RecoveryTab.toChase,
    this.classroomId,
    this.situation,
    this.search,
    this.page = 0,
    this.size = 10,
  });

  String? get trimmedSearch {
    final s = search?.trim();
    return s == null || s.isEmpty ? null : s;
  }

  /// Seule la première page de la liste, sans recherche ni fiche de classe,
  /// se garde hors ligne.
  bool get isCacheable =>
      page == 0 &&
      trimmedSearch == null &&
      classroomId == null &&
      situation == null;

  /// Paramètres des exports : la recherche ne restreint pas l'export (Q5).
  Map<String, dynamic> toExportParameters() => {
    ...question.toQueryParameters(),
    'tab': tab.wire,
    if (classroomId != null) 'classroomId': classroomId,
    if (situation != null) 'situation': situation,
  };

  Map<String, dynamic> toQueryParameters() => {
    ...toExportParameters(),
    if (trimmedSearch != null) 'q': trimmedSearch,
    'page': page,
    'size': size,
  };

  RecoveryStudentsQuery copyWith({
    RecoveryQuestion? question,
    RecoveryTab? tab,
    Object? classroomId = _keep,
    Object? situation = _keep,
    Object? search = _keep,
    int? page,
  }) => RecoveryStudentsQuery(
    question: question ?? this.question,
    tab: tab ?? this.tab,
    classroomId: identical(classroomId, _keep)
        ? this.classroomId
        : classroomId as String?,
    situation: identical(situation, _keep)
        ? this.situation
        : situation as String?,
    search: identical(search, _keep) ? this.search : search as String?,
    page: page ?? this.page,
    size: size,
  );

  @override
  List<Object?> get props => [
    question,
    tab,
    classroomId,
    situation,
    search,
    page,
    size,
  ];
}

const _keep = Object();
