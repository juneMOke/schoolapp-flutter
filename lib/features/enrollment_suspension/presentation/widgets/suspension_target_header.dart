import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Qui le geste vise : un élève (avatar, nom, classe) ou une pile de quatre
/// avatars au plus et la liste des prénoms.
class SuspensionTargetHeader extends StatelessWidget {
  final List<SuspensionCandidate> candidates;

  const SuspensionTargetHeader({super.key, required this.candidates});

  static const double _singleAvatar = 40;
  static const int _pileMax = 4;
  static const double _pileAvatar = 34;
  static const double _pileOverlap = 10;
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final single = candidates.length == 1;
    final first = candidates.first;
    return Row(
      children: [
        if (single) _avatar(first, _singleAvatar) else _pile(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: single
                ? [
                    Text.rich(
                      TextSpan(
                        text: first.familyName,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${first.firstName}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMutedAa,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (first.classLabel != null)
                      Text(
                        l10n.suspensionClassLabel(first.classLabel!),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ]
                : [
                    Text(
                      l10n.suspensionStudentsSummary(
                        candidates.length,
                        candidates.map((c) => c.firstName).join(', '),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(SuspensionCandidate c, double size) => PersonAvatar(
    firstName: c.firstName,
    lastName: c.lastName,
    personId: c.studentId,
    studentPhotoOf: c.studentId,
    size: size,
  );

  Widget _pile() {
    final shown = candidates.take(_pileMax).toList();
    final rest = candidates.length - shown.length;
    final slots = shown.length + (rest > 0 ? 1 : 0);
    const step = _pileAvatar - _pileOverlap;
    return SizedBox(
      width: _pileAvatar + step * (slots - 1),
      height: _pileAvatar,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: _ringed(_avatar(shown[i], _pileAvatar - 2 * _ring)),
            ),
          if (rest > 0)
            Positioned(
              left: step * shown.length,
              child: _ringed(
                Container(
                  width: _pileAvatar - 2 * _ring,
                  height: _pileAvatar - 2 * _ring,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceAlt,
                  ),
                  child: Text(
                    '+$rest',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ringed(Widget child) => Container(
    padding: const EdgeInsets.all(_ring),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.surfaceRaised,
    ),
    child: child,
  );
}
