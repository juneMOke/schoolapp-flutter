import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';

/// Un bandeau du module RH ([EteeloNotice]) dans la teinte d'un statut de
/// pointage : ambre (retard) pour ce qui reste à faire, gris (à pointer) pour
/// ce qui est simplement dit, rouge (absent) pour l'irréversible.
class PresenceWarning extends StatelessWidget {
  final String message;
  final IconData icon;
  final PresenceStatus tone;

  const PresenceWarning({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = PresenceStatus.late,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PresenceTone.of(tone);
    return EteeloNotice.tinted(
      message: message,
      icon: icon,
      ink: colors.ink,
      background: colors.soft,
      border: colors.border,
    );
  }
}
