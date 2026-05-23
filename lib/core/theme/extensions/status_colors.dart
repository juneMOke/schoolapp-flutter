import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color paid;
  final Color partial;
  final Color overdue;
  final Color cancelled;

  final Color present;
  final Color absentJustified;
  final Color absentUnjustified;

  final Color synced;
  final Color syncing;
  final Color offline;
  final Color pendingUpload;
  final Color syncConflict;

  const StatusColors({
	required this.paid,
	required this.partial,
	required this.overdue,
	required this.cancelled,
	required this.present,
	required this.absentJustified,
	required this.absentUnjustified,
	required this.synced,
	required this.syncing,
	required this.offline,
	required this.pendingUpload,
	required this.syncConflict,
  });

  static const light = StatusColors(
	paid: AppColors.success,
	partial: AppColors.warning,
	overdue: AppColors.error,
	cancelled: AppColors.textMuted,
	present: AppColors.success,
	absentJustified: AppColors.warning,
	absentUnjustified: AppColors.error,
	synced: AppColors.success,
	syncing: AppColors.info,
	offline: AppColors.textMuted,
	pendingUpload: AppColors.warning,
	syncConflict: AppColors.error,
  );

  @override
  StatusColors copyWith({
	Color? paid,
	Color? partial,
	Color? overdue,
	Color? cancelled,
	Color? present,
	Color? absentJustified,
	Color? absentUnjustified,
	Color? synced,
	Color? syncing,
	Color? offline,
	Color? pendingUpload,
	Color? syncConflict,
  }) {
	return StatusColors(
	  paid: paid ?? this.paid,
	  partial: partial ?? this.partial,
	  overdue: overdue ?? this.overdue,
	  cancelled: cancelled ?? this.cancelled,
	  present: present ?? this.present,
	  absentJustified: absentJustified ?? this.absentJustified,
	  absentUnjustified: absentUnjustified ?? this.absentUnjustified,
	  synced: synced ?? this.synced,
	  syncing: syncing ?? this.syncing,
	  offline: offline ?? this.offline,
	  pendingUpload: pendingUpload ?? this.pendingUpload,
	  syncConflict: syncConflict ?? this.syncConflict,
	);
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
	if (other is! StatusColors) {
	  return this;
	}

	return StatusColors(
	  paid: Color.lerp(paid, other.paid, t) ?? paid,
	  partial: Color.lerp(partial, other.partial, t) ?? partial,
	  overdue: Color.lerp(overdue, other.overdue, t) ?? overdue,
	  cancelled: Color.lerp(cancelled, other.cancelled, t) ?? cancelled,
	  present: Color.lerp(present, other.present, t) ?? present,
	  absentJustified:
		  Color.lerp(absentJustified, other.absentJustified, t) ?? absentJustified,
	  absentUnjustified: Color.lerp(
		absentUnjustified,
		other.absentUnjustified,
		t,
	  ) ??
	  absentUnjustified,
	  synced: Color.lerp(synced, other.synced, t) ?? synced,
	  syncing: Color.lerp(syncing, other.syncing, t) ?? syncing,
	  offline: Color.lerp(offline, other.offline, t) ?? offline,
	  pendingUpload: Color.lerp(pendingUpload, other.pendingUpload, t) ?? pendingUpload,
	  syncConflict: Color.lerp(syncConflict, other.syncConflict, t) ?? syncConflict,
	);
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get statusColors =>
	  Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}
