import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_panel.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_picker.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_query.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/workspace/cote_class_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La zone de travail d'une classe ouverte. La liste des élèves n'est montrée
/// que si la grille tient à côté, mesuré sur la largeur reçue, avec une marge au
/// retour pour qu'elle ne clignote pas autour du seuil.
class CoteWorkspace extends StatefulWidget {
  final String classroomName;
  final VoidCallback? onStudentChanged;

  /// La recherche et le filtre de la liste ; sans eux, l'espace de travail
  /// tient les siens — toujours au-dessus de la liste, qui va et vient.
  final CoteStudentQuery? studentQuery;

  const CoteWorkspace({
    super.key,
    required this.classroomName,
    this.onStudentChanged,
    this.studentQuery,
  });

  @override
  State<CoteWorkspace> createState() => _CoteWorkspaceState();
}

class _CoteWorkspaceState extends State<CoteWorkspace> {
  bool _listVisible = true;

  /// Le bulletin change de parent quand la liste paraît ou disparaît : sa clé
  /// garde son focus, son défilement et le réglage d'Entrée.
  final _bulletinKey = GlobalKey();

  final _ownQuery = CoteStudentQuery();

  @override
  void dispose() {
    _ownQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
          buildWhen: (previous, current) =>
              current is CoteSaisieReady &&
              (previous is! CoteSaisieReady ||
                  previous.columns != current.columns ||
                  previous.fromCache != current.fromCache),
          builder: (context, state) {
            if (state is! CoteSaisieReady) return const SizedBox.shrink();
            _listVisible = coteListVisible(
              width: constraints.maxWidth,
              columns: state.columns,
              wasVisible: _listVisible,
              textScale: MediaQuery.textScalerOf(context).scale(1),
            );
            final bulletin = KeyedSubtree(
              key: _bulletinKey,
              child: EteeloEntrance(
                index: 2,
                child: CoteBulletinCard(
                  classroomName: widget.classroomName,
                  onStudentChanged: widget.onStudentChanged,
                ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EteeloEntrance(
                  index: 0,
                  child: CoteClassBar(classroomName: widget.classroomName),
                ),
                if (state.fromCache) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.coteFromCacheBanner,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warningInk,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (_listVisible)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EteeloEntrance(
                        index: 1,
                        child: CoteStudentPanel(
                          query: widget.studentQuery ?? _ownQuery,
                          onStudentChanged: widget.onStudentChanged,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.coteListGap),
                      Expanded(child: bulletin),
                    ],
                  )
                else ...[
                  EteeloEntrance(
                    index: 1,
                    child: CoteStudentPicker(
                      onStudentChanged: widget.onStudentChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  bulletin,
                ],
              ],
            );
          },
        );
      },
    );
  }
}
