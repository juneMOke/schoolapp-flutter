import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_tab.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_tabs.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/student_attendance_summary_tab.dart';

/// Les deux volets de la fiche élève (Discipline puis Présence) et leur barre
/// d'onglets.
///
/// Monté **uniquement** quand la session détient `discipline.read` : sans ce
/// droit, la page rend la synthèse de présence seule, sans barre — un segmenté
/// à une colonne n'offre aucun choix, il ne ferait qu'annoncer une porte
/// fermée. La garde vit dans la page, pas ici : ce widget n'existe que dans le
/// cas autorisé.
class DisciplinaryDossierBody extends StatefulWidget {
  final DisciplinaryStudentDetailIntent intent;
  final int openCasesCount;

  const DisciplinaryDossierBody({
    super.key,
    required this.intent,
    required this.openCasesCount,
  });

  @override
  State<DisciplinaryDossierBody> createState() =>
      _DisciplinaryDossierBodyState();
}

class _DisciplinaryDossierBodyState extends State<DisciplinaryDossierBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intent = widget.intent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisciplinaryDossierTabs(
          controller: _tabController,
          openCasesCount: widget.openCasesCount,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Le contenu des onglets s'affiche directement sur le fond décoré
        // standard de la page (halos + motif), comme les autres pages : plus de
        // panneau peignant un fond plein qui le masquerait.
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              DisciplinaryCasesTab(
                studentId: intent.studentId,
                academicYearId: intent.academicYearId,
                onCreateCase: () => _showCreateDialog(context),
              ),
              StudentAttendanceSummaryTab(
                studentId: intent.studentId,
                academicYearId: intent.academicYearId,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    // Écriture offline-first : le dialog dispatche sur le BLoC offline (scopé
    // par AttendanceFeatureScope). showDialog monte sous le Navigator racine,
    // hors du scope : on relaie donc le BLoC via .value.
    final disciplinaryCaseOfflineBloc = context
        .read<DisciplinaryCaseOfflineBloc>();
    final intent = widget.intent;

    showDialog(
      context: context,
      builder: (context) => BlocProvider<DisciplinaryCaseOfflineBloc>.value(
        value: disciplinaryCaseOfflineBloc,
        child: DisciplinaryCaseCreateDialog(
          studentId: intent.studentId,
          studentFirstName: intent.studentFirstName,
          studentLastName: intent.studentLastName,
          studentMiddleName: intent.studentMiddleName,
          studentGender: intent.studentGender,
          academicYearId: intent.academicYearId,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      // La liste locale se recharge (le dialog a enfilé une création → l'onglet
      // recharge sur CasePendingSync ; on force aussi ici pour l'en-tête).
      disciplinaryCaseOfflineBloc.add(
        LoadOfflineDisciplinaryCases(
          studentId: intent.studentId,
          academicYearId: intent.academicYearId,
        ),
      );
    });
  }
}
