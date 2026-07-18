import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_input_model.dart';

/// Agrégat disciplinaire poussé au serveur (`POST /sync/disciplinary-cases`,
/// contrat 1.1.0) : `{case, comments[]}`. **Le même agrégat sert la création et
/// chaque évolution** (upsert) — le client re-pousse l'état courant du cas + ses
/// commentaires. Sert aussi de **payload d'outbox** (`toJsonString`/`fromJsonString`).
///
/// Régimes : le `case` = FAIT insert-only + TRAITEMENT LWW ; les `comments` =
/// append-only dédupliqués serveur par `id`.
class DisciplinaryCaseAggregateRequestModel extends Equatable {
  final DisciplinaryCaseInputModel caseInput;
  final List<DisciplinaryCommentInputModel> comments;

  const DisciplinaryCaseAggregateRequestModel({
    required this.caseInput,
    this.comments = const [],
  });

  factory DisciplinaryCaseAggregateRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = (json['comments'] as List<dynamic>?) ?? const [];
    return DisciplinaryCaseAggregateRequestModel(
      caseInput: DisciplinaryCaseInputModel.fromJson(
        json['case'] as Map<String, dynamic>,
      ),
      comments: raw
          .map(
            (e) => DisciplinaryCommentInputModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'case': caseInput.toJson(),
    'comments': comments.map((c) => c.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory DisciplinaryCaseAggregateRequestModel.fromJsonString(
    String payload,
  ) => DisciplinaryCaseAggregateRequestModel.fromJson(
    jsonDecode(payload) as Map<String, dynamic>,
  );

  @override
  List<Object?> get props => [caseInput, comments];
}
