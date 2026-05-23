import 'package:equatable/equatable.dart';

class SchoolLevel extends Equatable {
  final String id;
  final String name;
  final String code;
  final int displayOrder;
  final bool splitIntoClassrooms;

  const SchoolLevel({
    required this.id,
    required this.name,
    required this.code,
    required this.displayOrder,
    required this.splitIntoClassrooms,
  });

  @override
  List<Object?> get props => [id, name, code, displayOrder, splitIntoClassrooms];
}
