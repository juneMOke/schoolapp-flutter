import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Pavé numérique 3×4 du mode Focus (spec §9) : 7-8-9 / 4-5-6 / 1-2-3 /
/// virgule-0-retour. Cibles 52 dp (tablette). [onChar] reçoit un chiffre ou une
/// virgule ; la touche retour appelle [onBackspace].
class SaisieNumpad extends StatelessWidget {
  final ValueChanged<String> onChar;
  final VoidCallback onBackspace;
  final bool enabled;

  const SaisieNumpad({
    super.key,
    required this.onChar,
    required this.onBackspace,
    this.enabled = true,
  });

  static const List<List<String>> _rows = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    [',', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _rows.length; r++) ...[
          Row(
            children: [
              for (var c = 0; c < _rows[r].length; c++) ...[
                Expanded(child: _key(_rows[r][c])),
                if (c < _rows[r].length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          if (r < _rows.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _key(String value) {
    final isBackspace = value == '⌫';
    return _NumpadKey(
      isBackspace: isBackspace,
      enabled: enabled,
      onTap: enabled ? () => isBackspace ? onBackspace() : onChar(value) : null,
      child: isBackspace
          ? const Icon(
              Icons.backspace_outlined,
              size: 18,
              color: AppColors.textPrimary,
            )
          : Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final Widget child;
  final bool isBackspace;
  final bool enabled;
  final VoidCallback? onTap;

  const _NumpadKey({
    required this.child,
    required this.isBackspace,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: isBackspace ? AppColors.surfaceAlt : AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
