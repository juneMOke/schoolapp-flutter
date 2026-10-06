import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_file_preview.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une ressource : un lien dans le navigateur ; un document dans la
/// visionneuse (copie de la tablette, sinon téléchargé). Un type qui ne se
/// prévisualise pas (Word) ou un fichier introuvable le disent.
Future<void> openChapitreRessource(
  BuildContext context,
  ChapitreRessource ressource,
) async {
  final l10n = AppLocalizations.of(context)!;
  if (ressource.type == RessourceType.lien) {
    final uri = Uri.tryParse(ressource.url ?? '');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  final result = await context.read<ChapitreCubit>().openDocument(ressource);
  if (!context.mounted) return;
  await result.fold(
    (_) async =>
        AppSnackBar.showError(context, l10n.chapitreRessourceUnavailable),
    (bytes) async {
      final shown = await showEteeloFilePreview(
        context,
        title: ressource.nom,
        bytes: bytes,
        mimeType: ressource.mimeType ?? '',
        fileName: ressource.fileName ?? ressource.nom,
      );
      if (!shown && context.mounted) {
        AppSnackBar.showInfo(context, l10n.chapitreRessourceNotPreviewable);
      }
    },
  );
}
