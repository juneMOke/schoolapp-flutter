import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart' as tokens;
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBarProfileMenuButton extends StatelessWidget {
  const TopBarProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.homeUserMenuTooltip,
      onSelected: (value) {
        switch (value) {
          case 'logout':
            context.read<AuthBloc>().add(const AuthLogoutRequested());
            break;
          case 'profile':
          case 'settings':
            // TODO: Handle profile/settings actions
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 8),
                Text(l10n.profile),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings_outlined),
                const SizedBox(width: 8),
                Text(l10n.settings),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, color: AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  l10n.logout,
                  style: AppTextStyles.body.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ),
        ];
      },
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: tokens.AppColors.bleuArdoise,
        child: Icon(Icons.person, color: tokens.AppColors.textOnDark, size: 20),
      ),
    );
  }
}
