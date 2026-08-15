import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_data_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/fee_control_results_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Adapte l'état de [FeeControlBloc] vers le bon widget de résultats.
///
/// Responsabilité unique : router vers invitation / erreur / vide / tableau —
/// le rendu est délégué. Même anatomie que `FacturationStudentTable`, y compris
/// les composants d'états partagés.
class FeeControlResultsView extends StatelessWidget {
  final ValueChanged<FeeControlRow> onViewRequested;

  const FeeControlResultsView({super.key, required this.onViewRequested});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FeeControlBloc, FeeControlState>(
      buildWhen: _shouldBuild,
      builder: (context, state) {
        // Relu à CHAQUE reconstruction des résultats, jamais capturé dans la
        // closure : `permissionHolding` ne s'abonne pas, et lu une seule fois
        // dans le `build` extérieur le verdict resterait figé pour toute la vie
        // de l'écran — un droit élargi en séance ne changerait plus la phrase.
        //
        // Ce module s'ouvre sur `finance.*`, mais sa seule source de lignes est
        // le flux Inscription : un compte sans `enrollment.read` n'aura jamais
        // d'élève à croiser, quels que soient les critères.
        final enrollment = permissionHolding(context, const [
          Perm.enrollmentRead,
        ]);
        final classroom = permissionHolding(context, const [
          Perm.classroomRead,
        ]);

        if (!state.hasSearched) {
          return const FeeControlSearchInvitationCard();
        }

        final isLoading = state.status == EnrollmentLoadStatus.loading;
        final isError = state.status == EnrollmentLoadStatus.failure;
        final isEmpty =
            state.status == EnrollmentLoadStatus.success && state.rows.isEmpty;

        if (isError) {
          return AnimatedSwitcher(
            duration: AppMotion.layout,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            child: EnrollmentResultsErrorState(
              key: const ValueKey('fee-control-results-error'),
              type: state.errorType ?? EnrollmentErrorType.unknown,
              message: state.errorMessage,
              onRetry: () => context.read<FeeControlBloc>().add(
                const FeeControlRefreshRequested(),
              ),
              onReconnect: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          );
        }

        if (isEmpty) {
          return AnimatedSwitcher(
            duration: AppMotion.layout,
            switchInCurve: AppMotion.outCurve,
            switchOutCurve: AppMotion.inCurve,
            // Pas de bouton « Effacer » ici : il ne remettrait à zéro que les
            // résultats, pas les champs du formulaire (widget voisin), et
            // laisserait l'écran dans un état contradictoire. La remise à zéro
            // se fait depuis le formulaire, qui la porte déjà.
            child: FeeControlResultsEmptyState(
              key: const ValueKey('fee-control-results-empty'),
              description: _emptyDescription(
                state,
                l10n,
                enrollment: enrollment,
                classroom: classroom,
              ),
              criteria: _buildCriteria(state, l10n),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: FeeControlDataTable(
            key: ValueKey(state.status),
            rows: state.rows,
            totalCount: state.totalElements,
            isLoading: isLoading,
            isError: isError,
            loadingLabel: l10n.loadingStudents,
            errorLabel: state.errorMessage,
            // Même cause, même phrase : sans ce relais le tableau continuerait
            // d'annoncer « aucun élève ne correspond » là où la carte de vide
            // dit désormais la vérité.
            emptyLabel: _emptyDescription(
              state,
              l10n,
              enrollment: enrollment,
              classroom: classroom,
            ),
            showPagination: true,
            currentPage: state.page + 1,
            totalPages: state.totalPages,
            pageSize: state.size,
            onPreviousPage: () => context.read<FeeControlBloc>().add(
              FeeControlPageRequested(state.page - 1),
            ),
            onNextPage: () => context.read<FeeControlBloc>().add(
              FeeControlPageRequested(state.page + 1),
            ),
            pageLabelBuilder: (current, total) =>
                l10n.paginationPageIndicator(current, total),
            onViewRequested: onViewRequested,
          ),
        );
      },
    );
  }

  /// Une liste vide a plusieurs causes qui appellent des gestes différents. Les
  /// confondre envoie chercher une erreur de saisie là où il manque une
  /// synchronisation — ou l'inverse.
  ///
  /// **Le droit manquant passe en tête** (ADR-015 F1). Les deux messages de
  /// synchronisation ci-dessous promettent une mise à jour qui n'arrivera
  /// jamais : le flux qui remplirait ces tables est sauté à chaque cycle faute
  /// de permission. Placés avant, ils enverraient le caissier attendre
  /// indéfiniment un pull qui a déjà eu lieu et qui l'a délibérément sauté.
  static String _emptyDescription(
    FeeControlState state,
    AppLocalizations l10n, {
    required PermissionHolding enrollment,
    required PermissionHolding classroom,
  }) {
    if (enrollment == PermissionHolding.missing) {
      return l10n.feeControlEmptyEnrollmentWithheld;
    }
    if (state.lastQuery?.classroomId != null &&
        classroom == PermissionHolding.missing) {
      return l10n.feeControlEmptyClassroomWithheld;
    }
    if (state.lastQuery?.classroomId != null) {
      // Le roster de cette classe n'est pas descendu sur l'appareil : rien à
      // croiser, quels que soient les critères.
      if (state.classroomRosterSize == 0) {
        return l10n.feeControlEmptyRosterMissing;
      }
      // Roster connu, mais aucun de ses élèves n'a de dossier d'inscription
      // local sur l'année — décalage d'identifiants ou pull Inscription partiel.
      if (state.studentsInScope == 0) {
        return l10n.feeControlEmptyNoLocalEnrollment;
      }
    }
    // Des élèves, mais aucun ne porte ce frais : la grille ne l'a pas généré.
    if (state.studentsInScope > 0 && state.breakdown.isEmpty) {
      return l10n.feeControlNoChargeDescription;
    }
    return l10n.feeControlNoResultsDescription;
  }

  /// Puces rappelant ce qui a été demandé — le frais et le statut d'abord :
  /// ce sont eux qui expliquent une liste vide.
  static List<String> _buildCriteria(
    FeeControlState state,
    AppLocalizations l10n,
  ) {
    final query = state.lastQuery;
    if (query == null) return const <String>[];

    final chips = <String>[];
    if (query.feeCode.trim().isNotEmpty) {
      // Libellé localisé du code de frais — le même que la ligne de frais du
      // détail Facturation.
      chips.add(
        l10n.feeControlCriteriaFee(query.feeCode.localizedFeeLabel(l10n)),
      );
    }
    // Nom de la classe plutôt que son id — l'id ne dit rien à personne. Le
    // repli sur « toutes les classes » n'est pas affiché : c'est le défaut.
    final classroomId = query.classroomId;
    if (classroomId != null) {
      final name = state.classrooms
          .where((c) => c.id == classroomId)
          .map((c) => c.name)
          .firstOrNull;
      if (name != null) chips.add(l10n.feeControlCriteriaClassroom(name));
    }
    if (query.statusFilter != FeeControlPaymentFilter.all) {
      chips.add(
        l10n.feeControlCriteriaStatus(
          FeeControlPageHelpers.paymentFilterLabel(query.statusFilter, l10n),
        ),
      );
    }

    void addIfNotEmpty(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) chips.add('$label: $trimmed');
    }

    addIfNotEmpty(l10n.lastName, query.lastName);
    addIfNotEmpty(l10n.surname, query.surname);
    addIfNotEmpty(l10n.firstName, query.firstName);
    return chips;
  }

  static bool _shouldBuild(FeeControlState prev, FeeControlState curr) =>
      prev.status != curr.status ||
      prev.rows != curr.rows ||
      prev.totalElements != curr.totalElements ||
      prev.totalPages != curr.totalPages ||
      prev.page != curr.page ||
      prev.studentsInScope != curr.studentsInScope ||
      prev.breakdown != curr.breakdown ||
      prev.classroomRosterSize != curr.classroomRosterSize ||
      prev.errorType != curr.errorType ||
      prev.errorMessage != curr.errorMessage ||
      prev.lastQuery != curr.lastQuery;
}
