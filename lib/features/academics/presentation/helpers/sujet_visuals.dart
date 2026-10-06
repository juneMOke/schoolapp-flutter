import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';

/// Tonalité du barème (spec S4) : neutre, ambre, vert, rouge.
({Color color, Color soft, IconData icon}) baremeVisual(BaremeStatus status) =>
    switch (status) {
      BaremeStatus.empty => (
        color: AppColors.textMuted,
        soft: AppColors.surfaceAlt,
        icon: Icons.info_outline_rounded,
      ),
      BaremeStatus.under => (
        color: AppColors.academicsScoreWeak,
        soft: AppColors.academicsScoreWeakSoft,
        icon: Icons.error_outline_rounded,
      ),
      BaremeStatus.complete => (
        color: AppColors.academicsScoreGood,
        soft: AppColors.academicsScoreGoodSoft,
        icon: Icons.check_circle_outline_rounded,
      ),
      BaremeStatus.over => (
        color: AppColors.academicsScoreFail,
        soft: AppColors.academicsScoreFailSoft,
        icon: Icons.warning_amber_rounded,
      ),
    };
