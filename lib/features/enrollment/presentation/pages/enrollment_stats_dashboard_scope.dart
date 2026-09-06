import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_day_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';

/// Scope du tableau de bord des inscriptions — **deux BLoCs, dont un
/// subordonné**.
///
/// L'agrégat fait autorité ; la liste nominative le suit. Ce n'est pas une
/// hiérarchie de confort : les deux appels portent des permissions différentes
/// (la liste exige `enrollment.read` en plus du pilotage), et la liste n'a de
/// sens que sur une fenêtre d'un seul jour.
///
/// L'écouteur ci-dessous est **le seul endroit** qui décide quand la liste
/// charge. Il tient trois règles d'un coup :
///
///  * elle ne charge que sur une fenêtre d'un jour ;
///  * changer de fenêtre **remet sa pagination à zéro** ;
///  * une fenêtre qui cesse d'être un jour la vide.
///
/// Les deux BLoCs sont fermés dans [dispose] — contrepartie du
/// `registerFactory`.
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
  late final EnrollmentDayEntriesBloc _dayEntriesBloc;

  @override
  void initState() {
    super.initState();
    _statsBloc = GetIt.instance<EnrollmentStatsBloc>();
    _dayEntriesBloc = GetIt.instance<EnrollmentDayEntriesBloc>();
  }

  @override
  void dispose() {
    _statsBloc.close();
    _dayEntriesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EnrollmentStatsBloc>.value(value: _statsBloc),
        BlocProvider<EnrollmentDayEntriesBloc>.value(value: _dayEntriesBloc),
      ],
      child: BlocListener<EnrollmentStatsBloc, EnrollmentStatsState>(
        listenWhen: (prev, curr) =>
            prev.window != curr.window || prev.status != curr.status,
        listener: (context, state) {
          final day = state.window.singleDay;

          // Pas une journée, ou pas de chiffres : rien à lister.
          //
          // Le cas de l'échec est couvert ici aussi — sur `error`, la liste se
          // vide. Elle ne serait de toute façon pas rendue (la page ne
          // construit ce sous-arbre que dans la branche `success`), mais un
          // BLoC qui garderait des noms d'une lecture précédente est un
          // accident qui attend un futur point de montage.
          if (day == null || state.status != EnrollmentStatsStatus.success) {
            _dayEntriesBloc.add(const EnrollmentDayEntriesCleared());
            return;
          }

          _dayEntriesBloc.add(EnrollmentDayEntriesRequested(day));
        },
        child: widget.child,
      ),
    );
  }
}
