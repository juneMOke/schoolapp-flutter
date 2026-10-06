import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';

/// Type d'agrégat d'outbox de l'évaluation (routage → `EvaluationOutboxHandler`).
const String kEvaluationAggregateType = 'ACADEMICS_EVALUATION';

/// Écriture offline-first d'une évaluation (**régime A**, insert-only) :
/// matérialise la ligne locale `PENDING_SYNC` + enfile l'enveloppe de push, dans
/// une seule transaction (via le datasource). L'`authorId` est estampillé depuis
/// [CurrentUserContext] au moment de la saisie (ADR-010 D-05).
class EvaluationOfflineRepositoryImpl {
  final AcademicsLocalDataSource _local;
  final IdGenerator _idGenerator;
  final CurrentUserContext? _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const EvaluationOfflineRepositoryImpl({
    required AcademicsLocalDataSource localDataSource,
    required IdGenerator idGenerator,
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _local = localDataSource,
       _idGenerator = idGenerator,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  /// Id d'outbox déterministe **unique par évaluation** (idempotence du push).
  static String aggregateOutboxId(String evaluationId) =>
      '$kEvaluationAggregateType:$evaluationId';

  /// Crée une évaluation localement. [type] en valeur wire (INTERRO/DEVOIR/
  /// EXAMEN). [date] est ancrée UTC à minuit pour un aller-retour date-only sans
  /// dérive de fuseau. Rattachement temporel exclusif : un seul de [sousPeriodeId]
  /// / [periodeScolaireId] doit être non nul (garanti par l'appelant / l'UI).
  /// [chapitreIds] est intra-agrégat (régime A) : figé à la création, jamais
  /// modifié ensuite. [titre] et [cadre] sont écrits avec la ligne ; le cadre
  /// devient ensuite le sujet, modifiable (sous-agrégat LWW).
  Future<Either<Failure, EvaluationRow>> createEvaluation({
    required String coursId,
    required String type,
    required DateTime date,
    required double maxPoints,
    required int poids,
    String? sousPeriodeId,
    String? periodeScolaireId,
    List<String> chapitreIds = const [],
    String? titre,
    EvaluationCadre cadre = EvaluationCadre.empty,
  }) async {
    try {
      final nowMs = _now();
      final id = _idGenerator.newId();
      final evalDate = DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).millisecondsSinceEpoch;

      final row = EvaluationRow(
        id: id,
        coursId: coursId,
        type: type,
        evalDate: evalDate,
        maxPoints: maxPoints,
        poids: poids,
        sousPeriodeId: sousPeriodeId,
        periodeScolaireId: periodeScolaireId,
        updatedAt: nowMs,
        chapitreIdsJson: EvaluationRow.encodeChapitreIds(chapitreIds),
        titre: titre,
      );

      final sujet = EvaluationSujetRow.fromEntity(cadre, const []);
      final entry = OutboxEntry(
        id: aggregateOutboxId(id),
        aggregateType: kEvaluationAggregateType,
        aggregateId: id,
        operation: OutboxOperation.create,
        payload: EvaluationPushRequestModel(
          authorId: _currentUser?.uid,
          coursId: coursId,
          evaluation: EvaluationInputModel.fromRow(row, sujet: sujet),
        ).toJsonString(),
        createdAt: nowMs,
      );

      await _local.createEvaluationWithOutbox(
        row: row,
        sujet: sujet,
        outboxEntry: entry,
      );
      // Flush opportuniste : si connecté, l'évaluation part tout de suite.
      final engine = _syncEngine;
      if (engine != null) unawaited(engine.flush());
      return Right(row);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
