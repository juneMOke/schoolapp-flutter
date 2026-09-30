import 'package:equatable/equatable.dart';

/// Un diplôme déclaré sur la fiche, du plus élevé au plus ancien.
class StaffDiploma extends Equatable {
  /// Niveau (« Licence », « D6 »…), texte libre borné par la liste du poste.
  final String level;
  final String title;
  final String? institution;
  final int? graduationYear;

  const StaffDiploma({
    required this.level,
    required this.title,
    this.institution,
    this.graduationYear,
  });

  @override
  List<Object?> get props => [level, title, institution, graduationYear];
}
