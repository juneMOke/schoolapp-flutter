import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_sheet_figures.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_sheet_filter.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_student_list.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_buttons.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_call_list.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la fiche d'une classe (O2, I5/I6) : ses chiffres sur [feeCode], la
/// liste de ses élèves filtrable par situation, « Ouvrir dans le contrôle »,
/// PDF et Excel. Modale large (720), plein écran sous 760 de fenêtre.
///
/// La liste est lue par une instance propre de [RecoveryStudentsCubit],
/// fermée avec la fiche. Une classe compte au plus ~80 élèves : une page de
/// 100 suffit.
Future<void> showRecoveryClassSheet(
  BuildContext context, {
  required String academicYearId,
  required RecoveryQuestion question,
  required String feeCode,
  required String feeLabel,
  required RecoveryClassFeeRow row,
  required DateTime situationAt,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return EteeloFormDialog.show<void>(
    context,
    RecoveryClassSheet(
      hostContext: context,
      academicYearId: academicYearId,
      question: question,
      feeCode: feeCode,
      feeLabel: feeLabel,
      row: row,
      situationAt: situationAt,
    ),
  );
}

class RecoveryClassSheet extends StatefulWidget {
  /// Le contexte de la page : la fiche d'un élève (O4) y lit les titres des
  /// frais, que la modale ne voit pas.
  final BuildContext hostContext;
  final String academicYearId;
  final RecoveryQuestion question;
  final String feeCode;
  final String feeLabel;
  final RecoveryClassFeeRow row;
  final DateTime situationAt;

  const RecoveryClassSheet({
    super.key,
    required this.hostContext,
    required this.academicYearId,
    required this.question,
    required this.feeCode,
    required this.feeLabel,
    required this.row,
    required this.situationAt,
  });

  @override
  State<RecoveryClassSheet> createState() => _RecoveryClassSheetState();
}

class _RecoveryClassSheetState extends State<RecoveryClassSheet> {
  final RecoveryStudentsCubit _cubit = getIt<RecoveryStudentsCubit>();
  StudentChargeStatus? _situation;

  String get _classroomId => widget.row.classroomId ?? feeControlUnassigned;

  /// La requête de la liste ; sans [size] (défaut), c'est celle des exports.
  RecoveryStudentsQuery _query({
    int size = AppConstants.recoveryStudentsPageSize,
  }) => RecoveryStudentsQuery(
    question: widget.question.copyWith(feeCodes: [widget.feeCode]),
    tab: RecoveryTab.all,
    classroomId: _classroomId,
    situation: recoverySituationWire(_situation),
    size: size,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _load() => _cubit.load(
    widget.academicYearId,
    _query(size: recoveryCallListPageSize),
  );

  void _select(StudentChargeStatus? situation) {
    if (situation == _situation) return;
    setState(() => _situation = situation);
    _load();
  }

  /// Avant la première réponse, les comptes viennent de la ligne du
  /// classement (mêmes chiffres serveur, sur ce frais).
  RecoverySituationCounts _counts(RecoveryStudentsPage? page) =>
      page?.situationCounts ??
      RecoverySituationCounts(
        noPayment: widget.row.noPaymentStudents,
        partial:
            (widget.row.billedStudents -
                    widget.row.settledStudents -
                    widget.row.noPaymentStudents)
                .clamp(0, widget.row.billedStudents),
        settled: widget.row.settledStudents,
      );

  void _openControl() {
    Navigator.of(context).pop();
    openControlFromDashboard(
      widget.hostContext,
      feeCodes: [widget.feeCode],
      classroomId: _classroomId,
    );
  }

  void _openStudent(RecoveryStudentRow student) {
    final host = widget.hostContext;
    if (!host.mounted) return;
    openRecoveryStudentSheet(
      host,
      academicYearId: widget.academicYearId,
      studentId: student.studentId,
      displayName: student.displayName,
      classroomId: student.classroomId ?? widget.row.classroomId,
      feeCodes: [widget.feeCode],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycle = widget.row.cycleName;
    return BlocBuilder<RecoveryStudentsCubit, RecoveryStudentsState>(
      bloc: _cubit,
      builder: (context, state) {
        final page = state.page;
        final ready =
            state.status == RecoveryLoadStatus.success && page != null;
        final online = ready && page.cachedAt == null;
        return EteeloFormDialog(
          maxWidth: AppDimensions.recoveryClassSheetMaxWidth,
          eyebrow: cycle == null || cycle.trim().isEmpty
              ? widget.feeLabel
              : l10n.recoveryClassSheetEyebrow(cycle, widget.feeLabel),
          title: widget.row.classroomName,
          leading: OutlinedButton.icon(
            // Largeur du libellé : le thème étire les boutons pleine ligne.
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
            onPressed: _openControl,
            icon: const Icon(Icons.assignment_outlined),
            label: Text(l10n.recoveryClassSheetOpenControl),
          ),
          actions: [
            RecoveryExportButtons(
              query: _query(),
              title: page?.title ?? widget.row.classroomName,
              enabled: online && page.content.isNotEmpty,
              disabledReason: _offline(state)
                  ? l10n.recoveryExportsAwaitNetwork
                  : null,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.recouvrementClose),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.recoveryClassSheetSubtitle(
                  widget.row.billedStudents,
                  widget.situationAt.toLocal(),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RecoveryClassSheetFigures(row: widget.row, counts: _counts(page)),
              const SizedBox(height: AppSpacing.gridGap),
              RecoveryClassSheetFilter(
                value: _situation,
                counts: _counts(page),
                onChanged: _select,
              ),
              const SizedBox(height: AppDimensions.recoverySpace10),
              _results(l10n, state),
            ],
          ),
        );
      },
    );
  }

  /// Hors ligne : une coupure, ou une réponse tirée du cache. La fiche reste
  /// lisible ; les exports, eux, attendent le réseau.
  static bool _offline(RecoveryStudentsState state) =>
      state.page?.cachedAt != null ||
      (state.status == RecoveryLoadStatus.failure &&
          state.failure is NetworkFailure);

  Widget _results(AppLocalizations l10n, RecoveryStudentsState state) {
    final page = state.page;
    switch (state.status) {
      case RecoveryLoadStatus.failure:
        return RecoveryResultsErrorState(
          failure: state.failure!,
          onRetry: _load,
          nominative: true,
        );
      case RecoveryLoadStatus.success when page != null:
        if (page.content.isEmpty) {
          return EteeloEmptyResult(
            label: l10n.recoveryClassSheetEmpty,
            medallionIcon: Icons.filter_alt_off_outlined,
            minHeight: 0,
            cardPadding: const EdgeInsets.all(AppSpacing.xl),
            fullWidthCard: true,
          );
        }
        return RecoveryClassStudentList(
          rows: page.content,
          onStudentTapped: _openStudent,
        );
      default:
        return EteeloListSkeleton(
          rowCount: 6,
          pillCount: 1,
          semanticsLabel: l10n.recoveryClassSheetLoading,
        );
    }
  }
}
