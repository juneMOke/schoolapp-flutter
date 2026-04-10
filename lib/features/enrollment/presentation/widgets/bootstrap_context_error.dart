import 'package:flutter/material.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class BootstrapContextError extends StatelessWidget {
  final VoidCallback onLogout;

  const BootstrapContextError({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.bootstrapContextUnavailableTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.bootstrapContextUnavailableMessage,
              style: const TextStyle(height: 1.45, color: Color(0xFF991B1B)),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.signOutAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
