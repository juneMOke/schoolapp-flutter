import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_row_selection.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_selection_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/suspension_flow.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/show_suspended_toggle.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_changes_listener.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_selection_bar.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspension_start_button.dart';

/// La désactivation dans la liste Première inscription : le mode sélection,
/// sa portée sur la table et la grille, et la relecture de la liste quand une
/// désactivation change. Les désactivés y sont masqués à l'ouverture.
class FirstRegistrationSuspensionScope extends StatefulWidget {
  final Widget child;

  const FirstRegistrationSuspensionScope({super.key, required this.child});

  @override
  State<FirstRegistrationSuspensionScope> createState() =>
      _FirstRegistrationSuspensionScopeState();
}

class _FirstRegistrationSuspensionScopeState
    extends State<FirstRegistrationSuspensionScope> {
  @override
  void initState() {
    super.initState();
    // Bascule « Afficher les désactivés » : éteinte à chaque visite.
    context.read<EnrollmentLocalListBloc>().add(
      const LocalListShowSuspendedChanged(false),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SuspensionSelectionCubit(),
    child: SuspensionChangesListener(
      onChanged: () => context.read<EnrollmentLocalListBloc>().add(
        const LocalListRefreshRequested(),
      ),
      child: BlocListener<EnrollmentLocalListBloc, EnrollmentLocalListState>(
        listenWhen: (previous, current) =>
            current.summariesStatus == EnrollmentLoadStatus.success &&
            previous.lastSummariesQuery != current.lastSummariesQuery,
        listener: (context, _) =>
            context.read<SuspensionSelectionCubit>().retain({
              for (final s
                  in context.read<EnrollmentLocalListBloc>().loadedSummaries)
                s.enrollmentId,
            }),
        child: BlocBuilder<SuspensionSelectionCubit, SuspensionSelectionState>(
          builder: (context, selection) => EnrollmentRowSelectionScope(
            selection: selection.active
                ? EnrollmentRowSelection(
                    selected: selection.selected,
                    onToggle: (s) => context
                        .read<SuspensionSelectionCubit>()
                        .toggle(s.enrollmentId),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}

/// Les actions de la barre de résultats : la bascule « Afficher les
/// désactivés (N) » dès qu'il y en a un, et « Désactiver des élèves » hors
/// mode sélection.
class FirstRegistrationSuspensionActions extends StatelessWidget {
  const FirstRegistrationSuspensionActions({super.key});

  @override
  Widget build(BuildContext context) {
    final (suspendedCount, showSuspended) = context.select(
      (EnrollmentLocalListBloc b) =>
          (b.state.suspendedCount, b.state.showSuspended),
    );
    final selecting = context.select(
      (SuspensionSelectionCubit c) => c.state.active,
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (suspendedCount > 0)
          ShowSuspendedToggle(
            value: showSuspended,
            count: suspendedCount,
            onChanged: (show) => context.read<EnrollmentLocalListBloc>().add(
              LocalListShowSuspendedChanged(show),
            ),
          ),
        if (!selecting)
          SuspensionStartButton(
            onPressed: () => context.read<SuspensionSelectionCubit>().start(),
          ),
      ],
    );
  }
}

/// La barre sombre du mode sélection, au-dessus des résultats.
class FirstRegistrationSelectionBar extends StatelessWidget {
  const FirstRegistrationSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<SuspensionSelectionCubit>().state;
    if (!selection.active) return const SizedBox.shrink();
    final page = context.select(
      (EnrollmentLocalListBloc b) => b.state.summaries,
    );
    final eligible = [
      for (final s in page)
        if (EnrollmentRowSelection.isEligible(s)) s.enrollmentId,
    ];
    final cubit = context.read<SuspensionSelectionCubit>();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SuspensionSelectionBar(
        selectedCount: selection.selected.length,
        onTogglePage: eligible.isEmpty
            ? null
            : () => cubit.togglePage(eligible),
        pageFullySelected:
            eligible.isNotEmpty && eligible.every(selection.selected.contains),
        onCancel: cubit.cancel,
        onConfirm: () => _confirm(context, selection.selected),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, Set<String> selected) async {
    final summaries = context.read<EnrollmentLocalListBloc>().loadedSummaries;
    final candidates = [
      for (final s in summaries)
        if (selected.contains(s.enrollmentId) &&
            EnrollmentRowSelection.isEligible(s))
          candidateOf(s),
    ];
    if (candidates.isEmpty) return;
    final done = await SuspensionFlow.suspend(context, candidates);
    if (done > 0 && context.mounted) {
      context.read<SuspensionSelectionCubit>().cancel();
    }
  }
}

/// La ligne de liste vue par la désactivation.
SuspensionCandidate candidateOf(EnrollmentSummary s) => SuspensionCandidate(
  target: SuspensionTarget(
    enrollmentId: s.enrollmentId,
    studentId: s.student.id,
    academicYearId: s.academicYearId!,
  ),
  lastName: s.student.lastName,
  middleName: s.student.surname,
  firstName: s.student.firstName,
);
