import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

extension StudentChargeStatusUiX on StudentChargeStatus {
  Color get badgeColor => switch (this) {
    StudentChargeStatus.due => AppColors.muted,
    StudentChargeStatus.partial => AppColors.warning,
    StudentChargeStatus.paid => AppColors.success,
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    StudentChargeStatus.due => l10n.studentChargeStatusDue,
    StudentChargeStatus.partial => l10n.studentChargeStatusPartial,
    StudentChargeStatus.paid => l10n.studentChargeStatusPaid,
  };
}
