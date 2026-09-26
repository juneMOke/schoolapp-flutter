import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_composer.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';

/// Le geste « Annuler » / « Corriger » sur un versement (lot T2).
class PaymentCorrectionRepositoryImpl implements PaymentCorrectionRepository {
  final PaymentCorrectionWriteDao _dao;
  final PaymentComposer _composer;
  final IdGenerator _idGenerator;
  final SyncEngine _syncEngine;
  final CurrentUserContext? _currentUser;
  final int Function() _now;

  PaymentCorrectionRepositoryImpl({
    required PaymentCorrectionWriteDao dao,
    required PaymentComposer composer,
    required IdGenerator idGenerator,
    required SyncEngine syncEngine,
    CurrentUserContext? currentUser,
    int Function()? now,
  }) : _dao = dao,
       _composer = composer,
       _idGenerator = idGenerator,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _now = now ?? systemClock;

  @override
  Future<Either<Failure, PaymentCorrectionOutcome>> correctPayment(
    PaymentCorrectionDraft draft,
  ) async {
    try {
      if (!draft.reason.fits(draft.gesture)) {
        return const Left(
          ValidationFailure('Ce motif ne correspond pas à ce geste.'),
        );
      }
      final detail = draft.reasonDetail?.trim();
      if (draft.reason.requiresDetail && (detail == null || detail.isEmpty)) {
        return const Left(ValidationFailure('Précisez le motif.'));
      }

      final origin = await _dao.findOrigin(draft.paymentId);
      if (origin == null) {
        return const Left(ValidationFailure('Versement introuvable.'));
      }
      if (origin.serverCancelled || origin.alreadyCorrected) {
        return const Left(ValidationFailure('Ce versement est déjà annulé.'));
      }

      final now = _now();
      final replacementDraft = draft.replacement;
      ComposedPayment? replacement;
      if (replacementDraft != null) {
        final composed = await _composer.compose(
          replacementDraft,
          nowMs: now,
          replacesPaymentId: origin.id,
        );
        final failure = composed.fold<Failure?>((f) => f, (_) => null);
        if (failure != null) return Left(failure);
        replacement = composed.fold((_) => null, (payment) => payment);
      }

      // R2 : une origine refusée pour de bon par le serveur ne sera jamais
      // synchronisée. La correction reste locale ; attendre l'origine la
      // gèlerait pour toujours.
      final localOnly = origin.refusedByServer;
      final correctionId = _idGenerator.newId();

      await _dao.recordCorrection(
        PaymentCorrectionWrite(
          correctionId: correctionId,
          origin: origin,
          reasonCode: draft.reason.code,
          reason: (detail == null || detail.isEmpty) ? null : detail,
          cashMoved: draft.cashMoved,
          authorId: _currentUser?.uid,
          replacement: replacement,
          localOnly: localOnly,
        ),
        outboxEntryId: _idGenerator.newId(),
        // Garde-fou tenant de l'outbox, comme l'encaissement.
        schoolId: _currentUser?.schoolId,
        nowMs: now,
      );

      unawaited(_syncEngine.flush());
      return Right(
        PaymentCorrectionOutcome(
          correctionId: correctionId,
          replacementPaymentId: replacement?.payment.id,
          localOnly: localOnly,
        ),
      );
    } on StateError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(StorageFailure('Échec de la correction locale : $e'));
    }
  }
}
