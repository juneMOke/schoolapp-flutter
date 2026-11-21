import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Qui tient l'année quand le calendrier publié prend le relais (CAL-R10).
typedef PublishRelay = ({String current, String end, String start});

/// O5 — publier (CAL-R10), en confirmation centrée à tous les formats
/// (`AppConfirmationDialog`, A16) : le décompte, puis ce qui bloque (pas de
/// cadre, hors ligne, envois en attente) ou l'avertissement « à vérifier »,
/// qui verra le calendrier et quand il prend le relais. Rend `true` pour
/// publier ; « Publier » est inactif s'il y a un blocage.
class PublishCalendarDialog extends StatelessWidget {
  final String year;
  final int total;
  final int schoolCount;
  final int toVerify;
  final bool hasFramework;
  final bool online;
  final bool pending;

  /// L'année en vigueur qui le reste jusqu'à sa fin ; `null` s'il n'y en a
  /// pas d'autre.
  final PublishRelay? relay;

  const PublishCalendarDialog({
    super.key,
    required this.year,
    required this.total,
    required this.schoolCount,
    required this.toVerify,
    required this.hasFramework,
    required this.online,
    required this.pending,
    this.relay,
  });

  static Future<bool> show(
    BuildContext context,
    PublishCalendarDialog dialog,
  ) => showDialog<bool>(
    context: context,
    builder: (_) => dialog,
  ).then((ok) => ok ?? false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = !hasFramework || !online || pending;
    final relay = this.relay;
    Widget gap(Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: child,
    );
    return AppConfirmationDialog(
      title: l10n.schoolCalendarPublishTitle(year),
      message:
          '${l10n.schoolCalendarPublishSummary(total, schoolCount)} · '
          '${l10n.schoolCalendarPublishFramework(hasFramework ? 'yes' : 'no')}',
      confirmLabel: l10n.schoolCalendarPublish,
      cancelLabel: l10n.schoolCalendarFormCancel,
      headerIcon: Icons.send_rounded,
      headerIconColor: AppColors.terreCuite,
      headerIconBackgroundColor: AppColors.terreCuiteSoft,
      confirmIcon: Icons.send_rounded,
      confirmButtonColor: AppColors.terreCuite,
      confirmEnabled: !blocked,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasFramework)
            EteeloNotice.error(l10n.schoolCalendarPublishNoFramework(year)),
          if (!online) EteeloNotice.error(l10n.schoolCalendarPublishOffline),
          if (pending) EteeloNotice.error(l10n.schoolCalendarPublishPending),
          if (toVerify > 0)
            EteeloNotice.warning(l10n.schoolCalendarPublishToVerify(toVerify)),
          gap(
            Text(
              [
                l10n.schoolCalendarPublishAudience,
                if (relay != null)
                  l10n.schoolCalendarPublishRelay(
                    relay.current,
                    relay.end,
                    year,
                    relay.start,
                  ),
                l10n.schoolCalendarPublishReference,
              ].join(' '),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
