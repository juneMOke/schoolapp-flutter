import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_classroom_select.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_fee_picker_field.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_perimeter_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc A du tableau de bord : « Quels frais analyser ? », le périmètre
/// (tout l'établissement, un cycle, une classe — la recherche du socle s'ouvre
/// dès 8 options),
/// puis « {n} élèves · tous les chiffres de la page portent sur ces frais ».
///
/// Même barre que le contrôle des frais (`RecouvrementPerimeterBar`) : la
/// page entière porte sur ce sujet.
class RecoveryDashboardPerimeter extends StatelessWidget {
  final List<FeeNature> natures;
  final List<String> feeCodes;
  final FeeSectionTitlesState titles;
  final List<SchoolLevelGroupBundle> groups;
  final List<OfflineClassroom> classrooms;
  final RecoveryScopeKind scope;
  final String? scopeId;

  /// Élèves du périmètre portant au moins un frais retenu ; `null` tant que
  /// le serveur n'a pas répondu.
  final int? studentCount;
  final bool enabled;
  final ValueChanged<List<String>> onFeesChanged;
  final void Function(RecoveryScopeKind scope, String? scopeId) onScopeChanged;

  const RecoveryDashboardPerimeter({
    super.key,
    required this.natures,
    required this.feeCodes,
    required this.titles,
    required this.groups,
    required this.classrooms,
    required this.scope,
    required this.scopeId,
    required this.studentCount,
    required this.onFeesChanged,
    required this.onScopeChanged,
    this.enabled = true,
  });

  static const _school = 'school';
  static const _cyclePrefix = 'cycle:';
  static const _classPrefix = 'classe:';

  String get _value => switch (scope) {
    RecoveryScopeKind.school => _school,
    RecoveryScopeKind.cycle => '$_cyclePrefix$scopeId',
    RecoveryScopeKind.classroom => '$_classPrefix$scopeId',
  };

  void _onSelected(String? value) {
    if (value == null || value == _school) {
      onScopeChanged(RecoveryScopeKind.school, null);
    } else if (value.startsWith(_cyclePrefix)) {
      onScopeChanged(
        RecoveryScopeKind.cycle,
        value.substring(_cyclePrefix.length),
      );
    } else if (value.startsWith(_classPrefix)) {
      onScopeChanged(
        RecoveryScopeKind.classroom,
        value.substring(_classPrefix.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycleName = {for (final g in groups) g.group.id: g.group.name};
    final orderedGroups = [...groups]
      ..sort((a, b) => a.group.displayOrder.compareTo(b.group.displayOrder));
    final items = <EteeloSelectItem<String>>[
      EteeloSelectItem(value: _school, label: l10n.recouvrementScopeAll),
      for (final g in orderedGroups)
        EteeloSelectItem(
          value: '$_cyclePrefix${g.group.id}',
          label: l10n.recoveryScopeCycle(g.group.name),
        ),
      for (final c in FeeControlClassroomSelect.ordered(classrooms, groups))
        EteeloSelectItem(
          value: '$_classPrefix${c.id}',
          label: cycleName[c.schoolLevelGroupId] == null
              ? c.name
              : '${c.name} · ${cycleName[c.schoolLevelGroupId]}',
          searchTerms: c.name,
        ),
    ];
    final known = items.any((i) => i.value == _value);

    return LayoutBuilder(
      builder: (context, constraints) => RecouvrementPerimeterBar(
        fees: RecouvrementFeePickerField(
          natures: natures,
          selected: feeCodes,
          titles: titles,
          sheetTitle: l10n.recouvrementFeesQuestion,
          narrow: constraints.maxWidth < AppBreakpoints.dataTableCardsMax,
          enabled: enabled && natures.isNotEmpty,
          onChanged: onFeesChanged,
        ),
        scope: EteeloSelectInput<String>(
          label: l10n.recouvrementScopeLabel,
          value: known ? _value : _school,
          enabled: enabled,
          onChanged: _onSelected,
          items: items,
        ),
        footer: studentCount == null
            ? null
            : Text(
                l10n.recoveryPerimeterFooter(studentCount!),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}
