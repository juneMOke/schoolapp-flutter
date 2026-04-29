import 'package:equatable/equatable.dart';

class BootstrapSchoolLevel extends Equatable {
  final String id;
  final int version;
  final String name;
  final String code;
  final int displayOrder;
  final bool splitIntoClassrooms;

  const BootstrapSchoolLevel({
    required this.id,
    required this.version,
    required this.name,
    required this.code,
    required this.displayOrder,
    required this.splitIntoClassrooms,
  });

  BootstrapSchoolLevel copyWith({
    String? id,
    int? version,
    String? name,
    String? code,
    int? displayOrder,
    bool? splitIntoClassrooms,
  }) => BootstrapSchoolLevel(
    id: id ?? this.id,
    version: version ?? this.version,
    name: name ?? this.name,
    code: code ?? this.code,
    displayOrder: displayOrder ?? this.displayOrder,
    splitIntoClassrooms: splitIntoClassrooms ?? this.splitIntoClassrooms,
  );

  @override
  List<Object?> get props => [
    id,
    version,
    name,
    code,
    displayOrder,
    splitIntoClassrooms,
  ];
}
