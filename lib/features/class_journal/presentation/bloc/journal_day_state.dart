import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';

/// L'état de la page du journal. Le jour affiché ([date]) est connu dans tous
/// les états : l'en-tête reste visible, on peut toujours changer de jour.
sealed class JournalDayState extends Equatable {
  final DateTime date;

  /// Aujourd'hui, à l'heure de l'école.
  final DateTime today;

  const JournalDayState({required this.date, required this.today});

  bool get isToday => date == today;

  @override
  List<Object?> get props => [date, today];
}

/// Avant la première lecture (année scolaire pas encore résolue).
final class JournalDayIdle extends JournalDayState {
  const JournalDayIdle({required super.date, required super.today});
}

final class JournalDayLoading extends JournalDayState {
  const JournalDayLoading({required super.date, required super.today});
}

final class JournalDayReady extends JournalDayState {
  final JournalDay day;

  const JournalDayReady({
    required this.day,
    required super.date,
    required super.today,
  });

  @override
  List<Object?> get props => [...super.props, day];
}

final class JournalDayFailure extends JournalDayState {
  final Failure failure;

  const JournalDayFailure({
    required this.failure,
    required super.date,
    required super.today,
  });

  @override
  List<Object?> get props => [...super.props, failure];
}
