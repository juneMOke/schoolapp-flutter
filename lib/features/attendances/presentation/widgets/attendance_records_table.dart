import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_records_mobile_list.dart';

enum AttendanceRecordsLayoutMode {
  cardsOnly,
  cardsWithDesktopDensity,
  dataTableLegacy,
}

class AttendanceRecordsTable extends StatelessWidget {
  static const AttendanceRecordsLayoutMode _layoutMode =
      AttendanceRecordsLayoutMode.cardsOnly;

  final List<AttendanceEditableRow> rows;
  final bool scrollable;

  const AttendanceRecordsTable({
    super.key,
    required this.rows,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardList = AttendanceRecordsMobileList(
      key: ValueKey('attendance-cards-${rows.length}-$scrollable'),
      rows: rows,
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
    );

    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: Container(
        key: ValueKey(_layoutMode.name),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingS),
        child: switch (_layoutMode) {
          AttendanceRecordsLayoutMode.cardsOnly => cardList,
          // Reserved for a denser desktop card treatment if we need it in v2.
          AttendanceRecordsLayoutMode.cardsWithDesktopDensity => cardList,
          // Reserved for quick rollback if table layout is requested again.
          AttendanceRecordsLayoutMode.dataTableLegacy => cardList,
        },
      ),
    );
  }
}
