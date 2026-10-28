import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/ticket_batch_print_flow.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/tickets_to_print/tickets_to_print_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Tickets à imprimer » — les tickets que ce poste doit encore sortir
/// (continuité des tickets RC, lot D).
///
/// Un ticket ne sort qu'avec le numéro définitif de son reçu. Hors ligne, il
/// attend ici ; une fois le versement acquitté, le caissier le coche — seul ou
/// avec les autres — et lance l'impression. Rien ne s'imprime de soi-même :
/// l'imprimante est choisie à chaque lancement.
class TicketsToPrintPage extends StatelessWidget {
  const TicketsToPrintPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<TicketPrintQueueCubit>(
    create: (_) => getIt<TicketPrintQueueCubit>()..load(),
    child: const TicketsToPrintView(),
  );
}

class TicketsToPrintView extends StatelessWidget {
  const TicketsToPrintView({super.key});

  Future<void> _print(BuildContext context) async {
    final cubit = context.read<TicketPrintQueueCubit>();
    final jobs = cubit.state.selectedJobs;
    if (jobs.isEmpty || cubit.state.printing) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context)!;

    cubit.printingChanged(true);
    final TicketBatchOutcome outcome;
    try {
      outcome = await printTicketBatch(context, jobs: jobs);
    } finally {
      // Quoi qu'il arrive, le bouton se rallume : un lot qui lève ne doit pas
      // geler la page.
      if (!cubit.isClosed) cubit.printingChanged(false);
    }
    if (cubit.isClosed) return;
    await cubit.load();

    final problem = outcome.problem;
    final lines = [
      if (outcome.printed > 0) l10n.ticketsToPrintDone(outcome.printed),
      if (problem != null)
        l10n.ticketsToPrintStopped(thermalPrinterProblemMessage(l10n, problem)),
      if (outcome.skipped > 0) l10n.ticketsToPrintSkipped(outcome.skipped),
    ];
    if (lines.isNotEmpty) {
      messenger?.showSnackBar(SnackBar(content: Text(lines.join('\n'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TicketPrintQueueCubit>();

    return BlocListener<SyncStatusCubit, SyncStatusState>(
      // Une synchronisation terminée peut avoir scellé des reçus : leurs
      // tickets deviennent prêts.
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SyncStatus.synced,
      listener: (_, _) => cubit.load(),
      child: PageActionShortcut(
        action: PageAction.print,
        onInvoke: () => _print(context),
        isAllowed: () =>
            cubit.state.selected.isNotEmpty && !cubit.state.printing,
        child: PageActionShortcut(
          action: PageAction.refresh,
          onInvoke: cubit.load,
          child: AppPageBackground(
            appBar: ModuleTopBar(
              eyebrow: l10n.ticketsToPrintEyebrow,
              title: l10n.ticketsToPrintTitle,
              onBack: () => Navigator.of(context).maybePop(),
              backTooltip: l10n.ticketsToPrintBack,
            ),
            bottomNavigationBar: _PrintBar(onPrint: () => _print(context)),
            child: BlocBuilder<TicketPrintQueueCubit, TicketPrintQueueState>(
              buildWhen: (previous, current) =>
                  previous.phase != current.phase ||
                  previous.jobs != current.jobs ||
                  previous.selected != current.selected ||
                  previous.printing != current.printing ||
                  previous.retrying != current.retrying,
              builder: (context, state) => switch (state.phase) {
                TicketPrintQueuePhase.loading => EteeloListSkeleton(
                  semanticsLabel: l10n.ticketsToPrintTitle,
                ),
                TicketPrintQueuePhase.failure => EteeloErrorResult(
                  type: EteeloErrorType.server,
                  title: l10n.ticketsToPrintLoadErrorTitle,
                  message: l10n.ticketsToPrintLoadErrorMessage,
                  primaryAction: EteeloButton.primary(
                    label: l10n.ticketsToPrintRetry,
                    icon: Icons.refresh_rounded,
                    fullWidth: false,
                    onPressed: cubit.load,
                  ),
                ),
                TicketPrintQueuePhase.loaded when state.jobs.isEmpty =>
                  EteeloEmptyResult(
                    label: l10n.ticketsToPrintEmptyTitle,
                    description: l10n.ticketsToPrintEmptyDescription,
                    medallionIcon: Icons.print_outlined,
                    primaryAction: EteeloButton.secondary(
                      label: l10n.ticketsToPrintRefresh,
                      icon: Icons.refresh_rounded,
                      fullWidth: false,
                      onPressed: cubit.load,
                    ),
                  ),
                TicketPrintQueuePhase.loaded => TicketsToPrintList(
                  state: state,
                  onToggle: cubit.toggle,
                  onToggleAll: cubit.toggleAll,
                  onRetry: cubit.retryReceipt,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// La barre du bas : le seul geste de la page.
class _PrintBar extends StatelessWidget {
  final VoidCallback onPrint;

  const _PrintBar({required this.onPrint});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TicketPrintQueueCubit, TicketPrintQueueState>(
      buildWhen: (previous, current) =>
          previous.selected.length != current.selected.length ||
          previous.printing != current.printing,
      builder: (context, state) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          // Une `Row`, pas un `Align` : celui-ci s'étirerait sur toute la
          // hauteur que le `Scaffold` offre à sa barre basse, et couvrirait la
          // liste.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: EteeloButton.primary(
                  label: l10n.ticketsToPrintPrintAction(state.selected.length),
                  icon: Icons.print_outlined,
                  size: EteeloButtonSize.regular,
                  fullWidth: false,
                  isLoading: state.printing,
                  onPressed: state.selected.isEmpty || state.printing
                      ? null
                      : onPrint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
