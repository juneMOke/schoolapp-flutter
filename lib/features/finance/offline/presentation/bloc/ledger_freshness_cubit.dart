import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_ledger_freshness_use_case.dart';

/// Fraîcheur du grand-livre local (epoch ms | `null` si jamais synchronisé),
/// affichée près des totaux (ADR-002). Rechargée après chaque lecture réussie
/// des créances (le rafraîchissement ciblé a alors déjà mis à jour `synced_at`).
class LedgerFreshnessCubit extends Cubit<int?> {
  final GetLedgerFreshnessUseCase _getFreshness;

  LedgerFreshnessCubit(this._getFreshness) : super(null);

  Future<void> load(String studentId) async {
    emit(await _getFreshness(studentId));
  }
}
