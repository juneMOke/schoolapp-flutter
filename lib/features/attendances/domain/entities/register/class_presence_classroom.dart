import 'package:equatable/equatable.dart';

/// La classe dont on fait l'appel, telle que l'en-tête la montre.
class ClassPresenceClassroom extends Equatable {
  final String id;
  final String name;

  /// Le niveau (« 6ème primaire ») ; `null` s'il n'est pas connu.
  final String? levelName;
  final int studentCount;

  const ClassPresenceClassroom({
    required this.id,
    required this.name,
    required this.studentCount,
    this.levelName,
  });

  @override
  List<Object?> get props => [id, name, levelName, studentCount];
}
