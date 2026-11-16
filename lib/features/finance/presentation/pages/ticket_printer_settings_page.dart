import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/ticket_copies_stepper.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/ticket_printer/ticket_printer_settings_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/ticket_printer/ticket_printer_choice_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/ticket_printer/ticket_printer_permission_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Finances ▸ Imprimante de tickets : réglée une fois par tablette,
/// l'imprimante n'est plus demandée à chaque ticket.
class TicketPrinterSettingsPage extends StatelessWidget {
  const TicketPrinterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<TicketPrinterSettingsCubit>()..load(),
    child: const TicketPrinterSettingsView(),
  );
}

class TicketPrinterSettingsView extends StatefulWidget {
  const TicketPrinterSettingsView({super.key});

  @override
  State<TicketPrinterSettingsView> createState() =>
      _TicketPrinterSettingsViewState();
}

class _TicketPrinterSettingsViewState extends State<TicketPrinterSettingsView> {
  /// Au retour des réglages Android (permission, Bluetooth, appairage), la
  /// page relit ce qui a pu changer.
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      if (mounted) context.read<TicketPrinterSettingsCubit>().load();
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TicketPrinterSettingsCubit>();
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: cubit.load,
      child: AppPageBackground(
        width: PageContentWidth.reading,
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EteeloPageHeader(
              eyebrow: l10n.menuFinances,
              title: l10n.subMenuTicketPrinter,
              subtitle: l10n.ticketPrinterSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            BlocBuilder<TicketPrinterSettingsCubit, TicketPrinterSettingsState>(
              builder: (context, state) => state.loading
                  ? EteeloListSkeleton(
                      rowCount: 3,
                      pillCount: 1,
                      showAvatar: false,
                      semanticsLabel: l10n.ticketPrinterLoading,
                    )
                  : _sections(context, l10n, cubit, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sections(
    BuildContext context,
    AppLocalizations l10n,
    TicketPrinterSettingsCubit cubit,
    TicketPrinterSettingsState state,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (cubit.thermal) ...[
        TicketPrinterPermissionSection(
          missing: state.missing,
          blocked: state.blocked,
          onAllow: cubit.requestPermission,
          onOpenSettings: cubit.openSystemSettings,
        ),
        const SizedBox(height: AppSpacing.lg),
        TicketPrinterChoiceSection(
          state: state,
          onSelect: cubit.select,
          onTest: () => cubit.testPrint([
            l10n.ticketPrinterTestHeading,
            state.selected?.label ?? '',
            l10n.ticketPrinterTestBody,
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
      ] else ...[
        Text(
          l10n.ticketPrinterSpoolerNote,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      EteeloPanelCard(
        title: l10n.ticketCopiesDefaultTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TicketCopiesStepper(
              copies: state.copies,
              onChanged: cubit.copiesChanged,
            ),
            Text(
              l10n.ticketCopiesDefaultHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
