import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_card_tabs.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La teinte d'un statut de présence, réutilisée partout où il s'affiche :
/// carte, ligne, puce de filtre, calendrier, pastille.
class PresenceTone {
  /// Teinte pleine (médaillon, bordure, segment actif).
  final Color color;

  /// Voile de fond.
  final Color soft;
  final Color border;

  /// Encre d'un texte posé sur [soft].
  final Color ink;
  final IconData icon;

  const PresenceTone._(this.color, this.soft, this.border, this.ink, this.icon);

  static const PresenceTone _none = PresenceTone._(
    AppColors.presenceMarkNone,
    AppColors.presenceMarkNoneSoft,
    AppColors.presenceMarkNoneBorder,
    AppColors.presenceMarkNoneInk,
    Icons.back_hand_outlined,
  );
  static const PresenceTone _present = PresenceTone._(
    AppColors.presenceMarkPresent,
    AppColors.presenceMarkPresentSoft,
    AppColors.presenceMarkPresentBorder,
    AppColors.presenceMarkPresentInk,
    Icons.check_circle_outline,
  );
  static const PresenceTone _late = PresenceTone._(
    AppColors.presenceMarkLate,
    AppColors.presenceMarkLateSoft,
    AppColors.presenceMarkLateBorder,
    AppColors.presenceMarkLateInk,
    Icons.schedule,
  );
  static const PresenceTone _absent = PresenceTone._(
    AppColors.presenceMarkAbsent,
    AppColors.presenceMarkAbsentSoft,
    AppColors.presenceMarkAbsentBorder,
    AppColors.presenceMarkAbsentInk,
    Icons.cancel_outlined,
  );

  /// Un badge d'onglet à cette teinte.
  EteeloTabBadge badge(String label) => (label: label, soft: soft, ink: ink);

  static PresenceTone of(PresenceStatus status) => switch (status) {
    PresenceStatus.none => _none,
    PresenceStatus.present => _present,
    PresenceStatus.late => _late,
    PresenceStatus.absent => _absent,
  };
}
