import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListStudentsTableHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final ClassesListStudentsSortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<ClassesListStudentsSortColumn> onSortChanged;

  const ClassesListStudentsTableHeader({
    super.key,
    required this.l10n,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.classesSectionSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.sectionCardRadius),
          topRight: Radius.circular(AppDimensions.sectionCardRadius),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: AppDimensions.minTouchTarget,
            child: Icon(
              Icons.person_outline_rounded,
              size: AppDimensions.detailMiniIconSize,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          _SortCell(
            label: l10n.lastName,
            column: ClassesListStudentsSortColumn.lastName,
            sortColumn: sortColumn,
            sortAscending: sortAscending,
            onSortChanged: onSortChanged,
          ),
          _SortCell(
            label: l10n.surname,
            column: ClassesListStudentsSortColumn.surname,
            sortColumn: sortColumn,
            sortAscending: sortAscending,
            onSortChanged: onSortChanged,
          ),
          _SortCell(
            label: l10n.firstName,
            column: ClassesListStudentsSortColumn.firstName,
            sortColumn: sortColumn,
            sortAscending: sortAscending,
            onSortChanged: onSortChanged,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          SizedBox(
            width: AppDimensions.minTouchTarget,
            child: Text(
              l10n.actions,
              textAlign: TextAlign.end,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassesListStudentsDataRow extends StatefulWidget {
  final ClassesListStudentRow row;
  final bool isEven;
  final ValueChanged<ClassesListStudentRow> onViewRequested;

  const ClassesListStudentsDataRow({
    super.key,
    required this.row,
    required this.isEven,
    required this.onViewRequested,
  });

  @override
  State<ClassesListStudentsDataRow> createState() =>
      _ClassesListStudentsDataRowState();
}

class _ClassesListStudentsDataRowState extends State<ClassesListStudentsDataRow> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const defaultColor = AppColors.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onViewRequested(widget.row),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.outCurve,
              color: (_isHovered || _isFocused)
                  ? AppColors.classesMemberSurface
                  : defaultColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              child: Row(
                children: [
                  StudentAvatar(
                    firstName: widget.row.firstName,
                    lastName: widget.row.lastName,
                    size: 32,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  _DataCell(
                    text: widget.row.lastName,
                    isStrong: true,
                  ),
                  _DataCell(text: widget.row.surname),
                  _DataCell(text: widget.row.firstName),
                  const SizedBox(width: AppDimensions.spacingS),
                  SizedBox(
                    width: AppDimensions.minTouchTarget,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: l10n.viewDetails,
                        onPressed: () => widget.onViewRequested(widget.row),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(
                            AppDimensions.minTouchTarget,
                            AppDimensions.minTouchTarget,
                          ),
                          foregroundColor: AppColors.indigo,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.remove_red_eye_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortCell extends StatelessWidget {
  final String label;
  final ClassesListStudentsSortColumn column;
  final ClassesListStudentsSortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<ClassesListStudentsSortColumn> onSortChanged;

  const _SortCell({
    required this.label,
    required this.column,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = column == sortColumn;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          onTap: () => onSortChanged(column),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tableHeader.copyWith(
                      color: isActive ? AppColors.indigo : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: Icon(
                    isActive
                        ? (sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded)
                        : Icons.unfold_more_rounded,
                    key: ValueKey<String>(
                      'sort-${column.name}-$isActive-$sortAscending',
                    ),
                    size: AppDimensions.detailMiniIconSize,
                    color: isActive ? AppColors.indigo : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool isStrong;

  const _DataCell({required this.text, this.isStrong = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: (isStrong ? AppTextStyles.bodyStrong : AppTextStyles.body)
            .copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

enum ClassesListStudentsSortColumn { lastName, surname, firstName }