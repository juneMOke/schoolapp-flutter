import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_failure_mapper.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/helpers/justification_queue_actions.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_card.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_empty_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/widgets/justification_queue_tabs.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Disciplines ▸ Justifications — les justifications d'absence déposées par
/// les parents depuis le portail, et la décision de l'école.
///
/// Une demande ne justifie rien tant que l'école ne l'a pas acceptée : sans
/// cet écran, elle resterait en attente indéfiniment.
class JustificationQueuePage extends StatelessWidget {
  const JustificationQueuePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<JustificationQueueCubit>(
    create: (_) => getIt<JustificationQueueCubit>(),
    child: const JustificationQueueScreen(),
  );
}

class JustificationQueueScreen extends StatefulWidget {
  const JustificationQueueScreen({super.key});

  @override
  State<JustificationQueueScreen> createState() =>
      _JustificationQueueScreenState();
}

class _JustificationQueueScreenState extends State<JustificationQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final years = context.read<AcademicYearContextBloc>();
      years.add(const AcademicYearContextRequested());
      // Un contexte déjà résolu ne repasse pas par le listener.
      _onAcademicYear(years.state);
    });
  }

  void _onAcademicYear(AcademicYearContextState state) {
    final year = state.context?.academicYear;
    if (state.status != AcademicYearContextLoadStatus.success || year == null) {
      return;
    }
    unawaited(context.read<JustificationQueueCubit>().setAcademicYear(year.id));
  }

  @override
  Widget build(BuildContext context) => AppPageBackground(
    width: PageContentWidth.wide,
    child: MultiBlocListener(
      listeners: [
        BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.context?.academicYear.id !=
                  current.context?.academicYear.id,
          listener: (context, state) => _onAcademicYear(state),
        ),
        BlocListener<JustificationQueueCubit, JustificationQueueState>(
          listenWhen: (previous, current) =>
              current.decidedElsewhere.isNotEmpty &&
              previous.decidedElsewhere != current.decidedElsewhere,
          listener: _announceDecidedElsewhere,
        ),
      ],
      child: BlocBuilder<JustificationQueueCubit, JustificationQueueState>(
        buildWhen: (previous, current) =>
            previous.load != current.load ||
            previous.all != current.all ||
            previous.filter != current.filter ||
            previous.attachments != current.attachments ||
            previous.failure != current.failure,
        builder: _body,
      ),
    ),
  );

  void _announceDecidedElsewhere(
    BuildContext context,
    JustificationQueueState state,
  ) {
    AppSnackBar.showInfo(
      context,
      AppLocalizations.of(
        context,
      )!.justificationDecidedElsewhere(state.decidedElsewhere.length),
    );
    unawaited(
      context.read<JustificationQueueCubit>().acknowledgeDecidedElsewhere(),
    );
  }

  Widget _body(BuildContext context, JustificationQueueState state) {
    final cubit = context.read<JustificationQueueCubit>();
    if (state.isLoading) return const EteeloListSkeleton(rowCount: 6);
    final failure = state.failure;
    if (state.load == JustificationQueueLoad.failure && failure != null) {
      return AttendanceResultsErrorState(
        type: mapFailureToAttendanceErrorType(failure),
        onRetry: () => unawaited(cubit.refresh()),
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
      );
    }
    final actions = JustificationQueueActions(context);
    final visible = state.visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JustificationQueueTabs(state: state, onSelect: cubit.setFilter),
        const SizedBox(height: AppSpacing.lg),
        if (visible.isEmpty)
          JustificationEmptyState(filter: state.filter)
        else
          for (final justification in visible) ...[
            JustificationCard(
              key: ValueKey(justification.id),
              justification: justification,
              attachmentAvailable: switch (justification.attachment) {
                final ref? => state.attachments.canOpen(ref),
                null => false,
              },
              onOpenAttachment: () =>
                  unawaited(actions.openAttachment(justification)),
              onAccept: () => unawaited(actions.accept(justification)),
              onReject: () => unawaited(actions.reject(justification)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}
