import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_tariffs_for_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/has_fee_grid_use_case.dart';

/// Ce que l'écran sait de la grille d'un niveau après lecture.
class FeeControlTariffsOutcome {
  final bool failed;
  final List<LocalFeeTariff> tariffs;

  /// Grille absente **de l'appareil** (à synchroniser), par opposition à un
  /// niveau qui n'a simplement pas de frais.
  final bool gridMissing;

  const FeeControlTariffsOutcome({
    required this.failed,
    required this.tariffs,
    required this.gridMissing,
  });
}

/// Lit la grille d'un niveau **et qualifie une grille vide**.
///
/// Deux causes produisent la même liste vide et appellent des gestes opposés :
///  - le référentiel n'a pas été hydraté ici (le serveur caviarde `feeTariffs`
///    pour qui n'a pas `finance.grid.read`) → il faut synchroniser ;
///  - le référentiel est là, mais ce niveau n'a pas de frais → information.
///
/// La règle vit dans cette classe, à côté de la sonde qui la tranche, plutôt que
/// dispersée dans un gestionnaire d'événement.
class FeeControlTariffsResolver {
  final GetFeeTariffsForLevelUseCase _getTariffs;
  final HasFeeGridUseCase _hasFeeGrid;

  const FeeControlTariffsResolver({
    required GetFeeTariffsForLevelUseCase getTariffs,
    required HasFeeGridUseCase hasFeeGrid,
  }) : _getTariffs = getTariffs,
       _hasFeeGrid = hasFeeGrid;

  Future<FeeControlTariffsOutcome> resolve({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    final result = await _getTariffs(
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    );

    return result.fold(
      (_) async => const FeeControlTariffsOutcome(
        failed: true,
        tariffs: <LocalFeeTariff>[],
        gridMissing: false,
      ),
      (tariffs) async {
        if (tariffs.isNotEmpty) {
          return FeeControlTariffsOutcome(
            failed: false,
            tariffs: tariffs,
            gridMissing: false,
          );
        }
        // Fail-closed : une sonde illisible annonce « grille absente » plutôt
        // que « ce niveau n'a pas de frais » — mieux vaut envoyer synchroniser
        // que laisser croire qu'il n'y a rien à contrôler.
        final probe = await _hasFeeGrid(academicYearId);
        return FeeControlTariffsOutcome(
          failed: false,
          tariffs: const <LocalFeeTariff>[],
          gridMissing: probe.fold((_) => true, (has) => !has),
        );
      },
    );
  }
}
