import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_staff_table.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Ce que chaque salarié perçoit » : recherche (nom ou fonction), filtre,
/// tableau — et le PDF du serveur sur **les mêmes paramètres** (règle n° 14).
class PayrollDashboardStaffSection extends StatefulWidget {
  final String month;
  final List<PayrollDashboardRow> rows;
  final PayrollSnapshot snapshot;
  final bool validated;

  const PayrollDashboardStaffSection({
    super.key,
    required this.month,
    required this.rows,
    required this.snapshot,
    required this.validated,
  });

  @override
  State<PayrollDashboardStaffSection> createState() => _StaffSectionState();
}

class _StaffSectionState extends State<PayrollDashboardStaffSection> {
  String _search = '';
  PayrollDashboardFilter _filter = PayrollDashboardFilter.all;
  bool _printing = false;

  List<PayrollDashboardRow> get _visible => [
    for (final row in widget.rows)
      if (_filter.keeps(row.status) && _matches(row)) row,
  ];

  /// Nom ou fonction, sans égard à la casse ni aux accents — comme `q` côté
  /// serveur.
  bool _matches(PayrollDashboardRow row) {
    final needle = _search.trim();
    if (needle.isEmpty) return true;
    final member = widget.snapshot.member(row.staffMemberId);
    return member != null && StaffMemberSearch.matches(member, needle);
  }

  Future<void> _pdf() async {
    final cubit = context.read<PayrollCubit>();
    final l10n = AppLocalizations.of(context)!;
    setState(() => _printing = true);
    final query = _search.trim();
    final result = await cubit.commands.dashboardPdf(
      widget.month,
      filter: _filter.wire,
      query: query.isEmpty ? null : query,
    );
    if (!mounted) return;
    setState(() => _printing = false);
    await result.fold(
      (failure) async => cubit.announce(
        PayrollNotice(switch (failure) {
          NetworkFailure() => PayrollNoticeKind.offline,
          TooManyRequestsFailure() => PayrollNoticeKind.renderBusy,
          _ => PayrollNoticeKind.downloadFailed,
        }),
      ),
      (bytes) => showEteeloDocumentViewer(
        context,
        title: l10n.payrollDashStaffTitle,
        document: PrintableDocument(
          bytes: bytes,
          fileName: '${l10n.payrollDashPdfFileName(widget.month)}.pdf',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = _visible;
    return PayrollDashboardCard(
      title: l10n.payrollDashStaffTitle,
      subtitle: widget.validated ? null : l10n.payrollDashProvisional,
      trailing: EteeloButton.secondary(
        label: l10n.payrollDashPdf,
        icon: Icons.picture_as_pdf_outlined,
        isLoading: _printing,
        onPressed: widget.rows.isEmpty ? null : _pdf,
        fullWidth: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffSearchToolbar(
            text: _search,
            label: l10n.payrollDashSearchHint,
            placeholder: l10n.payrollDashSearchHint,
            onTextChanged: (text) => setState(() => _search = text),
          ),
          const SizedBox(height: AppSpacing.sm),
          PayrollChoiceChips<PayrollDashboardFilter>(
            values: PayrollDashboardFilter.values,
            selected: _filter,
            label: (filter) => switch (filter) {
              PayrollDashboardFilter.all => l10n.payrollFilterAll,
              PayrollDashboardFilter.outstanding =>
                l10n.payrollDashFilterOutstanding,
              PayrollDashboardFilter.settled => l10n.payrollDashFilterSettled,
            },
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            EteeloEmptyResult(
              label: l10n.payrollDashStaffEmpty,
              medallionIcon: Icons.search_off,
              primaryAction: EteeloButton.secondary(
                label: l10n.payrollDashShowAll,
                onPressed: () => setState(() {
                  _search = '';
                  _filter = PayrollDashboardFilter.all;
                }),
                fullWidth: false,
              ),
            )
          else
            PayrollDashboardStaffTable(
              rows: visible,
              snapshot: widget.snapshot,
            ),
        ],
      ),
    );
  }
}
