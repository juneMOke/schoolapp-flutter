import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_student_list.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/states/recovery_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La zone de résultats de la fiche de classe (O2) : squelette, erreur
/// (règle n° 10), vide filtré, ou la liste des élèves.
class RecoveryClassSheetResults extends StatelessWidget {
  final RecoveryStudentsState state;
  final VoidCallback onRetry;
  final ValueChanged<RecoveryStudentRow> onStudentTapped;

  const RecoveryClassSheetResults({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onStudentTapped,
  });

  /// Hors ligne : une coupure, ou une réponse tirée du cache. La fiche reste
  /// lisible ; les exports, eux, attendent le réseau.
  static bool offline(RecoveryStudentsState state) =>
      state.page?.cachedAt != null ||
      (state.status == RecoveryLoadStatus.failure &&
          state.failure is NetworkFailure);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final page = state.page;
    switch (state.status) {
      case RecoveryLoadStatus.failure:
        return RecoveryResultsErrorState(
          failure: state.failure!,
          onRetry: onRetry,
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
          onStudentTapped: onStudentTapped,
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
