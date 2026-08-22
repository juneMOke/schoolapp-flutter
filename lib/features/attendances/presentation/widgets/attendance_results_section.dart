import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_records_mobile_list.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_results_toolbar.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_save_overlay.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_empty_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_focus_mode.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// Mode de saisie de l'appel.
enum AttendanceEntryMode { list, focus }

class AttendanceResultsSection extends StatefulWidget {
  final AttendanceSearchRequest? lastRequest;
  final VoidCallback onRetry;

  const AttendanceResultsSection({
    super.key,
    required this.lastRequest,
    required this.onRetry,
  });

  @override
  State<AttendanceResultsSection> createState() =>
      _AttendanceResultsSectionState();
}

class _AttendanceResultsSectionState extends State<AttendanceResultsSection> {
  /// Le mode vit ici, hors du BLoC : c'est une préférence d'affichage, pas un
  /// état métier. Rien de ce qu'il change ne doit partir à la synchro.
  AttendanceEntryMode _mode = AttendanceEntryMode.list;

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = widget.lastRequest;

    if (request == null) {
      return EteeloEmptyResult(
        medallionIcon: Icons.calendar_today_outlined,
        label: l10n.attendanceSelectClassTitle,
        description: l10n.attendanceEmptySelectionMessage,
        fullWidthCard: true,
        minHeight: 260,
        cardPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingXL,
        ),
      );
    }

    return BlocBuilder<AttendanceBloc, AttendanceState>(
      buildWhen: AttendancePageHelpers.buildWhenResultsChanges,
      builder: (context, state) {
        late final Widget child;

        if (state.fetchStatus == AttendanceStatus.loading) {
          // Squelette partage : conserve les lignes d'appel + reduced-motion.
          child = EteeloListSkeleton(
            rowCount: 8,
            semanticsLabel: l10n.attendanceLoadingMessage,
          );
        } else if (state.fetchStatus == AttendanceStatus.failure) {
          // Anatomie d'erreur partagee (4 types) ; le 403 reste dormant.
          child = AttendanceResultsErrorState(
            type: state.fetchErrorType,
            onRetry: widget.onRetry,
            onReconnect: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            onContactAdmin: _contactAdmin,
          );
        } else if (state.fetchStatus != AttendanceStatus.success ||
            state.draftRows.isEmpty) {
          // Etat vide partage : medaillon pointille + renvoi vers Composition.
          child = AttendanceResultsEmptyState(
            onOpenComposition: () => context.read<NavigationBloc>().add(
              SubMenuItemSelected(
                menuId: MenuConstants.classesMenuId,
                subMenuId: MenuConstants.organisationId,
                title: l10n.classesOrganisationHeroTitle,
              ),
            ),
          );
        } else {
          final totalCount = state.draftRows.length;
          final absentCount = state.draftRows
              .where((row) => !row.present)
              .length;
          final presentCount = totalCount - absentCount;
          // ⚠️ Les deux compteurs écartent explicitement le motif absent, alors
          // qu'`isUnjustifiedAbsence(null)` vaut `true` partout ailleurs. Ce
          // n'est pas une divergence : cet écran INTERDIT d'enregistrer tant
          // qu'un motif manque (`canSave && missingReasonsCount == 0`), donc
          // « sans motif » y est un état de saisie en cours — compté à part,
          // dans `missingReasonsCount` — et jamais un verdict rendu. Le verdict
          // ne s'applique qu'aux absences déjà écrites.
          final justifiedCount = state.draftRows
              .where(
                (r) =>
                    !r.present &&
                    r.absenceReason != null &&
                    !isUnjustifiedAbsence(r.absenceReason),
              )
              .length;
          final unjustifiedCount = state.draftRows
              .where(
                (r) =>
                    !r.present &&
                    r.absenceReason != null &&
                    isUnjustifiedAbsence(r.absenceReason),
              )
              .length;
          final missingReasonsCount = state.draftRows
              .where((row) => !row.present && row.absenceReason == null)
              .length;
          // Une ligne dont le motif vient d'un catalogue serveur plus récent
          // que cette version. L'enregistrement renvoie TOUTES les lignes du
          // brouillon, chacune re-sérialisée : laisser passer celle-ci
          // remplacerait le motif d'origine sans que personne le voie. On
          // bloque jusqu'à ce qu'un motif connu soit choisi — et
          // `toApiValue()` lève si on l'atteignait quand même.
          final unsupportedReasonsCount = state.draftRows
              .where(
                (row) =>
                    !row.present &&
                    row.absenceReason == AbsenceReason.unsupported,
              )
              .length;
          // Le Focus n'itère que sur les ABSENTS : c'est le cadrage du lot.
          final rowsToFocus = state.draftRows
              .where((row) => !row.present)
              .toList(growable: false);
          // ⚠️ Le mode peut rester `focus` alors qu'il n'y a plus rien à
          // montrer — le dernier motif vient d'être posé, ou tout le monde est
          // repassé présent. On retombe alors sur la liste plutôt que de rendre
          // une carte vide : la bascule elle-même a déjà disparu.
          final focusUsable =
              _mode == AttendanceEntryMode.focus && rowsToFocus.isNotEmpty;

          final panelHeight = (MediaQuery.sizeOf(context).height * 0.62)
              .clamp(
                AppDimensions.attendanceResultsPanelMinHeight,
                AppDimensions.attendanceResultsPanelMaxHeight,
              )
              .toDouble();

          Future<void> onSaveCallPressed() async {
            if (!state.canSave ||
                missingReasonsCount > 0 ||
                unsupportedReasonsCount > 0) {
              return;
            }

            if (absentCount == 0) {
              final confirmed = await showAppConfirmationDialog(
                context: context,
                title: l10n.attendanceAllPresentConfirmTitle,
                message: l10n.attendanceAllPresentConfirmMessage(totalCount),
                confirmLabel: l10n.confirm,
                cancelLabel: l10n.cancel,
              );
              if (!context.mounted || !confirmed) return;
            }

            if (!context.mounted) return;
            await showAttendanceSaveOverlay(
              context: context,
              attendanceBloc: context.read<AttendanceBloc>(),
              offlineBloc: context.read<AttendanceOfflineBloc>(),
              classroomName: request.selectedClassroom.name,
              date: request.date,
              presentCount: presentCount,
              justifiedCount: justifiedCount,
              unjustifiedCount: unjustifiedCount,
            );
          }

          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3e état (invariant #1) : pas de session ⇒ appel non fait. On le
              // signale explicitement (le roster affiché n'est PAS un appel validé).
              if (!state.callTaken) ...[
                const _AppelNonFaitBar(),
                const SizedBox(height: AppDimensions.spacingS),
              ],
              // Le Focus ne se propose QUE s'il reste des motifs à renseigner.
              // Ailleurs il serait plus lent que la liste : le flux dominant
              // est « tout le monde est là sauf trois », déjà servi par
              // « Marquer tous présents ». Un Focus sur l'effectif entier
              // imposerait quarante passages pour trois absences.
              if (missingReasonsCount > 0) ...[
                _EntryModeBar(
                  mode: _mode,
                  pending: missingReasonsCount,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: AppDimensions.spacingS),
              ],
              if (unsupportedReasonsCount > 0) ...[
                _UnsupportedReasonBar(count: unsupportedReasonsCount),
                const SizedBox(height: AppDimensions.spacingS),
              ],
              _AttendanceActionBar(
                isSaving: state.saveStatus == AttendanceStatus.loading,
                canSave:
                    state.canSave &&
                    missingReasonsCount == 0 &&
                    unsupportedReasonsCount == 0,
                // Corriger un appel DÉJÀ enregistré, un jour RÉVOLU, est un
                // geste d'arbitrage. Prendre l'appel en retard — aucune session
                // pour ce jour — reste celui de qui constate, comme rectifier
                // l'appel du jour même.
                isPastCorrection:
                    state.callTaken && _isBeforeToday(request.date),
                onMarkAllPresent: () => context.read<AttendanceBloc>().add(
                  const AttendanceMarkAllPresentRequested(),
                ),
                onSaveCall: onSaveCallPressed,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              AttendanceResultsToolbar(
                presentCount: presentCount,
                justifiedCount: justifiedCount,
                unjustifiedCount: unjustifiedCount,
                pendingCount: missingReasonsCount,
                total: totalCount,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              SizedBox(
                height: panelHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.cardRadius,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: focusUsable
                              ? AttendanceFocusMode(rows: rowsToFocus)
                              : AttendanceRecordsMobileList(
                                  rows: state.draftRows,
                                  classroomName: request.selectedClassroom.name,
                                  shrinkWrap: false,
                                ),
                        ),
                        if (missingReasonsCount > 0)
                          _RappelAmbreBar(
                            missingReasonsCount: missingReasonsCount,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: KeyedSubtree(
            key: ValueKey(
              '${state.fetchStatus}-${state.draftRows.length}-${state.fetchErrorType}-${state.saveStatus}-${state.hasUnsavedChanges}-${state.hasValidationErrors}-${state.callTaken}',
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _AttendanceActionBar extends StatelessWidget {
  final bool isSaving;
  final bool canSave;
  final VoidCallback onMarkAllPresent;
  final VoidCallback onSaveCall;

  /// L'écriture serait une correction d'un appel passé, donc un arbitrage.
  final bool isPastCorrection;

  const _AttendanceActionBar({
    required this.isSaving,
    required this.canSave,
    required this.onMarkAllPresent,
    required this.onSaveCall,
    required this.isPastCorrection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // La feuille d'appel est atteignable avec `attendance.read` seul : sans
    // cette garde, un profil en lecture se verrait offrir l'enregistrement.
    //
    // Sur une correction d'un jour révolu, l'exigence monte d'un cran. Le repli
    // n'est pas vide ici, contrairement à la convention du gate : une feuille
    // d'appel sans bouton d'enregistrement, sans un mot, se lit comme une panne.
    return PermissionGate.access(
      isPastCorrection ? kAttendanceAmendAccess : kAttendanceRecordAccess,
      fallback: isPastCorrection ? const _PastCallAmendLockedNotice() : null,
      child: SessionWriteGate(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            EteeloButton.secondary(
              label: l10n.attendanceMarkAllPresentAction,
              onPressed: isSaving ? null : onMarkAllPresent,
              fullWidth: false,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            EteeloButton.primary(
              label: l10n.attendanceSaveCallAction,
              isLoading: isSaving,
              onPressed: canSave ? onSaveCall : null,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui bloque l'enregistrement quand une ligne porte un motif que cette
/// version ne connaît pas — et qui dit pourquoi, plutôt que de laisser un
/// bouton grisé sans explication.
class _UnsupportedReasonBar extends StatelessWidget {
  final int count;

  const _UnsupportedReasonBar({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                l10n.attendanceUnsupportedReasonBlocked,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La bascule Liste | Focus, avec le nombre de motifs restants.
///
/// Elle n'apparaît que s'il en reste : c'est ce qui empêche le Focus de devenir
/// un détour. Le compteur est le même que celui qui bloque l'enregistrement —
/// l'utilisateur voit donc décroître exactement ce qui le retient.
class _EntryModeBar extends StatelessWidget {
  final AttendanceEntryMode mode;
  final int pending;
  final ValueChanged<AttendanceEntryMode> onChanged;

  const _EntryModeBar({
    required this.mode,
    required this.pending,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        // ⚠️ `expand: true` : contraint en largeur dans une Row, le contrôle
        // déborde sans lui.
        SizedBox(
          width: 220,
          child: SegmentedTabFilter<AttendanceEntryMode>(
            selected: mode,
            onSelected: onChanged,
            expand: true,
            options: [
              SegmentedTabOption(
                label: l10n.attendanceModeList,
                value: AttendanceEntryMode.list,
                icon: Icons.table_rows_rounded,
              ),
              SegmentedTabOption(
                label: l10n.attendanceModeFocus,
                value: AttendanceEntryMode.focus,
                icon: Icons.center_focus_strong_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(
            l10n.attendancePendingReasons(pending),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _PastCallAmendLockedNotice extends StatelessWidget {
  const _PastCallAmendLockedNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            l10n.attendancePastCallAmendLocked,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le jour est-il révolu ?
///
/// L'horloge lue est celle de la tablette, et elle n'est pas digne de confiance
/// — c'est bien pourquoi le serveur refait le calcul sur la sienne avant
/// d'écrire. Ici on ne protège rien : on évite de mettre en file une écriture
/// qui mourrait en 403, et un 403 sur l'outbox est TERMINAL, donc la saisie
/// serait perdue plutôt que rejouée.
bool _isBeforeToday(DateTime date) {
  final now = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).isBefore(DateTime(now.year, now.month, now.day));
}

/// Bandeau du 3e état (invariant #1) : aucune session pour ce jour → l'appel
/// n'a pas été fait. Le roster est affiché pour la saisie mais rien n'est validé.
class _AppelNonFaitBar extends StatelessWidget {
  const _AppelNonFaitBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 16,
              color: AppColors.info,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.attendanceCallNotTakenTitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.attendanceCallNotTakenMessage,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RappelAmbreBar extends StatelessWidget {
  final int missingReasonsCount;

  const _RappelAmbreBar({required this.missingReasonsCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.cardRadius),
          bottomRight: Radius.circular(AppDimensions.cardRadius),
        ),
        border: Border(
          top: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Expanded(
              child: Text(
                l10n.attendanceMissingReasonsStatus(missingReasonsCount),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
