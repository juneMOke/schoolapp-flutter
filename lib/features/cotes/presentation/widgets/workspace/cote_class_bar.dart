import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/workspace/cote_save_status_indicator.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La classe, sa progression sur la portée et l'état de l'enregistrement.
class CoteClassBar extends StatelessWidget {
  final String classroomName;

  const CoteClassBar({super.key, required this.classroomName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
          buildWhen: (previous, current) =>
              current is CoteSaisieReady &&
              (previous is! CoteSaisieReady ||
                  previous.progress != current.progress ||
                  previous.scope != current.scope),
          builder: (context, state) {
            if (state is! CoteSaisieReady) return const SizedBox.shrink();
            return _progress(l10n, state);
          },
        ),
        BlocBuilder<CoteSaveCubit, CoteSaveStatus>(
          builder: (context, status) => CoteSaveStatusIndicator(
            status: status,
            onRetry: context.read<CoteSaveCubit>().retry,
          ),
        ),
      ],
    );
  }

  Widget _progress(AppLocalizations l10n, CoteSaisieReady state) {
    final progress = state.progress;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.coteClassBarEyebrow(classroomName).toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.terreCuite,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          l10n.coteClassBarSummary(
            CoteLabels.scope(l10n, state.classe, state.scope, state.columns),
            state.eleves.length,
            progress.complets,
          ),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(
          width: AppDimensions.coteProgressMaxWidth,
          height: AppDimensions.coteProgressHeight,
          child: ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: progress.cells == 0 ? 0 : progress.filled / progress.cells,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.vertSavane),
            ),
          ),
        ),
      ],
    );
  }
}
