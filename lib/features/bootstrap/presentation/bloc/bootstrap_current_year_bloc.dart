import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_current_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';

class BootstrapCurrentYearBloc
    extends BootstrapContextBloc<BootstrapContextEvent> {
  BootstrapCurrentYearBloc({
    required GetRemoteBootstrapCurrentYearUseCase
    getRemoteBootstrapCurrentYearUseCase,
    required super.getLocalBootstrapUseCase,
    required super.saveLocalBootstrapUseCase,
    required super.clearLocalBootstrapUseCase,
  }) : super(
         getRemoteCurrentYearUseCase: getRemoteBootstrapCurrentYearUseCase,
       ) {
    on<BootstrapContextRemoteCurrentYearRequested>(onLoadRemoteCurrentYear);
    on<BootstrapContextLocalRequested>(onLoadLocal);
    on<BootstrapContextResetRequested>(onReset);
  }
}
