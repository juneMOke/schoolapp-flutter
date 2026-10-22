import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/courses_coordinator_page.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/courses_feature_scope.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_feature_scope.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_overview_dashboard_page.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_overview_dashboard_scope.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/pages/class_presence_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_dashboard_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_coordinator_page.dart';
import 'package:school_app_flutter/features/class_journal/presentation/pages/journal_feature_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_feature_scope.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_list_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_organisation_page.dart';
import 'package:school_app_flutter/features/classes/presentation/pages/classes_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcement_templates_page.dart';
import 'package:school_app_flutter/features/communication/presentation/pages/announcements_page.dart';
import 'package:school_app_flutter/features/configuration/presentation/pages/configuration_settings_page.dart';
import 'package:school_app_flutter/features/course_programme/presentation/pages/programme_coordinator_page.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_feature_scope.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_feature_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/enrollment_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/first_registration_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/pre_registrations_page.dart';
import 'package:school_app_flutter/features/enrollment/presentation/pages/re_registrations_page.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_dashboard_page.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_feature_scope.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_queue_page.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_register_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_feature_scope.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_page.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/finance_stats_dashboard_scope.dart';
import 'package:school_app_flutter/features/home/presentation/pages/accueil_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_feature_scope.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/recouvrement_dashboard_page.dart';
import 'package:school_app_flutter/features/resultats/presentation/pages/resultats_coordinator_page.dart';
import 'package:school_app_flutter/features/resultats/presentation/pages/resultats_feature_scope.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_coordinator_page.dart';
import 'package:school_app_flutter/features/schedule/presentation/pages/schedule_feature_scope.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_attendance_page.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_file_page.dart';
import 'package:school_app_flutter/features/home/presentation/widget/shell/shell_under_construction.dart';

/// L'écran que la coquille affiche pour un sous-menu.
///
/// Un sous-menu déclaré au registre DOIT avoir son cas ici : sans lui, il tombe
/// dans le `default` et affiche « page en cours de développement », sans la
/// moindre erreur (`shell_sub_menu_coverage_test.dart` le garde).
class ShellScreen extends StatelessWidget {
  final String? subMenuId;

  /// Titre de l'écran, montré par le `default`.
  final String title;

  const ShellScreen({super.key, required this.subMenuId, required this.title});

