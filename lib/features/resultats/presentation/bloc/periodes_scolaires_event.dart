import 'package:equatable/equatable.dart';

sealed class PeriodesScolairesEvent extends Equatable {
  const PeriodesScolairesEvent();
}

/// Demande le chargement des grandes périodes d'une classe.
///
/// Émis quand une classe est choisie dans la cascade : [classroomId] suffit
/// (le backend résout l'année × cycle depuis la classe).
class PeriodesScolairesRequested extends PeriodesScolairesEvent {
  final String classroomId;

  const PeriodesScolairesRequested({required this.classroomId});

  @override
  List<Object?> get props => [classroomId];
}
