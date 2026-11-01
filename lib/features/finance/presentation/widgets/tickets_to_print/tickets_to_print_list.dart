import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_queue_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/tickets_to_print/ticket_print_job_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux groupes de « Tickets à imprimer » : ceux qui peuvent sortir, cochables
/// et rangés par numéro ; ceux qui attendent leur numéro, grisés.
class TicketsToPrintList extends StatelessWidget {
  final TicketPrintQueueState state;
  final void Function(String jobId, bool selected) onToggle;
  final ValueChanged<bool> onToggleAll;

  /// « Relancer » le reçu qu'un accusé n'a pas rapporté.
  final ValueChanged<TicketPrintJob> onRetry;

  const TicketsToPrintList({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onToggleAll,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ready = state.ready;
    final awaiting = state.awaiting;
    final frozen = state.printing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ready.isNotEmpty)
          _SectionCard(
            icon: Icons.print_outlined,
            title: l10n.ticketsToPrintReadySection(ready.length),
            subtitle: l10n.ticketsToPrintReadyHint,
            trailing: _SelectAll(
              value: state.allReadySelected,
              onChanged: frozen ? null : onToggleAll,
            ),
            children: [
              for (final job in ready)
                TicketPrintJobTile(
                  key: ValueKey(job.id),
                  job: job,
                  selected: state.selected.contains(job.id),
                  onChanged: frozen ? null : (value) => onToggle(job.id, value),
                ),
            ],
          ),
        if (ready.isNotEmpty && awaiting.isNotEmpty)
          const SizedBox(height: AppDimensions.spacingM),
        if (awaiting.isNotEmpty)
          _SectionCard(
            icon: Icons.hourglass_empty_rounded,
            title: l10n.ticketsToPrintAwaitingSection(awaiting.length),
            subtitle: l10n.ticketsToPrintAwaitingHint,
            children: [
              for (final job in awaiting)
                TicketPrintJobTile(
                  key: ValueKey(job.id),
                  job: job,
                  onRetry: job.state == TicketPrintJobState.receiptMissing
                      ? () => onRetry(job)
                      : null,
                  retrying: state.retrying.contains(job.id),
                ),
            ],
          ),
      ],
    );
  }
}

/// Un groupe de tickets : sa carte, son en-tête, ses lignes.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return FinanceSectionCard(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FinanceSectionHeader(
            icon: icon,
            title: title,
            subtitle: subtitle,
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.surfaceAlt,
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
          const SizedBox(height: AppDimensions.spacingS),
          ...children,
        ],
      ),
    );
  }
}

/// « Tout cocher », cible de 48 dp.
class _SelectAll extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SelectAll({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onChanged = this.onChanged;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.minTouchTarget,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged(v ?? false),
            ),
            Text(l10n.ticketsToPrintSelectAll, style: AppTextStyles.body),
            const SizedBox(width: AppDimensions.spacingS),
          ],
        ),
      ),
    );
  }
}

/// Le type d'un ticket, dans la langue de l'écran.
String ticketPrintJobKindLabel(
  TicketPrintJobKind kind,
  AppLocalizations l10n,
) => switch (kind) {
  TicketPrintJobKind.receipt => l10n.ticketsToPrintKindReceipt,
  TicketPrintJobKind.cancellation => l10n.ticketsToPrintKindCancellation,
};
