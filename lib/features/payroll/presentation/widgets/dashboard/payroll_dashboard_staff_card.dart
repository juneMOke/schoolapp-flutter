import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_agent_navigation.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_location.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_staff_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Ce que chaque salarié perçoit » : recherche (nom ou fonction) et filtre
/// partent au serveur, qui renvoie les lignes et leur total — et le PDF part
/// sur **les mêmes paramètres** (règle n° 14).
class PayrollDashboardStaffCard extends StatefulWidget {
  final PayrollDashboardState state;
  final PayrollDashboardCurrency section;

  const PayrollDashboardStaffCard({
    super.key,
    required this.state,
    required this.section,
  });

  @override
  State<PayrollDashboardStaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<PayrollDashboardStaffCard> {
  bool _printing = false;

  /// Une ligne ouvre la fiche de l'agent sur le mois affiché ; au retour,
  /// le tableau de bord se relit — un versement a pu y être posé.
  Future<void> _openAgent(String agentId) async {
    final cubit = context.read<PayrollDashboardCubit>();
    final state = cubit.state;
    await PayrollAgentNavigation.open(
      context,
      agentId: agentId,
      month: state.month,
      from: MenuConstants.hrPayrollDashboardId,
      screenQuery: {
        if (!state.isCurrentMonth)
          PayrollDashboardLocation.monthParam: state.month,
        PayrollDashboardLocation.filterParam: ?state.filter.address,
      },
    );
    if (!mounted || cubit.isClosed) return;
    await cubit.refresh();
  }

  Future<void> _pdf() async {
    final cubit = context.read<PayrollDashboardCubit>();
    final l10n = AppLocalizations.of(context)!;
    final month = cubit.state.month;
    setState(() => _printing = true);
    final result = await cubit.pdf();
    if (!mounted) return;
    setState(() => _printing = false);
    await result.fold(
      (failure) async => showPayrollNotice(
        context,
        PayrollNotice(switch (failure) {
          NetworkFailure() => PayrollNoticeKind.offline,
          TooManyRequestsFailure() => PayrollNoticeKind.renderBusy,
          _ => PayrollNoticeKind.downloadFailed,
        }),
        monthLabel: PayrollLabels.month(context, month),
      ),
      (bytes) => showEteeloDocumentViewer(
        context,
        title: l10n.payrollDashStaffTitle,
        document: PrintableDocument(
          bytes: bytes,
          fileName: '${l10n.payrollDashPdfFileName(month)}.pdf',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollDashboardCubit>();
    final state = widget.state;
    final section = widget.section;
    return EteeloStatsCard(
      title: l10n.payrollDashStaffTitle,
      subtitle: state.dashboard?.provisional ?? true
          ? l10n.payrollDashProvisional
          : null,
      icon: Icons.groups_outlined,
      tone: DashboardSense.attendu,
      toneStrength: DashboardTones.forceDe(DashboardSense.attendu),
      toneSurface: false,
      actions: [
        EteeloButton.secondary(
          label: l10n.payrollDashPdf,
          icon: Icons.picture_as_pdf_outlined,
          isLoading: _printing,
          // Le PDF couvre toutes les devises : il s'ouvre dès qu'une a des
          // lignes, même si l'onglet affiché n'en a pas.
          onPressed:
              (state.dashboard?.currencies.every((c) => c.rows.isEmpty) ?? true)
              ? null
              : () => unawaited(_pdf()),
          fullWidth: false,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffSearchToolbar(
            text: state.search,
            label: l10n.payrollDashSearchHint,
            placeholder: l10n.payrollDashSearchHint,
            onTextChanged: cubit.setSearch,
          ),
          const SizedBox(height: AppSpacing.sm),
          PayrollChoiceChips<PayrollDashboardFilter>(
            values: PayrollDashboardFilter.values,
            selected: state.filter,
            label: (filter) => switch (filter) {
              PayrollDashboardFilter.all => l10n.payrollFilterAll,
              PayrollDashboardFilter.outstanding =>
                l10n.payrollDashFilterOutstanding,
              PayrollDashboardFilter.settled => l10n.payrollDashFilterSettled,
            },
            onSelected: (filter) => unawaited(cubit.setFilter(filter)),
          ),
          const SizedBox(height: AppSpacing.md),
          if (section.rows.isEmpty)
            EteeloEmptyResult(
              label: l10n.payrollDashStaffEmpty,
              medallionIcon: Icons.search_off,
              fullWidthCard: true,
              primaryAction: state.hasRowFilters
                  ? EteeloButton.secondary(
                      label: l10n.payrollDashShowAll,
                      onPressed: () => unawaited(cubit.clearRowFilters()),
                      fullWidth: false,
                    )
                  : null,
            )
          else
            PayrollDashboardStaffTable(section: section, onOpen: _openAgent),
        ],
      ),
    );
  }
}
