import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'application de secours, montée à la place de l'application quand
/// `device.db` ne s'ouvre plus sous sa clé.
///
/// Elle vit HORS de l'injection : celle-ci a échoué à mi-chemin, rien de ce
/// qu'elle enregistre n'est utilisable. D'où ses propres `MaterialApp`,
/// thème et traductions.
///
/// Deux sorties, et le choix revient à l'utilisateur : réessayer — un
/// trousseau verrouillé se déverrouille, et les données reviennent intactes —
/// ou effacer, après confirmation, puisque les écritures pas encore parties
/// sont perdues.
class LocalDataRecoveryApp extends StatelessWidget {
  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  const LocalDataRecoveryApp({
    super.key,
    required this.onRetry,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    home: LocalDataRecoveryPage(onRetry: onRetry, onReset: onReset),
  );
}

class LocalDataRecoveryPage extends StatefulWidget {
  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  const LocalDataRecoveryPage({
    super.key,
    required this.onRetry,
    required this.onReset,
  });

  @override
  State<LocalDataRecoveryPage> createState() => _LocalDataRecoveryPageState();
}

class _LocalDataRecoveryPageState extends State<LocalDataRecoveryPage> {
  bool _busy = false;
  bool _resetFailed = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      // Réussie, l'action remplace l'application entière : cet écran n'est
      // déjà plus monté.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.localDataRecoveryConfirmTitle),
        content: Text(l10n.localDataRecoveryConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.localDataRecoveryConfirmCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.localDataRecoveryConfirmErase),
          ),
        ],
      ),
    );
    if (!mounted || !(confirmed ?? false)) return;
    await _run(() async {
      try {
        await widget.onReset();
      } catch (_) {
        if (mounted) setState(() => _resetFailed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: EteeloErrorResult(
              type: EteeloErrorType.server,
              title: l10n.localDataRecoveryTitle,
              message: _resetFailed
                  ? l10n.localDataRecoveryResetFailed
                  : l10n.localDataRecoveryMessage,
              fullWidthCard: false,
              primaryAction: FilledButton.icon(
                onPressed: _busy ? null : () => _run(widget.onRetry),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.localDataRecoveryRetry),
              ),
              secondaryAction: OutlinedButton.icon(
                onPressed: _busy ? null : _confirmReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(l10n.localDataRecoveryReset),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
