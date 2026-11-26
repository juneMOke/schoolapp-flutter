import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_declaration_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_declaration_row.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/mappers/expense_mappers.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_payload.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_declaration_repository.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_server_message_ids.dart';

/// Déclarer : la photo d'abord, puis la ligne, ses messages et son entrée
/// d'outbox dans une seule transaction.
///
/// Tout ce que l'écran aurait dû empêcher est **revérifié ici** (F47) : un
/// refus à l'envoi arriverait des heures plus tard, quand l'argent est sorti
/// depuis longtemps.
class ExpenseDeclarationRepositoryImpl implements ExpenseDeclarationRepository {
  final ExpenseDeclarationDao _dao;
  final ExpenseTypeDao _types;
  final ExpenseVoucherBlobs _blobs;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final SyncEngine? _syncEngine;
  final DateTime Function() _now;

  ExpenseDeclarationRepositoryImpl({
    required ExpenseDeclarationDao dao,
    required ExpenseTypeDao types,
    required ExpenseVoucherBlobs blobs,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    SyncEngine? syncEngine,
    DateTime Function()? now,
  }) : _dao = dao,
       _types = types,
       _blobs = blobs,
       _currentUser = currentUser,
       _ids = ids,
       _syncEngine = syncEngine,
       _now = now ?? DateTime.now;

  static const _noVoucher = ValidationFailure('La photo du bon est requise.');
  static const _badVoucher = ValidationFailure(
    'La photo du bon doit être une image JPEG ou PNG, ou un PDF.',
  );
  static const _heavyVoucher = ValidationFailure(
    'La photo du bon dépasse 5 Mo.',
  );
  static const _noAmount = ValidationFailure('Le montant doit être positif.');
  static const _advance = ValidationFailure(
    'Une avance au personnel ne se déclare pas : elle passe par la paie.',
  );
  static const _unknownType = ValidationFailure('Type de dépense inconnu.');

  @override
  Future<Either<Failure, Expense>> declare(
    ExpenseDeclarationDraft draft,
  ) async {
    final schoolId = _currentUser.schoolId ?? '';
    if (schoolId.isEmpty) return const Left(StorageFailure('Aucune école'));
    final authorId = _currentUser.uid;
    if (authorId == null) return const Left(AuthFailure('Aucune session'));
    final invalid = await _validate(draft, schoolId);
    if (invalid != null) return Left(invalid);
    try {
      return Right(await _write(draft, schoolId: schoolId, authorId: authorId));
    } on _VoucherNotSealed {
      return const Left(StorageFailure('Photo du bon non scellée'));
    } on ExpenseRedeclarationStale {
      return const Left(
        ConflictFailure('La déclaration refusée n’est plus à régulariser.'),
      );
    } catch (e) {
      return Left(StorageFailure('Déclaration non enregistrée : $e'));
    }
  }

  Future<ValidationFailure?> _validate(
    ExpenseDeclarationDraft draft,
    String schoolId,
  ) async {
    const policy = DocumentCapturePolicy.expenseVoucher;
    if (draft.voucherBytes.isEmpty) return _noVoucher;
    if (!policy.acceptedTypes.any((t) => t.value == draft.voucherContentType)) {
      return _badVoucher;
    }
    if (draft.voucherBytes.length > policy.maxBytes) return _heavyVoucher;
    if (draft.amountInCents <= 0) return _noAmount;
    final types = await _types.typesForSchool(schoolId);
    final type = types.where((t) => t.id == draft.typeId).firstOrNull;
    if (type == null) return _unknownType;
    if (type.code == ExpenseStaffAdvance.typeCode) return _advance;
    return null;
  }

