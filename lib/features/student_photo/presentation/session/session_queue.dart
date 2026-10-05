import 'package:school_app_flutter/core/helpers/person_name_comparator.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';

/// L'ordre et la marche de la file d'une séance : qui passe en premier, ce
/// qu'un élève est devenu, qui vient ensuite.
abstract final class SessionQueue {
  /// Les élèves sans photo d'abord, puis l'ordre alphabétique.
  static int order(SessionStudent a, SessionStudent b, Set<String> withPhoto) {
    final aHas = withPhoto.contains(a.id) ? 1 : 0;
    final bHas = withPhoto.contains(b.id) ? 1 : 0;
    if (aHas != bHas) return aHas - bHas;
    return _byName(a, b);
  }

  static final Comparator<SessionStudent> _byName = PersonNameComparator.by(
    lastName: (s) => s.lastName,
    surname: (s) => s.middleName,
    firstName: (s) => s.firstName,
    id: (s) => s.id,
  );

  static List<SessionItem> withStatus(
    List<SessionItem> queue,
    int index,
    SessionItemStatus status,
  ) => [
    for (var i = 0; i < queue.length; i++)
      i == index ? queue[i].withStatus(status) : queue[i],
  ];

  static int? nextTodo(List<SessionItem> queue, int from) {
    for (var step = 1; step <= queue.length; step++) {
      final i = (from + step) % queue.length;
      if (queue[i].status == SessionItemStatus.todo) return i;
    }
    return null;
  }
}
