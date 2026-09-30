import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';

import '../staff_builders.dart';

void main() {
  group('StaffContractTimeline', () {
    final frise = [
      period(StaffContractKind.vacataire, from: '2025-09-01', id: 'c-1'),
      period(StaffContractKind.permanent, from: '2026-11-01', id: 'c-2'),
    ];

    test('la période en vigueur est la plus récente déjà commencée', () {
      expect(
        StaffContractTimeline.currentAt(frise, '2026-10-31')?.contractId,
        'c-1',
      );
      expect(
        StaffContractTimeline.currentAt(frise, '2026-11-01')?.contractId,
        'c-2',
      );
    });

    test('rien avant la première date d effet, rien sans contrat', () {
      expect(StaffContractTimeline.currentAt(frise, '2025-08-31'), isNull);
      expect(StaffContractTimeline.currentAt(const [], '2026-01-01'), isNull);
    });

    test('une période terminée sans successeur ne vaut plus', () {
      final cdd = [period(StaffContractKind.vacataire, endsOn: '2026-06-30')];

      expect(StaffContractTimeline.currentAt(cdd, '2026-06-30'), isNotNull);
      expect(StaffContractTimeline.currentAt(cdd, '2026-07-01'), isNull);
    });
  });

  group('StaffDossier', () {
    test('un permanent doit identité, diplôme et désignation', () {
      final dossier = StaffDossier.of(
        kind: StaffContractKind.permanent,
        types: documentTypes,
        documents: [document('m', 'ID'), document('m', 'CP')],
      );

      expect(dossier.required.map((t) => t.rawCode), ['ID', 'DP', 'LD']);
      expect(dossier.done, 1);
      expect(dossier.isComplete, isFalse);
    });

    test('sans contrat, seules les pièces communes sont exigées', () {
      final dossier = StaffDossier.of(
        kind: null,
        types: documentTypes,
        documents: [document('m', 'ID'), document('m', 'DP')],
      );

      expect(dossier.total, 2);
      expect(dossier.isComplete, isTrue);
    });

    test('sans référentiel, le dossier n est ni complet ni incomplet', () {
      final dossier = StaffDossier.of(
        kind: StaffContractKind.permanent,
        types: const [],
        documents: const [],
      );

      expect(dossier.isKnown, isFalse);
      expect(dossier.isComplete, isFalse);
    });
  });

  group('StaffFileView et StaffFileQuery', () {
    final snapshot = StaffFileSnapshot(
      members: [
        member(
          'm-1',
          lastName: 'Kalala',
          firstName: 'Jean',
          contracts: [period(StaffContractKind.permanent)],
          branches: ['Mathématiques'],
        ),
        member(
          'm-2',
          lastName: 'Mbuyi',
          firstName: 'Élodie',
          contracts: [period(StaffContractKind.vacataire)],
          syncState: StaffSyncState.pending,
          staffNumber: null,
        ),
        member(
          'm-3',
          lastName: 'Nsimba',
          firstName: 'Béatrice',
          category: StaffCategory.administrative,
          jobTitle: 'Censeur',
        ),
      ],
      documentsByMember: {
        'm-1': [
          document('m-1', 'ID'),
          document('m-1', 'DP'),
          document('m-1', 'LD'),
        ],
        'm-2': [document('m-2', 'ID', syncState: StaffSyncState.failed)],
      },
      documentTypes: documentTypes,
      hasEverSynced: true,
    );

    StaffFileView view([
      StaffFileQuery query = StaffFileQuery.none,
      bool docs = true,
    ]) => StaffFileView.build(
      snapshot,
      query: query,
      today: '2026-09-29',
      documentsVisible: docs,
    );

    test('compte les contrats, les dossiers incomplets et l attente', () {
      final v = view();

      expect(v.byContract[StaffContractFilter.permanent], 1);
      expect(v.byContract[StaffContractFilter.vacataire], 1);
      expect(v.byContract[StaffContractFilter.none], 1);
      expect(v.incomplete, 2);
      // La fiche de m-2 et sa pièce refusée.
      expect(v.pending, 2);
      expect(v.all[1].sync, StaffSyncState.failed);
    });

    test('la recherche plie accents et casse, sur tous les champs', () {
      expect(
        view(const StaffFileQuery(text: 'elodie')).rows.single.member.id,
        'm-2',
      );
      expect(
        view(const StaffFileQuery(text: 'MATHEMATIQUES')).rows.single.member.id,
        'm-1',
      );
      expect(view(const StaffFileQuery(text: 'cf-ag-0001')).rows, hasLength(2));
      expect(
        view(
          const StaffFileQuery(text: 'nsimba censeur'),
        ).rows.single.member.id,
        'm-3',
      );
    });

    test('les filtres se combinent en ET', () {
      final query = StaffFileQuery.none
          .withCategory(StaffCategory.teacher)
          .toggleIncomplete();

      expect(view(query).rows.map((r) => r.member.id), ['m-2']);
      expect(
        view(
          query.toggleContract(StaffContractFilter.permanent),
        ).isFilteredEmpty,
        isTrue,
      );
    });

    test('un second tap sur le filtre de contrat actif le retire', () {
      final once = StaffFileQuery.none.toggleContract(StaffContractFilter.none);

      expect(view(once).rows.single.member.id, 'm-3');
      expect(once.toggleContract(StaffContractFilter.none).contract, isNull);
    });

    test('sans le droit de voir les pièces, aucun dossier n est mesuré', () {
      final v = view(StaffFileQuery.none, false);

      expect(v.incomplete, 0);
      expect(v.all.every((row) => row.dossier == null), isTrue);
    });
  });
}
