import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_card.dart';

/// Le registre en grille de cartes.
class StaffAttendanceGrid extends StatelessWidget {
  final StaffDayRegister register;
  final StaffAttendanceSettings settings;

  const StaffAttendanceGrid({
    super.key,
    required this.register,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) => EteeloGridView(
    padding: EdgeInsets.zero,
    minItemWidth: AppDimensions.staffAttendanceCardMinWidth,
    itemCount: register.rows.length,
    itemBuilder: (context, index) => StaffAttendanceCard(
      key: ValueKey(register.rows[index].member.id),
      row: register.rows[index],
      settings: settings,
      frozen: register.frozen,
    ),
  );
}
