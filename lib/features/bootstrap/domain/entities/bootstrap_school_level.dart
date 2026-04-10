import 'package:equatable/equatable.dart';

class BootstrapSchoolLevel extends Equatable {
  final String id;
  final int version;
  final String name;
  final String code;
  final int displayOrder;

  const BootstrapSchoolLevel({
    required this.id,
    required this.version,
    required this.name,
    required this.code,
    required this.displayOrder,
  });

  @override
  List<Object?> get props => [id, version, name, code, displayOrder];
}
