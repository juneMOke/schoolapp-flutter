import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La teinte d'un profil de présence : liseré, anneau d'avatar, puce, badge.
///
/// Quatre profils empruntent la teinte du statut qu'ils résument — un
/// absentéiste est rouge comme une absence, un retardataire ambre comme un
/// retard — pour qu'une couleur garde un seul sens dans tout le module. Seul
/// « régulier » n'a pas de statut jumeau : il prend le bleu ardoise, la couleur
/// neutre des tableaux de bord.
class PresenceProfileTone {
  /// Teinte pleine (liseré, anneau).
  final Color color;

  /// Voile de fond (badge, puce active).
  final Color soft;
  final Color border;

  /// Encre d'un texte posé sur [soft].
  final Color ink;
  final IconData icon;

  const PresenceProfileTone._(
    this.color,
    this.soft,
    this.border,
    this.ink,
    this.icon,
  );

  factory PresenceProfileTone._of(PresenceStatus status, IconData icon) {
    final tone = PresenceTone.of(status);
    return PresenceProfileTone._(
      tone.color,
      tone.soft,
      tone.border,
      tone.ink,
      icon,
    );
  }

  static final PresenceProfileTone _notEvaluated = PresenceProfileTone._of(
    PresenceStatus.none,
    Icons.help_outline,
  );
  static final PresenceProfileTone _absentee = PresenceProfileTone._of(
    PresenceStatus.absent,
    Icons.cancel_outlined,
  );
  static final PresenceProfileTone _late = PresenceProfileTone._of(
    PresenceStatus.late,
    Icons.schedule,
  );
  static final PresenceProfileTone _exemplary = PresenceProfileTone._of(
    PresenceStatus.present,
    Icons.verified_outlined,
  );
  static const PresenceProfileTone _regular = PresenceProfileTone._(
    AppColors.presenceProfileRegular,
    AppColors.presenceProfileRegularSoft,
    AppColors.presenceProfileRegularBorder,
    AppColors.presenceProfileRegularInk,
    Icons.event_available_outlined,
  );

  static PresenceProfileTone of(PresenceProfile profile) => switch (profile) {
    PresenceProfile.notEvaluated => _notEvaluated,
    PresenceProfile.absentee => _absentee,
    PresenceProfile.late => _late,
    PresenceProfile.exemplary => _exemplary,
    PresenceProfile.regular => _regular,
  };
}
