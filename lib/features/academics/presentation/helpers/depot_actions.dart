import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/attachments/attachment_document.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/copie_rendue.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la copie d'un élève : ses pages dans l'ordre, dans la visionneuse
/// partagée, sans partage ni impression — c'est la copie d'un mineur.
///
/// Des photos de pages forment un seul document. Une copie qui mêle un PDF à
/// d'autres pièces ne se fusionne pas : chaque pièce s'ouvre alors à son tour.
Future<void> openDepotCopie(BuildContext context, CopieRendue eleve) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await context.read<DepotsCubit>().pages(eleve);
  if (!context.mounted) return;
  final parts = result.fold((failure) {
    AppSnackBar.showError(
      context,
      failure is NetworkFailure
          ? l10n.depotEnLigneSeulement
          : l10n.depotIndisponible,
    );
    return null;
  }, (parts) => parts);
  if (parts == null) return;
  final title = l10n.depotViewerTitle(eleve.name);
  final whole = await AttachmentDocument.compose(parts, fileName: title);
  final documents = [
    ?whole,
    if (whole == null)
      for (final part in parts)
        ?await AttachmentDocument.compose([part], fileName: part.ref.name),
  ];
  if (!context.mounted) return;
  if (documents.isEmpty) {
    AppSnackBar.showError(context, l10n.depotIllisible);
    return;
  }
  for (final document in documents) {
    if (!context.mounted) return;
    await showEteeloDocumentViewer(
      context,
      title: title,
      document: document,
      canShare: false,
      canPrint: false,
    );
  }
}