  @override
  Widget build(BuildContext context) {
    switch (subMenuId) {
      case MenuConstants.accueilId:
        return const AccueilPage();
      case MenuConstants.inscriptionsDashboardId:
        return const EnrollmentStatsDashboardScope(
          child: EnrollmentStatsDashboardPage(),
        );
      // Key distinct par sous-menu : sans elle, Flutter réutilise le même
      // Element `EnrollmentFeatureScope` (même type, même emplacement dans le
      // switch) en basculant entre ces 3 pages — son State n'est alors jamais
      // remonté, et le EnrollmentLocalListBloc qu'il fournit (résolu une
      // seule fois dans initState) reste le MÊME pour les 3, faisant
      // apparaître les résultats périmés d'une page sur les deux autres.
      case MenuConstants.preInscriptionsId:
        return const EnrollmentFeatureScope(
          key: ValueKey(MenuConstants.preInscriptionsId),
          child: PreRegistrationsPage(),
        );
      case MenuConstants.reInscriptionsId:
        return const EnrollmentFeatureScope(
          key: ValueKey(MenuConstants.reInscriptionsId),
          child: ReRegistrationsPage(),
        );
      case MenuConstants.premiereInscriptionId:
        return const EnrollmentFeatureScope(
          key: ValueKey(MenuConstants.premiereInscriptionId),
          child: FirstRegistrationPage(),
        );
      // Key distinct par sous-menu : sans elle, Flutter réutilise le même
      // Element quand DEUX cas de ce switch rendent le même type de scope au
      // même emplacement. Son State n'est alors jamais remonté, donc
      // `initState` — et les pulls Finance + Inscription qu'il déclenche pour
      // hydrater le cache local, sa raison d'être — ne rejouent pas en entrant
      // sur le second écran. C'est ce qui arrivait entre Facturation et
      // Contrôle des frais, avant que ce dernier devienne un module à part.
      // La Facturation est aujourd'hui seule sous `FinanceFeatureScope` ; la
      // clé reste, pour que le piège ne se rouvre pas au prochain écran ajouté
      // sous ce scope.
      case MenuConstants.facturationsId:
        return const FinanceFeatureScope(
          key: ValueKey(MenuConstants.facturationsId),
          child: FacturationPage(),
        );
      // Même page que la route hors coquille `/finances/boutique`. Elle peint
      // son propre `AppPageBackground`, comme les réglages de Configuration, et
      // s'insère donc ici telle quelle.
      //
      // ⚠️ Sans ce cas, la caisse tombait dans le `default` : le menu latéral y
      // menait bel et bien, et l'écran répondait « page en cours de
      // développement » — alors que la route existait et que le module était
      // entier. Un sous-menu déclaré au registre DOIT avoir son cas ici.
      case MenuConstants.boutiqueAchatsId:
        return const BoutiquePage();

      case MenuConstants.boutiqueDashboardId:
        return const BoutiqueDashboardPage();
      // Les trois écrans des dépenses partagent le même type de scope au même
      // emplacement du switch : une clé par sous-menu, sinon Flutter recycle
      // l'Element et le pull de montage ne rejoue pas en passant de l'un à
      // l'autre.
      case MenuConstants.communicationAnnouncementsId:
        return const AnnouncementsPage();
      case MenuConstants.communicationTemplatesId:
        return const AnnouncementTemplatesPage();
      case MenuConstants.expenseDashboardId:
        return const ExpenseFeatureScope(
          key: ValueKey(MenuConstants.expenseDashboardId),
          child: ExpenseDashboardPage(),
        );
      case MenuConstants.expenseRegisterId:
        return const ExpenseFeatureScope(
          key: ValueKey(MenuConstants.expenseRegisterId),
          child: ExpenseRegisterPage(),
        );
      case MenuConstants.expenseQueueId:
        return const ExpenseFeatureScope(
          key: ValueKey(MenuConstants.expenseQueueId),
          child: ExpenseQueuePage(),
        );
      case MenuConstants.hrStaffFileId:
        return const StaffFilePage();
      case MenuConstants.hrStaffAttendanceId:
        return const StaffAttendancePage();
      case MenuConstants.hrPayrollId:
        return const PayrollPage();
      // Scope PROPRE depuis que le contrôle est un module à part : plus rien
      // ne le partage avec la Facturation, donc plus de `ValueKey` à poser
      // pour empêcher Flutter de recycler l'`Element` de l'autre écran — les
      // deux types diffèrent, le State ne peut plus être réutilisé.
      // Deux écrans, deux `Key` : ils partagent le MÊME type de scope au même
      // emplacement du switch, et sans clé Flutter recyclerait l'Element en
      // basculant de l'un à l'autre — son State ne serait jamais remonté, donc
      // les pulls d'hydratation ne rejoueraient pas.
      case MenuConstants.recouvrementDashboardId:
        return const FeeControlFeatureScope(
          key: ValueKey(MenuConstants.recouvrementDashboardId),
          child: RecouvrementDashboardPage(),
        );
      case MenuConstants.recouvrementControlId:
        return const FeeControlFeatureScope(
          key: ValueKey(MenuConstants.recouvrementControlId),
          child: FeeControlPage(),
        );
      case MenuConstants.documentsStudentId:
        return const DocumentsFeatureScope(
          key: ValueKey(MenuConstants.documentsStudentId),
          child: DocumentsPage(),
        );
      case MenuConstants.financesDashboardId:
        return const FinanceStatsDashboardScope(
          child: FinanceStatsDashboardPage(),
        );
      // Key distinct par sous-menu : même raison que pour EnrollmentFeatureScope
      // ci-dessus — les 4 cas partagent ClassesFeatureScope (voire ClassesListPage,
      // même type, seul l'intent diffère) au même emplacement du switch ; sans Key,
      // Flutter réutiliserait le même State (donc les mêmes blocs, résultats de
      // recherche et roster déjà chargé) en basculant entre Classes/Organisation/
      // Liste classes/Liste disciplines.
      case MenuConstants.classesDashboardId:
        return const ClassesFeatureScope(
          key: ValueKey(MenuConstants.classesDashboardId),
          child: ClassesStatsDashboardPage(),
        );
      case MenuConstants.organisationId:
        return const ClassesFeatureScope(
          key: ValueKey(MenuConstants.organisationId),
          child: ClassesOrganisationPage(),
        );
      case MenuConstants.classesListId:
        return const ClassesFeatureScope(
          key: ValueKey(MenuConstants.classesListId),
          child: ClassesListPage(intent: ClassesListIntent.classesList()),
        );
      case MenuConstants.presencesId:
        return const AttendanceFeatureScope(child: ClassPresencePage());
      case MenuConstants.disciplinesListId:
        return const ClassesFeatureScope(
          key: ValueKey(MenuConstants.disciplinesListId),
          child: ClassesListPage(intent: ClassesListIntent.disciplinesList()),
        );
      case MenuConstants.disciplinesDashboardId:
        return const AttendanceOverviewDashboardScope(
          child: AttendanceOverviewDashboardPage(),
        );
      case MenuConstants.myCoursesId:
        return const CoursesFeatureScope(
          key: ValueKey(MenuConstants.myCoursesId),
          child: CoursesCoordinatorPage(),
        );
      case MenuConstants.courseProgrammeId:
        return const CoursesFeatureScope(
          key: ValueKey(MenuConstants.courseProgrammeId),
          child: ProgrammeCoordinatorPage(),
        );
      case MenuConstants.timetableId:
        return const ScheduleFeatureScope(child: ScheduleCoordinatorPage());
      case MenuConstants.classJournalId:
        return const JournalFeatureScope(child: JournalCoordinatorPage());
      case MenuConstants.resultatsClasseId:
        return const ResultatsFeatureScope(child: ResultatsCoordinatorPage());
      // Même page que la route hors coquille `/configuration/settings`, qui
      // reste servie pour le lien profond. Elle ne monte ni Scaffold ni AppBar
      // — elle peint son propre `AppPageBackground` — donc elle s'insère ici
      // telle quelle, sans chrome à démonter.
      case MenuConstants.configurationSchoolId:
        return const ConfigurationSettingsPage();
      default:
        return ShellUnderConstruction(title: title);
    }
  }
}