  Future<Expense> _write(
    ExpenseDeclarationDraft draft, {
    required String schoolId,
    required String authorId,
  }) async {
    final now = _now().toUtc();
    // Une horloge de tablette en avance n'invente pas un décaissement futur.
    final disbursedAt = draft.disbursedAt.toUtc().isAfter(now)
        ? now
        : draft.disbursedAt.toUtc();
    final day = ExpenseDay.format(SchoolTime.today(disbursedAt));
    final id = _ids.newId();
    final messageId = _ids.newId();
    final visaId = draft.visaOnDeclare
        ? ExpenseServerMessageIds.visa(id)
        : null;
    final nowIso = now.toIso8601String();
    final nowMs = now.millisecondsSinceEpoch;

    // La photo AVANT la transaction : une déclaration en file sans ses octets
    // ne partirait jamais. Si la transaction échoue ensuite, la photo reste
    // orpheline — un fichier de trop, jamais un argent perdu.
    if (!await _blobs.write(id, draft.voucherBytes)) throw _VoucherNotSealed();

    final row = ExpenseLocalModel(
      id: id,
      schoolId: schoolId,
      typeId: draft.typeId,
      title: draft.title.trim(),
      description: _blankToNull(draft.description),
      amountInCents: draft.amountInCents,
      currency: CurrencyCode.normalize(draft.currency),
      status: ExpenseStatus.paid.wireValue,
      paidOn: day,
      expenseDate: day,
      supplier: _blankToNull(draft.supplier),
      fundingSource: draft.fundingSource.wireValue,
      recordedById: authorId,
      recordedByName: draft.recordedByName,
      clientUpdatedAt: nowIso,
      syncStatus: ExpenseSyncState.pending.dbValue,
      updatedAt: nowMs,
      declaration: ExpenseDeclarationRow(
        mode: ExpenseMode.declaration.wireValue,
        visaStatus:
            (visaId == null
                    ? ExpenseVisaStatus.pending
                    : ExpenseVisaStatus.visaed)
                .wireValue,
        visaById: visaId == null ? null : authorId,
        visaByName: visaId == null ? null : draft.recordedByName,
        visaAt: visaId == null ? null : nowIso,
        disbursedAt: disbursedAt.toIso8601String(),
        voucherId: id,
        voucherContentType: draft.voucherContentType,
        voucherSizeBytes: draft.voucherBytes.length,
      ),
    );
    final messages = [
      ExpenseMessageLocalModel.at(
        now,
        id: messageId,
        schoolId: schoolId,
        expenseId: id,
        body: draft.note.trim(),
        act: ExpenseAct.declaration,
        authorId: authorId,
        authorName: draft.recordedByName,
      ),
      // Le visa d'office suit la déclaration d'une milliseconde : le fil
      // s'ordonne sur son horloge, et il doit se lire dans ce sens.
      if (visaId != null)
        ExpenseMessageLocalModel.at(
          now.add(const Duration(milliseconds: 1)),
          id: visaId,
          schoolId: schoolId,
          expenseId: id,
          body: '',
          act: ExpenseAct.visa,
          authorId: authorId,
          authorName: draft.recordedByName,
        ),
    ];
    final payload = ExpenseDeclarationPayload(
      expense: row.toInput(),
      disbursedAt: disbursedAt.toIso8601String(),
      messageId: messageId,
      messageBody: draft.note.trim(),
      authorId: authorId,
      voucherContentType: draft.voucherContentType,
      visaMessageId: visaId,
    );
    await _dao.insert(
      row: row,
      messages: messages,
      entry: OutboxEntry(
        id: ExpenseDeclarationDao.entryId(id),
        aggregateType: ExpenseDeclarationDao.aggregateType,
        aggregateId: id,
        operation: OutboxOperation.upsert,
        payload: jsonEncode(payload.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
      replacing: draft.replacing,
      nowMs: nowMs,
    );
    final replaced = draft.replacing;
    if (replaced != null) unawaited(_blobs.delete(replaced));
    final engine = _syncEngine;
    if (engine != null) unawaited(engine.flush());
    return row.toEntity()!;
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class _VoucherNotSealed implements Exception {}
