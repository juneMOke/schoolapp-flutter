import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

/// Six apparences, la légende les reprend. [CoteCellLook.of] colore le chiffre
/// selon `scoreInk` ; une frappe hors barème garde son rouge d'erreur.
class CoteCellLook {
  final Color surface;
  final Color border;
  final Color ink;
  final double borderWidth;
  final bool dashed;

  const CoteCellLook({
    required this.surface,
    required this.border,
    required this.ink,
    this.borderWidth = 1,
    this.dashed = false,
  });

  factory CoteCellLook.of({
    required CoteCell? cell,
    required CoteColumn column,
    required bool focused,
    required bool changed,
    required bool empty,
    Color? scoreInk,
  }) {
    final exam = column.isExamen;
    if (cell?.isInvalid ?? false) {
      return const CoteCellLook(
        surface: AppColors.coteInvalidSurface,
        border: AppColors.error,
        ink: AppColors.error,
        borderWidth: 1.5,
      );
    }
    if (focused) {
      return CoteCellLook(
        surface: AppColors.surfaceRaised,
        border: AppColors.bleuArdoise,
        ink: scoreInk ?? AppColors.bleuProfond,
        borderWidth: 1.5,
      );
    }
    if (changed) {
      return CoteCellLook(
        surface: AppColors.coteChangedSurface,
        border: AppColors.warning,
        ink: scoreInk ?? AppColors.bleuProfond,
        borderWidth: 1.5,
      );
    }
    if (empty) {
      return const CoteCellLook(
        surface: AppColors.coteEmptySurface,
        border: AppColors.coteEmptyBorder,
        ink: AppColors.textMuted,
        dashed: true,
      );
    }
    final surface = exam ? AppColors.coteExamSurface : AppColors.surfaceRaised;
    final border = exam ? AppColors.coteExamBorder : AppColors.coteCellBorder;
    if (cell?.isCalculated ?? false) {
      return CoteCellLook(
        surface: surface,
        border: border,
        ink: scoreInk ?? AppColors.textSecondary,
        dashed: true,
      );
    }
    return CoteCellLook(
      surface: surface,
      border: border,
      ink: scoreInk ?? (exam ? AppColors.coteExamInk : AppColors.bleuProfond),
    );
  }
}
