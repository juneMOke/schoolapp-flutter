import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';

enum RecoveryLoadStatus { initial, loading, success, failure }

/// Code de refus du serveur : « a payé au moins » sur un périmètre qui porte
/// deux devises.
const String recoveryAtLeastUnavailable = 'AT_LEAST_UNAVAILABLE';

class RecoveryDashboardState extends Equatable {
  final RecoveryQuestion? question;
  final RecoveryLoadStatus status;

  /// La dernière réponse — gardée pendant une relecture (I1 : « pas de
  /// squelette, la page reste en place »).
  final RecoveryDashboard? dashboard;
  final Failure? failure;

  const RecoveryDashboardState({
    this.question,
    this.status = RecoveryLoadStatus.initial,
    this.dashboard,
    this.failure,
  });

  /// Une relecture est en cours sur une page déjà remplie.
  bool get isRefreshing =>
      status == RecoveryLoadStatus.loading && dashboard != null;

  @override
  List<Object?> get props => [question, status, dashboard, failure];
}

/// Les chiffres du tableau de bord (blocs B à F) — **une seule lecture** du
/// serveur par question (R14). La liste nominative vit dans son propre cubit :
/// elle demande un droit de plus, et son refus ne doit pas éteindre les
/// chiffres.
class RecoveryDashboardCubit extends Cubit<RecoveryDashboardState> {
  final RecoveryDashboardRepository _repository;
  final CountPendingPaymentsUseCase _countPending;

  /// Numéro de la lecture en cours : une réponse plus ancienne qu'une question
  /// posée depuis est jetée.
  var _generation = 0;

  RecoveryDashboardCubit({
    required RecoveryDashboardRepository repository,
    required CountPendingPaymentsUseCase countPending,
  }) : _repository = repository,
       _countPending = countPending,
       super(const RecoveryDashboardState());

  /// La question de la dernière photo hors ligne, pour rouvrir la page sur ce
  /// que l'appareil sait montrer.
  Future<RecoveryQuestion?> lastCachedQuestion(String academicYearId) =>
      _repository.lastCachedQuestion(academicYearId);

  Future<void> ask(String academicYearId, RecoveryQuestion question) async {
    final generation = ++_generation;
    // Les chiffres d'une AUTRE question ne restent pas sous la nouvelle :
    // seule une relecture de la même question garde la page en place.
    final kept = state.question == question ? state.dashboard : null;
    emit(
      RecoveryDashboardState(
        question: question,
        status: RecoveryLoadStatus.loading,
        dashboard: kept,
      ),
    );
    final pending = (await _countPending()).fold((_) => 0, (n) => n);
    final result = await _repository.dashboard(
      academicYearId,
      question,
      pendingWrites: pending,
    );
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) {
        // R8 : francs et dollars dans le périmètre, « au moins » n'a pas de
        // sens — la règle revient à « a payé quelque chose ».
        if (_isAtLeastRefusal(failure) &&
            question.rule == RecoveryRuleKind.atLeast) {
          ask(
            academicYearId,
            question.copyWith(rule: RecoveryRuleKind.somePayment),
          );
          return;
        }
        // Un cycle ou une classe que l'année ne connaît plus (adresse ancienne,
        // autre école sur la tablette) : on retombe sur tout l'établissement.
        if (failure is NotFoundFailure &&
            question.scope != RecoveryScopeKind.school) {
          ask(
            academicYearId,
            question.copyWith(scope: RecoveryScopeKind.school, scopeId: null),
          );
          return;
        }
        emit(
          RecoveryDashboardState(
            question: question,
            status: RecoveryLoadStatus.failure,
            dashboard: kept,
            failure: failure,
          ),
        );
      },
      (dashboard) {
        // Le serveur juge la devise sur les créances du périmètre, pas sur les
        // frais cochés : une règle « au moins » qui passe en mixte retombe.
        if (!dashboard.atLeastAvailable &&
            question.rule == RecoveryRuleKind.atLeast) {
          ask(
            academicYearId,
            question.copyWith(rule: RecoveryRuleKind.somePayment),
          );
          return;
        }
        emit(
          RecoveryDashboardState(
            question: question,
            status: RecoveryLoadStatus.success,
            dashboard: dashboard,
          ),
        );
      },
    );
  }

  static bool _isAtLeastRefusal(Failure failure) =>
      failure is ApiValidationFailure &&
      failure.detailCode == recoveryAtLeastUnavailable;
}
