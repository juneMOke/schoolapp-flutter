import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_origin.dart';

class ClassesListIntent extends Equatable {
  final ClassesListOrigin origin;

  const ClassesListIntent({required this.origin});

  const ClassesListIntent.classesList()
    : this(origin: ClassesListOrigin.classesList);

  const ClassesListIntent.disciplinesList()
    : this(origin: ClassesListOrigin.disciplinesList);

  @override
  List<Object?> get props => [origin];
}
