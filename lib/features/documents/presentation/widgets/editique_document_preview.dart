import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_pdf_preview.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/states/editique_results_error_state.dart';

/// Rendu des pages d'une pièce reçue.
///
/// **Adaptateur mince sur [EteeloPdfPreview]** : l'aperçu est commun à toutes
/// les sorties papier de l'application — registre, rapport, liste de relance,
/// ticket —, et seul le repli d'affichage reste propre à l'éditique.
///
/// Ce qui justifie ce repli-là plutôt que celui du socle : la carte du module
/// porte son anatomie d'erreur, et surtout sa règle de reprise. Le socle, lui,
/// peut proposer de régénérer — ici ce serait une faute.
class EditiqueDocumentPreview extends StatelessWidget {
  final EditiqueDocument document;

  const EditiqueDocumentPreview({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return EteeloPdfPreview(
      bytes: document.bytes,
      fileName: document.fileName,
      // La pièce est bien arrivée : c'est un incident d'affichage, pas
      // d'émission. Aucune reprise n'est donc proposée — la redemander ne
      // changerait rien, et sur une pièce horodatée en brûlerait le numéro.
      errorBuilder: (_) => const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: EditiqueResultsErrorState(
          type: EditiqueErrorType.server,
          canRetry: false,
        ),
      ),
    );
  }
}
