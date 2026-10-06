import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_codecs.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

/// Colonnes « sujet » de la ligne `evaluation` — un **sous-agrégat LWW**.
///
/// L'évaluation garde son régime A (insert seul) ; ce qui change après la
/// création — cadre et questions — vit ici, avec son propre statut d'envoi.
/// Le pull réécrit l'évaluation sans jamais toucher ces colonnes tant que
/// [syncStatus] vaut `PENDING_SYNC`.
///
/// [syncStatus] nul = jamais modifié depuis la création : le cadre est parti
/// avec l'enveloppe de création, il n'y a rien à envoyer.
class EvaluationSujetRow extends Equatable {
  final int? dureeMinutes;
  final List<String> programme;
  final String? consignes;
  final List<SujetQuestion> questions;

  /// Horloge client (epoch ms) de la dernière écriture du sujet ; garde de
  /// l'accusé et arbitre du dernier enregistrement gagnant.
  final int? updatedAt;
  final String? syncStatus;
  final String? rejectionCode;

  const EvaluationSujetRow({
    this.dureeMinutes,
    this.programme = const [],
    this.consignes,
    this.questions = const [],
    this.updatedAt,
    this.syncStatus,
    this.rejectionCode,
  });

  /// Colonnes lues par [fromMap] — à passer en `columns:` d'une requête.
  static const List<String> columns = [
    'duree_minutes',
    'programme_json',
    'consignes',
    'sujet_questions_json',
    'sujet_updated_at',
    'sujet_sync_status',
    'sujet_rejection_code',
  ];

  factory EvaluationSujetRow.fromEntity(
    EvaluationCadre cadre,
    List<SujetQuestion> questions, {
    int? updatedAt,
    String? syncStatus,
  }) {
    final normalized = cadre.normalized();
    return EvaluationSujetRow(
      dureeMinutes: normalized.dureeMinutes,
      programme: normalized.programme,
      consignes: normalized.consignes,
      questions: questions,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }

  factory EvaluationSujetRow.fromMap(Map<String, Object?> map) =>
      EvaluationSujetRow(
        dureeMinutes: (map['duree_minutes'] as num?)?.toInt(),
        programme: SujetCodecs.programmeFromJson(
          SujetCodecs.decodeColumn(map['programme_json']),
        ),
        consignes: map['consignes'] as String?,
        questions: SujetCodecs.questionsFromJson(
          SujetCodecs.decodeColumn(map['sujet_questions_json']),
        ),
        updatedAt: (map['sujet_updated_at'] as num?)?.toInt(),
        syncStatus: map['sujet_sync_status'] as String?,
        rejectionCode: map['sujet_rejection_code'] as String?,
      );

  Map<String, Object?> toMap() => {
    'duree_minutes': dureeMinutes,
    'programme_json': jsonEncode(programme),
    'consignes': consignes,
    'sujet_questions_json': jsonEncode(SujetCodecs.questionsToJson(questions)),
    'sujet_updated_at': updatedAt,
    'sujet_sync_status': syncStatus,
    'sujet_rejection_code': rejectionCode,
  };

  EvaluationCadre get cadre => EvaluationCadre(
    dureeMinutes: dureeMinutes,
    programme: programme,
    consignes: consignes,
  );

  EvaluationSujet toEntity() => EvaluationSujet(
    cadre: cadre,
    questions: questions,
    envoi: switch (syncStatus) {
      null => SujetEnvoi.initial,
      _ => switch (SyncState.fromDbValue(syncStatus)) {
        SyncState.synced => SujetEnvoi.envoye,
        SyncState.syncError => SujetEnvoi.refuse,
        _ => SujetEnvoi.enAttente,
      },
    },
    rejectionCode: rejectionCode,
  );

  @override
  List<Object?> get props => [
    dureeMinutes,
    programme,
    consignes,
    questions,
    updatedAt,
    syncStatus,
    rejectionCode,
  ];
}
