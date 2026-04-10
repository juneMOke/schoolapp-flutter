import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';

class SidebarHeader extends StatelessWidget {
  final bool isExpanded;

  const SidebarHeader({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(isExpanded ? 12 : 8, 8, isExpanded ? 12 : 8, 0),
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 10 : 6,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: isExpanded
            ? const _ExpandedHeader()
            : const _CollapsedHeader(),
      ),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('expanded'),
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentBlue, AppTheme.accentIndigo],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ETEELO',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Replier le menu',
          onPressed: () => context.read<NavigationBloc>().add(const SidebarToggled()),
          icon: const Icon(Icons.menu_open_rounded, color: Colors.white70, size: 20),
        ),
      ],
    );
  }
}

class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('collapsed'),
      child: IconButton(
        tooltip: 'Etendre le menu',
        onPressed: () => context.read<NavigationBloc>().add(const SidebarToggled()),
        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
