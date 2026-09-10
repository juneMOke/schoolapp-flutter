import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sélecteur de **classe** du niveau choisi — la maille sous le niveau.
///
/// Facultatif : la valeur vide vaut « toutes les classes du niveau ». Rendre la
/// classe obligatoire fermerait l'écran à un niveau dont les classes ne sont pas
/// encore composées, ou dont le roster n'est pas encore descendu sur l'appareil.
class FeeControlClassroomField extends StatelessWidget {
  /// Valeur sentinelle de « toutes les classes » — `EteeloSelectInput` distingue
  /// mal `null` (aucune sélection) d'un choix explicite.
  static const String allClassroomsValue = '__all__';

  final List<OfflineClassroom> classrooms;
  final String? selectedClassroomId;
  final bool hasLevel;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const FeeControlClassroomField({
    super.key,
    required this.classrooms,
    required this.selectedClassroomId,
    required this.hasLevel,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Reste ACTIF même sans classe composée : il porte alors la seule entrée
    // « toutes les classes du niveau », et le contrôle continue de fonctionner
    // à la maille niveau. Le message dit pourquoi la liste est courte.
    final enabled = hasLevel && !isLoading;
    final known = classrooms.any((c) => c.id == selectedClassroomId);
    // Une liste vide a deux causes, et une seule des deux se résoudra
    // (ADR-015 F1). Sans `classroom.read`, le roster n'est jamais tiré : dire
    // « aucune classe n'est composée pour ce niveau » affirme une chose sur
    // l'école alors qu'on ne sait rien d'elle — et laisse chercher côté
    // organisation des classes un manque qui est côté droits.
    final rosterWithheld =
        permissionHolding(context, const [Perm.classroomRead]) ==
        PermissionHolding.missing;

    return EteeloSelectInput<String>(
      label: l10n.feeControlClassroomLabel,
      placeholder: hasLevel ? null : l10n.feeControlClassroomPlaceholder,
      value: known ? selectedClassroomId : allClassroomsValue,
      enabled: enabled,
      errorText: hasLevel && !isLoading && classrooms.isEmpty
          ? (rosterWithheld
                ? l10n.feeControlClassroomWithheld
                : l10n.feeControlClassroomEmptyForLevel)
          : null,
      onChanged: onChanged,
      items: [
        EteeloSelectItem<String>(
          value: allClassroomsValue,
          label: l10n.feeControlClassroomAll,
        ),
        for (final classroom in classrooms)
          EteeloSelectItem<String>(value: classroom.id, label: classroom.name),
      ],
    );
  }
}
