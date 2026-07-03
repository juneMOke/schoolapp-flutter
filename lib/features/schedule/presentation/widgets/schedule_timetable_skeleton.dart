import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Squelette de chargement (spec §9) : grille fantôme qui **préserve la mise en
/// page** (en-tête + lignes, cases éparses). Région live (`role=status`) et
/// respect du mouvement réduit hérité d'[EteeloSkeletonBox].
class ScheduleTimetableSkeleton extends StatelessWidget {
  static const int _dayCount = 5;
  static const int _rowCount = 5;
  static const double _gutter = 52;

  const ScheduleTimetableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.scheduleLoadingSemantics,
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _headerRow(),
              for (var i = 0; i < _rowCount; i++) _bodyRow(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: _gutter),
          for (var d = 0; d < _dayCount; d++)
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EteeloSkeletonBox(width: 44, height: 10),
                    SizedBox(height: 6),
                    EteeloSkeletonBox(width: 28, height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bodyRow(int index) {
    // Cases éparses : une poignée de créneaux occupés, en quinconce.
    bool filled(int day) => (day + index) % 3 == 0;

    // IntrinsicHeight borne la hauteur de la ligne (sinon `stretch` force une
    // hauteur infinie dans le Column scrollable) — même garde que la vraie grille.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            width: _gutter,
            height: 54,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: EteeloSkeletonBox(width: 28, height: 9),
              ),
            ),
          ),
          for (var d = 0; d < _dayCount; d++)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: filled(d)
                    ? const EteeloSkeletonBox(
                        height: 40,
                        borderRadius: AppRadius.brSm,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
