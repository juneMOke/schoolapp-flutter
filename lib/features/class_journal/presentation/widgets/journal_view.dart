import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/cards/journal_card_list.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/header/journal_day_header.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/sheet/journal_sheet.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/states/journal_states.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une page du journal : l'en-tête du jour, toujours visible, puis la zone
/// d'état — squelette, feuille (large) ou cartes (étroit), vide, erreur.
class JournalView extends StatelessWidget {
  /// Ouvre la saisie d'une séance ; `null` : lecture seule.
  final ValueChanged<JournalLine>? onOpen;

  const JournalView({super.key, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<JournalDayCubit, JournalDayState>(
          builder: (context, state) {
            final cubit = context.read<JournalDayCubit>();
            return JournalDayHeader(
              date: state.date,
              isToday: state.isToday,
              day: switch (state) {
                JournalDayReady(:final day) => day,
                _ => null,
              },
              onPrevious: cubit.canGoBack ? cubit.previous : null,
              onNext: cubit.canGoForward ? cubit.next : null,
              onToday: cubit.goToday,
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<JournalDayCubit, JournalDayState>(
          buildWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType || prev != curr,
          builder: (context, state) => switch (state) {
            JournalDayIdle() || JournalDayLoading() => const JournalSkeleton(),
            JournalDayFailure(:final failure, :final date) =>
              JournalFailureView(
                failure: failure,
                onRetry: () => context.read<JournalDayCubit>().show(date),
              ),
            JournalDayReady(:final day) => _ReadyBody(day: day, onOpen: onOpen),
          },
        ),
      ],
    );
  }
}

class _ReadyBody extends StatelessWidget {
  final JournalDay day;
  final ValueChanged<JournalLine>? onOpen;

  const _ReadyBody({required this.day, this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (day.isEmpty) {
      return JournalEmptyDay(
        date: day.date,
        nextCourseDay: day.nextCourseDay,
        onOpenDay: context.read<JournalDayCubit>().show,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppDimensions.journalBreakpoint
              ? JournalSheet(lines: day.lines, onOpen: onOpen)
              : JournalCardList(lines: day.lines, onOpen: onOpen),
        ),
        if (onOpen != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.journalHelp,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
