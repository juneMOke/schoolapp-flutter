import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_list.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/relance_list_repository.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

/// Émet la liste nominative d'un périmètre — **la seule sortie matérielle du
/// module**, et son seul appel réseau.
class EmitRelanceListUseCase {
  final RelanceListRepository _repository;

  const EmitRelanceListUseCase(this._repository);

  Future<Either<Failure, RelanceList>> call({
    required RelanceScope scope,
    required List<String> feeCodes,
    required RecouvrementCriterion criterion,
    required List<LocalRecoveryLine> lines,
    required DateTime arretedAt,
    int? thresholdInCents,
    String? thresholdCurrency,
    int? pendingWrites,
  }) => _repository.emit(
    scope: scope,
    feeCodes: feeCodes,
    criterion: criterion,
    lines: lines,
    arretedAt: arretedAt,
    thresholdInCents: thresholdInCents,
    thresholdCurrency: thresholdCurrency,
    pendingWrites: pendingWrites,
  );
}
