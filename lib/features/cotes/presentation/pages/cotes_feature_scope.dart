import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';

/// Portée BLoC de la saisie des notes (AGENTS.md §11). Le scope relie les deux
/// blocs : une cellule posée relance l'enregistrement, un vidage de la file fait
/// relire les cellules.
class CotesFeatureScope extends StatefulWidget {
  final Widget child;

  const CotesFeatureScope({super.key, required this.child});

  @override
  State<CotesFeatureScope> createState() => _CotesFeatureScopeState();
}

class _CotesFeatureScopeState extends State<CotesFeatureScope> {
  late final CoteSaisieBloc _saisieBloc;
  late final CoteSaveCubit _saveCubit;
  late final AcademicYearContextBloc _academicYearContextBloc;
  late final ClassroomOfflineBloc _classroomOfflineBloc;

  @override
  void initState() {
    super.initState();
    _saisieBloc = GetIt.instance<CoteSaisieBloc>();
    _saveCubit = GetIt.instance<CoteSaveCubit>();
    _saisieBloc.onCellWritten = _saveCubit.noteChanged;
    _saveCubit.onFlushed = () {
      if (!_saisieBloc.isClosed) _saisieBloc.add(const CoteCellsRefreshed());
    };
    _academicYearContextBloc = GetIt.instance<AcademicYearContextBloc>()
      ..add(const AcademicYearContextRequested());
    _classroomOfflineBloc = GetIt.instance<ClassroomOfflineBloc>();
  }

  @override
  void dispose() {
    // Le bloc d'abord : la dernière case quittée s'y écrit encore, et le cubit
    // ne se ferme qu'après l'avoir envoyée.
    _saisieBloc.close().whenComplete(_saveCubit.close);
    _academicYearContextBloc.close();
    _classroomOfflineBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CoteSaisieBloc>.value(value: _saisieBloc),
        BlocProvider<CoteSaveCubit>.value(value: _saveCubit),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
        BlocProvider<ClassroomOfflineBloc>.value(value: _classroomOfflineBloc),
      ],
      child: widget.child,
    );
  }
}
