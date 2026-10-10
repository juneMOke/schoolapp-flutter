import 'package:equatable/equatable.dart';

/// Un enseignant de l'école, tel que la direction le choisit.
class JournalTeacher extends Equatable {
  final String id;
  final String displayName;

  const JournalTeacher({required this.id, required this.displayName});

  @override
  List<Object?> get props => [id, displayName];
}
