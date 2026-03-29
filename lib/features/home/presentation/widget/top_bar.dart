import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            state.currentTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          actions: [
            _buildNotificationButton(),
            const SizedBox(width: 8),
            _buildProfileMenu(context),
            const SizedBox(width: AppTheme.defaultPadding),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return IconButton(
      onPressed: () {
        // TODO: Handle notifications
      },
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      onSelected: (value) {
        // TODO: Handle profile menu actions
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
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.logout, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ];
      },
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }
}
