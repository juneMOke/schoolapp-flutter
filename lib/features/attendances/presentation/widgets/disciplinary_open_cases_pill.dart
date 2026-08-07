import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Pastille de synthèse « cas ouverts » affichée dans l'AppBar sombre.
///
/// Rouge si des cas sont ouverts, vert sinon. [openCasesCount] null = le compte
/// n'est pas encore connu (pastille masquée).
class DisciplinaryOpenCasesAppBarPill extends StatelessWidget {
  final int? openCasesCount;
  final String openLabel;
  final String noneLabel;

  const DisciplinaryOpenCasesAppBarPill({
    super.key,
    required this.openCasesCount,
    required this.openLabel,
    required this.noneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final count = openCasesCount;
    if (count == null) return const SizedBox.shrink();

    final hasOpen = count > 0;
    return StudentDetailAppBarPill(
      accent: hasOpen ? AppColors.error : AppColors.vertSavane,
      icon: hasOpen ? Icons.error_outline : Icons.check_circle_outline,
      label: hasOpen ? openLabel : noneLabel,
      alert: hasOpen,
    );
  }
}
