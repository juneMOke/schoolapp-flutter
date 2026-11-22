import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';

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
