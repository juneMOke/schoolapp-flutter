import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_catalog_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_address.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_fee_picker_field.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_sheet.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_ranking_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_fee_rates_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_key_figures_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_insights_row.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_call_list.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les blocs B à G, dans un ordre qui ne change à aucune largeur (§4.1) :
/// E précède toujours F, puisque F reprend la règle de E.
class RecoveryDashboardBlocks extends StatefulWidget {
  final String academicYearId;
  final RecoveryDashboard dashboard;
  final RecoveryDashboardAddress address;
  final ValueChanged<RecoveryDashboardAddress> onAddressChanged;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onRetryList;

  const RecoveryDashboardBlocks({
    super.key,
    required this.academicYearId,
    required this.dashboard,
    required this.address,
    required this.onAddressChanged,
    required this.onPageChanged,
    required this.onRetryList,
  });

  @override
  State<RecoveryDashboardBlocks> createState() =>
      _RecoveryDashboardBlocksState();
}

class _RecoveryDashboardBlocksState extends State<RecoveryDashboardBlocks> {
  /// La carte E : « Changer » de la simulation y remonte (I14).
  final _studentsKey = GlobalKey();

  /// Le montant de « a payé au moins » relit le serveur à la fin de la
  /// frappe, pas à chaque chiffre : chaque lecture est un instantané complet.
  Timer? _amountDebounce;

  @override
  void dispose() {
    _amountDebounce?.cancel();
    super.dispose();
  }

  void _onAmount(int? cents) {
    _amountDebounce?.cancel();
    _amountDebounce = Timer(AppConstants.recoveryAmountDebounce, () {
      if (!mounted) return;
      widget.onAddressChanged(widget.address.copyWith(thresholdInCents: cents));
    });
  }

  RecoveryDashboard get _d => widget.dashboard;
  RecoveryDashboardAddress get _a => widget.address;

  /// Le choix de « Classes en tête » : celui de l'adresse s'il est encore
  /// classé, sinon le premier (`feeCode`, ou `feeCode|devise` pour un frais
  /// facturé en deux devises).
  RecoveryRankingOption? get _ranking => RecoveryRankingOptions.resolve(
    RecoveryRankingOptions.of(_d),
    _a.rankingFeeCode ?? '',
  );

  String get _rankingValue => _ranking?.value ?? _a.feeCodes.first;

  String get _rankingFeeCode => _ranking?.feeCode ?? _a.feeCodes.first;

  String _feeLabel(String code) =>
      _d.fees.where((f) => f.code == code).firstOrNull?.label ?? code;

  /// « Scolarité » ou « Scolarité +1 autre » — la pastille « Sur … » de E.
  String _feesLabel(AppLocalizations l10n) {
    final first = _feeLabel(_a.feeCodes.first);
    final more = _a.feeCodes.length - 1;
    return more <= 0 ? first : '$first ${l10n.recouvrementFeesMore(more)}';
  }

  /// Hors ligne (photo du cache) : les exports attendent le réseau.
  bool get _online => _d.cachedAt == null;

  void _openFees() {
    final catalog = context.read<RecoveryCatalogCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    showRecouvrementFeeOptions(
      context,
      title: l10n.recouvrementFeesForWhich,
      natures: catalog.natures,
      selected: _a.feeCodes,
      titles: context.read<FeeSectionTitlesCubit>().state,
      onChanged: (fees) {
        if (fees.isNotEmpty) {
          widget.onAddressChanged(widget.address.copyWith(feeCodes: fees));
        }
      },
    );
  }

  void _openControl({String? classroomId, StudentChargeStatus? situation}) =>
      openControlFromDashboard(
        context,
        feeCodes: _a.feeCodes,
        classroomId: classroomId ?? controlClassroomOf(_a.question),
        situation: situation,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final question = _a.question;
    final students = context.watch<RecoveryStudentsCubit>().state;
    final exportQuery = RecoveryStudentsQuery(question: question, tab: _a.tab);
    const gap = SizedBox(height: AppSpacing.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecoveryKeyFiguresSection(
          dashboard: _d,
          onSituationTapped: (s) => _openControl(situation: s),
        ),
        gap,
        RecoveryFeeRatesPanel(dashboard: _d),
        gap,
        RecoveryClassRankingPanel(
          dashboard: _d,
          rankingFeeCode: _rankingValue,
          onRankingFeeChanged: (code) =>
              widget.onAddressChanged(_a.copyWith(rankingFeeCode: code)),
          onClassTapped: (row) => showRecoveryClassSheet(
            context,
            academicYearId: widget.academicYearId,
            question: question,
            feeCode: _rankingFeeCode,
            feeLabel: _feeLabel(_rankingFeeCode),
            row: row,
            situationAt: _d.situationAt,
          ),
        ),
        gap,
        RecoveryStudentsPanel(
          anchorKey: _studentsKey,
          dashboard: _d,
          students: students,
          rule: question.rule,
          thresholdInCents: question.thresholdInCents,
          tab: _a.tab,
          search: _a.search,
          exportQuery: exportQuery,
          exportsEnabled: _online,
          exportsDisabledReason: _online
              ? null
              : l10n.recoveryExportsAwaitNetwork,
          feesLabel: _feesLabel(l10n),
          onRuleChanged: (rule) =>
              widget.onAddressChanged(_a.copyWith(rule: rule)),
          onThresholdChanged: _onAmount,
          onTabChanged: (tab) => widget.onAddressChanged(_a.copyWith(tab: tab)),
          onSearchChanged: (q) => widget.onAddressChanged(
            _a.copyWith(search: RecoveryDashboardAddress.cleanSearch(q)),
          ),
          onPageChanged: widget.onPageChanged,
          onFeesTapped: _openFees,
          onRetry: widget.onRetryList,
          onStudentTapped: (row) => openRecoveryStudentSheet(
            context,
            academicYearId: widget.academicYearId,
            studentId: row.studentId,
            displayName: row.displayName,
            classroomId: row.classroomId,
            feeCodes: _a.feeCodes,
          ),
        ),
        gap,
        RecoverySimulationPanel(
          dashboard: _d,
          rule: question.effectiveRule,
          thresholdInCents: question.thresholdInCents,
          unmanageableBelow: _a.unmanageableBelow,
          onUnmanageableChanged: (p) =>
              widget.onAddressChanged(_a.copyWith(unmanageableBelow: p)),
          onChangeRule: () {
            final target = _studentsKey.currentContext;
            if (target != null) Scrollable.ensureVisible(target);
          },
          onClassTapped: (row) => showRecoverySimulationCallList(
            context,
            academicYearId: widget.academicYearId,
            question: question,
            row: row,
            criterionLabel: recoveryCriterionLabel(
              question,
              l10n,
              currency: _d.currencies.length == 1 ? _d.currencies.single : null,
            ),
          ),
        ),
        gap,
        RecoveryInsightsRow(
          dashboard: _d,
          rankingFeeCode: _rankingValue,
          unmanageableBelow: _a.unmanageableBelow,
          onControlStudents: () =>
              _openControl(situation: StudentChargeStatus.due),
        ),
      ],
    );
  }
}
