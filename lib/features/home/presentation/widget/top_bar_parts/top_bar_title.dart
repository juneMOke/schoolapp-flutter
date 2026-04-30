import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isPreRegistrations
                ? Icons.assignment_outlined
                : Icons.dashboard_customize_outlined,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sidebarTitle.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              if (isPreRegistrations)
                Text(
                  l10n.homeTopBarPendingSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
