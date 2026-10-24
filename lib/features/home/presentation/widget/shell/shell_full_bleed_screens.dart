import 'package:school_app_flutter/core/constants/menu_constants.dart';

/// Sous-menus « plein cadre » : leur page peint elle-même son fond et sa
/// largeur via `AppPageBackground`. La coquille ne leur ajoute ni fil d'Ariane,
/// ni padding, ni colonne centrée — sinon le padding est doublé, le contenu
/// tombe sous 1180 dp et le fond s'arrête dans une boîte au lieu de couvrir le
/// volet.
const Set<String> shellFullBleedSubMenuIds = {
  MenuConstants.accueilId,
  MenuConstants.inscriptionsDashboardId,
  MenuConstants.financesDashboardId,
  MenuConstants.classesDashboardId,
  MenuConstants.preInscriptionsId,
  MenuConstants.reInscriptionsId,
  MenuConstants.premiereInscriptionId,
  MenuConstants.facturationsId,
  MenuConstants.recouvrementDashboardId,
  MenuConstants.recouvrementControlId,
  MenuConstants.boutiqueDashboardId,
  MenuConstants.boutiqueAchatsId,
  MenuConstants.expenseDashboardId,
  MenuConstants.expenseRegisterId,
  MenuConstants.expenseQueueId,
  MenuConstants.communicationAnnouncementsId,
  MenuConstants.communicationTemplatesId,
  MenuConstants.organisationId,
  MenuConstants.classesListId,
  MenuConstants.presencesId,
  MenuConstants.justificationsId,
  MenuConstants.disciplinesListId,
  MenuConstants.disciplinesDashboardId,
  MenuConstants.myCoursesId,
  MenuConstants.timetableId,
  MenuConstants.classJournalId,
  MenuConstants.resultatsClasseId,
  MenuConstants.documentsStudentId,
  MenuConstants.configurationSchoolId,
  MenuConstants.hrStaffFileId,
  MenuConstants.hrStaffAttendanceId,
  MenuConstants.hrPayrollId,
  MenuConstants.hrPersonnelDashboardId,
  MenuConstants.hrPersonnelFileId,
  MenuConstants.courseProgrammeId,
};
