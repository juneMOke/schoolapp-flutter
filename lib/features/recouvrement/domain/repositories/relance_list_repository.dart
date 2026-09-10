import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_list.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

abstract class RelanceListRepository {
  /// Émet la liste nominative d'un périmètre. **Les lignes viennent de
  /// l'appareil** : lui seul voit les encaissements non encore remontés.
  Future<Either<Failure, RelanceList>> emit({
    required RelanceScope scope,
    required List<String> feeCodes,
    required RecouvrementCriterion criterion,
    required List<LocalRecoveryLine> lines,
    required DateTime arretedAt,
    int? thresholdInCents,
    String? thresholdCurrency,
    int? pendingWrites,
  });
}
