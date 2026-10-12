import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/helpers/initials_helper.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/audience_student_search_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/communication_failure_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mode « Élèves » : une recherche (deux lettres au moins, huit
/// résultats), et les élèves retenus en pastilles.
class StudentSelector extends StatefulWidget {
  final List<AudienceStudent> selected;
  final ValueChanged<AudienceStudent>? onAdd;
  final ValueChanged<String>? onRemove;

  const StudentSelector({
    super.key,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<StudentSelector> createState() => _StudentSelectorState();
}

class _StudentSelectorState extends State<StudentSelector> {
  /// Repart de la recherche en cours : revenir au mode « Élèves » montre la
  /// requête qui a produit les résultats affichés.
  late final _query = TextEditingController(
    text: context.read<AudienceStudentSearchCubit>().state.query,
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _pick(AudienceStudent student) {
    widget.onAdd?.call(student);
    _query.clear();
    context.read<AudienceStudentSearchCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remove = widget.onRemove;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloTextInput(
          controller: _query,
          label: l10n.communicationStudentSearchLabel,
          placeholder: l10n.communicationStudentSearchPlaceholder,
          enabled: widget.onAdd != null,
          // Un nom cherché se tape tel quel : aucune majuscule imposée.
          capitalization: EteeloTextCapitalization.none,
          prefix: const Icon(Icons.search, size: 18),
          onChanged: context.read<AudienceStudentSearchCubit>().search,
        ),
        BlocBuilder<AudienceStudentSearchCubit, AudienceStudentSearchState>(
          builder: (context, state) => _Results(
            state: state,
            selectedIds: {for (final s in widget.selected) s.id},
            onPick: _pick,
          ),
        ),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final student in widget.selected)
                InputChip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.bleuArdoiseSoft,
                    child: Text(
                      InitialsHelper.initialsFromName(student.displayName),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.bleuArdoise,
                      ),
                    ),
                  ),
                  label: Text(_chipLabel(l10n, student)),
                  onDeleted: remove == null ? null : () => remove(student.id),
                  deleteButtonTooltipMessage: l10n.communicationStudentRemove,
                ),
            ],
          ),
        ],
      ],
    );
  }

  static String _chipLabel(AppLocalizations l10n, AudienceStudent student) {
    final name = student.displayName.isEmpty
        ? l10n.communicationStudentUnnamed
        : student.displayName;
    final room = student.classroomLabel;
    return room == null ? name : l10n.communicationJoin(name, room);
  }
}

class _Results extends StatelessWidget {
  final AudienceStudentSearchState state;
  final Set<String> selectedIds;
  final ValueChanged<AudienceStudent> onPick;

  const _Results({
    required this.state,
    required this.selectedIds,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.tooShort) return const SizedBox.shrink();
    final failure = state.failure;
    final message = state.loading
        ? l10n.communicationStudentSearching
        : failure != null
        ? l10n.communicationStudentSearchFailed(l10n.failureReason(failure))
        : state.results.isEmpty
        ? l10n.communicationStudentNoMatch(state.query.trim())
        : null;
    if (message != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Semantics(
          liveRegion: true,
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          for (final student in state.results)
            ListTile(
              minTileHeight: AppDimensions.communicationStudentRowMinHeight,
              enabled: !selectedIds.contains(student.id),
              title: Text(student.displayName),
              subtitle: student.classroomLabel == null
                  ? null
                  : Text(student.classroomLabel!),
              trailing: selectedIds.contains(student.id)
                  ? const Icon(Icons.check, color: AppColors.feeStatusPaid)
                  : const Icon(Icons.add),
              onTap: () => onPick(student),
            ),
        ],
      ),
    );
  }
}
