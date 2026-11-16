import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'autorisation « Appareils à proximité » : accordée, ou ce qui manque et
/// comment l'obtenir.
class TicketPrinterPermissionSection extends StatelessWidget {
  final Set<NearbyPermission> missing;
  final bool blocked;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  const TicketPrinterPermissionSection({
    super.key,
    required this.missing,
    required this.blocked,
    required this.onAllow,
    required this.onOpenSettings,
  });

  /// Les noms Android, tels que l'administrateur les retrouve dans sa console.
  static String androidName(NearbyPermission permission) =>
      switch (permission) {
        NearbyPermission.connect => 'BLUETOOTH_CONNECT',
        NearbyPermission.scan => 'BLUETOOTH_SCAN',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final granted = missing.isEmpty;
    return EteeloPanelCard(
      title: l10n.ticketPrinterPermissionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                granted ? Icons.check_circle_outline : Icons.error_outline,
                color: granted ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  granted
                      ? l10n.ticketPrinterPermissionGranted
                      : l10n.ticketPrinterPermissionMissing(
                          missing.map(androidName).join(', '),
                        ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (!granted) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                // Refusée définitivement, Android n'affiche plus rien : le
                // bouton qui redemanderait ne ferait rien.
                if (!blocked)
                  EteeloButton.primary(
                    label: l10n.ticketPrinterPermissionAllow,
                    icon: Icons.bluetooth,
                    onPressed: onAllow,
                    fullWidth: false,
                  ),
                EteeloButton.secondary(
                  label: l10n.ticketPrinterPermissionOpenSettings,
                  icon: Icons.settings_outlined,
                  onPressed: onOpenSettings,
                  fullWidth: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.ticketPrinterPermissionManagedHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
