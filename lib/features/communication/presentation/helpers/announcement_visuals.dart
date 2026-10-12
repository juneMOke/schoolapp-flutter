import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';

/// Une encre, le fond qu'elle habille et une icône. Champs **nommés** : un
/// enregistrement positionnel de couleurs se lirait de travers au premier
/// changement d'ordre.
typedef AnnouncementTone = ({Color ink, Color soft, IconData icon});

/// Les teintes de catégorie, alignées sur les statuts existants : aucune
/// couleur neuve.
AnnouncementTone categoryTone(AnnouncementCategory category) =>
    switch (category) {
      AnnouncementCategory.info => (
        ink: AppColors.bleuArdoise,
        soft: AppColors.bleuArdoiseSoft,
        icon: Icons.info_outline,
      ),
      AnnouncementCategory.urgent => (
        ink: AppColors.feeStatusDue,
        soft: AppColors.feeStatusDueSoft,
        icon: Icons.priority_high,
      ),
      AnnouncementCategory.event => (
        ink: AppColors.feeStatusPaid,
        soft: AppColors.feeStatusPaidSoft,
        icon: Icons.event_outlined,
      ),
      AnnouncementCategory.administrative => (
        ink: AppColors.terreCuiteDark,
        soft: AppColors.terreCuiteSoft,
        icon: Icons.description_outlined,
      ),
    };

AnnouncementTone statusTone(AnnouncementStatus status) => switch (status) {
  AnnouncementStatus.draft => (
    ink: AppColors.textMuted,
    soft: AppColors.surfaceAlt,
    icon: Icons.edit_note,
  ),
  AnnouncementStatus.scheduled => (
    ink: AppColors.bleuArdoise,
    soft: AppColors.bleuArdoiseSoft,
    icon: Icons.schedule_send_outlined,
  ),
  AnnouncementStatus.sent => (
    ink: AppColors.feeStatusPaid,
    soft: AppColors.feeStatusPaidSoft,
    icon: Icons.done_all,
  ),
  AnnouncementStatus.failed => (
    ink: AppColors.feeStatusDue,
    soft: AppColors.feeStatusDueSoft,
    icon: Icons.error_outline,
  ),
  AnnouncementStatus.cancelled => (
    ink: AppColors.textMuted,
    soft: AppColors.surfaceAlt,
    icon: Icons.block,
  ),
};
