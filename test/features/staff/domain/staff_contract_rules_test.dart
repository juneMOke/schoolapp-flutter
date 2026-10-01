import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_timeline_merge.dart';

import '../staff_builders.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

StaffContract contract(
  String id, {
  String from = '2026-10-01',
  RecordSyncState syncState = RecordSyncState.pending,
  String? correctedAt,
  bool correctionPending = false,
}) => StaffContract(
  id: id,
  staffMemberId: 'm-1',
  kind: StaffContractKind.permanent,
  effectiveFrom: from,
  recordedAt: '2026-09-29T08:00:00Z',
  syncState: syncState,
  amount: const Money(32000, 'USD'),
  correctedAt: correctedAt,
  correctionPending: correctionPending,
);

void main() {
  group('StaffContractValidator', () {
    Map<StaffContractField, StaffContractError> validate(
      StaffContractDraft draft, {
      bool correcting = false,
    }) => StaffContractValidator.validate(draft, correcting: correcting);

    test('un brouillon vide réclame le statut et la date d effet', () {
      expect(validate(const StaffContractDraft()), {
        StaffContractField.kind: StaffContractError.required,
        StaffContractField.effectiveFrom: StaffContractError.required,
      });
    });

    test('un permanent doit un montant lisible', () {
      const base = StaffContractDraft(
        kind: StaffContractKind.permanent,
        effectiveFrom: '2026-10-01',
      );
      expect(validate(base), {
        StaffContractField.amount: StaffContractError.required,
      });
      expect(validate(base.copyWith(amount: '0')), {
        StaffContractField.amount: StaffContractError.amountInvalid,
      });
      expect(validate(base.copyWith(amount: '320')), isEmpty);
    });

    test('un vacataire doit son mode de paiement', () {
      const draft = StaffContractDraft(
        kind: StaffContractKind.vacataire,
        effectiveFrom: '2026-10-01',
        amount: '5',
      );
      expect(validate(draft), {
        StaffContractField.payMode: StaffContractError.required,
      });
      expect(
        validate(draft.copyWith(payMode: () => StaffPayMode.hourly)),
        isEmpty,
      );
    });

    test('un conventionné doit son SECOPE, pas de montant', () {
      const draft = StaffContractDraft(
        kind: StaffContractKind.conventionne,
        effectiveFrom: '2026-10-01',
      );
      expect(validate(draft), {
        StaffContractField.secope: StaffContractError.required,
      });
      expect(validate(draft.copyWith(secopeNumber: 'S-1')), isEmpty);
      expect(validate(draft.copyWith(secopeNumber: 'S-1', bonus: 'x')), {
        StaffContractField.bonus: StaffContractError.amountInvalid,
      });
    });

    test('la fin ne précède pas le début', () {
      const draft = StaffContractDraft(
        kind: StaffContractKind.conventionne,
        secopeNumber: 'S-1',
        effectiveFrom: '2026-10-01',
        endsOn: '2026-09-30',
      );
      expect(validate(draft), {
        StaffContractField.endsOn: StaffContractError.endBeforeStart,
      });
    });

    test('en correction, le motif est exigé — seul pour annuler', () {
      const draft = StaffContractDraft(
        kind: StaffContractKind.permanent,
        effectiveFrom: '2026-10-01',
        amount: '320',
      );
      expect(validate(draft), isEmpty);
      expect(validate(draft, correcting: true), {
        StaffContractField.reason: StaffContractError.required,
      });
      expect(
        StaffContractValidator.reasonErrors(
          const StaffContractDraft(reason: ' doublon '),
          correcting: true,
        ),
        isEmpty,
      );
    });
  });

  group('StaffTimelineMerge', () {
    test('une pose en attente entre dans la frise, rangée par date', () {
      final merged = StaffTimelineMerge.merge(
        [period(StaffContractKind.vacataire, id: 'c-0', from: '2025-09-01')],
        [contract('c-1')],
      );
      expect(merged.map((p) => p.contractId), ['c-0', 'c-1']);
    });

    test('une pose accusée que la fiche ignore encore y reste', () {
      final merged = StaffTimelineMerge.merge(const [], [
        contract('c-1', syncState: RecordSyncState.synced),
      ]);
      expect(merged.single.contractId, 'c-1');
    });

    test('une période corrigée (en vol ou accusée) sort de la frise', () {
      final server = [
        period(StaffContractKind.permanent, id: 'c-1'),
        period(StaffContractKind.permanent, id: 'c-2', from: '2026-01-01'),
      ];
      final merged = StaffTimelineMerge.merge(server, [
        contract(
          'c-1',
          syncState: RecordSyncState.synced,
          correctionPending: true,
        ),
        contract(
          'c-2',
          syncState: RecordSyncState.synced,
          correctedAt: '2026-09-29T09:00:00Z',
        ),
      ]);
      expect(merged, isEmpty);
    });

    test('une pose refusée n est en vigueur nulle part', () {
      final merged = StaffTimelineMerge.merge(const [], [
        contract('c-1', syncState: RecordSyncState.failed),
      ]);
      expect(merged, isEmpty);
    });

    test('la version de la fiche l emporte sur le doublon local', () {
      final server = [period(StaffContractKind.permanent, id: 'c-1')];
      final merged = StaffTimelineMerge.merge(server, [
        contract('c-1', syncState: RecordSyncState.synced),
      ]);
      expect(merged, server);
    });
  });

  group('StaffDossier et pièces refusées', () {
    test('une pièce refusée n est ni comptée ni préférée', () {
      final kept = document('m-1', 'ID');
      const rejected = StaffDocument(
        id: 'm-1-ID-2',
        staffMemberId: 'm-1',
        code: StaffDocumentCode.identity,
        rawCode: 'ID',
        source: StaffDocumentSource.scan,
        capturedAt: '2026-09-01T10:00:00.000Z',
        mimeType: 'image/jpeg',
        sizeBytes: 1,
        syncState: RecordSyncState.failed,
      );

      expect(
        StaffDossierSnapshot(
          types: documentTypes,
          documents: [rejected, kept],
        ).currentOf('ID'),
        kept,
      );
      expect(
        const StaffDossierSnapshot(
          types: documentTypes,
          documents: [rejected],
        ).currentOf('ID'),
        rejected,
      );
      expect(
        StaffDossier.of(
          kind: null,
          types: documentTypes,
          documents: const [rejected],
        ).done,
        0,
      );
    });
  });
}
