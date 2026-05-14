import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarTitle extends StatelessWidget {
  final String title;
  final bool isPreRegistrations;

  const TopBarTitle({
    super.key,
    required this.title,
    required this.isPreRegistrations,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.bleuArdoise,
            borderRadius: AppRadius.brSm,
          ),
          child: Icon(
            isPreRegistrations
                ? Icons.assignment_outlined
                : Icons.dashboard_customize_outlined,
            size: 18,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sidebarTitle.copyWith(
                  color: AppColors.bleuArdoise,
                ),
              ),
              if (isPreRegistrations)
                Text(
                  l10n.homeTopBarPendingSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
