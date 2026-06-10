import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pied du splash (spec COMPOSANT 04). Deux lignes ancrées en bas de la zone
/// sûre : la signature de marque (Lora italique) et le numéro de version
/// technique (Roboto Mono), lu via `PackageInfo` — jamais codé en dur.
///
/// Masqué par l'appelant sous une hauteur critique (cf. [SplashMetrics]).
class SplashFooter extends StatefulWidget {
  const SplashFooter({super.key});

  @override
  State<SplashFooter> createState() => _SplashFooterState();
}

class _SplashFooterState extends State<SplashFooter> {
  /// Chargé une seule fois (le canal plateforme n'est sollicité qu'au montage).
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  static const double _signatureSize = 13;
  static const double _versionSize = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.splashTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: _signatureSize,
            fontStyle: FontStyle.italic,
            color: AppColors.blancCasse.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 6),
        _VersionLine(future: _packageInfo, l10n: l10n, fontSize: _versionSize),
      ],
    );
  }
}

/// Ligne de version « v{semver} (build {n}) » en Roboto Mono, Or Doux atténué.
/// Tant que `PackageInfo` n'est pas résolu (ou en erreur — ex. en test), rien
/// n'est affiché : le pied reste propre sans version partielle.
class _VersionLine extends StatelessWidget {
  const _VersionLine({
    required this.future,
    required this.l10n,
    required this.fontSize,
  });

  final Future<PackageInfo> future;
  final AppLocalizations l10n;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: future,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Text(
          l10n.splashVersion(info.version, info.buildNumber),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontSize: fontSize,
            color: AppColors.orDoux.withValues(alpha: 0.70),
            letterSpacing: 0.5,
          ),
        );
      },
    );
  }
}
