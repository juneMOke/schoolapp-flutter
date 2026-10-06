import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Imprimée 2 fois · partagée 1 fois » (« jamais » à zéro).
String copieSubtitle(AppLocalizations l10n, int prints, int shares) =>
    '${l10n.copiePrintedTimes(prints)} · ${l10n.copieSharedTimes(shares)}';

/// Canal d'un partage, lisible.
String copieCanalLabel(AppLocalizations l10n, CopieCanal? canal) =>
    switch (canal) {
      CopieCanal.whatsapp => l10n.copieCanalWhatsapp,
      CopieCanal.email => l10n.copieCanalEmail,
      CopieCanal.lien => l10n.copieCanalLien,
      CopieCanal.systeme || null => l10n.copieCanalSysteme,
    };

/// « Imprimée le 11/06/2026 » ou « Partagée (WhatsApp) le 11/06/2026 ».
String diffusionLabel(BuildContext context, CopieDiffusion diffusion) {
  final l10n = AppLocalizations.of(context)!;
  final date = MaterialLocalizations.of(
    context,
  ).formatCompactDate(diffusion.occurredAt.toLocal());
  return switch (diffusion.kind) {
    CopieKind.print => l10n.copieDiffusionPrinted(date),
    CopieKind.share => l10n.copieDiffusionShared(
      copieCanalLabel(l10n, diffusion.canal),
      date,
    ),
  };
}
