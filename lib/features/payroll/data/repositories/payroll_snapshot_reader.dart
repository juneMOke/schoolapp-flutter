import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_local.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';

/// Lit toute la paie d'une école en une fois, modèles convertis en entités
/// ici et nulle part ailleurs (règle n°3).
///
/// Les agents viennent du fichier du personnel ([StaffRepository]) ; les
/// contrats **avec montants** de leur table, sous `hr.pay.read`.
class PayrollSnapshotReader {
  final StaffRepository _staff;
  final StaffContractDao _contracts;
  final PayrollLocal _local;

  const PayrollSnapshotReader({
    required StaffRepository staff,
    required StaffContractDao contracts,
    required PayrollLocal local,
  }) : _staff = staff,
       _contracts = contracts,
       _local = local;

  Future<Either<Failure, PayrollSnapshot>> read(String schoolId) async =>
      (await _staff.loadFile()).fold<Future<Either<Failure, PayrollSnapshot>>>(
        (failure) async => Left(failure),
        (file) async {
          try {
            final contracts = <String, List<StaffContract>>{};
            for (final row in await _contracts.forSchool(schoolId)) {
              final contract = row.toEntity();
              (contracts[contract.staffMemberId] ??= []).add(contract);
            }
            final byId = {
              for (final list in contracts.values)
                for (final contract in list) contract.id: contract,
            };
            final frozen = await _local.payrolls.frozenLines(schoolId);
            return Right(
              PayrollSnapshot(
                members: file.members,
                contractsByMember: contracts,
                settings: await _local.settings.read(schoolId),
                profiles: await _local.profiles.forSchool(schoolId),
                headers: await _local.payrolls.headers(schoolId),
                variables: await _local.variables.forSchool(schoolId),
                frozenLines: {
                  for (final entry in frozen.entries)
                    entry.key: [
                      for (final line in entry.value) _withContract(line, byId),
                    ],
                },
                summaries: await _local.summaries.forSchool(schoolId),
                gestures: await _local.gestures.forSchool(schoolId),
                advances: await _local.advances.forSchool(schoolId),
                disbursements: await _local.disbursements.forSchool(schoolId),
                schoolYears: await _local.calendar.schoolYears(schoolId),
                shareTraces: await _local.shares.forSchool(schoolId),
                hasEverSynced: file.hasEverSynced,
              ),
            );
          } catch (e) {
            return Left(StorageFailure('Lecture de la paie : $e'));
          }
        },
      );

  /// Le serveur ne redit pas le début du contrat retenu : la tablette le lit
  /// dans ses contrats, pour « contrat du 15/09 ».
  static PayrollLine _withContract(
    PayrollLine line,
    Map<String, StaffContract> byId,
  ) {
    final contract = byId[line.contractId];
    if (contract == null) return line;
    return line.withContract(
      kind: contract.kind,
      payMode: contract.payMode,
      from: contract.effectiveFrom,
    );
  }
}
