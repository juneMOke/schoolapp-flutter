part of 'enrollment_stats_bloc.dart';

const _undefined = Object();

/// Les états du tableau de bord des inscriptions.
///
/// **`empty` est un état à part entière, pas un `total == 0` testé par un
/// widget.** La règle « les blocs Rythme, Qui, Où, Liste et Lectures sont
/// masqués quand il n'y a rien à montrer » vit ici, en un seul endroit ; huit
/// conditions recopiées dans huit widgets auraient divergé au premier bloc
/// ajouté.
enum EnrollmentStatsStatus { initial, loading, success, empty, error }

class EnrollmentStatsState extends Equatable {
  final EnrollmentStatsStatus status;

  /// Les données lues. **Nulles dès que la lecture échoue** — cf. le bloc.
  ///
  /// L'écran n'a alors plus rien de juste à peindre sous l'en-tête : « sans
  /// données, l'effectif affiché serait un mensonge ». Garder la dernière
  /// lecture ici rendrait ce mensonge possible, et il suffirait d'un widget
  /// distrait pour qu'il arrive à l'écran.
  final EnrollmentStats? stats;

  /// L'échec, tel quel.
  ///
  /// Le `Failure` plutôt qu'un enum maison reprojeté : deux taxonomies de la
  /// même chose finissent par diverger, et celle qui perd est toujours la
  /// seconde. La vue d'erreur en tire son anatomie ET son message.
  final Failure? failure;

  /// La fenêtre affichée. Elle change **en même temps** que les chiffres :
  /// jamais d'onglet actif qui ne corresponde pas à ce qui est peint dessous.
  final EnrollmentStatsWindow window;

  const EnrollmentStatsState({
    this.status = EnrollmentStatsStatus.initial,
    this.stats,
    this.failure,
    this.window = const EnrollmentStatsWindow.year(),
  });

  EnrollmentStatsState copyWith({
    EnrollmentStatsStatus? status,
    Object? stats = _undefined,
    Object? failure = _undefined,
    EnrollmentStatsWindow? window,
  }) => EnrollmentStatsState(
    status: status ?? this.status,
    stats: identical(stats, _undefined)
        ? this.stats
        : stats as EnrollmentStats?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    window: window ?? this.window,
  );

  @override
  List<Object?> get props => [status, stats, failure, window];
}
