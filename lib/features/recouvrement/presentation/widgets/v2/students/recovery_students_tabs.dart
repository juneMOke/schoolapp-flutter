import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_tab_body.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';

/// Un onglet de la liste : titre, compteur et sous-ligne.
typedef RecoveryStudentsTabData = ({
  RecoveryTab tab,
  IconData icon,
  String title,
  int? count,
  String? subtitle,
});

/// Les trois onglets collés à la liste (R9) : l'actif porte un filet de 4 dp
/// de sa couleur et se prolonge dans le cadre teinté de la liste. La
/// sous-ligne se masque sous 600 reçus ([narrow]). Flèches au clavier.
///
/// Écart assumé à `EteeloCardTabs` : sa carte active est un bandeau sombre ;
/// la maquette (`RecSituationPanel`) veut un onglet clair qui se prolonge
/// dans la liste — et le socle ne se modifie pas depuis un module.
class RecoveryStudentsTabs extends StatefulWidget {
  final List<RecoveryStudentsTabData> tabs;
  final RecoveryTab active;
  final bool narrow;
  final ValueChanged<RecoveryTab> onSelect;

  const RecoveryStudentsTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.narrow,
    required this.onSelect,
  });

  @override
  State<RecoveryStudentsTabs> createState() => _RecoveryStudentsTabsState();
}

class _RecoveryStudentsTabsState extends State<RecoveryStudentsTabs> {
  final _nodes = {
    for (final t in RecoveryTab.values) t: FocusNode(debugLabel: t.wire),
  };

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(RecoveryTab from, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final step = key == LogicalKeyboardKey.arrowRight
        ? 1
        : key == LogicalKeyboardKey.arrowLeft
        ? -1
        : 0;
    if (step == 0) return KeyEventResult.ignored;
    final order = [for (final t in widget.tabs) t.tab];
    final next = order[(order.indexOf(from) + step) % order.length];
    _nodes[next]!.requestFocus();
    widget.onSelect(next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.recoverySpace6,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: widget.narrow ? AppSpacing.xs : AppDimensions.recoverySpace6,
      children: [
        for (final t in widget.tabs)
          Expanded(
            flex: t.tab == RecoveryTab.all ? 7 : 10,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (_, event) => _onKey(t.tab, event),
              child: _Tab(
                data: t,
                active: t.tab == widget.active,
                narrow: widget.narrow,
                focusNode: _nodes[t.tab]!,
                onTap: () => widget.onSelect(t.tab),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  final RecoveryStudentsTabData data;
  final bool active;
  final bool narrow;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _Tab({
    required this.data,
    required this.active,
    required this.narrow,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = RecoveryStudentsTones.of(data.tab);
    final sub = data.subtitle;
    return Semantics(
      selected: active,
      child: EteeloActivatable(
        focusNode: focusNode,
        semanticLabel: [
          data.title,
          if (data.count != null) '${data.count}',
          ?sub,
        ].join(' · '),
        onActivate: onTap,
        // ⚠️ Un rayon et une bordure de couleurs différentes ne se peignent
        // pas : le filet est une bande, rognée par le rayon.
        builder: (context, highlight) => Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: AppRadius.md),
            color: active
                ? RecoveryStudentsTones.soft(tone)
                : DashboardTones.teinte(
                    tone,
                    RecoveryStudentsTones.idleTabPercent,
                  ),
          ),
          foregroundDecoration: highlight.focused
              ? BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: AppRadius.md),
                  border: Border.all(
                    color: AppColors.bleuArdoise,
                    width: AppDimensions.focusRingWidth,
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppDimensions.recoveryStudentsTabRule,
                child: ColoredBox(color: active ? tone : Colors.transparent),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  narrow ? AppDimensions.recoverySpace10 : AppSpacing.gridGap,
                  narrow
                      ? AppDimensions.recoverySpace9
                      : AppDimensions.recoverySpace10,
                  narrow ? AppDimensions.recoverySpace10 : AppSpacing.gridGap,
                  narrow
                      ? AppDimensions.recoverySpace10
                      : AppDimensions.recoverySpace11,
                ),
                child: RecoveryStudentsTabBody(
                  data: data,
                  active: active,
                  narrow: narrow,
                  tone: tone,
                  subtitle: sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
