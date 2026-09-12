import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_empty_reason.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_query_phrase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_results_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_search_invitation_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/states/fee_control_results_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Adapte l'état de [FeeControlBloc] vers le bon widget de résultats.
///
/// Responsabilité unique : router vers invitation / erreur / vide / section de
/// résultat — le rendu est délégué. Même anatomie que `FacturationStudentTable`,
/// y compris les composants d'états partagés.
class FeeControlResultsView extends StatelessWidget {
  final ValueChanged<FeeControlRow> onViewRequested;
  final ValueChanged<FeeControlRow> onRowTapped;

  /// Mène à la Facturation. Si personne n'a payé, l'issue utile est
  /// d'encaisser, pas de re-chercher.
  final VoidCallback? onBilling;

  /// Les titres que l'école donne aux natures : la requête rejouée nomme les
  /// frais comme les pastilles qui les ont retenus.
  final FeeSectionTitlesState titles;

  const FeeControlResultsView({
    super.key,
    required this.onViewRequested,
    required this.onRowTapped,
    this.onBilling,
    this.titles = const FeeSectionTitlesState(),
  });

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

        final isEmpty =
            state.status == EnrollmentLoadStatus.success && state.rows.isEmpty;

        if (state.status == EnrollmentLoadStatus.failure) {
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
            // résultats, pas la carte de périmètre (widget voisin), et
            // laisserait l'écran dans un état contradictoire. La remise à zéro
            // se fait depuis la carte, qui la porte déjà.
            child: FeeControlResultsEmptyState(
              key: const ValueKey('fee-control-results-empty'),
              onWiden:
                  state.lastQuery?.statusFilter == FeeControlPaymentFilter.all
                  ? null
                  : () => context.read<FeeControlBloc>().add(
                      const FeeControlSituationRequested(
                        FeeControlPaymentFilter.all,
                      ),
                    ),
              onBilling: onBilling,
              description: feeControlEmptyReason(
                state,
                l10n,
                enrollment: enrollment,
                classroom: classroom,
              ),
              criteria: FeeControlQueryPhrase.chips(
                state,
                l10n,
                titles: titles,
              ),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: FeeControlResultsSection(
            key: ValueKey(state.status),
            state: state,
            titles: titles,
            // Même cause, même phrase : sans ce relais le tableau continuerait
            // d'annoncer « aucun élève ne correspond » là où la carte de vide
            // dit désormais la vérité.
            emptyLabel: feeControlEmptyReason(
              state,
              l10n,
              enrollment: enrollment,
              classroom: classroom,
            ),
            onViewRequested: onViewRequested,
            onRowTapped: onRowTapped,
          ),
        );
      },
    );
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
