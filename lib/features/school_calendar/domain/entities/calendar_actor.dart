import 'package:equatable/equatable.dart';

/// Qui a publié ou ajouté : un nom (nul si le compte n'en a pas) et un rôle
/// (`DIRECTOR`, `ACADEMIC_ADMIN`…), traduit à l'écran.
class CalendarActor extends Equatable {
  final String? name;
  final String? role;

  const CalendarActor({this.name, this.role});

  static CalendarActor? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'];
    final role = raw['role'];
    return CalendarActor(
      name: name is String && name.trim().isNotEmpty ? name : null,
      role: role is String && role.isNotEmpty ? role : null,
    );
  }

  @override
  List<Object?> get props => [name, role];
}
