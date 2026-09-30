import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';

import '../../staff_fixtures.dart';

void main() {
  group('StaffMemberDeltaDto', () {
    test('lit une fiche complète, frise et diplômes compris', () {
      final dto = StaffMemberDeltaDto.tryParse(
        staffMemberJson(
          'm-1',
          contracts: [
            contractPeriodJson(
              'c-1',
              kind: 'VACATAIRE',
              payMode: 'HEURES_PRESTEES',
            ),
          ],
        ),
      )!;

      expect(dto.staffNumber, 'CF-AG-0001');
      expect(dto.category, 'ENSEIGNANT');
      expect(dto.branches, ['Mathématiques']);
      expect(dto.diplomas.single.level, 'Licence');
      expect(dto.contracts.single.payMode, 'HEURES_PRESTEES');
      expect(dto.clientUpdatedAt, '2026-09-29T08:00:00.000Z');
    });

    test('un agent repris sans dossier reste lisible', () {
      final dto = StaffMemberDeltaDto.tryParse({
        'id': 'm-2',
        'staffNumber': 'CF-AG-0002',
        'lastName': 'Mbuyi',
        'firstName': 'Anne',
        'category': 'ENSEIGNANT',
        'branches': [],
        'diplomas': [],
        'contracts': [],
        'version': 1,
        'serverUpdatedAt': '2026-09-29T08:00:01Z',
      })!;

      expect(dto.sex, isNull);
      expect(dto.entryDate, isNull);
      expect(dto.clientUpdatedAt, isNull);
    });

    test('une fiche sans nom est écartée, une période abîmée aussi', () {
      expect(
        StaffMemberDeltaDto.tryParse({
          ...staffMemberJson('m-3'),
          'lastName': ' ',
        }),
        isNull,
      );
      final dto = StaffMemberDeltaDto.tryParse(
        staffMemberJson(
          'm-4',
          contracts: [
            contractPeriodJson('c-1'),
            {
              'contractId': 'c-2',
              'kind': 'PERMANENT',
              'effectiveFrom': '1er sept',
            },
          ],
        ),
      )!;
      expect(dto.contracts.map((c) => c.contractId), ['c-1']);
    });

    test('une page compte les lignes écartées sans lever', () {
      final page = StaffMemberPageDto.fromJson({
        'items': [
          staffMemberJson('m-1'),
          'illisible',
          {'id': 'm-x'},
        ],
        'hasMore': false,
        'nextWatermark': 'w1',
        'serverTime': '2026-09-29T08:00:00Z',
      });

      expect(page.items.map((m) => m.id), ['m-1']);
      expect(page.skipped, 2);
      expect(page.page.cursorToPersist, 'w1');
    });
  });

  test('StaffContractDeltaDto normalise la devise, jamais ne la rejette', () {
    final dto = StaffContractDeltaDto.tryParse(staffContractJson('c-1'))!;

    expect(dto.currency, 'USD');
    expect(dto.amountInCents, 32000);
    expect(StaffContractDeltaDto.tryParse({'id': 'c-2'}), isNull);
  });

  test('StaffDocumentDeltaDto exige ce qui décrit la pièce', () {
    final dto = StaffDocumentDeltaDto.tryParse(staffDocumentJson('d-1'))!;

    expect(dto.sha256, 'ab' * 32);
    expect(dto.code, 'ID');
    expect(
      StaffDocumentDeltaDto.tryParse({
        ...staffDocumentJson('d-2'),
        'sha256': null,
      }),
      isNull,
    );
  });
}
