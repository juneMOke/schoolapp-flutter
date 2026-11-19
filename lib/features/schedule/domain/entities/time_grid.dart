import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Une grille horaire de l'école (EDT-R1, D2) : son nom, sa récréation (une
/// **bande** de la grille, jamais un créneau) et les codes des cycles qui la
/// suivent.
class TimeGrid extends Equatable {
  final String id;
  final String name;
  final bool isDefault;
  final List<String> cycleCodes;
  final MinuteRange? recess;

  const TimeGrid({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.cycleCodes = const [],
    this.recess,
  });

  /// La grille d'un cycle (règle du back, la même des deux côtés) : celle
  /// dont `cycleCodes` contient son code, sinon la grille par défaut.
  static TimeGrid? forCycle(String cycleCode, Iterable<TimeGrid> grids) {
    TimeGrid? fallback;
    for (final grid in grids) {
      if (grid.cycleCodes.contains(cycleCode)) return grid;
      if (grid.isDefault) fallback = grid;
    }
    return fallback;
  }

  @override
  List<Object?> get props => [id, name, isDefault, cycleCodes, recess];
}
