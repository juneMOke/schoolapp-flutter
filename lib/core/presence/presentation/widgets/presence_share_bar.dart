import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';

/// La barre tricolore d'une ligne : à l'heure, en retard, absent, en part
/// des jours pointés. Sans pointage, la piste seule. La version compacte de
/// `EteeloSplitBar`, sans légende : la ligne écrit ses taux à côté.
class PresenceShareBar extends StatelessWidget {
  final int onTimePct;
  final int latePct;
  final int absentPct;

  /// La phrase qui porte les trois taux pour le lecteur d'écran ; `null`
  /// quand les taux sont déjà écrits à côté — la barre se tait alors.
  final String? semanticsLabel;

  const PresenceShareBar({
    super.key,
    required this.onTimePct,
    required this.latePct,
    required this.absentPct,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final none = PresenceTone.of(PresenceStatus.none);
    final segments = [
      (onTimePct, PresenceTone.of(PresenceStatus.present).color),
      (latePct, PresenceTone.of(PresenceStatus.late).color),
      (absentPct, PresenceTone.of(PresenceStatus.absent).color),
    ].where((segment) => segment.$1 > 0).toList();
    final label = semanticsLabel;
    final bar = ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppDimensions.presenceShareBarHeight / 2),
      ),
      child: SizedBox(
        height: AppDimensions.presenceShareBarHeight,
        child: segments.isEmpty
            ? ColoredBox(color: none.soft)
            // `stretch` : un ColoredBox sans enfant prend la plus petite
            // hauteur permise — sans elle, les segments faisaient 0 dp.
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (share, color) in segments)
                    Expanded(
                      flex: share,
                      child: ColoredBox(color: color),
                    ),
                ],
              ),
      ),
    );
    return label == null
        ? ExcludeSemantics(child: bar)
        : Semantics(label: label, excludeSemantics: true, child: bar);
  }
}
