import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés du module, en un endroit : la liste, l'éditeur et le détail
/// nomment les mêmes choses de la même façon.
extension AnnouncementLabels on AppLocalizations {
  String categoryLabel(AnnouncementCategory category) => switch (category) {
    AnnouncementCategory.info => communicationCategoryInfo,
    AnnouncementCategory.urgent => communicationCategoryUrgent,
    AnnouncementCategory.event => communicationCategoryEvent,
    AnnouncementCategory.administrative => communicationCategoryAdministrative,
  };

  String statusLabel(AnnouncementStatus status) => switch (status) {
    AnnouncementStatus.draft => communicationStatusDraft,
    AnnouncementStatus.scheduled => communicationStatusScheduled,
    AnnouncementStatus.sent => communicationStatusSent,
    AnnouncementStatus.failed => communicationStatusFailed,
    AnnouncementStatus.cancelled => communicationStatusCancelled,
  };

  /// Le nom d'un groupe de la liste (pluriel).
  String statusGroupLabel(AnnouncementStatus status) => switch (status) {
    AnnouncementStatus.draft => communicationGroupDrafts,
    AnnouncementStatus.scheduled => communicationGroupScheduled,
    AnnouncementStatus.sent => communicationGroupSent,
    AnnouncementStatus.failed => communicationGroupFailed,
    AnnouncementStatus.cancelled => communicationStatusCancelled,
  };

  String audienceModeLabel(AudienceMode mode) => switch (mode) {
    AudienceMode.school => communicationAudienceSchool,
    AudienceMode.levels => communicationAudienceModeLevels,
    AudienceMode.classrooms => communicationAudienceModeClassrooms,
    AudienceMode.students => communicationAudienceModeStudents,
    AudienceMode.overdue => communicationAudienceOverdue,
  };

  String channelLabel(AnnouncementChannel channel) => switch (channel) {
    AnnouncementChannel.whatsapp => communicationChannelWhatsapp,
  };

  String variableLabel(AnnouncementVariable variable) => switch (variable) {
    AnnouncementVariable.student => communicationVariableStudent,
    AnnouncementVariable.classroom => communicationVariableClassroom,
    AnnouncementVariable.amount => communicationVariableAmount,
  };

  /// L'audience en quelques mots, comptée plutôt que nommée : « 3 classes ».
  String audienceSummary(AnnouncementAudience audience) => switch (audience) {
    SchoolAudience() => communicationAudienceSchool,
    LevelsAudience(:final levelIds) => communicationAudienceLevelsCount(
      levelIds.length,
    ),
    ClassroomsAudience(:final classroomIds) =>
      communicationAudienceClassroomsCount(classroomIds.length),
    StudentsAudience(:final studentIds) => communicationAudienceStudentsCount(
      studentIds.length,
    ),
    OverdueAudience() => communicationAudienceOverdue,
  };

  /// L'extrait d'un message : chaque variable dite par son nom, entre
  /// chevrons, puisqu'elle n'a de valeur que pour une famille donnée.
  String excerptOf(Announcement announcement) => AnnouncementVariables.render(
    announcement.content.body.replaceAll(RegExp(r'\s+'), ' '),
    {
      for (final variable in AnnouncementVariable.values)
        variable: '‹${variableLabel(variable)}›',
    },
  );

  /// La méta d'une ligne : audience, portée une fois envoyé, canaux — une
  /// seule chaîne, jamais des fragments.
  String metaOf(Announcement announcement) {
    final reach = announcement.reachAtSend;
    return [
      audienceSummary(announcement.content.audience),
      if (reach != null)
        communicationReachSentShort(reach.reachableMessages, reach.messages),
      ...announcement.content.channels.map(channelLabel),
    ].reduce(communicationJoin);
  }

  /// Une énumération : « WhatsApp, Portail ».
  String listOf(Iterable<String> items) =>
      items.isEmpty ? '' : items.reduce(communicationListJoin);
}
