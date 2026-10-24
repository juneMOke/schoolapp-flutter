import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_profile_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

void main() {
  test('chaque profil a sa propre teinte', () {
    final colors = PresenceProfile.values
        .map((profile) => PresenceProfileTone.of(profile).color)
        .toSet();
    expect(colors, hasLength(PresenceProfile.values.length));
  });

  test('un profil jumeau d’un statut en reprend la teinte', () {
    const twins = {
      PresenceProfile.notEvaluated: PresenceStatus.none,
      PresenceProfile.absentee: PresenceStatus.absent,
      PresenceProfile.late: PresenceStatus.late,
      PresenceProfile.exemplary: PresenceStatus.present,
    };
    for (final MapEntry(key: profile, value: status) in twins.entries) {
      final tone = PresenceProfileTone.of(profile);
      final twin = PresenceTone.of(status);
      expect(
        [tone.color, tone.soft, tone.border, tone.ink],
        [twin.color, twin.soft, twin.border, twin.ink],
        reason: profile.name,
      );
    }
  });

  test('« régulier » prend le bleu ardoise', () {
    expect(
      PresenceProfileTone.of(PresenceProfile.regular).color,
      AppColors.bleuArdoise,
    );
  });

  test('l’encre de chaque profil tient 4,5:1 sur son voile', () {
    for (final profile in PresenceProfile.values) {
      final tone = PresenceProfileTone.of(profile);
      expect(
        DashboardTones.contraste(tone.ink, tone.soft),
        greaterThanOrEqualTo(DashboardTones.seuilTexte),
        reason: profile.name,
      );
    }
  });
}
