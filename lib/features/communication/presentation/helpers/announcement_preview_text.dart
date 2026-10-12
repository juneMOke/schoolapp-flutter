import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le texte de l'aperçu, rendu pour une famille d'exemple : ce que le serveur
/// rendra pour chaque couple (tuteur, élève) à l'envoi.
extension AnnouncementPreviewText on AppLocalizations {
  /// Le message WhatsApp, calqué mot pour mot sur le gabarit Meta
  /// `eteelo_school_announcement` (le texte qui fait foi est celui que Meta
  /// approuve).
  String whatsappPreview(AnnouncementContent content, {String? schoolName}) =>
      communicationWhatsappTemplate(
        communicationSampleGuardian,
        schoolName ?? communicationSampleSchool,
        communicationSampleStudent,
        content.title.trim().isEmpty
            ? communicationUntitled
            : _rendered(content.title),
      );

  /// Le texte complet de la page de lecture.
  String readingPreview(AnnouncementContent content) => _rendered(content.body);

  String readingTitle(AnnouncementContent content) =>
      content.title.trim().isEmpty
      ? communicationUntitled
      : _rendered(content.title);

  String _rendered(String text) => AnnouncementVariables.render(text, {
    AnnouncementVariable.student: communicationSampleStudent,
    AnnouncementVariable.classroom: communicationSampleClassroom,
    AnnouncementVariable.amount: communicationSampleAmount,
  });
}
