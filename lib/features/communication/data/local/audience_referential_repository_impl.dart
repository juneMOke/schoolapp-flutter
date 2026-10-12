import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/audience_referential_repository.dart';
import 'package:school_app_flutter/features/finance/domain/fee_tariff_code.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Les classes du module Classes et la grille de Finance, relues pour cibler.
class AudienceReferentialRepositoryImpl
    implements AudienceReferentialRepository {
  final ClassroomOfflineRepository _classrooms;
  final FinanceOfflineRepository _finance;

  const AudienceReferentialRepositoryImpl({
    required ClassroomOfflineRepository classrooms,
    required FinanceOfflineRepository finance,
  }) : _classrooms = classrooms,
       _finance = finance;

  @override
  Future<Either<Failure, AudienceReferential>> load(
    String academicYearId,
  ) async {
    final classrooms = await _classrooms.getClassrooms(
      academicYearId: academicYearId,
    );
    final tariffs = await _finance.getFeeTariffsForYear(academicYearId);
    return classrooms.fold(
      Left.new,
      (rooms) => tariffs.fold(
        Left.new,
        (grid) => Right(
          AudienceReferential(
            classrooms: [
              for (final room in rooms)
                AudienceClassroom(
                  id: room.id,
                  name: room.name,
                  levelId: room.schoolLevelId,
                ),
            ]..sort((a, b) => a.name.compareTo(b.name)),
            fees: natures(grid),
          ),
        ),
      ),
    );
  }

  /// Une entrée par nature, dans l'ordre de la grille ; ses tranches sont les
  /// codes **qui distinguent quelque chose** (`T1`, pas un code égal à la
  /// nature), chacune une fois, tous niveaux confondus.
  static List<OverdueFeeNature> natures(List<LocalFeeTariff> grid) {
    final byNature = <String, List<LocalFeeTariff>>{};
    for (final tariff in grid) {
      (byNature[tariff.feeCode] ??= []).add(tariff);
    }
    return [
      for (final MapEntry(key: feeCode, value: lines) in byNature.entries)
        OverdueFeeNature(
          feeCode: feeCode,
          singleLabel: lines.length == 1 ? lines.single.label : null,
          tranches: _tranches(feeCode, lines),
        ),
    ];
  }

  static List<OverdueFeeTranche> _tranches(
    String feeCode,
    List<LocalFeeTariff> lines,
  ) {
    final seen = <String, OverdueFeeTranche>{};
    for (final line in lines) {
      final code = meaningfulTariffCode(code: line.code, feeCode: feeCode);
      if (code == null) continue;
      seen.putIfAbsent(
        code,
        () => OverdueFeeTranche(code: code, label: line.label),
      );
    }
    // Une seule tranche ne se choisit pas : c'est la nature entière.
    return seen.length < 2 ? const [] : seen.values.toList(growable: false);
  }
}
