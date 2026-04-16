import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_previous_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';

class BootstrapPreviousYearBloc
    extends BootstrapContextBloc<BootstrapContextEvent> {
  BootstrapPreviousYearBloc({
    required GetRemoteBootstrapPreviousYearUseCase
    getRemoteBootstrapPreviousYearUseCase,
    required super.getLocalBootstrapUseCase,
    required super.saveLocalBootstrapUseCase,
    required super.clearLocalBootstrapUseCase,
  }) : super(
         getRemotePreviousYearUseCase: getRemoteBootstrapPreviousYearUseCase,
       ) {
    on<BootstrapContextRemotePreviousYearRequested>(onLoadRemotePreviousYear);
    on<BootstrapContextLocalRequested>(onLoadLocal);
    on<BootstrapContextResetRequested>(onReset);
  }
}
