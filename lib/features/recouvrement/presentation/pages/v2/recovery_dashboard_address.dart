import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';

/// Ce que l'adresse du tableau de bord retient (spec v2, §0) : frais,
/// périmètre, frais de « Classes en tête », règle et son montant, onglet,
/// recherche de la liste et seuil « ingérable ». Un rafraîchissement ne les
/// perd pas ; la page de la liste repart à la première.
class RecoveryDashboardAddress extends Equatable {
  final List<String> feeCodes;
  final RecoveryScopeKind scope;
  final String? scopeId;
  final String? rankingFeeCode;
  final RecoveryRuleKind rule;
  final int? thresholdInCents;
  final RecoveryTab tab;
  final String search;

  /// Seuil « ingérable » de la simulation, en % de l'effectif (30–90, pas 5).
  final int unmanageableBelow;

  const RecoveryDashboardAddress({
    this.feeCodes = const [],
    this.scope = RecoveryScopeKind.school,
    this.scopeId,
    this.rankingFeeCode,
    this.rule = RecoveryRuleKind.somePayment,
    this.thresholdInCents,
    this.tab = RecoveryTab.toChase,
    this.search = '',
    this.unmanageableBelow = AppConstants.recoveryUnmanageableDefault,
  });

  /// La dernière adresse de la séance — reprise quand on revient par le menu
  /// (A1 : « les frais et le périmètre de la dernière visite »). Mémoire de la
  /// séance seulement, rien sur disque.
  static RecoveryDashboardAddress? lastVisit;

  static const queryKeys = [
    _fees,
    _scope,
    _ranking,
    _rule,
    _amount,
    _tab,
    _search,
    _threshold,
  ];

  static const _fees = 'frais';
  static const _scope = 'perimetre';
  static const _ranking = 'classement';
  static const _rule = 'regle';
  static const _amount = 'montant';
  static const _tab = 'onglet';
  static const _search = 'q';
  static const _threshold = 'seuil';

  static const _ruleWire = {
    RecoveryRuleKind.somePayment: 'quelque-chose',
    RecoveryRuleKind.fullySettled: 'tout-solde',
    RecoveryRuleKind.atLeast: 'au-moins',
  };
  static const _tabWire = {
    RecoveryTab.toChase: 'a-relancer',
    RecoveryTab.inOrder: 'en-ordre',
    RecoveryTab.all: 'tous',
  };

  RecoveryQuestion get question => RecoveryQuestion(
    feeCodes: feeCodes,
    scope: scope,
    scopeId: scopeId,
    rule: rule,
    thresholdInCents: thresholdInCents,
  );

  RecoveryDashboardAddress withQuestion(RecoveryQuestion q) => copyWith(
    feeCodes: q.feeCodes,
    scope: q.scope,
    scopeId: q.scopeId,
    rule: q.rule,
    thresholdInCents: q.thresholdInCents,
  );

  /// `perimetre=cycle:<id>` / `classe:<id>` ; rien pour l'établissement.
  Map<String, String?> toQueryParameters() => {
    _fees: feeCodes.isEmpty ? null : feeCodes.join(','),
    _scope: switch (scope) {
      RecoveryScopeKind.school => null,
      RecoveryScopeKind.cycle => 'cycle:$scopeId',
      RecoveryScopeKind.classroom => 'classe:$scopeId',
    },
    _ranking: rankingFeeCode,
    _rule: rule == RecoveryRuleKind.somePayment ? null : _ruleWire[rule],
    _amount: thresholdInCents?.toString(),
    _tab: tab == RecoveryTab.toChase ? null : _tabWire[tab],
    _search: search.trim().isEmpty ? null : search.trim(),
    _threshold: unmanageableBelow == AppConstants.recoveryUnmanageableDefault
        ? null
        : '$unmanageableBelow',
  };

  /// `null` quand l'adresse ne porte aucun frais : la page s'ouvre alors sur
  /// la dernière visite, puis sur la dernière photo.
  static RecoveryDashboardAddress? fromQueryParameters(Map<String, String> q) {
    String? read(String key) {
      final v = q[key]?.trim() ?? '';
      return v.isEmpty ? null : v;
    }

    final fees = [
      for (final c in (read(_fees) ?? '').split(','))
        if (c.trim().isNotEmpty) c.trim(),
    ];
    if (fees.isEmpty) return null;
    var scope = RecoveryScopeKind.school;
    String? scopeId;
    final rawScope = read(_scope);
    if (rawScope != null) {
      final sep = rawScope.indexOf(':');
      final kind = sep < 0 ? '' : rawScope.substring(0, sep);
      final id = sep < 0 ? '' : rawScope.substring(sep + 1);
      if (id.isNotEmpty && (kind == 'cycle' || kind == 'classe')) {
        scope = kind == 'cycle'
            ? RecoveryScopeKind.cycle
            : RecoveryScopeKind.classroom;
        scopeId = id;
      }
    }
    T? lookup<T>(Map<T, String> wire, String? value) =>
        wire.entries.where((e) => e.value == value).firstOrNull?.key;
    final amount = int.tryParse(read(_amount) ?? '');
    final threshold = int.tryParse(read(_threshold) ?? '');
    return RecoveryDashboardAddress(
      feeCodes: fees,
      scope: scope,
      scopeId: scopeId,
      rankingFeeCode: read(_ranking),
      rule: lookup(_ruleWire, read(_rule)) ?? RecoveryRuleKind.somePayment,
      thresholdInCents: amount != null && amount >= 0 ? amount : null,
      tab: lookup(_tabWire, read(_tab)) ?? RecoveryTab.toChase,
      search: read(_search) ?? '',
      unmanageableBelow: clampUnmanageable(threshold),
    );
  }

  /// 30 à 90 par pas de 5 ; le défaut hors bornes.
  static int clampUnmanageable(int? value) {
    if (value == null ||
        value < AppConstants.recoveryUnmanageableMin ||
        value > AppConstants.recoveryUnmanageableMax) {
      return AppConstants.recoveryUnmanageableDefault;
    }
    return value - value % AppConstants.recoveryUnmanageableStep;
  }

  RecoveryDashboardAddress copyWith({
    List<String>? feeCodes,
    RecoveryScopeKind? scope,
    Object? scopeId = _keep,
    Object? rankingFeeCode = _keep,
    RecoveryRuleKind? rule,
    Object? thresholdInCents = _keep,
    RecoveryTab? tab,
    String? search,
    int? unmanageableBelow,
  }) => RecoveryDashboardAddress(
    feeCodes: feeCodes ?? this.feeCodes,
    scope: scope ?? this.scope,
    scopeId: identical(scopeId, _keep) ? this.scopeId : scopeId as String?,
    rankingFeeCode: identical(rankingFeeCode, _keep)
        ? this.rankingFeeCode
        : rankingFeeCode as String?,
    rule: rule ?? this.rule,
    thresholdInCents: identical(thresholdInCents, _keep)
        ? this.thresholdInCents
        : thresholdInCents as int?,
    tab: tab ?? this.tab,
    search: search ?? this.search,
    unmanageableBelow: unmanageableBelow ?? this.unmanageableBelow,
  );

  @override
  List<Object?> get props => [
    feeCodes,
    scope,
    scopeId,
    rankingFeeCode,
    rule,
    thresholdInCents,
    tab,
    search,
    unmanageableBelow,
  ];
}

const _keep = Object();
