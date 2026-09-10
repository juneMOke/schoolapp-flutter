import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

part 'relance_list_request_model.g.dart';

/// Un montant du corps : **une entrée par devise**, jamais un total.
///
/// La forme est celle du `MoneyBag` du front et du `Money(amountInCents,
/// currency)` de l'éditique serveur — un tableau d'objets, et non un objet
/// compact `{"USD": 30000}`. La forme compacte pèse 3 % de moins sur le fil une
/// fois compressée : pas de quoi tordre un contrat.
@JsonSerializable(createFactory: false)
class RelanceAmountModel {
  final String currency;
  final int amountInCents;

  const RelanceAmountModel({
    required this.currency,
    required this.amountInCents,
  });

  Map<String, dynamic> toJson() => _$RelanceAmountModelToJson(this);
}

/// Une ligne de la liste : **un identifiant et trois sacs**, rien d'autre.
///
/// Le nom, le matricule et la classe sont résolus **par le serveur** depuis son
/// référentiel. Deux raisons, dans cet ordre : sa garde du libellé de périmètre
/// s'arrêtait au titre et laissait les lignes libres — une tablette pouvait
/// titrer « 5ème année » honnêtement et coller « 6ème A » sur chaque ligne ; et
/// un nom recopié d'un miroir local a pu vieillir, alors que le papier scellé
/// doit porter l'orthographe du référentiel.
///
/// **Les sacs partent non élagués.** Un élève soldé part avec
/// `outstanding: [{USD, 0}]`, pas un sac vide : le sac vide dit « aucun
/// montant », l'entrée à zéro dit « en dollars, il ne reste rien ». Le serveur
/// traite de toute façon une devise absente comme un zéro.
@JsonSerializable(createFactory: false, explicitToJson: true)
class RelanceLineModel {
  final String studentId;
  final List<RelanceAmountModel> due;
  final List<RelanceAmountModel> paid;
  final List<RelanceAmountModel> outstanding;

  const RelanceLineModel({
    required this.studentId,
    required this.due,
    required this.paid,
    required this.outstanding,
  });

  factory RelanceLineModel.fromLine(LocalRecoveryLine line) => RelanceLineModel(
    studentId: line.studentId,
    due: _amounts(line.expected),
    paid: _amounts(line.paidTotal),
    outstanding: _amounts(line.remaining),
  );

  static List<RelanceAmountModel> _amounts(MoneyBag bag) => [
    for (final entry in bag.entries)
      RelanceAmountModel(
        currency: entry.currency,
        amountInCents: entry.amountInCents,
      ),
  ];

  Map<String, dynamic> toJson() => _$RelanceLineModelToJson(this);
}

@JsonSerializable(createFactory: false)
class RelanceScopeModel {
  final String kind;

  /// `null` pour `UNASSIGNED`, qui ne désigne aucune entité du référentiel.
  @JsonKey(includeIfNull: false)
  final String? id;

  const RelanceScopeModel({required this.kind, this.id});

  factory RelanceScopeModel.from(RelanceScope scope) => RelanceScopeModel(
    kind: switch (scope.kind) {
      RelanceScopeKind.classroom => 'CLASSROOM',
      RelanceScopeKind.schoolLevel => 'SCHOOL_LEVEL',
      RelanceScopeKind.schoolLevelGroup => 'SCHOOL_LEVEL_GROUP',
      RelanceScopeKind.unassigned => 'UNASSIGNED',
    },
    id: scope.id,
  );

  Map<String, dynamic> toJson() => _$RelanceScopeModelToJson(this);
}

/// Le corps de `POST /api/v1/finance/relance-list`.
///
/// `explicitToJson` n'est pas décoratif : sans lui, `toJson()` laisse les objets
/// imbriqués tels quels et le corps porte des instances Dart. Seul `jsonEncode`
/// les déplierait, au bon vouloir de l'encodeur — et aucun test ne pourrait
/// vérifier ce qui part réellement sur le fil.
///
/// **La tablette envoie les lignes ; le serveur imprime.** Elle est l'autorité
/// de cet écran — seule elle voit les encaissements non encore remontés — donc
/// elle est l'autorité du papier qui en sort. Un calcul serveur créerait deux
/// autorités pour un seul écran, et douze noms à l'écran contre treize sur le
/// papier signé.
///
/// Le serveur garde deux gardes qu'il ne peut pas céder : chaque `studentId`
/// doit porter une créance de cette école et de cette année, et le libellé du
/// périmètre est résolu chez lui.
@JsonSerializable(createFactory: false, explicitToJson: true)
class RelanceListRequestModel {
  final RelanceScopeModel scope;

  /// Les natures retenues, telles que l'écran les affiche. **Descriptives** :
  /// le serveur les imprime en sous-titre, il ne filtre rien avec.
  final List<String> feeCodes;

  /// `NO_PAYMENT` · `NOT_SETTLED` · `BELOW_THRESHOLD`. Descriptif lui aussi :
  /// c'est nous qui avons filtré.
  final String criterion;

  @JsonKey(includeIfNull: false)
  final int? thresholdInCents;

  @JsonKey(includeIfNull: false)
  final String? thresholdCurrency;

  /// L'heure à laquelle **l'appareil** a arrêté ces chiffres.
  ///
  /// Obligatoire : c'est la seule chose qui rende le papier lisible six heures
  /// plus tard. Le document imprime **aussi** la date d'émission du serveur, et
  /// les deux ne se confondent pas — une horloge de tablette dérive hors ligne.
  final String arretedAt;

  /// Nombre d'**encaissements** de la file finance non encore acquittés.
  ///
  /// Ni les inscriptions, ni les transferts de classe, ni la présence — et le
  /// gabarit dit « encaissement(s) » pour cette raison. Imprimé tel quel, il
  /// n'entre dans aucun calcul.
  @JsonKey(includeIfNull: false)
  final int? pendingWrites;

  final List<RelanceLineModel> lines;

  const RelanceListRequestModel({
    required this.scope,
    required this.feeCodes,
    required this.criterion,
    required this.arretedAt,
    required this.lines,
    this.thresholdInCents,
    this.thresholdCurrency,
    this.pendingWrites,
  });

  factory RelanceListRequestModel.of({
    required RelanceScope scope,
    required List<String> feeCodes,
    required RecouvrementCriterion criterion,
    required List<LocalRecoveryLine> lines,
    required DateTime arretedAt,
    int? thresholdInCents,
    String? thresholdCurrency,
    int? pendingWrites,
  }) => RelanceListRequestModel(
    scope: RelanceScopeModel.from(scope),
    feeCodes: feeCodes,
    criterion: switch (criterion) {
      RecouvrementCriterion.noPayment => 'NO_PAYMENT',
      RecouvrementCriterion.notSettled => 'NOT_SETTLED',
      RecouvrementCriterion.belowThreshold => 'BELOW_THRESHOLD',
    },
    thresholdInCents: thresholdInCents,
    thresholdCurrency: thresholdCurrency,
    arretedAt: arretedAt.toUtc().toIso8601String(),
    pendingWrites: pendingWrites,
    lines: [for (final line in lines) RelanceLineModel.fromLine(line)],
  );

  Map<String, dynamic> toJson() => _$RelanceListRequestModelToJson(this);
}
