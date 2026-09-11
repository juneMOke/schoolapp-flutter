import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_report_cubit.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

/// Scope du tableau de bord des inscriptions — **l'agrégat, et deux
/// subordonnés**.
///
/// L'agrégat fait autorité ; la liste nominative et son registre PDF le
/// suivent. Ce n'est pas une hiérarchie de confort : les appels portent des
/// permissions différentes (la liste et le PDF exigent `enrollment.read` en
/// plus du pilotage).
///
/// L'écouteur ci-dessous est **le seul endroit** qui décide quand la liste
/// charge. Il tient trois règles d'un coup :
///
///  * elle charge sur **toute** fenêtre dont l'agrégat a répondu — jour,
///    semaine, mois, année ou période libre ;
///  * changer de fenêtre **remet sa pagination à zéro** ;
///  * un agrégat qui n'a rien de juste à montrer — en chargement, vide ou en
///    erreur — la vide.
///
/// Les trois sont fermés dans [dispose] — contrepartie du `registerFactory`.
class EnrollmentStatsDashboardScope extends StatefulWidget {
  final Widget child;

  const EnrollmentStatsDashboardScope({super.key, required this.child});

  @override
  State<EnrollmentStatsDashboardScope> createState() =>
      _EnrollmentStatsDashboardScopeState();
}

class _EnrollmentStatsDashboardScopeState
    extends State<EnrollmentStatsDashboardScope> {
  late final EnrollmentStatsBloc _statsBloc;
  late final EnrollmentEntriesBloc _entriesBloc;
  late final EnrollmentEntriesReportCubit _reportCubit;

  @override
  void initState() {
    super.initState();
    _statsBloc = GetIt.instance<EnrollmentStatsBloc>();
    _entriesBloc = GetIt.instance<EnrollmentEntriesBloc>();
    _reportCubit = GetIt.instance<EnrollmentEntriesReportCubit>();
  }

  @override
  void dispose() {
    _statsBloc.close();
    _entriesBloc.close();
    _reportCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentStatsBloc>.value(value: _statsBloc),
        BlocProvider<EnrollmentEntriesBloc>.value(value: _entriesBloc),
        BlocProvider<EnrollmentEntriesReportCubit>.value(value: _reportCubit),
      ],
      child: BlocListener<EnrollmentStatsBloc, EnrollmentStatsState>(
        listenWhen: (prev, curr) =>
            prev.window != curr.window || prev.status != curr.status,
        listener: (context, state) {
          // Pas de chiffres, pas de noms.
          //
          // Au changement de fenêtre, l'agrégat repasse en chargement : la
          // liste se vide AVANT que les lignes de la nouvelle fenêtre
          // n'arrivent. Sans ça, les noms de l'ancienne resteraient un instant
          // sous le titre de la nouvelle. En erreur, elle ne serait de toute
          // façon pas rendue (la page ne construit ce sous-arbre que dans la
          // branche `success`), mais un BLoC qui garderait des noms d'une
          // lecture précédente est un accident qui attend un futur point de
          // montage.
          if (state.status != EnrollmentStatsStatus.success) {
            _entriesBloc.add(const EnrollmentEntriesCleared());
            return;
          }

          _entriesBloc.add(EnrollmentEntriesRequested(state.window));
        },
        child: widget.child,
      ),
    );
  }
}
