import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_detail_page.dart';
import 'package:school_app_flutter/features/student/presentation/widgets/student_identity_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le volet de droite de la Facturation en vue scindée : la fiche choisie, ou
/// l'invitation à en choisir une.
///
/// Une clé par élève : changer d'élève recrée ses BLoCs au lieu de nourrir
/// ceux du précédent. Une fiche rouverte par son adresse (F5, Précédent)
/// n'a que les identifiants : l'identité se relit en base locale.
class FacturationSplitDetailPane extends StatelessWidget {
  final FacturationDetailIntent? selected;
  final VoidCallback onClose;

  const FacturationSplitDetailPane({
    super.key,
    required this.selected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    if (selected == null) {
      final l10n = AppLocalizations.of(context)!;
      return SingleChildScrollView(
        child: EteeloEmptyResult(
          label: l10n.facturationPickStudentTitle,
          description: l10n.facturationPickStudentMessage,
          medallionIcon: Icons.receipt_long_outlined,
        ),
      );
    }
    final key = ValueKey('${selected.academicYearId}/${selected.studentId}');
    if (selected.hasStudentIdentity) return _detail(key, selected);
    return StudentIdentityGate(
      key: key,
      studentId: selected.studentId,
      academicYearId: selected.academicYearId,
      builder: (identity) => _detail(
        null,
        identity == null ? selected : selected.withIdentity(identity),
      ),
    );
  }

  Widget _detail(Key? key, FacturationDetailIntent intent) =>
      FacturationDetailPage(
        key: key,
        intent: intent,
        embedded: true,
        onClose: onClose,
      );
}
