import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_fonts.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_pdf.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Construit la copie (ou le corrigé) et l'ouvre dans la visionneuse
/// partagée. Une impression ou un partage abouti est rendu à [onDiffused],
/// qui le journalise.
Future<void> openCopieViewer(
  BuildContext context, {
  required SujetCopieContent content,
  required CopieOptions options,
  required void Function(CopieKind kind) onDiffused,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final PrintableDocument document;
  try {
    final bytes = await SujetCopiePdf.build(
      content: content,
      options: options,
      l10n: l10n,
      fonts: await SujetCopieFonts.load(),
    );
    document = PrintableDocument(
      bytes: bytes,
      fileName: _fileName(content.titre, fallback: l10n.copieSectionTitle),
      reference: options.reponses ? l10n.copieViewerCorrigeWarning : null,
    );
  } catch (_) {
    if (context.mounted) AppSnackBar.showError(context, l10n.copieBuildError);
    return;
  }
  if (!context.mounted) return;
  final scope = l10n.copieViewerScope(
    content.brancheNom,
    content.classroomName,
  );
  await showEteeloDocumentViewer(
    context,
    title: options.reponses
        ? l10n.copieViewerTitleCorrige(scope)
        : l10n.copieViewerTitle(scope),
    document: document,
    onPrinted: () {
      onDiffused(CopieKind.print);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.copiePrintedToast)));
    },
    onShared: () {
      onDiffused(CopieKind.share);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.copieSharedToast)));
    },
  );
}

/// Nom de fichier du PDF : le titre, débarrassé des caractères qu'un système
/// de fichiers refuse (un titre de chapitre peut contenir « / »).
String _fileName(String titre, {required String fallback}) {
  final safe = titre.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-').trim();
  return '${safe.isEmpty ? fallback : safe}.pdf';
}
