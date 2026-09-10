import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_list_item.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_call_list_cubit.dart';

class _MockSearch extends Mock implements SearchLocalEnrollmentsUseCase {}

LocalRecoveryLine line(String studentId, {int paid = 0}) => LocalRecoveryLine(
  schoolLevelId: 'lvl-1',
  studentId: studentId,
  charges: [
    RecoveryChargePosition(
      feeCode: 'TUITION',
      position: FeeChargePosition(
        currency: 'USD',
        expectedInCents: 30000,
        paidMirrorInCents: paid,
        paidPendingInCents: 0,
      ),
    ),
  ],
);

LocalEnrollmentListItem enrolled(
  String studentId, {
  required String lastName,
  required String firstName,
}) => LocalEnrollmentListItem(
  enrollmentId: 'e-$studentId',
  studentId: studentId,
  firstName: firstName,
  lastName: lastName,
  dateOfBirth: '2010-01-01',
  gender: OfflineGender.male,
  enrollmentType: EnrollmentType.newEnrollment,
  status: OfflineEnrollmentStatus.completed,
  enrollmentDate: '2026-09-01',
  syncState: SyncState.synced,
);

void main() {
  late _MockSearch search;

  setUp(() => search = _MockSearch());

  RecouvrementCallListCubit build() =>
      RecouvrementCallListCubit(searchEnrollments: search);

  void stub(List<LocalEnrollmentListItem> items) {
    when(
      () => search.currentYearEnrolled(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelId: any(named: 'schoolLevelId'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
      ),
    ).thenAnswer((_) async => Right(items));
  }

  Future<RecouvrementCallListCubit> run(
    List<LocalRecoveryLine> targeted,
  ) async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(
      academicYearId: 'ay-1',
      schoolLevelId: 'lvl-1',
      targeted: targeted,
    );
    return cubit;
  }

  group('les noms', () {
    test('viennent des inscriptions, croisés par identifiant', () async {
      stub([enrolled('s1', lastName: 'MBUYI', firstName: 'Jean')]);

      final cubit = await run([line('s1')]);

      expect(cubit.state.rows.single.displayName, 'MBUYI Jean');
    });

    test(
      'un élève PARTI garde sa ligne, sans nom — sa dette ne s\'efface pas',
      () async {
        // Le tableau de bord découvre sa population dans le GRAND-LIVRE ;
        // l'écran nominatif croise les INSCRIPTIONS. Un élève qui a quitté
        // l'école en gardant une dette est ici et pas là-bas.
        stub([enrolled('s1', lastName: 'MBUYI', firstName: 'Jean')]);

        final cubit = await run([line('s1'), line('parti')]);

        expect(cubit.state.rows, hasLength(2));
        final gone = cubit.state.rows.firstWhere((r) => r.studentId == 'parti');
        expect(
          gone.displayName,
          isNull,
          reason: 'le rendu écrira son identifiant plutôt que de le retirer',
        );
      },
    );

    test(
      'un ÉCHEC de nommage ne fait pas échouer l\'aperçu : les montants restent',
      () async {
        when(
          () => search.currentYearEnrolled(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('boum')));

        final cubit = await run([line('s1', paid: 12000)]);

        expect(cubit.state.status, EnrollmentLoadStatus.success);
        expect(cubit.state.rows.single.displayName, isNull);
        expect(
          cubit.state.rows.single.remaining.amountIn('USD')!.amountInCents,
          18000,
          reason:
              'perdre une information exacte pour une information '
              'd\'appoint serait un mauvais échange',
        );
      },
    );
  });

  group('l\'ordre', () {
    test('alphabétique — c\'est une liste qu\'on appelle', () async {
      stub([
        enrolled('s1', lastName: 'ZOLA', firstName: 'Ana'),
        enrolled('s2', lastName: 'ABEL', firstName: 'Boris'),
      ]);

      final cubit = await run([line('s1'), line('s2')]);

      expect(cubit.state.rows.map((r) => r.displayName), [
        'ABEL Boris',
        'ZOLA Ana',
      ]);
    });

    test('les sans-nom ferment la marche', () async {
      stub([enrolled('s2', lastName: 'ZOLA', firstName: 'Ana')]);

      final cubit = await run([line('inconnu'), line('s2')]);

      expect(cubit.state.rows.first.displayName, 'ZOLA Ana');
      expect(
        cubit.state.rows.last.displayName,
        isNull,
        reason:
            'les intercaler sous un identifiant opaque casserait l\'ordre '
            'alphabétique qu\'on vient chercher',
      );
    });
  });

  group('les montants', () {
    test('viennent du registre, jamais relus', () async {
      stub([]);

      final cubit = await run([line('s1', paid: 12000)]);

      final row = cubit.state.rows.single;
      expect(row.expected.amountIn('USD')!.amountInCents, 30000);
      expect(row.paid.amountIn('USD')!.amountInCents, 12000);
      expect(row.remaining.amountIn('USD')!.amountInCents, 18000);
    });
  });
}
